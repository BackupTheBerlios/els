ROOT    = ..
SUBDIRS = afio
include $(ROOT)/Makefile.inc

ALL = *.mnu *.setup *.pl *.spec \
      default.exclude rc.els-backup



rpms:: .rpms

docs:: .docs

check:: .docs

clean::
	rm -f *.html

install:: .rpms
	rm -f $(REDHAT_CD)/els-backup*.rpm
	cp -v /usr/src/redhat/RPMS/i386/els-backup*.rpm $(REDHAT_CD)/RedHat/RPMS



.rpms: $(ALL)
	rm -f /usr/src/redhat/RPMS/i386/els-backup*.rpm
	rpm -bb els-backup.spec
	touch .rpms

.docs: $(wildcard *.mnu)
	../els-base/sysadm-makedoc.pl --verbose *.mnu && touch .docs
