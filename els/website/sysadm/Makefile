ROOT = ../..
include $(ROOT)/Makefile.inc

INC = top.inc bottom.inc logos.inc admins.inc developers.inc



all:: .docs

docs:: .docs

clean::
	rm -f *.mnu *.html *.shtml $(INC) .files .docs

upload:: all
	scp *.html holgerschurig@els.berlios.de:/home/groups/els/htdocs/sysadm




.docs: .files $(INC)
	$(ROOT)/els-base/sysadm-makedoc.pl --shtml *.mnu
	for i in *.shtml; do $(ROOT)/utilities/makehtml.pl $$i >$${i%%.shtml}.html; done
	touch .docs

.files:
	rm -f *.mnu
	find $(ROOT)/els* -name "*.mnu" -exec ln -s {} . \;
	touch .files

top.inc: ../top.inc
	perl -pe 's{HREF="(?!http)}{HREF="../}g; s{SRC="(?!http)}{SRC="../}g' <$< >$@

bottom.inc: ../bottom.inc
	perl -pe 's{HREF="(?!http)}{HREF="../}g; s{SRC="(?!http)}{SRC="../}g' <$< >$@

logos.inc: ../logos.inc
	perl -pe 's{HREF="(?!http)}{HREF="../}g; s{SRC="(?!http)}{SRC="../}g' <$< >$@

admins.inc: ../admins.inc
	perl -pe 's{HREF="(?!http)}{HREF="../}g; s{SRC="(?!http)}{SRC="../}g' <$< >$@

developers.inc: ../developers.inc
	perl -pe 's{HREF="(?!http)}{HREF="../}g; s{SRC="(?!http)}{SRC="../}g' <$< >$@
