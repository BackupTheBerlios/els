%define name els-backup
%define vers 1.0
%define rel  3

Summary: Easy Linux Server backup module
Name: %{name}
Version: %{vers}
Release: %{rel}
Copyright: GPL
Group: Applications/System
Packager: Holger Schurig <holgerschurig@gmx.de>
BuildRoot: /var/tmp/%{name}-%{vers}-%{rel}
Requires: afio, mt-st


%description
Contains some sysadm menues for interactive and background backups.


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
mkdir -p $RPM_BUIL_ROOT/usr/doc/%{name}-%{vers}
./do --prefix=$RPM_BUILD_ROOT --install
cd -

%clean
rm -rf $RPM_BUILD_ROOT


%post
/usr/sbin/els-backup.pl


%files
# DIRECTORIES

# SYSADM
/usr/lib/sysadm/tape.mnu
/usr/lib/sysadm/backup.mnu
/usr/lib/sysadm/position.mnu
/usr/lib/sysadm/restore.mnu
/usr/lib/sysadm/sets.mnu

# SYSADM HELPERS
/usr/sbin/sysadm-backup.pl

# PRESET CONFIG FILES
%config(noreplace) /etc/backup.d/default.exclude
%config(noreplace) /etc/rc.d/rc.scsi

# CONFIG FILE CHANGER
/usr/sbin/els-backup.pl

# DIRECTORY ALIASES

# ENVIRONMENT PROFILES

# PROCESS WATCHER

# OTHER FILES

# DOCUMENTATION
/usr/src/redhat/SPECS/els-backup.spec
