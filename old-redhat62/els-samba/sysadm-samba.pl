#!/usr/bin/perl -w

use Getopt::Long;

use lib '/usr/lib/perl5/site_perl';
use ConfigFiles;


#
# Loads /etc/sysconfig/rc.sysadm into $ENV{}
#
sub LoadEnv ()
{
    open F, "/etc/sysconfig/rc.sysadm" || return;
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
    opendir DIR, "/etc/samba.d";
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

   open FILE, "/etc/samba.d/$share.smb" || return;
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

        #18938  DENY_NONE  RDWR       EXCLUSIVE+BATCH  /usr/samba/app/Somas/m_1/lagaart.dbf   Wed Jul 19 10:19:30 2000
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
	open FILE, "/etc/samba.d/$share.smb";
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
# data from any file in /etc/samba.d into shell environment variables.
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
# Creates a file in /etc/samba.d/ with all the value of the current
# shell environment variables
#
sub SetShare ()
{
    loadfile "/etc/samba.d/$SetShare.smb", "";

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
# This creates from environment variables and the files in /etc/samba.d
# an /etc/smb.conf that can be read and understood by samba
#
sub UpdateConfig ()
{
    LoadEnv();
    $ENV{SMB_NETBIOSNAME}    ||= 'LINUX';
    $ENV{SMB_DOMAINLOGON}    ||= 'yes';
    $ENV{SMB_PRINTERDRIVERS} ||= 'no';
    $ENV{SMB_TRANSLATION}    ||= '';
    $ENV{SMB_CODEPAGE}       ||= '850';
    $ENV{SMB_DEBUGLEVEL}     ||= '0';
    $ENV{SMB_NULLPASSWORDS}  ||= 'no';

    open FILE, ">/etc/smb.conf";

    #
    # Section 1: Intro
    #
    print FILE ";;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;\n",
               ";;  This is an automatically created file, do not change.      ;;\n",
               ";;  Please use sysadm -> Network -> Samba instead, thank you.  ;;\n",
               ";;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;\n",
               "[global]\n",
               "\n",
               "\n";

    #
    # Section 3: global parameters
    #
    my(@file) = LoadFile "/etc/samba.d/global.smb";
    @file = map { if ($_ =~ /^#/) { } else { $_ } } @file;
    print FILE ";;\n",
               ";;  Global SAMBA parameters:\n",
               ";;\n",
               @file,
	       "\n",
               "\n";

    #
    # Section 4: settable parameters
    #
    print FILE ";;\n",
               ";;  Parameters from sysadm -> Network -> Samba -> Setup:\n",
               ";;\n",
               "netbios name=$ENV{SMB_NETBIOSNAME}\n",
               "client code page=$ENV{SMB_CODEPAGE}\n",
               "debug level=$ENV{SMB_DEBUGLEVEL}\n",
               "null passwords=$ENV{SMB_NULLPASSWORDS}\n",
               "\n",
               "\n";
    print FILE "character set=$ENV{SMB_TRANSLATION}\n" if $ENV{SMB_TRANSLATION} ne "";
    if ($ENV{SMB_DOMAINLOGON} eq "yes") {
	print FILE ";;\n",
                   ";;  Domain logon support:\n",
                   ";;\n",
                   "domain logons=yes\n",
                   "logon script=logon.bat\n",
                   "domain master=yes\n",
                   "preferred master=yes\n",
                   "os level=65\n",
                   "\n",
                   "\n";

    }    
    if ($ENV{SMB_PRINTERDRIVERS} eq "yes") {
	print FILE
               ";;\n",
               ";;  Support for automatic printer driver installation:\n",
               ";;\n",
               "printer driver file=/usr/samba/printer/printers.def\n",
               "printer driver location=\\\\\\\\%h\\\\PRINTER\$\n",
               "[printer$]\n",
               "path=/usr/samba/printer\n",
               "guest ok=yes\n",
               "writable=no\n",
               "browseable=yes\n",
	       "\n",
	       "\n";
    }


    #
    # Section 6: the shares
    #
    print FILE ";;;;;;;;;;;;;;;;;;;;;;;;;;;\n",
               ";;  And now the shares:  ;;\n",
               ";;;;;;;;;;;;;;;;;;;;;;;;;;;\n",
	       "\n";

    @_ = GetShareList();
    foreach $share (sort @_) {
	@file = LoadFile "/etc/samba.d/$share.smb";
	print FILE "[$share]\n",
	      @file,
              "\n";
    }
    close FILE;
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
		    "updateconfig" => \$UpdateConfig,
		    "changepw" => \$ChangePW,
		    "checkpws" => \$CheckPWs,
		  );

GetOptions(%OptionsControl);

ShowUsers if $ShowUsers;		# formatted for humans
ShowShares if $ShowShares;		# formatted for humans
ListShares if $ListShares;		# formatted for computers

GetShare if $GetShare;
SetShare if $SetShare;

UpdateConfig if $UpdateConfig;
ChangePW if $ChangePW;
CheckPWs if $CheckPWs;

ShowUsage();
exit 1;
