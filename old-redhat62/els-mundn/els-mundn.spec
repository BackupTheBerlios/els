%define name els-mundn
%define vers 1.0
%define rel  5

Summary: Easy Linux Server M&N specific module
Name: %{name}
Version: %{vers}
Release: %{rel}
Copyright: GPL
Group: System Environment/Base
Packager: Holger Schurig <holgerschurig@gmx.de>
BuildRoot: /var/tmp/%{name}-%{vers}-%{rel}
Requires: els-lpr

%description 


%install
cd -
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/usr/doc/%{name}-%{vers}
./do --prefix=$RPM_BUILD_ROOT --install


%clean
rm -rf $RPM_BUILD_ROOT


%post
els-mundn.pl
echo "KDE" >/etc/sysconfig/desktop

%files
# DIRECTORIES

# PRESET CONFIG FILES
%config(noreplace) /etc/rc.d/rc.harddisk
/etc/skel/.xinitrc
/etc/skel/.cvsrc
%config(noreplace) /etc/X11/XF86Config-4

# CONFIG FILE CHANGER
%attr(0700,root,root) /usr/sbin/els-mundn.pl

# DIRECTORY ALIASES

# ENVIRONMENT PROFILES
/etc/profile.d/els-mundn.sh

# PROCESS WATCHER

# SYSADM AND ITS HELPERS

# SYSADM MENUS

# OTHER FILES

# DOCUMENTATION
