ROOT ?= .

SGML_CATALOG_FILES=$(ROOT)/utilities/sgml/HTML4.cat
REDHAT_CD ?= /u1/redhat72
export SGML_CATALOG_FILES

all::

rpms::

docs::

check:: docs
	nsgmls -s -wall -B $(wildcard *.html)

clean::
	rm -f a .rpms .docs

install::

upload::

all rpms docs check clean install upload::
	@for i in $(SUBDIRS) .; do test "$$i" = "." && continue; make -C $$i $@ ROOT=$(ROOT)/.. || exit 1; done
