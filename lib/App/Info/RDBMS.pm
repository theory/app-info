package App::Info::RDBMS;

use strict;
use App::Info;
use vars qw(@ISA $VERSION);
@ISA = qw(App::Info);
$VERSION = '0.01';

1;
__END__

# $Id: RDBMS.pm,v 1.2 2002/06/01 21:54:43 david Exp $

=head1 NAME

App::Info::RDBMS - Information about databases on a system

=head1 DESCRIPTION

This class is an abstract base class for App::Info subclasses that provide
information about web servers. Its subclasses are required to implement its
interface. See L<App::Info|App::Info> for a complete description and
L<App::Info::HTTPD::Apache|App::Info::HTTPD::Apache> for an example
implementation.

=head1 AUTHOR

David Wheeler <david@wheeler.net>

=head1 SEE ALSO

L<App::Info|App::Info>
L<App::Info::HTTPD::Apache|App::Info::HTTPD::Apache>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2002, David Wheeler. All Rights Reserved.

This module is free software; you can redistribute it and/or modify it under the
same terms as Perl itself.

=cut



