#!/usr/bin/env raku

# Tools/biber-preprocess.raku --input-dir=Resultate --output-file=Daten/Biber-Daten-Long.csv 

use Text::CSV:ver<0.022>:auth<zef:Tux>;

# fix random seed - however, anonymization is not yet reproducible
srand(90210);

my $NA-string = "none";

# Columns in input that need renaming
my %rename = "Gruppe" => 'Schuljahre', #11-12-13
             "Teamchef Benutzername" => "Name", # login name of student
             "Teamchef Klassen-/ Kursname" => "Klasse",# Spaltenname im Jahr 2024
             "Teamchef Klasse" => "Klasse";# Spaltenname im Jahr 2025

# remove columns that are not needed for data science
my @remove = "Teamchef Vorname", "Teamchef Nachname", 'Achievement', 'Bonus', 'Z Score', 'Total', 'Team rank', 'School rank', 'Teammitglied 1 Benutzername', 'Teammitglied 1 Vorname', 'Teammitglied 1 Nachname', 'Teammitglied 1 Klasse';

# anonymization length for each column, e.g. KSXX -> "abcd" (Schule -> 4 random characters)
my %anon-length =
    Name   => 6,
    Klasse => 5,
    Schule => 4,
    Team   => 3;

#| Preprocess an Biber csv files to extract for Data Science.
sub MAIN(Str :$input-dir = "Resultate", Str :$output-file = "Daten/Biber-Daten-Long.csv", Str :$input-csv-sep = ";") {
   # read csv files and create Array of Hashes (AoH) for single and team files
    my @aoh = |single($input-dir, $input-csv-sep),
              |team($input-dir, $input-csv-sep);

    say "Anonymize {@aoh.elems} students records columns: {%anon-length.keys.join(", ")}";
    for %anon-length.kv -> $column, $length {
            my Set $values = @aoh>>.{$column}.Set;
            my Set $anonym-values;
            
            while $values.elems != $anonym-values.elems {
                $anonym-values = $values.map({('a'...'z').pick($length).join("")}).Set;
            }
            my %randomized-values-map = $values.keys Z=> $anonym-values.keys;
            
            # replace old values with randomized values
            for @aoh -> %row {
                my $original_val = %row{$column};
                my $randomized_val = %randomized-values-map{$original_val};
                %row{$column} =  $randomized_val if %row{$column} ne $NA-string;
            }
    }
    
    # write csv file in long format
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
    say "Writing {@long-format.elems} anonymized answers to $out-file";
    csv(in => @long-format, out => $out-file, sep => ",", headers => "true");
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
            %row<Schuljahre> ~~ s:g/Schuljahre \s //;
            %row<Schuljahre> ~~ s:g/\s und /,/;
            %row<Schuljahre> ~~ s:g/ \, \s /+/;

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
            %row<Schuljahre> ~~ s:g/Schuljahre \s //;
            %row<Schuljahre> ~~ s:g/\s und /,/;
            %row<Schuljahre> ~~ s:g/ \, \s /+/;

            # add year
            %row<Jahr> = $jahr;
            %row<Schule> = $schule;
            %row<Land> = $land;

            # if name is empty, add random name - big enought to make sure there is no collision
            %row{'Name'} = ('a'...'z').pick(100).join("") unless %row{'Name'}:exists;
            
            # add dummy columns for team member to have same structure as team files
            %row<Team> = $NA-string;
        }
        say @aoh.elems, " single rows"; 
        take @aoh;
      }
    }
}
