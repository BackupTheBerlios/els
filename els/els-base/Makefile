# HTML 4.01 verification:
export SGML_CATALOG_FILES=../utilities/sgml/HTML4.cat

ALL = q *.pl *.sh *.mnu *.setup *.els-base bell cls els-base.dirs els-base.spec els.conf qrc sysadm



all: rpm

rpm: .rpm

.rpm: $(ALL)
	rm -f /usr/src/redhat/RPMS/i386/els-base*.rpm
	rpm -bb els-base.spec && touch .rpm

q:
	ln -s /usr/bin/joe q

install: rpm
	cp -v /usr/src/redhat/RPMS/i386/els-base*.rpm /u1/redhat72/RedHat/RPMS

html:
	../utilities/sysadmdoc.pl --verbose

check: html
	nsgmls -s -wall -B *.html
	
clean:
	rm -f *.html a q
