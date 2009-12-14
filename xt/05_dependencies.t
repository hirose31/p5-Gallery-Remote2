# -*- mode: cperl; -*-
use Test::Dependencies
    exclude => [qw(Test::Dependencies Test::Base Test::Perl::Critic
                   Gallery::Remote2)],
    style   => 'light';
ok_dependencies();
