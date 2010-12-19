PREFIX=$(HOME)
EMACSDIR=$(PREFIX)/.emacs.d

install: install-all

install-all:
	install -m 755 qooxdoo.el $(EMACSDIR)/qooxdoo.el