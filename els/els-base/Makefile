all: rpm

rpm: .rpm q

.rpm:
	rm -f /usr/src/redhat/RPMS/i386/els-base*.rpm
	rpm -bb els-base.spec && touch .rpm

q:
	ln -s /usr/bin/joe q

install: rpm
	cp -v /usr/src/redhat/RPMS/i386/els-base*.rpm /u1/redhat72/RedHat/RPMS
