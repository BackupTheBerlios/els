%define name afio
%define vers 2.4.7
%define rel  1


Summary: Archiver and backup program with builtin compression
Name: %{name}
Version: %{vers}
Release: %{rel}
Copyright: LGPL
Group: Applications/Archiving
Vendor: Easy Linux Server
Source: http://www.ibiblio.org/pub/linux/system/backup/afio-2.4.7.tgz
Patch: afio.patch
BuildRoot: /var/tmp/%{name}-%{vers}-%{rel}


%description
Afio makes cpio-format archives.  Afio can make compressed cpio
archives that are much safer than compressed tar or cpio archives.
Afio is best used as an `archive engine' in a backup script.
Documentation and some sample scripts are in /usr/doc/packages/afio/.


%prep
%setup
%patch


%build
make


%clean
rm -rf $RPM_BUILD_ROOT


%install
export RPM_BUILD_ROOT
mkdir -p                   $RPM_BUILD_ROOT/usr/bin/
mkdir -p                   $RPM_BUILD_ROOT/usr/share/man/man1
rm -f                      $RPM_BUILD_ROOT/usr/share/man/man1/afio.1.gz
install -c -s -m755 afio   $RPM_BUILD_ROOT/usr/bin/
install -c    -m644 afio.1 $RPM_BUILD_ROOT/usr/share/man/man1


%files
%doc afio.lsm
%doc README
%doc HISTORY
%doc PORTING
%doc SCRIPTS
%doc script1
%doc script2
%doc script3
%doc script4
%doc INSTALLATION
/usr/bin/afio
/usr/share/man/man1/afio.1*
