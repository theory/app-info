package App::Info::Lib::Iconv;

# $Id$

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
App::Info::Lib. Methods that trigger events will trigger them only the first
time they're called (See L<App::Info|App::Info> for documentation on handling
events). To start over (after, say, someone has installed libiconv) construct
a new App::Info::Lib::Iconv object to aggregate new metadata.

Some of the methods trigger the same events. This is due to cross-calling of
shared subroutines. However, any one event should be triggered no more than
once. For example, although the info event "Searching for 'iconv.h'" is
documented for the methods C<version()>, C<major_version()>, and
C<minor_version()>, rest assured that it will only be triggered once, by
whichever of those four methods is called first.

=cut

use strict;
use File::Basename ();
use App::Info::Util;
use App::Info::Lib;
use vars qw(@ISA $VERSION);
@ISA = qw(App::Info::Lib);
$VERSION = '0.26';

my $u = App::Info::Util->new;

##############################################################################

=head1 INTERFACE

=head2 Constructor

=head3 new

  my $iconv = App::Info::Lib::Iconv->new(@params);

Returns an App::Info::Lib::Iconv object. See L<App::Info|App::Info> for a
complete description of argument parameters.

When called, C<new()> searches the file system for the F<iconv> executable. If
F<iconv> is found, libiconv will be assumed to be installed. Otherwise, most
of the object methods will return C<undef>.

App::Info::Lib::Iconv searches for F<iconv> along your path, as defined by
C<File::Spec-E<gt>path>. Failing that, it searches the following directories:

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

B<Events:>

=over 4

=item info

Searching for iconv

=item unknown

Path to iconv executable?

=item confirm

Path to iconv executable?

=back

=cut

sub new {
    my $self = shift->SUPER::new(@_);
    # Find iconv.
    $self->info("Searching for iconv");
    my @paths = ($u->path,
      qw(/usr/local/bin
         /usr/bin
         /bin
         /sw/bin
         /usr/local/sbin
         /usr/sbin/
         /sbin
         /sw/sbin));

    if (my $exe = $u->first_cat_exe('iconv', @paths)) {
        # We found it. Confirm.
        $self->{iconv_exe} =
          $self->confirm( key      => 'iconv_exe',
                          prompt   => 'Path to iconv executable?',
                          value    => $exe,
                          callback => sub { -x },
                          error    => 'Not an executable');
    } else {
        # No luck. Ask 'em for it.
        $self->{iconv_exe} =
          $self->unknown( key      => 'iconv_exe',
                          prompt   => 'Path to iconv executable?',
                          callback => sub { -x },
                          error    => 'Not an executable');
    }

    return $self;
}

##############################################################################

=head2 Class Method

=head3 key_name

  my $key_name = App::Info::Lib::Iconv->key_name;

Returns the unique key name that describes this class. The value returned is
the string "libiconv".

=cut

sub key_name { 'libiconv' }

##############################################################################

=head2 Object Methods

=head3 installed

  print "libiconv is ", ($iconv->installed ? '' : 'not '),
    "installed.\n";

Returns true if libiconv is installed, and false if it is not.
App::Info::Lib::Iconv determines whether libiconv is installed based on the
presence or absence of the F<iconv> application, as found when C<new()>
constructed the object. If libiconv does not appear to be installed, then most
of the other object methods will return empty values.

=cut

sub installed { $_[0]->{iconv_exe} ? 1 : undef }

##############################################################################

=head3 name

  my $name = $iconv->name;

Returns the name of the application. In this case, C<name()> simply returns
the string "libiconv".

=cut

sub name { 'libiconv' }

##############################################################################

=head3 version

  my $version = $iconv->version;

Returns the full version number for libiconv. App::Info::Lib::Iconv attempts
to parse the version number from the F<iconv.h> file, if it exists.

B<Events:>

=over 4

=item info

Searching for 'iconv.h'

Searching for include directory

=item error

Cannot find include directory

Cannot find 'iconv.h'

Cannot parse version number from file 'iconv.h'

=item unknown

Enter a valid libiconv include directory

Enter a valid libiconv version number

=back

=cut

# This code reference is called by version(), major_version(), and
# minor_version() to get the version numbers.
my $get_version = sub {
    my $self = shift;
    $self->{version} = undef;
    $self->info("Searching for 'iconv.h'");
    # No point in continuing if there's no include directory.
    my $inc = $self->inc_dir
      or ($self->error("Cannot find 'iconv.h'")) && return;
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
            @{$self}{qw(version major minor)} =
              ("$major.$minor", $major, $minor);
    } else {
        $self->error("Cannot parse version number from file '$header'");
    }
};


sub version {
    my $self = shift;
    return unless $self->{iconv_exe};

    # Get data.
    $get_version->($self) unless exists $self->{version};

    # Handle an unknown value.
    unless ($self->{version}) {
        # Create a validation code reference.
        my $chk_version = sub {
            # Try to get the version number parts.
            my ($x, $y) = /^(\d+)\.(\d+)$/;
            # Return false if we didn't get all three.
            return unless $x and defined $y;
            # Save both parts.
            @{$self}{qw(major minor)} = ($x, $y);
            # Return true.
            return 1;
        };
        $self->{version} = $self->unknown( key      => 'version number',
                                           callback => $chk_version);
    }

    return $self->{version};
}

##############################################################################

=head3 major_version

  my $major_version = $iconv->major_version;

Returns the libiconv major version number. App::Info::Lib::Iconv attempts to
parse the version number from the F<iconv.h> file, if it exists. For example,
if C<version()> returns "1.7", then this method returns "1".

B<Events:>

=over 4

=item info

Searching for 'iconv.h'

Searching for include directory

=item error

Cannot find include directory

Cannot find 'iconv.h'

Cannot parse version number from file 'iconv.h'

=item unknown

Enter a valid libiconv include directory

Enter a valid libiconv version number

=back

=cut

# This code reference is used by major_version() and minor_version() to
# validate a version number entered by a user.
my $is_int = sub { /^\d+$/ };

sub major_version {
    my $self = shift;
    return unless $self->{iconv_exe};

    # Get data.
    $get_version->($self) unless exists $self->{version};

    # Handle an unknown value.
    $self->{major} = $self->unknown( key      => 'major version number',
                                     callback => $is_int)
      unless $self->{major};

    return $self->{major};
}

##############################################################################

=head3 minor_version

  my $minor_version = $iconv->minor_version;

Returns the libiconv minor version number. App::Info::Lib::Iconv attempts to
parse the version number from the F<iconv.h> file, if it exists. For example,
if C<version()> returns "1.7", then this method returns "7".

B<Events:>

=over 4

=item info

Searching for 'iconv.h'

Searching for include directory

=item error

Cannot find include directory

Cannot find 'iconv.h'

Cannot parse version number from file 'iconv.h'

=item unknown

Enter a valid libiconv include directory

Enter a valid libiconv version number

=back

=cut

sub minor_version {
    my $self = shift;
    return unless $self->{iconv_exe};

    # Get data.
    $get_version->($self) unless exists $self->{version};

    # Handle an unknown value.
    $self->{minor} = $self->unknown( key      => 'minor version number',
                                     callback => $is_int)
      unless $self->{minor};

    return $self->{minor};
}

##############################################################################

=head3 patch_version

  my $patch_version = $iconv->patch_version;

Since libiconv has no patch number in its version number, this method will
always return false.

=cut

sub patch_version { return }

##############################################################################

=head3 bin_dir

  my $bin_dir = $iconv->bin_dir;

Returns the path of the directory in which the F<iconv> application was found
when the object was constructed by C<new()>.

B<Events:>

=over 4

=item info

Searching for bin directory

=item error

Cannot find bin directory

=item unknown

Enter a valid libiconv bin directory

=back

=cut

# This code reference is used by inc_dir() and so_lib_dir() to validate a
# directory entered by the user.
my $is_dir = sub { -d };

sub bin_dir {
    my $self = shift;
    return unless $self->{iconv_exe};
    unless (exists $self->{bin_dir}) {
        # This is all probably redundant, but let's do the drill, anyway.
        $self->info("Searching for bin directory");
        if (my $bin = File::Basename::dirname($self->{iconv_exe})) {
            # We found it!
            $self->{bin_dir} = $bin;
        } else {
            $self->{bin_dir} = $self->unknown( key      => 'bin directory',
                                               callback => $is_dir);
        }
    }
    return $self->{bin_dir};
}

##############################################################################

=head3 inc_dir

  my $inc_dir = $iconv->inc_dir;

Returns the directory path in which the file F<iconv.h> was found.
App::Info::Lib::Iconv searches for F<iconv.h> in the following directories:

=over 4

=item /usr/local/include

=item /usr/include

=item /sw/include

=back

B<Events:>

=over 4

=item info

Searching for include directory

=item error

Cannot find include directory

=item unknown

Enter a valid libiconv include directory

=back

=cut

sub inc_dir {
    my $self = shift;
    return unless $self->{iconv_exe};
    unless (exists $self->{inc_dir}) {
        $self->info("Searching for include directory");
        # Should there be more paths than this?
        my @paths = qw(/usr/local/include
                       /usr/include
                       /sw/include);

        if (my $dir = $u->first_cat_dir('iconv.h', @paths)) {
            $self->{inc_dir} = $dir;
        } else {
            $self->error("Cannot find include directory");
            my $cb = sub { $u->first_cat_dir('iconv.h', $_) };
            $self->{inc_dir} =
              $self->unknown( key      => 'include directory',
                              callback => $cb,
                              error    => "File 'iconv.h' not found in " .
                                          "directory");

        }
    }
    return $self->{inc_dir};
}

##############################################################################

=head3 lib_dir

  my $lib_dir = $iconv->lib_dir;

Returns the directory path in which a libiconv library was found.
App::Info::Lib::Iconv searches for these files:

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

B<Events:>

=over 4

=item info

Searching for library directory

=item error

Cannot find library directory

=item unknown

Enter a valid libiconv library directory

=back

=cut

sub lib_dir {
    my $self = shift;
    return unless $self->{iconv_exe};
    unless (exists $self->{lib_dir}) {
        $self->info("Searching for library directory");
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

        if (my $dir = $u->first_cat_dir(\@files, @paths)) {
            # Success!
            $self->{lib_dir} = $dir;
        } else {
            $self->error("Cannot not find library direcory");
            my $cb = sub { $u->first_cat_dir(\@files, $_) };
            $self->{lib_dir} =
              $self->unknown( key      => 'library directory',
                              callback => $cb,
                              error    => "Library files not found in " .
                                          "directory");
        }
    }
    return $self->{lib_dir};
}

##############################################################################

=head3 so_lib_dir

  my $so_lib_dir = $iconv->so_lib_dir;

Returns the directory path in which a libiconv shared object library was
found. App::Info::Lib::Iconv searches for these files:

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

<Events:>

=over 4

=item info

Searching for shared object library directory

=item error

Cannot find shared object library directory

=item unknown

Enter a valid libiconv shared object library directory

=back

=cut

sub so_lib_dir {
    my $self = shift;
    return unless $self->{iconv_exe};
    unless (exists $self->{so_lib_dir}) {
        $self->info("Searching for shared object library directory");
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

        if (my $dir = $u->first_cat_dir(\@files, @paths)) {
            $self->{so_lib_dir} = $dir;
        } else {
            $self->error("Cannot find shared object library directory");
            my $cb = sub { $u->first_cat_dir(\@files, $_) };
            $self->{so_lib_dir} =
              $self->unknown( key      => 'shared object library directory',
                              callback => $cb,
                              error    => "Shared object libraries not " .
                                          "found in directory");
        }
    }
    return $self->{so_lib_dir};
}

##############################################################################

=head3 home_url

  my $home_url = $iconv->home_url;

Returns the libiconv home page URL.

=cut

sub home_url { 'http://www.gnu.org/software/libiconv/' }

##############################################################################

=head3 download_url

  my $download_url = $iconv->download_url;

Returns the libiconv download URL.

=cut

sub download_url { 'ftp://ftp.gnu.org/pub/gnu/libiconv/' }

1;
__END__

=head1 KNOWN ISSUES

This is a pretty simple class. It's possible that there are more directories
that ought to be searched for libraries and includes.

=head1 TO DO

Improve this class by borrowing code from Matt Seargent's AxKit F<Makefil.PL>.

=head1 BUGS

Report all bugs via the CPAN Request Tracker at
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-Info>.

=head1 AUTHOR

David Wheeler <L<david@wheeler.net|"david@wheeler.net">> based on code by Sam
Tregar <L<sam@tregar.com|"sam@tregar.com">>.

=head1 SEE ALSO

L<App::Info|App::Info>,
L<App::Info::Lib|App::Info::Lib>,
L<Text::Iconv|Text::Iconv>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2002-2004, David Wheeler. All Rights Reserved.

This module is free software; you can redistribute it and/or modify it under the
same terms as Perl itself.

=cut
