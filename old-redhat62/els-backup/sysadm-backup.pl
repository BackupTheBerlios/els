#!/usr/bin/perl -w

use File::Find;
use Getopt::Long;


#use strict;


#
# Constants
#
$SETDIR    = '/etc/backup.d';			# directory that hold backup sets
$RCSYSADM  = '/etc/sysconfig/rc.sysadm';	# system configuration file
$FILELIST  = '/var/tmp/sysadm.filelist';	# list of all files in one backup set
$BACKUPLOG = '/var/tmp/sysadm.backuplog';	# file to keep the output of this script




#
# Command-line options
#
$OptDebug       = 0;
$OptVerbose     = 0;
$OptNoWrite     = 0;
$OptIncremental = 0;
$OptRewindB     = 0;
$OptRewindA     = 0;
$OptEject       = 0;
$OptMail        = 0;
$OptTemp	= 0;
$OptOverwrite	= 0;
$OptNoVerify    = 0;



#
# Variables
#
$SetName     = '';				# name of current set
@SetInclude  = ();				# directories to include
@SetExclude  = ();				# shell globs of files to exclude
$ExcludeExpr = sub {};				# regexp created on the fly
$BackupAbort = 0;				# set to 1 on hard errors
$BackupWarn  = 0;				# set to 1 on warnings
$BackupCount = 0;				# files in the backup
$BackupSize  = 0;				# size in bytes
$Subject     = 'sysadm-backup run';             # subject to be used for e-mail



#
# Default values if entries in /etc/sysconfig/rc.sysadm do not exist
#
$Def_TAPE_STATUS = 'mt status';			# Command to get status of tape
$Def_TAPE_REWIND = 'mt rewind';			# Command to rewind tape
$Def_TAPE_EJECT  = 'mt offline';		# Command to eject tape
$Def_TAPE_SETUP  = '';				# Command to setup tape



#
# Options for TAR
#
#$Def_BACKUPPROG = '/bin/tar';
#$Def_BACKUPOPTS = 'cT - '		# accept files from stdin
#		. '--record-size 1024 '	# tape block size
#		. '--blocking-factor 20 '	# tape block count
#		. '--no-recursion '	# we specify the files, not tar
#		. '--atime-preserve '	# preserve access times
#		. '-f '			# write files out to device
#		;
#$Def_VERIFYOPTS = 'd '			# accept files from stdin
#		. '--record-size 1024 '	# tape block size
#		. '--blocking-factor 20 '	# tape block count
#		. '--atime-preserve '	# preserve access times
#		. '-f '			# write files out to device
#		;
#$Def_RESTOREOPTS ...


#
# Options for AFIO
#
# +++ make block size and block count configurable
#
$Def_BACKUPPROG = '/usr/bin/afio';
$Def_BACKUPOPTS = '-o '			# output option
		. '-b 8192 '		# tape block size
		. '-c 16 '		# tape block count
		. '-a '			# preserve access time
	#	. '-f '			# crude double-buffering via subprocess
	#	. '-z '			# print execution statistics
		. '-Z '			# compress files
		. '-G 1 '		# compression factor
		. '-T 64k ';		# compress file > 64k
		;
$Def_VERIFYOPTS = '-r '			# output option
		. '-b 8192 '		# tape block size
		. '-c 16 '		# tape block count
		. '-a '			# preserve access time
		;
$Def_RESTOREOPTS = '-i '		# input option
		. '-b 8192 '		# tape block size
		. '-c 16 '		# tape block count
		. '-Z '			# compress files
		;



############################################################################
#
#  General utility functions
#
############################################################################


#
# Log
#	Emits the current time followed by all arguments. If the output
#	goes to mail, then the current time is preceeded
#
sub Log {
    my ($sec,$min,$hour) = localtime time;
    if ($OptMail) {
	printf "%02d:%02d:%02d %s\n", $hour, $min, $sec, join(" ",@_);
    } else {
	print join(" ", @_), "\n";
    }
}



#
# Stop
#	Use instead of die to abort execution, but present a nice log entry.
#	It exits with an errorlevel of 1, which can be tested in the calling
#	script.
#
sub Stop {
    my $text = shift || "Backup stopped.";
    Log $text;
    exit 1;
}



#
# ProcessConfigLine
#
#	Called by ReadConfiguration and InitSet if a line like
#
#	    TAPE_STATUS="mt status"
#
#	is found in either the system config file or in a per-backup-set
#	config file.
#
sub ProcessConfigLine ($$)
{
   my ($varname,$param) = @_;
   print "ProcessConfigLine('$varname','$param')\n" if $OptDebug;

   $TAPE_STATUS = $param if $varname eq 'TAPE_STATUS';
   #+++ make regexp to get File number configurable
   $TAPE_REWIND = $param if $varname eq 'TAPE_REWIND';
   #+++ TAPE_FORWARD
   #+++ TAPE_BACK
   $TAPE_EJECT  = $param if $varname eq 'TAPE_EJECT';
   $TAPE_SETUP  = $param if $varname eq 'TAPE_SETUP';
   $BACKUPPROG  = $param if $varname eq 'BACKUPPROG';
   $BACKUPOPTS  = $param if $varname eq 'BACKUPOPTS';
   $VERIFYOPTS  = $param if $varname eq 'VERIFYOPTS';
   $RESTOREOPTS = $param if $varname eq 'RESTOREOPTS';
}



#
# ReadConfiguration ($fname)
#
#	This subroutine first sets the config variables back to defaults.
#	Then it read the specified file. So everything in the specified
#	file overwrites the defaults.
#
sub ReadConfiguration ($) {

    my ($fname) = @_;
    print "ReadConfiguration('$fname')\n" if $OptDebug;

    # first set defaults

    $TAPE_STATUS = $Def_TAPE_STATUS;
    $TAPE_REWIND = $Def_TAPE_REWIND;
    $TAPE_EJECT  = $Def_TAPE_EJECT;
    $TAPE_SETUP  = $Def_TAPE_SETUP;
    $BACKUPPROG  = $Def_BACKUPPROG;
    $BACKUPOPTS  = $Def_BACKUPOPTS;
    $VERIFYOPTS  = $Def_VERIFYOPTS;
    $RESTOREOPTS = $Def_RESTOREOPTS;

 
    # and now allow the defaults to be overwritten by the
    # real config file
    
    open FILE, "<$fname"
      or Stop "Could not open configuration file $fname.";
    
    while (defined( $_ = <FILE>)) {
	next unless /^([A-Z_]+)\s*=\s*([\"\']?)(.*)\2$/;
	ProcessConfigLine $1, $3;

	#print "1: >$1<  3: >$3<\n" if $OptDebug
    }
    close FILE;
}



#
# ExecScript ($pattern)
#	This executes all scripts that match the pattern, e.g.
#	ExecScript('/etc/backup.d/*.before').
#
sub ExecScript ($) {
   
    my($script) = @_;
    print "ExecScript('$script')\n" if $OptDebug;

    my $fname = "/etc/backup.d/$script";
    foreach (glob $fname) {
	if (-x $_) {
	    Log "Executing script", $_ if $OptVerbose;
	    system($_);
	}
    }
}




############################################################################
#
#  Backup low level functions
#
############################################################################


#
# CreateExcludeExpr
#	@SetExclude contains an array with strings of shell patterns
#	we should not backup.
#
#	This subroutine takes this array, converts the shell
#	patterns into regular expressions. This exists as a string
#	and get's converted via eval into a variable that contains
#	an unnamed subroutine. The eval compiles this unnamend
#	subroutine, so all the code uses this compiled code. This
#	approach of using a closure makes all file tests much faster.
#
#	The $ExcludeExpr is then later used in DescendDirs, which in
#	turn calls DescendFiles for actual file name tests.
#
sub CreateExcludeExpr {
    my $dir = shift;
    print "CreateExcludeExpr()\n" if $OptDebug && $OptVerbose;
    
    my $expr = "sub {\n";
    $expr  .= " return";
    my $add = 0;
    foreach (@SetExclude) {
	$expr .= " ||" if $add;
	# this changes shell glob like '*' into perl regexps like  '.*'
	my $glob = $_;
	$glob =~ s:([\.\+\$\@\-]):\\$1:g;
	$glob =~ s:\*:\.\*:g;
	$glob =~ s:\?:\.:g;
	$expr .= " m:^$glob\$:\n";
	$add = 1;
    }
    $expr .= "}\n";
    print $expr if $OptDebug;
    
    $ExcludeExpr = eval $expr;
}



#
# AddExcludes ($fname)
#	Load files/directories to be excluded from the backup from the
#	file $fname. Adds all excludes to @SetExclude.
#
sub AddExcludes ($) {
    my $fname = shift;
    print "LoadExcludes('$fname')\n" if $OptDebug;
    
    open EXCLUDE, $fname
      or return;		# silently ignore error
    while (defined( $_ = <EXCLUDE>)) {
	chomp;
	next if /^\s*\#/;       			 # comments
	next if /^\s*$/;	# empty lines
	next if /^[A-Z_]+\s*=\s*([\"\']?).*\1$/; # defines VAR="xyz"
	push @SetExclude, $_;
    }
    close EXCLUDE;
}
		 


#
# DescendFiles ($filename, &match-subroutine, &nomatch-subroutine)
#	this subroutine checks if the current filename is on the same
#	filesystem and does not matches the precomputed exclusion-expression.
#	And if the file is really a directory, then every directory will be
#	visited recursively, too.
#
sub DescendFiles
{
    my($fname, $submatch, $subnomatch) = @_;
    print "DescendFiles('$fname',$submatch,$subnomatch)\n" if $OptDebug > 1;
    
    
    # same file system?
    
    my($dev) = lstat($fname)
      or return;
    
    
    # Execute workhorse subroutine
    
    if (&$ExcludeExpr) {
	#print "found $fname\n";
	&$subnomatch;
    } else {
	#print "ok    $fname\n";
	&$submatch;
    }

    if ($BackupAbort) {
	print "BackupAbort in DescendFiles\n" if $OptDebug;
	return;
    }
    
    
    # check device number
    
    if ($dev != $DirDev) {
	#print "$fname: different fs\n";
	return;
    }
    
    
    # visit directories, too
    
    if (-d _) {
	#my $path = $_;
	opendir DIR, $fname;
	my(@files) = readdir DIR;
	closedir DIR;
	foreach (@files) {
	    next if $_ eq '.';
	    next if $_ eq '..';
	    $_ = "$fname/$_";
	    $_ =~ s:^//:/:;
	    DescendFiles($_, $submatch, $subnomatch)
	}
    }
}



#
# DescendDirs ($directory, $match-subroutine, $nomatch-subroutine)
#	Saves the filesystem device number of $directory and calls
#	DescendFiles.
#
sub DescendDirs ($&&)
{
    my($dir, $submatch, $subnomatch) = @_;
    print "DescendDirs('$dir',$submatch,$subnomatch)\n" if $OptDebug;
    
    ($DirDev) = lstat($dir);
    DescendFiles $dir, $submatch, $subnomatch;
}




#
# InitSet ($setname)
#	Initialize backup set $fname to be backed up or simply to
#	print the file list
#
sub InitSet ($) {
    my $fname = shift;
    print "InitSet('$fname')\n" if $OptDebug;
    
    # if $fname is just the name of the set, then make proper path
    
    $fname = "/etc/backup.d/$fname" unless $fname =~ m:/:;
    $fname .= ".set" unless $fname =~ m:\.set$:;
    $SetName = $1 if $fname =~ m:([^\/]+).set$:;
    
    # Initialize variables
    
    @SetInclude = ();
    @SetExclude = ();
    ReadConfiguration $RCSYSADM;
    
    # create a new exclude list
    
    foreach (glob "$SETDIR/*.exclude") {
	AddExcludes $_;
    }
    
    # read directory and, special exclusions and special variables
    
    open SET, "<$fname"
      or Stop "Could not open backup set description $fname";

    while (defined( $_ = <SET>)) {
	chomp;
	next if /^\s*\#/;	# comments
        next if /^\s*$/;	# empty lines
	
	# per-backup-set variables
	if ( /^([A-Z_]+)\s*=\s*([\"\']?)(.*)\2$/ ) {
	    ProcessConfigLine $1, $3;
	} elsif ( /^\-(.*)/ ) {
	    # per-backup-set excludes
	    push @SetExclude, $1;
	} else {
	    # directories
	    push @SetInclude, $_;
	}
    }
    close SET;
    
    CreateExcludeExpr;
}



#
# CreateFileList
#
sub CreateFileList {
    my($setname) = @_;
    print "CreateFileList('$setname')\n" if $OptDebug;
    
    # get reference date for incremental backups
    my $incrementaldate = 0;
    if ($OptIncremental) {
	$incrementaldate = (lstat("/var/tmp/last-backup-mark.$setname"))[9] || 0;
	#print "Incremental reference: $incrementaldate\n" if $OptDebug;
	
	open TOUCH, ">/var/tmp/last-backup-mark.$setname";
	print TOUCH "This file saves the time of the previous backup in it's modification date\n";
	close TOUCH;
    }
    
    open FILELIST, ">$FILELIST";
    $BackupCount = 0;
    $BackupSize  = 0;
    $BackupAbort = 0;
    $BackupWarn  = 0;
    foreach (@SetInclude) {
	DescendDirs $_, sub {
	    # check if we need to backup this file:
	    if ($OptIncremental && ((lstat(_))[9] < $incrementaldate))  { 
		print "Backup aborted because of $_",(lstat(_))[9],"\n" if $OptDebug;
		$BackupAbort = 1;
		return;
	    };

	    #change abs path into relative:
	    if (  /\/(.+)/ ) { $_ = $1; }

	    $BackupCount++;
	    $BackupSize += -s _;
	    print FILELIST "$_\n";
	}, sub {
	};
	last if $BackupAbort;
    }
    close FILELIST;
}



#
# BackupPart1
#	Part one of the Backup writes the small header onto the tape
#
sub BackupPart1 ($) {
    my($setname) = @_;
    print "BackupPart1('$setname')\n" if $OptDebug;
    
    my $device = $OptNoWrite ? '/dev/null' : '/dev/tape';
    open TAPE, ">$device"
      or Stop "Could not access tape: $!";
    
    my ($sec,$min,$hour, $day,$month,$year) = localtime time;
    printf TAPE "DATE=\"%04d-%02d-%02d %02d:%02d:%02d\"\n",
    $year+1900, $month+1, $day, $hour, $min, $sec;
    printf TAPE "TAPEFILES=\"%d\"\n", $BackupCount;
    printf TAPE "TAPESIZE=\"%d\"\n",  $BackupSize / 1024;
    print TAPE "INCLUDE=\"";
    my $space = 0;
    foreach (@SetInclude) {
	print TAPE " " if $space;
	$space = 1;
	print TAPE $_;
    }
    print TAPE "\"\n";
  close TAPE;
}


#
# BackupPart2
#	Part 2 stores the list of files onto the tape
#
sub BackupPart2
{
    print "BackupPart2\n" if $OptDebug;
    
    my $device = $OptNoWrite ? '/dev/null' : '/dev/tape';
    chdir '/';
    open PROG, "|$BACKUPPROG $BACKUPOPTS $device"
      or Stop "Could not start backup program $BACKUPPROG.";
    
    $FILELIST =~ /^\/(.*)/;
    print PROG "$1\n";
    
    close PROG;
    # 512 is error level 2, which is only a warning
    if (($? != 0) && ($? != 512)) {
	print "Backup aborted because of error level $?\n" if $OptDebug;
	$BackupAbort = 1;
    }
}



#
# BackupPart3
#	Part 3 stores all the files of the file list onto the tape
#
sub BackupPart3 ($)
{
    my($setname) = @_;
    print "BackupPart3('$setname')\n" if $OptDebug;
    
    #InitSet ($setname); 	# +++ ???
    my $StartTime = time;
    
    # open pipe to backup program
    chdir '/';
    open FILES, "<$FILELIST"
      or Stop "Could not open file list: $!";
    
    my $device = $OptNoWrite ? '/dev/null' : '/dev/tape';
    if ($OptVerbose) {
	Log "Backup command is";
	Log "$BACKUPPROG $BACKUPOPTS $device";
    }
    open PROG, "|$BACKUPPROG $BACKUPOPTS $device"
      or Stop "Could not start backup program $BACKUPPROG.";
    
    # +++ simply cat the file list into afio?
    
    # backup everything by printing the file list
    while (defined ($_ = <FILES>)) {
	unless (print PROG $_) {
	    print "Backup aborted because of afio didn't accept files anymore\n" if $OptDebug;
	    $BackupAbort = 1;
	    last;
	}
    }
    
    close FILES;
    
    close PROG;
    # 512 is error level 2, which is only a warning
    if ($? == 512) {
	$BackupWarn = 1;
    }
    elsif ($?) {
	print "Backup aborted because error level $? from afio\n" if $OptDebug;
	$BackupAbort = 1;
    }
    print "BackupAbort in BackupPart3 3 ($?)\n" if $OptDebug && $BackupAbort;
    
    if ($BackupWarn) {
	Log "Common warnings:";
	Log "No such file or directory: deleted by user/process while backup";
    }
    
    unless ($BackupAbort) {
	my $seconds = (time - $StartTime);
	$seconds ||= 1;
	$BackupSize = $BackupSize / 1024;
	
	Log sprintf "  No of files:  %d", $BackupCount;
	Log sprintf "  Set size:     %d KB", $BackupSize;
	Log sprintf "  Duration:     %.1f min", ($seconds / 60)+0.1;
	Log sprintf "  Backup speed: %.1f KB/s", $BackupSize / $seconds;
    }
}
		 
		 
		 
sub Verify {
    # +++
}
		 


#
# WaitForTape ($command)
#	Wait until the tape is ready. Normally used with mt status, but
#	can be used to rewind the tape, too.
#
sub WaitForTape
{
    # +++ execute this stuff if we don't work to a file

    my $cmd = shift || $TAPE_STATUS;
    print "WaitForTape('$cmd')\n" if $OptDebug;

    #
    # Original idea was to use "mt -f /dev/nst0 bsfm 1". However, this
    # turned out to NOT work on Red Hat 5.2 ...  strange, isn't it?
    #
    #my $cmdexec = $cmd;
    #$cmdexec =~ s/^mt ([^\-])/mt \-f $TAPE $1/;

    my $count = 360;
    while ($count--) {
        my $result = `$cmd` || "";			# was cmdexec
	last if $? == 512;
	print "Cmd: $cmd\nError code: $?\nResult: $result\n" if $OptVerbose && $OptDebug;
	if ($cmd =~ /status/) {
	    return $result if $? == 0 && $result =~ /ONLINE/;
	} else {
	    return 1 if $? == 0 && $result !~ /error/;
	}
	sleep 1;
	next;
    }
    return 0 unless $cmd eq $TAPE_STATUS;
    Stop "Tape not ready (\"$cmd\" didn't work).";
}



sub RewindTape
{
    print "RewindTape\n" if $OptDebug;

    Log 'Rewinding tape ...' if $OptVerbose;
    WaitForTape $TAPE_REWIND;
}



sub EjectTape
{
    print "EjectTape\n" if $OptDebug;

    Log 'Ejecting tape ...';
    system $TAPE_EJECT;
}





############################################################################
#
#  High level
#
############################################################################


#
# BackupSet
#	Back up ONE specific backup set, without rewinding/ejecting etc
#	Used mostly internal, but can be handy to be executed by command
#	line
#
sub BackupSet ($$)
{
    my($optname,$setname) = @_;
    print "BackupSet('$optname','$setname')\n" if $OptDebug;
    
    Log "Processing backup set '$setname'";
    ExecScript "$setname*.before";
    InitSet($setname);
    CreateFileList($setname);
    BackupPart1($setname)	unless $BackupAbort;
    BackupPart2			unless $BackupAbort;
    BackupPart3($setname)	unless $BackupAbort;
    Verify			unless $BackupAbort;
    ExecScript "$setname*.after";
    Log "Done" if $OptVerbose;
}



#
# BackupAll
#	make a backup of all backup sets mentioned in $SETDIR
#
sub BackupAll ($$)
{
    my($optname,$setname) = @_;
    
    Log "Starting backup";
    RewindTape if $OptRewindB;
    ExecScript 'backup*.before';
    
    foreach (glob "$SETDIR/*.set") {
	/([^\/]+)\.set$/;
	BackupSet('', $1);
	last if $BackupAbort;
    }
    
    Log "Backup aborted\n" if $BackupAbort;
    ExecScript 'backup*.after';
    RewindTape if $OptRewindA;
    EjectTape if $OptEject;
    unlink $FILELIST;
    Log "Finished backup";
}



#
# Backup
#	Back up a list of backup sets, one after the other
#
sub Backup
{
    my($optname,$optdummy) = @_;
    
    Log "Starting backup";
    $Subject = 'backup';
    RewindTape if $OptRewindB;
    ExecScript 'backup*.before';
    
    foreach (@ARGV) {
	next if $_ eq '--';	# avoid bug in Getopt::Long of RH5.2
	s/\"//g;
	BackupSet 'backup', $_;
    }

    Log "Backup aborted\n" if $BackupAbort;
    ExecScript 'backup*.after';
    RewindTape if $OptRewindA;
    EjectTape if $OptEject;
    Log "Finished backup";
}



#
# Restore
#
sub Restore ($$)
{
    my($optname, $optvar) = @_;

    Log "Starting restore";

    # Find Current Position And Rewind If Necessary To Start Of A Set
    $_ = WaitForTape or Stop "Can't access tape.";
    /File number=(-?\d+)/i;
    my $filenum = $1 || 0;
    my $filecnt = $1 % 3;

    /Block number=(\d)/i;
    my $blocknum = $1;

    print "File number is $filenum, mod 3 is $filecnt, block number = $blocknum\n" if $OptDebug;

    if ($filenum == -1) {
	WaitForTape "mt rewind";
	WaitForTape "mt fsf 2";
    }

    if ($blocknum != 0) {
	WaitForTape "mt bsfm 1";
    }

    if ($filecnt == 0) {
	WaitForTape "mt fsf 2";
    } elsif ($filecnt == 1) {
	WaitForTape "mt fsf";
    }

    # process options

    if ($OptTemp) {
	chdir '/var/tmp'
    } else {
	chdir '/';
    }
    my $cmd = "$BACKUPPROG $RESTOREOPTS";
    $cmd = "$cmd -n" unless $OptOverwrite;
    $cmd = "$cmd -v" if $OptVerbose;
    $cmd = "$cmd -w $FILELIST /dev/tape";

    # execute restore

    $Subject = 'restore';
    Log $cmd if $OptVerbose;
    system $cmd;
    EjectTape if $OptEject;
    Log "Finished restore";
}



#
# ShowFiles($setname)
#
sub ShowFiles ($$)
{
    my($optname,$setname) = @_;
    print "ShowFiles('$optname','$setname')\n" if $OptDebug;
    
    InitSet ($setname);
    
    print "Files in backup set '$SetName':\n\n" if $OptVerbose;
    
    $BackupCount = 0;
    $BackupSize  = 0;
    foreach (@SetInclude) {
	#print "SetInclude is $_\n";
	DescendDirs $_, sub {
	    #change abs path into relative:
	    if (  /\/(.+)/ ) { $_ = $1; }

	    $BackupCount++;
	    $BackupSize += -s _;
	    print "$_\n";
	}, sub {
	};
	last if $BackupAbort;
    }
    # +++ when is $? set?
    if ($?) {
	print "Backup aborted because of error level $?\n";
	$BackupAbort = 1;
    }
    #print "BackupAbort in ShowFiles ($?)\n" if $OptDebug && $BackupAbort;
    
    return unless $OptVerbose;
    print "\n";
    printf "No of files: %d\n", $BackupCount;
    printf "Total size:  %d KB\n", $BackupSize / 1024;
}



#
# ShowExcluded($setname)
#
sub ShowExcluded ($$)
{
    my($optname,$setname) = @_;
    print "ShowExcluded('$optname','$setname')\n" if $OptDebug;
    
    InitSet ($setname);
    
    print "Files excluded from backup set '$SetName':\n\n" if $OptVerbose;
    
    $BackupCount = 0;
    $BackupSize  = 0;
    foreach (@SetInclude) {
	#print "SetInclude is $_\n";
	DescendDirs $_, sub {
	}, sub {
	    $BackupCount++;
	    $BackupSize += -s _;
	    print "$_\n";
	};
	last if $BackupAbort;
    }
    # +++ when is $? set?
    if ($?) {
	print "Backup aborted because of error level $?\n";
	$BackupAbort = 1;
    }
    #print "BackupAbort in ShowFiles ($?)\n" if $OptDebug && $BackupAbort;
    
    return unless $OptVerbose;
    print "\n";
    printf "No of files: %d\n", $BackupCount;
    printf "Total size:  %d KB\n", $BackupSize / 1024;
}



#
# Show all sets in user-readable format
#
sub ShowSets ($$)
{
    my($optname,$setname) = @_;
    
    print "The following backup sets do exist:\n\n";
    
    if ($OptVerbose) {
	
	printf "%-30s %12s %12s\n", "Backup set", "Files", "Size in KB";
	print "-" x 56, "\n";
	my $TotalCount = 0;
	my $TotalSize  = 0;
	foreach (glob "$SETDIR/*.set") {
	    next unless /([^\/]+)\.set$/;
	    my $setname = $1;
	    InitSet ($setname);
	    $BackupCount = 0;
	    $BackupSize  = 0;
	    foreach (@SetInclude) {
		#print "SetInclude is $_\n";
		DescendDirs $_, sub {
		    $BackupCount++;
		    $BackupSize += -s _;
		    1;
		}, sub {
		};
		last if $BackupAbort;
		$TotalCount += $BackupCount;
		$TotalSize  += $BackupSize;
		printf "%-30s %12d %12d\n", $setname, $BackupCount, $BackupSize / 1024;
	    }
	}
	print "-" x 56, "\n";
	printf "%-30s %12d %12d\n", "Total", $TotalCount, $TotalSize / 1024;
	
	print "\nPlease use  sysadm -> Backup -> Sets -> Files  if you want a\n";
	print "detailed list of all files in one set.\n";
	
    } else {
	
	foreach (glob "$SETDIR/*.set") {
	    next unless /([^\/]+)\.set$/;
	    print "$1\n";
	}

    }
}



#
# GetPosition
#	Get's the header of the tape and displays it in a form that
#	is shell-sourcable. Here is the output:
#
#	DATE		date of backup
#	TAPEDESC	(might be missing) user description
#	TAPEFILES	number of files in backup
#	DESC		formatted description
#
#	After the header has been read, the tape is position back onto
#	the first file of the backup set.
#
sub GetPosition ($$)
{
    my($optname, $optvar) = @_;
    
    # Find Current Position And Rewind If Necessary To Start Of A Set
    $_ = WaitForTape or Stop "Can't access tape.";
    /File number=(-?\d+)/i;
    my $filenum = $1 || 0;
    my $filecnt = $1 % 3;

    /Block number=(\d)/i;
    my $blocknum = $1;

    #print "File Number Is $filenum, Mod 3 Is $filecnt, Block Number = $blocknum\n";
   
    if ($filenum < 3 && $filenum != 0) {
	# Somewhere In The First Three Files
	WaitForTape "mt rewind" or Stop "Can't rewind tape\n";
    } elsif ($filecnt) {
	# in file 1,2 or 4,5 or 6,7 ...
	$filecnt++;
	WaitForTape "mt bsfm $filecnt" or Stop "Can't rewind tape\n";
    } elsif ($blocknum) {
	# in file 0,3,6 ..., but somewhere in the middle of the blocks
	WaitForTape "mt bsfm 1" or Stop "Can't rewind tape\n";
    }

    print "---------- reading dir:\n" if $OptDebug;
    system "mt status" if $OptDebug;

    open FILE, "</dev/tape" or Stop "Can't read tape\n";
    my $check = 1;
    while (defined($_ = <FILE>)) {
	if ($check) {
	    Stop "Tape not used for backups (or tape empty)" unless /^DATE/;
	}
	print $_;
	$check = 0;
    }
    close FILE;
    print "BACKUPSET=", int($filenum/3), "\n";
}


#
# GetFilelist
#
sub GetFilelist
{
    my($optname, $optvar) = @_;
    
    # Find Current Position And Rewind If Necessary To Start Of A Set
    $_ = WaitForTape or Stop "Can't access tape.";
    /File number=(-?\d+)/i;
    my $filenum = $1 || 0;
    my $filecnt = $1 % 3;

    /Block number=(\d)/i;
    my $blocknum = $1;

    print "File number is $filenum, mod 3 is $filecnt, block number = $blocknum\n";

    if ($filenum == -1) {
	WaitForTape "mt rewind";
	WaitForTape "mt fsf";
    }

    if ($blocknum != 0) {
	WaitForTape "bsfm 1";
    }

    if ($filecnt == 0) {
	WaitForTape "mt fsf";
    } elsif ($filecnt == 2) {
	WaitForTape "mt bsfm 2";
    }

    unlink $FILELIST;
    chdir '/';

    print "$BACKUPPROG $RESTOREOPTS /dev/tape\n" if $OptDebug;
    system "$BACKUPPROG $RESTOREOPTS /dev/tape";
    Stop "Could not load file list. $? $!" if $? != 0;
}



#
# PrevBackupSet
#	Skips to the previous backup set
#
sub PrevTapeSet ($$)
{
    my($optname,$optvar) = @_;

    # Find current position and rewind if necessary to start of a set
    $_ = WaitForTape or Stop "Can't access tape.";
    /File number=(-?\d+)/i;
    my $filenum = $1 || 0;
    my $filecnt = $1 % 3;

    #print "File number is $filenum, mod 3 is $filecnt\n";

    if ($filenum < 3 && $filenum != -1) {
	Stop "Already at start of tape."
    }
    elsif ($filenum < 6) {
	#print "mt rewind\n";
	WaitForTape "mt rewind";
    } else {
	$filecnt += 3+1;
	#print "mt bsfm $filecnt\n";
	WaitForTape "mt bsfm $filecnt";
    }
}


#
# NextTapeSet
#	Skips to the next backup set
#
sub NextTapeSet ($$)
{
    my($optname,$optvar) = @_;

    # Find current position and rewind if necessary to start of a set
    $_ = WaitForTape or Stop "Can't access tape.";
    /File number=(-?\d+)/i;
    my $filenum = $1 || 0;
    my $filecnt = $1 % 3;

    #print "File number is $filenum, mod 3 is $filecnt\n";

    if ($filenum == -1) {
	WaitForTape "mt rewind";
    } else {
	$filecnt = 3-$filecnt;
	#print "mt fsf $filecnt\n";
	WaitForTape "mt fsf $filecnt" or Stop "End of tape reached.";
    }
}


#
# Display all sets in a format suitable for dialog(1) (listbox)
#
sub ListSets ($$)
{
    my($optname,$optvar) = @_;
    
    foreach (glob "$SETDIR/*.set") {
	next unless /([^\/]+)\.set$/;
	print "\"$1\" \"\" ";
    }
}


#
# Display all sets in a format suitable for dialog(1) (checkboxes)
#
sub SelectSets ($$)
{
    my($optname,$optvar) = @_;
    
    my $line  = '';
    my $count = 0;
    
    foreach (glob "$SETDIR/*.set") {
	next unless /([^\/]+)\.set$/;
	$line .= "\"$1\" \"\" \"on\" ";
	$count ++;
    }
    print $count+7, " 40 $count $line";
}



# +++
sub MailOutput
{
    print "MailOutput\n" if $OptDebug;

    *OLDOUT = *OLDOUT; open OLDOUT, '>&STDOUT';
    *OLDERR = *OLDERR; open OLDERR, '>&STDERR';
    open STDOUT, '>/var/tmp/sysadm.backuplog';
    open STDERR, '>&STDOUT';			# from Perl Cookbook, Recipe 7.20

    select((select(STDOUT), $_ = 1)[0]);	# from Perl Cookbook, Recipe 7.12

    $OptMail = 1;

    #my $pid;
    #return if $pid = open STDOUT, ">$BACKUPLOG"
    #die "cannot fork: $!" unless defined $pid;		# die, not Stop!
    #while (<STDIN>) { print }
    #exit;
}

END {
  close STDOUT; open STDOUT, '>&OLDOUT';
  close STDERR; open STDERR, '>&OLDERR';       	# from Perl Cookbook, Recipe 7.20

  system "mail operator -s 'sysadm: result of $Subject' <$BACKUPLOG" if $OptMail;
}


sub Test
{
    InitSet 'usr';
    CreateFileList 'usr';
}




###########################################################################
#
#  Main program
#
###########################################################################


#
# Make no distinction between STDOUT and STDERR and unbuffer them
#
open STDERR, '>&STDOUT';
select(STDERR); $| = 1;
select(STDOUT); $| = 1;



ReadConfiguration $RCSYSADM;


#Getopt::Long::Configure('bundling');
GetOptions("debug", 		\$OptDebug,
	   "verbose", 		\$OptVerbose,
	   "eject",		\$OptEject,
	   "incremental",	\$OptIncremental,
	   "noverify",		\$OptNoVerify,
	   "nowrite",		\$OptNoWrite,
	   "overwrite",		\$OptOverwrite,
	   "rewindafter",	\$OptRewindA,
	   "rewindbefore",	\$OptRewindB,
	   "temp",		\$OptTemp,

	   "mail",		\&MailOutput,
	   "backupset=s",	\&BackupSet,	# somewhat internal
	   "backup",		\&Backup,
	   "all",		\&BackupAll,
	   "getposition",	\&GetPosition,
	   "getfilelist",       \&GetFilelist,
	   "restore",           \&Restore,
	   "prevtapeset",       \&PrevTapeSet,
	   "nexttapeset",       \&NextTapeSet,
	   "sets",		\&ShowSets,
           "files=s",		\&ShowFiles,
	   "excluded=s",        \&ShowExcluded,
	   "listsets",		\&ListSets,
	   "selectsets",	\&SelectSets,
	   "test",		\&Test,		# internal :-)
	   );
