%define name els-postfix
%define vers 1.95
%define rel  1
%define withdoc 1

Summary: Easy Linux Server Postfix mailer module
Name: %{name}
Version: %{vers}
Release: %{rel}
Copyright: GPL
Group: Applications/System
Vendor: Easy Linux Server
BuildArch: noarch
Requires: els-base, postfix, procmail
BuildRoot: /var/tmp/%{name}-%{vers}-%{rel}

%description 
Postfix is the SMTP mailer to send and receive e-mail


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
/usr/sbin/sysadm-setup.pl --quiet postfixsave postfix postfixusers postfixgroups
# We don't know yet if the user wants canonical name rewriting on. However,
# Postfix needs the canonical.db file, otherwise it would complain
touch /etc/postfix/canonical
postmap /etc/postfix/canonical >/dev/null
postmap /etc/postfix/relocated >/dev/null
postmap /etc/postfix/transport >/dev/null
 

%files
# DIRECTORIES

# PRESET CONFIG FILES
%attr(0644,root,root) /etc/postfix/main.defaults
%attr(0644,root,root) %config(noreplace) /etc/postfix/main.local
%attr(0644,root,root) %config(noreplace) /etc/postfix/bodychecks
%attr(0644,root,root) %config(noreplace) /etc/postfix/relocated
%attr(0644,root,root) %config(noreplace) /etc/postfix/transport

# CONFIG FILE CHANGER
%attr(0600,root,root) /usr/lib/els/postfixcanonical.setup
%attr(0600,root,root) /usr/lib/els/postfixchroot.setup
%attr(0600,root,root) /usr/lib/els/postfixgroups.setup
%attr(0600,root,root) /usr/lib/els/postfixsave.setup
%attr(0600,root,root) /usr/lib/els/postfix.setup
%attr(0600,root,root) /usr/lib/els/postfixusers.setup

# SYSADM AND ITS HELPERS
%attr(0600,root,root) /usr/lib/els/email.mnu
%attr(0600,root,root) /usr/lib/els/postfix.mnu
%attr(0700,root,root) /usr/lib/els/adduser.els-postfix
%attr(0700,root,root) /usr/lib/els/deluser.els-postfix

# DIRECTORY ALIASES

# ENVIRONMENT PROFILES

# OTHER FILES
%attr(0755,root,root) /etc/ppp/20postfix.up

# DOCUMENTATION
%if %{withdoc}
%doc $OLDPWD/html/*
%endif
