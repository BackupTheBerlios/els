all: rpm

rpm: .rpm

.rpm: q *.pl *.sh *.mnu *.setup *.els-base bell cls els-base.dirs els-base.spec els.conf qrc sysadm
	rm -f /usr/src/redhat/RPMS/i386/els-base*.rpm
	rpm -bb els-base.spec && touch .rpm

q:
	ln -s /usr/bin/joe q

install: rpm
	cp -v /usr/src/redhat/RPMS/i386/els-base*.rpm /u1/redhat72/RedHat/RPMS
