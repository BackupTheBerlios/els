ROOT    = .
SUBDIRS = utilities els-base els-backup els-postfix website

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
	@echo "  upload      upload website to berlios.de"
	@echo
