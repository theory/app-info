#!/usr/bin/perl -w

# $Id: myapache.t,v 1.1 2002/06/03 17:59:17 david Exp $

use strict;
use Test::More;

if (exists $ENV{APP_INFO_MAINTAINER}) {
    plan tests => 21;
} else {
    plan skip_all => "maintainer's internal tests.";
}

BEGIN { use_ok('App::Info::HTTPD::Apache') }

my @mods = qw(http_core mod_env mod_log_config mod_mime mod_negotiation
              mod_status mod_include mod_autoindex mod_dir mod_cgi mod_asis
              mod_imap mod_actions mod_userdir mod_alias mod_rewrite
              mod_access mod_auth mod_so mod_setenvif mod_ssl mod_perl);

ok( my $apache = App::Info::HTTPD::Apache->new, "Got Object");
isa_ok($apache, 'App::Info::HTTPD::Apache');
isa_ok($apache, 'App::Info::HTTPD');
isa_ok($apache, 'App::Info');
ok( $apache->installed, "Apache is installed" );
is( $apache->name, "Apache", "Get name" );
is( $apache->version, "1.3.23", "Test Version" );
is( $apache->major_version, '1', "Test major version" );
is( $apache->minor_version, '3', "Test minor version" );
is( $apache->patch_version, '23', "Test patch version" );
is( $apache->httpd_root, "/usr/local/apache", "Test httpd root" );
is( $apache->magic_number, '19990320:11', "Test magic number" );
ok( $apache->mod_so, "Test mod_so" );
ok( $apache->mod_perl, "Test mod_perl" );
eq_set( scalar $apache->static_mods, \@mods, "Check static mods" );
is( $apache->compile_option('SERVER_CONFIG_FILE'), 'conf/httpd.conf',
    "Check config file [compile_option()]" );

is( $apache->lib_dir, '/usr/local/apache/libexec', "Test lib dir" );
is( $apache->bin_dir, '/usr/local/apache/bin', "Test bin dir" );
is( $apache->so_lib_dir, '/usr/local/apache/libexec', "Test so lib dir" );
is( $apache->inc_dir, "/usr/local/apache/include", "Test inc dir" );
is( $apache->home_url, 'http://httpd.apache.org/', "Get home URL" );
is( $apache->download_url, 'http://www.apache.org/dist/httpd/',
    "Get download URL" );
