#!perl -T

use Test::More tests => 22;
use PPI;
use PPI::Dumper;

BEGIN {
    use_ok( 'JGoff::App::Perltidy' ) || print "Bail out!\n";
}

my $tidy = JGoff::App::Perltidy->new;

#
# Default settings - Deliberately somewhat complex
#
# $x = 0; # Comments as well
# sub foo # complex braces as well
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
#  [ '0 ++' => '0++' ],
);

for my $test ( @test ) {
  is( $tidy->reformat( text => $test->[0] ), $test->[1] ) or do {
$tidy->DEBUG(1) if $test->[0] eq '+  1';
    my $ppi = PPI::Document->new( \$test->[0] );
    my $d = PPI::Dumper->new( $ppi );
    diag( "Dump( '$test->[0]' ): " . $d->string );
  };
}
