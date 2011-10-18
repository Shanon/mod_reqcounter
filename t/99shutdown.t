
use strict;
use warnings;
use FindBin;

use Test::More tests => 2;

my $apache_home = "$FindBin::Bin/apache_home/";

my $apache_bin;

ok(find_apache(), 'find apache program');
ok(stop_apache(), 'shutdown apache web server');

sub find_apache {
    $apache_bin = `which httpd 2>/dev/null`;
    return 1 if( length( $apache_bin ) );

    $apache_bin = `which apache 2>/dev/null`;
    return 1 if( length( $apache_bin ) );

    foreach my $path (qw!/usr/sbin/httpd /usr/sbin/apache!) {
        if( -x $path ) {
            $apache_bin = $path;
            return 1;
        }
    }
    diag("can not find apache program");
    return 0;
}

sub stop_apache {
    system("$apache_bin -f $apache_home/conf/httpd.conf -k stop");
    sleep( 5 );
    my $ps_rt = `ps ax | grep $apache_bin | grep $apache_home | grep -v grep`;
    if( length( $ps_rt ) ) {
        diag("can not shutdown apache web server");
        diag("please shutdown manualy\n$ps_rt");
        return 0;
    }
    return 1;
}
