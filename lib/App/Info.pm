package App::Info;

# $Id: Info.pm,v 1.10 2002/06/03 19:27:41 david Exp $

=head1 NAME

App::Info - Information about software packages on a system

=head1 SYNOPSIS

  use App::Info::Category::FooApp;

  my $app = App::Info::Category::FooApp->new;

  if ($app->installed) {
      print "App name: ", $app->name, "\n";
      print "Version:  ", $app->version, "\n";
      print "Bin dir:  ", $app->bin_dir, "\n";
  } else {
      print "App not installed on your system. :-(\n";
  }

=head1 DESCRIPTION

App::Info is an abstract base class designed to provide a generalized
interface for subclasses that provide meta data about software packages
installed on a system. The idea is that these classes can be used in Perl
application installers in order to determine whether software dependencies
have been fulfilled, and to get necessary meta data about those software
packages.

A few L<sample subclasses|"SEE ALSO"> are provided with the distribution, but
others are invited to write their own subclasses and contribute them to the
CPAN. Contributors are welcome to extend their subclasses to provide more
information relevant to the application for which data is to be provided (see
L<App::Info::HTTPD::Apache|App::Info::HTTPD::Apache> for an example), but are
encouraged to, at a minimum, implement the methods defined here and in the
category abstract base classes (e.g. L<App::Info::HTTPD|App::Info::HTTPD> and
L<App::Info::Lib|App::Info::Lib>. See L<"NOTES ON SUBCLASSING"> for more
information on adding new sofware package subclasses.

=cut

use strict;
use Carp ();

our $VERSION = '0.04';

my $croak = sub {
    my ($caller, $meth) = @_;
    $caller = ref $caller || $caller;
    if ($caller eq __PACKAGE__) {
        $meth = __PACKAGE__ . '::' . shift;
        Carp::croak(__PACKAGE__ . " is an abstract base class. Attempt to " .
                    " call non-existent method $meth");
    } else {
        Carp::croak("Class $caller inherited from the abstract base class " .
                    __PACKAGE__ . "but failed to redefine the $meth method. " .
                    "Attempt to call non-existent method ${caller}::$meth");
    }
};

sub new { $croak->(shift, 'new') }
sub installed { $croak->(shift, 'installed') }
sub name { $croak->(shift, 'name') }
sub version { $croak->(shift, 'version') }
sub major_version { $croak->(shift, 'major_version') }
sub minor_version { $croak->(shift, 'minor_version') }
sub patch_version { $croak->(shift, 'patch_version') }
sub inc_dir { $croak->(shift, 'inc_dir') }
sub bin_dir { $croak->(shift, 'bin_dir') }
sub lib_dir { $croak->(shift, 'lib_dir') }
sub so_lib_dir { $croak->(shift, 'so_lib_dir') }
sub home_url  { $croak->(shift, 'home_url') }
sub download_url  { $croak->(shift, 'download_url') }


1;
__END__

=head1 CONSTRUTORS

=head2 new

  my $app = App::Info::Category::FooApp;

Consructs the FooApp App::Info object.

=head1 OBJECT METHODS

=head2 installed

  if ($app->installed) {
      print "App is installed.\n"
  } else {
      print "App is not installed.\n"
  }

Returns a true value of the application is installed, and a false value if it
is not.

=head2 name

  my $name = $app->name;

Returns the name of the application.

=head2 version

  my $version = $app->version;

Returns the full version number of the application.

=head2 major_version

  my $major_version = $app->major_version;

Returns the major version number of the application. For example, if
C<version()> returns "7.1.2", then this method returns "7".

=head2 minor_version

  my $minor_version = $app->minor_version;

Returns the minor version number of the application. For example, if
C<version()> returns "7.1.2", then this method returns "1".

=head2 patch_version

  my $patch_version = $app->patch_version;

Returns the patch version number of the application. For example, if
C<version()> returns "7.1.2", then this method returns "2".

=head2 bin_dir

  my $bin_dir = $app->bin_dir;

Returns the full path the application's bin directory, if it exists.

=head2 inc_dir

  my $inc_dir = $app->inc_dir;

Returns the full path the application's include directory, if it exists.

=head2 lib_dir

  my $lib_dir = $app->lib_dir;

Returns the full path the application's lib directory, if it exists.

=head2 so_lib_dir

  my $so_lib_dir = $app->so_lib_dir;

Returns the full path the application's shared library directory, if it
exists.

=head2 home_url

  my $home_url = $app->home_url;

The URL for the software's home page.

=head2 download_url

  my $download_url = $app->download_url;

The URL for the software's download page.

=head1 NOTES ON SUBCLASSING

The organizational idea behind App::Info is to name subclasses by broad
software categories. This allows the categories to function as abstract base
classes that extend App::Info, so that they can specify more methods for all
of their base classes to implement. For example, L<App::Info::HTTPD> has
specified the C<httpd_root()> abstract method that its subclasses must
implement. So as you get ready to implement your own subclass, think about
what category of software you're gathering information about. New categories
can be added as needed.

Feel free to use the subclasses included in this distribution as examples to
follow when creating your own subclasses. I've tried to encapsulate common
functionality in L<App::Info::Util|App::Info::Util> to make the job easiser. I
found that most of what I was doing repetitively was looking for files and
directories, and searching through files. Thus, App::Info::Util subclasses
L<File::Spec|File::Spec> in order to offer easy access to commonly-used
methods from that class (e.g., C<path()>. Plus, it has several of its own
methods to assist you in finding files and directories in lists of files and
directories, as well as methods for searching through files and returning the
values found in those files. See L<App::Info::Util|App::Info::Util> for more
information, and the App::Info subclasses in this distribution for actual
usage examples.

To save resources as much as possible, I recommend implementing the App::Info
subclasses as singleton objects. The reason for this is that the information
about a software package is unlikely to change during the execution of a
program. More likely, if the relevant information about software packages
cannot be found or does not meet immediate needs, and program using App:Info
will tell the user to install or upgrade the software and then exit. Once the
software has been installed or upgraded, the program will be run again. This
makes sense given App::Info's target of assisting insallation programs to
determine dependencies; they only need to verify those dependencies once.

Please also be sure to implement B<all> of the abstract methods defined by
your abstract base class -- even if they don't do anythin. Doing so ensures
that all App::Info subclasses share a common interface, and can, if necessary,
be used without regard to subclass. Any method not implemented but called on
an object will generate an exception.

Otherwise, have fun! There are a lot of software packages out that for which
relevant information might be collected and aggregated into an App::Info
subclass (witness all of the Automake macros in the world!), and folks who are
knowledgable about particular software packages or categories of software are
warmly invited to contribute. As more subclasses are implemented, it will make
sense, I think, to create separate distributions based on category -- or even,
when necessary, on a single software package. Broader categories can then be
aggregated in Bundle distributions.

But I get ahead of myself...

=head1 BUGS

Can there really be much in the way of bugs in an abstract base class? Drop me
a line if you happen to discover any.

=head1 AUTHOR

David Wheeler <david@wheeler.net>

=head1 SEE ALSO

L<App::Info::Lib|App::Info::HTTPD>,
L<App::Info::Lib|App::Info::RDBMS>,
L<App::Info::Lib|App::Info::Lib>,
L<App::Info::HTTPD::Apache|App::Info::HTTPD::Apache>
L<App::Info::RDBMS::PostgreSQL|App::Info::RDBMS::PostgreSQL>
L<App::Info::Lib|App::Info::Lib::Expat>,
L<App::Info::Lib|App::Info::Lib::Iconv>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2002, David Wheeler. All Rights Reserved.

This module is free software; you can redistribute it and/or modify it under the
same terms as Perl itself.

=cut
