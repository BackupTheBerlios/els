export ROOT = ../..
include $(ROOT)/Makefile.inc

INC = top.inc admins.inc developers.inc logos.inc bottom.inc
DOCS = index.html install.html



all:: docs

docs:: .links $(DOCS)

upload:: docs
	$(ROOT)/utilities/uploader.pl --subdir=els-samba *.html

clean::
	rm -f *.mnu *.html *.shtml $(INC) .links



%.html: %.shtml
	$(ROOT)/utilities/shtml2html.pl $< >$@

index.shtml: $(ROOT)/els-samba/README
	echo '<!--#set var="title" value="Easy Linux Server - els-samba"-->' >$@
	echo '<!--#include file="top.inc"-->' >>$@
	echo '<!--#include file="admins.inc"-->' >>$@
	echo '<!--#include file="logos.inc"-->' >>$@
	$(ROOT)/utilities/text2shtml.pl $< >>$@
	echo '<!--#include file="bottom.inc"-->' >>$@

install.shtml: $(ROOT)/els-samba/INSTALL
	echo '<!--#set var="title" value="Easy Linux Server - Install els-samba"-->' >$@
	echo '<!--#include file="top.inc"-->' >>$@
	echo '<!--#include file="admins.inc"-->' >>$@
	echo '<!--#include file="logos.inc"-->' >>$@
	$(ROOT)/utilities/text2shtml.pl $< >>$@
	echo '<!--#include file="bottom.inc"-->' >>$@

.links:
	ln -fs ../sysadm/top.inc top.inc
	ln -fs ../sysadm/bottom.inc bottom.inc
	ln -fs ../sysadm/admins.inc admins.inc
	ln -fs ../sysadm/developers.inc developers.inc
	ln -fs ../sysadm/logos.inc logos.inc
	touch .links

index.html:: index.shtml $(INC)
install.html:: install.shtml $(INC)
