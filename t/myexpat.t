#!/usr/bin/perl -w

# $Id: myexpat.t,v 1.2 2002/06/05 23:50:42 david Exp $

use strict;
use Test::More;

if (exists $ENV{APP_INFO_MAINTAINER}) {
    plan tests => 16;
} else {
    plan skip_all => "maintainer's internal tests.";
}

BEGIN { use_ok('App::Info::Lib::Expat') }

ok( my $expat = App::Info::Lib::Expat->new( error_level => 'confess' ),
    "Got Object");
isa_ok($expat, 'App::Info::Lib::Expat');
isa_ok($expat, 'App::Info::Lib');
isa_ok($expat, 'App::Info');
ok( $expat->installed, "libexpat is installed" );
is( $expat->name, "Expat", "Get name" );
is( $expat->version, "1.95.2", "Test Version" );
is( $expat->major_version, '1', "Test major version" );
is( $expat->minor_version, '95', "Test minor version" );
is( $expat->patch_version, '2', "Test patch version" );
is( $expat->lib_dir, '/usr/local/lib', "Test lib dir" );
ok( ! defined $expat->bin_dir, "Test bin dir" );
is( $expat->so_lib_dir, '/sw/lib', "Test so lib dir" );
is( $expat->inc_dir, "/usr/local/include", "Test inc dir" );
is( $expat->home_url, 'http://expat.sourceforge.net/', "Get home URL" );
is( $expat->download_url, 'http://sourceforge.net/projects/expat/',
    "Get download URL" );
