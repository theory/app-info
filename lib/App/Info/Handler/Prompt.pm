package App::Info::Handler::Prompt;

# $Id: Prompt.pm,v 1.1 2002/06/12 04:16:57 david Exp $

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
    my $self = $pkg->SUPER::new;
    $self->{tty} = -t STDIN && ( -t STDOUT || !( -f STDOUT || -c STDOUT ) );
    # We're done!
    return $self;
}

my $get_ans = sub {
    my ($prompt, $def, $tty) = @_;
    # Print the message.
    local $| = 1;
    local $\;
    print $prompt;

    # Collect the answer.
    my $ans;
    if ($tty) {
        $ans = <STDIN>;
        if( defined $ans ) {
            chomp $ans;
        } else { # user hit ctrl-D
            print "\n";
        }
    } else {
        print "$def\n";
    }
    return $ans;
};

sub handler {
    my ($self, $req) = @_;
    my $type = $req->type;
    if ($type eq 'unknown') {
    } elsif ($type eq 'confirm') {
    } else {
        # Decline to handle other types of requests.
        return;
    }

    # Assemble the prompt message.
    my $msg = $req->message;
    my $prompt = $req->prompt;
    if ($msg) {
        $msg .= $prompt ? "\n$prompt" : '';
    } else {
        $msg = $prompt ? $prompt : '';
    }
    $msg .= $showdef;

    # Get the answer.
    my $ans = $get_ans->($msg, $def, $self->{tty});

    # Validate the answer.
    while (!$req->callback($ans)) {
        print "Invalid value: '$ans'\n";
        $ans = $get_ans->($msg, $def, $self->{tty});
    }

    # Save the answer.
    $req->value($ans);

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
