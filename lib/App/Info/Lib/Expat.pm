package App::Info::Lib::Expat;

# $Id: Expat.pm,v 1.10 2002/06/03 18:11:21 david Exp $

=head1 NAME

App::Info::Lib::Expat - Information about the Expat XML parser

=head1 SYNOPSIS

  use App::Info::Lib::Expat;

  my $expat = App::Info::Lib::Expat->new;

  if ($expat->installed) {
      print "App name: ", $expat->name, "\n";
      print "Version:  ", $expat->version, "\n";
      print "Bin dir:  ", $expat->bin_dir, "\n";
  } else {
      print "Expat is not installed. :-(\n";
  }

=head1 DESCRIPTION

App::Info::Lib::Expat supplies information about the Expat XML parser
installed on the local system. It implements all of the methods defined by
App::Info::Lib.

When it loads, App::Info::Lib::Expat searches all of the paths in the
C<libsdirs> and C<loclibpth> -- as defined by the Perl L<Config|Config> module
-- plus F</sw/lib> (in support of all you Fink users out there) for one of the
following files:n

=over 4

=item libexpat.so

=item libexpat.so.0

=item libexpat.so.0.0.1

=item libexpat.dylib

=item libexpat.0.dylib

=item libexpat.0.0.1.dylib

=item libexpat.a

=item libexpat.la

=back

If any of these files is found, then Expat is assumed to be installed.

=cut

use strict;
use App::Info::Util;
use App::Info::Lib;
use Config;
use vars qw(@ISA $VERSION);
@ISA = qw(App::Info::Lib);
$VERSION = '0.02';

my $obj = {};
my $u = App::Info::Util->new;

do {
    # Find libexpat.
    my @paths = grep { defined and length }
      ( split(' ', $Config{libsdirs}),
        split(' ', $Config{loclibpth}),
        '/sw/lib' );

    my $libs = ["libexpat.so", "libexpat.so.0", "libexpat.so.0.0.1",
                "libexpat.dylib", "libexpat.0.dylib", "libexpat.0.0.1.dylib",
                "libexpat.a", "libexpat.la"];

    $obj->{libexpat} = $u->first_cat_dir($libs, @paths);
};

=head1 CONSTRUCTOR

=head2 new

  my $expat = App::Info::Lib::Expat->new;

Returns an App::Info::Lib::Expat object. Since App::Info::Lib::Expat is
implemented as a singleton class, the same object will be returned every time.
This ensures that only the minimum number of system calls are made to gather
the data necessary for the object methods.

=cut

sub new { bless $obj, ref $_[0] || $_[0] }

=head1 OBJECT METHODS

=head2 installed

  print "Expat is ", ($expat->installed ? '' : 'not '),
    "installed.\n";

Returns true if Expat is installed, and false if it is not.
App::Info::Lib::Expat determines whether Expat is installed based on the
presence or absence on the file system of one of the files described in the
L<"Description">.

=cut

sub installed { $_[0]->{libexpat} ? 1 : undef }

=head2 name

  my $name = $expat->name;

Returns the name of the application. In this case, C<name()> simply returns the
string "Expat".

=cut

sub name { 'Expat' }

=head2 version

Returns the full version number for Expat. App::Info::Lib::Expat parses the
version number from the expat.h file, if it exists. Returns undef if Expat is
not installed. Emits a warning if Expat is installed but F<expat.h> could not
be found or the version number could not be parsed.

=cut

sub version {
    return unless $_[0]->{libexpat};
    unless (exists $_[0]->{version}) {
        $_[0]->{version} = undef;
        my $inc = $_[0]->inc_dir
          or Carp::carp("Cannot get Expat version because file 'expat.h' " .
                        "does not exist");
        my $header = $u->catfile($inc, 'expat.h');
        my @regexen = ( qr/XML_MAJOR_VERSION\s+(\d+)$/,
                        qr/XML_MINOR_VERSION\s+(\d+)$/,
                        qr/XML_MICRO_VERSION\s+(\d+)$/ );

        my ($x, $y, $z) = $u->multi_search_file($header, @regexen);
        unless (defined $x and defined $y and defined $z) {
            # Warn them if we couldn't get them all.
            Carp::carp("Failed to parse Expat version from file '$header'");
        }
        # But go ahead and keep them all, anyway -- some may be there.
        @{$_[0]}{qw(version major minor patch)} = ("$x.$y.$z", $x, $y, $z);
    }
    return $_[0]->{version};
}

=head2 major_version

  my $major_version = $expat->major_version;

Returns the Expat major version number. App::Info::Lib::Expat parses the
version number from the expat.h file, if it exists. If C<version()> returns
"1.95.2", then this method returns "1". Returns undef if Expat is not
installed. Emits a warning if Expat is installed but F<expat.h> could not be
found or the version number could not be parsed.

=cut

sub major_version {
    $_[0]->version unless exists $_[0]->{version};
    return $_[0]->{major};
}

=head2 minor_version

  my $minor_version = $expat->minor_version;

Returns the Expat minor version number. App::Info::Lib::Expat parses the
version number from the expat.h file, if it exists. If C<version()> returns
"1.95.2", then this method returns "95". Returns undef if Expat is not
installed. Emits a warning if Expat is installed but F<expat.h> could not be
found or the version number could not be parsed.

=cut

sub minor_version {
    $_[0]->version unless exists $_[0]->{version};
    return $_[0]->{minor};
}

=head2 patch_version

  my $patch_version = $expat->patch_version;

Returns the Expat patch version number. App::Info::Lib::Expat parses the
version number from the expat.h file, if it exists. If C<version()> returns
"1.95.2", then this method returns "2". Returns undef if Expat is not
installed. Emits a warning if Expat is installed but F<expat.h> could not be
found or the version number could not be parsed.

=cut

sub patch_version {
    $_[0]->version unless exists $_[0]->{version};
    return $_[0]->{patch};
}

=head2 bin_dir

  my $bin_dir = $expat->bin_dir;

Since Expat includes no binaries, this method always returns false.

=cut

sub bin_dir { return }

=head2 inc_dir

  my $inc_dir = $expat->inc_dir;

Returns the directory path in which the file F<expat.h> was found. Returns
undef if Expat is not installed, or if F<expat.h> could not be found.
App::Info::Lib::Expat searches for F<expat.h> in the following directories:

=over 4

=item /usr/local/include

=item /usr/include

=item /sw/include

=back

=cut

sub inc_dir {
    return unless $_[0]->{libexpat};
    unless (exists $_[0]->{inc_dir}) {
        $_[0]->{inc_dir} = undef;
        # Should there be more paths than this?
        my @paths = qw(/usr/local/include
                       /usr/include
                       /sw/include);

        $_[0]->{inc_dir} = $u->first_cat_dir('expat.h', @paths);
    }
    return $_[0]->{inc_dir};
}

=head2 lib_dir

  my $lib_dir = $expat->lib_dir;

Returns the directory path in which a Expat library was found. The files
and paths searched are as described in the L<"DESCRIPTION">.

=cut

sub lib_dir { $_[0]->{libexpat} }

=head2 so_lib_dir

  my $so_lib_dir = $expat->so_lib_dir;

Returns the directory path in which a Expat shared object library was found.
It searches all of the paths in the C<libsdirs> and C<loclibpth> -- as defined
by the Perl L<Config|Config> module -- plus F</sw/lib> (for all you Fink fans)
for one of the following files:

=over

=item libexpat.so

=item libexpat.so.0

=item libexpat.so.0.0.1

=item libexpat.dylib

=item libexpat.0.dylib

=item libexpat.0.0.1.dylib

=back

=cut

sub so_lib_dir {
    return unless $_[0]->{libexpat};
    unless (exists $_[0]->{so_lib_dir}) {
        my @paths = grep { defined and length }
          ( split(' ', $Config{libsdirs}),
            split(' ', $Config{loclibpth}),
                  '/sw/lib' );
        my $libs = ["libexpat.so", "libexpat.so.0", "libexpat.so.0.0.1",
                    "libexpat.dylib", "libexpat.0.dylib",
                    "libexpat.0.0.1.dylib"];

        $obj->{so_lib_dir} = $u->first_cat_dir($libs, @paths);
    }
    return $_[0]->{so_lib_dir};
}

=head2 home_url

  my $home_url = $expat->home_url;

Returns the libexpat home page URL.

=cut

sub home_url { 'http://expat.sourceforge.net/' }

=head2 download_url

  my $download_url = $expat->download_url;

Returns the libexpat download URL.

=cut

sub download_url { 'http://sourceforge.net/projects/expat/' }

1;
__END__

=head1 KNOWN ISSUES

This is a pretty simple class. It's possible that there are more directories
that ought to be searched for libraries and includes. And if anyone knows
how to get the version numbers, let me know!

=head1 BUGS

Feel free to drop me a line if you discover any bugs. Patches welcome.

=head1 AUTHOR

David Wheeler <david@wheeler.net> based on code by Sam Tregar <sam@tregar.com>
that Sam, in turn, borrowed from Clark Cooper's L<XML::Parser|XML::Parser>
module.

=head1 SEE ALSO

L<App::Info|App::Info>,
L<App::Info::Lib|App::Info::Lib>,
L<XML::Parser|XML::Parser>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2002, David Wheeler. All Rights Reserved.

This module is free software; you can redistribute it and/or modify it under the
same terms as Perl itself.

=cut
