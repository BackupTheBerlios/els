%define name els-samba
%define version 1.0
%define release 1

Summary: Easy Linux Server SAMBA configuration package
Name: %{name}
Version: %{version}
Release: %{release}
Copyright: GPL
Vendor: Operation Mobilisation
Packager: Holger Schurig <holgerschurig@gmx.de>
Group: Applications/System
Source: %{name}-%{version}.tar.gz

Requires: els-base, samba-common, samba >= 2.0.6, /etc/rc.d/init.d/smb
Requires: recode
BuildRoot: /var/tmp/%{name}-%{version}-%{release}

%description
This is a basic setup for SAMBA, the network protocol that is used
for Windows for Workgroups, Windows 95 and Windows NT. It allows all
of these machines to use the Linux Server as a file server.

%prep
# There is nothing to prepare ...

%build
cd -
rm -rf html
mkdir html
sysadm-makehtml.pl --destdir=html/ --srcdir=.


%install
cd -
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/usr/doc/%{name}-%{vers}
./do --prefix=$RPM_BUILD_ROOT --install


%clean
rm -rf $RPM_BUILD_ROOT


%pre
if ps ax | grep -q "[0-9] smbd " ; then
    echo -e "\nShutting SAMBA down:"
    [ -x /etc/rc.d/init.d/smb ] && /etc/rc.d/init.d/smb stop
    [ -x /etc/rc.d/init.d/samba ] && /etc/rc.d/init.d/samba stop
    sleep 2
    echo
fi


%post
echo -e "\nCreating initial samba configuration ..."
/usr/sbin/els-samba.pl
/usr/sbin/sysadm-samba.pl --updateconfig
[ -f /etc/rc.d/init.d/smb ] && chkconfig smb on
echo


%files
# DIRECTORIES
%dir /etc/samba.d
%dir /usr/samba
%dir /usr/samba/app
%attr(-,root,users)    %dir /usr/samba/arc
%dir /usr/samba/dat
%attr(2750,root,users) %dir /usr/samba/dat/transfer
%attr(2750,root,users) %dir /usr/samba/dat/general
%dir /usr/samba/netlogon
%dir /usr/samba/dat/users

# SYSADM
/usr/lib/sysadm/samba.mnu
/usr/lib/sysadm/sambamod.mnu
/usr/lib/sysadm/sambasetup.mnu

# SYSADM HELPERS
/usr/sbin/sysadm-samba.pl
/usr/lib/sysadm/adduser.els-samba
/usr/lib/sysadm/deluser.els-samba
/usr/lib/sysadm/pwchange.els-samba

# PRESET CONFIG FILES
%config(noreplace) /etc/samba.d/app.smb
%config(noreplace) /etc/samba.d/arc.smb
%config(noreplace) /etc/samba.d/cdrom.smb
%config(noreplace) /etc/samba.d/dat.smb
%config(noreplace) /etc/samba.d/global.smb
%config(noreplace) /etc/samba.d/home.smb
%config(noreplace) /etc/samba.d/linux.smb
%config(noreplace) /etc/samba.d/netlogon.smb
/usr/samba/netlogon/logon.bat

# CONFIG FILE CHANGER
/usr/sbin/els-samba.pl

# DIRECTORY ALIASES
/etc/diralias.d/els-samba.dirs

# ENVIRONMENT PROFILES

# PROCESS WATCHER
/etc/cron.hourly/els-samba.hourly

# OTHER FILES
/etc/cron.daily/els-samba.daily

# DOCUMENTATION
%doc html/*
