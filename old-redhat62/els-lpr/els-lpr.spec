%define name els-lpr
%define vers 1.0
%define rel  3

Summary: Easy Linux Server print module
Name: %{name}
Version: %{vers}
Release: %{rel}
Copyright: GPL
Group: Applications/System
Packager: Holger Schurig <holgerschurig@gmx.de>
Source: %{name}-%{vers}.tar.gz
PreReq: sysadm
Requires: sysadm, perl >= 5, lpr >= 0.48, rhs-printfilters, mpage
BuildRoot: /var/tmp/%{name}-%{vers}-%{rel}

%description 
This module implements a print spooling system.

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
# Clean up after ourselves, but be careful in case someone sets a bad buildroot
[ -d $RPM_BUILD_ROOT ] && [ "/" != "$RPM_BUILD_ROOT" ] && rm -rf $RPM_BUILD_ROOT


%files
# SYSADM
%attr(0600,root,root) /usr/lib/sysadm/printjobs.mnu
%attr(0600,root,root) /usr/lib/sysadm/printer.mnu
%attr(0600,root,root) /usr/lib/sysadm/printermod.mnu

# SYSADM HELPERS
/usr/sbin/sysadm-printer.pl

# PROCESS WATCHER
/etc/cron.hourly/els-lpr.sh

# OTHER FILES
#enhanced printfilter
/usr/lib/sysadm/printfilter

# DOCUMENTATION
# The docs generated from the *.mnu files go in the html dir during build
%doc $OLDPWD/html/*
%doc $OLDPWD/README*
