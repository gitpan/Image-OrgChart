
######################### We start with some black magic to print on failure.

BEGIN { $numtests = 5 }
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

#### Test 2 -- set_hashref method
$hash{bar} = {
	      'foo1' => {},
	      'foo2' => {},
             };
$t = Image::OrgChart->new();
$t->set_hashref(\%hash);
&report_result( (scalar keys %{$t->{_data}{bar}} == 2) );

#### Test 3 -- get data type
$type = $t->data_type();
if ($type ne 'gif' && $type ne 'png') {
    warn "Data Type '$type' is not png or gif.\n";
    &report_result(0);
} else {
    &report_result(1);
}

#### Test 4 -- test data (approximate)
$data = $t->draw();
$length = length($data);
if ( $length < 508 || $length > 608 ) {
    warn "Data length not within 50 bytes.($length != 53)\n";
    &report_result(0);
} else {
    &report_result(1);
}

### Test 5 -- test data (exact length)
if ($length != 558) {
    warn "Data size not exact. Possible GD version diffrence ?\n";
    &report_result(0);
} else {
    &report_result(1);
} 

sub report_result {
  my $bad = !shift;
  use vars qw($TEST_NUM);
  $TEST_NUM++;
  print "not "x$bad, "ok $TEST_NUM\n";
  
  print $_[0] if ($bad and $ENV{TEST_VERBOSE});
}
