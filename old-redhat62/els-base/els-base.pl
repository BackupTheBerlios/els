#!/usr/bin/perl -w

#########################################################################
#
# This file patches various configuration of Red Hat 6.2
# It establishes a nice and workable environment.
#
#########################################################################

use lib '/usr/lib/perl5/site_perl';
use ConfigFiles;



#########################################################################
#
# Setup environment
#

# First of all, we determine which version of RedHat we're running
$FILE = '/etc/redhat-release';
open FILE;
$_ = <FILE>;
/(\d.\d)/;
$version = $1;
unless ($version eq '6.2') {
    die "This module has not been certified for Red Hat $version\n";
}
$insideanaconda = !defined $ENV{LOGNAME};
$force = 0;
$quiet = 0;
$laptop = 0;
$server = 0;

use Getopt::Long;
GetOptions('force' => \$force,
           'quiet' => \$quiet,
           'laptop' => \$laptop,
           'server' => \$server);

# Save persistent data
loadfile '/etc/sysconfig/rc.sysadm';
if    ($laptop) { setopt 'TYPE=', '"laptop"' }
elsif ($server) { setopt 'TYPE=', '"server"' }
else            { setopt 'TYPE=', '"workstation"' }
$laptop = (getopt('TYPE=') =~ /laptop/i);
$server = (getopt('TYPE=') =~ /server/i);
writefile;


# mark output buffered
$| = 1;



#########################################################################
#
# Now, we setup our preferred environment in the filesystem
#
#########################################################################
chdir '/';


#
# Create initial ini file for mc
#
if (!-f '/root/.mc/ini' || $force) {
    mkdir '/root/.mc', 0755;
    open FILE, '>/root/.mc/ini';
    print FILE <<EOF;
[Layout]
permission_mode=0
filetype_mode=0
[Midnight-Commander]
show_backups=1
show_dot_files=1
auto_save_setup=1
use_internal_edit=0
eight_bit_clean=1
full_eight_bits=0
use_8th_bit_as_meta=0
wrap_mode=0
have_fast_cpu=1
num_history_items_recorded=20
tar_gzipped_memlimit=2097152
[New Left Panel]
list_mode=user
user_format=half type,name,|,size
user_status3=name
[New Right Panel]
list_mode=user
user_format=half type,name,|,size
user_status3=name
EOF
    close FILE;
    open FILE, '>/root/.mc/hotlist';
    close FILE;
    print "/root/.mc/init: config file for 'mc' adjusted\n" unless $quiet;
}


#
# Stop unneeded background processes
#
# GPM is a mouse manager, it's main usability is cut-and-paste between
# different virtual consoles. This is handy - for programmers, but
# certainly not at a server. Because it's just a waste of memory, I delete
# the service.
#
# Note that only the service is deleted, not the program itself. You can
# start GPM from the command line at any time!
#
if ($insideanaconda) {
    my $disabled = 0;
    open CHKCONFIG, "chkconfig --list|";
    @lines = <CHKCONFIG>;
    close CHKCONFIG;
    foreach (@lines) {
       if ($server  && /^gpm.*on/)    { system('chkconfig --del gpm    >/dev/null 2>&1'); $disabled = 1; }
       if ($server  && /^nfsfs.*on/)  { system('chkconfig --del nfsfs  >/dev/null 2>&1'); $disabled = 1; }
       if (!$laptop && /^pcmcia.*on/) { system('chkconfig --del pcmcia >/dev/null 2>&1'); $disabled = 1; }
    }
}



#
# Fold /usr/etc to /etc
#
# Some RPMs drop files into /usr/etc. I want to have this in /etc instead.
if (-d '/usr/etc' && ! -l '/usr/etc') {
    system 'cd /usr && ' .
           'rm -rf /usr/etc && ' .	# save, because it's empty after a fresh install
           'ln -s /etc /usr/etc';
    print "Folded /usr/etc to /etc\n" unless $quiet;
}


#
# Fold /opt to /usr
#
# Some RPMs drop files into /opt. I want to have this in /usr instead
# (Okay, granted: you can use the relocate option of RPM. But what if
# you simply forget it?  Then suddenly your root partition is full ...
#
if (-d '/opt' && !-l '/opt') {
    system 'rm -rf /opt; ' .		# save, because it's empty after RH51 install
           'ln -s usr /opt';
    print "Folded /opt to /usr\n" unless $quiet;
}



#
# Fold /etc/init.d to /etc/rc.d/init.d
#
# This make RH 6.2 somewhat more FHS compliant
#
if (! -l '/etc/init.d') {
    symlink '/etc/rc.d/init.d', '/etc/init.d';
}


#
# Create default mount points
#
my $madedir = 0;
unless (-d '/mnt/cdrom')   { mkdir '/mnt/cdrom', 0755;  $madedir = 1; }
unless (-d '/mnt/floppy')  { mkdir '/mnt/floppy', 0755; $madedir = 1; }
unless (-d '/mnt/nfs')     { mkdir '/mnt/nfs', 0755;    $madedir = 1; }
unless (-d '/mnt/samba')   { mkdir '/mnt/samba', 0755;  $madedir = 1; }
unless (-d '/mnt/novell')  { mkdir '/mnt/novell', 0755; $madedir = 1; }
unless (-d '/mnt/dos')     { mkdir '/mnt/dos', 0755;    $madedir = 1; }
unless (-d '/mnt/zip')     { mkdir '/mnt/zip', 0755;    $madedir = 1; }
print "Created default mount points\n" if $madedir and !$quiet;


#
# Patch /etc/bashrc
#
# /etc/bashrc is executed at startup time of any interactive shell.
# Therefore, we set aliases that help the (interactive) user. Environment
# variables belong to /etc/profile, because the profile is sourced by any
# shell, even by non-interactive ones. Aliases are for users, not for
# programs, so to define environment variable see /etc/profile or just
# create your own executable shell script in /etc/profile.d/*.sh.
#
loadfile '/etc/bashrc';
if (search('PROMPT_COMMAND') || $force) {
    # now we have PROMPT_COMMAND in /etc/profile.d/els-base.sh
    deleteline 'PROMPT_COMMAND=';
    deleteline 'PS1=';

=for me

    appendonce '# make it more like dos';
    appendonce 'alias copy="cp -i"';
    appendonce 'alias del="rm -i"';
    appendonce 'alias dir="ls"';
    appendonce 'alias md="mkdir"';
    appendonce 'alias move="mv -i"';
    appendonce 'alias rd="rmdir"';
    appendonce 'alias ren="mv -i"';
    appendonce '# several handy shortcuts';
    appendonce 'alias l="ls -lF --color=tty"';
    appendonce 'alias ll="ls -lAF --color=tty"';
    appendonce 'alias ls="ls -AF --color=tty"';
    appendonce 'alias psg="ps aux | grep"';
    appendonce 'alias gdb="gdb --quiet"';
    appendonce '# directory changing for the lazy ones';
    appendonce 'alias ..="cd .."';
    appendonce 'alias ...="cd ../.."';
    appendonce 'alias ....="cd ../../.."';
    appendonce 'alias .....="cd ../../../.."';
    appendonce 'alias -="cd -"';
    appendonce '# get rid of core dumps';
    appendonce 'ulimit -c 0';
    unless (search('BASH_VERSINF')) {
        append 'test -z "$BASH_VERSINFO" && alias -="cd -"';
    }

=cut

    writefile;
    print "/etc/bashrc: changed prompt\n" unless $quiet;
}



#
# Patch /etc/inputrc
#
loadfile '/etc/inputrc';
unless (search 'mn320') {
    # +++ deleteall?
    deleteline '# for linux console';
    deleteline 'beginning-of-line';
    deleteline 'end-of-line';
    deleteline 'beginning-of-history';
    deleteline 'end-of-history';
    deleteline 'delete-char';
    deleteline 'quoted-insert';
    deleteline '#';
    deleteline '^$';

    append '';
    append '# Local standards:';
    append 'set bell-style none';

    append '$if term=linux';
    append '"\e[1~": beginning-of-line';
    append '"\e[4~": end-of-line';
    append '"\e[3~": delete-char';
    append '"\e[2~": quoted-insert';
    append '"\e[5~": history-search-backward';
    append '"\e[6~": history-search-forward';
    append '$endif';
    append '$if term=mn320';
    append '"\e[2~": beginning-of-line';
    append '"\e[5~": end-of-line';
    append '"\e[4~": delete-char';
    append '"\e[1~": quoted-insert';
    append '"\e[3~": history-search-backward';
    append '"\e[6~": history-search-forward';
    append '$endif';
    append '$if term=xterm';
    append '"\eOH": beginning-of-line';
    append '"\eOF": end-of-line';
    append '"\e[3~": delete-char';
    append '"\e[1~": quoted-insert';
    append '"\e[5~": history-search-backward';
    append '"\e[6~": history-search-forward';
    append '$endif';
    append '';
    append '"\\e[A":	previous-history';
    append '"\\e[B":	next-history';
    append '"\\e[C":	forward-char';
    append '"\\e[D":	backward-char';
    writefile;
    print "/etc/inputrc: added teraterm, xterm, linux\n" unless $quiet;
}


#
# Patch /etc/skel/.bash_profile
#
# This is the same as /etc/profile, but it will automatically copied into
# the home directory of every new user
#

loadfile '/etc/skel/.bash_profile';
if (!search('startup') || $force) {
    deleteline 'PATH=';
    deleteline 'USERNAME=';
    deleteline 'ENV=';
    deleteline 'export';
    appendonce '# set path to private ~/bin if present';
    appendonce 'test -d $HOME/bin && PATH="$PATH:$HOME/bin"';
    appendonce 'export USERNAME="$USER"';
    appendonce 'export BASH_ENV=$HOME/.bashrc';
    appendonce '# launch user into application if one is defined';
    append 'test -f ~/.startup && . ~/.startup';
    writefile;
    print "/etc/skel/.bash_profile: patched\n" unless $quiet;
}

loadfile '/root/.bash_profile';
if (!search('startup') || $force) {
    deleteline 'PATH=';
    deleteline 'USERNAME=';
    deleteline 'ENV=';
    deleteline 'export';
    appendonce '# set path to private ~/bin if present';
    appendonce 'test -d $HOME/bin && PATH="$PATH:$HOME/bin"';
    appendonce 'export USERNAME="$USER"';
    appendonce 'export BASH_ENV=$HOME/.bashrc';
    appendonce '# launch user into application if one is defined';
    append 'test -f ~/.startup && . ~/.startup';
    writefile;
    print "/root/.bash_profile: patched\n" unless $quiet;
}


#
# Patch /etc/rc.d/rc.local
#
# This file is executed automatically after the normal system boot process.
# It contained code that automatically overwrote /etc/issue and
# /etc/issue.net and we really don't want that.
#
# Now it executes all rc.* files in this directory with the exception of
# itself, rc.sysinit and rc.serial. So if you need special SCSI setup, just
# place a rc.scsi file in this directory and it gets automatically executed.
#
loadfile '/etc/rc.d/rc.local';
if (!search('rc.serial') || $force) {
    deleteall;
    append '#!/bin/sh';
    append '#';
    append '# This script will be executed *after* all other init scripts.';
    append '#';
    append '# Do *NOT* write anything into this script, create your own shell';
    append '# script and place it as rc.<whatever> into /etc/rc.d instead. It';
    append '# will be sourced automatically, so it can only be a shell script.';
    append '#';
    append 'cd /etc/rc.d';
    append 'for i in rc.*; do';
    append '    if [ $i != rc.local -a $i != rc.serial -a $i != rc.sysinit \\';
    append '        -a $i = ${i%.sample} \\';
    append '        -a $i = ${i%.rpmsave} -a $i = ${i%.rpmnew} -a $i = ${i%.rpmorig} \\';
    append '        -a $i = ${i%\~} ]; then';
    append '        echo running $i';
    append '        . $i';
    append '    fi';
    append 'done';
    writefile;
    print "/etc/rc.d/rc.*: allow local startup scripts\n" unless $quiet;
}


#
# Patch /etc/issue
#
# This file contains a text that is displayed before the user enters his
# username/password at the console.
#
chomp(my $hostname = `/bin/hostname`);
loadfile '/etc/issue';
if (!$insideanaconda &&
    (!search($hostname) || $force)) {
    deleteall;
    append '';
    append 'Easy Linux Server at ' . `uname -n`;
    append 'Authorized use only!';
    append '';
    writefile;
    print "/etc/issue: changed\n" unless $quiet;
}


#
# Patch /etc/issue.net
#
# This file contains a text that is displayed before the user enters his
# username/password from the network, e.g. via telnet.
#
loadfile '/etc/issue.net';
if (!$insideanaconda &&
    (!search($hostname) || $force)) {
    deleteall;
    append '';
    append 'Easy Linux Server at ' . `uname -n`;
    append 'Authorized use only!';
    append '';
    writefile;
    print "/etc/issue.net: changed\n" unless $quiet;
}


#
# Patch /etc/man.config
#
# We change the PAGER to make sure that LESS is used as our pager with the
# system-wide options.
#

=for me

loadfile '/etc/man.config';
if (!search '#PAGER' || $force) {
    comment 'PAGER';
    writefile;
}

=cut


#
# Patch /etc/inetd.conf
#
# This file defines which incoming TCP/IP should launch which program. Here
# I use a "tight ship" policy: only services that are known to be configured
# in a secure way are allowed, all other services are commented out and
# therefore disabled.
#
loadfile '/etc/inetd.conf';
if (!search '#login' || $force) {
    comment 'echo';
    comment 'discard';
    comment 'daytime';
    comment 'chargen';
    comment 'time';
    comment 'ftp';
    comment 'telnet';
    comment 'shell';
    comment 'login';
    comment 'exec';
    comment 'comsat';
    comment 'talk';
    comment 'ntalk';
    comment 'dtalk';
    comment 'pop-2';
    comment 'tftp';
    comment 'bootps';
    comment 'finger';
    comment 'cfinger';
    comment 'sysstat';
    comment 'netstat';
    comment 'auth';
    comment 'linuxconf';
    comment 'swat';
    deleteline '# End of inetd.conf';
    deleteline '^$';
    writefile;

    system '/usr/bin/killall', '-HUP', 'inetd';
    print "/etc/inetd.conf: more secure now\n" unless $quiet;
}


#
# Patch /etc/hosts.allow and /etc/hosts.deny
#
# This two files are the configuration for the TCP Wrapper. This is a
# special program that is called via the initd daemon (see /etc/inetd.conf)
# and specifies which INCOMING services are allowed. For now, we make our
# server pretty much secure: any incoming connection from our own subnet is
# allowd, any incoming connection from outside is denied.
#
# This security scheme does not work for daemons that are running on their
# own and not via inetd, e.g. "sendmail" or "lpd". For this services you
# must ensure security with other tools, e.g. proper configuration in
# /etc/sendmail.cf or /etc/printcap.
#
loadfile '/etc/hosts.deny';
if (!search('ALL') || $force) {
    setopt 'ALL: ', 'ALL';
    deleteline '# The portmap';
    deleteline '# the new secure';
    deleteline '# you should know';
    writefile;
    print "/etc/hosts.deny: initialized tcp_wrappers\n" unless $quiet;
}

loadfile '/etc/hosts.allow';
if (!search('ALL') || $force) {
    setopt 'ALL: ', '127.0.0.1';
    writefile;
    print "/etc/hosts.allow: initialized tcp_wrappers\n" unless $quiet;
}



#
# Patch PAM
#
# /etc/pam.conf    used by RedHat 4.1
# /etc/pam.d/*     used by RadHat 4.2
#
# configure the pluggable authentication module scheme. Here I allow
# logins from anywhere, not only from the files in /etc/securettys.
# This is completely ok because I also patched /etc/hosts.allow to ban
# any incoming connection from the outside.
#

=for me

loadfile '/etc/pam.d/login';
comment 'auth.+required.+securetty';
replace ' use_authtok', '';
writefile;
loadfile '/etc/pam.d/passwd';
comment 'password.+cracklib';
writefile;
print '.';

=cut


# 
# Patch /etc/syslog.conf
#
# This file defines which error messages, notification or even debug
# messages should end up in what file. Here I define that console 12 (switch
# to it with Alt-F12) get all notifications or worse.
#
loadfile '/etc/syslog.conf';
unless (search('tty12')) {
    append '';
    append '# log almost everything on console 12';
    append '*.notice						/dev/tty12';
    writefile;
    system 'killall -HUP syslogd';
    print "/etc/syslog.conf: output to console 12\n" unless $quiet;
}


#
# Patch /etc/inittab
#
# This file defines which background processes should be started by init
# (note that another category of background processes are started by the
# /etc/rc.d/rc?.d/ directory hierarchy).
#
# The patch makes mgetty on console 1 not to clear the screen before asking
# the user for the username. This way possible error messages from the
# boot process stay visible on the screen.
#
loadfile '/etc/inittab';
if (!search('noclear') || $force) {
    replace 'mingetty tty1$', 'mingetty --noclear tty1';
    writefile;
    print "/etc/inittab: keep console 1 contents after booting\n" unless $quiet;
}
#
# We also make sure that the Ctrl-Alt-Del shut the system down (in workstation
# mode)
#
if (!$server && (!search('-h now') || $force)) {
    replace '-r now', '-h now';
    writefile;
    print "/etc/inittab: halt system on C-A-D, don't reboot\n" unless $quiet;
}


#
# Patch /etc/modules.conf
#
# Linux can be compiled with a monolythic kernel, containing lots of
# drivers. Or you can compile it in a way that needed modules are loaded
# automatically by kerneld, the kernel daemon.
#
# This file set some reasonable values into the config file for kerneld.
# Don't ask me what this all means, I've stolen the texts from the 
# SuSE Linux distribution which worked very well.
#
# Ok, with the "options" you can define options (e.g. interrupts and
# so on) for the modules that can't do good autoprobing or that need
# special options to enable/disable features. You have to look at the
# sources or documentation to find out the possible options.
#
unless ($insideanaconda) {
    if (-f '/etc/conf.modules') {
        system('/bin/mv', '/etc/conf.modules', '/etc/modules.conf');
    }
    loadfile '/etc/modules.conf';
    if (!search('aout') || $force) {
        replace '[ \\t]+', ' ';
        appendonce 'options dummy0 -o dummy0';
        appendonce 'options dummy1 -o dummy1';
        appendonce 'alias net-pf-3 off';
        appendonce 'alias net-pf-4 off';
        appendonce 'alias net-pf-5 off';
        appendonce 'alias binfmt-0004 iBCS';
        appendonce 'alias binfmt-0064 binfmt_aout';
        writefile;
        system('/sbin/depmod', '-a');
        print "/etc/modules.conf: adjusted kernel module configuration\n" unless $quiet;
    }
}


#
# Add Teraterm to /etc/termcap
#
# You might add your favorite terminal to this list:
#
if (!$insideanaconda or $force) {
    if (!-f '/usr/share/terminfo/t/teraterm' || $force) {
        system 'tic', '/usr/share/terminfo/t/teraterm.ti';
        print "/usr/share/terminfo/t/teraterm: installed\n" unless $quiet;
    }

    if (!-f '/usr/share/terminfo/m/mn320' || $force) {
        system 'tic /usr/share/terminfo/t/teraterm.ti';
        print "/usr/share/terminfo/m/mn320: installed\n" unless $quiet;
    }

    loadfile '/etc/termcap';
    # +++ allow --force!
    unless (search 'teraterm') {
        system 'infocmp -1C teraterm | grep -v \.\.sa= | grep -v ZA= >>/etc/termcap';
        print "/etc/termcap: installed 'teraterm' entry\n" unless $quiet;
    }

    loadfile '/etc/termcap';
    unless (search 'mn320') {
        appendonce 'mn320:Tera Term Pro legacy entry:\\\\';
        appendonce '        :tc=teraterm:';
        writefile;
        print "/etc/termcap: installed 'mn320' entry\n" unless $quiet;
    }
}


#
# Patch /usr/src/linux/.config
#
# Here I set lots of default parameters, mostly I make a module out of
# everything that is not needed during boot-stage or for remote-debugging.
# Note that the default contains modules for SCSI support, but not a
# single SCSI controller. After all, you have to enable YOUR specific
# SCSI controller manually in "make menuconfig"
#
# Note that for the first installation (when no .config file is there)
# I set much more options than at additional runs. This is because I follow
# the strategy of setting it up all right, but if later the system
# administrator overwrite non-vital stuff, I believe him. However, if he
# overwrites vital stuff (which may break other modules), I won't believe
# him and silently make everything correct again.
#

=for me

# two helper functions
sub linux_set ($$) { my($what,$to) = @_; deleteline $what; setopt "$what=", $to; }
sub linux_del ($)  { my($what) = @_; deleteline "$what\\b"; append "# $what is not set"; }

# Just copy in the default config for now
my $initial = 0;
my $kernel     = `uname -r |sed -e 's/-.*//'`;
my $processor  = `uname -m`;
my $configfile = "/usr/src/linux-$kernel/configs/kernel-$kernel-$processor.config";
$configfile =~ s/\n//g;
if (-f $configfile && !-f "/usr/src/linux/.config") {
    system 'cp', '-p', $configfile, '/usr/src/linux/.config';
    $initial = 1;
}

=cut




#
# Delete unneccessary RPMs
#
# RPM is not re-entrant, so I cannot call RPM from inside RPM (and therefore
# not during 'rpm -i es-basic.rpm' ...      so I create a shell script that
# will be automatically executed by user "root" at login time that deletes
# all the unnecessary modules RedHat installed automatically.
#
# So I create a script that will only be executed by "root" and
# deletes itself automatically.
#
# People might argue that I should leave linuxconf installed. But it messes
# around in many ways (e.g. sendmail setup) that is unpredictable and
# contrary to our needs.
#
my $removerpms = 0;
sub checkrpm ($$)
{
   my ($package, $file) = @_;
   if (-e $file) {
       append "/etc/rc.d/init.d/$package stop 2>/dev/null >>/tmp/remove.log";
       append "rpm -e $package 2>>/tmp/remove.log";
       $removerpms = 1;
   }
}
loadfile '/etc/profile.d/delrpms.sh';
deleteall;
append '#!/bin/bash';
checkrpm('apmd',           '/usr/bin/apmd');
checkrpm('anachron',       '/usr/sbin/anachron');
checkrpm('kudzu',          '/usr/sbin/kudzu');
checkrpm('kudzu-devel',    '/usr/lib//libkudzu.a');
checkrpm('linuxconf',      '/bin/linuxconf');
checkrpm('linuxconf-devel','/bin/lib/liblinuxconf.a');
checkrpm('getty_ps',       '/sbin/getty');

if ($removerpms) {
    append 'rm -f /etc/profile.d/delrpms.sh';
    writefile;
    chmod 0700 ,'/etc/profile.d/delrpms.sh';
    print "Removing unnecessary RPMs at next login\n" unless $quiet;
}



#
# Patch /etc/cron.daily/updatedb.cron
#
# This script gives the command line option --prunepaths to updatedb.
# This has the unfortunate side effect that the environment PRUNEPATHS
# variable is now longer used for this.
#
# The same applies to NETPATHS.
#

=for me

loadfile '/etc/cron.daily/updatedb.cron';
replace " --prunepaths='.*?'", '';
replace " --netpaths='.*?'", '';
writefile;
print '.';

=cut


#
# Patch /etc/lilo.conf
#
# LILO is also broken, because RedHat used for some strange reason
# their internal patchlevel (5.0) in directory names. Don't do that!
#
# We alse add a new entry "old" that allows us to boot the previous kernel.
#
loadfile '/etc/lilo.conf';
if (search '2.2.14') {
    replace '-2.2.14-5.0', '';
    unless (search 'label=previous') {
        append 'image=/boot/vmlinuz.old';
        append '	label=previous';
        append '	root=' . getopt 'root=';
        append '	read-only';
    }
    writefile;
    symlink 'vmlinuz-2.2.14-5.0', '/boot/vmlinuz';
    symlink 'vmlinuz-2.2.14-5.0', '/boot/vmlinuz-2.2.14';
    symlink 'System.map-2.2.14-5.0', '/boot/System.map';
    symlink 'System.map-2.2.14-5.0', '/boot/System.map-2.2.14';
    symlink 'initrd-2.2.14-5.0.img', '/boot/initrd.img';
    symlink 'initrd-2.2.14-5.0.img', '/boot/initrd-2.2.14.img';

    # make label=previous work:
    system 'cp -p /boot/vmlinuz /boot/vmlinuz.old'       unless -f '/boot/vmlinuz.old';
    system 'cp -p /boot/System.map /boot/System.map.old' unless -f '/boot/System.map.old';
    system 'cp -p /boot/initrd.img /boot/initrd.old'     if -f '/boot/initrd.img' && ! -f '/boot/initrd.old';
    print "/etc/lilo.conf: added option to boot previous kernel\n" unless $quiet;
}
if (search '2.2.19') {
    replace '-2.2.19-6.2.1', '';
    unless (search 'label=previous') {
        append 'image=/boot/vmlinuz.old';
        append '	label=previous';
        append '	root=' . getopt 'root=';
        append '	read-only';
    }
    writefile;
    symlink 'vmlinuz-2.2.19-6.2.1', '/boot/vmlinuz';
    symlink 'vmlinuz-2.2.19-6.2.1', '/boot/vmlinuz-2.2.19';
    symlink 'System.map-2.2.19-6.2.1', '/boot/System.map';
    symlink 'System.map-2.2.19-6.2.1', '/boot/System.map-2.2.19';
    symlink 'initrd-2.2.19-6.2.1.img', '/boot/initrd.img';
    symlink 'initrd-2.2.19-6.2.1.img', '/boot/initrd-2.2.19.img';

    # make label=previous work:
    system 'cp -p /boot/vmlinuz /boot/vmlinuz.old'       unless -f '/boot/vmlinuz.old';
    system 'cp -p /boot/System.map /boot/System.map.old' unless -f '/boot/System.map.old';
    system 'cp -p /boot/initrd.img /boot/initrd.old'     if -f '/boot/initrd.img' && ! -f '/boot/initrd.old';
    print "/etc/lilo.conf: added option to boot previous kernel\n" unless $quiet;
}


=for me

### Put .config file for kernel builds in place if none exists
if (-d '/usr/src/linux/configs' && ! -f '/usr/src/linux/.config') {
    chomp(my $kernelver=`/bin/uname -r`); $kernelver =~ s/-.*$//;
    chomp(my $processor=`/bin/uname -m`); $processor =~ s/i486/i386/;
    system('/bin/cp', '-p', "/usr/src/linux/configs/kernel-$kernelver-$processor.config", '/usr/src/linux/.config');
    print "Set up default kernel .config file for a $processor processor\n" unless $quiet;
}

=cut




#
# Patch /etc/sysctl.conf to turn on packet forwarding.
#
loadfile '/etc/sysctl.conf';
if ((getopt('kernel.sysrq = ') eq '0') || $force) {
    replace 'Disables the magic', 'Enables the magic';
    setopt 'kernel.sysrq = ', '1';
    setopt 'net.ipv4.tcp_timestamps = ', '0';
    writefile;
    print "/etc/sysctl.conf: no tcp timestamps, allowd sysrq\n" unless $quiet;
}


#
# Patch /etc/DIR_COLORS because some colors are nearly unvisible with Teraterm
#
loadfile '/etc/DIR_COLORS';
if (!search 'teraterm' || $force) {
    comment 'LINK';
    comment 'FIFO';
    comment 'SOCK';
    comment 'BLK';
    comment 'CHR';
    comment 'ORPHAN';
    comment 'MISSING';
    replace 'EXEC 01;32', 'EXEC 01;31';
    replace 'TERM dtterm', 'TERM mn320';
    replace 'TERM cons25', 'TERM teraterm';
    comment '\.';
    writefile;
    print "/etc/DIR_COLORS: force readable output\n" unless $quiet;
}


#
# We don't use multicast, do we?
#
if (-f '/etc/ntp.conf') {
    loadfile '/etc/ntp.conf';
    if (!search '192.168.233.1') {
        comment 'multicastclient';
        appendonce 'server 192.168.233.1';
        appendonce 'server 192.168.233.2';
        writefile;
    }
}


#
# Patch /etc/cron.daily/tmpwatch to get rid of superfluous
# 'can't lstat ...' messages
#
loadfile '/etc/cron.daily/tmpwatch';
if (!search '2>/dev/null') {
  replace '}', '} 2>/dev/null';
  writefile;
  print "/etc/cron.daily/tmpwatch: stop superfluous error messages\n";
}


#
# Fix some permissions
#
chmod 0750, '/root';
chmod 01777, '/tmp';
