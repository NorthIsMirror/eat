#!/usr/bin/env perl

use strict;
use warnings;
use Data::Dumper;
use Term::ReadLine;
use Term::ReadLine::Perl;
use Term::ANSIColor;
use Term::Size;
use Text::Wrap;
use Storable;
use YAML qw'LoadFile';
use Perl6::Form;

# Local module
use FoodCalc;
FoodCalc::init;

$Data::Dumper::Indent = 1;
$Data::Dumper::Sortkeys = 1;


# Width of the text to display
my ($COLUMNS, $LINES) = Term::Size::chars;
my $cols = $COLUMNS > 100 ? 100 : $COLUMNS - 1;
$Text::Wrap::columns = $cols;

# Location and names of files
my $workdir = "fooddata";

# Colors used for emphasizing phrases
my %colors = (
    "entry" => color("bold green"),
    "reset" => color("reset")
);

use constant {
    PERCENT => 'Percent',
    AMOUNT => 'Amount',
};

# Read file names belonging to the food database
opendir(D, $workdir);
my @files = grep { /\.yml$/ } readdir(D);
closedir(D);

# Aliases for the foods
# Have to be capitalized
my %aliases = (
    "Millet" => "Raw Millet",

    "Lentils" => "Raw Lentils",
    "Lentil" => "Raw Lentils",

    "Buckwheat" => "Raw Buckwheat",
    "Buck" => "Raw Buckwheat",

    "Egg" => "Raw Egg",
    "Eggs" => "Raw Egg",
    "Chicken Egg" => "Raw Egg",
    "Chicken Eggs" => "Raw Egg",

    "Sunflower" => "Raw Sunflower Seeds [kernel]",
    "Sunflower Seeds" => "Raw Sunflower Seeds [kernel]",
    "Raw Sunflower" => "Raw Sunflower Seeds [kernel]",
    "Raw Sunflower Seeds" => "Raw Sunflower Seeds [kernel]",

    # Include the direct names
    "Ham" => "Ham",
    "Raw Millet" => "Raw Millet",
    "Raw Lentils" => "Raw Lentils",
    "Raw Buckwheat" => "Raw Buckwheat",
    "Raw Egg" => "Raw Egg",
    "Raw Sunflower Seeds [kernel]" => "Raw Sunflower Seeds [kernel]",
);

# Structure of what to look for
my %nutrient_types = (
                "vitamins" => [ "A", "retinol", "alpha carotene", "beta carotene", "beta cryptoxanthin",
                                "lycopene", "lutein plus zeaxanthin", "C", "E", "beta tocophreol",
                                "gamma tocophreol", "delta tocophreol", "D", "K", "thiamin B1",
                                "riboflavin B2", "niacin B3", "B6", "biotin B7", "folate B9",
                                "folic acid B9", "B12", "panto acid B5" ], 

                "minerals" => [ "calcium", "iron", "magnesium", "phosphorus", "potassium",
                                "sodium", "zinc", "copper", "manganese", "selenium" ],

                "amino acids" => [ "proteins", "tryptophan", "threonine", "isoleucine", "leucine", "lysine",
                                   "methionine", "cystine", "phenylalanine", "tyrosine", "valine", "arginine",
                                   "histidine", "alanine", "aspartic acid", "glutamic acid", "glycine", "proline",
                                   "serine", "hydroxyproline" ]
);

# Structure of what to display
my %nutrients_to_display = (
                "vitamins" => [ "A", "C", "E", "beta tocophreol", "gamma tocophreol", "delta tocophreol",
                                "D", "K", "thiamin B1", "riboflavin B2", "niacin B3", "B6", "biotin B7",
                                "folate B9", "folic acid B9", "B12", "panto acid B5" ], 

                "minerals" => [ "calcium", "iron", "magnesium", "phosphorus", "potassium",
                                "sodium", "zinc", "copper" ],

                "amino acids" => [ "proteins", "tryptophan", "threonine", "isoleucine", "leucine", "lysine",
                                   "methionine", "cystine", "phenylalanine", "tyrosine", "valine", "arginine",
                                   "histidine", "alanine", "aspartic acid", "glutamic acid", "glycine", "proline",
                                   "serine", "hydroxyproline" ]
);

sub init_template_result {
    my %result = ();
    while ( my ($type, $listref) = each %nutrient_types ) {
        $result{$type} = {};
        foreach my $compound ( @{$listref} ) {
            # Each compound, e.g. vitamin A, has two data - amount and % GDA
            $result{$type}->{$compound} = [ 0, 0 ];
        }
    }

    return %result;
}

sub table_for_nutrient_type {
    my $type = lc shift;
    my $alldata = shift;
    my $whichdata = shift;

    $whichdata = PERCENT unless defined $whichdata;

    my $output = "";

    $output .=      "================================\n";
    $output .= form "| {<<<<<<<<<<<<<} | {||||||||} |", ucfirst substr( $type, 0, -1), $whichdata;
    $output .=      "+-----------------+------------+\n";

    foreach my $compound ( @{$nutrients_to_display{ $type }} ) {
        my $disp_percent;
        if( $whichdata eq AMOUNT ) {
            $disp_percent = $alldata->{ $type }->{ $compound }->[0];
        } else {
            $disp_percent = $alldata->{ $type }->{ $compound }->[1];
        }

        my $disp_compound = $compound;
        $output .= form "| {<<<<<<<<<<<<<} | {||||||||} |", $disp_compound, $disp_percent;
    }

    $output .= "================================\n";

    return $output;
}

sub capitalize {
    my( $line ) = join " ", @_;
    return join " ", map {ucfirst lc} split " ", $line;
}

# The food info hash
my %db = ();

foreach my $current_file (@files) {
    # Skip the template files
    next if $current_file =~ "template.*";

    print "Processing $current_file\n";

    my ($hashref) = LoadFile("$workdir/$current_file");

    my $name = $hashref->{"name"};
    $db{ $name } = $hashref;
}

# print Dumper( \%db );

# Process user input in a loop
my $term = Term::ReadLine->new('FoodCalculator');
print "Using ", $term->ReadLine, "\n";
# Make autohistory basically disabled
$term->MinLine(2000);

my $prompt = "Enter query: ";
my $OUT = $term->OUT || \*STDOUT;


my @history = ();
if( -e ".history" ) {
    @history = @{ retrieve ".history" };
    foreach my $line ( @history ) {
        $term->addhistory($line);
    }
}

while ( defined ($_ = $term->readline($prompt)) ) {
    # Append to history
    $term->addhistory($_) if /\S/ and $_ ne "q";
    push @history, $_ if /\S/ and $_ ne "q";

    # Exit on "q" 
    last if $_ eq "q";

    # Colapse spaces
    $_ =~ s/\s+/ /g;

    # Test if query is empty
    if ( $_ =~ /^\s*$/ ) {
        print "You've entered an empty query\n";
        next;
    }

    my $processed_input = FoodCalc::parse( $_ );

    # Print how has been the input interpreted
    # Capitalize food names
    my $input_str = "";
    foreach my $food_entry ( @{$processed_input} ) {
        $food_entry->{"name"} = capitalize( $food_entry->{"name"} );
        $input_str .= $food_entry->{"count"} . $food_entry->{"unit"} . " " . $food_entry->{"name"} . ", ";
    }
    if( length( $input_str ) > 2 ) {
        $input_str = substr( $input_str, 0, -2 );
    }
    print "Computing data for: ", $input_str, "\n";

    #
    # Do the final computation (summation of nutrients)
    #

    my %result = init_template_result;

    #
    # This loops iterate over %nutrients for each user's given food
    #

    # For every user's given food entry..
    #
    # It is in the form:
    #   {
    #       'count' => 100,
    #       'name' => 'Millet',
    #       'unit' => 'g'
    #   }, 
    #
    foreach my $food_entry ( @{$processed_input} ) {
        my $given_mass = $food_entry->{"count"};
        my $given_unit = $food_entry->{"unit"};
        my $db_entry_name = $aliases{ $food_entry->{"name"} };
        my $db_entry = $db{ $db_entry_name };

        # For every compound type.. (vitamin, mineral, etc.)
        while ( my ($type, $listref) = each %nutrient_types) {

            # For every compound ...
            foreach my $compound ( @{$listref} ) {
                my $multiplier = 1.0;
                if( $given_unit eq "g" ) {
                    $multiplier = $given_mass / 100.0;
                } elsif( $given_unit eq "mg" ) {
                    $multiplier = $given_mass / 100000.0;
                } else {
                    print "ERROR: unknown unit exists: $given_unit\n";
                }

                # Sum the amount of the compound
                # It is given per 100g, so scale according to user's entered mass
                my $weight = $db_entry->{ $type }->{ $compound }->[0];
                $weight =~ s/[a-zA-Z ]*//g;
                $result{$type}->{$compound}->[0] += $weight * $multiplier;

                # The same with % GDA
                my $percent = $db_entry->{ $type }->{ $compound }->[1];
                $percent =~ s/%//;
                $result{$type}->{$compound}->[1] += $percent * $multiplier;
            }
        }
    }

    my $vitamins = table_for_nutrient_type "vitamins", \%result;
    my $minerals = table_for_nutrient_type "minerals", \%result;
    my $aminoacids = table_for_nutrient_type "amino acids", \%result, AMOUNT;

    print $vitamins;
    print $minerals;
    print $aminoacids;
}

store \@history, ".history";

