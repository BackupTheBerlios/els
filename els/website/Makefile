include $(ROOT)/Makefile.inc

# SHTML -> HTML transformation
ALL = $(patsubst %.shtml,%.html,$(wildcard *.shtml))



%.html:	%.shtml top.inc logos.inc bottom.inc admins.inc developers.inc
	../utilities/makehtml.pl $< >$@


all:: docs

docs:: all

check:: all
	nsgmls -s -wall -B ${ALL}

clean::
	rm -f ${ALL}

upload:: all
	scp *.html holgerschurig@els.berlios.de:/home/groups/els/htdocs/
