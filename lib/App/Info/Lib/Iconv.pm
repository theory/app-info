package App::Info::Lib::Iconv;

# $Id: Iconv.pm,v 1.15 2002/06/05 20:37:20 david Exp $

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

When it loads, App::Info::Lib::Iconv searches the file system for the F<iconv>
application. If F<iconv> is found, libiconv will be assumed to be installed.

App::Info::Lib::Iconv searches for F<iconv> along your path, as defined by
C<File::Spec->path>. Failing that, it searches the following directories:

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
$VERSION = '0.05';

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

    $obj->{iconv_exe} = $u->first_cat_exe('iconv', @paths);
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

Returns the full version number for libiconv. App::Info::Lib::Iconv parses the
version number from the iconv.h file, if it exists. Returns C<undef> if Iconv
is not installed. Emits a warning if Iconv is installed but F<iconv.h> could
not be found or the version number could not be parsed.

=cut

sub version {
    return unless $_[0]->{iconv_exe};
    unless (exists $_[0]->{version}) {
        $_[0]->{version} = undef;
        my $inc = $_[0]->inc_dir
          or Carp::carp("Cannot get libiconv version because file 'iconv.h' " .
                        "does not exist");
        my $header = $u->catfile($inc, 'iconv.h');
        # This is the line we're looking for:
        # #define _LIBICONV_VERSION 0x0107    /* version number: (major<<8) + minor */
        my $regex = qr/_LIBICONV_VERSION\s+([^\s]+)\s/;
        if (my $ver = $u->search_file($header, $regex)) {
            # Convert the version number from hex.
            $ver = hex $ver;
            # Shift 8.
            my $major = $ver >> 8;
            # Left shift 8 and subtract from version.
            my $minor = $ver - ($major << 8);
            # Store 'em!
            @{$_[0]}{qw(version major minor)} =
              ("$major.$minor", $major, $minor);
        } else {
            Carp::carp("Unable to parse version number from file '$header'");
        }
    }
    return $_[0]->{version};
}

=head2 major_version

  my $major_version = $iconv->major_version;

Returns the Iconv major version number. App::Info::Lib::Iconv parses the
version number from the iconv.h file, if it exists. For example, if
C<version()> returns "1.95.2", then this method returns "1". Returns C<undef>
if Iconv is not installed. Emits a warning if Iconv is installed but
F<iconv.h> could not be found or the version number could not be parsed.

=cut

sub major_version {
    $_[0]->version unless exists $_[0]->{version};
    return $_[0]->{major};
}

=head2 minor_version

  my $minor_version = $iconv->minor_version;

Returns the Iconv minor version number. App::Info::Lib::Iconv parses the
version number from the iconv.h file, if it exists. For example, if
C<version()> returns "1.95.2", then this method returns "95". Returns C<undef>
if Iconv is not installed. Emits a warning if Iconv is installed but
F<iconv.h> could not be found or the version number could not be parsed.

=cut

sub minor_version {
    $_[0]->version unless exists $_[0]->{version};
    return $_[0]->{minor};
}

=head2 patch_version

  my $patch_version = $iconv->patch_version;

Libiconv has no patch number in its version number, so this method will always
return false.

=cut

sub patch_version {}

=head2 bin_dir

  my $bin_dir = $iconv->bin_dir;

Returns the path of the directory in which the F<iconv> application was found.
Returns C<undef> if libiconv is not installed.

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
C<undef> if libiconv is not installed, or if F<iconv.h> could not be found.
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
C<undef> if libiconv is not installed, or if no libiconv library could be
found. App::Info::Lib::Iconv searches for these files:

=over 4

=item libiconv.so

=item libiconv.so.0

=item libiconv.so.0.0.1

=item libiconv.dylib

=item libiconv.2.dylib

=item libiconv.2.0.4.dylib

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
                       libiconv.dylib
                       libiconv.2.dylib
                       libiconv.2.0.4.dylib
                       libiconv.a
                       libiconv.la);

        $_[0]->{lib_dir} = $u->first_cat_dir(\@files, @paths);
    }
    return $_[0]->{lib_dir};
}

=head2 so_lib_dir

  my $so_lib_dir = $iconv->so_lib_dir;

Returns the directory path in which a libiconv shared object library was
found. Returns C<undef> if libiconv is not installed, or if no libiconv shared
object library could be found. App::Info::Lib::Iconv searches for these files:

=over 4

=item libiconv.so

=item libiconv.so.0

=item libiconv.so.0.0.1

=item libiconv.dylib

=item libiconv.2.dylib

=item libiconv.2.0.4.dylib

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
                       /usr/lib
                       /sw/lib);
        # Testing is the same as for lib_dir() except that we only check for
        # sos.
        my @files = qw(libiconv.so
                       libiconv.so.0
                       libiconv.so.0.0.1
                       libiconv.dylib
                       libiconv.2.dylib
                       libiconv.2.0.4.dylib);

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
that ought to be searched for libraries and includes.

=head1 BUGS

Feel free to drop me a line if you discover any bugs. Patches welcome.

=head1 AUTHOR

David Wheeler <david@wheeler.net> based on code by Sam Tregar
<sam@tregar.com>.

=head1 SEE ALSO

L<App::Info|App::Info>,
L<App::Info::Lib|App::Info::Lib>,
L<Text::Iconv|Text::Iconv>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2002, David Wheeler. All Rights Reserved.

This module is free software; you can redistribute it and/or modify it under the
same terms as Perl itself.

=cut
