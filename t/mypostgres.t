#!/usr/bin/perl -w

# $Id: mypostgres.t,v 1.5 2002/06/17 19:27:14 david Exp $

use strict;
use Test::More;

if (exists $ENV{APP_INFO_MAINTAINER}) {
    plan tests => 17;
} else {
    plan skip_all => "maintainer's internal tests.";
}

BEGIN { use_ok('App::Info::RDBMS::PostgreSQL') }
BEGIN { use_ok('App::Info::Handler::Carp') }

ok( my $pg = App::Info::RDBMS::PostgreSQL->new( on_error => 'confess' ),
    "Got Object");
isa_ok($pg, 'App::Info::RDBMS::PostgreSQL');
isa_ok($pg, 'App::Info::RDBMS');
isa_ok($pg, 'App::Info');
is( $pg->key_name, 'PostgreSQL', "Check key name" );

ok( $pg->installed, "PostgreSQL is installed" );
is( $pg->name, "PostgreSQL", "Get name" );
is( $pg->version, "7.2.1", "Test Version" );
is( $pg->major_version, '7', "Test major version" );
is( $pg->minor_version, '2', "Test minor version" );
is( $pg->patch_version, '1', "Test patch version" );
is( $pg->lib_dir, '/usr/local/pgsql/lib', "Test lib dir" );
is( $pg->bin_dir, '/usr/local/pgsql/bin', "Test bin dir" );
is( $pg->so_lib_dir, '/usr/local/pgsql/lib', "Test so lib dir" );
is( $pg->inc_dir, "/usr/local/pgsql/include", "Test inc dir" );
is( $pg->home_url, 'http://www.postgresql.org/', "Get home URL" );
is( $pg->download_url, 'http://www.ca.postgresql.org/sitess.html',
    "Get download URL" );
