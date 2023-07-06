DESTDIR ?= tmp/output

all:

clean:
	rm -rf tmp/output
	-rmdir --ignore-fail-on-non-empty --parents tmp

install:
	umask 022
	mkdir -p $(DESTDIR)/etc/apt/preferences.d
	mkdir -p $(DESTDIR)/etc/apt/sources.list.d
	cp -rt $(DESTDIR)/etc/apt/preferences.d preferences.d/*
	cp -rt $(DESTDIR)/etc/apt/sources.list.d sources.list.d/*

.PHONY: all install clean
