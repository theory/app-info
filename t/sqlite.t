#!/usr/bin/perl -w

# $Id$

use strict;
use Test::More tests => 17;

BEGIN { use_ok('App::Info::RDBMS::SQLite') }

ok( my $sqlite = App::Info::RDBMS::SQLite->new, "Got Object");
isa_ok($sqlite, 'App::Info::RDBMS::SQLite');
isa_ok($sqlite, 'App::Info');
is( $sqlite->key_name, 'SQLite', "Check key name" );


if ($sqlite->installed) {
    ok( $sqlite->installed, "SQLite is installed" );
    is( $sqlite->name, 'SQLite', "Got name" );
    ok( $sqlite->version, "Got version" );
    ok( $sqlite->major_version, "Got major version" );
    ok( defined $sqlite->minor_version, "Got minor version" );
    ok( defined $sqlite->patch_version, "Got patch version" );
    if ($sqlite->bin_dir) {
        ok( $sqlite->bin_dir, "Got bin_dir" );
        ok( $sqlite->lib_dir, "Got lib dir" );
        ok( $sqlite->so_lib_dir, "Got so lib dir" );
        ok( $sqlite->inc_dir, "Got inc dir" );
    } else {
        ok( !$sqlite->bin_dir, "Don't got bin_dir" );
        ok( !$sqlite->lib_dir, "Don't got lib dir" );
        ok( !$sqlite->so_lib_dir, "Don't got so lib dir" );
        ok( !$sqlite->inc_dir, "Don't got inc dir" );
    }
} else {
    ok( !$sqlite->installed, "SQLite is not installed" );
    ok( !$sqlite->name, "Don't got name" );
    ok( !$sqlite->version, "Don't got version" );
    ok( !$sqlite->major_version, "Don't got major version" );
    ok( !$sqlite->minor_version, "Don't got minor version" );
    ok( !$sqlite->patch_version, "Don't got patch version" );
    ok( !$sqlite->lib_dir, "Don't got lib dir" );
    ok( !$sqlite->bin_dir, "Don't got bin_dir" );
    ok( !$sqlite->so_lib_dir, "Don't got so lib dir" );
    ok( !$sqlite->inc_dir, "Don't got inc dir" );
}
ok( $sqlite->home_url, "Get home URL" );
ok( $sqlite->download_url, "Get download URL" );
