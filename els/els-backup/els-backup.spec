%define name els-backup
%define vers 1.95
%define rel  1
%define withdoc 1

Summary: Easy Linux Server backup module
Name: %{name}
Version: %{vers}
Release: %{rel}
Copyright: GPL
Group: Applications/System
Vendor: Easy Linux Server
Requires: els-base, afio, mt-st
BuildRoot: /var/tmp/%{name}-%{vers}-%{rel}


%description
Contains some sysadm menues for interactive and background backups.


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


%post
/usr/sbin/sysadm-setup.pl detecttape backupsets


%files
# DIRECTORIES
%attr(0755,root,root) %dir /etc/backup.d

# SYSADM AND ITS HELPERS
%attr(0700,root,root) /usr/sbin/sysadm-backup.pl
%attr(0600,root,root) /usr/lib/els/tape.mnu
%attr(0600,root,root) /usr/lib/els/backup.mnu
%attr(0600,root,root) /usr/lib/els/position.mnu
%attr(0600,root,root) /usr/lib/els/restore.mnu
%attr(0600,root,root) /usr/lib/els/sets.mnu

# PRESET CONFIG FILES
%attr(0600,root,root) %config(noreplace) /etc/backup.d/default.exclude
%attr(0600,root,root) %config(noreplace) /etc/rc.d/rc.els-backup

# CONFIG FILE CHANGER
%attr(0600,root,root) /usr/lib/els/detecttape.setup
%attr(0600,root,root) /usr/lib/els/backupsets.setup

# DIRECTORY ALIASES

# ENVIRONMENT PROFILES

# PROCESS WATCHER

# OTHER FILES

# DOCUMENTATION
%if %{withdoc}
%doc $OLDPWD/html/*
%endif
