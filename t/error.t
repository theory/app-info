#!/usr/bin/perl -w

# $Id: error.t,v 1.1 2002/06/05 20:59:47 david Exp $

use strict;
use Test::More tests => 28;

our $msg = "Error retrieving version";

# Set up an App::Info subclass to ruin.
package App::Info::Category::FooApp;
use App::Info;
use strict;
use vars qw(@ISA);
@ISA = qw(App::Info);

sub version { shift->error($msg) }

package main;

# Try confess first.
ok( my $app = App::Info::Category::FooApp->new( error_level => 'confess'),
    "Set up for confess" );
eval { $app->version };
ok( my $err = $@, "Get confess" );
like( $err, qr/^Error retrieving version/, "Starts with confess message" );
like( $err, qr/called at t\/error\.t line/, "Confess has stack trace" );

# Now try croak.
ok( $app = App::Info::Category::FooApp->new( error_level => 'croak'),
    "Set up for croak" );
eval { $app->version };
ok( $err = $@, "Get croak" );
like( $err, qr/^Error retrieving version/, "Starts with croak message" );
unlike( $err, qr/called at t\/error\.t line/, "Croak has no stack trace" );

# Now die.
ok( $app = App::Info::Category::FooApp->new( error_level => 'die'),
    "Set up for die" );
eval { $app->version };
ok( $err = $@, "Get die" );
like( $err, qr/^Error retrieving version/, "Starts with die message" );
unlike( $err, qr/called at t\/error\.t line/, "Die has no stack trace" );

# Set up to capture warnings.
$SIG{__WARN__} = sub { $err = shift };

# Cluck.
ok( $app = App::Info::Category::FooApp->new( error_level => 'cluck'),
    "Set up for cluck" );
$app->version;
like( $err, qr/^Error retrieving version/, "Starts with cluck message" );
like( $err, qr/called at t\/error\.t line/, "Cluck as stack trace" );
is( $app->last_error, $msg, "Compare cluck with last_error" );

# Carp.
ok( $app = App::Info::Category::FooApp->new( error_level => 'carp'),
    "Set up for carp" );
$app->version;
like( $err, qr/^Error retrieving version/, "Starts with carp message" );
unlike( $err, qr/called at t\/error\.t line/, "Carp has no stack trace" );
is( $app->last_error, $msg, "Compare carp with last_error" );

# Warn.
ok( $app = App::Info::Category::FooApp->new( error_level => 'warn'),
    "Set up for warn" );
$app->version;
like( $err, qr/^Error retrieving version/, "Starts with warn message" );
unlike( $err, qr/called at t\/error\.t line/, "Warn has no stack trace" );
is( $app->last_error, $msg, "Compare warn with last_error" );

# Silent.
$err = undef;
ok( $app = App::Info::Category::FooApp->new( error_level => 'silent'),
    "Set up for silent" );
$app->version;
ok( ! defined $err, "Error not defined" );
ok( $err = $app->last_error, "Grab last silent error" );
like( $err, qr/^Error retrieving version/, "Starts with silent message" );


