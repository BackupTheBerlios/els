# HTML 4.01 verification:
export SGML_CATALOG_FILES=../utilities/sgml/HTML4.cat

ALL = *.mnu *.setup *.pl *.spec default.exclude rc.els-backup



all: rpm

rpm: .rpm

.rpm: $(ALL)
	rm -f /usr/src/redhat/RPMS/i386/els-backup*.rpm
	rpm -bb els-backup.spec && touch .rpm

install: rpm
	cp -v /usr/src/redhat/RPMS/i386/els-backup*.rpm /u1/redhat72/RedHat/RPMS

html:
	../utilities/sysadmdoc.pl --verbose

check: html
	nsgmls -s -wall -B *.html
	
clean:
	rm -f *.html a q
