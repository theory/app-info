package App::Info::HTTPD::Apache;

# $Id: Apache.pm,v 1.3 2002/06/01 21:29:05 david Exp $

use strict;
use App::Info::Util;
use Carp ();
use vars qw(@ISA $VERSION);
@ISA = qw(App::Info);
$VERSION = '0.02';

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

    $obj->{apache_exe} = $u->first_cat_file(\@exes, @paths);
};

sub new { bless $obj, ref $_[0] || $_[0] }

sub installed { return $_[0]->{apache_exe} ? 1 : undef }

# This should get the name from somewhere...
sub name { return $_[0]->{apache_exe} ? 'Apache' : undef }

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
        my ($x, $y, $z) = $version =~ /(\d+)\.(\d+).(\d+)/;
        unless (defined $x and defined $y and defined $z) {
            Carp::carp("Failed to parse Apache version from string '$version'");
            return;
        }

        @{$_[0]}{qw(version major minor patch)} = ("$x.$y.$z", $x, $y, $z);
    }
    return $_[0]->{version};
}

sub major_version {
    $_[0]->version unless $_[0]->{version};
    return $_[0]->{major};
}

sub minor_version {
    $_[0]->version unless $_[0]->{version};
    return $_[0]->{minor};
}

sub patch_version {
    $_[0]->version unless $_[0]->{version};
    return $_[0]->{patch};
}

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
    }
    return $_[0]->{httpd_root}
}

sub magic_number {
    $_[0]->httpd_root unless $_[0]->{-V};
    return $_[0]->{magic_number};
}

sub compile_option {
    $_[0]->httpd_root unless $_[0]->{-V};
    return $_[0]->{lc $_[1]};
}

sub bin_dir {
    unless (exists $_[0]->{bin_dir}) {
        $_[0]->{bin_dir} = undef;
        my $root = $_[0]->httpd_root || return;
        if (my $dir = $u->first_cat_file('bin', $root)) {
            $_[0]->{bin_dir} = $dir;
        }

    }
    return $_[0]->{bin_dir};
}

sub inc_dir {
    unless (exists $_[0]->{inc_dir}) {
        $_[0]->{inc_dir} = undef;
        my $root = $_[0]->httpd_root || return;
        if (my $dir = $u->first_cat_file(['include', 'inc',], $root)){
            $_[0]->{inc_dir} = $dir;
        }
    }
    return $_[0]->{inc_dir};
}

sub lib_dir {
    unless (exists $_[0]->{lib_dir}) {
        $_[0]->{lib_dir} = undef;
        my $root = $_[0]->httpd_root || return;
        if (my $dir = $u->first_cat_file(['lib', 'modules', 'libexec'], $root)){
            $_[0]->{lib_dir} = $dir;
        } elsif ($u->first_dir('/usr/lib/apache/1.3')) {
            # The Debian way.
            $_[0]->{lib_dir} = '/usr/lib/apache/1.3';
        }
    }
    return $_[0]->{lib_dir};
}

# For now, at least, these seem to be the same.
*so_lib_dir = \&lib_dir;

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
        }
        $_[0]->{static_mods} = \@mods;
    }
    return unless $_[0]->{static_mods};
    return wantarray ? @{$_[0]->{static_mods}} : $_[0]->{static_mods};
}

sub mod_so {
    $_[0]->static_mods unless $_[0]->{static_mods};
    return $_[0]->{mod_so};
}

sub home_url { "http://httpd.apache.org/" }
sub download_url { "http://www.apache.org/dist/httpd/" }

1;
__END__
