# HTML 4.01 verification:
export SGML_CATALOG_FILES=/usr/lib/sgml/html401/HTML4.cat


# SHTML -> HTML transformation
ALL = $(patsubst %.shtml,%.html,$(wildcard *.shtml))

%.html:	%.shtml top.inc logos.inc bottom.inc admins.inc developers.inc
	../utilities/makehtml.pl $< >$@


all: $(ALL) top.inc bottom.inc admins.inc developers.inc

check: all
	nsgmls -s -wall -B ${ALL}

update: all
	scp *.html holgerschurig@els.berlios.de:/home/groups/els/htdocs/

#../utilities/weblint -x Microsoft -d mailto-link ${ALL}
#../utilities/linklint ${ALL}

clean:
	rm -f ${ALL}
