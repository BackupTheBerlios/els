ROOT ?= .

SGML_CATALOG_FILES=../utilities/sgml/HTML4.cat
REDHAT_CD ?= /u1/redhat72
export SGML_CATALOG_FILES

all::

rpms::

docs::

check::
	nsgmls -s -wall -B $(wildcard *.html)

clean::
	rm -f a

install::

upload::

all rpms docs check clean install upload::
	@for i in $(SUBDIRS); do echo "Entering $$i"; make -C $$i $@ ROOT=$(ROOT)/.. || exit 1; echo "Leaving $$i"; done
