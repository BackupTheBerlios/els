ROOT = ..
include $(ROOT)/Makefile.inc

ALL = *.pl *.mnu *.setup *.smb *.els-samba \
      els-samba.dirs els-samba.spec


rpms:: .rpms

docs:: .docs

check:: .docs

clean::
	rm -f *.html q

install:: .rpms
	cp -v /usr/src/redhat/RPMS/i386/els-samba*.rpm $(REDHAT_CD)/RedHat/RPMS





.rpms: $(ALL)
	rm -f /usr/src/redhat/RPMS/i386/els-samba*.rpm
	rpm -bb els-samba.spec && touch .rpms

.docs: $(wildcard *.mnu)
	../els-samba/sysadm-makedoc.pl --verbose *.mnu && touch .docs

q:
	ln -s /usr/bin/joe q
