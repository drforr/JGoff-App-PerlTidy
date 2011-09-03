#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'JGoff::App::Perltidy' ) || print "Bail out!\n";
}

diag( "Testing JGoff::App::Perltidy $JGoff::App::Perltidy::VERSION, Perl $], $^X" );
