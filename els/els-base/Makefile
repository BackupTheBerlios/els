ROOT = ..
include $(ROOT)/Makefile.inc

ALL = *.pl *.sh *.mnu *.setup *.els-base \
      q bell cls sysadm \
      els-base.dirs els-base.spec els.conf qrc


rpms:: .rpm

docs::
	../utilities/sysadmdoc.pl --verbose

check:: html

clean::
	rm -f *.html q

install:: .rpm
	cp -v /usr/src/redhat/RPMS/i386/els-base*.rpm $(REDHAT_CD)/RedHat/RPMS





.rpm: $(ALL)
	rm -f /usr/src/redhat/RPMS/i386/els-base*.rpm
	rpm -bb els-base.spec && touch .rpm

q:
	ln -s /usr/bin/joe q
	
