use inc::Module::Install;

name     'Gallery-Remote2';
all_from 'lib/Gallery/Remote2.pm';
license  'perl';

# requires '';

tests 't/*.t';
author_tests 'xt';

build_requires 'Test::More';
auto_set_repository;
use_test_base;
auto_include;
WriteAll;
