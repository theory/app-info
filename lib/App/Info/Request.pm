package App::Info::Request;

# $Id: Request.pm,v 1.5 2002/06/16 00:42:51 david Exp $

=head1 NAME

App::Info::Handler - App::Info event handler request object

=head1 SYNOPSIS

  package App::Info::Handler::FooHandler;
  use strict;
  use App::Info::Handler;
  use vars qw(@ISA);
  @ISA = qw(App::Info::Handler);

  # ...

  sub handler {
      my ($self, $req) = @_;
      print "Event Type:  ", $req->type;
      print "Message:     ", $req->message;
      print "Error:       ", $req->error;
      print "Value:       ", $req->value;
  }

=head1 DESCRIPTION

Objects of this class are passed to the C<handler()> method of App::Info event
handlers. Generally, this class will be of most interest to App::Info::Handler
subclass implementors.

The L<event triggering methods|App::Info/"Events"> in App::Info each construct
a new App::Info::Request object and initialize it with their arguments. The
App::Info::Request object is then the sole argument passed to the C<handler()>
method of any and all App::Info::Handler objects in the event handling chain.
Thus, if you'd like to create your own App::Info event handler, this is the
object you need to be familiar with.

Each of the App::Info event triggering methods constructs an
App::Info::Request object with different values. Be sure to consult the
documentation for the L<event triggering methods|App::Info/"Events"> in
App::Info, where the values assigned to the App::Info::Request object are
documented. Then, in your event handler subclass, check the value returned by
the C<type()> method to determine what type of event request you'r handling to
handle the request appropriately.

=cut

use strict;
use vars qw($VERSION);
$VERSION = '0.20';

##############################################################################
# This code reference is used to validate and return an array reference.
my $get_array = sub {
    Carp::croak("Value '$_[0]' is not an array reference")
      unless UNIVERSAL::isa($_[0], 'ARRAY');
    return $_[0];
};

##############################################################################
# This code reference is used to validate and return a hash reference.
my $get_hash = sub {
    Carp::croak("Value '$_[0]' is not a hash reference")
      unless UNIVERSAL::isa($_[0], 'HASH');
    return $_[0];
};

##############################################################################
# This hash links different sigils to their validation code references.
my %sigils = ( '$' => sub { shift },
               '@' => $get_array,
               '%' => $get_hash
             );

##############################################################################

=head1 INTERFACE

The following sections document the App::Info::Request interface.

=head2 Constructor

=head3 new

  my $req = App::Info::Request->new(\%params);

This method is used internally by App::Info to construct new
App::Info::Request objects to pass to event handler objects. Generally, you
won't need to use it, other than perhaps for testing custom App::Info::Handler
classes.

The parameters to C<new()> are passed as a hash reference.

=cut

sub new {
    my $pkg = shift;

    # Make sure we've got a hash of arguments.
    Carp::croak("Odd number of parameters in call to " . __PACKAGE__ .
                "->new() when named parameters expected" ) if @_ % 2;
    my %params = @_;

    # Validate the callback.
    if ($params{callback}) {
        Carp::croak("Callback parameter '$params{callback}' is not a code ",
                    "reference")
            unless UNIVERSAL::isa($params{callback}, 'CODE');
    } else {
        # Otherwise just assign a default approve callback.
        $params{callback} = sub { 1 };
    }

    # Validate the sigil.
    if ($params{sigil}) {
        unless ($sigils{$params{sigil}}) {
            my @s = keys %sigils;
            local $" = "', '";
            Carp::croak("Sigil parameter must be one of '@s'");
        }
    } else {
        $params{sigil} = '$';
    }

    # Validate type parameter.
    if (my $t = $params{type}) {
        Carp::croak("Invalid handler type '$t'")
          unless $t eq 'error' or $t eq 'info' or $t eq 'unknown'
          or $t eq 'confirm';
    } else {
        $params{type} = 'info';
    }

    # Return the request object.
    bless \%params, ref $pkg || $pkg;
}

##############################################################################

sub message { $_[0]->{message} }

##############################################################################

sub error { $_[0]->{error} }

##############################################################################

sub sigil { $_[0]->{sigil} }

##############################################################################

sub type { $_[0]->{type} }

##############################################################################

sub callback {
    my $self = shift;
    my $code = $self->{callback};
    local $_ = $_[0];
    $code->(@_);
}

##############################################################################

sub value {
    my $self = shift;
    if ($#_ >= 0) {
        # grab the value.
        my $value = $sigils{$self->sigil}->(@_);
        # Validate the value.
        if ($self->callback($value)) {
            # The value is good. Assign it and return true.
            $self->{value} = $value;
            return 1;
        } else {
            # Invalid value. Return false.
            return;
        }
    }
    # Just return the value.
    return $self->{value};
}

1;
__END__

=head1 BUGS

I suppose it's possible that there are bugs in this code. Drop me a line if
you happen to discover any.

=head1 AUTHOR

David Wheeler <david@wheeler.net>

=head1 SEE ALSO

L<App::Info|App::Info>
L<App::Info::Handler:|App::Info::Handler>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2002, David Wheeler. All Rights Reserved.

This module is free software; you can redistribute it and/or modify it under the
same terms as Perl itself.

=cut
