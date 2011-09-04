#!perl -T

use Test::More tests => 13;
use PPI;
use PPI::Dumper;

BEGIN {
    use_ok( 'JGoff::App::Perltidy' ) || print "Bail out!\n";
}

my $tidy = JGoff::App::Perltidy->new;

#
# Default settings - Deliberately somewhat complex
#
# $x = 0;
# sub foo
#   {
#     my $self = shift;
#     $self->bar( 1 );
#   }
#

my @test = (
  [ '<' => '<' ],
  [ '0<' => '0 <' ],
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
);

for my $test ( @test ) {
  is( $tidy->reformat( text => $test->[0] ), $test->[1] ) or do {
    my $ppi = PPI::Document->new( \$test->[0] );
    my $d = PPI::Dumper->new( $ppi );
    diag( "Dump( '$test->[0]' ): " . $d->string );
  };
}

my @operator = (
  'lt',
  '<=', 'le',
  '>', 'gt',
  '>=', 'ge',
  '==', 'eq',
  '!=', 'ne',
  '&', '&&', 'and',
  '|', '||', 'or',
  '+=', '-=', '*=', '/=',
  '*', '/', '%',
);
