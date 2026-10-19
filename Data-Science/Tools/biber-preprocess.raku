#!/usr/bin/env raku

use Text::CSV:ver<0.022>:auth<zef:Tux>;

# fix random seed - however, anonymization is not yet reproducible
srand(90210);

my %rename = "Gruppe" => 'Schuljahre', #11, 12, 13
             "Teamchef Benutzername" => "Name",
             "Teamchef Klassen-/ Kursname" => "Klasse",#Spaltenname im Jahr 2024
             "Teamchef Klasse" => "Klasse";#Spaltenname im Jahr 2025

my @remove = "Teamchef Vorname", "Teamchef Nachname", 'Achievement', 'Bonus', 'Z Score', 'Total', 'Team rank', 'School rank', 'Teammitglied 1 Benutzername', 'Teammitglied 1 Vorname', 'Teammitglied 1 Nachname', 'Teammitglied 1 Klasse';

#| Preprocess an Biber csv files to extract for Data Science.
sub MAIN(Str :$input-dir, Str :$output-file = "Biber-Daten-Long.csv", Str :$input-csv-sep = ";") {
    my @aoh_single = single($input-dir, $input-csv-sep);
    my @aoh_team = team($input-dir, $input-csv-sep);

    my @aoh = |@aoh_single, |@aoh_team;

    # Anonymize names, classes, schools and teams
    my @names = @aoh>>.{"Name"};
    my $names = @names.Set;
    my Set $anonym-names = [].Set;
    while $names.elems != $anonym-names.elems {
        $anonym-names = $names.map({('a'...'z').pick(5).join("")}).Set;
    }
    my %match-names = $names.keys Z=> $anonym-names.keys;

    my @klassen = @aoh>>.{"Klasse"};
    my $klassen = @klassen.Set;
    my Set $anonym-klassen = [].Set;
    while $klassen.elems != $anonym-klassen.elems {
        $anonym-klassen = $klassen.map({('A'...'Z').pick(3).join("")}).Set;
    }
    my %match-klassen = $klassen.keys Z=> $anonym-klassen.keys;
    
    my @schulen = @aoh>>.{"Schule"};
    my $schulen = @schulen.Set;
    my Set $anonym-schulen = [].Set;
    while $schulen.elems != $anonym-schulen.elems {
        $anonym-schulen = $schulen.map({('A'...'Z').pick(4).join("")}).Set;
    }
    my %match-schulen = $schulen.keys Z=> $anonym-schulen.keys;

    my @teams = @aoh>>.{"Team"};
    my $teams = @teams.Set;
    my Set $anonym-teams = [].Set;
    while $teams.elems != $anonym-teams.elems {
        $anonym-teams = $teams.map({('a'...'z').pick(4).join("")}).Set;
    }
    my %match-teams = $teams.keys Z=> $anonym-teams.keys;

    # replace old values with randomized values
    for @aoh -> %row {
        %row<Name> =  %match-names{%row<Name>};  
        %row<Klasse> =  %match-klassen{%row<Klasse>};  
        %row<Schule> =  %match-schulen{%row<Schule>};  
        %row<Team> =  %match-teams{%row<Team>} if %row<Team> ne 'N/A';  
    }

    my @column-keys = <Jahr Schule Land Schuljahre Name Klasse Team>;
    my @long-format;

    # create long format
    for @aoh -> %row {
        my %columns = @column-keys Z=> %row{@column-keys};
        # use set (-) to get the keys that are not in @column-keys
        my @value-keys = (%row.keys (-) @column-keys).keys;
        my %values = @value-keys Z=> %row{@value-keys};
        for %values.kv -> $key, $value {
            my %r = %columns.clone, { "Aufgabe" => $key, "Punkte" => $value };
            @long-format.push: %r;
        }
    }

    # write to csv
    my Str $out-file =  $output-file.IO.extension("anonym.csv").Str;
    say "Writing {@long-format.elems} rows to $out-file";
    csv(in => @long-format, out => $out-file, sep => ",", headers => "true");
}

sub team($input-dir, $input-csv-sep) {
  flat gather {
      for $input-dir.IO.dir.grep(/.*\d\d\d\d.*Gruppe\.csv$/) -> $in-file {
        say "Processing $in-file";

        my ($jahr, $schule, $land) = get-infor-from-filename($in-file);

        my $team = 1;
        
        my @aoh = csv(in => $in-file, headers => "true", sep => $input-csv-sep);

        # anonymize, rename, remove columns
        my @team-entries;

        for @aoh -> %row {
            # save team member info
            my $team-mate = %row{"Teammitglied 1 Benutzername"},
            
            # remove keys
            @remove.map: { %row{$_}:delete if %row{$_}:exists };
            
            #rename keys
            for %rename.kv -> $old-key, $new-key {
                if %row{$old-key}:exists {
                    %row{$new-key} = %row{$old-key};
                    %row{$old-key}:delete;
                }
            }

            # remove "Schuljahre " from string
            %row<Schuljahre> ~~ s:g/Schuljahre \s //;
            %row<Schuljahre> ~~ s:g/\s und /,/;
            %row<Schuljahre> ~~ s:g/ \, \s /+/;

            # add year
            %row<Jahr> = $jahr;
            %row<Team> = 'N/A';
            %row<Schule> =  $schule;
            %row<Land> =  $land;
            
            # create second entry for team member
            if so $team-mate {
                my %teammember = %row.clone;

                %teammember<Name> = $team-mate;
                %row<Team> = $team;
                %teammember<Team> = $team++;
                @team-entries.push(%teammember);
            }
        }

        @aoh = |@aoh, |@team-entries;
        say @aoh.elems, " rows"; 
        take @aoh;
      }
  }
}

sub single($input-dir, $input-csv-sep) {
    flat gather {
      for $input-dir.IO.dir.grep(/.*\d\d\d\d.*Einzel\.csv$/) -> $in-file {
        say "Processing $in-file";

        my ($jahr, $schule, $land) = get-infor-from-filename($in-file);

        my @aoh = csv(in => $in-file, headers => "true", sep => $input-csv-sep);

        # rename, remove columns
        for @aoh -> %row {
            # remove keys
            @remove.map: { %row{$_}:delete if %row{$_}:exists };
            
            #rename keys
            for %rename.kv -> $old-key, $new-key {
                if %row{$old-key}:exists {
                    %row{$new-key} = %row{$old-key};
                    %row{$old-key}:delete;
                }
            }

            # remove "Schuljahre " from string
            %row<Schuljahre> ~~ s:g/Schuljahre \s //;
            %row<Schuljahre> ~~ s:g/\s und /,/;
            %row<Schuljahre> ~~ s:g/ \, \s /+/;

            # add year
            %row<Jahr> = $jahr;
            %row<Schule> = $schule;
            %row<Land> = $land;

            # add dummy columns for team member to have same structure as team files
            %row<Team> = 'N/A';
        }
        say @aoh.elems, " rows"; 
        take @aoh;
      }
    }
}

sub get-infor-from-filename($in-file) {
    my $jahr = $in-file.basename ~~ /(\d\d\d\d)/;
    $jahr = $jahr[0].Str;
    
    my $schule = $in-file.basename ~~ /_(\w\w\w\w)_.*/;
    $schule = $schule[0].Str;
    
    my $land = $in-file.basename ~~ /^^(\w\w)_.*/;
    $land = $land[0].Str;

    return ($jahr, $schule, $land);
}

