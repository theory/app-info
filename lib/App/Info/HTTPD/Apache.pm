package App::Info::HTTPD::Apache;

# $Id: Apache.pm,v 1.27 2002/06/12 18:18:58 david Exp $

=head1 NAME

App::Info::HTTPD::Apache - Information about Apache web server

=head1 SYNOPSIS

  use App::Info::HTTPD::Apache;

  my $apache = App::Info::HTTPD::Apache->new;

  if ($apache->installed) {
      print "App name: ", $apache->name, "\n";
      print "Version:  ", $apache->version, "\n";
      print "Bin dir:  ", $apache->bin_dir, "\n";
  } else {
      print "Apache is not installed. :-(\n";
  }

=head1 DESCRIPTION

App::Info::HTTPD::Apache supplies information about the Apache web server
installed on the local system. It implements all of the methods defined by
App::Info::HTTPD. Methods that throw errors will throw them only the first
time they're called. To start over (after, say, someone has installed Apache)
construct a new App::Info::HTTPD::Apache object to aggregate new metadata.

=cut

use strict;
use App::Info::HTTPD;
use App::Info::Util;
use vars qw(@ISA $VERSION);
@ISA = qw(App::Info::HTTPD);
$VERSION = '0.06';

my $u = App::Info::Util->new;

=head1 CONSTRUCTOR

=head2 new

  my $apache = App::Info::HTTPD::Apache->new(@params);

Returns an App::Info::HTTPD::Apache object. See L<App::Info|App::Info> for a
complete description of argument parameters.

When called, C<new()> searches the file system for the F<httpd>,
F<apache-perl>, or F<apache> application. If found, the application (hereafer
referred to as F<httpd>, regardless of how it was actually found to be named)
will be called by the object methods below to gather the data necessary for
each. If F<httpd> cannot be found, then Apache is assumed not to be installed,
and each of the object methods will return C<undef>.

App::Info::HTTPD::Apache searches for F<httpd> along your path, as defined by
C<File::Spec->path>. Failing that, it searches the following directories:

=over 4

=item /usr/local/apache/bin

=item /usr/local/bin

=item /usr/local/sbin

=item /usr/bin

=item /usr/sbin

=item /bin

=item /opt/apache/bin

=item /etc/httpd/bin

=item /etc/apache/bin

=item /home/httpd/bin

=item /home/apache/bin

=item /sw/bin

=item /sw/sbin

=back

=cut

sub new {
    # Construct the object.
    my $self = shift->SUPER::new(@_);

    # Find Apache executable.
    $self->info("Looking for Apache binary");

    my @paths = ($u->path,
      qw(/usr/local/apache/bin
         /usr/local/bin
         /usr/local/sbin
         /usr/bin
         /usr/sbin
         /bin
         /opt/apache/bin
         /etc/httpd/bin
         /etc/apache/bin
         /home/httpd/bin
         /home/apache/bin
         /sw/bin
         /sw/sbin));

    my @exes = qw(httpd apache-perl apache);

    if (my $exe = $u->first_cat_exe(\@exes, @paths)) {
        # We found httpd. Confirm.
        $self->{binary} = $self->confirm('binary', $exe, sub { -x $_[0] });
    } else {
        # Handle an unknown value.
        $self->{binary} = $self->unknown('binary', sub { -x $_[0] })
          unless $self->{binary};
    }
    return $self;
};

sub key_name { 'Apache' }

=head1 OBJECT METHODS

=head2 installed

  print "apache is ", ($apache->installed ? '' : 'not '),
    "installed.\n";

Returns true if Apache is installed, and false if it is not.
App::Info::HTTPD::Apache determines whether Apache is installed based on the
presence or absence of the F<httpd> application on the file system, as found
when C<new()> constructed the object. If Apache does not appear to be
installed, then all of the other object methods will return empty values.

=cut

sub installed { return $_[0]->{binary} ? 1 : undef }

=head2 name

  my $name = $apache->name;

Returns the name of the application. App::Info::HTTPD::Apache parses the name
from the system call C<`httpd -v`>. See the L<version|"version"> method for a
list of possible errors.

=cut

sub name {
    my $self = shift;
    return unless $self->{binary};

    # Load data.
    $self->version unless exists $self->{version};

    # Handle an unknown name.
    $self->{name} = $self->unknown('name') unless $self->{name};

    # Return the name.
    return $self->{name};
}

=head2 version

  my $version = $apache->version;

Returns the apache version number. App::Info::HTTPD::Apache parses the version
number from the system call C<`httpd --v`>. Throws an error if Apache is
installed but the version number or name could not be parsed.

=cut

sub version {
    my $self = shift;
    return unless $self->{binary};
    unless (exists $self->{version}) {{
        $self->info("Executing `$self->{binary} -v`");
        my $version = `$self->{binary} -v`;
        unless ($version) {
            $self->error("Failed to find Apache version with ",
                         "`$self->{binary} -v`");
            last; # Double braces allow this.
        }

        chomp $version;
        my ($n, $x, $y, $z) = $version =~
          /Server\s+version:\s+([^\/]*)\/(\d+)\.(\d+).(\d+)/;
        unless ($n and $x and defined $y and defined $z) {
            $self->error("Failed to parse Apache name and ",
                         "version from string '$version'");
            last; # Double braces allow this.
        }

        @{$self}{qw(name version major minor patch)} =
          ($n, "$x.$y.$z", $x, $y, $z);
    }} # unless

    # Handle an unknown value.
    unless ($self->{version}) {
        # Create a validation code reference.
        my $chk_version = sub {
            my $ver = shift;
            # Try to get the version number parts.
            my ($x, $y, $z) =
              $ver =~ /Server\s+version:\s+([^\/]*)\/(\d+)\.(\d+).(\d+)/;
            # Return false if we didn't get all three.
            return unless $x and defined $y and defined $z;
            # Save all three parts.
            @{$self}{qw(major minor patch)} = ($x, $y, $z);
            # Return true.
            return 1;
        };
        $self->{version} = $self->unknown('version', $chk_version);
    }

    # Return the version number.
    return $self->{version};
}

=head2 major_version

  my $major_version = $apache->major_version;

Returns the Apache major version number. App::Info::HTTPD::Apache parses the
version number from the system call C<`httpd --v`>. For example, if
C<version()> returns "1.3.24", then this method returns "1". See the
L<version|"version"> method for a list of possible errors.

=cut

sub major_version {
    my $self = shift;
    $self->version unless exists $self->{version};
    # Handle an unknown value.
    $self->{major} = $self->unknown('major version number')
      unless $self->{major};
    return $self->{major};
}

=head2 minor_version

  my $minor_version = $apache->minor_version;

Returns the Apache minor version number. App::Info::HTTPD::Apache parses the
version number from the system call C<`httpd --v`>. For example, if
C<version()> returns "1.3.24", then this method returns "3". See the
L<version|"version"> method for a list of possible errors.

=cut

sub minor_version {
    my $self = shift;
    $self->version unless exists $self->{version};
    # Handle an unknown value.
    $self->{minor} = $self->unknown('minor version number')
      unless defined $self->{minor};
    return $self->{minor};
}

=head2 patch_version

  my $patch_version = $apache->patch_version;

Returns the Apache patch version number. App::Info::HTTPD::Apache parses the
version number from the system call C<`httpd --v`>. For example, if
C<version()> returns "1.3.24", then this method returns "24". See the
L<version|"version"> method for a list of possible errors.

=cut

sub patch_version {
    my $self = shift;
    $self->version unless exists $self->{version};
    # Handle an unknown value.
    $self->{patch} = $self->unknown('patch version number')
      unless defined $self->{patch};
    return $self->{patch};
}

=head2 httpd_root

  my $httpd_root = $apache->httpd_root;

Returns the HTTPD root directory path. This path is defined at compile time,
and App::Info::HTTPD::Apache parses it from the system call C<`httpd -V`>.
Throws an error if Apache is installed but the HTTPD root could not be parsed.

=cut

# This code ref takes care of processing the compile settings. It is used by
# httpd_root(), magic_number(), or compile_option(), whichever is called
# first.
my $get_compile_settings = sub {
    my $self = shift;
    $self->{-V} = 1;
    $self->info("Executing `$self->{binary} -V`");
    # Get the compile settings.
    my $data = `$self->{binary} -V`;
    unless ($data) {
        $self->error("Unable to extract compile settings from ",
                     "`$self->{binary} -V`");
        return;
    }

    # Split out the parts.
    foreach (split /\s*\n\s*/, $data) {
        if (/magic\s+number:\s+(.*)$/i) {
            $self->{magic_number} = $1;
        } elsif (/=/) {
            $_ =~ s/^-D\s+//;
            $_ =~ s/"$//;
            my ($k, $v) = split /\s*=\s*"/, $_;
            $self->{lc $k} = $v;
        } elsif (/-D/) {
            $_ =~ s/^-D\s+//;
            $self->{lc $_} = 1;
        }
    }
    # Issue a warning if no httpd root was found.
    $self->error("Could not parse HTTPD root from ",
                 "`$self->{binary} -V`") unless $self->{httpd_root};
};

sub httpd_root {
    my $self = shift;
    return unless $self->{binary};
    # Get the compile settings.
    $get_compile_settings->($self) unless $self->{-V};
    # Handle an unknown value.
    $self->{httpd_root} = $self->unknown('httpd root')
      unless defined $self->{httpd_root};
    return $self->{httpd_root};
}

=head2 magic_number

  my $magic_number = $apache->magic_number;

Returns the "Magic Number" for the Apache installation. This number is defined
at compile time, and App::Info::HTTPD::Apache parses it from the system call
C<`httpd -V`> See the L<httpd_root|"httpd_root"> method for a list of possible
errors.

=cut

sub magic_number {
    my $self = shift;
    # Get the compile settings.
    $get_compile_settings->($self) unless $self->{-V};
    # Handle an unknown value.
    $self->{magic_number} = $self->unknown('magic number')
      unless defined $self->{magic_number};
    return $self->{magic_number};
}

=head2 compile_option

  my $compile_option = $apache->compile_option($option);

Returns the value of the Apache compile option C<$option>. The compile option
is looked up case-insensitively. All of the Apache compile options are
collected from the system call C<`httpd -V`>. For compile options that contain
a corresponding value (such as "SUEXEC_BIN" or "DEFAULT_PIDLOG"),
C<compile_option()> returns the value of the option if the option exists. For
other options, it returns true (1) if the option was included, and
false(C<undef>) if it was not. Returns C<undef> if Apache is not installed or
if the option could not be parsed. See the L<httpd_root|"httpd_root"> method
for a list of possible errors.

See the Apache documentation at L<http://httpd.apache.org/docs-project/> to
learn about all the possible compile options.

=cut

sub compile_option {
    my $self = shift;
    # Get the compile settings.
    $get_compile_settings->($self) unless $self->{-V};
    # Handle an unknown value.
    my $option = lc $_[0];
    $self->{$option} = $self->unknown("option $option")
      unless defined $self->{$option};
    return $self->{$option};
}

=head2 conf_file

Returns the full path to the Apache configuration file. C<conf_file()> looks
for the configuration file in a number of locations and under a number of
names. First it tries to use the file specifed by the C<SERVER_CONFIG_FILE>
compile option (as returned by a call to C<compile_option()>) -- and if it's a
relative file name, it gets appended to the directory returned by
C<httpd_root()>. If that file isn't found, C<conf_file()> then looks for the
files F<httpd.conf> and F<httpd.conf.default> in the F<conf> subdirectory of
the HTTPD root directory. Failing that, it looks for the following:

=over 4

=item /usr/share/doc/apache-perl/examples/httpd.conf

=item /usr/share/doc/apache-perl/examples/httpd.conf.default

=item /etc/httpd/httpd.conf

=item /etc/httpd/httpd.conf.default

=back

Throws an error and returns C<undef> if the file cannot be found.

=cut

sub conf_file {
    my $self = shift;
    return unless $self->{binary};
    unless (exists $self->{conf_file}) {
        $self->info("Searching for Apache configuration file");
        my $root = $self->httpd_root;
        my $conf = $self->compile_option('SERVER_CONFIG_FILE');
        $conf = $u->file_name_is_absolute($conf) ?
          $conf : $u->catfile($root, $conf) if $conf;
        # Paths to search.
        my @paths = ($conf ? ($conf) : (),
                     $u->catfile($root, 'conf', 'httpd.conf'),
                     $u->catfile($root, 'conf', 'httpd.conf.default'),
                     "/usr/share/doc/apache-perl/examples/httpd.conf",
                     "/usr/share/doc/apache-perl/examples/httpd.conf.default",
                     "/etc/httpd/httpd.conf",
                     "/etc/httpd/httpd.conf.default");

        $self->{conf_file} = $u->first_file(@paths)
          or $self->error("No server config file found");
    }
    # Handle an unknown value.
    $self->{conf_file} = $self->unknown('configuration file', sub { -e $_[0] })
      unless defined $self->{conf_file};
    return $self->{conf_file};
}

=head2 user

  my $user = $apache->user;

Returns the name of the Apache user. This value is collected from the Apache
configuration file as returned by C<conf_file()>. Throws an error and returns
C<undef>if the configuration file cannot be found or if the user name, group,
or port number could not be parsed from the configuration file.

=cut

# This code reference parses the Apache configuration file. It is called by
# user(), group(), or port(), whichever gets called first.
my $parse_conf_file = sub {
    my $self = shift;
    return if exists $self->{user};
    $self->{user} = undef;
    # Find the configuration file.
    my $conf = $self->conf_file or return;

    $self->info("Parsing Apache configuration file");

    # This is the place to add more regexes to collect stuff from the
    # config file in the future.
    my @regexen = (qr/^\s*User\s+(.*)$/,
                   qr/^\s*Group\s+(.*)$/,
                   qr/^\s*Port\s+(.*)$/ );
    my ($usr, $grp, $prt) = $u->multi_search_file($conf, @regexen);
    # Issue a warning if we couldn't find the user and group.
    $self->error("Could not parse user and group from file '$conf'")
      unless $usr && $grp;
    $self->error("Could not parse port from file '$conf'") unless $prt;
    # Assign them anyway.
    @{$self}{qw(user group port)} = ($usr, $grp, $prt);
};

sub user {
    my $self = shift;
    return unless $self->{binary};
    $parse_conf_file->($self) unless exists $self->{user};
    # Handle an unknown value.
    $self->{user} = $self->unknown('user', sub { getpwnam $_[0] })
      unless $self->{user};
    return $self->{user};
}

=head2 group

Returns the name of the Apache user group. This value is collected from the
Apache configuration file as returned by C<conf_file()>. See the
L<"user"|user> method for a list of possible errors.

=cut

sub group {
    my $self = shift;
    return unless $self->{binary};
    $parse_conf_file->($self) unless exists $self->{group};
    # Handle an unknown value.
    $self->{group} = $self->unknown('group', sub { getgrnam $_[0] })
      unless $self->{group};
    return $self->{group};
}

=head2 port

Returns the port number on which Apache listens. This value is collected from
Apache configuration file as returned by C<conf_file()>. See the
L<"user"|user> method for a list of possible errors.

=cut

sub port {
    my $self = shift;
    return unless $self->{binary};
    $parse_conf_file->($self) unless exists $self->{port};
    # Handle an unknown value.
    $self->{port} = $self->unknown('port', sub { $_[0] =~ /^\d+$/ })
      unless $self->{port};
    return $self->{port};
}

=head2 bin_dir

  my $bin_dir = $apache->bin_dir;

Returns the Apache binary directory path. App::Info::HTTPD::Apache simply
looks for the F<bin> directory under the HTTPD root directory, as returned by
C<httpd_root()>. Throws an error and eturns C<undef> if Apache is not
installed or if the bin directory could not be found.

=cut

sub bin_dir {
    my $self = shift;
    return unless $self->{binary};
    unless (exists $self->{bin_dir}) {{
        my $root = $self->httpd_root || last; # Double braces allow this.
        $self->info("Searching for binary directory");
        $self->{bin_dir} = $u->first_cat_path('bin', $root)
          or $self->error("Could not find bin directory");
    }}

    # Handle unknown value.
    $self->{bin_dir} = $self->unknown('binary directory', sub { -d $_[0] })
      unless $self->{bin_dir};
    return $self->{bin_dir};
}

=head2 inc_dir

  my $inc_dir = $apache->inc_dir;

Returns the Apache include directory path. App::Info::HTTPD::Apache simply
looks for the F<include> or F<inc> directory under the F<httpd_root>
directory, as returned by C<httpd_root()>. Throws an error and eturns C<undef>
if Apache is not installed or if the inc directory could not be found.

=cut

sub inc_dir {
    my $self = shift;
    unless (exists $self->{inc_dir}) {{
        my $root = $self->httpd_root || last; # Double braces allow this.
        $self->info("Searching for include directory");
        $self->{inc_dir} = $u->first_cat_path(['include', 'inc',], $root)
          or $self->error("Could not find inc directory");
    }}
    # Handle unknown value.
    $self->{inc_dir} = $self->unknown('include directory', sub { -d $_[0] })
      unless $self->{inc_dir};
    return $self->{inc_dir};
}

=head2 lib_dir

  my $lib_dir = $apache->lib_dir;

Returns the Apache library directory path. App::Info::HTTPD::Apache simply
looks for the F<lib>, F<modules>, or F<libexec> directory under the HTTPD
root> directory, as returned by C<httpd_root()>. Throws an error and returns
C<undef> if Apache is not installed or if the lib directory could not be
found.

=cut

sub lib_dir {
    my $self = shift;
    unless (exists $self->{lib_dir}) {{
        my $root = $self->httpd_root || last; # Double braces allow this.
        $self->info("Searching for library directory");
        if (my $d = $u->first_cat_path([qw(lib modules libexec)], $root)) {
            # The usual suspects.
            $self->{lib_dir} = $d;
        } elsif ($u->first_dir('/usr/lib/apache/1.3')) {
            # The Debian way.
            $self->{lib_dir} = '/usr/lib/apache/1.3';
        } else {
            $self->error("Could not find lib direcory");
        }
    }}
    # Handle unknown value.
    $self->{lib_dir} = $self->unknown('library directory', sub { -d $_[0] })
      unless $self->{lib_dir};
    return $self->{lib_dir};
}

=head2 so_lib_dir

  my $so_lib_dir = $apache->so_lib_dir;

Returns the Apache shared object library directory path. Currently, this
directory is assumed to be the same as the lib directory, so this method is
simply an alias for C<lib_dir>. Throws an error and returns C<undef> if Apache
is not installed or if the lib directory could not be found.

=cut

# For now, at least, these seem to be the same.
*so_lib_dir = \&lib_dir;

=head2 static_mods

Returns a list (in an array context) or an anonymous array (in a scalar
reference) of all of the modules statically compiled into Apache. These are
collected from the system call C<`httpd -l`>. If Apache is not installed,
C<static_mods()> throws an error and returns an empty list in an array context
or an empty anonymous array in a scalar context.

=cut

# This code reference collects the list of static modules from Apache. Used by
# static_mods(), mod_perl(), or mod_so(), whichever gets called first.
my $get_static_mods = sub {
    my $self = shift;
    $self->{static_mods} = undef;
    $self->info("Collecting list of static modules");
    my $data = `$self->{binary} -l`;
    unless ($data) {
        $self->error("Unable to extract needed data from ".
                     "`$self->{binary} =l`");
        return;
    }

    # Parse out the modules.
    my @mods;
    while ($data =~ /^\s*(\w+)\.c\s*$/mg) {
        push @mods, $1;
        $self->{mod_so} = 1 if $1 eq 'mod_so';
        $self->{mod_perl} = 1 if $1 eq 'mod_perl';
    }
    $self->{static_mods} = \@mods;
};

sub static_mods {
    my $self = shift;
    return unless $self->{binary};
    $get_static_mods->($self) unless exists $self->{static_mods};
    return unless $self->{static_mods};
    return wantarray ? @{$self->{static_mods}} : $self->{static_mods};
}

=head2 mod_so

Boolean method that returns true when mod_so has been compiled into Apache,
and false if it has not. The presence or absence of mod_so is determined by
the system call C<`httpd -l`>. See the L<"static_mods"|static_mods> method for
a list of possible errors.

=cut

sub mod_so {
    my $self = shift;
    $get_static_mods->($self) unless exists $self->{static_mods};
    return $self->{mod_so};
}

=head2 mod_perl

Boolean method that returns true when mod_perl has been statically compiled
into Apache, and false if it has not. The presence or absence of mod_perl is
determined by the system call C<`httpd -l`>. See the
L<"static_mods"|static_mods> method for a list of possible errors.

=cut

sub mod_perl {
    my $self = shift;
    $get_static_mods->($self) unless exists $self->{static_mods};
    return $self->{mod_perl};
}

=head2 home_url

  my $home_url = $apache->home_url;

Returns the Apache home page URL.

=cut

sub home_url { "http://httpd.apache.org/" }

=head2 download_url

  my $download_url = $apache->download_url;

Returns the Apache download URL.

=cut

sub download_url { "http://www.apache.org/dist/httpd/" }

1;
__END__

=head1 KNOWN ISSUES

It's likely that a lot more can be done to collect data about Apache. The
methodology for determining the lib, inc, bin, and so_lib directories in
particular may be considered rather weak. And the Port number can be specified
multiple ways (and times!) in an Apache configuration file. Patches from those
who know a great deal more about interrogating Apache will be most welcome.

=head1 TO DO

Add method to return the names of available DSOs. These should either be
parsed from the F<httpd.conf> file or C<glob>bed from the file system.

=head1 BUGS

Feel free to drop me a line if you discover any bugs. Patches welcome.

=head1 AUTHOR

David Wheeler <david@wheeler.net> based on code by Sam Tregar
<sam@tregar.com>.

=head1 SEE ALSO

L<App::Info|App::Info>,
L<App::Info::HTTPD|App::Info::HTTPD>,
L<Apache|Apache>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2002, David Wheeler. All Rights Reserved.

This module is free software; you can redistribute it and/or modify it under the
same terms as Perl itself.

=cut
