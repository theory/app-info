package App::Info::HTTPD::Apache;

# $Id$

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
App::Info::HTTPD. Methods that trigger events will trigger them only the first
time they're called (See L<App::Info|App::Info> for documentation on handling
events). To start over (after, say, someone has installed Apache) construct a
new App::Info::HTTPD::Apache object to aggregate new metadata.

Some of the methods trigger the same events. This is due to cross-calling of
methods or of functions common to methods. However, any one event should be
triggered no more than once. For example, although the info event "Executing
`httpd -v`" is documented for the methods C<name()>, C<version()>,
C<major_version()>, C<minor_version()>, and C<patch_version()>, rest assured
that it will only be triggered once, by whichever of those four methods is
called first.

=cut

use strict;
use App::Info::HTTPD;
use App::Info::Util;
use vars qw(@ISA $VERSION);
@ISA = qw(App::Info::HTTPD);
$VERSION = '0.26';
use constant WIN32 => $^O eq 'MSWin32';

my $u = App::Info::Util->new;

=head1 INTERFACE

=head2 Constructor

=head3 new

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
C<File::Spec-E<gt>path>. Failing that, it searches the following directories:

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

B<Events:>

=over 4

=item info

Looking for Apache executable

=item confirm

Path to your httpd executable?

=item unknown

Path to your httpd executable?

=back

=cut

sub new {
    # Construct the object.
    my $self = shift->SUPER::new(@_);

    # Find Apache executable.
    $self->info("Looking for Apache executable");

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
    if (WIN32) { $_ .= ".exe" for @exes }

    if (my $exe = $u->first_cat_exe(\@exes, @paths)) {
        # We found httpd. Confirm.
        $self->{exe} =
          $self->confirm( key      => 'executable',
                          prompt   => 'Path to your httpd executable?',
                          value    => $exe,
                          callback => sub { -x },
                          error    => 'Not an executable');
    } else {
        # Handle an unknown value.
        $self->{exe} =
          $self->unknown( key      => 'executable',
                          prompt   => 'Path to your httpd executable?',
                          callback => sub { -x },
                          error    => 'Not an executable');
    }
    return $self;
};

##############################################################################

=head2 Class Method

=head3 key_name

  my $key_name = App::Info::HTTPD::Apache->key_name;

Returns the unique key name that describes this class. The value returned is
the string "Apache".

=cut

sub key_name { 'Apache' }

##############################################################################

=head2 Object Methods

=head3 installed

  print "apache is ", ($apache->installed ? '' : 'not '),
    "installed.\n";

Returns true if Apache is installed, and false if it is not.
App::Info::HTTPD::Apache determines whether Apache is installed based on the
presence or absence of the F<httpd> application on the file system, as found
when C<new()> constructed the object. If Apache does not appear to be
installed, then all of the other object methods will return empty values.

=cut

sub installed { return $_[0]->{exe} ? 1 : undef }

##############################################################################

=head3 name

  my $name = $apache->name;

Returns the name of the application. App::Info::HTTPD::Apache parses the name
from the system call C<`httpd -v`>.

B<Events:>

=over 4

=item info

Executing `httpd -v`

=item error

Failed to find Apache version data with `httpd -v`

Failed to parse Apache name and version from string

=item unknown

Enter a valid Apache name

=back

=cut

my $get_version = sub {
    my $self = shift;
    $self->{-v} = 1;
    $self->info("Executing `$self->{exe} -v`");
    my $version = `$self->{exe} -v`;
    unless ($version) {
        $self->error("Failed to find Apache version data with ",
                     "`$self->{exe} -v`");
        return;
    }

    chomp $version;
    my ($n, $x, $y, $z) = $version =~
      /Server\s+version:\s+([^\/]*)\/(\d+)\.(\d+).(\d+)/;
    unless ($n and $x and defined $y and defined $z) {
        $self->error("Failed to parse Apache name and ",
                         "version from string '$version'");
        return;
    }

    @{$self}{qw(name version major minor patch)} =
      ($n, "$x.$y.$z", $x, $y, $z);
};

sub name {
    my $self = shift;
    return unless $self->{exe};

    # Load data.
    $get_version->($self) unless exists $self->{-v};

    # Handle an unknown name.
    $self->{name} ||= $self->unknown( key => 'name' );

    # Return the name.
    return $self->{name};
}

##############################################################################

=head3 version

  my $version = $apache->version;

Returns the apache version number. App::Info::HTTPD::Apache parses the version
number from the system call C<`httpd -v`>.

B<Events:>

=over 4

=item info

Executing `httpd -v`

=item error

Failed to find Apache version data with `httpd -v`

Failed to parse Apache name and version from string

=item unknown

Enter a valid Apache version number

=back

=cut

sub version {
    my $self = shift;
    return unless $self->{exe};

    # Load data.
    $get_version->($self) unless exists $self->{-v};

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

    # Return the version number.
    return $self->{version};
}

##############################################################################

=head3 major_version

  my $major_version = $apache->major_version;

Returns the Apache major version number. App::Info::HTTPD::Apache parses the
version number from the system call C<`httpd --v`>. For example, if
C<version()> returns "1.3.24", then this method returns "1".

B<Events:>

=over 4

=item info

Executing `httpd -v`

=item error

Failed to find Apache version data with `httpd -v`

Failed to parse Apache name and version from string

=item unknown

Enter a valid Apache major version number

=back

=cut

# This code reference is used by major_version(), minor_version(), and
# patch_version() to validate a version number entered by a user.
my $is_int = sub { /^\d+$/ };

sub major_version {
    my $self = shift;
    return unless $self->{exe};
    # Load data.
    $get_version->($self) unless exists $self->{-v};
    # Handle an unknown value.
    $self->{major} = $self->unknown( key      => 'major version number',
                                     callback => $is_int)
      unless $self->{major};
    return $self->{major};
}

##############################################################################

=head3 minor_version

  my $minor_version = $apache->minor_version;

Returns the Apache minor version number. App::Info::HTTPD::Apache parses the
version number from the system call C<`httpd --v`>. For example, if
C<version()> returns "1.3.24", then this method returns "3". See the
L<version|"version"> method for a list of possible errors.

B<Events:>

=over 4

=item info

Executing `httpd -v`

=item error

Failed to find Apache version data with `httpd -v`

Failed to parse Apache name and version from string

=item unknown

Enter a valid Apache minor version number

=back

=cut

sub minor_version {
    my $self = shift;
    return unless $self->{exe};
    # Load data.
    $get_version->($self) unless exists $self->{-v};
    # Handle an unknown value.
    $self->{minor} = $self->unknown( key      => 'minor version number',
                                     callback => $is_int)
      unless defined $self->{minor};
    return $self->{minor};
}

##############################################################################

=head3 patch_version

  my $patch_version = $apache->patch_version;

Returns the Apache patch version number. App::Info::HTTPD::Apache parses the
version number from the system call C<`httpd --v`>. For example, if
C<version()> returns "1.3.24", then this method returns "24".

B<Events:>

=over 4

=item info

Executing `httpd -v`

=item error

Failed to find Apache version data with `httpd -v`

Failed to parse Apache name and version from string

=item unknown

Enter a valid Apache patch version number

=back

=cut

sub patch_version {
    my $self = shift;
    return unless $self->{exe};
    # Load data.
    $get_version->($self) unless exists $self->{-v};
    # Handle an unknown value.
    $self->{patch} = $self->unknown( key      => 'patch version number',
                                     callback => $is_int)
      unless defined $self->{patch};
    return $self->{patch};
}

##############################################################################

=head3 httpd_root

  my $httpd_root = $apache->httpd_root;

Returns the HTTPD root directory path. This path is defined at compile time,
and App::Info::HTTPD::Apache parses it from the system call C<`httpd -V`>.

B<Events:>

=over 4

=item info

Executing `httpd -V`

=item error

Unable to extract compile settings from `httpd -V`

Cannot parse HTTPD root from `httpd -V`

=item unknown

Enter a valid HTTPD root

=back

=cut

# This code ref takes care of processing the compile settings. It is used by
# httpd_root(), magic_number(), or compile_option(), whichever is called
# first.
my $get_compile_settings = sub {
    my $self = shift;
    $self->{-V} = 1;
    $self->info("Executing `$self->{exe} -V`");
    # Get the compile settings.
    my $data = `$self->{exe} -V`;
    unless ($data) {
        $self->error("Unable to extract compile settings from ",
                     "`$self->{exe} -V`");
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
            if (WIN32) {
                if ($k eq 'SUEXEC_BIN') {
                    $self->{lc $k} = 0;
                } elsif ($k eq 'HTTPD_ROOT') {
                    $self->{lc $k} =
                      join('\\', (split /\\/, $self->{exe} )[0 .. 1]);
                 }
            }
        } elsif (/-D/) {
            $_ =~ s/^-D\s+//;
            $self->{lc $_} = 1;
        }
    }
    # Issue a warning if no httpd root was found.
    $self->error("Cannot parse HTTPD root from ",
                 "`$self->{exe} -V`") unless $self->{httpd_root};
};

# This code reference is used by httpd_root(), lib_dir(), bin_dir(), and
# so_lib_dir() to validate a directory entered by the user.
my $is_dir = sub { -d };

sub httpd_root {
    my $self = shift;
    return unless $self->{exe};
    # Get the compile settings.
    $get_compile_settings->($self) unless $self->{-V};
    # Handle an unknown value.
    $self->{httpd_root} = $self->unknown( key      => 'HTTPD root',
                                          callback => $is_dir)
      unless defined $self->{httpd_root};
    return $self->{httpd_root};
}

##############################################################################

=head3 magic_number

  my $magic_number = $apache->magic_number;

Returns the "Magic Number" for the Apache installation. This number is defined
at compile time, and App::Info::HTTPD::Apache parses it from the system call
C<`httpd -V`>.

B<Events:>

=over 4

=item info

Executing `httpd -V`

=item error

Unable to extract compile settings from `httpd -V`

Cannot parse HTTPD root from `httpd -V`

=item unknown

Enter a valid magic number

=back

=cut

sub magic_number {
    my $self = shift;
    return unless $self->{exe};
    # Get the compile settings.
    $get_compile_settings->($self) unless $self->{-V};
    # Handle an unknown value.
    $self->{magic_number} = $self->unknown( key => 'magic number' )
      unless defined $self->{magic_number};
    return $self->{magic_number};
}

##############################################################################

=head3 compile_option

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

B<Events:>

=over 4

=item info

Executing `httpd -V`

=item error

Unable to extract compile settings from `httpd -V`

Cannot parse HTTPD root from `httpd -V`

=item unknown

Enter a valid option

=back

=cut

sub compile_option {
    my $self = shift;
    return unless $self->{exe};
    # Get the compile settings.
    $get_compile_settings->($self) unless $self->{-V};
    # Handle an unknown value.
    my $option = lc $_[0];
    $self->{$option} = $self->unknown( key => "option $option" )
      unless defined $self->{$option};
    return $self->{$option};
}

##############################################################################

=head3 conf_file

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

B<Events:>

=over 4

=item info

Searching for Apache configuration file

=item error

No Apache config file found

=item unknown

Location of httpd.conf file?

=back

=cut

sub conf_file {
    my $self = shift;
    return unless $self->{exe};
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
          or $self->error("No Apache config file found");
    }
    # Handle an unknown value.
    $self->{conf_file} =
      $self->unknown( key      => 'conf_file',
                      prompt   => "Location of httpd.conf file?",
                      callback => sub { -f },
                      error    => "Not a file")
      unless defined $self->{conf_file};
    return $self->{conf_file};
}

##############################################################################

=head3 user

  my $user = $apache->user;

Returns the name of the Apache user. This value is collected from the Apache
configuration file as returned by C<conf_file()>.

B<Events:>

=over 4

=item info

Searching for Apache configuration file

Executing `httpd -V`

Parsing Apache configuration file

=item error

No Apache config file found

Cannot parse user from file

Cannot parse group from file

Cannot parse port from file

=item unknown

Location of httpd.conf file?

Enter Apache user name

=back

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
    $self->error("Cannot parse user from file '$conf'") unless $usr;
    $self->error("Cannot parse group from file '$conf'") unless $grp;
    $self->error("Cannot parse port from file '$conf'") unless $prt;
    # Assign them anyway.
    @{$self}{qw(user group port)} = ($usr, $grp, $prt);
};

sub user {
    my $self = shift;
    return unless $self->{exe};
    $parse_conf_file->($self) unless exists $self->{user};
    # Handle an unknown value.
    $self->{user} = $self->unknown( key      => 'user',
                                    prompt   => 'Enter Apache user name',
                                    callback => sub { getpwnam $_ },
                                    error    => "Not a user")
      unless $self->{user};
    return $self->{user};
}

##############################################################################

=head3 group

Returns the name of the Apache user group. This value is collected from the
Apache configuration file as returned by C<conf_file()>.

B<Events:>

=over 4

=item info

Searching for Apache configuration file

Executing `httpd -V`

Parsing Apache configuration file

=item error

No Apache config file found

Cannot parse user from file

Cannot parse group from file

Cannot parse port from file

=item unknown

Location of httpd.conf file?

Enter Apache user group name

=back

=cut

sub group {
    my $self = shift;
    return unless $self->{exe};
    $parse_conf_file->($self) unless exists $self->{group};
    # Handle an unknown value.
    $self->{group} =
      $self->unknown( key       => 'group',
                      prompt    => 'Enter Apache user group name',
                      callback  => sub { getgrnam $_ },
                      error     => "Not a user group")
      unless $self->{group};
    return $self->{group};
}

##############################################################################

=head3 port

Returns the port number on which Apache listens. This value is collected from
Apache configuration file as returned by C<conf_file()>.

B<Events:>

=over 4

=item info

Searching for Apache configuration file

Executing `httpd -V`

Parsing Apache configuration file

=item error

No Apache config file found

Cannot parse user from file

Cannot parse group from file

Cannot parse port from file

=item unknown

Location of httpd.conf file?

Enter Apache TCP/IP port number

=back

=cut

sub port {
    my $self = shift;
    return unless $self->{exe};
    $parse_conf_file->($self) unless exists $self->{port};
    # Handle an unknown value.
    $self->{port} =
      $self->unknown( key      => 'port',
                      prompt   => 'Enter Apache TCP/IP port number',
                      callback => $is_int,
                      error    => "Not a valid port number")
      unless $self->{port};
    return $self->{port};
}

##############################################################################

=head3 bin_dir

  my $bin_dir = $apache->bin_dir;

Returns the Apache binary directory path. App::Info::HTTPD::Apache simply
looks for the F<bin> directory under the HTTPD root directory, as returned by
C<httpd_root()>.

B<Events:>

=over 4

=item info

Executing `httpd -V`

Searching for bin directory

=item error

Unable to extract compile settings from `httpd -V`

Cannot parse HTTPD root from `httpd -V`

Cannot find bin directory

=item unknown

Enter a valid HTTPD root

Enter a valid Apache bin directory

=back

=cut

sub bin_dir {
    my $self = shift;
    return unless $self->{exe};
    unless (exists $self->{bin_dir}) {{
        my $root = $self->httpd_root || last; # Double braces allow this.
        $self->info("Searching for bin directory");
        $self->{bin_dir} = $u->first_cat_path('bin', $root)
          or $self->error("Cannot find bin directory");
    }}

    # Handle unknown value.
    $self->{bin_dir} = $self->unknown( key      => 'bin directory',
                                       callback => $is_dir)
      unless $self->{bin_dir};
    return $self->{bin_dir};
}

##############################################################################

=head3 inc_dir

  my $inc_dir = $apache->inc_dir;

Returns the Apache include directory path. App::Info::HTTPD::Apache simply
looks for the F<include> or F<inc> directory under the F<httpd_root>
directory, as returned by C<httpd_root()>.

B<Events:>

=over 4

=item info

Executing `httpd -V`

Searching for include directory

=item error

Unable to extract compile settings from `httpd -V`

Cannot parse HTTPD root from `httpd -V`

Cannot find include directory

=item unknown

Enter a valid HTTPD root

Enter a valid Apache include directory

=back

=cut

sub inc_dir {
    my $self = shift;
    return unless $self->{exe};
    unless (exists $self->{inc_dir}) {{
        my $root = $self->httpd_root || last; # Double braces allow this.
        $self->info("Searching for include directory");
        $self->{inc_dir} = $u->first_cat_path(['include', 'inc',], $root)
          or $self->error("Cannot find include directory");
    }}
    # Handle unknown value.
    $self->{inc_dir} = $self->unknown( key      => 'include directory',
                                       callback => $is_dir)
      unless $self->{inc_dir};
    return $self->{inc_dir};
}

##############################################################################

=head3 lib_dir

  my $lib_dir = $apache->lib_dir;

Returns the Apache library directory path. App::Info::HTTPD::Apache simply
looks for the F<lib>, F<modules>, or F<libexec> directory under the HTTPD
root> directory, as returned by C<httpd_root()>.

B<Events:>

=over 4

=item info

Executing `httpd -V`

Searching for library directory

=item error

Unable to extract compile settings from `httpd -V`

Cannot parse HTTPD root from `httpd -V`

Cannot find library directory

=item unknown

Enter a valid HTTPD root

Enter a valid Apache library directory

=back

=cut

sub lib_dir {
    my $self = shift;
    return unless $self->{exe};
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
            $self->error("Cannot find library direcory");
        }
    }}
    # Handle unknown value.
    $self->{lib_dir} = $self->unknown( key      => 'library directory',
                                       callback => $is_dir)
      unless $self->{lib_dir};
    return $self->{lib_dir};
}

##############################################################################

=head3 so_lib_dir

  my $so_lib_dir = $apache->so_lib_dir;

Returns the Apache shared object library directory path. Currently, this
directory is assumed to be the same as the lib directory, so this method is
simply an alias for C<lib_dir>.

B<Events:>

=over 4

=item info

Executing `httpd -V`

Searching for library directory

=item error

Unable to extract compile settings from `httpd -V`

Cannot parse HTTPD root from `httpd -V`

Cannot find library directory

=item unknown

Enter a valid HTTPD root

Enter a valid Apache library directory

=back

=cut

# For now, at least, these seem to be the same.
*so_lib_dir = \&lib_dir;

##############################################################################

=head3 static_mods

Returns a list (in an array context) or an anonymous array (in a scalar
reference) of all of the modules statically compiled into Apache. These are
collected from the system call C<`httpd -l`>. If Apache is not installed,
C<static_mods()> throws an error and returns an empty list in an array context
or an empty anonymous array in a scalar context.

B<Events:>

=over 4

=item info

Executing `httpd -l`

=item error

Unable to extract needed data from `httpd -l`

=back

=cut

# This code reference collects the list of static modules from Apache. Used by
# static_mods(), mod_perl(), or mod_so(), whichever gets called first.
my $get_static_mods = sub {
    my $self = shift;
    $self->{static_mods} = undef;
    $self->info("Executing `$self->{exe} -l`");
    my $data = `$self->{exe} -l`;
    unless ($data) {
        $self->error("Unable to extract needed data from ".
                     "`$self->{exe} =l`");
        return;
    }

    # Parse out the modules.
    my @mods;
    while ($data =~ /^\s*(\w+)\.c\s*$/mg) {
        push @mods, $1;
        $self->{mod_so} = 1 if $1 eq 'mod_so';
        $self->{mod_perl} = 1 if $1 eq 'mod_perl';
    }
    $self->{static_mods} = \@mods if @mods;
};

sub static_mods {
    my $self = shift;
    return unless $self->{exe};
    $get_static_mods->($self) unless exists $self->{static_mods};
    return unless $self->{static_mods};
    return wantarray ? @{$self->{static_mods}} : $self->{static_mods};
}

##############################################################################

=head3 mod_so

Boolean method that returns true when mod_so has been compiled into Apache,
and false if it has not. The presence or absence of mod_so is determined by
the system call C<`httpd -l`>.

B<Events:>

=over 4

=item info

Executing `httpd -l`

=item error

Unable to extract needed data from `httpd -l`

=back

=cut

sub mod_so {
    my $self = shift;
    return unless $self->{exe};
    $get_static_mods->($self) unless exists $self->{static_mods};
    return $self->{mod_so};
}

##############################################################################

=head3 mod_perl

Boolean method that returns true when mod_perl has been statically compiled
into Apache, and false if it has not. The presence or absence of mod_perl is
determined by the system call C<`httpd -l`>.

B<Events:>

=over 4

=item info

Executing `httpd -l`

=item error

Unable to extract needed data from `httpd -l`

=back

=cut

sub mod_perl {
    my $self = shift;
    return unless $self->{exe};
    $get_static_mods->($self) unless exists $self->{static_mods};
    return $self->{mod_perl};
}

##############################################################################

=head3 home_url

  my $home_url = $apache->home_url;

Returns the Apache home page URL.

=cut

sub home_url { "http://httpd.apache.org/" }

##############################################################################

=head3 download_url

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

Report all bugs via the CPAN Request Tracker at
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-Info>.

=head1 AUTHOR

David Wheeler <L<david@wheeler.net|"david@wheeler.net">> based on code by Sam
Tregar <L<sam@tregar.com|"sam@tregar.com">>.

=head1 SEE ALSO

L<App::Info|App::Info> documents the event handling interface.

L<App::Info::HTTPD|App::Info::HTTPD> is the App::Info::HTTP::Apache parent
class.

L<Apache|Apache> and L<mod_perl_mod_perl> document mod_perl.

L<http://httpd.apache.org/> is the Apache web server home page.

L<http://perl.apache.org/> is the mod_perl home page.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2002-2003, David Wheeler. All Rights Reserved.

This module is free software; you can redistribute it and/or modify it under the
same terms as Perl itself.

=cut
