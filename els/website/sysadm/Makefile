ROOT = ../..
include $(ROOT)/Makefile.inc





all:: getmenufiles
	./sysadmdoc.pl *.mnu

clean::
	rm -f *.mnu *.html



getmenufiles:
	rm -f *.mnu
	find $(ROOT)/els* -name "*.mnu" -exec ln -s {} . \;
