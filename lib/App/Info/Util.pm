package App::Info::Util;

# $Id: Util.pm,v 1.7 2002/06/02 00:15:00 david Exp $

=head1 NAME

App::Info::Util - Utility class for App::Info subclasses

=head1 SYNOPSIS

  use App::Info::Util;

  my $util = App::Info::Util->new;

  # Subclasses File::Spec.
  my @paths = $util->paths;

  # First directory that exists in a list.
  my $dir = $util->first_dir(@paths);

  # First directory that exists in a path.
  $dir = $util->first_path($ENV{PATH});

  # First file that exists in a list.
  my $file = $util->first_file('this.txt', '/that.txt', 'C:\\foo.txt');

  # First file found among file base names and directories.
  my $files = ['this.txt', 'that.txt'];
  $file = $util->first_cat_file($files, @paths);

=head1 DESCRIPTION

This class subclasses L<File::Spec|File::Spec> and adds a couple more methods
in order to offer utility methods to L<App::Info|App::Info> subclasses.
Although it is intended to be used by App::Info subclasses, in truth its
utiltiy may be considered more general, so feel free to use it elsewhere.

The methods added in addition to the usual File::Spec suspects are designed to
facilitate locating files and directories on the local file system. The
assumption is that, in order to provide useful metadata about a given software
package, an App::Info subclass must find relevant files and directories.
This class offers methods that may commonly be used for that task.

=cut

use strict;
use File::Spec::Functions ();
use vars qw(@ISA $VERSION);
@ISA = qw(File::Spec);
$VERSION = '0.02';

my %path_dems = (MacOS   => qr',',
                 MSWin32 => qr';',
                 os2     => qr';',
                 VMS     => undef,
                 epoc    => undef);

my $path_dem = exists $path_dems{$^O} ? $path_dems{$^O} : qr':';

=head1 CONSTRUCTOR

=head2 new

  my $util = App::Info::Util->new;

This is a very simple constructor that merely returns an App::Info::Util
object. Since, like its File::Spec super class, App::Info::Util manages no
internal data itself, all methods may be used as class methods, if one prefers
to. The constructor here is provided merely as a convenience.

=cut

sub new { bless {}, ref $_[0] || $_[0] }

=head1 OBJECT METHODS

In addition to all of the methods offered by its superclass,
L<File::Spec|File::Spec>, App::Info::Util offers the following methods.

=head2 first_dir

  my @paths = $util->paths;
  my $dir = $util->first_dir(@dirs);

Returns the first file system directory in @paths that exists on the local
file system. Only the first item in @paths that is a director will be
returned; any other paths that lead to non-directories will be ignored.

=cut

sub first_dir {
    shift;
    foreach (@_) { return $_ if -d }
    return;
}

=head2 first_path

  my $path = $ENV{PATH};
  $dir = $util->first_path($path);

Takes the $path string and splits it into a list of directory paths, based on
the path demarcator on the local file system. Then calls C<first_dir()> to
return the first directoy in the path list that exists on the local file
system. The path demarcator is specified for the following file systems:

=over 4

=item MacOS: ","

=item MSWin32: ";"

=item os2: ";"

=item VMS: undef

This method always returns undef on VMS. Patches welcome.

=item epoc: undef

This method always returns undef on epoch. Patches welcome.

=item Unix: ":"

All other operating systems are assumed to be Unix-based.

=back

=cut

sub first_path {
    return unless $path_dem;
    shift->first_dir(split /$path_dem/, shift)
}

=head2 first_file

  my $file = $util->first_file(@filelist);

Examines each of the files in @filelist and returns the first one that exists
on the local file system. The file must be a regular file -- directories will
be ignored.

=cut

sub first_file {
    shift;
    foreach (@_) { return $_ if -f }
    return;
}

=head2 first_cat_file

  my $file = $util->first_cat_file('ick.txt', @paths);
  $file = $util->first_cat_file(['this.txt', 'that.txt'], @paths);

The first argument to this method may be either a file base name (that is, a
file name without a directory specification), or an reference to an array of
file base names. The remaining arguments constitute a list of directory paths.
C<first_cat_file()> processes each of the file base names in the first
argument, concatenates them (by the method native to the local operating
system) to each of the directory path names in turn, and returns the first one
that exists on the local file system.

For example, let us say that we were looking for a file called either F<httpd>
or F<apache>, and it could be in any of the following paths: F</usr/local/bin>,
F</usr/bin/>, F</bin>. The method call looks like this:

  my $httpd = $util->first_cat_file(['httpd', 'apache'], '/usr/local/bin',
                                    '/usr/bin/', '/bin');

If the local file system is Unix-based, C<first_cat_file()> will then look for
the first file that exists in this order:

=over 4

=item /usr/local/bin/httpd

=item /usr/bin/httpd

=item /bin/httpd

=item /usr/local/bin/apache

=item /usr/bin/apache

=item /bin/apache

=back

The first of these complete file names to be found will be returned. If none
are found, then undef will be returned.

=cut

sub first_cat_file {
    my $self = shift;
    my $file = shift;
    foreach my $exe (ref $file ? @$file : ($file)) {
        foreach (@_) {
            my $path = File::Spec::Functions::catfile($_, $exe);
            return $path if -f $path;
        }
    }
    return;
}

=head2 first_cat_dir

  my $dir = $util->first_cat_file('ick.txt', @paths);
  $dir = $util->first_cat_file(['this.txt', 'that.txt'], @paths);

Funtionally identical to C<first_cat_file()>, except that it returns
the directory in which the first file was found, rather than the full
path name to the file.

=cut

sub first_cat_dir {
    my $self = shift;
    my $file = shift;
    foreach my $exe (ref $file ? @$file : ($file)) {
        foreach (@_) {
            my $path = File::Spec::Functions::catfile($_, $exe);
            return $_ if -f $path;
        }
    }
    return;
}

1;
__END__

=head1 BUGS

None. No, really! But if you find you must report them anyway, drop me an
email.

=head1 AUTHOR

David Wheeler <david@wheeler.net>

=head1 SEE ALSO

L<App::Info|App::Info>, L<File::Spec|File::Spec>,
L<App::Info::HTTPD::Apache|App::Info::HTTPD::Apache>
L<App::Info::RDBMS::PostgreSQL|App::Info::RDBMS::PostgreSQL>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2002, David Wheeler. All Rights Reserved.

This module is free software; you can redistribute it and/or modify it under the
same terms as Perl itself.

=cut
