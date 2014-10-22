#!/usr/bin/perl

#### Shadow Example

require '../OrgChart.pm';
use strict;
$|=1;

print "OrgChart [v$Image::OrgChart::VERSION]\n";

my %hash = ();
$hash{bar} = {
	      'foo1' => {},
	      'foo234567891011' => {
                                    a => {},
                                    b => {
                                      222 => {},
                                      553 => {},
                                      554 => {},
                                      555 => {},
                                    },
                                    c => {
                                    },
                                    },
             };
my $t = Image::OrgChart->new(
                             indent      => 3, # characters
                             shadow      => 1,
                             );
$t->set_hashref(\%hash);

my $file = 'test.' . $t->data_type;

open(OUT,"> $file") || die "Could not open output file : $1";
binmode(OUT);
print OUT $t->draw();
close(OUT);
