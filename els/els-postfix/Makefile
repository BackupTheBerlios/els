ROOT    = ..
SUBDIRS = postfix
include $(ROOT)/Makefile.inc



rpms:: .rpm

docs::
	../utilities/sysadmdoc.pl --verbose

check:: html

clean::
	rm -f *.html

install:: .rpm
	cp -v /usr/src/redhat/RPMS/i386/els-postfix*.rpm $(REDHAT_CD)/RedHat/RPMS




.rpm:

#.rpm: $(ALL)
#	rm -f /usr/src/redhat/RPMS/i386/els-backup*.rpm
#	rpm -bb els-backup.spec && touch .rpm





	
