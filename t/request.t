#!/usr/bin/perl -w

# $Id: request.t,v 1.5 2002/06/13 22:09:09 david Exp $

use strict;
use Test::More tests => 17;

BEGIN { use_ok('App::Info::Request') }

ok( my $req = App::Info::Request->new, "New default request" );
isa_ok($req, 'App::Info::Request');
eval {  App::Info::Request->new('foo') };
like( $@,
      qr/^Parameters to App::Info::Request->new\(\) must be a hash reference/,
      "Catch invalid params" );
eval {  App::Info::Request->new({ sigil => 'foo' }) };
like( $@, qr/^Sigil parameter must be one of/, "Catch invalid sigil" );
eval {  App::Info::Request->new({ callback => 'foo' }) };
like( $@, qr/^Callback parameter 'foo' is not a code reference/,
      "Catch invalid callback" );


# Now create a request we can actually use for testing stuff.
my %args = ( message  => 'Enter a value',
             callback => sub { ref $_[0] eq 'HASH' && $_[0]->{val} == 1 },
             sigil    => '%',
             error   => 'Invalid value',
             type     => 'info'
           );

ok( $req = App::Info::Request->new( \%args ), "New custom request" );
is( $req->message, $args{message}, "Check message" );
is( $req->error, $args{error}, "Check error" );
is( $req->sigil, $args{sigil}, "Check sigil" );
is( $req->type, $args{type}, "Check type" );

ok( !$req->callback('foo'),  "Fail callback" );
my $val = { val => 1 };
ok( $req->callback($val), "Succeed callback" );
eval { $req->value([]) };
ok( $@, "Fail sigil check" );
ok( ! $req->value({ val => 0 }), "Fail value" );
ok( $req->value($val), "Succeed value" );
is( $req->value, $val, "Check value" );
