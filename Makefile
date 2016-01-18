APTINSTALL = apt-get install -y \
	-o Dir::Cache::Archives=.build/apt/archives

ISOLINUXDIR = /usr/lib/ISOLINUX
SYSBIOSDIR = /usr/lib/syslinux/modules/bios

ROOTDIR = /tmp/plasma/root

.DELETE_ON_ERROR:

.PHONY: all
all: .build/plasma.iso

.build/apt/archives:
	mkdir -p $@

/usr/sbin/debootstrap: | .build/apt/archives
	$(APTINSTALL) $(@F)

/usr/bin/mksquashfs: | .build/apt/archives
	$(APTINSTALL) squashfs-tools

/usr/bin/genisoimage: | .build/apt/archives
	$(APTINSTALL) $(@F)

$(ISOLINUXDIR)/isolinux.bin \
$(SYSBIOSDIR)/ldlinux.c32: | .build/apt/archives
	$(APTINSTALL) isolinux

$(ROOTDIR)/vmlinuz \
$(ROOTDIR)/initrd.img: | /usr/sbin/debootstrap
	$(firstword $|) \
		--variant=minbase \
		--include=linux-image-amd64,live-boot \
		`lsb_release -sc` $(@D) \
	|| rm -rf $(@D) # debootstrap leaves partial root on error

.build/iso:
	mkdir -p $@

.build/iso/isolinux.bin: $(ISOLINUXDIR)/isolinux.bin | .build/iso
	cp $< $@

.build/iso/ldlinux.c32: $(SYSBIOSDIR)/ldlinux.c32 | .build/iso
	cp $< $@

.build/iso/isolinux.cfg: src/isolinux.cfg | .build/iso
	cp $< $@

.build/iso/vmlinuz: $(ROOTDIR)/vmlinuz | .build/iso
	cp $(ROOTDIR)/`readlink $<` $@

.build/iso/initrd.img: $(ROOTDIR)/initrd.img | .build/iso
	cp $(ROOTDIR)/`readlink $<` $@

.build/iso/live:
	mkdir -p $@

.build/iso/live/root.squashfs: $(ROOTDIR) | /usr/bin/mksquashfs .build/iso/live
	$(firstword $|) \
		$< $@ \
		-noappend \
		-no-duplicates \
		-e boot vmlinuz initrd.img

.build/plasma.iso: \
.build/iso/isolinux.bin \
.build/iso/ldlinux.c32 \
.build/iso/isolinux.cfg \
.build/iso/vmlinuz \
.build/iso/initrd.img \
.build/iso/live/root.squashfs \
| /usr/bin/genisoimage
	$(firstword $|) \
		-input-charset utf-8 \
	  -no-emul-boot \
	  -boot-info-table \
		-rational-rock \
	  -b isolinux.bin \
	  -o $@ .build/iso
