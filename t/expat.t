#!/usr/bin/perl -w

use strict;
use Test::More tests => 17;

BEGIN { use_ok('App::Info::Lib::Expat') }

ok( my $expat = App::Info::Lib::Expat->new, "Got Object");
isa_ok($expat, 'App::Info::Lib::Expat');
isa_ok($expat, 'App::Info::Lib');
isa_ok($expat, 'App::Info');
ok( $expat->name, "Got name" );

if ($expat->installed) {
    ok( $expat->installed, "libexpat is installed" );
    ok( $expat->version, "Got version" );
    ok( $expat->major_version, "Got major version" );
    ok( $expat->minor_version, "Got minor version" );
    ok( $expat->patch_version, "Got patch version" );
} else {
    ok( !$expat->installed, "libexpat is not installed" );
    ok( !$expat->version, "Don't got version" );
    ok( !$expat->major_version, "Don't got major version" );
    ok( !$expat->minor_version, "Don't got minor version" );
    ok( !$expat->patch_version, "Don't got patch version" );
}

# Installation doesn't guarntee lib & inc installation.
$expat->lib_dir; pass("Can call lib_dir");
$expat->bin_dir, pass("Can call bin_dir");
$expat->so_lib_dir; pass("Can call so_lib_dir" );
$expat->inc_dir, pass("Can call inc_dir");

ok( $expat->home_url, "Get home URL" );
ok( $expat->download_url, "Get download URL" );
