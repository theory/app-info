package App::Info::HTTPD::Apache;

# $Id: Apache.pm,v 1.14 2002/06/03 23:49:18 david Exp $

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
App::Info::HTTPD.

When it loads, App::Info::HTTPD::Apache searches the local file system for the
F<httpd>, F<apache-perl>, or F<apache> application. If found, the application
(hereafer referred to as F<httpd>, regardless of how it was actually found to
be named) will be called to gather the data necessary for each of the methods
below. If none of the applications can be found, then Apache is assumed not to
be installed, and each of the methods will return C<undef>.

App::Info::HTTPD::Apache searches for F<httpd> along your path, as defined by
File::Spec->path. Failing that, it searches the following directories:

=over 4

=item /usr/local/apache/bin

=item /usr/local/bin

=item /usr/local/sbin

=item /usr/bin

=item /usr/sbin

=item /bin

=item /sw/bin

=item /sw/sbin

=back

=cut

use strict;
use App::Info::HTTPD;
use App::Info::Util;
use Carp ();
use vars qw(@ISA $VERSION);
@ISA = qw(App::Info::HTTPD);
$VERSION = '0.03';

my $obj = {};
my $u = App::Info::Util->new;

do {
    # Find Apache executable.
    my @paths = ($u->path,
      qw(/usr/local/apache/bin
         /usr/local/bin
         /usr/local/sbin
         /usr/bin
         /usr/sbin
         /bin
         /sw/bin
         /sw/sbin));

    my @exes = qw(httpd apache-perl apache);

    $obj->{apache_exe} = $u->first_cat_path(\@exes, @paths);
};

=head1 CONSTRUCTOR

=head2 new

  my $apache = App::Info::HTTPD::Apache->new;

Returns an App::Info::HTTPD::Apache object. Since App::Info::HTTPD::Apache is
implemented as a singleton class, the same object will be returned every time.
This ensures that only the minimum number of system calls are made to gather
the data necessary for the object methods.

=cut

sub new { bless $obj, ref $_[0] || $_[0] }

=head1 OBJECT METHODS

=head2 installed

  print "apache is ", ($apache->installed ? '' : 'not '),
    "installed.\n";

Returns true if Apache is installed, and false if it is not.
App::Info::HTTPD::Apache determines whether Apache is installed based on the
presence or absence of the F<httpd> application on the file system.

=cut

sub installed { return $_[0]->{apache_exe} ? 1 : undef }

=head2 name

  my $name = $apache->name;

Returns the name of the application. App::Info::HTTPD::Apache parses the
name from the system call C<`httpd -v`>.

=cut

sub name {
    $_[0]->version unless exists $_[0]->{version};
    return $_[0]->{name};
}

=head2 version

  my $version = $apache->version;

Returns the apache version number. App::Info::HTTPD::Apache parses the version
number from the system call C<`httpd --v`>. Returns C<undef> if Apache is not
installed. Emits a warning if Apache is installed but the version number could
not be parsed.

=cut

sub version {
    return unless $_[0]->{apache_exe};
    unless (exists $_[0]->{version}) {
        $_[0]->{version} = undef;
        my $version = `$_[0]->{apache_exe} -v`;
        unless ($version) {
            Carp::carp("Failed to find Apache version with " .
                       "`$_[0]->{apache_exe} -v`");
            return;
        }

        chomp $version;
        my ($n, $x, $y, $z) = $version =~
          /Server\s+version:\s+([^\/]*)\/(\d+)\.(\d+).(\d+)/;
        unless ($n and defined $x and defined $y and defined $z) {
            Carp::carp("Failed to parse Apache name and version from string ".
                       "'$version'");
            return;
        }

        @{$_[0]}{qw(name version major minor patch)} =
          ($n, "$x.$y.$z", $x, $y, $z);
    }
    return $_[0]->{version};
}

=head2 major_version

  my $major_version = $apache->major_version;

Returns the apache major version number. App::Info::HTTPD::Apache parses the
version number from the system call C<`httpd --v`>.For example, C<version()>
returns "1.3.24", then this method returns "1". Returns C<undef> if Apache is not
installed. Emits a warning if Apache is installed but the version number could
not be parsed.

=cut

sub major_version {
    $_[0]->version unless exists $_[0]->{version};
    return $_[0]->{major};
}

=head2 minor_version

  my $minor_version = $apache->minor_version;

Returns the apache minor version number. App::Info::HTTPD::Apache parses the
version number from the system call C<`httpd --v`>.For example, C<version()>
returns "1.3.24", then this method returns "3". Returns C<undef> if Apache is not
installed. Emits a warning if Apache is installed but the version number could
not be parsed.

=cut

sub minor_version {
    $_[0]->version unless exists $_[0]->{version};
    return $_[0]->{minor};
}

=head2 patch_version

  my $patch_version = $apache->patch_version;

Returns the apache patch version number. App::Info::HTTPD::Apache parses the
version number from the system call C<`httpd --v`>.For example, C<version()>
returns "1.3.24", then this method returns "24". Returns C<undef> if Apache is
not installed. Emits a warning if Apache is installed but the version number
could not be parsed.

=cut

sub patch_version {
    $_[0]->version unless exists $_[0]->{version};
    return $_[0]->{patch};
}

=head2 httpd_root

  my $httpd_root = $apache->httpd_root;

Returns the HTTPD root directory path. This path is defined at compile time,
and App::Info::HTTPD::Apache parses it from the system call C<`httpd -V`>.
Returns C<undef> if Apache is not installed. Emits a warning if Apache is
installed but the HTTPD root could not be parsed.

=cut

sub httpd_root {
    return unless $_[0]->{apache_exe};
    unless ($_[0]->{-V}) {
        $_[0]->{-V} = 1;
        # Get the compile settings.
        my $data = `$_[0]->{apache_exe} -V`;
        unless ($data) {
            Carp::carp("Unable to extract compile settings from ".
                       "`$_[0]->{apache_exe} =V`");
            return;
        }

        # Split out the parts.
        foreach (split /\s*\n\s*/, $data) {
            if (/magic\s+number:\s+(.*)$/i) {
                $_[0]->{magic_number} = $1;
            } elsif (/=/) {
                $_ =~ s/^-D\s+//;
                $_ =~ s/"$//;
                my ($k, $v) = split /\s*=\s*"/, $_;
                $_[0]->{lc $k} = $v;
            } elsif (/-D/) {
                $_ =~ s/^-D\s+//;
                $_[0]->{lc $_} = 1;
            }
        }
        # Issue a warning if no httpd root was found.
        Carp::carp("Could not parse HTTPD root from `$_[0]->{apache_exe} -V`")
          unless $_[0]->{httpd_root};
    }
    return $_[0]->{httpd_root};
}

=head2 magic_number

  my $magic_number = $apache->magic_number;

Returns the "Magic Number" for the Apache installation. This number is defined
at compile time, and App::Info::HTTPD::Apache parses it from the system call
C<`httpd -V`>. Returns C<undef> if Apache is not installed or if the magic number
could not be parsed.

=cut

sub magic_number {
    $_[0]->httpd_root unless $_[0]->{-V};
    return $_[0]->{magic_number};
}

=head2 compile_option

  my $compile_option = $apache->compile_option($option);

Returns the value of the Apache compile option $option. All of the Apache
compile options are collected from the system call C<`httpd -V`>. For compile
options that contain a corresponding value (such as 'SUEXEC_BIN" or
"DEFAULT_PIDLOG"), C<compile_option()> returns the value of the option if it
exists. For other options, it returns true (1) if the option was included, and
false(C<undef>) if it was not. Returns C<undef> if Apache is not installed or if the
option could not be parsed.

See the Apache documentation at L<http://httpd.apache.org/docs-project/> to
learn about all the possible compile options.

=cut

sub compile_option {
    $_[0]->httpd_root unless $_[0]->{-V};
    return $_[0]->{lc $_[1]};
}

=head2 conf_file

Returns the full path to the Apache configuration file. C<conf_file()> looks
for the configuration file in a number of locations and under a number of
names. First it tries to use the file specifed by the SERVER_CONFIG_FILE
compile option (as returned by a call to C<compile_option()> -- and if it's a
relative file name, it gets appended to the directory returned by
C<httpd_root()>. If that file isn't found, C<conf_file()> then looks for the
files F<httpd.conf> and F<httpd.conf.default> in the F<conf> subdirectory of
the httpd root directory. Failing that, it looks for the following:

=over 4

=item /usr/share/doc/apache-perl/examples/httpd.conf

=item /usr/share/doc/apache-perl/examples/httpd.conf.default

=item /etc/httpd/httpd.conf

=item /etc/httpd/httpd.conf.default

=back

Returns C<undef> if the file cannot be found.

=cut

sub conf_file {
    return unless $_[0]->{apache_exe};
    unless (exists $_[0]->{conf_file}) {
        my $root = $_[0]->httpd_root;
        my $conf = $_[0]->compile_option('SERVER_CONFIG_FILE');
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

        $_[0]->{conf_file} = $u->first_file(@paths)
          or Carp::carp("No server config file found");
    }
    return $_[0]->{conf_file};
}

=head2 user

  my $user = $apache->user;

Returns the name of the Apache user. This value is collected from the Apache
configuration file as returned by C<conf_file()>. Returns C<undef> if Apache
isn't installed or the configuration file cannot be found or if the user name
could not be parsed from the configuration file.

=cut

sub user {
    return unless $_[0]->{apache_exe};
    unless (exists $_[0]->{user}) {
        $_[0]->{user} = undef;
        my $conf = $_[0]->conf_file or return;

        # This is the place to add more regexes to collect stuff from the
        # config file in the future.
        my @regexen = (qr/^\s*User\s+(.*)$/,
                       qr/^\s*Group\s+(.*)$/,
                       qr/^\s*Port\s+(.*)$/ );
        my ($usr, $grp, $prt) = $u->multi_search_file($conf, @regexen);
        # Issue a warning if we couldn't find the user and group.
        Carp::carp("Could not parse user and group from file '$conf'")
          unless $usr && $grp;
        Carp::carp("Could not parse port from file '$conf'") unless $prt;
        # Assign them anyway.
        @{$_[0]}{qw(user group port)} = ($usr, $grp, $prt);
    }
    return $_[0]->{user};
}

=head2 group

Returns the name of the Apache user group. This value is collected from the
Apache configuration file as returned by C<conf_file()>. Returns C<undef> if
Apache isn't installed or the configuration file cannot be found or if the
group name could not be parsed from the configuration file.

=cut

sub group {
    $_[0]->user unless exists $_[0]->{user};
    return $_[0]->{group};
}

=head2 port

Returns the port number on which Apache listens. This value is collected from
Apache configuration file as returned by C<conf_file()>. Returns C<undef> if
Apache isn't installed or the configuration file could not be found or if the
port number could not be parsed from the configuration file.

=cut

sub port {
    $_[0]->user unless exists $_[0]->{user};
    return $_[0]->{port};
}

=head2 bin_dir

  my $bin_dir = $apache->bin_dir;

Returns the Apache binary directory path. App::Info::HTTPD::Apache simply
looks for the F<bin> directory under the F<httpd_root> directory, as returned
by C<$apache->httpd_root>. Returns C<undef> if Apache is not installed or if the
bin directory could not be found.

=cut

sub bin_dir {
    unless (exists $_[0]->{bin_dir}) {
        $_[0]->{bin_dir} = undef;
        my $root = $_[0]->httpd_root || return;
        if (my $dir = $u->first_cat_path('bin', $root)) {
            $_[0]->{bin_dir} = $dir;
        }

    }
    return $_[0]->{bin_dir};
}

=head2 inc_dir

  my $inc_dir = $apache->inc_dir;

Returns the Apache include directory path. App::Info::HTTPD::Apache simply
looks for the F<include> or F<inc> directory under the F<httpd_root>
directory, as returned by C<$apache->httpd_root>. Returns C<undef> if Apache is
not installed or if the inc directory could not be found.

=cut

sub inc_dir {
    unless (exists $_[0]->{inc_dir}) {
        $_[0]->{inc_dir} = undef;
        my $root = $_[0]->httpd_root || return;
        if (my $dir = $u->first_cat_path(['include', 'inc',], $root)){
            $_[0]->{inc_dir} = $dir;
        }
    }
    return $_[0]->{inc_dir};
}

=head2 lib_dir

  my $lib_dir = $apache->lib_dir;

Returns the Apache library directory path. App::Info::HTTPD::Apache simply
looks for the F<lib>, F<modules>, or F<libexec> directory under the
F<httpd_root> directory, as returned by C<$apache->httpd_root>. Returns C<undef>
if Apache is not installed or if the lib directory could not be found.

=cut

sub lib_dir {
    unless (exists $_[0]->{lib_dir}) {
        $_[0]->{lib_dir} = undef;
        my $root = $_[0]->httpd_root || return;
        if (my $dir = $u->first_cat_path(['lib', 'modules', 'libexec'], $root)){
            $_[0]->{lib_dir} = $dir;
        } elsif ($u->first_dir('/usr/lib/apache/1.3')) {
            # The Debian way.
            $_[0]->{lib_dir} = '/usr/lib/apache/1.3';
        }
    }
    return $_[0]->{lib_dir};
}

=head2 so_lib_dir

  my $so_lib_dir = $apache->so_lib_dir;

Returns the Apache shared object library directory path. Currently, this
directory is assumed to be the same as the lib directory, so this method is
simply an alias for C<lib_dir>. Returns C<undef> if Apache is not installed or if
the lib directory could not be found.

=cut

# For now, at least, these seem to be the same.
*so_lib_dir = \&lib_dir;

=head2 static_mods

Returns a list (in an array context) or an anonymous array (in a scalar
reference) of all of the modules statically compiled into Apache. These are
collected from the system call C<`httpd -l`>. If Apache is not installed,
C<static_mods()> returns an empty list in an array reference, or an empty
anonymous array in a scalar context.

=cut

sub static_mods {
    return unless $_[0]->{apache_exe};
    unless (exists $_[0]->{static_mods}) {
        $_[0]->{static_mods} = undef;
        my $data = `$_[0]->{apache_exe} -l`;
        unless ($data) {
            Carp::carp("Unable to extract needed data from ".
                       "`$_[0]->{apache_exe} =l`");
            return;
        }

        # Parse out the modules.
        my @mods;
        while ($data =~ /^\s*(\w+)\.c\s*$/mg) {
            push @mods, $1;
            $_[0]->{mod_so} = 1 if $1 eq 'mod_so';
            $_[0]->{mod_perl} = 1 if $1 eq 'mod_perl';
        }
        $_[0]->{static_mods} = \@mods;
    }
    return unless $_[0]->{static_mods};
    return wantarray ? @{$_[0]->{static_mods}} : $_[0]->{static_mods};
}

=head2 mod_so

Boolean method that returns true when mod_so has been compiled into Apache,
and false if it has not. The presence or absence of mod_so is determined by
the system call C<`httpd -l`>. Returns false if Apache has not been installed.

=cut

sub mod_so {
    $_[0]->static_mods unless $_[0]->{static_mods};
    return $_[0]->{mod_so};
}

=head2 mod_perl

Boolean method that returns true when mod_perl has been statically compiled
into Apache, and false if it has not. The presence or absence of mod_perl is
determined by the system call C<`httpd -l`>. Returns false if Apache has not
been installed.

=cut

sub mod_perl {
    $_[0]->static_mods unless $_[0]->{static_mods};
    return $_[0]->{mod_perl};
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
particular may be considered rather weak. Patches from those who know a great
deal more about interrogating Apache will be most welcome.

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
