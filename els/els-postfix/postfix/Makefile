ROOT = ../..
include $(ROOT)/Makefile.inc


# Postfix from the half-official RPM maintainer:
POSTFIX=postfix-20010228_pl08release-3.i386.rpm
URL=    http://www.ea4els.ampr.org/~sjmudd/postfix/ftp/rh72/RPMS/i386


##################################################
#
# This are older versions for Red Hat 7.1:
#
# Postfix from Red Hat Powertools 7.1:
#POSTFIX = postfix-20011125-1SASL.i386.rpm
#URL     = ftp://updates.redhat.com/7.1/en/powertools/i386
#
# Dito, but the source RPM:
#POSTFIX=postfix-20011125-1SASL.src.rpm
#URL=    ftp://updates.redhat.com/7.1/en/powertools/SRPMS
##################################################


POSTFIXDEST = /usr/src/redhat/RPMS/i386/$(POSTFIX)



rpms:: $(POSTFIXDEST)

install:: $(POSTFIXDEST)
	rm -f $(REDHAT_CD)/RedHat/RPMS/postfix*.rpm
	cp -p /usr/src/redhat/RPMS/i386/postfix*.rpm $(RPM_DEST)



$(POSTFIX):
	wget $(URL)/$(POSTFIX)

$(POSTFIXDEST): $(POSTFIX)
	rm -f /usr/src/redhat/RPMS/i386/postfix*.rpm
	cp -p $(POSTFIX) $(POSTFIXDEST)
