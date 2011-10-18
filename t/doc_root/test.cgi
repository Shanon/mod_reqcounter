#!/usr/bin/perl

use strict;
use Data::Dumper;

my $body = Dumper({parent_pid => getppid(),
                   pwn_pid => $$,
                   rc_long => $ENV{'RC_LONG'},
                   rc_short => $ENV{'RC_SHORT'},
                   rc_persent => $ENV{'RC_PERSENT'},
                   hostname => $ENV{'HTTP_HOST'}});

print "Content-type: text/plain\n";
print "Content-Length: ".length($body)."\n";
print "\n";
print "$body\n";
