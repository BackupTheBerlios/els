#!/usr/bin/perl -w

use Getopt::Long;

use lib '/usr/lib/perl5/site_perl';
use ConfigFiles;

use strict 'var';





###########################################################################
#
# This is actually the "beef": all these routines can be called directly
# via proper command lines. /usr/lib/sysadm/users.mnu do this heavily!
#
###########################################################################


#
# SHOWUSERS
#	Displays all users. The format is for humans.
#
sub ShowUsers ()
{
    my($id, $user, $realname, $groups);

format USERS_TOP =
 Id Login name   Real name              Member of groups ...
------------------------------------------------------------------------
.
format USERS =
@>> @<<<<<<<<<<< ^<<<<<<<<<<<<<<<<<<<<< ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$id, $user,      $realname,             $groups,
                 ^<<<<<<<<<<<<<<<<<<<<< ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<~
                 $realname,             $groups
                 ^<<<<<<<<<<<<<<<<<<<<< ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<~
                 $realname,             $groups
                 ^<<<<<<<<<<<<<<<<<<<<< ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<~
                 $realname,             $groups
                 ^<<<<<<<<<<<<<<<<<<<<< ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<~
                 $realname,             $groups
                 ^<<<<<<<<<<<<<<<<<<<<< ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<~
                 $realname,             $groups
                 ^<<<<<<<<<<<<<<<<<<<<< ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<~
                 $realname,             $groups
.

    ReadData();

    $ofh = select(STDOUT);
    $~   = "USERS";
    $^   = "USERS_TOP";
    $=   = 99999;

    USER: for $_ ( sort keys %users ) {
	$id       = $users{$_}[1];
	next USER if ($id < 500) and ($_ ne "root") and (!$FlagAll);
	next USER if ($id >=64000) and (!$FlagAll);

	# set $user  (can be changed by output format)
	$user     = $_;

	# set $realname (can be changed by output format)
	$realname = $users{$_}[3];

	# calculate $groups
	my($g, @glist);
	GROUP: for $g ( sort keys %groups ) {
	    next GROUP unless $groups{$g}[2] =~ /\b$_\b/;
	    push @glist, $g;
	}
	$groups = join ",", @glist;
        # emit a comment if user is disabled
        my $pwstatus =`/usr/bin/passwd -S $user |/usr/bin/tail -1`;
	if ($pwstatus =~ m/^Locked/) {
	    $user = "(" . $user . ")";	  
	}

	write;
    }
    select($ofh);

    exit 0;
}


#
# LISTUSERS
#	Emits all users in a form suitable /usr/bin/dialog
#
sub ListUsers ()
{
    ReadData();

    #
    # first: emit only normal users & root
    #
    my($user, $id, $pw, $realname);
    USER: for $user ( sort keys %users ) {
	$id = $users{$user}[1];
	next USER if ($id < 500) and ($user ne "root");
	next USER if ($id >=64000);
	$realname = $users{$user}[3];
	my $pwstatus =`/usr/bin/passwd -S $user |/usr/bin/tail -1`;
	if ($pwstatus =~ m/^Locked/) {
	    $realname .= " (disabled)"; }
	print "\"$user\" \"$realname\" ";
    }

    #
    # if asked for, emit all special users, too
    #
    if ($FlagAll) {
        SPECIALS: for $user ( sort keys %users ) {
	    $id = $users{$user}[1];
	    next SPECIALS if ($id >= 500) or ($id <64000) or ($user eq "root");
	    $realname = $users{$user}[3];
	    my $pwstatus =`/usr/bin/passwd -S $user |/usr/bin/tail -1`;
	    if ($pwstatus =~ m/^Locked/) {
		$realname .= " (disabled)"; }
	    print "\"$user\" \"$realname\" ";
	}
    }
    exit 0;
}


#
# GETUSERDATA
#	returns some user data in a form that will be understood by the shell
#
sub GetUserData ()
{
    ReadData();

    # does user exist?
    if (!$users{$GetUserData}) {
	die "User '$GetUserData' not found.\n";
    }

    print "USER_PASSWORD=";
    my $pwstatus =`/usr/bin/passwd -S $GetUserData |/usr/bin/tail -1`;
    if ($pwstatus =~ m/^Locked/) {
	print "\"(no password, login disabled)\"";
    }
    elsif ($users{$GetUserData}[0] eq "") {
	print "\"(empty password)\"";
    } else {
	print "\"(normal password)\"";
    }
    print "\n";

    print "USER_UID=$users{$GetUserData}[1]\n";

    my $id = $users{$GetUserData}[2];
    my $name = GetGroupName($id);
    $id .= ", $name" if $name;
    print "USER_GID=\"$id\"\n";

    print "USER_FULLNAME=\"$users{$GetUserData}[3]\"\n";
    print "USER_HOME=$users{$GetUserData}[4]\n";
    print "USER_SHELL=$users{$GetUserData}[5]\n";

    exit 0;
}


#
# SHOWGROUPS
#	displays all groups in a format suitable for human beings
#
sub ShowGroups ()
{
    my($id, $group, $users);

format GROUPS_TOP =
 Id Group name   Users
------------------------------------------------------------------------
.
format GROUPS =
@>> @<<<<<<<<<<< ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$id,$group,      $users
                 ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<~
                 $users
                 ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<~
                 $users
                 ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<~
                 $users
                 ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<~
                 $users
                 ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<~
                 $users
                 ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<~
                 $users
                 ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<~
                 $users
.

    ReadData();
    $ofh = select(STDOUT);
    $~   = "GROUPS";
    $^   = "GROUPS_TOP";
    $=   = 99999;

    #
    # list normal groups
    #
    my $name;
    GROUP: for $name ( sort keys %groups ) {
	# don't display UPG (user private groups)
	next GROUP if $users{$name};

	$id    = $groups{$name}[1];
	next GROUP if ((($id < 500) or ($id >= 64000)) and !$FlagAll);

	$group = $name;
	$groups{$name}[2] =~ /^,?(.*?),?$/;
	$users = $1;
	write;
    }

    SPECIAL: for $name ( sort keys %groups ) {
	# don't display UPG (user private groups)
	next SPECIAL if $users{$name};

	$id    = $groups{$name}[1];
	next SPECIAL if ($id >= 500) or ($id < 64000);

	$group = $name;
	$groups{$name}[2] =~ /^,?(.*?),?$/;
	$users = $1;
	write;
    }

    select($ofh);
    exit 0;
}


#
# LISTGROUPS
#	displays all groups in a format suitable for /usr/bin/dialog
#
sub ListGroups ()
{
    ReadData();
    my $found;

    # emit all "normal" groups
    for $_ ( sort keys %groups ) {
	next if $users{$_};			# don't display UPGs
	next if $groups{$_}[1] <= 500;		# don't display special groups
	next if $groups{$_}[1] > 64000;		# don't display special groups
	print "\"$_\" \"normal group\" ";
	$found = 1;
    }

    # emit all "user-private-groups"
    if ($FlagWithUPG) {
	print "\"users\" \"special group\" ";
	for $_ ( sort keys %groups ) {
	    next unless $users{$_};		# don't display non-UPGs
	    next if $groups{$_}[1] < 500;	# don't display special groups
	    next if $groups{$_}[1] >= 64000;	# don't display special groups
	    print "\"$_\" \"user private group\" ";
	    $found = 1;
	}
    }
    
    # emit all "internal" groups if asked to do so
    if ($FlagAll) {
	for $_ ( sort keys %groups ) {
	    next if $groups{$_}[1] > 500;	# don't display UPGs and normal groups
	    next if $groups{$_}[1] <= 64000;	# don't display UPGs and normal groups
	    print "\"$_\" \"internal group\" ";
	    $found = 1;
	}
    }

    die "There are no selectable groups.\n" unless $found;
    exit 0;
}


#
# USERSINTOGROUP
#	Allows us to put many users into one group at once
#
sub UsersIntoGroup ()
{
    die "ELS_TEMP not set\n" unless $ENV{ELS_TEMP};

    ReadData();
    my @cmd = ('dialog','--checklist',
	"Set users for group '$UsersIntoGroup' with the SPACE key",	# Title
	'23',					# height
	'76',					# width
	'16');					# entries

    # emit all "normal" users
    for $_ ( sort keys %users ) {
	next if $users{$_}[1] < 500;		# don't display special users
	next if $users{$_}[1] >= 64000;		# don't display special users
	next if /^[A-Z]/;			# don't display UUCP users
	next if $_ eq $UsersIntoGroup;		# don't allow modification of your UPG
	push @cmd, ($_, $users{$_}[3],
		$groups{$UsersIntoGroup}[2] =~ /\b$_\b/ ? 'on' : '');
    }

    # emit "special" users
    for $_ ( sort keys %users ) {
	next if $users{$_}[1] >= 500;		# don't display special users
	next if $users{$_}[1] < 64000;		# don't display special users
	next unless $_ eq 'root' || $FlagAll;	# inhibit internal users normally
	next if $_ eq $UsersIntoGroup;		# don't allow modification of your UPG
	push @cmd, ($_, 'internal user',
		$groups{$UsersIntoGroup}[2] =~ /\b$_\b/ ? 'on' : '');
    }

    # emit all "UUCP" users
    if ($FlagAll) {
	for $_ ( sort keys %users ) {
	    next if $users{$_}[1] < 500;	# don't display special users
	    next if $users{$_}[1] >= 64000;	# don't display special users
	    next unless /^[A-Z]/;		# don't display UUCP users
	    next if $_ eq $UsersIntoGroup;	# don't allow modification of your UPG
	    push @cmd, ($_, 'UUCP login user',
		$groups{$UsersIntoGroup}[2] =~ /\b$_\b/ ? 'on' : '');
	}
    }

    open SAVEERR, ">&STDERR";
    open STDERR, ">$ENV{ELS_TEMP}";
    $_ = system(@cmd);
    open STDERR, ">&SAVEERR";
    close SAVEERR;

    if ($_ == 0) {
	# find out new users
	open FILE, $ENV{ELS_TEMP};
	$_ = <FILE> || '';
	close FILE;
        s/"//g;
	s/ $//;
	s/ /,/g;
	$groups{$UsersIntoGroup}[2] = $_;
	WriteGroup();
    }

    exit 0;
}


#
# USERINTOGROUPS
#	Allows us to put a user into many groups at once
#
sub UserIntoGroups ()
{
    die "ELS_TEMP not set\n" unless $ENV{ELS_TEMP};

    ReadData();
    my @cmd = ('dialog','--checklist',
	"Set groups for '$UserIntoGroups' with the SPACE key",	# Title
	'23',					# height
	'60',					# width
	'16');					# entries

    #print "User: $UserIntoGroups\n";

    # emit all "normal" groups
    for $_ ( sort keys %groups ) {
	next if $users{$_};			# don't display UPGs
	next if $groups{$_}[1] < 500;		# don't display special groups
	next if $groups{$_}[1] >= 64000;	# don't display special groups
        #print "Group: $_  $groups{$_}[2]\n";
        #print "----------> match $_\n" if $groups{$_}[2] =~ /(^|,)$UserIntoGroups(,|$)/;
	push @cmd, ($_, 'normal group',
		$groups{$_}[2] =~ /(^|,)$UserIntoGroups(,|$)/ ? 'on' : '');
    }

    # emit all "user-private-groups"
    for $_ ( sort keys %groups ) {
	next unless $users{$_};			# don't display non-UPGs
	next if $groups{$_}[1] < 500;		# don't display special groups
	next if $groups{$_}[1] >= 64000;	# don't display special groups
	next if $_ eq $UserIntoGroups;		# don't display own UPG
	push @cmd, ($_, 'user private group',
		$groups{$_}[2] =~ /(^|,)$UserIntoGroups(,|$)/ ? 'on' : '');
    }
    
    # emit all "internal" groups if asked to do so
    if ($FlagAll) {
	for $_ ( sort keys %groups ) {
	    # don't display UPGs and normal groups:
	    next if $groups{$_}[1] >= 500 && $groups{$_}[1] < 64000;
	    push @cmd, ($_, 'special group',
		$groups{$_}[2] =~ /(^|,)$UserIntoGroups(,|$)/ ? 'on' : '');
	}
    }


    open SAVEERR, ">&STDERR";
    open STDERR, ">$ENV{ELS_TEMP}";
    $_ = system(@cmd);
    open STDERR, ">&SAVEERR";
    close SAVEERR;

    if ($_ == 0) {
	# find out new groups
	open FILE, $ENV{ELS_TEMP};
	$_ = <FILE> || '';
	close FILE;
        s/"//g;
	s/ $//;
	$_ = ",$_" if $_;

        system('/usr/sbin/usermod', '-G', "$UserIntoGroups,users$_", $UserIntoGroups);
    }

    exit 0;
}


########################################################################
#
# Functions for command-line handling
#
########################################################################


sub ShowUsage ()
{
    print "Please invoke with the proper options ...\n";
    exit 1;
}

%OptionsControl = (
		    # for "users.mnu":
		    "users" => \$ShowUsers,
		    "listusers" => \$ListUsers,
		    "getuserdata:s" => \$GetUserData,
		    "userintogroups:s" => \$UserIntoGroups,

		    # for "groups.mnu":
		    "groups" => \$ShowGroups,
		    "listgroups" => \$ListGroups,
		    "usersintogroup:s" => \$UsersIntoGroup,

		    # various flags
		    "all" => \$FlagAll,
		    "withupg" => \$FlagWithUPG,
		  );

GetOptions(%OptionsControl);

ShowUsers if $ShowUsers;      # formatted for humans
ListUsers if $ListUsers;      # formatted for dialog
GetUserData if $GetUserData;
UserIntoGroups if $UserIntoGroups;

ShowGroups if $ShowGroups;    # formatted for humans
ListGroups if $ListGroups;    # formatted for dialog
UsersIntoGroup if $UsersIntoGroup;

ShowUsage();
exit 1;
