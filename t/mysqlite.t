#!/usr/bin/perl -w

# $Id$

use strict;
use Test::More;

if (exists $ENV{APP_INFO_MAINTAINER}) {
    plan tests => 17;
} else {
    plan skip_all => "maintainer's internal tests.";
}

BEGIN { use_ok('App::Info::RDBMS::SQLite') }
BEGIN { use_ok('App::Info::Handler::Carp') }

ok( my $pg = App::Info::RDBMS::SQLite->new( on_error => 'confess' ),
    "Got Object");
isa_ok($pg, 'App::Info::RDBMS::SQLite');
isa_ok($pg, 'App::Info::RDBMS');
isa_ok($pg, 'App::Info');
is( $pg->key_name, 'SQLite', "Check key name" );

ok( $pg->installed, "SQLite is installed" );
is( $pg->name, "SQLite", "Get name" );
is( $pg->version, "3.0.8", "Test Version" );
is( $pg->major_version, '3', "Test major version" );
is( $pg->minor_version, '0', "Test minor version" );
is( $pg->patch_version, '8', "Test patch version" );
is( $pg->lib_dir, '/usr/local/lib', "Test lib dir" );
is( $pg->bin_dir, '/usr/local/bin', "Test bin dir" );
is( $pg->so_lib_dir, '/usr/local/lib', "Test so lib dir" );
is( $pg->inc_dir, "/usr/local/include", "Test inc dir" );
is( $pg->home_url, 'http://www.sqlite.org/', "Get home URL" );
is( $pg->download_url, 'http://www.sqlite.org/download.html',
    "Get download URL" );
