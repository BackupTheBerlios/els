%define name els-base
%define vers 1.0
%define rel  9

Summary: Easy Linux Server base module
Name: %{name}
Version: %{vers}
Release: %{rel}
Copyright: GPL
Group: System Environment/Base
Packager: Holger Schurig <holgerschurig@gmx.de>
Requires: dialog, joe => 2.8-42, less, perl, Authen-PAM >= 0.10
Provides: sysadm
BuildRoot: /var/tmp/%{name}-%{vers}-%{rel}

%description 
The Easy Linux Server project tries to achive an easy-to-setup,
easy-to-administer and easy-to-enhance Linux server system.


%prep
# There is nothing to prepare ...


%build
cd -
rm -rf html
mkdir html
./sysadm-makehtml.pl --destdir=html/ --srcdir=.


%install
cd -
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/usr/doc/%{name}-%{vers}
./do --prefix=$RPM_BUILD_ROOT --install


%clean
rm -rf $RPM_BUILD_ROOT


%post
echo "Run 'els-base.pl' to get a nice environment ..."


%files
# DIRECTORIES
%dir /etc/diralias.d
%dir /usr/lib/sysadm

# PRESET CONFIG FILES
%config(noreplace) /etc/joe/qrc
%config(noreplace) /etc/dialogrc
/usr/share/terminfo/t/teraterm.ti
%config(noreplace) /etc/rc.d/rc.serial
%config(noreplace) /etc/sysconfig/rc.sysadm

# CONFIG FILE CHANGER
%attr(0700,root,root) /usr/sbin/els-base.pl

# DIRECTORY ALIASES
/etc/diralias.d/els-base.dirs

# ENVIRONMENT PROFILES
/etc/profile.d/els-base.sh
/etc/profile.d/els-q.sh

# PROCESS WATCHER
/etc/cron.hourly/els-base.cron

# SYSADM AND ITS HELPERS
%attr(0700,root,root) /usr/sbin/sysadm
%attr(0700,root,root) /usr/sbin/sysadm-user.pl
%attr(0700,root,root) /usr/lib/sysadm/adduser.els-base
%attr(0700,root,root) /usr/lib/sysadm/deluser.els-base
%attr(0700,root,root) /usr/lib/sysadm/pwchange.els-base
/usr/lib/sysadm/rpmlist.txt

# SYSADM MENUS
%attr(0600,root,root) /usr/lib/sysadm/cdrom.mnu
%attr(0600,root,root) /usr/lib/sysadm/expert.mnu
%attr(0600,root,root) /usr/lib/sysadm/floppy.mnu
%attr(0600,root,root) /usr/lib/sysadm/groups.mnu
%attr(0600,root,root) /usr/lib/sysadm/hardware.mnu
%attr(0600,root,root) /usr/lib/sysadm/install.mnu
%attr(0600,root,root) /usr/lib/sysadm/kernel.mnu
%attr(0600,root,root) /usr/lib/sysadm/login.mnu
%attr(0600,root,root) /usr/lib/sysadm/main.mnu
%attr(0600,root,root) /usr/lib/sysadm/messages.mnu
%attr(0600,root,root) /usr/lib/sysadm/modem.mnu
%attr(0600,root,root) /usr/lib/sysadm/network.mnu
%attr(0600,root,root) /usr/lib/sysadm/runlevel.mnu
%attr(0600,root,root) /usr/lib/sysadm/system.mnu
%attr(0600,root,root) /usr/lib/sysadm/tcpip.mnu
%attr(0600,root,root) /usr/lib/sysadm/usermod.mnu
%attr(0600,root,root) /usr/lib/sysadm/users.mnu

# OTHER FILES
# Process watcher file
%attr(0600,root,root) /usr/lib/process-watcher
# Creates HTML files from the sysadm menu
/usr/sbin/sysadm-makehtml.pl
# hex, a hex dumper
%attr(0755,root,root) /usr/bin/hex
/usr/lib/hex.fmt
# Little screen clearer
%attr(0755,root,root) /usr/bin/cls
# Little audible program
%attr(0755,root,root) /usr/bin/bell
# Variant of joe, a modeless full screen editor
/usr/bin/q
# A hint for root on how to start Sysadm
%config(noreplace) /root/.startup
# Helper routine to access configuration files
/usr/lib/perl5/site_perl/ConfigFiles.pm

# DOCUMENTATION
%doc $OLDPWD/html/*
#/usr/man/man8/sysadm.8.gz
#/usr/man/man8/els-base.pl.8.gz
