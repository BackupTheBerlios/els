ROOT    = ..
SUBDIRS = postfix
include $(ROOT)/Makefile.inc

ALL = *.mnu *.setup *.els-postfix main.* \
      bodychecks relocated transport els-postfix.spec


rpms:: .rpms

docs:: .docs

check:: .docs

clean::
	rm -f *.html

install:: .rpms
	cp -v /usr/src/redhat/RPMS/i386/els-postfix*.rpm $(REDHAT_CD)/RedHat/RPMS





.rpms: $(ALL)
	rm -f /usr/src/redhat/RPMS/i386/els-postfix*.rpm
	rpm -bb els-postfix.spec
	touch .rpms

.docs: $(wildcard *.mnu)
	../els-base/sysadm-makedoc.pl --verbose *.mnu && touch .docs
