#!/usr/bin/perl -w

# $Id: prompt.t,v 1.1 2002/06/12 04:16:57 david Exp $

# Make sure that we can use the stuff that's in our local lib directory.
BEGIN {
    if( $ENV{PERL_CORE} ) {
        chdir 't' if -d 't';
        @INC = ('../lib', 'lib');
    }
    else {
        unshift @INC, 't/lib';
    }
}
chdir 't';

use strict;
use Test::More tests => 3;
use TieOut;


# Set up an App::Info subclass to ruin.
package App::Info::Category::FooApp;
use App::Info;
use strict;
use vars qw(@ISA);
@ISA = qw(App::Info);
sub key_name { 'FooApp' }

sub inc_dir { shift->unknown('binary', sub { -e $_[0] }) }

package main;

BEGIN { use_ok('App::Info::Handler::Prompt') }

ok( my $p = App::Info::Handler::Prompt->new, "Create prompt" );
ok( my $app = App::Info::Category::FooApp->new( on_unknown => $p),
    "Set up for unknown" );

$app->inc_dir if $ENV{APP_INFO_MAINTAINER}

__END__
