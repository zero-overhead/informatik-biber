#!/usr/bin/env raku

# Tools/biber-preprocess.raku --input-dir=Resultate --output-file=Daten/Biber-Daten-Long.csv 

use Text::CSV:ver<0.022>:auth<zef:Tux>;

# fix random seed - however, anonymization is not yet reproducible
#srand(90210);

my $NA-string = "none";

# Columns in input that need renaming
my %rename = "Gruppe" => 'Klassenstufe', #11-12-13
             "Teamchef Benutzername" => "Name", # login name of student
             "Teamchef Klassen-/ Kursname" => "Klasse",# Spaltenname im Jahr 2024
             "Teamchef Klasse" => "Klasse";# Spaltenname im Jahr 2025

# remove columns that are not needed for data science
my @remove = "Teamchef Vorname", "Teamchef Nachname", 'Achievement', 'Z Score', 'Total', 'Team rank', 'School rank', 'Teammitglied 1 Benutzername', 'Teammitglied 1 Vorname', 'Teammitglied 1 Nachname', 'Teammitglied 1 Klasse';

#| Preprocess an Biber csv files to extract for Data Science.
sub MAIN(Str :$input-dir = "Resultate", Str :$output-file = "Daten/Biber-Daten-Long.csv", Str :$input-csv-sep = ";", Bool :$anonymize = True, Str :$vornamen-file-f = "Daten/CH_vornamen_f.csv", Str :$vornamen-file-m = "Daten/CH_vornamen_m.csv", Str :$nachnamen-file = "Daten/CH_nachnamen.csv", Bool :$debug) {
   # read csv files and create Array of Hashes (AoH) for single and team files
    my @aoh = |single($input-dir, $input-csv-sep),
              |team($input-dir, $input-csv-sep);

    if $anonymize {
       @aoh = anonymize(@aoh, $vornamen-file-f, $vornamen-file-m, $nachnamen-file, $debug);
    } else {
        say "Skipping anonymization";
    }
    
    # write csv file in long format
    my @column-keys = <Jahr Schule Land Klassenstufe Name Klasse Team>;
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
    my $extension = "csv";
    $extension = "anonym.csv" if $anonymize;
    my Str $out-file =  $output-file.IO.extension($extension).Str;
    say "Writing {@long-format.elems} answers to $out-file";
    csv(in => @long-format, out => $out-file, sep => ",", headers => "true");
}

sub anonymize(@aoh, $vornamen-file-f, $vornamen-file-m, $nachnamen-file, $debug) {
        
        say "reading data for anonymization from $vornamen-file-m, $vornamen-file-f, $nachnamen-file)" if $debug;
        my @vornamen-m = $vornamen-file-m.IO.slurp().lines().skip();
        my @vornamen-f = $vornamen-file-f.IO.slurp().lines().skip();
        my @nachnamen = $nachnamen-file.IO.slurp().lines().skip();
        
        my $vornamen = BagHash.new-from-pairs: @vornamen-m.skip()>>.split(";")>>.pairup,
                       BagHash.new-from-pairs: @vornamen-f.skip()>>.split(";")>>.pairup;
        
        my $nachnamen = BagHash.new-from-pairs: @nachnamen.skip()>>.split(";")>>.pairup;
        
        say "anonymization length for each column, e.g. KSXX -> 'abcd' (Schule -> 4 random characters)" if $debug;
        my %anon-length =
            Name   => {($vornamen.pick(), $nachnamen.pick()).join(" ")}, 
            Klasse => {(('A'...'Z').pick(1),(1..4).rand.Int,(1..10).rand.Int,('a'...'h').pick(1)).flat.join("")},
            Schule => {(("K", "B", "R", "S").pick(1), "S", ('A'...'Z').pick(2)).flat.join("")},
            Team   => {(('A'...'Z').pick(2),(4..10).rand().Int,(1..7).rand().Int).flat.join("")}
        ;

        say "Anonymize {@aoh.elems} students on columns: {%anon-length.keys.join(", ")}";
        for %anon-length.kv -> $column, &fn {
                my Set $values = @aoh>>.{$column}.Set;
                my Set $anonym-values;
                
                while $values.elems != $anonym-values.elems {
                    $anonym-values = $values.map({&fn()}).Set;
                }
                my %randomized-values-map = $values.keys Z=> $anonym-values.keys;
                
                # replace old values with randomized values
                for @aoh -> %row {
                    my $original_val = %row{$column};
                    my $randomized_val = %randomized-values-map{$original_val};
                   %row{$column} =  $randomized_val if %row{$column} ne $NA-string;
                }
        }
        return @aoh;
}

sub team($input-dir, $input-csv-sep) {
  flat gather {
      for $input-dir.IO.dir.grep(/.*\d\d\d\d.*Gruppe\.csv$/) -> $in-file {
        say "Processing $in-file";

        # CH_KSZZ_Wettbewerb_2025_Resultate_9-10_Einzel.csv
        my $match = $in-file.basename ~~ /^^(\w\w)_(\w\w\w\w)_.*(\d\d\d\d).*csv$$/;
        my ($land, $schule, $jahr) = $match>>.Str;

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
            %row<Klassenstufe> ~~ s:g/Schuljahre \s //;
            %row<Klassenstufe> ~~ s:g/\s und /,/;
            %row<Klassenstufe> ~~ s:g/ \, \s /+/;

            # add year
            %row<Jahr> = $jahr;
            %row<Team> = $NA-string;
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
        say @aoh.elems, " team rows"; 
        take @aoh;
      }
  }
}

sub single($input-dir, $input-csv-sep) {
    flat gather {
      for $input-dir.IO.dir.grep(/.*\d\d\d\d.*Einzel\.csv$/) -> $in-file {
        say "Processing $in-file";

        # CH_KSZZ_Wettbewerb_2025_Resultate_9-10_Einzel.csv
        my $match = $in-file.basename ~~ /^^(\w\w)_(\w\w\w\w)_.*(\d\d\d\d).*csv$$/;
        my ($land, $schule, $jahr) = $match>>.Str;

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
            %row<Klassenstufe> ~~ s:g/Schuljahre \s //;
            %row<Klassenstufe> ~~ s:g/\s und /,/;
            %row<Klassenstufe> ~~ s:g/ \, \s /+/;

            # add year
            %row<Jahr> = $jahr;
            %row<Schule> = $schule;
            %row<Land> = $land;

            # if name is empty, add random name - big enough to make sure there is no collision
            %row{'Name'} = ('a'...'z').pick(100).join("") unless %row{'Name'}:exists;
            
            # add dummy columns for team member to have same structure as team files
            %row<Team> = $NA-string;
        }
        say @aoh.elems, " single rows"; 
        take @aoh;
      }
    }
}
