ROOT    = ..
SUBDIRS = afio
include $(ROOT)/Makefile.inc

ALL = Makefile *.spec *.setup *.mnu *.pl default.exclude rc.els-backup



all:: rpms

rpms:: .rpms

docs:: .docs

check:: .docs

install:: .rpms
	cp /usr/src/redhat/RPMS/noarch/els-backup*.rpm $(RPM_DEST)



.rpms: $(ALL)
	rm -f /usr/src/redhat/RPMS/noarch/els-backup*.rpm
	rpm -bb els-backup.spec
	touch .rpms

.docs: $(wildcard *.mnu)
	../els-base/sysadm-makedoc.pl --verbose *.mnu
	touch .docs
