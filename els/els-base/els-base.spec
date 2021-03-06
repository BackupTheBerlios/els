%define name els-base
%define vers 1.96
%define rel  6
%define withdoc 1
%define withjoe 1

Summary: Easy Linux Server base module
Name: %{name}
Version: %{vers}
Release: %{rel}
Copyright: GPL
Vendor: Easy Linux Server
Requires: redhat-release => 7.2, findutils, grep, gawk, textutils
Requires: util-linux, mtools, e2fsprogs, shadow-utils, perl
%if %{withjoe}
Requires: joe
%endif
%if "%{_vendor}" == "MandrakeSoft"
Group: System/Base
# Get this from Cooker
Requires: cdialog >= 0.9a-8mdk
%else
Requires: dialog
Group: System Environment/Base
%endif
Provides: sysadm
BuildArch: noarch
BuildRoot: /var/tmp/%{name}-%{vers}-%{rel}

%description 
The Easy Linux Server project tries to achive an easy-to-setup,
easy-to-administer and easy-to-enhance Linux server system.


%prep
# There is nothing to prepare ...


%build
%if %{withdoc}
cd -
rm -rf html
mkdir html
./sysadm-makedoc.pl --destdir=html/ --srcdir=. *.mnu
%endif


%install
cd -
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/usr/doc/%{name}-%{vers}
ln -sf joe q
../utilities/rpmhelper.pl --prefix=$RPM_BUILD_ROOT --install
rm q

%clean
# Clean up after ourselves, but be careful in case someone sets a bad buildroot
[ -d $RPM_BUILD_ROOT ] && [ "/" != "$RPM_BUILD_ROOT" ] && rm -rf $RPM_BUILD_ROOT


%post
echo "Run 'sysadm-setup.pl' or 'sysadm-setup.pl --all' to get a nice environment ..."
cd /etc
lesskey -o .less lesskey

%files
# DIRECTORIES
%attr(0755,root,root) %dir /etc/diralias.d
%attr(0700,root,root) %dir /usr/lib/els

# PRESET CONFIG FILES
%attr(0600,root,root) %config(noreplace) /etc/lesskey
%attr(0600,root,root) %config(noreplace) /etc/els.conf
%if %{withjoe}
%attr(0644,root,root) %config(noreplace) /etc/joe/qrc
%endif

# CONFIG FILE CHANGER
%attr(0700,root,root) /usr/sbin/sysadm-setup.pl
%attr(0600,root,root) /usr/lib/els/bashrc.setup
%attr(0600,root,root) /usr/lib/els/bootmessages.setup
%attr(0600,root,root) /usr/lib/els/ctrlaltdel.setup
%attr(0600,root,root) /usr/lib/els/devpts.setup
%attr(0600,root,root) /usr/lib/els/dircolors.setup
%attr(0600,root,root) /usr/lib/els/inputrc.setup
%attr(0600,root,root) /usr/lib/els/issue.setup
%attr(0600,root,root) /usr/lib/els/less.setup
%attr(0600,root,root) /usr/lib/els/mc-root.setup
%attr(0600,root,root) /usr/lib/els/mountpoints.setup
%attr(0600,root,root) /usr/lib/els/movehome.setup
%attr(0600,root,root) /usr/lib/els/moveopt.setup
%attr(0600,root,root) /usr/lib/els/rclocal.setup
%attr(0600,root,root) /usr/lib/els/rootbashrc.setup
%attr(0600,root,root) /usr/lib/els/syslog.setup
%attr(0600,root,root) /usr/lib/els/tcptimestamps.setup
%attr(0600,root,root) /usr/lib/els/tcpwrappers.setup
%attr(0600,root,root) /usr/lib/els/unneededdaemons.setup
%attr(0600,root,root) /usr/lib/els/xterm.setup
%if "%{_vendor}" != "MandrakeSoft"
%attr(0600,root,root) /usr/lib/els/less.setup
%endif

# SYSADM AND ITS HELPERS
%attr(0700,root,root) /usr/sbin/sysadm
%attr(0700,root,root) /usr/sbin/sysadm-base.pl
%attr(0700,root,root) /usr/lib/els/adduser.els-base
%attr(0700,root,root) /usr/lib/els/deluser.els-base
%attr(0700,root,root) /usr/lib/els/pwchange.els-base
%attr(0600,root,root) /usr/lib/els/expert.mnu
%attr(0600,root,root) /usr/lib/els/groups.mnu
%attr(0600,root,root) /usr/lib/els/hardware.mnu
%attr(0600,root,root) /usr/lib/els/install.mnu
%attr(0600,root,root) /usr/lib/els/kernel.mnu
%attr(0600,root,root) /usr/lib/els/login.mnu
%attr(0600,root,root) /usr/lib/els/main.mnu
%attr(0600,root,root) /usr/lib/els/messages.mnu
%attr(0600,root,root) /usr/lib/els/network.mnu
%attr(0600,root,root) /usr/lib/els/runlevel.mnu
%attr(0600,root,root) /usr/lib/els/setup.mnu
%attr(0600,root,root) /usr/lib/els/system.mnu
%attr(0600,root,root) /usr/lib/els/usermod.mnu
%attr(0600,root,root) /usr/lib/els/users.mnu
%if "%{_vendor}" != "MandrakeSoft"
%attr(0600,root,root) /usr/lib/els/cdrom.mnu
%attr(0600,root,root) /usr/lib/els/floppy.mnu
%endif

# DIRECTORY ALIASES
%attr(0644,root,root) %config(noreplace) /etc/diralias.d/els-base.dirs

# ENVIRONMENT PROFILES
%attr(0755,root,root) %config(noreplace) /etc/profile.d/els-base.sh
%if %{withjoe}
%attr(0755,root,root) %config(noreplace) /etc/profile.d/els-q.sh
%endif

# OTHER FILES
# Helper routine to access configuration files
%attr(0600,root,root) /usr/lib/perl5/site_perl/ConfigFiles.pm
# Clear the screen and ring the bell
%attr(0755,root,root) /usr/bin/cls
%attr(0755,root,root) /usr/bin/bell
# Editor
%if %{withjoe}
/usr/bin/q
%endif

# DOCUMENTATION
%if %{withdoc}
%doc $OLDPWD/html/*
#%doc $OLDPWD/README $OLDPWD/INSTALL
%endif
