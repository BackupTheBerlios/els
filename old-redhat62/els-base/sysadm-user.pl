#!/usr/bin/perl -w

use Getopt::Long;

use lib '/usr/lib/perl5/site_perl';
use ConfigFiles;

use strict 'var';





###########################################################################
#
# helper functions
#
###########################################################################


#
# NEXTUSERID
#	Returns the next available user id. This is the highest already
#	defined user id plus one. User IDs in the middle won't be re-used.
#
sub NextUserId ()
{
    # find highest used UID
    my $nextid = 0;
    for $_ ( keys %users ) {
	$nextid = $users{$_}[1] if $users{$_}[1] > $nextid;
    }

    # increment by one to get next free UID
    $nextid++;

    # make sure that we never assign UIDs below 500
    $nextid = 500 if $nextid < 500;

    return $nextid;
}


#
# NEXTGROUPID
#	returns the next available group id. This is the highest already
#	defined group id plus one.
#
sub NextGroupId ()
{
    # find highest used GID
    my $nextid = 0;
    foreach $_ ( keys %groups ) {
	$nextid = $groups{$_}[1] if ($groups{$_}[1] > $nextid);
    }

    # increment by one to get next free GID
    $nextid++;

    # make sure that we never assign GIDs below 500
    $nextid = 500 if $nextid < 500;

    return $nextid;
}


#
# ADDTOGROUP
#	Adds a user to a group.
#
sub AddToGroup ($$;$)
{
    my($user, $group, $verbose) = @_;

    # does the user and group exist?
    unless ($users{$user})   { die "User '$user' not found.\n" if $verbose; return; }
    unless ($groups{$group}) { die "Group '$group' not found.\n" if $verbose; return; }

    # get the list of users and check if user is already in
    if ($groups{$group}[2] =~ /,$user,/) {
       die "User '$user' already in group '$group'.\n" if $verbose;
       return;
    }

    # add user to group
    @_ = split ",", $groups{$group}[2];
    push @_, $user;
    $groups{$group}[2] = join ",", @_;
}


#
# DELETEFROMGROUP
#	Removes a user from a group.
#
sub DeleteFromGroup ($$$)
{
    my($user, $group, $verbose) = @_;

    # does the user and group exist?
    if ($verbose) {
	unless ($users{$user})   { die "User '$user' not found.\n"; }
	unless ($groups{$group}) { die "Group '$group' not found.\n"; }
    }

    # get the list of users and check if user is in
    unless ($groups{$group}[2] =~ /,$user,/) {
       die "User '$user' not in group '$group'.\n" if $verbose;
       return;
    }

    # delete user from group list
    @_ = split ",", $groups{$group}[2];
    grep{ ! /^$user$/ } @_;
    $groups{$group}[2] = join ",";
}







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
	    next SPECIALS if ($id >= 500) or ($user eq "root");
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
# ADDUSER
#	adds the user $AddUser with real name $Value to /etc/passwd
#	and /etc/group
#
sub AddUser ()
{
    ReadData();

    # go away with virtual users ...
    if ($AddUser eq 'postmaster') {
	die "Did you ever learn how to alias postmaster\nto a real person?\n";
    }

    # is user already there?
    if ($users{$AddUser}) {
	die "User '$AddUser' already defined.\n";
    }
    if ($groups{$AddUser}) {
	die "'$AddUser' already occupied, use a different name.\n";
    }

    # make sure the user name is valid
    if ($AddUser =~ /:/) {
	die "Please don't use ':' in user names.\n";
    }
    if ($AddUser =~ /\s/) {
	die "Please don't use spaces in user names.\n";
    }
    if ($AddUser =~ /[A-Z]/) {
	die "Please don't use CAPITAL letters in user names.\n";
    }
    if ($Value =~ /:/) {
	die "Please don't use ':' in real names.\n";
    }


    # find out next user and group id
    my $nextuserid  = NextUserId();
    my $nextgroupid = NextGroupId();

    # add user
    $users{$AddUser}[0] = "*";
    $users{$AddUser}[1] = $nextuserid;
    $users{$AddUser}[2] = $nextgroupid;
    $users{$AddUser}[3] = $Value;
    $users{$AddUser}[4] = "/usr/home/$AddUser";
    $users{$AddUser}[5] = "/bin/bash";

    $groups{$AddUser}[0] = "";
    $groups{$AddUser}[1] = $nextgroupid;
    $groups{$AddUser}[2] = "";

    # automatically add the user to the group 'users'
    AddToGroup($AddUser,'users');


    WriteData();
    exit 0;
}


#
# DELETEUSER
#	deletes the user $DeleteUser from /etc/passwd and /etc/group
#
sub DeleteUser ()
{
    ReadData();

    # does user exist?
    if (!$users{$DeleteUser}) {
	die "User '$DeleteUser' not found.\n";
    }

    # delete user and UPG
    delete $users{$DeleteUser};
    delete $groups{$DeleteUser};

    # delete user from any other group
    foreach $_ ( keys %groups ) {
	@_ = split ",", $groups{$_}[2];
	@_ = grep{ ! /^$DeleteUser$/ } @_;
	$groups{$_}[2] = join ",", @_;
    }

    WriteData();
    exit 0;
}


#
# SETUSERDATA
#	set's any field of a user to any value
#
# --data 0 --value "" --setuserdata user		set password
# --data 1 --value 10 --setuserdata user		set uid to 10
# --data 2 --value 31 --setuserdata user		set gid to 31
# --data 3 --value "Full name" --setuserdata user	set new full name
# --data 4 --value "/root" --setuserdata user		set new home dir
# --data 5 --value "/bin/csh" --setuserdata user	set new shell
# --data 10 --value "secret" --setuserdata user		set&encrypt password 
# --data 11 --value "users" --setuserdata user		set new primary group
#
sub SetUserData ()
{
    ReadPasswd();

    # does user exist?
    if (!$users{$SetUserData}) {
	die "User '$SetUserData' not found.\n";
    }

    # make sure no : is used
    if ($SetUserData =~ /:/) {
	die "Please don't use ':' in the user name.\n";
    }

    # encrypt the password if necessary
    if ($Data == 10) {
	$users{$SetUserData}[0] = crypt($Value, $Value);
    }
    elsif ($Data == 11) {
	ReadGroup();

	# delete user from old primary group
	my $oldgroup = GetGroupName($users{$SetUserData}[2]);
	my @userlist = split ",", $groups{$oldgroup}[2];
	@userlist = grep{ ! /^$SetUserData$/ } @userlist;
	$groups{$oldgroup}[2] = join ",", @userlist;

	# set primary group field in user record
	$users{$SetUserData}[2] = $groups{$Value}[1];

	# set primary group in group file
	AddToGroup($SetUserData, $Value);
	WriteGroup();
    } else {
	$users{$SetUserData}[$Data] = $Value;
    }

    WritePasswd();
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
# USERINTOGROUPS
#	Allows us to put a user into many groups at once
#
sub UserIntoGroups ()
{
    die "TMPFILE not set\n" unless $ENV{TMPFILE};

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
	next if $groups{$_}[1] < 100;		# don't display special groups
        #print "Group: $_  $groups{$_}[2]\n";
        #print "----------> match $_\n" if $groups{$_}[2] =~ /(^|,)$UserIntoGroups(,|$)/;
	push @cmd, ($_, 'normal group',
		$groups{$_}[2] =~ /(^|,)$UserIntoGroups(,|$)/ ? 'on' : '');
    }

    # emit all "user-private-groups"
    for $_ ( sort keys %groups ) {
	next unless $users{$_};			# don't display non-UPGs
	next if $groups{$_}[1] < 500;		# don't display special groups
	next if $_ eq $UserIntoGroups;		# don't display own UPG
	push @cmd, ($_, 'user private group',
		$groups{$_}[2] =~ /(^|,)$UserIntoGroups(,|$)/ ? 'on' : '');
    }
    
    # emit all "internal" groups if asked to do so
    if ($FlagAll) {
	for $_ ( sort keys %groups ) {
	    next if $groups{$_}[1] >= 500;	# don't display UPGs and normal groups
	    push @cmd, ($_, 'special group',
		$groups{$_}[2] =~ /(^|,)$UserIntoGroups(,|$)/ ? 'on' : '');
	}
    }


    open SAVEERR, ">&STDERR";
    open STDERR, ">$ENV{TMPFILE}";
    $_ = system(@cmd);
    open STDERR, ">&SAVEERR";
    close SAVEERR;

    if ($_ == 0) {
	# remove user from all current groups
	foreach $_ ( keys %groups ) {
	    @_ = split ",", $groups{$_}[2];
	    @_ = grep{ ! /^$UserIntoGroups$/ } @_;
	    $groups{$_}[2] = join ",", @_;
	}
	
	# find out new groups
	open FILE, $ENV{TMPFILE};
	$_ = <FILE>;
	close FILE;
        s/"//g;
	s/ $//;

	# put user into all new groups
	foreach $_ (split / /, $_) {
	    AddToGroup($UserIntoGroups, $_);
	}
	WriteGroup();
    }

    exit 0;
}


#
# USERSINTOGROUP
#	Allows us to put many users into one group at once
#
#
sub UsersIntoGroup ()
{
    die "TMPFILE not set\n" unless $ENV{TMPFILE};

    ReadData();
    my @cmd = ('dialog','--checklist',
	"Set users for group '$UsersIntoGroup' with the SPACE key",	# Title
	'23',					# height
	'76',					# width
	'16');					# entries

    # emit all "normal" users
    for $_ ( sort keys %users ) {
	next if $users{$_}[1] < 100;		# don't display special users
	next if /^[A-Z]/;			# don't display UUCP users
	next if $_ eq $UsersIntoGroup;		# don't allow modification of your UPG
	push @cmd, ($_, $users{$_}[3],
		$groups{$UsersIntoGroup}[2] =~ /\b$_\b/ ? 'on' : '');
    }

    # emit "special" users
    for $_ ( sort keys %users ) {
	next if $users{$_}[1] >= 100;		# don't display special users
	next unless $_ eq 'root' || $FlagAll;	# inhibit internal users normally
	next if $_ eq $UsersIntoGroup;		# don't allow modification of your UPG
	push @cmd, ($_, 'internal user',
		$groups{$UsersIntoGroup}[2] =~ /\b$_\b/ ? 'on' : '');
    }

    # emit all "UUCP" users
    if ($FlagAll) {
	for $_ ( sort keys %users ) {
	    next if $users{$_}[1] < 500;	# don't display special users
	    next unless /^[A-Z]/;		# don't display UUCP users
	    next if $_ eq $UsersIntoGroup;	# don't allow modification of your UPG
	    push @cmd, ($_, 'UUCP login user',
		$groups{$UsersIntoGroup}[2] =~ /\b$_\b/ ? 'on' : '');
	}
    }


    open SAVEERR, ">&STDERR";
    open STDERR, ">$ENV{TMPFILE}";
    $_ = system(@cmd);
    open STDERR, ">&SAVEERR";
    close SAVEERR;

    if ($_ == 0) {
	# find out new users
	open FILE, $ENV{TMPFILE};
	$_ = <FILE>;
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
	next GROUP if (($id < 500) and !$FlagAll);

	$group = $name;
	$groups{$name}[2] =~ /^,?(.*?),?$/;
	$users = $1;
	write;
    }

    SPECIAL: for $name ( sort keys %groups ) {
	# don't display UPG (user private groups)
	next SPECIAL if $users{$name};

	$id    = $groups{$name}[1];
	next SPECIAL if ($id >= 500);

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
	print "\"$_\" \"normal group\" ";
	$found = 1;
    }

    # emit all "user-private-groups"
    if ($FlagWithUPG) {
	print "\"users\" \"special group\" ";
	for $_ ( sort keys %groups ) {
	    next unless $users{$_};		# don't display non-UPGs
	    next if $groups{$_}[1] < 500;	# don't display special groups
	    print "\"$_\" \"user private group\" ";
	    $found = 1;
	}
    }
    
    # emit all "internal" groups if asked to do so
    if ($FlagAll) {
	for $_ ( sort keys %groups ) {
	    next if $groups{$_}[1] > 500;	# don't display UPGs and normal groups
	    print "\"$_\" \"internal group\" ";
	    $found = 1;
	}
    }

    die "There are no selectable groups.\n" unless $found;
    exit 0;
}


#
# USERGROUPS
#	displays all groups in a format suitable for /usr/bin/dialog,
#	but only the groups in which the user $UserGroups is contained.
#
sub UserGroups ()
{
    ReadData();

    # does user exist?
    if (!$users{$UserGroups}) {
	die "User '$UserGroups' not found.\n";
    }

    my($name, %glist, $somegroup);

    foreach $name ( sort keys %groups ) {
	#print "--> $groups{$name}[2]\n";
	if ( $groups{$name}[2] =~ /,$UserGroups,/ and $groups{$name}[1] != $users{$UserGroups}[2] ) {
	    $glist{$name} = $name;
	    $somegroup = 1;
	}
    }

    unless ($somegroup) {
	die "User '$UserGroups' does not belong to any group.\n";
    }

    foreach $name ( sort keys %glist ) {
	if ($FlagLine) {
	    print "$name ";
	} else {
	    print "\"$name\" \"\" ";
	}
    }

    exit 0;
}


#
# ADDGROUP
#	this subroutines adds the group $AddGroup to /etc/group
#
sub AddGroup ()
{
    ReadGroup();

    # is group already there?
    if ($groups{$AddGroup}) {
	die "Group '$AddGroup' already exists.\n";
    }
    if ($users{$AddGroup}) {
	die "'$AddGroup' already occupied, use a different name.\n";
    }

    # make sure the group name is valid
    if ($AddGroup =~ /:/) {
	die "Please don't use ':' in group names.\n";
    }
    if ($AddGroup =~ /\s/) {
	die "Please don't use spaces in group names.\n";
    }

    my $nextid = NextGroupId();
    $groups{$AddGroup}[0] = "";
    $groups{$AddGroup}[1] = $nextid;
    $groups{$AddGroup}[2] = "";

    WriteGroup();
    exit 0;
}


#
# DELETEGROUP
#	this subroutines deletes the group $AddGroup from /etc/group
#
sub DeleteGroup ()
{
    ReadGroup();

    if (!$groups{$DeleteGroup}) {
	die "Group '$DeleteGroup' does not exists.\n";
    }
    if ($groups{$DeleteGroup}[1]<=500 && !$FlagAll) {
	die "You can't delete internal groups.\n";
    }

    delete $groups{$DeleteGroup};

    WriteGroup();
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
		    "adduser:s" => \$AddUser,
		    "deleteuser:s" => \$DeleteUser,
		    "setuserdata:s" => \$SetUserData,
		    "getuserdata:s" => \$GetUserData,
		    "data:s" => \$Data,
		    "value:s" => \$Value,
		    "userintogroups:s" => \$UserIntoGroups,

		    # for "groups.mnu":
		    "groups" => \$ShowGroups,
		    "listgroups" => \$ListGroups,
		    "usergroups:s" => \$UserGroups,
 		    "addgroup:s" => \$AddGroup,
		    "deletegroup:s" => \$DeleteGroup,
		    "usersintogroup:s" => \$UsersIntoGroup,

		    # various flags
		    "all" => \$FlagAll,
		    "withupg" => \$FlagWithUPG,
		    "line" => \$FlagLine,
		  );

GetOptions(%OptionsControl);

ShowUsers if $ShowUsers;      # formatted for humans
ListUsers if $ListUsers;      # formatted for dialog
AddUser if $AddUser;
DeleteUser if $DeleteUser;
GetUserData if $GetUserData;
SetUserData if $SetUserData;
UserIntoGroups if $UserIntoGroups;

ShowGroups if $ShowGroups;    # formatted for humans
ListGroups if $ListGroups;    # formatted for dialog
UserGroups if $UserGroups;    # formatted for dialog
AddGroup if $AddGroup;
DeleteGroup if $DeleteGroup;
UsersIntoGroup if $UsersIntoGroup;


ShowUsage();
exit 1;
