package App::Info::Handler::Prompt;

# $Id: Prompt.pm,v 1.6 2002/06/15 00:49:55 david Exp $

=head1 NAME

App::Info::Handler::Prompt - App::Info Prompt handler

=head1 SYNOPSIS

  use strict;
  use App::Info::Handler::Prompt;
  use App::Info::Category::FooApp;

  my $prompt = App::Info::Handler::Prompt->new;

=head1 DESCRIPTION

To be written.

=cut

use strict;
use App::Info::Handler;
use vars qw($VERSION @ISA);
$VERSION = '0.01';
@ISA = qw(App::Info::Handler);

# Register ourselves.
App::Info::Handler->register_handler('prompt',
                                     sub { __PACKAGE__->new('prompt') } );

sub new {
    my $pkg = shift;
    my $self = $pkg->SUPER::new(@_);
    $self->{tty} = -t STDIN && ( -t STDOUT || !( -f STDOUT || -c STDOUT ) );
    # We're done!
    return $self;
}

my $get_ans = sub {
    my ($prompt, $tty, $def) = @_;
    # Print the message.
    local $| = 1;
    local $\;
    print $prompt;

    # Collect the answer.
    my $ans;
    if ($tty) {
        $ans = <STDIN>;
        if (defined $ans ) {
            chomp $ans;
        } else { # user hit ctrl-D
            print "\n";
        }
    } else {
        print "$def\n" if defined $def;
    }
    return !defined $ans || $ans eq '' ? $def : $ans;
};

sub handler {
    my ($self, $req) = @_;
    my $ans;
    my $type = $req->type;
    if ($type eq 'unknown' || $type eq 'confirm') {
        # We'll want to prompt for a new value.
        my $val = $req->value;
        my ($def, $dispdef) = defined $val ? ($val, " [$val] ") : ('', ' ');
        my $msg = $req->message or Carp::croak("No message in request");
        $msg .= $dispdef;

        # Get the answer.
        $ans = $get_ans->($msg, $self->{tty}, $def);

        # Validate the answer.
        my $err = $req->error;
        while (!$req->callback($ans)) {
            print "$err: '$ans'\n";
            $ans = $get_ans->($msg, $self->{tty});
        }

    } elsif ($type eq 'info') {
        # Just print the message.
        print STDOUT $req->message, "\n";
    } elsif ($type eq 'error') {
        # Just print the message.
        print STDERR $req->message, "\n";
    } else {
        # This shouldn't happen.
        Carp::croak("Invalid request type '$type'");
    }

    # Save the answer.
    $req->value($ans);

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
