#!perl -T

use Test::More tests => 34;
use PPI;
use PPI::Dumper;

BEGIN {
  use_ok( 'JGoff::App::Perltidy' ) || print "Bail out!\n";
}

my $tidy = JGoff::App::Perltidy->new;

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

my @test = (
  [ '' => '' ],
  [ '<' => '<' ],
  [ '0<' => '0 <' ],
  [ '<0' => '< 0' ],
  [ '0<1' => '0 < 1' ],
  [ '0 <' => '0 <' ],
  [ '0  <' => '0 <' ],
  [ '0  <1' => '0 < 1' ],
  [ '0  < 1' => '0 < 1' ],
  [ '0  <  1' => '0 < 1' ],
  [ "0\n<\n1" => '0 < 1' ],
  [ "0 \n<\n1" => '0 < 1' ],
  [ "0\n < \n1" => '0 < 1' ],
  [ "0 \n < \n1" => '0 < 1' ],
  [ "0\t\n\t<\t\n1" => '0 < 1' ],

  [ '0,1' => '0, 1' ],
  [ '0=>1' => '0 => 1' ],
  [ '$foo->bar' => '$foo->bar' ],
  [ '$foo -> bar' => '$foo->bar' ],

  [ '0*1/1' => '0 * 1 / 1' ],
  [ '+1' => '+1' ],
  [ '+  1' => '+1' ],
  [ "\t+  1 " => '+1' ],
  [ '-1' => '-1' ],
  [ '-  1' => '-1' ],
  [ "\t-  1 " => '-1' ],
  [ '0++' => '0++' ],
  [ '++0' => '++0' ],
  [ '0++' => '0++' ],
  [ '0 ++' => '0++' ],
  [ "0 ++;1\t++" => "0++;\n1++" ],
  [ "0 ++;\n1\t++" => "0++;\n1++" ],
  [ "0 ++;\n1\t++  ;\n  2+2" => "0++;\n1++;\n2 + 2" ],
);

#my $ppi = PPI::Document->new( \"(1,2)" );
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
