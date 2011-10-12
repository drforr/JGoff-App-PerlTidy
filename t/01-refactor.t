#!perl -T

use Test::More tests => 5;
use PPI;
use PPI::Dumper;
use Try::Tiny;

BEGIN {
  use_ok( 'JGoff::App::Perltidy' ) || print "Bail out!\n";
}

my $tidy = JGoff::App::Perltidy->new;

#|
#|package Foo;
#|
#|# Comments get properly indented and remain on the original line.
#|# Comments always have at least one space after '#'
#|32 + 2
#|my $first = 17 + ( 9 / 2 ) || $stuff;
#|sub empty { }
#|sub do_something
#|  {
#|    my @rray = []; # Comments after code get one leading space
#|    $first++;
#|    $rray[0] = 92;
#|    for my $stuff ( @rray )
#|      {
#|        $first  = 9;
#|        $second = 32;
#|      }
#|  }

my @test = (
  [ q{package Foo} => q{package Foo}, 'package', {debug => 0} ],
  [ q{package  Foo} => q{package Foo}, 'package with spaces', {debug => 0} ],
  [ qq{package\nFoo} => q{package Foo}, 'package with newline', {debug => 0} ],
  [ qq{package \n  \t Foo} => q{package Foo},
    'package with mixed whitespace', {debug => 0} ]
#  [ q{} => q{}, 'empty', {debug => 0} ],
#  [ q{ } => q{}, 'whitespace', {debug => 0} ],
#  [ q{#foo} => q{# foo}, 'comment', {debug => 0} ],
#  [ q{ #foo} => q{# foo}, 'comment w/ leading ws', {debug => 0} ],
#  [ q{  #foo} => q{# foo}, 'comment w/ more leading ws', {debug => 0} ],
#  [ qq{\n  #foo} => qq{\n# foo}, 'comment w/ even more leading ws', {debug => 0} ],
);

for my $test ( @test ) {
  my ( $in, $out, $name, $debug ) = @$test;
  my $res;
  try {
    $res = $tidy->reformat(
      %$debug,
      text => $in,
      style => 'whitesmiths'
    );

    is( $res, $out, $name ) or do {
      $in =~ s{ }{|}g;
      $out =~ s{ }{|}g;
      $res =~ s{ }{|}g;
      diag(
        "\n---- in ----\n$in\n---- out ----\n$out\n---- res ----\n$res\n----"
      );
    };
  }
  catch {
    my $str = PPI::Dumper->new($tidy->ppi)->string;
    diag(
      "\n---- \$_ ----\n$_\n---- in ----\n$in\n---- Dump ----\n$str\n----"
    );
  };
}

=pod

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
    $in =~ s{ }{|}g;
    $out =~ s{ }{|}g;
    $res =~ s{ }{|}g;
    diag(
      "\n---- in ----\n$in\n---- out ----\n$out\n---- res ----\n$res\n----"
    );
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

=cut

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
