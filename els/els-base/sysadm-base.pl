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
	next USER if ($id >64000) and (!$FlagAll);

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
	next USER if ($id >64000);
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
		  );

GetOptions(%OptionsControl);

ShowUsers if $ShowUsers;      # formatted for humans
ListUsers if $ListUsers;      # formatted for dialog
GetUserData if $GetUserData;


ShowUsage();
exit 1;
