use 5.012;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'XML::Insert',
    license             => 'Artistic_2_0',
    dist_author         => q{Jeremy Volkening <jdv@base2bio.com>},
    dist_version_from   => 'lib/XML/Insert.pm',
    abstract_from       => 'lib/XML/Insert.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'XML::Parser' => 0,
    },
    add_to_cleanup     => [ 'XML-Insert-*' ],
);

$builder->create_build_script();
