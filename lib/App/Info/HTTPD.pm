package App::Info::HTTPD;

use strict;
use App::Info;
use vars qw(@ISA $VERSION);
@ISA = qw(App::Info);
$VERSION = '0.01';

1;
__END__

# $Id: HTTPD.pm,v 1.3 2002/06/01 22:23:30 david Exp $

=head1 NAME

App::Info::HTTPD - Information about web servers on a system

=head1 DESCRIPTION

This class is an abstract base class for App::Info subclasses that provide
information about databases. Its subclasses are required to implement its
interface. See L<App::Info|App::Info> for a complete description and
L<App::Info::RDBMS::PostgreSQL|App::Info::RDBMS::PostgreSQL> for an example
implementation.

=head1 AUTHOR

David Wheeler <david@wheeler.net>

=head1 SEE ALSO

L<App::Info|App::Info>,
L<App::Info::RDBMS::PostgreSQL|App::Info::RDBMS::PostgreSQL>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2002, David Wheeler. All Rights Reserved.

This module is free software; you can redistribute it and/or modify it under the
same terms as Perl itself.

=cut


