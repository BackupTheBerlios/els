#!/usr/bin/perl -w

use Getopt::Long;

use lib '/usr/lib/perl5/site_perl';
use ConfigFiles;


#
# Loads /etc/els.conf into $ENV{}
#
sub LoadEnv ()
{
    open F, "/etc/els.conf" || return;
    while (defined($_ = <F>)) {
	next if /^$/;
	next if /^#/;
	/^(.*?)=\"?(.*?)\"?$/;
	$ENV{$1} = $2;
    }
    close F;
}


#
# Loads any file and returns all of it's lines in @_
#
sub LoadFile ($)
{
    my($fn) = shift;
    @res = ();
    open F, $fn || return @res;
    @res = <F>;
    close F;
    return @res;
}



#
# Makes list of all shares. Returns this as @_
#
sub GetShareList ()
{
    my(@shares);
    opendir DIR, "/etc/samba";
    while (defined ($_ = readdir DIR)) {
	next unless /\.smb$/;
	next if /^global\.smb$/;
	$_ =~ /(.*)\.smb$/;
	push @shares, $1;
    }
    closedir DIR;
    return(@shares);
}


#
# Get the important data of one share.
# Returns this in several global variables.
#
sub GetShareData ($)
{
   $share = shift;

   $comment    = undef;
   $path       = undef;
   $writelist  = undef;
   $browseable = undef;
   $readonly   = undef;
   $available  = undef;
   $guestok    = undef;
   $volume     = undef;
   $printable  = undef;

   open FILE, "/etc/samba/$share.smb" || return;
   $share = uc $share;
   while (<FILE>) {
       chomp;
       next if /^$/;                # ignore empty lines
       next if /^[;#]/;                # ignore paths
       /^\s*(.*?)\s*=\s*(.*)$/;
       $_ = lc $1;
       if ($_ eq "comment")          { $comment = $2; }
       elsif ($_ eq "path")          { $path = $2; }
       elsif ($_ eq "write list")    { $writelist = $2; }
       elsif ($_ eq "browseable")    { $browseable = $2; }
       elsif ($_ eq "read only")     { $readonly = $2; }
       elsif ($_ eq "guest ok")      { $guestok = $2; }
       elsif ($_ eq "volume")        { $volume = $2; } 
       elsif ($_ eq "available")     { $available = $2; } 
       elsif ($_ eq "printable")     { $printable = $2; }
   }
   close FILE;
}


#
# SHOWUSERS
#	Displays all users. The format is for humans.
#
sub ShowUsers ()
{
    my (%SHARE, %USERS, %MACHINE, %FILES);

    open FILE, "smbstatus|";
    while (defined($_ = <FILE>)) {

        #app          schirrmacher users    18938   mnz67    (192.168.236.73) Wed Jul 19 06:23:39 2000
        if ($_ =~ /^(\S+)\s+(\S+)\s+\S+\s+(\d+)\s+(\w+)/i) {
            #print "share $1  user $2  pid $3   machine $4\n";
            if (defined $USERS{$3}) {
                next unless $USERS{$3} eq 'root';
            }
            $SHARE{$3} = $1;
            $USERS{$3} = $2;
            $MACHINE{$3} = $4;
        }

        #18938  DENY_NONE  RDWR       EXCLUSIVE+BATCH  /var/samba/app/Somas/m_1/lagaart.dbf   Wed Jul 19 10:19:30 2000
        if ($_ =~ /^(\d+)\s+\S+\s+\S+\s+\S+\s+(\S+)/) {
             #print "pid $1  file $2\n";
             #printf "%-20s %s\n",  $USERS{$1}, $2;
             push @{$FILES{$2}}, $1;
        }

    }
    close FILE;

    foreach $file (sort keys %FILES) {
        foreach (sort @{$FILES{$file}}) {
           #print "  $USERS{$_} on $MACHINE{$_}\n";
           printf "%-12s %-8s %s\n", $USERS{$_}, $MACHINE{$_}, $file;
        }
    }

    exit;
}


#
# Display share information in user format
#
sub ShowShares ()
{
    @_ = GetShareList();
    foreach $_ (sort @_) {
        $share = uc $_;
	GetShareData($_);

	$comment = "Printer" if $printable;
	printf "%-16s %s\n", $share, $comment;
	print "  Available      $available\n" if $available;
	print "  Volume label   $volume\n" if $volume;
	print "  Server path    $path\n" if $path;
	print "  Browseable     $browseable\n" if $browseable;
	print "  Guest ok       $guestok\n" if $guestok;
	print "  Read only      $readonly\n" if $readonly && !$printable;
	print "  Write list     $writelist\n" if $writelist;
	print "\n";
    }
    exit 0;
}


#
# List all shares for use with dialog --menu
#
sub ListShares ()
{
    @_ = GetShareList();
    foreach $share (sort @_) {

	$comment   = undef;
	$printable = undef;
	open FILE, "/etc/samba/$share.smb";
	while (<FILE>) {
	    $comment = $1 if /^\s*comment\s*=\s*(.*)/;
	    $printable = 1 if /^\s*printable/;
	}
	close FILE;

	unless ($comment) {
	    if ($printable) {
		$comment = uc($share) . " printer";
	    } else {
		$comment = uc($share) . " share";
	    }
	}
	print "\"$share\" \"$comment\" ";
    }
    exit 0;
}

#
# Get's the data of a share and writes out a list of commands that
# can be sourced into a shell. This way, we can convert important
# data from any file in /etc/samba into shell environment variables.
#
sub GetShare ()
{
    GetShareData($GetShare);
    $comment    ||= "";
    $path       ||= "";
    $writelist  ||= "";
    $browseable ||= "yes";
    $readonly   ||= "no";
    $available  ||= "yes";
    $guestok    ||= "no";
    $volume     ||= "";
    $printable  ||= "";

    print "export SMB_SHARE=\"$share\"\n";
    print "export SMB_COMMENT=\"$comment\"\n";
    print "export SMB_PATH=\"$path\"\n";
    print "export SMB_WRITELIST=\"$writelist\"\n";
    print "export SMB_BROWSEABLE=\"$browseable\"\n";
    print "export SMB_READONLY=\"$readonly\"\n";
    print "export SMB_AVAILABLE=\"$available\"\n";
    print "export SMB_GUESTOK=\"$guestok\"\n";
    print "export SMB_VOLUME=\"$volume\"\n";
    print "export SMB_PRINTABLE=\"$printable\"\n";

    exit 0;
}


#
# Creates a file in /etc/samba/ with all the value of the current
# shell environment variables
#
sub SetShare ()
{
    loadfile "/etc/samba/$SetShare.smb", "";

    deleteline "^volume";
    deleteline "^browseable";
    deleteline "^available";
    deleteline "^guest ok";
    deleteline "^read only";
    deleteline "^write list";

    setopt "comment=", "$ENV{SMB_COMMENT}";
    setopt "available=", "no" if $ENV{SMB_AVAILABLE} eq "no";
    setopt "path=", "$ENV{SMB_PATH}";
    setopt "volume=", "$ENV{SMB_VOLUME}" if $ENV{SMB_VOLUME};
    setopt "browseable=", "no" if $ENV{SMB_BROWSEABLE} eq "no";
    setopt "guest ok=", "yes" if $ENV{SMB_GUESTOK} eq "yes";
    setopt "read only=", "yes" if $ENV{SMB_READONLY} eq "yes";
    setopt "write list=", "$ENV{SMB_WRITELIST}" if $ENV{SMB_WRITELIST};

    writefile;

    exit 0;
}


#
# This is a little password change dialog that will be executed by
# samba whenever a user changes his password from the commandline.
#
sub ChangePW()
{
    my($name, $pw);
    print "username: ";
    chomp($name = <>);
    print "new password: ";
    chomp($pw = <>);

    # call all changer programs
    opendir DIR, '/usr/lib/sysadm';
    while (defined($_ = readdir DIR)) {
	next unless /^pwchange\./;
	system("/usr/lib/sysadm/$_", $name, $pw);
    }

    # fine, that's all
    print "changed\n";

    exit 0;
}


sub CheckPWs()
{
    open FILE, '/etc/smbpasswd' or exit 1;
    while (defined($_ = <FILE>)) {
	next unless /(^.+):\d+:NO PASSWORD/;
	print "Invoke sysadm -> Users -> Modify -> Password for these users:\n\n" unless $head;
	$head = 1;
	print "  $1\n";
    }
    print "\nOnly after you re-assigned a password to them they can use your\nfile server from Windows 95.\n";
    exit 0;
}


#
# Will be executed if you forget the "exit 0" at the end of a
# subroutine or if the user supplied a wrong argument
#
sub ShowUsage ()
{
    print "Please invoke with the proper options ...\n";
    exit 1;
}


%OptionsControl = (
		    # for "printer.mnu":
		    "users" => \$ShowUsers,
		    "shares" => \$ShowShares,
		    "listshares" => \$ListShares,
		    "getshare:s" => \$GetShare,
		    "setshare:s" => \$SetShare,
		    "changepw" => \$ChangePW,
		    "checkpws" => \$CheckPWs,
		  );

GetOptions(%OptionsControl);

ShowUsers if $ShowUsers;		# formatted for humans
ShowShares if $ShowShares;		# formatted for humans
ListShares if $ListShares;		# formatted for computers

GetShare if $GetShare;
SetShare if $SetShare;

ChangePW if $ChangePW;
CheckPWs if $CheckPWs;

ShowUsage();
exit 1;
