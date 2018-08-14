KBUILD ?= /lib/modules/$(shell uname -r)/build
VERSION ?= $(shell git describe --tags 2>/dev/null || echo unknown)
DKMS_NAME = antfs

Q ?= @

MODULE_CONFIG += CONFIG_ANTFS_FS=m
MODULE_CONFIG += CONFIG_ANTFS_SYMLINKS=y

sources += $(wildcard include/*)
sources += $(wildcard libntfs-3g/*)
sources += $(wildcard *.h *.c)
sources += Makefile Kbuild Kconfig

destination = $(DESTDIR)/usr/src/$(DKMS_NAME)-$(VERSION)

default: antfs.ko

antfs.ko: force
	$(MAKE) -C $(KBUILD) M=$(CURDIR) modules $(MODULE_CONFIG)
	$(call cmd_strip,$@)

clean: force
	$(MAKE) -C $(KBUILD) M=$(CURDIR) clean

.NOTPARALLEL:

install: install-source install-dkms

uninstall: uninstall-dkms uninstall-source

install-source: force
	@echo "INSTALL to $(destination)"
	$(Q)echo $(sources) | tr " " "\n" | cpio -pmud --quiet $(destination)/
	$(Q)sed -re 's,=ANTFS_VERSION,=$(VERSION),g' < dkms.conf > $(destination)/dkms.conf

uninstall-source: force
	@echo "PURGE $(destination)"
	$(Q)rm -rf $(destination)
	$(Q)rmdir --ignore-fail-on-non-empty --parents $(dir $(destination)) 2>/dev/null || true

install-dkms: force
	dkms add -m $(DKMS_NAME) -v $(VERSION)

uninstall-dkms:
	dkms remove -m $(DKMS_NAME) -v $(VERSION) --all
	$(MAKE) uninstall-source

force: ;
