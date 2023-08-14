VERSION:=4.3.6
TOP_DIR:=$(CURDIR)

BUILDER_DIR:=$(TOP_DIR)/glbuilder
BUILDER_TAG:=v1.0.7
BUILDER_URL:=https://github.com/gl-inet/glbuilder/archive/refs/tags/$(BUILDER_TAG).tar.gz

IMAGEBUILDER_DIR:=$(BUILDER_DIR)/build_dir/imagebuilder-mt1300-$(VERSION)
SDK_DIR:=$(BUILDER_DIR)/build_dir/sdk-mt1300-$(VERSION)
TOOLCHAIN_DIR:=$(SDK_DIR)/staging_dir/toolchain-mipsel_24kc_gcc-11.2.0_musl

all: image

$(BUILDER_DIR):
	mkdir -p $(BUILDER_DIR)
	curl -fSsLo- $(BUILDER_URL) | tar zx -C $(BUILDER_DIR) --strip-components=1

glbuilder-prepare: $(BUILDER_DIR)
	cp $(TOP_DIR)/files/.config $(BUILDER_DIR)/.config
	make -C $(BUILDER_DIR) defconfig
	make -C $(BUILDER_DIR) sdk/prepare
	make -C $(BUILDER_DIR) imagebuilder/prepare

glbuilder-patch: glbuilder-prepare
	mkdir -p $(BUILDER_DIR)/files/etc/board.d
	cp -f $(TOP_DIR)/files/04_fix_network $(BUILDER_DIR)/files/etc/board.d
	cp -f $(TOP_DIR)/files/mt7621_glinet_gl-mt1300.dts $(IMAGEBUILDER_DIR)/target/linux/ramips/dts
	cp -r $(SDK_DIR)/build_dir/target-mipsel_24kc_musl/linux-ramips_mt7621/linux-5.10.176 \
		$(IMAGEBUILDER_DIR)/build_dir/target-mipsel_24kc_musl/linux-ramips_mt7621

image: glbuilder-patch
	env PATH=$(PATH):$(SDK_DIR)/staging_dir/host/bin:$(TOOLCHAIN_DIR)/bin \
		make -C $(IMAGEBUILDER_DIR)/target/linux/ramips/image \
		$(IMAGEBUILDER_DIR)/build_dir/target-mipsel_24kc_musl/linux-ramips_mt7621/glinet_gl-mt1300-kernel.bin \
		TOPDIR="$(IMAGEBUILDER_DIR)" \
		INCLUDE_DIR="$(IMAGEBUILDER_DIR)/include" \
		TARGET_BUILD=1 \
		BOARD="ramips" \
		SUBTARGET="mt7621" \
		PROFILE="glinet_gl-mt1300" \
		DEVICE_DTS="mt7621_glinet_gl-mt1300"
	make -C $(BUILDER_DIR)

clean:
	make -C $(BUILDER_DIR) clean
