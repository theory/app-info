#!/usr/bin/perl -w

# $Id$

use strict;
use Test::More tests => 17;
use constant SKIP => 13;

##############################################################################
# Make sure that we can use the stuff that's in our local lib directory.
BEGIN {
    if( $ENV{PERL_CORE} ) {
        chdir 't' if -d 't';
        @INC = ('../lib', 'lib');
    } else {
        unshift @INC, 't/lib', 'lib';
    }
}
chdir 't';
use EventTest;

##############################################################################
BEGIN { use_ok('App::Info::RDBMS::SQLite') }

# Test info events.
ok( my $info = EventTest->new, "Create info EventTest" );
ok( my $pg = App::Info::RDBMS::SQLite->new( on_info => $info ),
    "Got Object");
is( $info->message, "Looking for sqlite3 or sqlite",
    "Check constructor info" );

SKIP: {
    # Skip tests?
    skip "SQLite not installed", SKIP unless $pg->installed;

    # Check version.
    ok( $pg = App::Info::RDBMS::SQLite->new( on_info => $info ),
        "Got Object 2");
    $info->message; # Throw away constructor message.
    $pg->version;
    like($info->message, qr/^Executing `".*sqlite3?(.exe)?" -version`$/,
        "Check version info" );

    $pg->version;
    ok( ! defined $info->message, "No info" );
    $pg->major_version;
    ok( ! defined $info->message, "Still No info" );

    # Check major version.
    ok( $pg = App::Info::RDBMS::SQLite->new( on_info => $info ),
        "Got Object 3");
    $info->message; # Throw away constructor message.
    $pg->major_version;
    like($info->message, qr/^Executing `".*sqlite3?(.exe)?" -version`$/,
        "Check major info" );

    # Check minor version.
    ok( $pg = App::Info::RDBMS::SQLite->new( on_info => $info ),
        "Got Object 4");
    $info->message; # Throw away constructor message.
    $pg->minor_version;
    like($info->message, qr/^Executing `".*sqlite3?(.exe)?" -version`$/,
        "Check minor info" );

    # Check patch version.
    ok( $pg = App::Info::RDBMS::SQLite->new( on_info => $info ),
        "Got Object 5");
    $info->message; # Throw away constructor message.
    $pg->patch_version;
    like($info->message, qr/^Executing `".*sqlite3?(.exe)?" -version`$/,
        "Check patch info" );

    # Check dir methods.
    $pg->inc_dir;
    like( $info->message, qr/^Searching for include directory$/,
        "Check inc info" );
    $pg->lib_dir;
    like( $info->message, qr/^Searching for library directory$/,
          "Check lib info" );
    $pg->so_lib_dir;
    like( $info->message, qr/^Searching for shared object library directory$/,
        "Check so lib info" );
}

__END__
