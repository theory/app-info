package App::Info::Handler;

# $Id: Handler.pm,v 1.6 2002/06/15 00:49:55 david Exp $

=head1 NAME

App::Info::Handler - App::Info event handler base class

=head1 SYNOPSIS

  use App::Info::Category::FooApp;
  use App::Info::Handler;

  my $app = App::Info::Category::FooApp->new(on_info => ['default']);

=head1 DESCRIPTION

This class defines the interface for subclasses that wish to handle events
triggered by App::Info concrete subclasses. The different types of events
triggered by App::Info can all be handled by App::Info::Handler (indeed, by
default they're all handled by a single App::Info::Handler object), and
App::Info::Handler subclasses may be designed to handle whatever events they
wish.

If you're interested in using an App::Info event handler, this is probably not
the class you should look at, since all it does is define a simple handler
that does nothing with an event. Look to the L<App::Info::Handler
subclasses|"SEE ALSO"> included in this distribution to do more interesting
things with App::Info events.

If, on the other hand, you're interested in implementing your own event
handlers, read on!

=cut

use strict;
use vars qw($VERSION);
$VERSION = '0.20';

my %handlers;

=head1 INTERFACE

This section documents the public interface of App::Info.

=head2 Class Method

=head3 register_handler

  App::Info::Handler->register_handler($key => $code_ref);

This class method may be used by App::Info::Handler subclasses to register
themselves with App::Info::Handler. Multiple registrations are supported. The
idea is that a subclass can define different functionality by specifying
different strings that represent different modes of constructing an
App::Info::Handler subclass object. The keys should be unique across
App::Info::Handler subclasses so that many subclasses can be loaded and used
separately. If the C<$key> is already registered, C<register_handler()> will
throw an exception. The values are code references that, when executed, return
the appropriate App::Info::Handler subclass object.

For example, say we're creating a handler subclass FooHandler. It has two
modes, a default "foo" mode and an advanced "bar" mode. To allow both to be
constructed by stringified shortcuts, the FooHandler class implementation
might start like this:

  package FooHandler;

  use strict;
  use App::Info::Handler;
  use vars qw(@ISA);
  @ISA = qw(App::Info::Handler);

  App::Info::Handler->register_handler('foo' => sub { __PACKAGE__->new } );
  App::Info::Handler->register_handler('bar' =>
                                       sub { __PACKAGE__->new('bar') } );

These strings can then be used by clients as shortcuts to have App::Info
objects automatically create and use handlers for certain events. For example,
if a client wanted to use a "bar" event handler for its info events, it might
do this:

  use App::Info::Category::FooApp;
  use FooHandler;

  my $app = App::Info::Category::FooApp->new(on_info => ['bar']);

=cut

sub register_handler {
    my ($pkg, $key, $code) = @_;
    Carp::croak("Handler '$key' already exists")
      if $handlers{$key};
    $handlers{$key} = $code;
}

# Register ourself.
__PACKAGE__->register_handler('default', sub { __PACKAGE__->new } );

##############################################################################

=head2 Constructor

=head3 new

  my $handler = App::Info::Handler->new;
  $handler =  App::Info::Handler->new( key => $key);

Constructs an App::Info::Handler object and returns it. If the key parameter
is provided and has been registered by an App::Info::Handler subclass via the
C<register_handler()> class method, then the relevant code reference will be
executed and the resulting App::Info::Handler subclass object returned. This
approach provides a handy shortcut for having C<new()> behave as an abstract
factory method, returning an object of the subclass appropriate to the key
parameter.

=cut

sub new {
    my ($pkg, %p) = @_;
    my $class = ref $pkg || $pkg;
    $p{key} ||= 'default';
    if ($class eq __PACKAGE__ && $p{key} ne 'default') {
        # We were called directly! Handle it.
        Carp::croak("No such handler '$p{key}'") unless $handlers{$p{key}};
        return $handlers{$p{key}}->();
    } else {
        # A subclass called us -- just instantiate and return.
        return bless \%p, $class;
    }
}

=head2 Instance Method

=head3 handler

  $handler->handler($req);

App::Info::Handler defines a single instance method that must be defined by
its subclasses, C<handler()>. This is the method that will be executed by an
event triggered by an App::Info concrete subclass. It takes as its single
argument an App::Info::Request object, and returns a true value if it has
handled the event request. Returning a false value declines the request, and
App::Info will then move on to the next handler in the chain.

The C<handler()> method implemented in App::Info::Handler itself does nothing
more than return a true value. It thus acts as a very simple default event
handler. See the App::Info::Handler subclasses for more interesting handling
of events, or create youre own!

=cut

sub handler { 1 }

1;
__END__

=head1 SUBCLASSING

I hatched the idea of the App::Info event model with its subclassable handlers
as a way of separating the aggregation of application metadata from writing a
user interface for handling certain conditions. I felt it a better idea to
allow people to create their own user interfaces, and instead to provide only
a few examples. The App::Info::Handler class defines the API interface for
handling these conditions, which App::Info refers to as "events".

There are various types of events defined by App::Info ("info", "error",
"uknown", and "confirm"), but the App::Info::Handler interface is designed to
be flexible enough to handle any and all of them. If you're interested in
creating your own App::Info event handler, this is the place to learn how.

=head2 The Interface

To create an App::Info event handler, all one need do is subclass
App::Info::Handler and then implement the C<new()> constructor and the
C<handler()> method. The C<new()> constructor can do anything you like, and
take any arguments you like. However, I do recommend that the first thing
you do in your implementation is to call the super constructor:

  sub new {
      my $pkg = shift;
      my $self = $pkg->SUPER::new(@_);
      # ... other stuff.
      return $self;
  }

Although the default C<new()> constructor currently doesn't do much, that may
change in the future, so this call will keep you covered. Then simply process
whatever arguments you've defined for your class and return the new object.

Next, I recommend that you take advantage of the C<register_handler()> method
to create some shortcuts for creating handlers of your class. The code for
this is covered in the L<register_handler|"register_handler"> section, but
I'll provide a more detailed example here.

=head1 BUGS

Feel free to drop me an email if you discover any bugs. Patches welcome.

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
