package App::Info::RDBMS::PostgreSQL;

# $Id: PostgreSQL.pm,v 1.10 2002/06/03 18:12:33 david Exp $

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
methods defined by App::Info::RDBMS.

When it loads, App::Info::RDBMS::PostgreSQL searches the local file system for
the F<pg_config> application. If found, F<pg_config> will be called to gather
the data necessary for each of the methods below. If F<pg_config> cannot be
found, then PostgreSQL is assumed not to be installed, and each of the methods
will return undef.

App::Info::RDBMS::PostgreSQL searches for F<pg_config> along your path, as
defined by File::Spec->path. Failing that, it searches the following
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

use strict;
use App::Info::RDBMS;
use App::Info::Util;
use vars qw(@ISA $VERSION);
@ISA = qw(App::Info::RDBMS);
$VERSION = '0.03';

my $obj = {};
my $u = App::Info::Util->new;

do {
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

    $obj->{pg_config} = $u->first_cat_path('pg_config', @paths);
};

=head1 CONSTRUCTOR

=head2 new

  my $pg = App::Info::RDBMS::PostgreSQL->new;

Returns an App::Info::RDBMS::PostgreSQL object. Since
App::Info::RDBMS::PostgreSQL is implemented as a singleton class, the same
object will be returned every time. This ensures that only the minimum number
of system calls are made to gather the data necessary for the object methods.

=cut

sub new { bless $obj, ref $_[0] || $_[0] }

# We'll use this code reference as a common way of collecting data.

my $get_data = sub {
    my $pgc = $_[0]->{pg_config} || return;
    my $info = `$pgc $_[1]`;
    chomp $info;
    return $info;
};

=head1 OBJECT METHODS

=head2 installed

  print "PostgreSQL is ", ($pg->installed ? '' : 'not '), "installed.\n";

Returns true if PostgreSQL is installed, and false if it is not.
App::Info::RDBMS::PostgreSQL determines whether PostgreSQL is installed based
on the presence or absence of the F<pg_config> application on the file
system.

=cut

sub installed { return $_[0]->{pg_config} ? 1 : undef }

=head2 name

  my $name = $pg->name;

Returns the name of the application. App::Info::RDBMS::PostgreSQL parses the
name from the system call C<`pg_config --version`>. Returns undef if
PostgreSQL is not installed. Emits a warning if PostgreSQL is installed but
the version number could not be parsed.

=cut

sub name {
    unless ($_[0]->{name}) {
        my $data = $get_data->($_[0], '--version');
        unless ($data) {
            Carp::carp("Failed to find PostgreSQL version with ".
                       "`$_[0]->{pg_config} --version");
            return;
        }

        chomp $data;
        my ($name, $version) =  split /\s+/, $data, 2;
        Carp::carp("Unable to parse name from string '$data'") unless $name;

        if ($version) {
            my ($x, $y, $z) = $version =~ /(\d+)\.(\d+).(\d+)/;
            unless (defined $x and defined $y and defined $z) {
                Carp::carp("Failed to parse PostgreSQL version parts from string ".
                           "'$version'");
            }
            @{$_[0]}{qw(name version major minor patch)} =
              ($name, $version, $x, $y, $z);
        } else {
            Carp::carp("Unable to parse version from string '$data'");
            $_[0]->{name} = $name;
        }
    }
    return $_[0]->{name};
}

=head2 version

  my $version = $pg->version;

Returns the PostgreSQL version number. App::Info::RDBMS::PostgreSQL parses the
version number from the system call C<`pg_config --version`>. Returns undef if
PostgreSQL is not installed. Emits a warning if PostgreSQL is installed but
the version number could not be parsed.

=cut

sub version {
    $_[0]->name unless $_[0]->{version};
    return $_[0]->{version};
}

=head2 major version

  my $major_version = $pg->major_version;

Returns the PostgreSQL major version number. App::Info::RDBMS::PostgreSQL
parses the major version number from the system call C<`pg_config --version`>.
For example, C<version()> returns "7.1.2", then this method returns "7".
Returns undef if PostgreSQL is not installed. Emits a warning if PostgreSQL is
installed but the version number could not be parsed.

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
Returns undef if PostgreSQL is not installed. Emits a warning if PostgreSQL is
installed but the version number could not be parsed.

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
Returns undef if PostgreSQL is not installed. Emits a warning if PostgreSQL is
installed but the version number could not be parsed.

=cut

sub patch_version {
    $_[0]->name unless $_[0]->{version};
    return $_[0]->{patch};
}

=head2 bin_dir

  my $bin_dir = $pg->bin_dir;

Returns the PostgreSQL binary directory path. App::Info::RDBMS::PostgreSQL
gathers the path from the system call C<`pg_config --bindir`>. Returns undef
if PostgreSQL is not installed.

=cut

sub bin_dir {
    $_[0]->{bin_dir} ||= $get_data->($_[0], '--bindir');
    return $_[0]->{bin_dir};
}

=head2 inc_dir

  my $inc_dir = $pg->inc_dir;

Returns the PostgreSQL include directory path. App::Info::RDBMS::PostgreSQL
gathers the path from the system call C<`pg_config --includedir`>. Returns
undef if PostgreSQL is not installed.

=cut

sub inc_dir {
    $_[0]->{inc_dir} ||= $get_data->($_[0], '--includedir');
    return $_[0]->{inc_dir};
}

=head2 lib_dir

  my $lib_dir = $pg->lib_dir;

Returns the PostgreSQL library directory path. App::Info::RDBMS::PostgreSQL
gathers the path from the system call C<`pg_config --libdir`>. Returns undef
if PostgreSQL is not installed.

=cut

sub lib_dir {
    $_[0]->{lib_dir} ||= $get_data->($_[0], '--libdir');
    return $_[0]->{lib_dir};
}

=head2 so_lib_dir

  my $so_lib_dir = $pg->so_lib_dir;

Returns the PostgreSQL shared object library directory path.
App::Info::RDBMS::PostgreSQL gathers the path from the system call
C<`pg_config --pkglibdir`>. Returns undef if PostgreSQL is not installed.

=cut

# Location of dynamically loadable modules.
sub so_lib_dir {
    $_[0]->{so_lib_dir} ||= $get_data->($_[0], '--pkglibdir');
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
