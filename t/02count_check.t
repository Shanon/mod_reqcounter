
use strict;
use warnings;
use FindBin;

use Test::More tests => 4;

use IO::Socket::INET;
use Data::Dumper;

my $apache_home = "$FindBin::Bin/apache_home/";

my @hosts = qw/localhost.localdomain
               test1.localhost.localdomain
               test2.localhost.localdomain
               test3.localhost.localdomain
               dummy.localhost.localdomain
              /;
my %aplog;

diag("\nthis test takes few minutes.\nplease wait.\n");

ok(check_long_up(),    'checking count up');
ok(check_short_up(),   'checking short count up');
ok(check_short_down(), 'checking short count down');
ok(check_long_down(),  'checking count down');

sub check_short_up {
    my $time = time;
    my $count = 0;
    my $last_count = 0;
    while($time  + 10 > time) {
        my $data = get_contents( 'test.shortcount.localhost.localdomain' );
        $count ++;
        $last_count = $data->{rc_short};
    }
    if( $last_count != $count ) {
        diag("short count is wrong.\ndo count = $count : return count = $last_count");
        return 0;
    }
    return 1;
}

sub check_short_down {
    sleep(10);
    my $data = get_contents( 'test.shortcount.localhost.localdomain' );
    unless( $data->{rc_short} == 1 ) {
        diag("count down data is wrong.\n".Dumper($data));
        return 0;
    }
    return 1;
}

sub check_long_up {
    foreach my $host ( @hosts ) {
        $aplog{$host} = { pids => {},
                          count => 0,
                          last_times => []};
        while( scalar keys( %{$aplog{$host}->{pids}} ) < 5 ) {
            my $data = get_contents( $host );
            push( @{$aplog{$host}->{last_times}}, time);
            $aplog{$host}->{pids}->{$data->{parent_pid}} = 0
                unless( exists $aplog{$host}->{pids}->{$data->{parent_pid}} );
            $aplog{$host}->{pids}->{$data->{parent_pid}} ++;
            $aplog{$host}->{count} ++;
            $aplog{$host}->{last_long_count} = $data->{rc_long};
        }
    }
    my $flg = 1;
    foreach my $host ( keys( %aplog ) ) {
        $flg = 0
            if( $aplog{$host}->{last_long_count} != $aplog{$host}->{count} );
    }
    unless( $flg ) {
        diag("count up data is wrong.");
        foreach my $host (sort keys(%aplog)) {
            next if( $aplog{$host}->{count} == $aplog{$host}->{last_long_count} );
            Dumper(\$aplog{$host});
        }
    }
    return $flg;
}

sub check_long_down {
    my $old_data = $aplog{$hosts[0]};
    my %tcounts;
    foreach my $t (@{$old_data->{last_times}}) {
        $tcounts{$t} = 0
            unless( exists $tcounts{$t} );
        $tcounts{$t} ++;
    }
    my $ftime = time;
    my $data = get_contents($hosts[0]);
#    my $now_count = $data->{rc_long};
    my $max_tc = $old_data->{last_times}->[-1];

    my $flg = 0;
    while( $max_tc + 60 * 6 + 1 > time ) {
        if( $max_tc + 60 * 5 < time and $flg == 0) {
            my $a = get_contents( $hosts[0] );
            $flg = 1;
        }
        sleep(1);
    }
    my $rt = get_contents( $hosts[0] );
    unless( $ftime + 60 * 5 > time ? $rt->{rc_long} == 3 : $rt->{rc_long} == 2 ) {
        diag("count down data is wrong.\n".Dumper($rt));
        return 0;
    }
    return 1;
}

sub get_contents {
    my $host = shift;
    my $socket = IO::Socket::INET->new( PeerAddr => '127.0.0.1',
                                        PeerPort => $ENV{'OPEN_PORT'},
                                        Proto => 'tcp',
                                        keepalive => 0 );
    die "can not connect: $!"
        unless( $socket );
    print $socket "GET /test.cgi HTTP/1.1\n";
    print $socket "Host: $host\n";
    print $socket "\n";
    $socket->flush;

    my $head = '';
    my $length = 0;
    my $body = '';
    my $flg = 0;
    while( my $buf = <$socket> ) {
        $buf =~ s/\r//g;
        $buf =~ s/\n//g;
        chomp( $buf );

        if( $flg == 0 and length($buf) < 1 ) {
            $flg = 1;
            next;
        }
        
        next if( length( $body ) < 1 and $buf =~ /^e\d+$/ );
        unless( $flg ) {
            $head .= "$buf\n";
            ($length) = $buf =~ /^Content-Length: (\d+)/
                if( $buf =~ /^Content-Length/ );
        }
        else {
            $body .= "$buf\n";
            last if( length($body) > $length);
        }
    }
    $socket->close;
    my $data;
    $body =~ s/\$VAR1/\$data/g;
    eval "$body";
    return $data;
}
