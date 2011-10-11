#!perl -T

use Test::More tests => 19;
use PPI;
use PPI::Dumper;

BEGIN {
  use_ok( 'JGoff::App::Perltidy' ) || print "Bail out!\n";
}

my $tidy = JGoff::App::Perltidy->new;

my @test = (
  [ q{my$first} => q{my $first}, {debug => 0} ],
  [ q{my $first} => q{my $first}, {debug => 0} ],
  [ q{my  $first} => q{my $first}, {debug => 0} ],
  [ q{my $first } => q{my $first}, {debug => 0} ],
  [ q{my$first=0} => q{my $first = 0}, {debug => 0} ],
  [ q{my$first = 0} => q{my $first = 0}, {debug => 0} ],
  [ q{my $first = 0} => q{my $first = 0}, {debug => 0} ],
  [ q{my  $first = 0} => q{my $first = 0}, {debug => 0} ],
  [ q{my  $first  = 0} => q{my $first = 0}, {debug => 0} ],
  [ q{my  $first  =  0} => q{my $first = 0}, {debug => 0} ],
  [ qq{my\n\$first\n=\n0} => q{my $first = 0}, {debug => 0} ],
  [ qq{my\n\$first\n=\n0;my \$second=1} =>
    qq{my \$first = 0;\nmy \$second = 1}, {debug => 0} ],
  [ qq{my\n\$first\n=\n0; my \$second=1} =>
    qq{my \$first = 0;\nmy \$second = 1}, {debug => 0} ],
  [ qq{my\n\$first\n=\n0;\nmy \$second=1} =>
    qq{my \$first = 0;\nmy \$second = 1}, {debug => 0} ],
);
for my $test ( @test ) {
  my ( $in, $out, $debug ) = @$test;
  my $res = $tidy->reformat(
    %$debug,
    text => $in,
    style => 'whitesmiths'
  );
  is( $res, $out ) or do {
    diag( "\n----\n$in\n----\n$out\n----\n$res\n----" );
  };
}

{
  my $in = 'my $first=0;sub something{print $_[0]}$first--' . "\n";
  my $out = <<'EOF';
my $first = 0;
sub something
  {
    print $_[0]
  }
$first--
EOF
  my $res = $tidy->reformat(
#    debug => 1,
    text => $in,
    style => 'whitesmiths'
  );
#die PPI::Dumper->new($tidy->ppi)->string;

  is( $res, $out );# or diag( "$in => $out but was $res" );
#die PPI::Dumper->new($tidy->ppi)->string;
}

{
  my $in = 'my $first=0;sub something{print $_[0];$first++}$first--' . "\n";
  my $out = <<'EOF';
my $first = 0;
sub something
  {
    print $_[0];
    $first++
  }
$first--
EOF
#$tidy->DEBUG(1);
  my $res = $tidy->reformat(
#    debug => 1,
    text => $in,
    style => 'whitesmiths'
  );
#$tidy->DEBUG(undef);
#die PPI::Dumper->new($tidy->ppi)->string;

  is( $res, $out );# or diag( "$in => $out but was $res" );
}

{
  my $in = 'my $first  =0;sub something{print $_[0]}$first--' . "\n";
  my $out = <<'EOF';
my $first = 0;
sub something
  {
    print $_[0]
  }
$first--
EOF
  my $res = $tidy->reformat(
#    debug => 1,
    text => $in,
    style => 'whitesmiths'
  );
#die PPI::Dumper->new($tidy->ppi)->string;

  is( $res, $out );
#die PPI::Dumper->new($tidy->ppi)->string;
}

{
  my $in = 'my $first  =0;  sub something{print $_[0]}$first--' . "\n";
  my $out = <<'EOF';
my $first = 0;
sub something
  {
    print $_[0]
  }
$first--
EOF
#$tidy->DEBUG(1);
  my $res = $tidy->reformat(
#    debug => 1,
    text => $in,
    style => 'whitesmiths'
  );
#$tidy->DEBUG(undef);
#die PPI::Dumper->new($tidy->ppi)->string;

  is( $res, $out ) or do {
    $in =~ s{ }{|}g;
    $out =~ s{ }{|}g;
    $res =~ s{ }{|}g;
    diag( "$in\n----\n$out\n----\n$res\n----" );
  };
#die PPI::Dumper->new($tidy->ppi)->string;
}

=pod

{
  my $in = 'sub something{print $_[0]}';
  my $out = 'sub something{my $self = shift; print $self}';
  my $res = $tidy->reformat(
    text => $in,
    munge_args => { oo => 1 }
  );

  is( $res, $out ) or diag( "$in => $out but was $res" );
}

{
  my $in = 'sub something{my $self = shift; print $_[0]}';
  my $out = 'sub something{my $self = shift; print $_[0]}';
  my $res = $tidy->reformat(
    text => $in,
    munge_args => { oo => 1 }
  );

  is( $res, $out ) or diag( "$in => $out but was $res" );
}

{
  my $in = <<'EOF';
sub read_attribute { print $_[0]->{target} }
EOF

  my $out = <<'EOF';
use Moose;
has target => ( is => 'rw', isa => 'Str' );
sub read_attribute { print $_[0]->target }
EOF

  my $res = $tidy->reformat(
    text => $in,
    moosify => 1
  );

  is( $res, $out ) or diag( "$in => $out but was $res" );
}

{
  my $in = <<'EOF';
sub read_attribute {
  my ( $self ) = @_;
  print $self->{target};
}
EOF

  my $out = <<'EOF';
use Moose;
has target => ( is => 'rw', isa => 'Str' );
sub read_attribute {
  my ( $self ) = @_;
  print $self->target;
}
EOF

  my $res = $tidy->reformat(
    text => $in,
    moosify => 1
  );

  is( $res, $out ) or diag( "$in => $out but was $res" );
}

{
  my $in = <<'EOF';
sub read_attribute {
  my $self = shift;
  print $self->{target};
}
EOF

  my $out = <<'EOF';
use Moose;
has target => ( is => 'rw', isa => 'Str' );
sub read_attribute {
  my $self = shift;
  print $self->target;
}
EOF

  my $res = $tidy->reformat(
    text => $in,
    moosify => 1
  );

  is( $res, $out ) or diag( "$in => $out but was $res" );
}

{
  my $in = <<'EOF';
sub read_attribute {
  my $class = shift;
  print $class->{target};
}
EOF

  my $out = <<'EOF';
use Moose;
has target => ( is => 'rw', isa => 'Str' );
sub read_attribute {
  my $class = shift;
  print $class->target;
}
EOF

  my $res = $tidy->reformat(
    text => $in,
    moosify => 1
  );

  is( $res, $out ) or diag( "$in => $out but was $res" );
}

{
  my $in = <<'EOF';
sub write_attribute {
  my $self = shift;
  $self->{target}++;
}
EOF

  my $out = <<'EOF';
use Moose;
has target => ( is => 'rw', isa => 'Num' );
sub read_attribute {
  my $self = shift;
  $self->target( $self->target + 1 );
}
EOF

  my $res = $tidy->reformat(
    text => $in,
    moosify => 1
  );

  is( $res, $out ) or diag( "$in => $out but was $res" );
}

{
  my $in = <<'EOF';
sub write_attribute {
  my $self = shift;
  $self->{target} .= 'foo';
}
EOF

  my $out = <<'EOF';
use Moose;
has target => ( is => 'rw', isa => 'Num' );
sub read_attribute {
  my $self = shift;
  $self->target( $self->target . 'foo' );
}
EOF

  my $res = $tidy->reformat(
    text => $in,
    moosify => 1
  );

  is( $res, $out ) or diag( "$in => $out but was $res" );
}

=cut
