ROOT ?= .

SGML_CATALOG_FILES=$(ROOT)/utilities/sgml/HTML4.cat
RPM_DEST ?= /var/tmp
export SGML_CATALOG_FILES

all::

rpms::

docs::

check:: docs
	nsgmls -s -wall -B *.html

clean::
	rm -rf html a .rpms .docs *.html

install::

upload::

all rpms clean install upload::
	@for i in $(SUBDIRS) .; do test "$$i" = "." && continue; make -C $$i $@ ROOT=$(ROOT)/.. || exit 1; done
