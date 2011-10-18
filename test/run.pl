#!/usr/bin/perl

use strict;
use warnings;
use FindBin;

my $base = "/tmp/mod_reqcounter";
main();

sub main {
    my $cmd = $ARGV[0];
    die "Usage: $0 [start|restart|graceful|graceful-stop|stop]\n"
        unless( defined $cmd );

    unless( -d $base ) {
        init();
    }
    if( $cmd eq 'start' ) {
        start();
    }
    elsif( $cmd eq 'stop' ) {
        stop();
    }
    elsif( $cmd eq 'restart') {
        stop();
        sleep(1);
        start();
    }
}

sub init {
    system("mkdir -p $base/run");
    system("mkdir -p $base/logs");
    system("mkdir -p $base/conf");
    system("mkdir -p $base/modules");
    system("cp -p /etc/httpd/modules/* $base/modules");
    system("cp /etc/httpd/conf/magic $base/conf/");
}

sub start {
    system("cp $FindBin::Bin/../.libs/mod_reqcounter.so $base/modules");
    system("/usr/sbin/httpd -f $FindBin::Bin/httpd.conf");
}

sub stop {
    system("kill `cat $base/run/httpd.pid`");
}
