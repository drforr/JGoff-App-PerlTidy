use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'JGoff::App::Perltidy',
    AUTHOR              => q{Jeffrey Goff <jgoff@cpan.org>},
    VERSION_FROM        => 'lib/JGoff/App/Perltidy.pm',
    ABSTRACT_FROM       => 'lib/JGoff/App/Perltidy.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'PPI' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'JGoff-App-Perltidy-*' },
);
