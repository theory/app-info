#!/usr/bin/perl -w

# $Id: apache.t,v 1.6 2002/06/03 23:49:18 david Exp $

use strict;
use Test::More tests => 26;

BEGIN { use_ok('App::Info::HTTPD::Apache') }

ok( my $apache = App::Info::HTTPD::Apache->new, "Got Object");
isa_ok($apache, 'App::Info::HTTPD::Apache');
isa_ok($apache, 'App::Info');

if ($apache->installed) {
    ok( $apache->installed, "Apache is installed" );
    ok( $apache->name, "Got name" );
    ok( $apache->version, "Got version" );
    ok( $apache->major_version, "Got major version" );
    ok( $apache->minor_version, "Got minor version" );
    ok( $apache->patch_version, "Got patch version" );
    ok( $apache->httpd_root, "Got httpd root" );
    ok( $apache->magic_number, "Got magic number" );
    $apache->mod_so;
    pass("Can get mod_so");
    $apache->mod_perl;
    pass("Can get mod_perl");
    is( ref $apache->static_mods, 'ARRAY', "Got static mods" );
    ok( $apache->compile_option('DEFAULT_ERRORLOG'), "Got compile option" );

    # We should be able to find httpd.conf.
    ok( $apache->conf_file, "Got Apache conf file" );
    ok( $apache->user, "Got Apache user." );
    ok( $apache->group, "Got Apache group." );
    ok( $apache->port, "Got Apache port." );
} else {
    ok( !$apache->installed, "Apache is not installed" );
    ok( !$apache->name, "Don't got name" );
    ok( !$apache->version, "Don't got version" );
    ok( !$apache->major_version, "Don't got major version" );
    ok( !$apache->minor_version, "Don't got minor version" );
    ok( !$apache->patch_version, "Don't got patch version" );
    ok( !$apache->httpd_root, "Don't got httpd root" );
    ok( !$apache->magic_number, "Don't got magic number" );
    ok( !$apache->mod_so, "Don't got mod_so" );
    ok( !$apache->mod_perl, "Don't got mod_perl" );
    ok( !$apache->static_mods, "Don't got static mods" );
    ok( !$apache->compile_option('DEFAULT_ERRORLOG'),
        "Don't got compile option" );
    ok( !$apache->conf_file, "Don't got Apache conf file" );
    ok( !$apache->user, "Don't got Apache user." );
    ok( !$apache->group, "Don't got Apache group." );
    ok( !$apache->port, "Don't got Apache port." );
}

# Installation doesn't guarantee lib & inc installation.
$apache->lib_dir; pass("Can call lib_dir");
$apache->bin_dir, pass("Can call bin_dir");
$apache->so_lib_dir; pass("Can call so_lib_dir" );
$apache->inc_dir, pass("Can call inc_dir");

ok( $apache->home_url, "Get home URL" );
ok( $apache->download_url, "Get download URL" );
