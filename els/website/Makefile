ROOT    = ..
SUBDIRS = sysadm
include $(ROOT)/Makefile.inc


SRC = $(wildcard *.shtml) ../README
DST = $(patsubst %.shtml,%.html,$(wildcard *.shtml)) index.shtml index.html



all:: .docs

docs:: .docs

clean::
	rm -f $(DST) .docs

upload:: all
	scp *.html holgerschurig@els.berlios.de:/home/groups/els/htdocs/



.docs: $(SRC) $(DST)
	touch .docs

%.html:	%.shtml top.inc logos.inc bottom.inc admins.inc developers.inc
	$(ROOT)/utilities/makehtml.pl $< >$@

index.shtml: ../README
	echo '<!--#set var="title" value="Easy Linux Server"-->' >$@
	echo '<!--#include file="top.inc"-->' >>$@
	echo '<!--#include file="logos.inc"-->' >>$@
	$(ROOT)/utilities/text2shtml.pl $< >>$@
	echo '<!--#include file="bottom.inc"-->' >>$@
