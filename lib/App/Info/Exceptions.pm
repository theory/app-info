package App::Info::Exceptions;

# $Id: Exceptions.pm,v 1.1 2002/06/05 04:36:11 david Exp $

=head1 NAME

App::Info::Exceptions - Defines Exceptions for App::Info

=head1 SYNOPSIS

  package App::Info::Category::FooApp;

  use App::Info::Exceptions;

  eval {
      # Something goes wrong...
  };

  App::Info::Exception::ParseError->new( error => $@ ) if $@;

=head1 DESCRIPTION

To be written.

=cut

use strict;
use vars qw(@ISA $VERSION);
@ISA = qw(Exception::Class);
$VERSION = '0.01';

################################################################################
# Constants
################################################################################
use constant DEBUG => 1;

# Turn on tracing if debugging is on.
DEBUG && __PACKAGE__->Trace(1);

################################################################################
# Exception definitions
################################################################################
use Exception::Class
  ( App::Info::Exception =>
    { description => 'Generic App::Info exception base class.'},
   App::Info::Exception::ParseError =>
    { description => 'Error parsing values from a file file.',
      isa => 'Kinet::Util::Except' },
  );

##############################################################################
# Construtors
##############################################################################
sub throw {
    my $pkg = shift;
    # We need an App::Info object.
    my $obj = shift
      or Exception::Class::Base->throw( error => "App::Info object not " .
                                        "passed to constructor for class " .
                                        ref $pkg || $pkg );
    my $self = $pkg->new(@_);
    # Decide what to do with the exception here die, warn, or do nothing,
    # based on a flag in $obj.
}


1;
__END__

=head1 BUGS

None. No, really! But if you find you must report them anyway, drop me an
email.

=head1 AUTHOR

David Wheeler <david@wheeler.net>

=head1 SEE ALSO

L<App::Info|App::Info>,
L<App::Info::HTTPD::Apache|App::Info::HTTPD::Apache>
L<App::Info::RDBMS::PostgreSQL|App::Info::RDBMS::PostgreSQL>
L<App::Info::Lib::Expat|App::Info::Lib::Expat>,
L<App::Info::Lib::Iconv|App::Info::Lib::Iconv>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2002, David Wheeler. All Rights Reserved.

This module is free software; you can redistribute it and/or modify it under the
same terms as Perl itself.

=cut
