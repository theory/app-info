#!/usr/bin/perl -w

# $Id: myiconv.t,v 1.8 2003/12/11 20:47:22 david Exp $

use strict;
use Test::More;

if (exists $ENV{APP_INFO_MAINTAINER}) {
    plan tests => 17;
} else {
    plan skip_all => "maintainer's internal tests.";
}

BEGIN { use_ok('App::Info::Lib::Iconv') }
BEGIN { use_ok('App::Info::Handler::Carp') }

ok( my $iconv = App::Info::Lib::Iconv->new( on_error => 'confess' ),
    "Got Object");
isa_ok($iconv, 'App::Info::Lib::Iconv');
isa_ok($iconv, 'App::Info::Lib');
isa_ok($iconv, 'App::Info');
is( $iconv->key_name, 'libiconv', "Check key name" );

ok( $iconv->installed, "libiconv is installed" );
is( $iconv->name, "libiconv", "Get name" );
is( $iconv->version, "1.9", "Test Version" );
is( $iconv->major_version, '1', "Test major version" );
is( $iconv->minor_version, '9', "Test minor version" );
ok( ! defined $iconv->patch_version, "Test patch version" );
is( $iconv->lib_dir, '/usr/lib', "Test lib dir" );
is( $iconv->bin_dir, '/usr/bin', "Test bin dir" );
is( $iconv->so_lib_dir, '/usr/lib', "Test so lib dir" );
is( $iconv->inc_dir, "/usr/include", "Test inc dir" );
is( $iconv->home_url, 'http://www.gnu.org/software/libiconv/', "Get home URL" );
is( $iconv->download_url, 'ftp://ftp.gnu.org/pub/gnu/libiconv/',
    "Get download URL" );
