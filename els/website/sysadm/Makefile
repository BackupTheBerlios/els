ROOT = ../..
include $(ROOT)/Makefile.inc



all:: .docs

docs:: .docs

clean::
	rm -f *.mnu *.html *.shtml *.inc .files .docs

upload:: all
	scp *.html holgerschurig@els.berlios.de:/home/groups/els/htdocs/sysadm



.docs: .files ../top.inc ../admins.inc ../logos.inc ../bottom.inc
	$(ROOT)/els-base/sysadm-makedoc.pl --shtml *.mnu
	for i in *.shtml; do $(ROOT)/utilities/makehtml.pl $$i >$${i%%.shtml}.html; done
	touch .docs

.files:
	rm -f *.mnu
	find $(ROOT)/els* -name "*.mnu" -exec ln -s {} . \;
	cd ..; for i in *.inc; do perl -pe 's{HREF="(?!http)}{HREF="../}g; s{SRC="(?!http)}{SRC="../}g' <$$i >sysadm/$$i; done; cd -
	touch .files
