package App::Info::Handler::Carp;

# $Id: Carp.pm,v 1.2 2002/06/10 06:03:06 david Exp $

=head1 NAME

App::Info::Handler::Carp - App::Info Carp handler

=head1 SYNOPSIS

  use strict;
  use App::Info::Handler::Carp;
  use App::Info::Category::FooApp;

  my $carp = App::Info::Handler::Carp->new('croak');
  my $app = App::Info::Category::FooApp->new( on_error => [ $carp ],
                                              on_null  => [ $carp ] );

=head1 DESCRIPTION

To be written.

=cut

use strict;
use App::Info::Handler;
use vars qw($VERSION @ISA);
$VERSION = '0.01';
@ISA = qw(App::Info::Handler);

my %levels = ( croak   => sub { Carp::croak(@_) },
               carp    => sub { Carp::carp(@_) },
               cluck   => sub { Carp::cluck(@_) },
               confess => sub { Carp::confess(@_) }
             );

# A couple of aliases.
$levels{die} = $levels{croak};
$levels{warn} = $levels{carp};

# Register ourselves.
for (qw(croak carp cluck confess die warn)) {
    App::Info->register_handler($_, sub { __PACKAGE__->new($_) } );
}

sub new {
    my ($pkg, $level) = @_;
    my $self = $pkg->SUPER::new;
    if ($level) {
        Carp::croak("Invalid error_level '$level'")
          unless $levels{$level};
        $self->{level} = $level;
    } else {
        $self->{level} = 'carp';
    }
    return $self;
}

sub handler {
    my ($self, $req) = @_;
    $levels{level}->($req->error);
    # Return OK to indicate that we've handled the request.
    return App::Info::Handler::OK;
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
