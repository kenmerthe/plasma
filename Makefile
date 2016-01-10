APTINSTALL = apt-get install -y \
	-o Dir::Cache::Archives=.build/apt/archives

ISOLINUXDIR = /usr/lib/ISOLINUX
SYSBIOSDIR = /usr/lib/syslinux/modules/bios

.DELETE_ON_ERROR:

.PHONY: all
all: .build/plasma.iso

.build/apt/archives:
	mkdir -p $@

/usr/bin/genisoimage: | .build/apt/archives
	$(APTINSTALL) $(@F)

$(ISOLINUXDIR)/isolinux.bin \
$(SYSBIOSDIR)/ldlinux.c32: | .build/apt/archives
	$(APTINSTALL) isolinux

.build/iso:
	mkdir -p $@

.build/iso/isolinux.bin: $(ISOLINUXDIR)/isolinux.bin | .build/iso
	cp $< $@

.build/iso/ldlinux.c32: $(SYSBIOSDIR)/ldlinux.c32 | .build/iso
	cp $< $@

.build/iso/isolinux.cfg: src/isolinux.cfg | .build/iso
	cp $< $@

.build/plasma.iso: \
.build/iso/isolinux.bin \
.build/iso/ldlinux.c32 \
.build/iso/isolinux.cfg \
| /usr/bin/genisoimage
	$(firstword $|) \
		-input-charset utf-8 \
	  -no-emul-boot \
	  -boot-info-table \
	  -b isolinux.bin \
	  -o $@ .build/iso
