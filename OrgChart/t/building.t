
######################### We start with some black magic to print on failure.

BEGIN { $numtests = 4 }
END {print "1..$numtests\nnot ok 1\n" unless $loaded;}

use Image::OrgChart;
$loaded = 1;

if ('GD::Image'->can('gif')) {
  print "1..$numtests\n";
} else {
  print "1..0\n";
  exit 0;
}

#### Test 1 -- Loaded
&report_result(1);

######################### End of black magic.

#### Test 2 -- New Object
my $t = new Image::OrgChart();
&report_result($t);

#### Test 3 -- add method
$t->add('/foo/bar');
&report_result( (scalar keys %{$t->{_data}{foo}} == 1) );

#### Test 4 -- set_hashref method
$hash{bar} = {
	      'foo1' => {},
	      'foo2' => {},
             };
$t->set_hashref(\%hash);
&report_result( (scalar keys %{$t->{_data}{bar}} == 2) );


sub report_result {
  my $bad = !shift;
  use vars qw($TEST_NUM);
  $TEST_NUM++;
  print "not "x$bad, "ok $TEST_NUM\n";
  
  print $_[0] if ($bad and $ENV{TEST_VERBOSE});
}
