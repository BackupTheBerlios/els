ROOT = ../..

# Default target: dummy
all::

include $(ROOT)/Makefile.inc

ALL = afio.spec afio.patch \
      /usr/src/redhat/SOURCES/afio.patch \
      /usr/src/redhat/SOURCES/afio-2.4.7.tgz



rpms:: .rpms

install:: .rpms
	cp -v /usr/src/redhat/RPMS/i386/afio*.rpm $(RPM_DEST)

	

.rpms: $(ALL)
	rm -f /usr/src/redhat/RPMS/i386/afio*.rpm
	rpm -bb afio.spec
	touch .rpms

/usr/src/redhat/SOURCES/afio.patch: afio.patch
	cp -p afio.patch /usr/src/redhat/SOURCES/afio.patch

/usr/src/redhat/SOURCES/afio-2.4.7.tgz: afio-2.4.7.tgz
	cp -p $@ /usr/src/redhat/SOURCES/$<

afio-2.4.7.tgz:
	wget http://www.ibiblio.org/pub/linux/system/backup/afio-2.4.7.tgz
