ROOT    = ..
SUBDIRS = sysadm

docs::

include $(ROOT)/Makefile.inc


SRC = $(wildcard *.shtml) ../README
DST = $(patsubst %.shtml,%.html,$(wildcard *.shtml)) \
      index.shtml   index.html \
      install.shtml install.html



all:: .docs

docs:: .docs

clean::
	rm -f $(DST) .docs

upload:: all
	scp *.css *.html holgerschurig@els.berlios.de:/home/groups/els/htdocs/

lint:: .docs
	$(ROOT)/utilities/linklint -quiet -error /@


.docs: $(SRC) $(DST)
	touch .docs

%.html:	%.shtml top.inc logos.inc bottom.inc
	$(ROOT)/utilities/makehtml.pl $< >$@

index.shtml: ../README
	echo '<!--#set var="title" value="Easy Linux Server"-->' >$@
	echo '<!--#include file="top.inc"-->' >>$@
	echo '<!--#include file="logos.inc"-->' >>$@
	$(ROOT)/utilities/text2shtml.pl $< >>$@
	echo '<!--#include file="bottom.inc"-->' >>$@

install.shtml: ../INSTALL
	echo '<!--#set var="title" value="Easy Linux Server"-->' >$@
	echo '<!--#include file="top.inc"-->' >>$@
	echo '<!--#include file="admins.inc"-->' >>$@
	echo '<!--#include file="logos.inc"-->' >>$@
	$(ROOT)/utilities/text2shtml.pl $< >>$@
	echo '<!--#include file="bottom.inc"-->' >>$@

# Dependencies:
developers.html patches.html structure.html:: developers.inc
admins.html download.html faq.html install.html installation.html:: admins.inc
modules.html sysadm.html:: admins.inc
