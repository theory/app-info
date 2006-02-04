#!/usr/bin/perl -w

# $Id$

use strict;
use Test::More tests => 22;
use File::Spec::Functions;

BEGIN { use_ok('App::Info::Lib::OSSPUUID') }

my $ext     = $^O eq 'MSWin32' ? '.bat' : '';
my $bin_dir = catdir 't', 'scripts';
$bin_dir    = catdir 't', 'bin' unless -d $bin_dir;
my $exe     = catfile $bin_dir, "myuuid$ext";

ok my $pg = App::Info::Lib::OSSPUUID->new(
    search_bin_dirs   => $bin_dir,
    search_exe_names  => "uuid-config$ext",
    search_uuid_names => "myuuid$ext",
), 'Got Object';

isa_ok $pg, 'App::Info::Lib::OSSPUUID';
isa_ok $pg, 'App::Info::Lib';
isa_ok $pg, 'App::Info';

is $pg->key_name,      'OSSP UUID', 'Check key name';
ok $pg->installed,                  'OSSP UUID is installed';
is $pg->name,          'OSSP uuid', 'Get name';
is $pg->version,       '1.3.0',     'Test Version';
is $pg->major_version, '1',         'Test major version';
is $pg->minor_version, '3',         'Test minor version';
is $pg->patch_version, '0',         'Test patch version';
is $pg->lib_dir,       't/testlib', 'Test lib dir';
is $pg->executable,    $exe,        'Test executable';
is $pg->uuid,          $exe,        'Test uuid';
is $pg->bin_dir,       $bin_dir,    'Test bin dir';
is $pg->so_lib_dir,    't/testlib', 'Test so lib dir';
is $pg->inc_dir,       't/testinc', 'Test inc dir';
is $pg->cflags,        '-I/usr/local/include', 'Test configure';
is $pg->ldflags,       '-L/usr/local/lib',     'Test configure';

is $pg->home_url,      'http://www.ossp.org/pkg/lib/uuid/', 'Get home URL';
is $pg->download_url,  'http://www.ossp.org/pkg/lib/uuid/', 'Get download URL';
