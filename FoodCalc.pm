package FoodCalc;

use warnings;

use Exporter qw(import);
use Data::Dumper;
use Parse::RecDescent;

our @EXPORT_OK = qw(init parse);
$::RD_HINT = 1;

sub dbg {
    #print @_, "\n";
}

sub dbg_ {
    #print @_;
}

# Only grabs RecDescent input - triplets of val, operator, val 
# and passes them to compute_on_arrays
sub evalop
{
	my (@list) = @{$_[0]};
	my $val1 = shift(@list)->();

	while (@list)
	{
		my ($op, $arg2) = splice @list, 0, 2;
                compute_on_arrays( $val1, $op, $arg2->() );
	}
	return $val1;
}

# Template of the list used when doing any math or aggregating inputs
# Actions either add hashes into the list, or colapse any existing ones
# (when they have the same units).
my @elemen = (
    [
    "name" => "",
    "count" => "",
    "unit" => ""
    ]
);

#
# Unit conversion and calculation procedures
#

sub match_units {
    my $unit1 = $_[0]->{"unit"};
    my $unit2 = $_[1]->{"unit"};

    if ( $unit1 ne $unit2 ) {
        if ( $unit1 eq "g" and $unit2 eq "mg" ) {
            $_[0]->{"count"} *= 1000;
            $_[0]->{"unit"} = "mg";
        } elsif ( $unit1 eq "mg" and $unit2 eq "g" ) {
            $_[0]->{"count"} /= 1000;
            $_[0]->{"unit"} = "g";
        }
    }
}

sub add_units {
    dbg "add_units()";

    match_units( $_[0], $_[1] );
    $_[0]->{"count"} += $_[1]->{"count"};
}

sub sub_units {
    dbg "sub_units()";

    match_units( $_[0], $_[1] );
    $_[0]->{"count"} -= $_[1]->{"count"};
}

sub mul_units {
    dbg "mul_units()";

    match_units( $_[0], $_[1] );
    $_[0]->{"count"} *= $_[1]->{"count"};
}

sub div_units {
    dbg "div_units()";

    match_units( $_[0], $_[1] );
    $_[0]->{"count"} /= $_[1]->{"count"};
}

#
# Handling of the aggregated data storage
# Calling actual calculation, collapsing the same foods, aggregating distinct ones
#

sub compute_on_arrays
{
    # Create copies of lists (note: the contained hash references are still the same)
    my(@list1) = @{$_[0]};
    my(@list2) = @{$_[2]};
    my $op = $_[1];

    # Traverse through list1, at each its element traverse list2
    #
    # When the same food occurs, compute the result to list1, put zero to list2.  This
    # is because each food can be added only once - RecDescent first processes the most
    # nested brackets, everything there is summed one by one, and even if some food
    # would apparently be used again because of (a + b)(a + c) multiplication, it will
    # in fact be either (a + a)(a + c) = 2a(a + c), or indeed (a + b)(a + c) with `a'
    # and `b' being distinct, but then, you can only do a*a, a*b doesn't have any
    # meaning and will not be performed. So, as list1 is traversed only once, the
    # results of operators (with multiplications being quite awkward, the units are not
    # being multiplied, only values, but maybe there will be some use of this, so it is
    # allowed) are put into it, and the multiple-times traversed list2 has elements
    # zeroed after each use, so that they are then skipped at the aggregation stage.
    #
    # When a value-only element occurs, the result is computed to the opposite list,
    # i.e. the one containing food element.
    foreach my $el1 (@list1) {
        foreach my $el2 (@list2) {
            if ( $el1->{"name"} eq $el2->{"name"} ) {
                # Compute result of $op operator into $el2
                $op->( $el1, $el2 );
                # $el2 is now already used and should be removed
                $el2->{"count"} = 0;
            } elsif ( $el2->{"unit"} eq "-" ) {
                # Food : value-only
                $op->( $el1, $el2 );
            } elsif ( $el1->{"unit"} eq "-" ) {
                # value-only : Food
                $op->( $el2, $el1 );
            } elsif ( $el1->{"unit"} eq "-" and $el2->{"unit"} eq "-" ) {
                # value-only : value-only
                # This will not happen, each parenthesis will not contain any value-only
                # elements after being processed, or the user entered an improper expression,
                # like: (2 + 100 g <food>) * 2. The only correct expressions are like:
                # (2 * 100 g <food>) * 2 ; (200 g <food>) * 2 ; 400 g <food>
                # TODO: signal error
            } else {
                # The typical case where distinct foods are e.g. added
                # This is handled in the aggregation stage, as such foods
                # cannot be added nor multiplied
            }
        }
        dbg_ "After inner foreach: ", Dumper($el1);
    }

    # Remove hollow elements, store into input arrays of
    # the procedure (i.e. dereference $_[0] and $_[2])
    @{$_[0]} = grep { $_->{"count"} != 0 and $_->{"unit"} ne "-"; } @list1;
    @{$_[2]} = grep { $_->{"count"} != 0 and $_->{"unit"} ne "-"; } @list2;

    # Append $_[2] to $_[0], i.e. do the aggregation part
    push @{$_[0]}, @{$_[2]};
    dbg_ "compute_on_arrays result: ", Dumper($_[0]);
}

my $parse;

#
# Initialize the parser
#
sub init {
    $parse = Parse::RecDescent->new(<<'END_OF_GRAMMAR');
	main: expr /\s*\Z/ { $item[1]->() }
	    | <error>

	expr: 
	    lvar '=' addition
			{
                          my ($vname, $expr) = @item[1,3];
			  sub { no strict 'refs'; $$vname = $expr->() }
			}
	    | addition

	addition: <leftop:multiplication add_op multiplication>
			{ 
                            my $add = $item[1];
                            # my @lst = @{$add}; print "Add:", ::Dumper( $lst[2]->() );
                            sub { FoodCalc::evalop $add }
                        }

	add_op: '+'	{
                            \&FoodCalc::add_units
                        }
	      | '-'	{
                            \&FoodCalc::sub_units
                        }

	multiplication: <leftop:factor mult_op factor>
			{ my $mult = $item[1]; sub { FoodCalc::evalop $mult } }
  
	mult_op: '*'	{
                            \&FoodCalc::mul_units
                        }
	       | '/'	{
                            \&FoodCalc::div_units
                        }

	factor: number_unit_name
              | number
	      | rvar
	      | '(' expr ')' { $item[2] }

        number: /[-+]?\d+(\.\d+)?/      {
                                            sub {
                                                return [
                                                    {
                                                    "name" => "[value-only]",
                                                    "count" => "$item[1]",
                                                    "unit" => "-"
                                                    }
                                                ]
                                            }
                                        }

        number_unit_name: /([-+]?\d+)(\.\d+)?\s*(g|mg)\s+([a-zA-Z ]+)/	{
                                                    sub { 
                                                        $item[1] =~ /([-+]?\d+)(\.\d+)?\s*(g|mg)\s+([a-zA-Z ]+)/;
                                                        my $number = $1 . $2;
                                                        my $unit = $3;
                                                        my $name = $4;
                                                        $name =~ s/^\s+|\s+$//g;

                                                        return [
                                                            {
                                                            "name" => $name,
                                                            "count" => $number,
                                                            "unit" => $unit
                                                            }
                                                        ]
                                                    }
                                                                        }

	lvar:	/\$([a-z]\w*)/		{ $1 }

	rvar:	lvar			{ sub { no strict 'refs'; ${$item[1]} } } 

END_OF_GRAMMAR
}

#
# Parse the input
#
sub parse {
  my $input = join " ", @_;
  dbg "input: $input";
  return $parse->main( $input );
}

1;
