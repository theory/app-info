package App::Info;

# $Id: Info.pm,v 1.20 2002/06/08 07:22:06 david Exp $

=head1 NAME

App::Info - Information about software packages on a system

=head1 SYNOPSIS

  use App::Info::Category::FooApp;

  my $app = App::Info::Category::FooApp->new( error_level => 'croak' );

  if ($app->installed) {
      print "App name: ", $app->name, "\n";
      print "Version:  ", $app->version, "\n";
      print "Bin dir:  ", $app->bin_dir, "\n";
  } else {
      print "App not installed on your system. :-(\n";
  }

=head1 DESCRIPTION

App::Info is an abstract base class designed to provide a generalized
interface for subclasses that provide metadata about software packages
installed on a system. The idea is that these classes can be used in Perl
application installers in order to determine whether software dependencies
have been fulfilled, and to get necessary metadata about those software
packages.

A few L<sample subclasses|"SEE ALSO"> are provided with the distribution, but
others are invited to write their own subclasses and contribute them to the
CPAN. Contributors are welcome to extend their subclasses to provide more
information relevant to the application for which data is to be provided (see
L<App::Info::HTTPD::Apache|App::Info::HTTPD::Apache> for an example), but are
encouraged to, at a minimum, implement the methods defined here and in the
category abstract base classes (e.g. L<App::Info::HTTPD|App::Info::HTTPD> and
L<App::Info::Lib|App::Info::Lib>. See L<"NOTES ON SUBCLASSING"> for more
information on implementing new subclasses.

=cut

use strict;
use Carp ();
use vars qw($VERSION);

$VERSION = '0.12';

my %handlers;

sub register_handler {
    my ($pkg, $key, $code) = @_;
    Carp::croak("Handler '$key' already exists")
      if $handlers{$key};
    $handlers{$key} = $code;
}

my $croak = sub {
    my ($caller, $meth) = @_;
    $caller = ref $caller || $caller;
    if ($caller eq __PACKAGE__) {
        $meth = __PACKAGE__ . '::' . shift;
        Carp::croak(__PACKAGE__ . " is an abstract base class. Attempt to " .
                    " call non-existent method $meth");
    } else {
        Carp::croak("Class $caller inherited from the abstract base class " .
                    __PACKAGE__ . ", but failed to redefine the $meth() " .
                    "method. Attempt to call non-existent method " .
                    "${caller}::$meth");
    }
};

my $set_handlers = sub {
    my $on_key = shift;
    # Default is to do nothing.
    return [] unless $on_key;
    my $ref = ref $on_key;
    if ($ref) {
        $on_key = [$on_key] unless $ref eq 'ARRAY';
        # Make sure they're all handlers.
        foreach my $h (@$on_key) {
            if (my $r = ref $h) {
                Carp::croak("$r object is not an App::Info::Handler")
                  unless UNIVERSAL::isa($h, 'App::Info::Handler');
            } else {
                # Look up the handler.
                Carp::croak("No such handler '$h'") unless $handlers{$on_key};
                # $h is an alias, so direct assignment works.
                $h = $handlers{$h}->();
            }
        }
        # Return 'em!
        return $on_key;
    } else {
        # Look up the handler.
        Carp::croak("No such handler '$on_key'")
          unless $handlers{$on_key};
        return [ $handlers{$on_key}->() ];
    }
};

sub new {
    my ($pkg, %p) = @_;
    my $class = ref $pkg || $pkg;
    # Fail if the method isn't overridden.
    $croak->($pkg, 'new') if $class eq __PACKAGE__;

    # We can dump support for error_level eventually.
    my $on_err = $p{on_error} || $p{error_level};
    $p{on_error} = $set_handlers->($on_err);
    $p{on_null} = $set_handlers->($p{on_null});

    # Do it!
    return bless \%p, $class;
}

sub error {
    my $self = shift;
    # Sanity check. We really want to keep control over this.
    Carp::croak("Cannot call protected method error()")
      unless UNIVERSAL::isa($self, __PACKAGE__);

    # Do the deed.
    foreach my $eh (@{$self->{on_error}}) {
        last if $eh->handler(@_) eq OK;
    }

    # If we haven't died, save the error.
    $self->{error} = $_[0]->{error};
}

sub null {
    my $self = shift;
    # Sanity check. We really want to keep control over this.
    Carp::croak("Cannot call protected method error()")
      unless UNIVERSAL::isa($self, __PACKAGE__);

    # Do the deed.
    foreach my $eh (@{$self->{on_null}}) {
        last if $eh->handler(@_) eq OK;
    }
}

sub last_error { $_[0]->{error} }
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

  my $app = App::Info::Category::FooApp->new;
  my $app = App::Info::Category::FooApp->new( error_level => 'confess' );

Consructs the FooApp App::Info object and returns it. The C<error_level>
parameter determines how the object will behave when it encounters an error,
such as when a specific file can't be found or a value can't be parsed from a
file. The options are:

=over 4

=item confess

Calls C<Carp::confess()>, causing the application to die and display a
detailed stack trace, as well as the error message.

=item croak

Calls C<Carp::croak()>, causing the application to die and display the error
message.

=item die

Alias for "croak"

=item cluck

Calls C<Carp::cluck()>, which prints the error message and a complete stack
trace as a warning.

=item carp

Calls C<Carp::carp()>, which prints the error message as a warning. This is
the default error level.

=item warn

Alias for "carp".

=item silent

Ignores the error.

=back

In the cases of "cluck", "carp", "warn", and "silent", the last error can
always be retrieved via the C<last_error()> method.

=head1 OBJECT METHODS

=head2 installed

  if ($app->installed) {
      print "App is installed.\n"
  } else {
      print "App is not installed.\n"
  }

Returns a true value if the application is installed, and a false value if it
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

=head2 last_error

  my $err = $app->last_error;

Returns the last error encountered by the object. Useful for instances where
C<error_level> is set to "silent", though in truth it returns the last
non-fatal error.

=head1 PROTECTED OBJECT METHODS

=head2 error

  my $version = parse_version();
  $self->error("Unable to parse version number") unless $version;

The C<error()> method should be considered the sole method for alerting the
clients of App::Info subclasses that an error was encountered. Think of it as
a substitute for C<Carp::warn> (serious exceptions can use C<Carp::croak()>,
instead. Using the C<error()> method allows App::Info subclass clients to
handle the errors in any of several ways. See the description the L<new|"new">
method above to see how clients can manage error levels. Do not assume that
errors will be fatal. See L<Notes on Sublcassing|"NOTES ON SUBCLASSING"> below
for more on subclassing App::Info. The C<error()> method is a protected
method and therefore cannot be used by client libraries.

=head1 NOTES ON SUBCLASSING

The organizational idea behind App::Info is to name subclasses by broad
software categories. This approach allows the categories to function as
abstract base classes that extend App::Info, so that they can specify more
methods for all of their base classes to implement. For example,
L<App::Info::HTTPD> has specified the C<httpd_root()> abstract method that its
subclasses must implement. So as you get ready to implement your own subclass,
think about what category of software you're gathering information about.

Here are some guidelines for subclassing App::Info.

=over 4

=item *

Always subclass an App::Info category subclass. This will help to keep the
App::Info namespace well-organized. New categories can be added as needed.

=item *

When you create the new() constructor, always call SUPER::new(). This ensures
that the methods handle by the App::Info base classes (e.g., C<error()>) work
properly.

=item *

Use a package-scoped lexical App::Info::Util object to carry out common tasks.
If you find you're doing something over and over that's not already addressed
by an App::Info::Util method, consider submitting a patch to App::Info::Util
to add the functionality you need. See L<App::Info::Util|App::Info::Util> for
complete documentation of its interface.

=item *

Use the C<error()> method to report problems to clients of your App::Info
subclass. Doing so ensures that all problems encountered in interrogating
software package can be reported to and handled by client users in a uniform
manner. Furthermore, don't assume that calling C<error()> causes the program
to exit or to return from method execution. Clients can choose to ignore
errors by using the "silent" C<error_level>. Of course, fatal problem should
still be fatal, but non-fatal issues -- such as when an important file cannot
be found, resulting in less metadata being provided by the App::Info object --
should be noted by use of the C<error()> method exclusively.

=item *

Be sure to implement B<all> of the abstract methods defined by your category
abstract base class -- even if they don't do anything. Doing so ensures that
all App::Info subclasses share a common interface, and can, if necessary, be
used without regard to subclass. Any method not implemented but called on an
object will generate a fatal exception.

=back

Feel free to use the subclasses included in this distribution as examples to
follow when creating your own subclasses. I've tried to encapsulate common
functionality in L<App::Info::Util|App::Info::Util> to make the job easier. I
found that most of what I was doing repetitively was looking for files and
directories, and searching through files. Thus, App::Info::Util subclasses
L<File::Spec|File::Spec> in order to offer easy access to commonly-used
methods from that class (e.g., C<path()>. Plus, it has several of its own
methods to assist you in finding files and directories in lists of files and
directories, as well as methods for searching through files and returning the
values found in those files. See L<App::Info::Util|App::Info::Util> for more
information, and the App::Info subclasses in this distribution for actual
usage examples.

Otherwise, have fun! There are a lot of software packages for which relevant
information might be collected and aggregated into an App::Info subclass
(witness all of the Automake macros in the world!), and folks who are
knowledgeable about particular software packages or categories of software are
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
L<App::Info::HTTPD::Apache|App::Info::HTTPD::Apache>,
L<App::Info::RDBMS::PostgreSQL|App::Info::RDBMS::PostgreSQL>,
L<App::Info::Lib|App::Info::Lib::Expat>,
L<App::Info::Lib|App::Info::Lib::Iconv>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2002, David Wheeler. All Rights Reserved.

This module is free software; you can redistribute it and/or modify it under the
same terms as Perl itself.

=cut
