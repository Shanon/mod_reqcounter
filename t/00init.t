
use strict;
use warnings;
use FindBin;

use Test::More tests => 4;

my $apache_home = "$FindBin::Bin/apache_home/";

# prepare apache home
{
    ok(cleanup(),     "clean up apache home");
    ok(prepare_dir(), "initialize apache home");
    ok(gen_config(),  "generate test httpd.conf");
    ok(copy_files(),  "copy necessary files");
}

sub copy_files {
    if( system("cp -p $ENV{APACHE_HOME}/modules/* $apache_home/modules/") ) {
        diag("can not copy $ENV{APACHE_HOME}/modules/* to $apache_home/modules/ : $!");
        return 0;
    }
    if( system("cp -p $FindBin::Bin/../.libs/mod_reqcounter.so $apache_home/modules/") ) {
        diag("can not copy $FindBin::Bin/../.libs/mod_reqcounter.so to $apache_home/modules/ : $!");
        return 0;
    }
    return 1;
}

sub gen_config {
    {
        my $tmpl = replase_template("$FindBin::Bin/httpd.conf.tmpl",
                                    {server_root => $apache_home,
                                     document_root => "$FindBin::Bin/doc_root",
                                     openport => $ENV{'OPEN_PORT'} || 10080 } )
            or return 0;
        if( open( CONF, ">$apache_home/conf/httpd.conf" ) ) {
            print CONF $tmpl;
            close( CONF );
        }
        else {
            diag("can not open $apache_home/conf/httpd.conf : $!");
            return 0;
        }
    }
    {
        my $tmpl = replase_template("$FindBin::Bin/magic.tmpl",
                                    { server_root => $apache_home,
                                      document_root => "$FindBin::Bin/doc_root",
                                      openport => $ENV{'OPEN_PORT'} || 10080  })
            or return 0;
        if( open( CONF, ">$apache_home/conf/magic" ) ) {
            print CONF $tmpl;
            close( CONF );
        }
        else {
            diag("can not open $apache_home/conf/magic : $!");
            return 0;
        }
    }
    return 1;
}

sub prepare_dir {
    unless( -d $ENV{APACHE_HOME} ) {
        diag("can not find apache home direcotyr ex) /etc/httpd");
        diag("please set apache home in Makefile");
        return 0;
    }
    foreach my $dir (qw/run logs conf modules html rc_shm/) {
        if( system("mkdir -p $apache_home/$dir") ) {
            diag("can not create dir : $apache_home/$dir");
            return 0;
        }
    }
    return 1;
}

sub cleanup {
    if( -d $apache_home ) {
        if( system("rm -rf $apache_home") ) {
            diag("can not remove $apache_home");
            return 0;
        }
    }
    return 1;
}

sub replase_template {
    my $file = shift;
    my $data = shift;

    if( open( IN, "$file" ) ) {
        my $body = join('', <IN>);
        close( IN );
        $body =~ s/\[\% (\w+) \%\]/$data->{$1}/g;
        return $body;
    }
    else {
        diag("can not open $file : $!");
        return 0;
    }
}

1;
