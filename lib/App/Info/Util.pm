package App::Info::Util;

use strict;
use File::Spec::Functions ();
use vars qw(@ISA $VERSION);
@ISA = qw(File::Spec);
$VERSION = '0.01';

my %path_dems = (MacOS   => qr',',
                 MSWin32 => qr';',
                 os2     => qr';',
                 VMS     => undef,
                 epoc    => undef);

my $path_dem = exists $path_dems{$^O} ? $path_dems{$^O} : qr':';

sub new { bless {}, ref $_[0] || $_[0] }

sub first_dir {
    shift;
    foreach (@_) { return $_ if -d }
    return;
}

sub first_path {
    return unless $path_dem;
    shift;
    first_dir(split /$path_dem/, shift)
}

sub first_file {
    shift;
    foreach (@_) { return $_ if -e }
    return;
}

sub first_cat_file {
    my $self = shift;
    my $file = shift;
    foreach my $exe (ref $file ? @$file : ($file)) {
        foreach (@_) {
            my $path = File::Spec::Functions::catfile($_, $exe);
            return $path if -e $path;
        }
    }
    return;
}

1;
__END__
