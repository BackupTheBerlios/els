ROOT = ../..
include $(ROOT)/Makefile.inc

INC = top.inc modules.inc admins.inc developers.inc bottom.inc logos.inc



all:: .docs

docs:: .docs

upload:: docs
	$(ROOT)/utilities/uploader.pl --subdir=sysadm *.html

clean::
	rm -f *.mnu *.html *.shtml $(INC) .files .docs



.docs: .files $(INC)
	$(ROOT)/els-base/sysadm-makedoc.pl --shtml *.mnu
	for i in *.shtml; do $(ROOT)/utilities/shtml2html.pl $$i >$${i%%.shtml}.html; done
	touch .docs

.files:
	rm -f *.mnu
	find $(ROOT)/els* -name "*.mnu" -exec ln -s {} . \;
	touch .files

top.inc: ../top.inc
	perl -pe 's{HREF="(?!http)}{HREF="../}g; s{SRC="(?!http)}{SRC="../}g' <$< >$@

modules.inc: ../modules.inc
	perl -pe 's{HREF="(?!http)}{HREF="../}g; s{SRC="(?!http)}{SRC="../}g' <$< >$@

admins.inc: ../admins.inc
	perl -pe 's{HREF="(?!http)}{HREF="../}g; s{SRC="(?!http)}{SRC="../}g' <$< >$@

developers.inc: ../developers.inc
	perl -pe 's{HREF="(?!http)}{HREF="../}g; s{SRC="(?!http)}{SRC="../}g' <$< >$@

bottom.inc: ../bottom.inc
	perl -pe 's{HREF="(?!http)}{HREF="../}g; s{SRC="(?!http)}{SRC="../}g' <$< >$@

logos.inc: ../logos.inc
	perl -pe 's{HREF="(?!http)}{HREF="../}g; s{SRC="(?!http)}{SRC="../}g' <$< >$@
