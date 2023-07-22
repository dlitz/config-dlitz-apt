DESTDIR ?= tmp/output
OUTPUTS =
OUTPUTS += sources.list.d/bookworm-backports-dlitz.sources
OUTPUTS += sources.list.d/bullseye-backports-dlitz.sources
OUTPUTS += sources.list.d/dlitz-aptly.sources

all: $(OUTPUTS) check

check: $(OUTPUTS)
	diff -q /usr/share/keyrings/dlitz-aptly.gpg keyrings/dlitz-aptly.gpg

clean:
	rm -f $(OUTPUTS)

mrproper: clean
	rm -rf tmp/output
	-rmdir --ignore-fail-on-non-empty --parents tmp

install: all
	umask 022
	mkdir -p $(DESTDIR)/etc/apt/preferences.d
	mkdir -p $(DESTDIR)/etc/apt/sources.list.d
	cp -rt $(DESTDIR)/etc/apt/preferences.d preferences.d/*
	cp -rt $(DESTDIR)/etc/apt/sources.list.d sources.list.d/*.sources

%.sources: %.sources.in keyrings/dlitz-aptly.gpg scripts/generate-sources-list
	scripts/generate-sources-list $< keyrings/dlitz-aptly.gpg > $@

.PHONY: all install check clean mrproper
