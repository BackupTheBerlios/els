#!/usr/bin/perl -w

use lib '/usr/lib/perl5/site_perl';
use ConfigFiles;


#
# Set defaults
#
loadfile '/etc/sysconfig/rc.sysadm';
append 'SMB_NETBIOSNAME="LINUX"' unless searchline 'SMB_NETBIOSNAME';
append 'SMB_DOMAINLOGON="yes"'   unless searchline 'SMB_DOMAINLOGON';
append 'SMB_PRINTERDRIVERS="no"' unless searchline 'SMB_PRINTERDRIVERS';
append 'SMB_TRANSLATION=""'      unless searchline 'SMB_TRANSLATION';
append 'SMB_CODEPAGE="437"'      unless searchline 'SMB_CODEPAGE';
append 'SMB_DEBUGLEVEL="1"'      unless searchline 'SMB_DEBUGLEVEL';
append 'SMB_NULLPASSWORDS="no"'  unless searchline 'SMB_NULLPASSWORDS';
deleteline 'SMB_WINSSUPPORT';	# this is now forced to YES
writefile;


#
# Activate sample config files
#
ActivateSample('/etc/samba.d/app.smb');
ActivateSample('/etc/samba.d/arc.smb');
ActivateSample('/etc/samba.d/cdrom.smb');
ActivateSample('/etc/samba.d/dat.smb');
ActivateSample('/etc/samba.d/global.smb');
ActivateSample('/etc/samba.d/homes.smb');
ActivateSample('/etc/samba.d/linux.smb');
ActivateSample('/etc/samba.d/zip.smb');
ActivateSample('/etc/samba.d/netlogon.smb');
ActivateSample('/usr/samba/netlogon/logon.bat');


#
# Create the /etc/smbpasswd file
# 
ReadPasswd();
ReadSamba();
WriteSamba();
chmod 0600, "/etc/smbpasswd";
chmod 0644, "/etc/passwd";


#
# Make all the links in /usr/samba/users
#
MakeLinks();





##########################################################################
## Subroutines
##########################################################################
exit;


# $users{$name}[0] password		from /etc/passwd (ReadPassWd)
# $users{$name}[1] user id		from /etc/passwd
# $users{$name}[2] primary group id	from /etc/passwd
# $users{$name}[3] full name		from /etc/passwd
# $users{$name}[4] home path		from /etc/passwd
# $users{$name}[5] shell		from /etc/passwd
# $users{$name}[6] hash 1		from /etc/smbpasswd (ReadSamba)
# $users{$name}[7] hash 2		from /etc/smbpasswd


#
# ReadSamba
#	reads /etc/smbpasswd into the %users hash
#
sub ReadSamba ()
{
    my $name;

    $FILE = "/etc/smbpasswd";
    open FILE or return;
    while (<FILE>) {
	chomp;
	@_ = split ":", $_;
	$name = shift;
	next unless $users{$name};
	$users{$name}[6] = $_[1];
	$users{$name}[7] = $_[2];
    }
    close FILE;
}


#
# WriteSamba
#	write data from the %users into /etc/smbpasswd
#
sub WriteSamba ()
{
    # make a backup copy ...
    system "cp --preserve /etc/smbpasswd /etc/smbpasswd-" if -f "/etc/smbpasswd";

    # ... and write the data
    $FILE = ">/etc/smbpasswd";
    open FILE or die "Can't open $FILE";

    foreach $_ ( sort keys %users ) {
	$users{$_}[6] = 'NO PASSWORDXXXXXXXXXXXXXXXXXXXXX' unless defined $users{$_}[6];
	$users{$_}[7] = 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX' unless defined $users{$_}[7];
	print FILE "$_:$users{$_}[1]:$users{$_}[6]:$users{$_}[7]:$users{$_}[3]:$users{$_}[4]:$users{$_}[5]\n"
	    if $users{$_}[1] && ($users{$_}[1] >= 100 || $users{$_}[1] == 0); 
    }
    close FILE;
}



#
# MakeLinks
#	Creates a symlink in /usr/samba/dat/users for each user
#
sub MakeLinks()
{
    # make a link for every user
    for $_ ( sort keys %users ) {
	$id       = $users{$_}[1];
	next if ($id < 100) and ($_ ne "root");
	next if $_ =~ /^[A-Z]/;
	symlink($users{$_}[4], "/usr/samba/dat/users/$_") unless (-l "/usr/samba/dat/users/$_");
    }

    # remove files that don't belong to valid user entries
    my $basename;
    for $_ ( glob ('/usr/samba/dat/users/*')) {
	$basename = $_;
	$basename =~ s:.*/([^/]*):$1:g;
	system "rm -rf $_" unless ($users{$basename});
    }
}


