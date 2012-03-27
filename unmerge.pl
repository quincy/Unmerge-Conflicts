#!/usr/bin/perl

#-------------------------------------------------------------------------------
# File:        unmerge.pl
# Author:      Quincy Bowers
# Description: Splits a file with merge conflict markers into two separate
#              files.
#
# March 27, 2012  Quincy Bowers
# Initial version.
#-------------------------------------------------------------------------------

use strict;
use warnings;

if (grep(/^-h|^--help/, @ARGV))
{
    usage();
    exit 0;
}

if (! scalar @ARGV)
{
    print "You must specify a merge conflict file.\n\n";
    usage();
    exit 0;
}

my $merge_file = shift @ARGV;

if (! -e $merge_file)
{
    print "$merge_file does not exist.\n\n";
    usage();
    exit 0;
}

my $lhs      = 0;
my $rhs      = 0;
my $lhs_text = q{};
my $rhs_text = q{};
my $lhs_file = q{};
my $rhs_file = q{};

# Open the merge file and write its contents to the lhs and rhs.
open my $MERGE, '<', $merge_file
    or die "Couldn't open $merge_file for reading.  $!\n";

LINE:
while (my $line = <$MERGE>)
{
    if ($lhs)
    {
        if ($line =~ m{=======}xms)
        {
            $lhs = 0;
            $rhs = 1;
            next LINE;
        }

        $lhs_text .= $line;
    }
    elsif ($rhs)
    {
        if ($line =~ m{>>>>>>>\s+(\S+)}xms)
        {
            $rhs = 0;
            $rhs_file = $merge_file . $1 . 'unmerged'  unless $rhs_file;
            next LINE;
        }

        $rhs_text .= $line;
    }
    else
    {
        if ($line =~ m{<<<<<<<\s+(\S+)}xms)
        {
            $lhs = 1;
            $lhs_file = $merge_file . $1 . 'unmerged'  unless $lhs_file;
            next LINE;
        }
        else
        {
            $lhs_text .= $line;
            $rhs_text .= $line;
        }
    }
}

close $MERGE;

if (!$lhs_file || !$rhs_file)
{
    print "No conflict markers found in $merge_file.\n";
    exit 1;
}

# Write the lhs file
open my $LHS, '>', $lhs_file
    or die "Could not open $lhs_file for writing.  $!\n";
print $LHS $lhs_text;
close $LHS;
print "Created $lhs_file\n";

# Write the rhs file
open my $RHS, '>', $rhs_file
    or die "Could not open $rhs_file for writing.  $!\n";
print $RHS $rhs_text;
close $RHS;
print "Created $rhs_file\n";

exit 0;

#-------------------------------------------------------------------------------
# Prints the help screen
#-------------------------------------------------------------------------------
sub usage
{
    while (<DATA>) { print; }
}


__END__
Help Screen

$ unmerge.pl [options] {conflict file}

OPTIONS
--help, -h      Show this help screen.

DESCRIPTION
unmerge.pl splits a file containing merge conflict markers into two files.

Given a file named sandwich.txt that looks like this:

    Top piece of bread
    Mayonnaise
    Lettuce
    Tomato
    Provolone
    <<<<<<< .mine
    Salami
    Mortadella
    Prosciutto
    =======
    Sauerkraut
    Grilled Chicken
    >>>>>>> .r2
    Creole Mustard
    Bottom piece of bread

The result of unmerge.pl will be two new files called sandwich.txt.mine and
sandwich.txt.r2 which look like this:

    sandwich.txt.mine.unmerged           sandwich.txt.r2.unmerged
    --------------------------           ------------------------
    Top piece of bread                   Top piece of bread
    Mayonnaise                           Mayonnaise
    Lettuce                              Lettuce
    Tomato                               Tomato
    Provolone                            Provolone
    Salami                               Sauerkraut
    Mortadella                           Grilled Chicken
    Prosciutto                           Creole Mustard
    Creole Mustard                       Bottom piece of bread
    Bottom piece of bread

AUTHOR Quincy Bowers
Last Modification March 27, 2012

