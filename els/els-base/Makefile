ROOT = ..
include $(ROOT)/Makefile.inc


ALL = Makefile *.sh *.spec *.setup *.mnu *.pl *.dirs *.els-base \
      q bell cls sysadm els.conf qrc


all:: rpms

rpms:: .rpms

docs:: .docs

check:: .docs

install:: .rpms
	cp /usr/src/redhat/RPMS/noarch/els-base*.rpm $(RPM_DEST)



.rpms: $(ALL)
	rm -f /usr/src/redhat/RPMS/noarch/els-base*.rpm
	rpm -bb els-base.spec
	touch .rpms

.docs: $(wildcard *.mnu)
	../els-base/sysadm-makedoc.pl --verbose *.mnu
	touch .docs

q:
	test -L q || ln -s ./joe q 

clean::
	rm -rf q
