ROOT    = ..
SUBDIRS = postfix
include $(ROOT)/Makefile.inc

ALL = Makefile *.spec *.setup *.mnu *.els-postfix \
      main.* bodychecks relocated transport


all:: rpms

rpms:: .rpms

docs:: .docs

check:: .docs

install:: .rpms
	cp /usr/src/redhat/RPMS/noarch/els-postfix*.rpm $(RPM_DEST)



.rpms: $(ALL)
	rm -f /usr/src/redhat/RPMS/noarch/els-postfix*.rpm
	rpm -bb els-postfix.spec
	touch .rpms

.docs: $(wildcard *.mnu)
	../els-base/sysadm-makedoc.pl --verbose *.mnu
	touch .docs
