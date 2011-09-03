#!perl -T

use Test::More tests => 1;

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

{
  is( $tidy->reformat( text => << 'EOF' ), << 'EOF' );
$x=0
EOF
$x = 0
EOF
}
