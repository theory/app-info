package App::Info::RDBMS::PostgreSQL;

# $Id: PostgreSQL.pm,v 1.15 2002/06/05 23:46:52 david Exp $

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
$VERSION = '0.06';

my $u = App::Info::Util->new;

=head1 CONSTRUCTOR

=head2 new

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

=cut

sub new {
    # Construct the object.
    my $self = shift->SUPER::new(@_);

    # Find pg_config.
    my @paths = ($u->path,
      qw(/usr/local/pgsql/bin
         /usr/local/postgres/bin
         /opt/pgsql/bin
         /usr/local/bin
         /usr/local/sbin
         /usr/bin
         /usr/sbin
         /bin));

    $self->{pg_config} = $u->first_cat_exe('pg_config', @paths);
    return $self;
}

# We'll use this code reference as a common way of collecting data.

my $get_data = sub {
    return unless $_[0]->{pg_config};
    my $info = `$_[0]->{pg_config} $_[1]`;
    chomp $info;
    return $info;
};

=head1 OBJECT METHODS

=head2 installed

  print "PostgreSQL is ", ($pg->installed ? '' : 'not '), "installed.\n";

Returns true if PostgreSQL is installed, and false if it is not.
App::Info::RDBMS::PostgreSQL determines whether PostgreSQL is installed based
on the presence or absence of the F<pg_config> application on the file system
as found when C<new()> constructed the object. If PostgreSQL does not appear
to be installed, then all of the other object methods will return empty
values.

=cut

sub installed { return $_[0]->{pg_config} ? 1 : undef }

=head2 name

  my $name = $pg->name;

Returns the name of the application. App::Info::RDBMS::PostgreSQL parses the
name from the system call C<`pg_config --version`>. Throws an error if
PostgreSQL is installed but the version number or name could not be parsed.

=cut

sub name {
    my $self = shift;
    return unless $self->{pg_config};
    unless (exists $self->{name}) {
        $self->{name} = undef;
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
    }
    return $self->{name};
}

=head2 version

  my $version = $pg->version;

Returns the PostgreSQL version number. App::Info::RDBMS::PostgreSQL parses the
version number from the system call C<`pg_config --version`>. See the
L<name|"name"> method for a list of possible errors.

=cut

sub version {
    $_[0]->name unless $_[0]->{version};
    return $_[0]->{version};
}

=head2 major version

  my $major_version = $pg->major_version;

Returns the PostgreSQL major version number. App::Info::RDBMS::PostgreSQL
parses the major version number from the system call C<`pg_config --version`>.
For example, C<version()> returns "7.1.2", then this method returns "7". See
the L<name|"name"> method for a list of possible errors.

=cut

sub major_version {
    $_[0]->name unless $_[0]->{version};
    return $_[0]->{major};
}

=head2 minor version

  my $minor_version = $pg->minor_version;

Returns the PostgreSQL minor version number. App::Info::RDBMS::PostgreSQL
parses the minor version number from the system call C<`pg_config --version`>.
For example, if C<version()> returns "7.1.2", then this method returns "2".
See the L<name|"name"> method for a list of possible errors.

=cut

sub minor_version {
    $_[0]->name unless $_[0]->{version};
    return $_[0]->{minor};
}

=head2 patch version

  my $patch_version = $pg->patch_version;

Returns the PostgreSQL patch version number. App::Info::RDBMS::PostgreSQL
parses the patch version number from the system call C<`pg_config --version`>.
For example, if C<version()> returns "7.1.2", then this method returns "1".
See the L<name|"name"> method for a list of possible errors.

=cut

sub patch_version {
    $_[0]->name unless $_[0]->{version};
    return $_[0]->{patch};
}

=head2 bin_dir

  my $bin_dir = $pg->bin_dir;

Returns the PostgreSQL binary directory path. App::Info::RDBMS::PostgreSQL
gathers the path from the system call C<`pg_config --bindir`>. Throws an error
if the binary directory path cannot be determined.

=cut

sub bin_dir {
    unless (exists $_[0]->{bin_dir} ) {
        if (my $dir = $get_data->($_[0], '--bindir')) {
            $_[0]->{bin_dir} = $dir;
        } else {
            $_[0]->error("Could not find bin directory");
            $_[0]->{bin_dir} = undef;
        }
    }
    return $_[0]->{bin_dir};
}

=head2 inc_dir

  my $inc_dir = $pg->inc_dir;

Returns the PostgreSQL include directory path. App::Info::RDBMS::PostgreSQL
gathers the path from the system call C<`pg_config --includedir`>. Throws an
error if the include directory path cannot be determined.

=cut

sub inc_dir {
    unless (exists $_[0]->{inc_dir} ) {
        if (my $dir = $get_data->($_[0], '--includedir')) {
            $_[0]->{inc_dir} = $dir;
        } else {
            $_[0]->error("Could not find bin directory");
            $_[0]->{inc_dir} = undef;
        }
    }
    return $_[0]->{inc_dir};
}

=head2 lib_dir

  my $lib_dir = $pg->lib_dir;

Returns the PostgreSQL library directory path. App::Info::RDBMS::PostgreSQL
gathers the path from the system call C<`pg_config --libdir`>. Throws an error
if the library directory path cannot be determined.

=cut

sub lib_dir {
    unless (exists $_[0]->{lib_dir} ) {
        if (my $dir = $get_data->($_[0], '--libdir')) {
            $_[0]->{lib_dir} = $dir;
        } else {
            $_[0]->error("Could not find bin directory");
            $_[0]->{lib_dir} = undef;
        }
    }
    return $_[0]->{lib_dir};
}

=head2 so_lib_dir

  my $so_lib_dir = $pg->so_lib_dir;

Returns the PostgreSQL shared object library directory path.
App::Info::RDBMS::PostgreSQL gathers the path from the system call
C<`pg_config --pkglibdir`>. Throws an error if the shared object library
directory path cannot be determined.

=cut

# Location of dynamically loadable modules.
sub so_lib_dir {
    unless (exists $_[0]->{so_lib_dir} ) {
        if (my $dir = $get_data->($_[0], '--pkglibdir')) {
            $_[0]->{so_lib_dir} = $dir;
        } else {
            $_[0]->error("Could not find bin directory");
            $_[0]->{so_lib_dir} = undef;
        }
    }
    return $_[0]->{so_lib_dir};
}

=head2 home_url

  my $home_url = $pg->home_url;

Returns the PostgreSQL home page URL.

=cut

sub home_url { "http://www.postgresql.org/" }

=head2 download_url

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
