package App::Info::Handler::Print;

# $Id: Print.pm,v 1.3 2002/06/15 00:49:55 david Exp $

=head1 NAME

App::Info::Handler::Print - App::Info Print handler

=head1 SYNOPSIS

  use strict;
  use App::Info::Handler::Print;
  use App::Info::Category::FooApp;

  my $carp = App::Info::Handler::Print->new('stderr');

=head1 DESCRIPTION

To be written.

=cut

use strict;
use App::Info::Handler;
use vars qw($VERSION @ISA);
$VERSION = '0.01';
@ISA = qw(App::Info::Handler);

# Register ourselves.
for my $c (qw(stderr stdout)) {
    App::Info::Handler->register_handler
      ($c, sub { __PACKAGE__->new( fh => $c ) } );
}

sub new {
    my $pkg = shift;
    my $self = $pkg->SUPER::new(@_);
    if (!defined $self->{fh} || $self->{fh} eq 'stderr') {
        # Create a reference to STDERR.
        $self->{fh} = \*STDERR;
    } elsif ($self->{fh} eq 'stdout') {
        # Create a reference to STDOUT.
        $self->{fh} = \*STDOUT;
    } elsif (!ref $self->{fh}) {
        # Assume a reference to a file handle or else it's invalid.
        Carp::croak("Invalid argument to new(): '$self->{fh}'");
    }
    # We're done!
    return $self;
}

sub handler {
    my ($self, $req) = @_;
    print {$self->{fh}} $req->message, "\n";
    # Return true to indicate that we've handled the request.
    return 1;
}

1;
__END__

=head1 BUGS

Can there really be much in the way of bugs in an abstract base class? Drop me
a line if you happen to discover any.

=head1 AUTHOR

David Wheeler <david@wheeler.net>

=head1 SEE ALSO

L<App::Info|App::Info>
L<App::Info::HTTPD::Apache|App::Info::HTTPD::Apache>,
L<App::Info::RDBMS::PostgreSQL|App::Info::RDBMS::PostgreSQL>,
L<App::Info::Lib|App::Info::Lib::Expat>,
L<App::Info::Lib|App::Info::Lib::Iconv>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2002, David Wheeler. All Rights Reserved.

This module is free software; you can redistribute it and/or modify it under the
same terms as Perl itself.

=cut
