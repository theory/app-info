package App::Info::Lib::Iconv;

# $Id: Iconv.pm,v 1.5 2002/06/01 21:41:48 david Exp $

use strict;
use File::Basename ();
use App::Info::Util;
use App::Info::Lib;
use vars qw(@ISA $VERSION);
@ISA = qw(App::Info::Lib);
$VERSION = '0.01';

my $obj = {};
my $u = App::Info::Util->new;

do {
    # Find iconv.
    my @paths = ($u->path,
      qw(/usr/local/bin
         /usr/bin
         /bin
         /sw/bin
         /usr/local/sbin
         /usr/sbin/
         /sbin
         /sw/sbin));

    $obj->{iconv_exe} = $u->first_cat_file('iconv', @paths);
};

sub new { bless $obj, ref $_[0] || $_[0] }

sub installed { $_[0]->{iconv_exe} ? 1 : undef }
sub name { 'libiconv' }
# How does one get the version number?
sub version {}
sub major_version {}
sub minor_version {}
sub patch_version {}
sub home_url { 'http://http://www.gnu.org/software/libiconv/' }
sub download_url { 'ftp://ftp.gnu.org/pub/gnu/libiconv/' }

sub bin_dir {
    return unless $_[0]->{iconv_exe};
    unless (exists $_[0]->{bin_dir}) {
        $_[0]->{bin_dir} = File::Basename::dirname($_[0]->{iconv_exe});
    }
    return $_[0]->{bin_dir};
}

sub inc_dir {
    return unless $_[0]->{iconv_exe};
    unless (exists $_[0]->{inc_dir}) {
        $_[0]->{inc_dir} = undef;
        # Should there be more paths than this?
        my @paths = qw(/usr/local/include
                       /usr/include);

        $_[0]->{inc_dir} = $u->first_cat_file('iconv.h', @paths);
    }
    return $_[0]->{inc_dir};
}

sub lib_dir {
    return unless $_[0]->{iconv_exe};
    unless (exists $_[0]->{lib_dir}) {
        $_[0]->{lib_dir} = undef;
        # Should there be more paths than this?
        my @paths = qw(/usr/local/lib
                       /usr/lib);
        my @files = qw(libexpat.so
                       libexpat.so.0
                       libexpat.so.0.0.1
                       libexpat.a
                       libexpat.la);

        $_[0]->{lib_dir} = $u->first_cat_file(\@files, @paths);
    }
    return $_[0]->{lib_dir};
}

sub so_lib_dir {
    return unless $_[0]->{iconv_exe};
    unless (exists $_[0]->{so_lib_dir}) {
        $_[0]->{so_lib_dir} = undef;
        # Should there be more paths than this?
        my @paths = qw(/usr/local/lib
                       /usr/lib);
        # Testing is the same as for lib_dir() except that we only check for
        # sos.
        my @files = qw(libexpat.so
                       libexpat.so.0
                       libexpat.so.0.0.1);

        $_[0]->{so_lib_dir} = $u->first_cat_file(\@files, @paths);
    }
    return $_[0]->{so_lib_dir};
}

1;
__END__
