ROOT = ..
include $(ROOT)/Makefile.inc


ALL = Makefile *.sh *.spec *.setup *.mnu *.pl *.dirs *.els-samba *.smb



all:: rpms

rpms:: .rpms

docs:: .docs

check:: .docs

install:: .rpms
	cp /usr/src/redhat/RPMS/noarch/els-samba*.rpm $(RPM_DEST)



.rpms: $(ALL)
	rm -f /usr/src/redhat/RPMS/noarch/els-samba*.rpm
	rpm -bb els-samba.spec
	touch .rpms

.docs: $(wildcard *.mnu)
	../els-base/sysadm-makedoc.pl --verbose *.mnu
	touch .docs
