#!/usr/bin/perl -w

# $Id: print.t,v 1.1 2002/06/11 23:56:44 david Exp $

use strict;
use Test::More tests => 11;
use File::Spec::Functions qw(:ALL);
use File::Path;
use FileHandle;

# This is the message we'll test for.
my $msg = "Run away! Run away!";

# Set up an App::Info subclass to ruin.
package App::Info::Category::FooApp;
use App::Info;
use strict;
use vars qw(@ISA);
@ISA = qw(App::Info);

sub version { shift->info($msg) }

package main;

BEGIN { use_ok('App::Info::Handler::Print') }

my $file = catfile tmpdir, 'app-info-print.tst';

# Try a file handle.
my $fh = FileHandle->new(">$file");
ok( my $p = App::Info::Handler::Print->new($fh), "Create with file handle" );
ok( my $app = App::Info::Category::FooApp->new( on_info => $p),
    "Set up for file handle" );
$app->version;
$fh->close;
chk_file($file, "Check file handle output", "$msg\n");

# Try appending.
$fh = FileHandle->new(">>$file");
ok( $p = App::Info::Handler::Print->new($fh), "Create with append" );
ok( $app->on_info($p), "Set append handler" );
$app->version;
$fh->close;
chk_file($file, "Check append output", "$msg\n$msg\n");

# Try a file handle glob.
open F, ">$file" or die "Cannot open $file: $!\n";
ok( $p = App::Info::Handler::Print->new(\*F), "Create with glob" );
ok( $app->on_info($p), "Set glob handler" );
$app->version;
close F or die "Cannot close $file: $!\n";
chk_file($file, "Check glob output", "$msg\n");

# Try an invalid argument.
eval { App::Info::Handler::Print->new('foo') };
like( $@, qr/^Invalid argument to new\(\): 'foo'/, "Check invalid argument" );

# Delete the test file.
rmtree $file;

sub chk_file {
    my ($file, $tst_name, $val) = @_;
    open F, "<$file" or die "Cannot open $file: $!\n";
    local $/;
    is(<F>, $val || "$msg\n", $tst_name);
    close F or die "Cannot close $file: $!\n";
}

__END__

# Start by testing STDERR.
ok( my $p = App::Info::Handler::Print->new, "Create default" );
close STDERR or die "Cannot close STDERR: $!\n";
stderr(sub { $p->handler($req) }, "Check default's output" );
ok( $p = App::Info::Handler::Print->new('stderr'), "Create stderr" );
stderr(sub { $p->handler($req) }, "Check stderr's output" );

# Now test STDOUT.
close STDERR or die "Cannot close STDOUT: $!\n";
ok( $p = App::Info::Handler::Print->new('stdout'), "Create stdout" );
stderr(sub { $p->handler($req) }, "Check stdout's output" );

sub stderr {
    my ($code, $name) = @_;
    open STDERR, ">$stderr" or die "Cannot open $stderr: $!\n";
    $code->();
    close STDERR or die "Cannot close $stderr: $!\n";
    open STDERR, "<$stderr" or die "Cannot open $stderr: $!\n";
    is(<STDERR>, $msg, $name );
    close STDERR or die "Cannot close $stderr: $!\n";
}

sub stdout {
    my ($code, $name) = @_;
    open STDOUT, ">$stdout" or die "Cannot open $stdout: $!\n";
    $code->();
    close STDOUT or die "Cannot close $stdout: $!\n";
    open STDOUT, "<$stdout" or die "Cannot open $stdout: $!\n";
    is(<STDOUT>, $msg, $name );
    close STDOUT or die "Cannot close $stdout: $!\n";
}

__END__
