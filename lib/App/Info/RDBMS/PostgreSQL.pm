package App::Info::RDBMS::PostgreSQL;

# $Id: PostgreSQL.pm,v 1.16 2002/06/17 17:24:05 david Exp $

=head1 NAME

App::Info::RDBMS::PostgreSQL - Information about PostgreSQL

=head1 SYNOPSIS

  use App::Info::RDBMS::PostgreSQL;

  my $pg = App::Info::RDBMS::PostgreSQL->new;

  if ($pg->installed) {
      print "App name: ", $pg->name, "\n";
      print "Version:  ", $pg->version, "\n";
      print "Bin dir:  ", $pg->bin_dir, "\n";
  } else {
      print "PostgreSQL is not installed. :-(\n";
  }

=head1 DESCRIPTION

App::Info::RDBMS::PostgreSQL supplies information about the PostgreSQL
database server installed on the local system. It implements all of the
methods defined by App::Info::RDBMS. Methods that throw errors will throw them
only the first time they're called. To start over (after, say, someone has
installed PostgreSQL) construct a new App::Info::RDBMS::PostgreSQL object to
aggregate new metadata.

=cut

use strict;
use App::Info::RDBMS;
use App::Info::Util;
use vars qw(@ISA $VERSION);
@ISA = qw(App::Info::RDBMS);
$VERSION = '0.20';

my $u = App::Info::Util->new;

=head1 INTERFACE

=head2 Constructor

=head3 new

  my $pg = App::Info::RDBMS::PostgreSQL->new(@params);

Returns an App::Info::RDBMS::PostgreSQL object. See L<App::Info|App::Info> for
a complete description of argument parameters.

When it called, C<new()> searches the file system for the F<pg_config>
application. If found, F<pg_config> will be called by the object methods below
to gather the data necessary for each. If F<pg_config> cannot be found, then
PostgreSQL is assumed not to be installed, and each of the object methods will
return C<undef>.

App::Info::RDBMS::PostgreSQL searches for F<pg_config> along your path, as
defined by C<File::Spec->path>. Failing that, it searches the following
directories:

=over 4

=item /usr/local/pgsql/bin

=item /usr/local/postgres/bin

=item /opt/pgsql/bin

=item /usr/local/bin

=item /usr/local/sbin

=item /usr/bin

=item /usr/sbin

=item /bin

=back

B<Events:>

=over 4

=item info

Looking for pg_config

=item confirm

Path to pg_config?

=item unknown

Path to pg_config?

=back

=cut

sub new {
    # Construct the object.
    my $self = shift->SUPER::new(@_);

    # Find pg_config.
    $self->info("Looking for pg_config");
    my @paths = ($u->path,
      qw(/usr/local/pgsql/bin
         /usr/local/postgres/bin
         /opt/pgsql/bin
         /usr/local/bin
         /usr/local/sbin
         /usr/bin
         /usr/sbin
         /bin));

    if (my $cfg = $u->first_cat_exe('pg_config', @paths)) {
        # We found it. Confirm.
        $self->{pg_config} = $self->confirm('pg_config',
                                            'Path to pg_config?',
                                            $cfg, sub { -x },
                                            'Not an executable');
    } else {
        # Handle an unknown value.
        $self->{pg_config} = $self->unknown('pg_config',
                                            'Path to pg_config?',
                                            sub { -x },
                                            'Not an executable');
    }

    return $self;
}

# We'll use this code reference as a common way of collecting data.
my $get_data = sub {
    return unless $_[0]->{pg_config};
    $_[0]->info("Executing `$_[0]->{pg_config} $_[1]`");
    my $info = `$_[0]->{pg_config} $_[1]`;
    chomp $info;
    return $info;
};

##############################################################################

=head2 Class Method

=head3 key_name

  my $key_name = App::Info::RDBMS::PostgreSQL->key_name;

Returns the unique key name that describes this class. The value returned is
the string "PostgreSQL".

=cut

sub key_name { 'PostgreSQL' }

##############################################################################

=head2 Object Methods

=head3 installed

  print "PostgreSQL is ", ($pg->installed ? '' : 'not '), "installed.\n";

Returns true if PostgreSQL is installed, and false if it is not.
App::Info::RDBMS::PostgreSQL determines whether PostgreSQL is installed based
on the presence or absence of the F<pg_config> application on the file system
as found when C<new()> constructed the object. If PostgreSQL does not appear
to be installed, then all of the other object methods will return empty
values.

=cut

sub installed { return $_[0]->{pg_config} ? 1 : undef }

##############################################################################

=head3 name

  my $name = $pg->name;

Returns the name of the application. App::Info::RDBMS::PostgreSQL parses the
name from the system call C<`pg_config --version`>.

B<Events:>

=over 4

=item info

Executing `pg_config --version`

=item error

Failed to find PostgreSQL version with `pg_config --version`

Unable to parse name from string

Unable to parse version from string

Failed to parse PostgreSQL version parts from string

=item unknown

Enter a valid PostgreSQL name

=back

=cut

# This code reference is used by name(), version(), major_version(),
# minor_version(), and patch_version() to aggregate the data they need.
my $get_version = sub {
    my $self = shift;
    $self->{'--version'} = 1;
    my $data = $get_data->($self, '--version');
    unless ($data) {
        $self->error("Failed to find PostgreSQL version with ".
                     "`$self->{pg_config} --version");
            return;
    }

    chomp $data;
    my ($name, $version) =  split /\s+/, $data, 2;

    # Check for and assign the name.
    $name ?
      $self->{name} = $name :
      $self->error("Unable to parse name from string '$data'");

    # Parse the version number.
    if ($version) {
        my ($x, $y, $z) = $version =~ /(\d+)\.(\d+).(\d+)/;
        if (defined $x and defined $y and defined $z) {
            @{$self}{qw(version major minor patch)} =
              ($version, $x, $y, $z);
        } else {
            $self->error("Failed to parse PostgreSQL version parts from " .
                         "string '$version'");
        }
    } else {
        $self->error("Unable to parse version from string '$data'");
    }
};

sub name {
    my $self = shift;
    return unless $self->{pg_config};

    # Load data.
    $get_version->($self) unless $self->{'--version'};

    # Handle an unknown name.
    $self->{name} = $self->unknown('name') unless $self->{name};

    # Return the name.
    return $self->{name};
}

##############################################################################

=head3 version

  my $version = $pg->version;

Returns the PostgreSQL version number. App::Info::RDBMS::PostgreSQL parses the
version number from the system call C<`pg_config --version`>.

B<Events:>

=over 4

=item info

Executing `pg_config --version`

=error

Failed to find PostgreSQL version with `pg_config --version`

Unable to parse name from string

Unable to parse version from string

Failed to parse PostgreSQL version parts from string

=item unknown

Enter a valid PostgreSQL version number

=back

=cut

sub version {
    my $self = shift;
    return unless $self->{pg_config};

    # Load data.
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
        $self->{version} =
          $self->unknown('version number', undef, $chk_version);
    }

    return $self->{version};
}

##############################################################################

=head3 major version

  my $major_version = $pg->major_version;

Returns the PostgreSQL major version number. App::Info::RDBMS::PostgreSQL
parses the major version number from the system call C<`pg_config --version`>.
For example, C<version()> returns "7.1.2", then this method returns "7".

B<Events:>

=over 4

=item info

Executing `pg_config --version`

=error

Failed to find PostgreSQL version with `pg_config --version`

Unable to parse name from string

Unable to parse version from string

Failed to parse PostgreSQL version parts from string

=item unknown

Enter a valid PostgreSQL major version number

=back

=cut

# This code reference is used by major_version(), minor_version(), and
# patch_version() to validate a version number entered by a user.
my $is_int = sub { /^\d+$/ };

sub major_version {
    my $self = shift;
    return unless $self->{pg_config};
    # Load data.
    $get_version->($self) unless exists $self->{'--version'};
    # Handle an unknown value.
    $self->{major} = $self->unknown('major version number', undef, $is_int)
      unless $self->{major};
    return $self->{major};
}

##############################################################################

=head3 minor version

  my $minor_version = $pg->minor_version;

Returns the PostgreSQL minor version number. App::Info::RDBMS::PostgreSQL
parses the minor version number from the system call C<`pg_config --version`>.
For example, if C<version()> returns "7.1.2", then this method returns "2".

B<Events:>

=over 4

=item info

Executing `pg_config --version`

=error

Failed to find PostgreSQL version with `pg_config --version`

Unable to parse name from string

Unable to parse version from string

Failed to parse PostgreSQL version parts from string

=item unknown

Enter a valid PostgreSQL minor version number

=back

=cut

sub minor_version {
    my $self = shift;
    return unless $self->{pg_config};
    # Load data.
    $get_version->($self) unless exists $self->{'--version'};
    # Handle an unknown value.
    $self->{minor} = $self->unknown('minor version number', undef, $is_int)
      unless defined $self->{minor};
    return $self->{minor};
}

##############################################################################

=head3 patch version

  my $patch_version = $pg->patch_version;

Returns the PostgreSQL patch version number. App::Info::RDBMS::PostgreSQL
parses the patch version number from the system call C<`pg_config --version`>.
For example, if C<version()> returns "7.1.2", then this method returns "1".

B<Events:>

=over 4

=item info

Executing `pg_config --version`

=error

Failed to find PostgreSQL version with `pg_config --version`

Unable to parse name from string

Unable to parse version from string

Failed to parse PostgreSQL version parts from string

=item unknown

Enter a valid PostgreSQL minor version number

=back

=cut

sub patch_version {
    my $self = shift;
    return unless $self->{pg_config};
    # Load data.
    $get_version->($self) unless exists $self->{'--version'};
    # Handle an unknown value.
    $self->{patch} = $self->unknown('patch version number', undef, $is_int)
      unless defined $self->{patch};
    return $self->{patch};
}

##############################################################################

=head3 bin_dir

  my $bin_dir = $pg->bin_dir;

Returns the PostgreSQL binary directory path. App::Info::RDBMS::PostgreSQL
gathers the path from the system call C<`pg_config --bindir`>.

B<Events:>

=over 4

=item info

Executing `pg_config --bindir`

=item error

Could not find bin directory

=item unknown

Enter a valid PostgreSQL bin directory

=back

=cut

# This code reference is used by bin_dir(), lib_dir(), and so_lib_dir() to
# validate a directory entered by the user.
my $is_dir = sub { -d };

sub bin_dir {
    my $self = shift;
    return unless $self->{pg_config};
    unless (exists $self->{bin_dir} ) {
        if (my $dir = $get_data->($self, '--bindir')) {
            $self->{bin_dir} = $dir;
        } else {
            # Handle an unknown value.
            $self->error("Could not find bin directory");
            $self->{bin_dir} = $self->unknown('bin directory', undef, $is_dir)
        }
    }

    return $self->{bin_dir};
}

##############################################################################

=head3 inc_dir

  my $inc_dir = $pg->inc_dir;

Returns the PostgreSQL include directory path. App::Info::RDBMS::PostgreSQL
gathers the path from the system call C<`pg_config --includedir`>.

B<Events:>

=over 4

=item info

Executing `pg_config --includedir`

=item error

Could not find include directory

=item unknown

Enter a valid PostgreSQL include directory

=back

=cut

sub inc_dir {
    my $self = shift;
    return unless $self->{pg_config};
    unless (exists $self->{inc_dir} ) {
        if (my $dir = $get_data->($self, '--includedir')) {
            $self->{inc_dir} = $dir;
        } else {
            # Handle an unknown value.
            $self->error("Could not find include directory");
            $self->{inc_dir} = $self->unknown('include directory', undef, $is_dir)
        }
    }

    return $self->{inc_dir};
}

##############################################################################

=head3 lib_dir

  my $lib_dir = $pg->lib_dir;

Returns the PostgreSQL library directory path. App::Info::RDBMS::PostgreSQL
gathers the path from the system call C<`pg_config --libdir`>.

B<Events:>

=over 4

=item info

Executing `pg_config --includedir`

=item error

Could not find library directory

=item unknown

Enter a valid PostgreSQL library directory

=back

=cut

sub lib_dir {
    my $self = shift;
    return unless $self->{pg_config};
    unless (exists $self->{lib_dir} ) {
        if (my $dir = $get_data->($self, '--libdir')) {
            $self->{lib_dir} = $dir;
        } else {
            # Handle an unknown value.
            $self->error("Could not find library directory");
            $self->{lib_dir} = $self->unknown('library directory', undef, $is_dir)
        }
    }

    return $self->{lib_dir};
}

##############################################################################

=head3 so_lib_dir

  my $so_lib_dir = $pg->so_lib_dir;

Returns the PostgreSQL shared object library directory path.
App::Info::RDBMS::PostgreSQL gathers the path from the system call
C<`pg_config --pkglibdir`>.

B<Events:>

=over 4

=item info

Executing `pg_config --includedir`

=item error

Could not find shared object library directory

=item unknown

Enter a valid PostgreSQL shared object library directory

=back

=cut

# Location of dynamically loadable modules.
sub so_lib_dir {
    my $self = shift;
    return unless $self->{pg_config};
    unless (exists $self->{so_lib_dir} ) {
        if (my $dir = $get_data->($self, '--pkglibdir')) {
            $self->{so_lib_dir} = $dir;
        } else {
            # Handle an unknown value.
            $self->error("Could not find shared object library directory");
            $self->{so_lib_dir} =
              $self->unknown('shared object library directory', undef, $is_dir)
        }
    }

    return $self->{so_lib_dir};
}

##############################################################################

=head3 home_url

  my $home_url = $pg->home_url;

Returns the PostgreSQL home page URL.

=cut

sub home_url { "http://www.postgresql.org/" }

##############################################################################

=head3 download_url

  my $download_url = $pg->download_url;

Returns the PostgreSQL download URL.

=cut

sub download_url { "http://www.ca.postgresql.org/sitess.html" }

1;
__END__

=head1 BUGS

Feel free to drop me a line if you discover any bugs. Patches welcome.

=head1 AUTHOR

David Wheeler <david@wheeler.net> based on code by Sam Tregar
<sam@tregar.com>.

=head1 SEE ALSO

L<App::Info|App::Info>,
L<App::Info::RDBMS|App::Info::RDBMS>,
L<DBD::Pg|DBD::Pg>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2002, David Wheeler. All Rights Reserved.

This module is free software; you can redistribute it and/or modify it under the
same terms as Perl itself.

=cut
