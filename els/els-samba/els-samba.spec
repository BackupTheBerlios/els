%define name els-samba
%define vers 2.0
%define rel  1
%define withdoc 0

Summary: Easy Linux Server SAMBA module
Name: %{name}
Version: %{vers}
Release: %{rel}
Copyright: GPL
Vendor: Easy Linux Server
Group: Applications/System
Requires: els-base, samba-common, samba, /etc/init.d/smb
BuildRoot: /var/tmp/%{name}-%{vers}-%{rel}


%description
This is a basic setup for SAMBA, the network protocol that is used
for Windows for Workgroups, Windows 95 and Windows NT. It allows all
of these machines to use the Linux Server as a file server.

%prep
# There is nothing to prepare ...


%build
%if %{withdoc}
cd -
rm -rf html
mkdir html
../els-base/sysadm-makedoc.pl --destdir=html/ --srcdir=. *.mnu
%endif


%install
cd -
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/usr/doc/%{name}-%{vers}
../utilities/rpmhelper.pl --prefix=$RPM_BUILD_ROOT --install


%clean
rm -rf $RPM_BUILD_ROOT


%pre
#if ps ax | grep -q "[0-9] smbd " ; then
#    echo -e "\nShutting SAMBA down:"
#    test -x /etc/init.d/smb && /etc/init.d/smb stop
#    sleep 2
#    echo
#fi


%post
echo -e "\nCreating initial samba configuration ..."
/usr/sbin/sysadm-setup.pl --verbose smbconfig.setup smbpasswd.setup smbhomedirs.setup
#test -x /etc//init.d/smb  && chkconfig --add smb
echo


%files
# DIRECTORIES
%attr(0755,root,root)  %dir /var/samba
%attr(0750,root,users) %dir /var/samba/app
%attr(0750,root,users) %dir /var/samba/arc
%attr(0750,root,users) %dir /var/samba/dat
%attr(2777,root,users) %dir /var/samba/dat/transfer
%attr(2770,root,users) %dir /var/samba/dat/general
%attr(0750,root,users) %dir /var/samba/dat/users
%attr(0755,root,root)  %dir /var/samba/netlogon

# SYSADM AND ITS HELPERS
%attr(0600,root,root) /usr/lib/els/samba.mnu
%attr(0600,root,root) /usr/lib/els/sambamod.mnu
%attr(0600,root,root) /usr/lib/els/sambasetup.mnu
%attr(0700,root,root) /usr/lib/els/adduser.els-samba
%attr(0700,root,root) /usr/lib/els/deluser.els-samba
%attr(0700,root,root) /usr/lib/els/pwchange.els-samba
%attr(0700,root,root) /usr/sbin/sysadm-samba.pl

# PRESET CONFIG FILES
%attr(0600,root,root) %config(noreplace) /etc/samba/app.smb
%attr(0600,root,root) %config(noreplace) /etc/samba/arc.smb
%attr(0600,root,root) %config(noreplace) /etc/samba/cdrom.smb
%attr(0600,root,root) %config(noreplace) /etc/samba/dat.smb
%attr(0600,root,root) %config(noreplace) /etc/samba/global.smb
%attr(0600,root,root) %config(noreplace) /etc/samba/home.smb
%attr(0600,root,root) %config(noreplace) /etc/samba/linux.smb
%attr(0600,root,root) %config(noreplace) /etc/samba/printers.smb
%attr(0600,root,root) %config(noreplace) /etc/samba/netlogon.smb
%attr(0644,root,root) %config(noreplace) /usr/samba/netlogon/logon.bat

# CONFIG FILE CHANGER
%attr(0600,root,root) /usr/lib/els/smbconfig.setup
%attr(0600,root,root) /usr/lib/els/smbpasswd.setup
%attr(0600,root,root) /usr/lib/els/smbhomedirs.setup

# DIRECTORY ALIASES
%attr(0644,root,root) %config(noreplace) /etc/diralias.d/els-samba.dirs

# ENVIRONMENT PROFILES

# OTHER FILES
%attr(0600,root,root) /etc/cron.daily/els-samba.daily

# DOCUMENTATION
%if %{withdoc}
%doc html/*
%endif
