#!/usr/bin/perl -w

# $Id: util.t,v 1.4 2002/06/02 23:45:12 david Exp $

use strict;
use Test::More tests => 10;
use File::Spec::Functions;
use File::Path;

BEGIN { use_ok('App::Info::Util') }

ok( my $util = App::Info::Util->new, "Create Util object" );

# Test inheritance.
my $root = $util->rootdir;
is( $root, File::Spec::Functions::rootdir, "Inherited rootdir()" );
ok( $util->first_dir("C:\\foo", "C:\\bar", $root), "Test first_dir" );

# test first_path(). This is actually platform-dependent -- corrections
# welcome.
if ($^O eq 'MSWin32' or $^O eq 'os2') {
    is( $util->first_path("C:\\foo;C:\\bar;$root"), $root, "Test first_path");
} elsif ($^O eq 'MacOS') {
    is( $util->first_path(":foo,:bar,$root"), $root, "Test first_path");
} elsif ($^O eq 'VMS' or $^O eq 'epoc') {
    ok( ! defined $util->first_path,
        "first_path() returns undef on this platform" );
} else {
    # Assume unix.
    is( $util->first_path("/foo:/bar:$root"), $root, "Test first_path");
}

# Test first_file(). First, create a file to find.
my $tmp_file = $util->catfile($util->tmpdir, 'app-info.tst');
open F, ">$tmp_file" or die "Cannot open $tmp_file: $!\n";
print F "King of the who?";
close F;

# Now find the file.
is( $util->first_file("this.foo", "that.foo", "C:\\foo.tst", $tmp_file),
    $tmp_file, "Test first_file" );

# Now find the same file with first_cat_file().
is( $util->first_cat_file('app-info.tst', $util->path, $util->tmpdir),
    $tmp_file, "Test first_cat_file" );

# And test it again using an array.
is( $util->first_cat_file(['foo.foo', 'bar.foo', 'app-info.tst', 'ick'],
                          $util->path, $util->tmpdir, "C:\\mytemp"),
    $tmp_file, "Test first_cat_file with array" );

# Now find the directory housing the file.
is( $util->first_cat_dir('app-info.tst', $util->path, $util->tmpdir),
    $util->tmpdir, "Test first_cat_file" );

# And test it again using an array.
is( $util->first_cat_dir(['foo.foo', 'bar.foo', 'app-info.tst', 'ick'],
                          $util->path, $util->tmpdir, "C:\\mytemp"),
    $util->tmpdir, "Test first_cat_file with array" );



# Don't forget to delete our temporary file.
rmtree $tmp_file;


