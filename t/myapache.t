#!/usr/bin/perl -w

# $Id: myapache.t,v 1.8 2002/07/01 03:46:24 david Exp $

use strict;
use Test::More;

if (exists $ENV{APP_INFO_MAINTAINER}) {
    plan tests => 27;
} else {
    plan skip_all => "maintainer's internal tests.";
}

BEGIN { use_ok('App::Info::HTTPD::Apache') }
BEGIN { use_ok('App::Info::Handler::Carp') }

my @mods = qw(http_core mod_env mod_log_config mod_mime mod_negotiation
              mod_status mod_include mod_autoindex mod_dir mod_cgi mod_asis
              mod_imap mod_actions mod_userdir mod_alias mod_rewrite
              mod_access mod_auth mod_so mod_setenvif mod_ssl mod_perl);

ok( my $apache = App::Info::HTTPD::Apache->new( on_error => 'confess' ),
    "Got Object");
isa_ok($apache, 'App::Info::HTTPD::Apache');
isa_ok($apache, 'App::Info::HTTPD');
isa_ok($apache, 'App::Info');
is( $apache->key_name, 'Apache', "Check key name" );

ok( $apache->installed, "Apache is installed" );
is( $apache->name, "Apache", "Get name" );
if ($apache->httpd_root eq '/usr') {
    # Apple-installed Apache
    is( $apache->version, "1.3.26", "Test Version" );
    is( $apache->major_version, '1', "Test major version" );
    is( $apache->minor_version, '3', "Test minor version" );
    is( $apache->patch_version, '26', "Test patch version" );
    is( $apache->httpd_root, "/usr", "Test httpd root" );
    ok( !$apache->mod_perl, "Test mod_perl" );
    is( $apache->conf_file, "/etc/httpd/httpd.conf", "Test conf file" );
    is( $apache->user, "www", "Test user" );
    is( $apache->group, "www", "Test group" );
    is( $apache->compile_option('DEFAULT_ERRORLOG'), '/var/log/httpd/error_log',
        "Check error log from compile_option()" );
    is( $apache->lib_dir, '/usr/lib', "Test lib dir" );
    is( $apache->bin_dir, '/usr/bin', "Test bin dir" );
    is( $apache->so_lib_dir, '/usr/lib', "Test so lib dir" );
    is( $apache->inc_dir, "/usr/include", "Test inc dir" );
    ok( eq_set( [ $apache->static_mods ], [qw(http_core mod_so)], ),
        "Check static mods" );
    is( $apache->magic_number, '19990320:13', "Test magic number" );
} else {
    is( $apache->version, "1.3.23", "Test Version" );
    is( $apache->major_version, '1', "Test major version" );
    is( $apache->minor_version, '3', "Test minor version" );
    is( $apache->patch_version, '23', "Test patch version" );
    is( $apache->httpd_root, "/usr/local/apache", "Test httpd root" );
    ok( $apache->mod_perl, "Test mod_perl" );
    is( $apache->conf_file, "/usr/local/apache/conf/httpd.conf", "Test conf file" );
    is( $apache->user, "nobody", "Test user" );
    is( $apache->group, "nobody", "Test group" );
    is( $apache->compile_option('DEFAULT_ERRORLOG'), 'logs/error_log',
        "Check error log from compile_option()" );
    is( $apache->lib_dir, '/usr/local/apache/libexec', "Test lib dir" );
    is( $apache->bin_dir, '/usr/local/apache/bin', "Test bin dir" );
    is( $apache->so_lib_dir, '/usr/local/apache/libexec', "Test so lib dir" );
    is( $apache->inc_dir, "/usr/local/apache/include", "Test inc dir" );
    ok( eq_set( scalar $apache->static_mods, \@mods, ), "Check static mods" );
    is( $apache->magic_number, '19990320:11', "Test magic number" );
}

is( $apache->port, '80', "Test port" );
ok( $apache->mod_so, "Test mod_so" );


is( $apache->home_url, 'http://httpd.apache.org/', "Get home URL" );
is( $apache->download_url, 'http://www.apache.org/dist/httpd/',
    "Get download URL" );
