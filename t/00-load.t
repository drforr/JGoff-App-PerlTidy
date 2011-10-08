#!perl -T

use Test::More tests => 2;
use PPI;
use PPI::Dumper;

BEGIN {
  use_ok( 'JGoff::App::Perltidy' ) || print "Bail out!\n";
}

my $tidy = JGoff::App::Perltidy->new;

{
  my $in = <<'EOF';
EOF

  my $out = <<'EOF';
EOF

  my $res = $tidy->reformat( text => $in );

  is( $res, $out ) or diag( "$in => $out but was $res" );
}

=pod

#
# Default settings - Deliberately somewhat complex
#
# $x = 0; # Comments as well # sub foo # complex braces as well
#   {
#     my $self = shift;
#     $self->bar( 1 );
#     if ( $conditional ) # ' ' around () here, but
#       {
#       do_stuff(); # nothing around ()
#       }
#   }
#

# $x = 0;
# BEGIN { $short_statement->in_one( 'line' ) }
# sub foo
#   {
#     $bar++;
#     $bar += 32;
#     do { $stuff++ };
#     die "Blah blah" if # Conditionals at EOL,
#       $bar == 1;       # tests below that.
#     this( list => 'of', parameters => [qw( is really-long )],
#           and => 'will', wrap => 'at', 72 => columns );
#     if ( my $condition = stuff( like => this() ) )
#       {
#         $func = 27 / int( $stuff );
#       }
#   }

my @test = (
  [ q{!0} => q{!0} ],
  [ q{! 0} => q{!0} ],
  [ qq{!\t 0} => q{!0} ],

  [ q{+3} => q{+3} ],
  [ q{+ 3} => q{+3} ],
  [ qq{+\n \t 3} => q{+3} ],

  [ q{1=+5} => q{1 = +5} ],
  [ q{1  = +   5} => q{1 = +5} ],

  [ q{-3} => q{-3} ],
  [ q{- 3} => q{-3} ],
  [ qq{-\n \t 3} => q{-3} ],

  [ q{++$x} => q{++$x} ],
  [ q{++ $x} => q{++$x} ],
  [ qq{++   \n \$x} => q{++$x} ],
  [ q{$x++} => q{$x++} ],
  [ qq{\$x\t++} => q{$x++} ],

  [ q{} => q{} ],
  [ q{<} => q{<} ],
  [ q{0<} => q{0 <} ],
  [ q{<0} => q{< 0} ],
  [ q{0<1} => q{0 < 1} ],
  [ q{0 <} => q{0 <} ],
  [ q{0  <} => q{0 <} ],
  [ q{0  <1} => q{0 < 1} ],
  [ q{0  < 1} => q{0 < 1} ],
  [ q{0  <  1} => q{0 < 1} ],
  [ qq{0\n<\n1} => q{0 < 1} ],
  [ qq{0 \n<\n1} => q{0 < 1} ],
  [ qq{0\n < \n1} => q{0 < 1} ],
  [ qq{0 \n < \n1} => q{0 < 1} ],
  [ qq{0\t\n\t<\t\n1} => q{0 < 1} ],

  [ q{0,1} => q{0, 1} ],
  [ q{0=>1} => q{0 => 1} ],
  [ q{$foo->bar} => q{$foo->bar} ],
  [ q{$foo -> bar} => q{$foo->bar} ],

  [ q{0*1/1} => q{0 * 1 / 1} ],
  [ q{+1} => q{+1} ],
  [ q{+  1} => q{+1} ],
  [ qq{\t+  1 } => q{+1} ],
  [ q{-1} => q{-1} ],
  [ q{-  1} => q{-1} ],
  [ qq{\t-  1 } => q{-1} ],
  [ q{$x++} => q{$x++} ],
  [ q{++$x} => q{++$x} ],
  [ q{$x++} => q{$x++} ],
  [ q{$x ++} => q{$x++} ],
  [ qq{\$x ++;\$x\t++} => qq{\$x++;\n\$x++} ],
  [ qq{\$x ++;\n\$x\t++} => qq{\$x++;\n\$x++} ],
  [ qq{\$x ++;\n\$x\t++  ;\n  2+2} => qq{\$x++;\n\$x++;\n2 + 2} ],

  #[ q(sub  foo{}) => qq(sub foo\n  {\n  }) ]
  [ q(sub  foo{$x++}) => qq(sub foo\n  {\n  \$x++\n  }) ]
);

#my $ppi = PPI::Document->new( \"1=-5" );
#my $d = PPI::Dumper->new( $ppi );
#die "\n".$d->string;

for my $test ( @test ) {
  my $res = $tidy->reformat( text => $test->[0] );
  is( $res, $test->[1] ) or do {
    my $ppi = PPI::Document->new( \$test->[0] );
    my $d = PPI::Dumper->new( $ppi );
    my $test_0 = $d->string;
    $ppi = PPI::Document->new( \$test->[1] );
    $d = PPI::Dumper->new( $ppi );
    my $test_1 = $d->string;
    $ppi = PPI::Document->new( \$res );
    $d = PPI::Dumper->new( $ppi );
    my $res_dump = $d->string;

    diag "C<$test->[0]>\nshould be:\nC<$test->[1]>\nbut is:\nC<$res>";
    diag "$test_0\n$test_1\n$res_dump";
  };
}

=cut
