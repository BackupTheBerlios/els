ROOT    = .
SUBDIRS = utilities els-base els-backup website

# Trick so that not 'all::' is the default target but 'help::'
help::

include Makefile.inc


help::
	@echo "Valid target are:"
	@echo
	@echo "  rpms        create rpms"
	@echo "  docs        create docs"
	@echo "  check       check docs"
	@echo "  clean       tidy all"
	@echo "  install     install RPMs to your $(REDHAT_CD)/RedHat/RPMS"
	@echo "  upload      upload files to berlios.de"
	@echo

all rpms docs check clean install upload::
	@for i in $(SUBDIRS); do echo "Entering $$i"; make -C $$i $@ || break; echo "Leaving $$i"; done
