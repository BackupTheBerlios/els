%define name els-dns
%define vers 1.0
%define rel  2

Summary: Easy Linux Server dns module
Name: %{name}
Version: %{vers}
Release: %{rel}
Copyright: GPL
Group: Applications/System
Packager: Holger Schurig <holgerschurig@gmx.de>
Requires: bind >= 8.2.2_P5 els-base, bind-utils
BuildRoot: /var/tmp/%{name}-%{vers}-%{rel}


%description
This implements a caching domain name server, based on bind 8.2.2
Patchlevel 5


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


%clean
rm -rf $RPM_BUILD_ROOT


%post
/usr/sbin/els-dns.pl


%files
# DIRECTORIES
%dir /var/named

# PRESET CONFIG FILES
%config(noreplace) /etc/named.conf
%config /var/named/named.root
/var/named/127.0.0.zone
/var/named/localhost.zone

# CONFIG FILE CHANGER
/usr/sbin/els-dns.pl

# DIRECTORY ALIASES
/etc/diralias.d/els-dns.dirs

# ENVIRONMENT PROFILES

# PROCESS WATCHER
/etc/cron.hourly/els-dns.sh

# SYSADM
/usr/lib/sysadm/dns.mnu

# SYSADM HELPERS

# OTHER FILES

# DOCUMENTATION
/usr/src/redhat/SPECS/els-dns.spec
