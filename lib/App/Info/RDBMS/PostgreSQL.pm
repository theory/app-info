package App::Info::RDBMS::PostgreSQL;

use strict;
use File::Spec::Functions ();
use App::Info::Util;
use vars qw(@ISA $VERSION);
@ISA = qw(App::Info);
$VERSION = '0.01';

my $obj = {};
my $u = App::Info::Util->new;

do {
    # Find pg_config.
    my @paths = (File::Spec::Functions::path(),
      qw(/usr/local/pgsql/bin/pg_config
         /usr/local/postgres/bin/pg_config
         /opt/pgsql/bin/pg_config
         /usr/local/bin/pg_config
         /usr/local/sbin/pg_config
         /usr/bin/pg_config
         /usr/sbin/pg_config
         /bin/pg_config));

    $obj->{pg_config} = $u->first_cat_file('pg_config', @paths);
};

sub new { bless $obj, ref $_[0] || $_[0] }

my $get_data = sub {
    my $pgc = $_[0]->{pg_config} || return;
    my $info = `$pgc $_[1]`;
    chomp $info;
    return $info;
};

sub installed { return $_[0]->{pg_config} ? 1 : undef }

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

sub version {
    $_[0]->name unless $_[0]->{version};
    return $_[0]->{version};
}

sub major_version {
    $_[0]->name unless $_[0]->{version};
    return $_[0]->{major};
}

sub minor_version {
    $_[0]->name unless $_[0]->{version};
    return $_[0]->{minor};
}

sub patch_version {
    $_[0]->name unless $_[0]->{version};
    return $_[0]->{patch};
}

sub inc_dir {
    $_[0]->{inc_dir} ||= $get_data->($_[0], '--includedir');
    return $_[0]->{inc_dir};
}

sub bin_dir {
    $_[0]->{bin_dir} ||= $get_data->($_[0], '--bindir');
    return $_[0]->{bin_dir};
}

sub lib_dir {
    $_[0]->{lib_dir} ||= $get_data->($_[0], '--libdir');
    return $_[0]->{lib_dir};
}

# Location of dynamically loadable modules.
sub so_lib_dir {
    $_[0]->{so_lib_dir} ||= $get_data->($_[0], '--pkglibdir');
    return $_[0]->{so_lib_dir};
}

sub home_url { "http://www.postgresql.org/" }
sub download_url { "http://www.ca.postgresql.org/sitess.html" }

1;
__END__
