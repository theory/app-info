package App::Info::Lib::Iconv;

# $Id: Iconv.pm,v 1.7 2002/06/02 00:21:25 david Exp $

=head1 NAME

App::Info::Lib::Iconv - Information about libiconv

=head1 SYNOPSIS

  use App::Info::Lib::Iconv;

  my $iconv = App::Info::Lib::Iconv->new;

  if ($iconv->installed) {
      print "App name: ", $iconv->name, "\n";
      print "Version:  ", $iconv->version, "\n";
      print "Bin dir:  ", $iconv->bin_dir, "\n";
  } else {
      print "libiconv is not installed. :-(\n";
  }

=head1 DESCRIPTION

App::Info::Lib::Iconv supplies information about the libiconv library
installed on the local system. It implements all of the methods defined by
App::Info::Lib.

When it loads, App::Info::Lib::Iconv searches the local file system for the
F<iconv> application. If F<iconv> is found, libiconv will be assumed to be
installed.

App::Info::Lib::Iconv searches for F<iconv> along your path, as defined by
File::Spec->path. Failing that, it searches the following directories:

=over 4

=item /usr/local/bin

=item /usr/bin

=item /bin

=item /sw/bin

=item /usr/local/sbin

=item /usr/sbin/

=item /sbin

=item /sw/sbin

=back

=cut

use strict;
use File::Basename ();
use App::Info::Util;
use App::Info::Lib;
use vars qw(@ISA $VERSION);
@ISA = qw(App::Info::Lib);
$VERSION = '0.01';

my $obj = {};
my $u = App::Info::Util->new;

do {
    # Find iconv.
    my @paths = ($u->path,
      qw(/usr/local/bin
         /usr/bin
         /bin
         /sw/bin
         /usr/local/sbin
         /usr/sbin/
         /sbin
         /sw/sbin));

    $obj->{iconv_exe} = $u->first_cat_file('iconv', @paths);
};

=head1 CONSTRUCTOR

=head2 new

  my $iconv = App::Info::Lib::Iconv->new;

Returns an App::Info::Lib::Iconv object. Since App::Info::Lib::Iconv is
implemented as a singleton class, the same object will be returned every time.
This ensures that only the minimum number of system calls are made to gather
the data necessary for the object methods.

=cut

sub new { bless $obj, ref $_[0] || $_[0] }

=head1 OBJECT METHODS

=head2 installed

  print "libiconv is ", ($iconv->installed ? '' : 'not '),
    "installed.\n";

Returns true if libiconv is installed, and false if it is not.
App::Info::Lib::Iconv determines whether libiconv is installed based on the
presence or absence of the F<iconv> application on the file system.

=cut

sub installed { $_[0]->{iconv_exe} ? 1 : undef }

=head2 name

  my $name = $iconv->name;

Returns the name of the application. In this case, C<name()> simply returns
the string "libiconv".

=cut

sub name { 'libiconv' }

=head2 version

  my $version = $iconv->version;

Unimplemented. Patches welcome.

=cut

sub version {}

=head2 major_version

  my $major_version = $iconv->major_version;

Unimplemented. Patches welcome.

=cut

sub major_version {}

=head2 minor_version

  my $minor_version = $iconv->minor_version;

Unimplemented. Patches welcome.

=cut

sub minor_version {}

=head2 patch_version

  my $patch_version = $iconv->patch_version;

Unimplemented. Patches welcome.

=cut

sub patch_version {}

=head2 bin_dir

  my $bin_dir = $iconv->bin_dir;

Returns the path of the directory in which the F<iconv> application was found.
Returns undef if libiconv is not installed.

=cut

sub bin_dir {
    return unless $_[0]->{iconv_exe};
    unless (exists $_[0]->{bin_dir}) {
        $_[0]->{bin_dir} = File::Basename::dirname($_[0]->{iconv_exe});
    }
    return $_[0]->{bin_dir};
}

=head2 inc_dir

  my $inc_dir = $iconv->inc_dir;

Returns the directory path in which the file F<iconv.h> was found. Returns
undef if libiconv is not installed, or if F<iconv.h> could not be found.
App::Info::Lib::Iconv searches for F<iconv.h> in the following directories:

=over 4

=item /usr/local/include

=item /usr/include

=item /sw/include

=back

=cut

sub inc_dir {
    return unless $_[0]->{iconv_exe};
    unless (exists $_[0]->{inc_dir}) {
        $_[0]->{inc_dir} = undef;
        # Should there be more paths than this?
        my @paths = qw(/usr/local/include
                       /usr/include
                       /sw/include);

        $_[0]->{inc_dir} = $u->first_cat_dir('iconv.h', @paths);
    }
    return $_[0]->{inc_dir};
}

=head2 lib_dir

  my $lib_dir = $iconv->lib_dir;

Returns the directory path in which a libiconv library was found. Returns
undef if libiconv is not installed, or if no libiconv library could be found.
App::Info::Lib::Iconv searches for these files:

=over 4

=item libiconv.so

=item libiconv.so.0

=item libiconv.so.0.0.1

=item libiconv.a

=item libiconv.la

=back

...in these directories:

=over 4

=item /usr/local/lib

=item /usr/lib

=item /sw/lib

=back

=cut

sub lib_dir {
    return unless $_[0]->{iconv_exe};
    unless (exists $_[0]->{lib_dir}) {
        $_[0]->{lib_dir} = undef;
        # Should there be more paths than this?
        my @paths = qw(/usr/local/lib
                       /usr/lib
                       /sw/lib);
        my @files = qw(libiconv.so
                       libiconv.so.0
                       libiconv.so.0.0.1
                       libiconv.a
                       libiconv.la);

        $_[0]->{lib_dir} = $u->first_cat_dir(\@files, @paths);
    }
    return $_[0]->{lib_dir};
}

=head2 so_lib_dir

  my $so_lib_dir = $iconv->so_lib_dir;

Returns the directory path in which a libiconv shared object library was
found. Returns undef if libiconv is not installed, or if no libiconv shared
object library could be found. App::Info::Lib::Iconv searches for these files:

=over 4

=item libiconv.so

=item libiconv.so.0

=item libiconv.so.0.0.1

=back

...in these directories:

=over 4

=item /usr/local/lib

=item /usr/lib

=item /sw/lib

=back

=cut

sub so_lib_dir {
    return unless $_[0]->{iconv_exe};
    unless (exists $_[0]->{so_lib_dir}) {
        $_[0]->{so_lib_dir} = undef;
        # Should there be more paths than this?
        my @paths = qw(/usr/local/lib
                       /usr/lib);
        # Testing is the same as for lib_dir() except that we only check for
        # sos.
        my @files = qw(libiconv.so
                       libiconv.so.0
                       libiconv.so.0.0.1);

        $_[0]->{so_lib_dir} = $u->first_cat_dir(\@files, @paths);
    }
    return $_[0]->{so_lib_dir};
}

=head2 home_url

  my $home_url = $iconv->home_url;

Returns the libiconv home page URL.

=cut

sub home_url { 'http://www.gnu.org/software/libiconv/' }

=head2 download_url

  my $download_url = $iconv->download_url;

Returns the libiconv download URL.

=cut

sub download_url { 'ftp://ftp.gnu.org/pub/gnu/libiconv/' }

1;
__END__

=head1 KNOWN ISSUES

This is a pretty simple class. It's possible that there are more directories
that ought to be searched for libraries and includes. And if anyone knows
how to get the version numbers, let me know!

=head1 BUGS

Feel free to drop me a line if you discover any bugs. Patches welcome.

=head1 AUTHOR

David Wheeler <david@wheeler.net>

=head1 SEE ALSO

L<App::Info|App::Info>,
L<App::Info::Lib|App::Info::Lib>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2002, David Wheeler. All Rights Reserved.

This module is free software; you can redistribute it and/or modify it under the
same terms as Perl itself.

=cut
