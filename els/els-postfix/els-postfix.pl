#!/usr/bin/perl -w

use strict;
use lib '/usr/lib/perl5/site_perl';
use ConfigFiles;

my $verbose = 0;


sub UpdateDatabases ()
{
    foreach ( 'canonical',
              'insiders_only',
              'protected_destinations',
              'relocated',
              'transport' ) {
        my $file = "/etc/postfix/$_";
        next unless -f $file;
        system('/usr/sbin/postmap', $_);
    }
}



sub AddAliases ()
{
    loadfile '/etc/postfix/aliases.users';

    foreach my $user ( sort keys %users ) {
        next if search "\\s$user\$";

	my $id = $users{$user}[1];
	next if $id < 500;

	my $realname = lc $users{$user}[3];
        $realname =~ s/�/ae/g;
        $realname =~ s/�/oe/g;
        $realname =~ s/�/ue/g;
        $realname =~ s/�/Ae/g;
        $realname =~ s/�/Oe/g;
        $realname =~ s/�/Ue/g;
        $realname =~ s/�/ss/g;
        unless ($realname =~ /^(\S+)\s+(\S+)/) {
            print "Ignored realname \"$realname\" of user \"$user\" while making aliases\n" if $verbose;
            next;
        }

        append sprintf("%-39s %s", "$1.$2:", $user);
        append sprintf("%-39s %s", substr($1,0,1) . ".$2:", $user);
    }
    writefile;
}


sub CreateUnixgroupAliases ()
{
    open FILE, ">/etc/postfix/aliases.unixgroups";

    foreach my $name ( sort keys %groups ) {
	next if $users{$name};
	my $id    = $groups{$name}[1];
	next if $id < 100;

        printf FILE "%-20s %s\n", "$name:", $groups{$name}[2];
    }

    close FILE;
}


sub AddCanonicals ()
{
    loadfile '/etc/postfix/canonical';
    foreach my $user ( sort keys %users ) {
        next if search "^$user\\s";

	my $id = $users{$user}[1];
	next if $id < 500;

	my $realname = lc $users{$user}[3];
        $realname =~ s/�/ae/g;
        $realname =~ s/�/oe/g;
        $realname =~ s/�/ue/g;
        $realname =~ s/�/Ae/g;
        $realname =~ s/�/Oe/g;
        $realname =~ s/�/Ue/g;
        $realname =~ s/�/ss/g;
        next unless $realname =~ /^(\S+)\s+(\S+)/;

        append sprintf("%-39s %s.%s", $user, substr($1,0,1), $2);
    }
    writefile;
}


ReadPasswd();
ReadGroup();

chdir '/etc/postfix';
AddAliases();
CreateUnixgroupAliases();
system('/usr/bin/newaliases');

AddCanonicals();
UpdateDatabases();
