ROOT = ..
include $(ROOT)/Makefile.inc

ALL = *.pl *.sh *.mnu *.setup *.els-base \
      q bell cls sysadm \
      els-base.dirs els-base.spec els.conf qrc


rpms:: .rpms

docs:: .docs

check:: .docs

clean::
	rm -rf html q

install:: .rpms
	cp -v /usr/src/redhat/RPMS/i386/els-base*.rpm $(RPM_DEST)





.rpms: $(ALL)
	rm -f /usr/src/redhat/RPMS/i386/els-base*.rpm
	rpm -bb els-base.spec
	touch .rpms

.docs: $(wildcard *.mnu)
	../els-base/sysadm-makedoc.pl --verbose *.mnu && touch .docs

q:
	ln -s ./joe q
