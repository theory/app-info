#!/usr/bin/perl -w

# $Id$

use strict;
use Test::More tests => 18;

BEGIN { use_ok('App::Info::RDBMS::PostgreSQL') }

ok( my $pg = App::Info::RDBMS::PostgreSQL->new, "Got Object");
isa_ok($pg, 'App::Info::RDBMS::PostgreSQL');
isa_ok($pg, 'App::Info');
is( $pg->key_name, 'PostgreSQL', "Check key name" );

if ($pg->installed) {
    ok( $pg->installed, "PostgreSQL is installed" );
    ok( $pg->name, "Got name" );
    ok( $pg->version, "Got version" );
    ok( $pg->major_version, "Got major version" );
    ok( defined $pg->minor_version, "Got minor version" );
    ok( defined $pg->patch_version, "Got patch version" );
    ok( $pg->lib_dir, "Got lib dir" );
    ok( $pg->bin_dir, "Got bin_dir" );
    ok( $pg->so_lib_dir, "Got so lib dir" );
    ok( $pg->inc_dir, "Got inc dir" );
    ok( defined $pg->configure, "Got configure" );
} else {
    ok( !$pg->installed, "PostgreSQL is not installed" );
    ok( !$pg->name, "Don't got name" );
    ok( !$pg->version, "Don't got version" );
    ok( !$pg->major_version, "Don't got major version" );
    ok( !$pg->minor_version, "Don't got minor version" );
    ok( !$pg->patch_version, "Don't got patch version" );
    ok( !$pg->lib_dir, "Don't got lib dir" );
    ok( !$pg->bin_dir, "Don't got bin_dir" );
    ok( !$pg->so_lib_dir, "Don't got so lib dir" );
    ok( !$pg->inc_dir, "Don't got inc dir" );
    ok( !$pg->configure, "Don't got configure" );
}
ok( $pg->home_url, "Get home URL" );
ok( $pg->download_url, "Get download URL" );
