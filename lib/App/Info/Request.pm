package App::Info::Request;

# $Id: Request.pm,v 1.2 2002/06/12 00:48:43 david Exp $

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
            ({ message => "Cannot find exe",
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

my $get_array = sub {
    Carp::croak("Value '$_[0]' is not an array reference")
      unless UNIVERSAL::isa($_[0], 'ARRAY');
    return $_[0];
};

my $get_hash = sub {
    Carp::croak("Value '$_[0]' is not a hash reference")
      unless UNIVERSAL::isa($_[0], 'HASH');
    return $_[0];
};

my %sigils = ( '$' => sub { shift },
               '@' => $get_array,
               '%' => $get_hash
             );

sub new {
    my ($pkg, $params)= @_;
    my $class = ref $pkg || $pkg;
    if ($params) {
        Carp::croak("Parameters to ${class}->new() must be a hash ",
                    "reference") unless UNIVERSAL::isa($params, 'HASH');
    } else {
        $params = {};
    }

    # Validate the callback.
    if ($params->{callback}) {
        Carp::croak("Callback parameter '$params->{callback}' is not a code ",
                    "reference")
            unless UNIVERSAL::isa($params->{callback}, 'CODE');
    } else {
        # Otherwise just assign a default approve callback.
        $params->{callback} = sub { 1 };
    }

    # Validate the sigil.
    if ($params->{sigil}) {
        unless ($sigils{$params->{sigil}}) {
            my @s = keys %sigils;
            local $" = "', '";
            Carp::croak("Sigil parameter must be one of '@s'");
        }
    } else {
        $params->{sigil} = '$';
    }

    # Validate type parameter.
    if (my $t = $params->{type}) {
        Carp::croak("Invalid handler type '$t'")
          unless $t eq 'error' or $t eq 'info' or $t eq 'unknown'
          or $t eq 'confirm';
    } else {
        $params->{type} = 'info';
    }

    # Return the request object.
    bless $params, $class;
}

sub message { $_[0]->{message} }
sub prompt { $_[0]->{prompt} }
sub sigil { $_[0]->{sigil} }
sub type { $_[0]->{type} }

sub callback {
    my $self = shift;
    my $code = $self->{callback};
    $code->(@_);
}

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
