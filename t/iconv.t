#!/usr/bin/perl -w

use strict;
use Test::More tests => 17;

BEGIN { use_ok('App::Info::Lib::Iconv') }

ok( my $iconv = App::Info::Lib::Iconv->new, "Got Object");
isa_ok($iconv, 'App::Info::Lib::Iconv');
isa_ok($iconv, 'App::Info');
is( $iconv->name, 'libiconv', "Check name" );
is( $iconv->key_name, 'libiconv', "Check key name" );

if ($iconv->installed) {
    ok( $iconv->installed, "libiconv is installed" );
    if ($iconv->version) {
        # I really wish there were a better way to ensure that I had a version
        # number. Meanwhile, this should allow all of the tests to pass.
        ok( $iconv->version, "Got version" );
        ok( $iconv->major_version, "Got major version" );
        ok( defined $iconv->minor_version, "Got minor version" );
    } else {
        ok( !$iconv->version, "Don't got version" );
        ok( !$iconv->major_version, "Don't got major version" );
        ok( !$iconv->minor_version, "Don't got minor version" );
    }
    ok( !$iconv->patch_version, "There is no patch version" );
} else {
    ok( !$iconv->installed, "libiconv is not installed" );
    ok( !$iconv->version, "Don't got version" );
    ok( !$iconv->major_version, "Don't got major version" );
    ok( !$iconv->minor_version, "Don't got minor version" );
    ok( !$iconv->patch_version, "Don't got patch version" );
}

# Installation doesn't guarntee lib & inc installation.
$iconv->lib_dir; pass("Can call lib_dir");
$iconv->bin_dir, pass("Can call bin_dir");
$iconv->so_lib_dir; pass("Can call so_lib_dir" );
$iconv->inc_dir, pass("Can call inc_dir");

ok( $iconv->home_url, "Get home URL" );
ok( $iconv->download_url, "Get download URL" );
