use ExtUtils::MakeMaker;

# $Id: Makefile.PL,v 1.2 2002/06/01 21:29:05 david Exp $

use strict;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    'NAME'		=> 'App::Info',
    'VERSION_FROM'	=> 'lib/App/Info.pm', # finds $VERSION
    'PREREQ_PM'		=> {File::Spec => 0,        # Should subclass any just fine.
                            Test::Simple => 0.17 }, # Need Test::More
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/App/Info.pm', # retrieve abstract from module
       AUTHOR     => 'David Wheeler <david@wheeler.net>') : ()),
);
