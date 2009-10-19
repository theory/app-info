#!perl -w

# $Id$

use strict;
use Test::More;
eval 'use Test::Spelling';
plan skip_all => 'Test::Spelling required for testing POD spelling' if $@;

add_stopwords(<DATA>);
all_pod_files_spelling_ok();

__DATA__
DBI
SQLite
dylib
libsqlite
sqlite
Tregar
createdb
createlang
createuser
dropdb
droplang
dropuser
executables
initdb
postgres
psql
vacuumdb
LD
OSSP
UUID
cflags
ldflags
uuid
AxKit
Seargent's
libiconv
libexpat
DSOs
DocumentRoot
apache
apachectl
apxs
conf
htdigest
libexec
logresolve
rotatelogs
subdirectory
stderr
stdout
parameterized
MSWin
VMS
os
epoc
API
FooHandler
subclassable
Automake
CPAN
FooApp
one's
cgi
ScriptAlias
