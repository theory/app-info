package App::Info::HTTPD;

use strict;
use App::Info;
use vars qw(@ISA $VERSION);
@ISA = qw(App::Info);
$VERSION = '0.02';

my $croak = sub {
    my ($caller, $meth) = @_;
    $caller = ref $caller || $caller;
    if ($caller eq __PACKAGE__) {
        $meth = __PACKAGE__ . '::' . shift;
        Carp::croak(__PACKAGE__ . " is an abstract base class. Attempt to " .
                    " call non-existent method $meth");
    } else {
        Carp::croak("Class $caller inherited from the abstract base class " .
                    __PACKAGE__ . "but failed to redefine the $meth method. " .
                    "Attempt to call non-existent method ${caller}::$meth");
    }
};

sub httpd_root { $croak->(shift, 'httpd_root') }


1;
__END__

# $Id: HTTPD.pm,v 1.4 2002/06/03 18:57:08 david Exp $

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


