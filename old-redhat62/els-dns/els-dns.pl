#!/usr/bin/perl -w

use strict;
use lib '/usr/lib/perl5/site_perl';
use ConfigFiles;


my $verbose = 0;
my $hostname = '';
my @hostnumbers = ();
my %networks = ();
my $domainname = '';

my($sec,$min,$hour,$day,$month,$year) = localtime(time);
$year -= 100 if $year >= 100;


sub GetHostAndDomain ()
{
    chomp($hostname   = `hostname`);
    if ($hostname =~ /[^\.]+\.(.+)/) {
        $domainname = $1
    }
    print "Host $hostname\n" if $verbose;
    print "Host $domainname\n" if $verbose;
}


sub GetHostNumbers()
{
    my $interface;
    open IN, "/sbin/ifconfig|";
    while (defined($_ = <IN>)) {
	$interface = $1 if /^(\S+)/;
	if ( /inet addr:(\d+\.\d+\.\d+\.\d+)/ ) {
            next if $interface =~ /^lo/;
            next if $interface =~ /^ppp/;
            next if $interface =~ /^ippp/;
            print "$interface: $1\n" if $verbose;
            my $ip = $1;
            push @hostnumbers, $ip;
            # TODO
            # This code simply assumes that we are in a class C network
            # it changes 192.168.233.1 into the network part 192.168.233
            $ip =~ s/\.\d+$//;
            $networks{$ip} = 1;
	}
    }
    close IN;

    #print "All hosts: ", join(', ',@hostnumbers), "\n" if $verbose;
    #print "All nets: ", join(', ',sort keys %networks), "\n" if $verbose;

    loadfile '/etc/sysconfig/rc.sysadm';
    if ($_ = getopt('DNS_NETWORKS')) {
        s/"//g;
        s/^=//g;
        #print "Hosts: $_\n";
        push @hostnumbers, split / /, $_;
        s/.0 / /g;
        s/.0$//g;
        #print "Networks: $_\n";
        foreach (split / /, $_) {
            $networks{$_} = 1;
        }
    }

    print "All hosts: ", join(', ',@hostnumbers), "\n" if $verbose;
    print "All nets: ", join(', ',sort keys %networks), "\n" if $verbose;
}


sub MakeForward ()
{
    #
    # first create the definition file
    #
    open OUT, ">/var/named/forward.def";
    print OUT "#\n";
    print OUT "# Warning: don't edit this file manually. Instead use\n";
    print OUT "# sysadm -> Network -> TCPIP -> Hosts\n";
    print OUT "#\n";
    print OUT "zone \"$domainname\" IN {\n";
    print OUT "    type master;\n";
    print OUT "    notify no;\n";
    print OUT "    file \"forward.zone\";\n";
    print OUT "    check-names fail;\n";
    print OUT "    allow-update { none; };\n";
    print OUT "    allow-transfer { none; };\n";
    print OUT "};\n";


    #
    # then create the zone file
    #
    open OUT, '>/var/named/forward.zone';
    print OUT "; Warning: don't edit this file manually. Instead use\n";
    print OUT "; sysadm -> Network -> TCPIP -> Hosts\n\n";
    printf OUT "\$TTL 1d\n\n";
    printf OUT "%-20s IN SOA   %s\n", '@',  "$hostname. postmaster.$domainname. (";
    my $serial = sprintf "%02d%02d%02d%d", $year, $month, $day, $hour*3600+$min*60+$sec;
    printf OUT "%s %s ; Serial number\n", ' 'x29, $serial-0;
    print OUT ' 'x30, "12h    ; Refresh\n";
    print OUT ' 'x30, " 2h    ; Retry\n";
    print OUT ' 'x30, " 1w    ; Expire\n";
    print OUT ' 'x30, " 1d )  ; Minumum\n";
    
    printf OUT "%-20s IN NS    $hostname.\n", '';
    printf OUT "%-20s IN A     127.0.0.1\n", 'localhost';

    open HOSTS, '</etc/hosts';
    my $line;
    while (defined ($line = <HOSTS>)) {
	next unless $line =~ /^(\d+\.\d+\.\d+\.\d+)\s+(.+)$/;
        my $ip = $1;
        next if $ip eq '127.0.0.1';

        my $prev = '';
        my %names;
        foreach my $name (split /\s+/, $2) {
            $name =~ s/\.$domainname$//;
            if ($prev) {
                next if defined $names{$name};
                printf OUT "%-20s IN CNAME %s\n", $name, $prev;
                #printf OUT "%-20s IN A     %s\n", $name, $ip;
            } else {
                $prev = $name;
                printf OUT "%-20s IN A     %s\n", $name, $ip;
            }            
            $names{$name} = 1;
        }
    }
    close HOSTS;
}


sub MakeReverse()
{
    open REVERSE, ">/var/named/reverse.def";

    foreach my $net (keys %networks) {
        @_ = ();
        foreach (split /\./, $net) { unshift @_, $_ };
        my $rev = join('.', @_);
        print "Make reverse lookup table for network $net\n" if $verbose;

        #
        # first create the definition file
        #
        open OUT, ">/var/named/$net.def";
        print OUT "#\n";
        print OUT "# Warning: don't edit this file manually. Instead use\n";
        print OUT "# sysadm -> Network -> TCPIP -> Hosts\n";
        print OUT "#\n";
        print OUT "zone \"$rev.in-addr.arpa\" IN {\n";
        print OUT "    type master;\n";
        print OUT "    notify no;\n";
        print OUT "    file \"$net.zone\";\n";
        print OUT "    check-names fail;\n";
        print OUT "    allow-update { none; };\n";
        print OUT "    allow-transfer { none; };\n";
        print OUT "};\n";
        close OUT;
        print REVERSE "include \"/var/named/$net.def\";\n";

        open OUT, ">/var/named/$net.zone";
        print OUT "; Warning: don't edit this file manually. Instead use\n";
        print OUT "; sysadm -> Network -> TCPIP -> Hosts\n\n";
        printf OUT "\$TTL 1d\n\n";
        printf OUT "%-20s IN SOA   %s\n", '@',  "$hostname. postmaster.$domainname. (";
        my $serial = sprintf "%02d%02d%02d%d", $year, $month, $day, $hour*3600+$min*60+$sec;
        printf OUT "%s %s ; Serial number\n", ' 'x29, $serial-0;
        print OUT ' 'x30, "12h    ; Refresh\n";
        print OUT ' 'x30, " 2h    ; Retry\n";
        print OUT ' 'x30, " 1w    ; Expire\n";
        print OUT ' 'x30, " 1d )  ; Minumum\n";
        
        printf OUT "%-20s IN NS    $hostname.\n", '';

        open HOSTS, '</etc/hosts';
        my $line;
        while (defined($line = <HOSTS>)) {
            next unless $line =~ /^$net\.(\S+)\s+(\S+)/;
            #printf OUT "%-20s IN PTR %s\n", "$2.$1", $3;
            my $ip = $1;
            my $name = $2;
            unless ($name =~ /$domainname$/o) {
                $name = "$name.$domainname";
            }
            printf OUT "%-20s IN PTR   %s.\n", $ip, $name;
        }
        close HOSTS;

        close OUT;

    }
}


sub GetMainNameServer()
{
    my $dnsserver = '0.0.0.0';
    open IN, "</etc/sysconfig/rc.sysadm";
    while (defined($_ = <IN>)) {
	next unless /^DNS_SERVER\s*=\s*(["'])?(\d+\.\d+\.\d+\.\d+)(["'])?/;
	$dnsserver = $2;
        print "dnsserver is $2\n" if $verbose;
	last;
    }
    close IN;


    # ok, there was no entry, so try to read the previous nameserver
    # from /etc/resolv.conf
    if ($dnsserver eq '0.0.0.0' and -f '/etc/resolv.conf') {
	open IN, '</etc/resolv.conf';
	while (defined($_ = <IN>)) {		# while instead of if to use last
	    next unless /^nameserver\s+(\S+)/;
	    next if $1 eq '127.0.0.1';
	    next if $1 =~ /^192\.168/;
	    $dnsserver = $1;
	    loadfile '/etc/sysconfig/rc.sysadm';
	    setopt 'DNS_SERVER=', "\"$dnsserver\"";
            print "DNS_SERVER is $dnsserver\n" if $verbose;
	    writefile;
	}
	close IN;
    }

    # now make /etc/resolv.conf to point at localhost
    open OUT, '>/etc/resolv.conf';

    # Enter the nameserver as the local DNS. This will be used
    # for initial lookup, using the cache.
    # Only those entries not cached will be forwarded
    print OUT "# Set up by ELS DNS - do not alter!!\n";
    print OUT "nameserver $dnsserver\n";
    close OUT;


    # should I touch /etc/nsswitch.conf ?
    # no, the default from redhat is set up well

    
    # now enter the $dnsserver into the bind configuration file
    loadfile "/etc/named.conf", "modify forwarder";
    replace "#forwarders", "forwarders";
    if ($dnsserver ne "0.0.0.0") {
	replace "forwarders {.*}", "forwarders { $dnsserver; }";
    } else {
	replace 'forwarders {', '#forwarders {';
    }
    writefile;
    if (-f '/var/spool/postfix/etc/named.conf') {
        system('cp','-p','/etc/named.conf','/var/spool/postfix/etc/named.conf');
    }

}




GetHostAndDomain();
GetHostNumbers();

MakeForward();
MakeReverse();

system('/usr/bin/killall', '-HUP', 'named');
