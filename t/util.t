#!/usr/bin/perl -w

# $Id: util.t,v 1.6 2002/06/03 18:43:16 david Exp $

use strict;
use Test::More tests => 17;
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
print F "King of the who?\nWell, I didn't vote for ya.";
close F;

# Now find the file.
is( $util->first_file("this.foo", "that.foo", "C:\\foo.tst", $tmp_file),
    $tmp_file, "Test first_file" );

# Now find the same file with first_cat_path().
is( $util->first_cat_path('app-info.tst', $util->path, $util->tmpdir),
    $tmp_file, "Test first_cat_path" );

# And test it again using an array.
is( $util->first_cat_path(['foo.foo', 'bar.foo', 'app-info.tst', 'ick'],
                          $util->path, $util->tmpdir, "C:\\mytemp"),
    $tmp_file, "Test first_cat_path with array" );

# Now find the directory housing the file.
is( $util->first_cat_dir('app-info.tst', $util->path, $util->tmpdir),
    $util->tmpdir, "Test first_cat_path" );

# And test it again using an array.
is( $util->first_cat_dir(['foo.foo', 'bar.foo', 'app-info.tst', 'ick'],
                          $util->path, $util->tmpdir, "C:\\mytemp"),
    $util->tmpdir, "Test first_cat_path with array" );

# Look for stuff in the file.
is( $util->search_file($tmp_file, qr/(of.*\?)/), 'of the who?',
    "Find 'of the who?'" );

# Look for a couple of things at once.
is_deeply( [$util->search_file($tmp_file, qr/(of\sthe)\s+(who\?)/)],
           ['of the', 'who?'], "Find 'of the' and 'who?'" );

ok( ! defined  $util->search_file($tmp_file, qr/(ick)/),
    "Find nothing" );

# Look for a couple of things.
is_deeply([$util->multi_search_file($tmp_file, qr/(of.*\?)/, qr/(di.*e)/)],
          ['of the who?', "didn't vote"], "Find a couple" );

# Look for a couple of things on the same line.
is_deeply([$util->multi_search_file($tmp_file, qr/(of.*\?)/, qr/(Ki[mn]g)/)],
          ['of the who?', "King"], "Find a couple on one line" );

# Look for a couple of things, but have one be undef.
is_deeply([$util->multi_search_file($tmp_file, qr/(of.*\?)/, qr/(ick)/)],
          ['of the who?', undef], "Find one but not the other" );

# And finally, find a couple of things where one is an array.
is_deeply([$util->multi_search_file($tmp_file, qr/(of\sthe)\s+(who\?)/,
                                    qr/(Ki[mn]g)/)],
          [['of the', 'who?'], 'King'], "Find one an array ref and a scalar" );

# Don't forget to delete our temporary file.
rmtree $tmp_file;


