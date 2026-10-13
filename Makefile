VERSION := 0.$(shell git rev-list --count HEAD)
PKG := audiobible-verses-shmueloff-original

CHAPTERS := $(wildcard [0-9][0-9]/[0-9][0-9][0-9])
CHAPTER_PKGS := $(foreach c,$(CHAPTERS),$(PKG)-$(subst /,-,$(c)))
CHAPTER_DEBS := $(foreach p,$(CHAPTER_PKGS),build/dist/$(p)_$(VERSION)_all.deb)

empty :=
space := $(empty) $(empty)
comma := ,
DEPENDS := $(subst $(space),$(comma)$(space),$(CHAPTER_PKGS))

.PHONY: deb check-prefix clean

deb: check-prefix $(CHAPTER_DEBS) build/dist/$(PKG)_$(VERSION)_all.deb

check-prefix:
	test -n "$(PREFIX)"

# One small deb per chapter, e.g. build/dist/audiobible-verses-shmueloff-original-01-001_<version>_all.deb
build/dist/$(PKG)-%_$(VERSION)_all.deb:
	ch=$$(echo $* | tr - /); \
	book=$$(echo $$ch | cut -d/ -f1); \
	chapter=$$(echo $$ch | cut -d/ -f2); \
	pkgname=$(PKG)-$*; \
	staging=build/staging/$$pkgname; \
	folder=$$staging$(PREFIX)/share/scriptures/audio/shmueloff-original/$$ch; \
	rm -rf $$staging; \
	mkdir -p $$folder $$staging/DEBIAN; \
	cp -v -r $$ch/. $$folder/; \
	find $$staging -type d -exec chmod 0755 {} +; \
	find $$staging -type f -exec chmod 0644 {} +; \
	sed -e "s/@PKG@/$$pkgname/" \
		-e 's/@VERSION@/$(VERSION)/' \
		-e "s/@BOOK@/$$book/" \
		-e "s/@CHAPTER@/$$chapter/" \
		-e "s/@SIZE@/$$(du -sk $$staging | cut -f1)/" \
		debian/control-chapter.in > $$staging/DEBIAN/control; \
	mkdir -p build/dist; \
	debian/fast-build.sh $$staging $@

# Meta package: no audio, just the CSV and a Depends on every chapter package (unpinned)
build/dist/$(PKG)_$(VERSION)_all.deb: original.csv
	staging=build/staging/$(PKG); \
	folder=$$staging$(PREFIX)/share/scriptures/audio/shmueloff-original; \
	rm -rf $$staging; \
	mkdir -p $$folder $$staging/DEBIAN; \
	cp original.csv $$folder/; \
	find $$staging -type d -exec chmod 0755 {} +; \
	find $$staging -type f -exec chmod 0644 {} +; \
	sed -e 's/@VERSION@/$(VERSION)/' \
		-e "s/@SIZE@/$$(du -sk $$staging | cut -f1)/" \
		-e 's/@DEPENDS@/$(DEPENDS)/' \
		debian/control.in > $$staging/DEBIAN/control; \
	mkdir -p build/dist; \
	debian/fast-build.sh $$staging $@

clean:
	rm -rf build
