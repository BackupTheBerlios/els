%define name els-base
%define vers 2.0
%define rel  1
%define withdoc 0
%define withjoe 1

Summary: Easy Linux Server base module
Name: %{name}
Version: %{vers}
Release: %{rel}
Copyright: GPL
Group: System Environment/Base
Packager: Holger Schurig <holgerschurig@gmx.de>
Requires: redhat-release => 7.2, ncurses, perl
%if %{withjoe}
Requires: joe
%endif
Provides: sysadm
BuildRoot: /var/tmp/%{name}-%{vers}-%{rel}

%description 
The Easy Linux Server project tries to achive an easy-to-setup,
easy-to-administer and easy-to-enhance Linux server system.


%prep
# There is nothing to prepare ...


%build
cd -
%if %{withdoc}
rm -rf html
mkdir html
./els-makehtml.pl --destdir=html/ --srcdir=.
%endif


%install
cd -
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/usr/doc/%{name}-%{vers}
../utilities/rpmhelper.pl --prefix=$RPM_BUILD_ROOT --install


%clean
rm -rf $RPM_BUILD_ROOT


%post
echo "Run 'sysadm-setup.pl' or 'sysadm-setup.pl --all' to get a nice environment ..."


%files
# DIRECTORIES
%dir /etc/diralias.d
%dir /usr/lib/els

# PRESET CONFIG FILES
%if %{withjoe}
%attr(0644,root,root) %config(noreplace) /etc/joe/qrc
%endif
%attr(0700,root,root) %config(noreplace) /etc/els.conf

# CONFIG FILE CHANGER
%attr(0700,root,root) /usr/sbin/sysadm-setup.pl
%attr(0700,root,root) /usr/lib/els/bashrc.setup
%attr(0700,root,root) /usr/lib/els/bootmessages.setup
%attr(0700,root,root) /usr/lib/els/ctrlaltdel.setup
%attr(0700,root,root) /usr/lib/els/detectmodem.setup
%attr(0700,root,root) /usr/lib/els/detecttape.setup
%attr(0700,root,root) /usr/lib/els/dircolors.setup
%attr(0700,root,root) /usr/lib/els/inputrc.setup
%attr(0700,root,root) /usr/lib/els/issue.setup
%attr(0700,root,root) /usr/lib/els/mc-root.setup
%attr(0700,root,root) /usr/lib/els/mountpoints.setup
%attr(0700,root,root) /usr/lib/els/movehome.setup
%attr(0700,root,root) /usr/lib/els/nscd.setup
%attr(0700,root,root) /usr/lib/els/profile.setup
%attr(0700,root,root) /usr/lib/els/rclocal.setup
%attr(0700,root,root) /usr/lib/els/syslog.setup
%attr(0700,root,root) /usr/lib/els/sysrq.setup
%attr(0700,root,root) /usr/lib/els/tcptimestamps.setup
%attr(0700,root,root) /usr/lib/els/tcpwrappers.setup
%attr(0700,root,root) /usr/lib/els/unneededdaemons.setup

# DIRECTORY ALIASES
%attr(0700,root,root) /etc/diralias.d/els-base.dirs

# ENVIRONMENT PROFILES
%if %{withjoe}
/etc/profile.d/els-q.sh
%endif

# OTHER FILES
# Editor
%if %{withjoe}
/usr/bin/q
%endif
# Helper routine to access configuration files
%attr(0700,root,root) /usr/lib/perl5/site_perl/ConfigFiles.pm

# DOCUMENTATION
%if %{withdoc}
%doc $OLDPWD/html/*
%endif
