%define name els-postfix
%define vers 1.0
%define rel  1

Summary: Easy Linux Server Postfix mailer module
Name: %{name}
Version: %{vers}
Release: %{rel}
Copyright: GPL
Group: Applications/System
Packager: Holger Schurig <holgerschurig@gmx.de>
Requires: postfix, els-base
BuildRoot: /var/tmp/%{name}-%{vers}-%{rel}

%description 


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
/usr/sbin/els-postfix.pl


%files
# DIRECTORIES

# PRESET CONFIG FILES
%config(noreplace) /etc/postfix/aliases.lists
%config(noreplace) /etc/postfix/insiders_only
%config(noreplace) /etc/postfix/protected_destinations
%config(noreplace) /etc/postfix/relocated
%config(noreplace) /etc/postfix/transport

# CONFIG FILE CHANGER
/usr/sbin/els-postfix.pl

# DIRECTORY ALIASES
#/etc/diralias.d/els-postfix.dirs

# ENVIRONMENT PROFILES

# PROCESS WATCHER
#/etc/cron.hourly/els-postfix.cron

# SYSADM AND ITS HELPERS

# SYSADM MENUS
/usr/lib/sysadm/postfix.mnu

%doc $OLDPWD/html/*
