#!/usr/bin/perl -w

use lib '/usr/lib/perl5/site_perl';
use ConfigFiles;


#
# Activate sample configuration files
#
ActivateSample('/etc/backup.d/default.exclude.sample');
ActivateSample('/etc/rc.d/rc.scsi.sample');



#
# Create initial backup set definitions for mounted file systems. FS must
# - be not mounted read-only
# - of type ext2
#

sub MakeInitialSets
{
    open MOUNTS, "</proc/mounts";
    while (defined ($_ = <MOUNTS>)) {
        my($dev, $dir, $fs, $flags) = split / /, $_;
        next if $flags eq "ro";
        next if $fs ne "ext2";

	# transform "/usr/samba/app" into "app":
        $dir =~ /([^\/]*$)/;
	$name = $1 || 'root';

	# create backup set definition file, if it doesn't exist yet
        next if -f "/etc/backup.d/$name.set";
	open SET, ">/etc/backup.d/$name.set";

	# Note: this should be the same text as in /usr/lib/sysadm/backupsets.mnu
	print SET <<"EOF";
#
# /etc/backup.d/$name.set
#
# Backup set definition file, used by sysadm -> backup
#
#
# Format
# ------
# This file may contain many line. The starting character of each line
# does tells what this line is for:
#
#   #	          comment
#   /usr/samba    slashes define paths to be backed up
#   -*.bak        minus denote files that should not be backed up
#

EOF
	print SET "$dir\n";
	close SET;
        #print "$name   $dir\n";
    }
    close MOUNTS;
}


MakeInitialSets;
