ROOT = ../..
include $(ROOT)/Makefile.inc

# Postfix from Red Hat Powertools 7.1:
POSTFIX = postfix-20011125-1SASL.i386.rpm
URL     = ftp://updates.redhat.com/7.1/en/powertools/i386

# Dito, but the source RPM:
#POSTFIX=postfix-20011125-1SASL.src.rpm
#URL=    postfix-20010228_pl08release-2.i386.rpm

# Postfix from the half-official RPM maintainer:
#POSTFIX=http://www.ea4els.ampr.org/~sjmudd/postfix/ftp/rh72/RPMS/i386
#URL=    ftp://updates.redhat.com/7.1/en/powertools/SRPMS

ALL = $(POSTFIX)


all:: $(ALL)

$(POSTFIX):
	wget $(URL)/$(POSTFIX)
