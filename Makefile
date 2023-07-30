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
	install -m0644 -D -t $(DESTDIR)/etc/apt/sources.list.d sources.list.d/*.sources
	install -m0644 -D -T keyrings/dlitz-aptly.gpg $(DESTDIR)/etc/apt/keyrings/bullseye-backports-dlitz.gpg

%.sources: %.sources.in keyrings/dlitz-aptly.gpg scripts/generate-sources-list
	scripts/generate-sources-list $< keyrings/dlitz-aptly.gpg > $@

.PHONY: all install check clean mrproper
