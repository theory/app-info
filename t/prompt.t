#!/usr/bin/perl -w

# $Id: prompt.t,v 1.2 2002/06/12 18:18:36 david Exp $

# Make sure that we can use the stuff that's in our local lib directory.
BEGIN {
    if( $ENV{PERL_CORE} ) {
        chdir 't' if -d 't';
        @INC = ('../lib', 'lib');
    } else {
        unshift @INC, 't/lib', '../t/lib';
    }
}
chdir 't';

use strict;
use Test::More tests => 14;
use TieOut;
use File::Spec::Functions qw(:ALL);


# Set up an App::Info subclass to ruin.
package App::Info::Category::FooApp;
use App::Info;
use strict;
use vars qw(@ISA);
@ISA = qw(App::Info);
sub key_name { 'FooApp' }

sub inc_dir { shift->unknown('binary', sub { -e $_[0] }) }
sub lib_dir { shift->confirm('executable', '/bin/sh', sub { -x $_[0] }) }

package main;

BEGIN { use_ok('App::Info::Handler::Prompt') }

ok( my $p = App::Info::Handler::Prompt->new, "Create prompt" );
ok( my $app = App::Info::Category::FooApp->new( on_unknown => $p,
                                                on_confirm => $p),
    "Set up for unknown" );

# Tie off the file handles.
my $stdout = tie *STDOUT, 'TieOut' or die "Cannot tie STDOUT: $!\n";
my $stdin = tie *STDIN, 'TieOut' or die "Cannot tie STDIN: $!\n";

# Set up a couple of answers.
print STDIN 'foo3424324';
print STDIN tmpdir;
# Trigger the unknown handler.
my $dir = $app->inc_dir;

# Check the result and the output.
is( $dir, tmpdir, "Got tmpdir" );
my $expected = qq{Could not determine FooApp binary
Please enter a valid FooApp binary Invalid value: 'foo3424324'
Could not determine FooApp binary
Please enter a valid FooApp binary };
is ($stdout->read, $expected, "Check unknown prompt" );

# Okay, now we'll test the confirm handler.
ok( $app = App::Info::Category::FooApp->new( on_unknown => $p,
                                                on_confirm => $p),
    "Set up for first confirm" );

# Start with an affimative answer.
print STDIN "yes\n";
my $sh = $app->lib_dir;
is($sh, '/bin/sh', "Got /bin/sh" );
$expected = qq{Found FooApp executable value '/bin/sh'
Is this correct? [y] };
is( $stdout->read, $expected, "Check first confirm prompt" );

# Now try the default answer (which is affirmative).
ok( $app = App::Info::Category::FooApp->new( on_unknown => $p,
                                                on_confirm => $p),
    "Set up for second confirm" );
print STDIN "\n";
$sh = $app->lib_dir;
is($sh, '/bin/sh', "Got /bin/sh" );
is( $stdout->read, $expected, "Check second confirm prompt" );

# Now try a negative answer.
ok( $app = App::Info::Category::FooApp->new( on_unknown => $p,
                                                on_confirm => $p),
    "Set up for second confirm" );
# Set up the answers.
print STDIN "no\n";
print STDIN "foo123123\n";
print STDIN "/bin/sh\n";
# Set it off.
$sh = $app->lib_dir;
# Check the answer.
is($sh, '/bin/sh', "Got /bin/sh" );
# Check the output.
$expected = qq{Found FooApp executable value '/bin/sh'
Is this correct? [y] Enter a new value Invalid value: 'foo123123'
Enter a new value };
is( $stdout->read, $expected, "Check third confirm prompt" );

undef $stdout;
undef $stdin;
untie *STDOUT;
untie *STDIN;

if ($ENV{APP_INFO_MAINTAINER}) {
    # Interactive tests for maintainer only.
    $app = App::Info::Category::FooApp->new( on_unknown => $p,
                                             on_confirm => $p);
    $app->inc_dir;
    $app->lib_dir;
}

__END__
