package App::Info::Handler;

# $Id: Handler.pm,v 1.1 2002/06/08 07:22:06 david Exp $

=head1 NAME

App::Info::Handler - App::Info error and null value handler base class

=head1 SYNOPSIS

  package App::Info::Category::FooApp;
  use strict;

  sub new {
      # Construct the object.
      my $self = shift->SUPER::new(@_);

      # Find relevant file.
      if (my $exe = _find_exe()) {
          # Just keep it if we're successful.
          $self->{exe_loc} = $exe;
      } else {
          # We got a null value. Handle null calls stack of handlers.
          $self->{exe_loc} = $self->null
            ({ error => "Cannot find exe",
               prompt => "Where is exe?",
               sigil  => '$',
               callback => \&is_exe
            });
      }
  }

=head1 DESCRIPTION

To be written.

=cut

use strict;
use vars qw($VERSION);
$VERSION = '0.01';

use constant OK => 1;
use constant DECLINED => 2;

# Register ourself.
App::Info->register_handler('default', sub { __PACKAGE__->new } );

sub new { bless {}, ref $_[0] || $_[0] }
sub handler { OK }

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
