ROOT    = ..
SUBDIRS = afio
include $(ROOT)/Makefile.inc

ALL = *.mnu *.setup *.pl *.spec \
      default.exclude rc.els-backup



rpms:: .rpm

docs::
	../utilities/sysadmdoc.pl --verbose

check:: html

clean::
	rm -f *.html

install:: .rpm
	cp -v /usr/src/redhat/RPMS/i386/els-backup*.rpm $(REDHAT_CD)/RedHat/RPMS




.rpm: $(ALL)
	rm -f /usr/src/redhat/RPMS/i386/els-backup*.rpm
	rpm -bb els-backup.spec && touch .rpm





	
