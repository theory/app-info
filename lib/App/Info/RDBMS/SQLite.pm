package App::Info::RDBMS::SQLite;

# $Id$

=head1 NAME

App::Info::RDBMS::SQLite - Information about SQLite

=head1 SYNOPSIS

  use App::Info::RDBMS::SQLite;

  my $sqlite = App::Info::RDBMS::SQLite->new;

  if ($sqlite->installed) {
      print "App name: ", $sqlite->name, "\n";
      print "Version:  ", $sqlite->version, "\n";
      print "Bin dir:  ", $sqlite->bin_dir, "\n";
  } else {
      print "SQLite is not installed. :-(\n";
  }

=head1 DESCRIPTION

App::Info::RDBMS::SQLite supplies information about the SQLite application
installed on the local system. It implements all of the methods defined by
App::Info::RDBMS. Methods that trigger events will trigger them only the first
time they're called (See L<App::Info|App::Info> for documentation on handling
events). To start over (after, say, someone has installed SQLite) construct a
new App::Info::RDBMS::SQLite object to aggregate new metadata.

Some of the methods trigger the same events. This is due to cross-calling of
shared subroutines. However, any one event should be triggered no more than
once. For example, although the info event "Executing `pg_config --version`"
is documented for the methods C<name()>, C<version()>, C<major_version()>,
C<minor_version()>, and C<patch_version()>, rest assured that it will only be
triggered once, by whichever of those four methods is called first.

=cut

##############################################################################

use strict;
use App::Info::RDBMS;
use App::Info::Util;
use Config;
use vars qw(@ISA $VERSION);
@ISA = qw(App::Info::RDBMS);
$VERSION = '0.31';
use constant WIN32 => $^O eq 'MSWin32';

my $u = App::Info::Util->new;

=head1 INTERFACE

=head2 Constructor

=head3 new

  my $sqlite = App::Info::RDBMS::SQLite->new(@params);

Returns an App::Info::RDBMS::SQLite object. See L<App::Info|App::Info> for a
complete description of argument parameters.

When it called, C<new()> searches the file system for the F<sqlite3> or
F<sqlite> application (if both are installed, it will prefer F<sqlite3>. If
found, it will be called by the object methods below to gather the data
necessary for each. If it cannot be found, then C<new()> will attempt to load
L<DBD::SQLite|DBD::SQLite> or L<DBD::SQLite2|DBD::SQLite2>. These DBI drivers
have SQLite embedded in them but do not install the application. If these
fail, then SQLite is assumed not to be installed, and each of the object
methods will return C<undef>.

App::Info::RDBMS::SQLite searches for F<sqlite3> and F<sqlite> along your
path, as defined by C<< File::Spec->path >>.

B<Events:>

=over 4

=item info

Looking for sqlite3 or sqlite.

=item confirm

Path to sqlite3 or sqlite?

=item unknown

Path to sqlite3 or sqlite?

=back

=cut

sub new {
    # Construct the object.
    my $self = shift->SUPER::new(@_);

    # Find pg_config.
    $self->info("Looking for sqlite3 or sqlite");

    my @exes = qw(sqlite3 sqlite);
    if (WIN32) { $_ .= ".exe" for @exes }

    if (my $cfg = $u->first_cat_exe(\@exes, $u->path)) {
        # We found it. Confirm.
        $self->{sqlite} = $self->confirm(
            key      => 'sqlite',
            prompt   => "Path to sqlite3 or sqlite?",
            value    => $cfg,
            callback => sub { -x },
            error    => 'Not an executable'
        );
    } else {
        # Try using DBD::SQLite, which includes SQLite.
        for my $dbd ('SQLite', 'SQLite2') {
            if (eval "use DBD::$dbd") {
                # Looks like DBD::SQLite is installed. Set up a temp database
                # handle so we can get information from it.
                require DBI;
                $self->{dbfile} = $u->catfile($u->tmpdir, 'tmpdb');
                $self->{dbh} = DBI->connect("dbi:$dbd:dbname=$self->{dbfile}","","");
                # I don't think there's any way to really confirm, so just return.
                return $self;
            }
        }

        # Handle an unknown value.
        $self->{sqlite} = $self->unknown(
            key      => 'sqlite',
            prompt   => "Path to sqlite3 or sqlite?",
            callback => sub { -x },
            error    => 'Not an executable'
        );
    }

    return $self;
}

sub DESTROY {
    my $self = shift;
    $self->{dbh}->disconnect if $self->{dbh};
    unlink $self->{dbfile} if $self->{dbfile};
}

##############################################################################

=head2 Class Method

=head3 key_name

  my $key_name = App::Info::RDBMS::SQLite->key_name;

Returns the unique key name that describes this class. The value returned is
the string "SQLite".

=cut

sub key_name { 'SQLite' }

##############################################################################

=head2 Object Methods

=head3 installed

  print "SQLite is ", ($sqlite->installed ? '' : 'not '), "installed.\n";

Returns true if SQLite is installed, and false if it is not.

App::Info::RDBMS::SQLite determines whether SQLite is installed based on the
presence or absence of the F<sqlite3> or F<sqlite> application on the file
system as found when C<new()> constructed the object. If SQLite does not
appear to be installed, then all of the other object methods will return empty
values.

=cut

sub installed { return $_[0]->{sqlite} || $_[0]->{dbh} ? 1 : undef }

##############################################################################

=head3 name

  my $name = $sqlite->name;

Returns the name of the application. App::Info::RDBMS::SQLite simply returns
the value returned by C<key_name> if SQLite is installed, and C<undef> if
it is not installed.

=cut

sub name { $_[0]->installed ? $_[0]->key_name : undef }

# This code reference is used by version(), major_version(),  minor_version(),
# and patch_version() to aggregate the data they need.
my $get_version = sub {
    my $self = shift;
    $self->{'--version'} = 1;
    my $version;

    if ($self->{sqlite}) {
        # Get the version number from the executable.
        $self->info(qq{Executing `"$self->{sqlite}" -version`});
        $version = `"$self->{sqlite}" -version`;
        unless ($version) {
            $self->error("Failed to find SQLite version with ".
                         "`$self->{sqlite} -version`");
            return;
        }
        chomp $version;

    } elsif ($self->{dbh}) {
        # Get the version number from the database handle.
        $self->info('Grabbing version from DBD::SQLite');
        $version = $self->{dbh}->{sqlite_version};
        unless ($version) {
            $self->error("Failed to retreive SQLite version from DBD::SQLite");
            return;
        }

    } else {
        # No dice.
        return;
    }

    # Parse the version number.
    my ($x, $y, $z) = $version =~ /(\d+)\.(\d+).(\d+)/;
    if (defined $x and defined $y and defined $z) {
        # Beta/devel/release candidates are treated as patch level "0"
        @{$self}{qw(version major minor patch)} =
          ($version, $x, $y, $z);
    } elsif ($version =~ /(\d+)\.(\d+)/) {
        # New versions, such as "3.0", are treated as patch level "0"
        @{$self}{qw(version major minor patch)} =
          ($version, $1, $2, 0);
    } else {
        $self->error("Failed to parse SQLite version parts from " .
                     "string '$version'");
    }
};

##############################################################################

=head3 version

  my $version = $sqlite->version;

Returns the SQLite version number. App::Info::RDBMS::SQLite parses the version
number from the system call C<`sqlite -version`> or retreives it from
DBD::SQLite.

B<Events:>

=over 4

=item info

Executing `sqlite -version`

=item error

Failed to find SQLite version with `sqlite -version`

Failed to retreive SQLite version from DBD::SQLite

Unable to parse name from string

Unable to parse version from string

Failed to parse SQLite version parts from string

=item unknown

Enter a valid SQLite version number

=back

=cut

sub version {
    my $self = shift;
    return unless $self->installed;

    # Get data.
    $get_version->($self) unless $self->{'--version'};

    # Handle an unknown value.
    unless ($self->{version}) {
        # Create a validation code reference.
        my $chk_version = sub {
            # Try to get the version number parts.
            my ($x, $y, $z) = /^(\d+)\.(\d+).(\d+)$/;
            # Return false if we didn't get all three.
            return unless $x and defined $y and defined $z;
            # Save all three parts.
            @{$self}{qw(major minor patch)} = ($x, $y, $z);
            # Return true.
            return 1;
        };
        $self->{version} = $self->unknown( key      => 'version number',
                                           callback => $chk_version);
    }
    return $self->{version};
}

##############################################################################

=head3 major version

  my $major_version = $sqlite->major_version;

Returns the SQLite major version number. App::Info::RDBMS::SQLite parses the
version number from the system call C<`sqlite -version`> or retreives it from
DBD::SQLite. For example, if C<version()> returns "3.0.8", then this method
returns "3".

B<Events:>

=over 4

=item info

Executing `sqlite -version`

=item error

Failed to find SQLite version with `sqlite -version`

Failed to retreive SQLite version from DBD::SQLite

Unable to parse name from string

Unable to parse version from string

Failed to parse SQLite version parts from string

=item unknown

Enter a valid SQLite version number

=back

=cut

# This code reference is used by major_version(), minor_version(), and
# patch_version() to validate a version number entered by a user.
my $is_int = sub { /^\d+$/ };

sub major_version {
    my $self = shift;
    return unless $self->installed;
    # Load data.
    $get_version->($self) unless exists $self->{'--version'};
    # Handle an unknown value.
    $self->{major} = $self->unknown( key      => 'major version number',
                                     callback => $is_int)
      unless $self->{major};
    return $self->{major};
}

##############################################################################

=head3 minor version

  my $minor_version = $sqlite->minor_version;

Returns the SQLite minor version number. App::Info::RDBMS::SQLite parses the
version number from the system call C<`sqlite -version`> or retreives it from
DBD::SQLite. For example, if C<version()> returns "3.0.8", then this method
returns "0".

B<Events:>

=over 4

=item info

Executing `sqlite -version`

=item error

Failed to find SQLite version with `sqlite -version`

Failed to retreive SQLite version from DBD::SQLite

Unable to parse name from string

Unable to parse version from string

Failed to parse SQLite version parts from string

=item unknown

Enter a valid SQLite version number

=back

=cut

sub minor_version {
    my $self = shift;
    return unless $self->installed;
    # Load data.
    $get_version->($self) unless exists $self->{'--version'};
    # Handle an unknown value.
    $self->{minor} = $self->unknown( key      => 'minor version number',
                                     callback => $is_int)
      unless defined $self->{minor};
    return $self->{minor};
}

##############################################################################

=head3 patch version

  my $patch_version = $sqlite->patch_version;

Returns the SQLite patch version number. App::Info::RDBMS::SQLite parses the
version number from the system call C<`sqlite -version`> or retreives it from
DBD::SQLite. For example, if C<version()> returns "3.0.8", then this method
returns "8".

B<Events:>

=over 4

=item info

Executing `sqlite -version`

=item error

Failed to find SQLite version with `sqlite -version`

Failed to retreive SQLite version from DBD::SQLite

Unable to parse name from string

Unable to parse version from string

Failed to parse SQLite version parts from string

=item unknown

Enter a valid SQLite version number

=back

=cut

sub patch_version {
    my $self = shift;
    return unless $self->installed;
    # Load data.
    $get_version->($self) unless exists $self->{'--version'};
    # Handle an unknown value.
    $self->{patch} = $self->unknown( key      => 'patch version number',
                                     callback => $is_int)
      unless defined $self->{patch};
    return $self->{patch};
}

##############################################################################

=head3 bin_dir

  my $bin_dir = $sqlite->bin_dir;

Returns the SQLite binary directory path. App::Info::RDBMS::SQLite simply
retreives it as the directory part of the path to the F<sqlite3> or F<sqlite>
executable.

=cut

sub bin_dir {
    my $self = shift;
    return unless $self->{sqlite};
    unless (exists $self->{bin_dir} ) {
        $self->{bin_dir} = $u->catdir(($u->splitpath($self->{sqlite}))[0,1]);
    }
    return $self->{bin_dir};
}

##############################################################################

=head3 lib_dir

  my $lib_dir = $expat->lib_dir;

Returns the directory path in which an SQLite shared object library was
found. No search is performed if SQLite is not installed or if only
DBD::SQLite is installed. It searches all of the paths in the C<libsdirs> and
C<loclibpth> attributes defined by the Perl L<Config|Config> module -- plus
F</sw/lib> (in support of all you Fink users out there) -- for one of the
following files:

=over

=item libsqlite3.a

=item libsqlite3.la

=item libsqlite3.so

=item libsqlite3.so.0

=item libsqlite3.so.0.0.1

=item libsqlite3.dylib

=item libsqlite3.0.dylib

=item libsqlite3.0.0.1.dylib

=item libsqlite.a

=item libsqlite.la

=item libsqlite.so

=item libsqlite.so.0

=item libsqlite.so.0.0.1

=item libsqlite.dylib

=item libsqlite.0.dylib

=item libsqlite.0.0.1.dylib

=back

B<Events:>

=over 4

=item info

Searching for shared object library directory

=item error

Cannot find shared object library direcory

=item unknown

Enter a valid Expat shared object library directory

=back

=cut

my $lib_dir = sub {
    my ($self, $label) = (shift, shift, shift);
    return unless $self->{sqlite};
    $self->info("Searching for $label directory");
    my $exe = $u->splitpath($self->{sqlite});
    my $libs = [ map { "lib$exe.$_"} @_,
                 qw(so so.0 so.0.0.1 dylib 0.dylib .0.0.1.dylib)
             ];
    my $dir;
    unless ($dir = $u->first_cat_dir($libs, $u->lib_dirs, '/sw/lib')) {
        $self->error("Cannot find $label direcory");
        $dir = $self->unknown(
            key      => "$label directory",
            callback => sub { $u->first_cat_dir($libs, $_) },
            error    => "No $label found in directory "
        );
    }
    return $dir;

};

sub lib_dir {
    my $self = shift;
    return unless $self->{sqlite};
    $self->{lib_dir} = $lib_dir->($self, 'library', 'a', 'la')
      unless exists $self->{lib_dir};
    return $self->{lib_dir};
}

##############################################################################

=head3 so_lib_dir

  my $so_lib_dir = $expat->so_lib_dir;

Returns the directory path in which an SQLite shared object library was
found. No search is performed if SQLite is not installed or if only
DBD::SQLite is installed. It searches all of the paths in the C<libsdirs> and
C<loclibpth> attributes defined by the Perl L<Config|Config> module -- plus
F</sw/lib> (in support of all you Fink users out there) -- for one of the
following files:

=over

=item libsqlite3.so

=item libsqlite3.so.0

=item libsqlite3.so.0.0.1

=item libsqlite3.dylib

=item libsqlite3.0.dylib

=item libsqlite3.0.0.1.dylib

=item libsqlite.so

=item libsqlite.so.0

=item libsqlite.so.0.0.1

=item libsqlite.dylib

=item libsqlite.0.dylib

=item libsqlite.0.0.1.dylib

=back

B<Events:>

=over 4

=item info

Searching for shared object library directory

=item error

Cannot find shared object library direcory

=item unknown

Enter a valid Expat shared object library directory

=back

=cut

sub so_lib_dir {
    my $self = shift;
    return unless $self->{sqlite};
    $self->{so_lib_dir} = $lib_dir->($self, 'shared object library')
      unless exists $self->{so_lib_dir};
    return $self->{so_lib_dir};
}

##############################################################################

=head3 inc_dir

  my $inc_dir = $sqlite->inc_dir;

Returns the directory path in which the file F<sqlite3.h> or F<sqlite.h> was
found. No search is performed if SQLite is not installed or if only
DBD::SQLite is installed.

App::Info::RDBMS::SQLite searches for F<sqlite.h> in the following
directories:

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

Enter a valid SQLite include directory

=back

=cut

sub inc_dir {
    my $self = shift;
    return unless $self->{sqlite};
    unless (exists $self->{inc_dir}) {
        $self->info("Searching for include directory");
        # Should there be more paths than this?
        my @paths = qw(/usr/local/include
                       /usr/include
                       /sw/include);
        my $incs = ['sqlite3.h', 'sqlite.h'];

        if (my $dir = $u->first_cat_dir($incs, @paths)) {
            $self->{inc_dir} = $dir;
        } else {
            $self->error("Cannot find include directory");
            $self->{inc_dir} = $self->unknown(
                key      => 'include directory',
                callback => sub { $u->first_cat_dir($incs, $_) },
                error    => "File 'sqlite.h' not found in directory"
            );
        }
    }
    return $self->{inc_dir};
}

##############################################################################

=head3 home_url

  my $home_url = $pg->home_url;

Returns the PostgreSQL home page URL.

=cut

sub home_url { "http://www.sqlite.org/" }

##############################################################################

=head3 download_url

  my $download_url = $pg->download_url;

Returns the PostgreSQL download URL.

=cut

sub download_url { "http://www.sqlite.org/download.html" }

1;
__END__

=head1 BUGS

Please send bug reports to <bug-app-info@rt.cpan.org> or file them at
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-Info>.

=head1 AUTHOR

David Wheeler <david@justatheory.com>

=head1 SEE ALSO

L<App::Info|App::Info> documents the event handling interface.

L<App::Info::RDBMS|App::Info::RDBMS> is the App::Info::RDBMS parent class from
which App::Info::RDBMS::SQLite inherits.

L<DBD::SQLite|DBD::SQLite> is the L<DBI|DBI> driver for connecting to SQLite
databases.

L<http://www.sqlite.org/> is the SQLite home page.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2004, David Wheeler. All Rights Reserved.

This module is free software; you can redistribute it and/or modify it under the
same terms as Perl itself.

=cut
