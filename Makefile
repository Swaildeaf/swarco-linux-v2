#*****************************************************************************
#* 
#*  @file          Makefile
#*
#*                 SWARCO Traffic Systems Embdedded Linux Repository
#*
#*  @par Program:  SWARCO Traffic Systems Linux Repository
#*
#*  @version       1.0 (\$Revision$)
#*  @author        Guido Classen
#*                 SWARCO Traffic Systems
#* 
#*  $LastChangedBy$  
#*  $Date$
#*  $URL$
#*
#*  @par Modification History:
#*   2007-01-18 gc: initial version
#*
#*  @par Makefile calls:
#*
#*  Build: 
#*   make 
#*
#*****************************************************************************

BASE_DIR = .
WEISS_CD_DIR = $(HOME)/mnt/entwicklung/WeissEmbeddedLinux/DistriCD
# offline directory
#WEISS_CD_DIR = $(HOME)/mnt/daten/WeissEmbeddedLinux_lokal/DistriCD

include	$(BASE_DIR)/version.mk
include	$(BASE_DIR)/directories.mk

# soft float toolchain neccessary for building u-boot boot-loader
SOFT_FLOAT_TOOLCHAIN_DIR = buildroot/buildroot-2.0-soft-float/build_arm/staging_dir/usr/bin
SOFT_FLOAT_TOOLCHAIN = $(SOFT_FLOAT_TOOLCHAIN_DIR)/arm-linux-gcc	\
			$(SOFT_FLOAT_TOOLCHAIN_DIR)/arm-linux-ar	\
			$(SOFT_FLOAT_TOOLCHAIN_DIR)/arm-linux-ld	\
			$(SOFT_FLOAT_TOOLCHAIN_DIR)/arm-linux-objcopy

.PHONY: all
all: buildroot u-boot kernel \
     modules_install swarco-usermode-tools
# run make in buildroot again, to include the newly build kernel modules in 
# the jffs2 images
	cd $(BUILDROOT_PATH); make
	cp $(BUILDROOT_PATH)/binaries/ccm2200/rootfs-ccm2200-lp-nand.jffs2 $(TFTP_ROOT_DIR)
#	cp $(BUILDROOT_PATH)/binaries/ccm2200/rootfs-ccm2200-sp-nand.jffs2 $(TFTP_ROOT_DIR)
	cp $(BUILDROOT_PATH)/binaries/ccm2200/rootfs-ccm2200-lp.arm.ubifs $(TFTP_ROOT_DIR)


.PHONY: buildroot
buildroot:
#	make -C $(BUILDROOT_PATH) #this dosn't work WHY?
	cd $(BUILDROOT_PATH); make
	cp $(BUILDROOT_PATH)/binaries/ccm2200/rootfs-ccm2200-lp-nand.jffs2 $(TFTP_ROOT_DIR)
#	cp $(BUILDROOT_PATH)/binaries/ccm2200/rootfs-ccm2200-sp-nand.jffs2 $(TFTP_ROOT_DIR)
	cp $(BUILDROOT_PATH)/binaries/ccm2200/rootfs-ccm2200-lp.arm.ubifs $(TFTP_ROOT_DIR)


# .PHONY: buildroot-soft-float
# buildroot-soft-float:
# 	-make -C $(BUILDROOT_BASE)/$(BUILDROOT_SOFT_FLOAT_DIR)

$(SOFT_FLOAT_TOOLCHAIN):
	make -C $(BUILDROOT_BASE)/$(BUILDROOT_SOFT_FLOAT_DIR)
	rm -rf   $(BUILDROOT_BASE)/$(BUILDROOT_SOFT_FLOAT_DIR)/toolchain_build_arm


.PHONY: u-boot
u-boot: $(SOFT_FLOAT_TOOLCHAIN)
	cd $(U_BOOT_PATH); sh build-ccm2200.sh


.PHONY: kernel
kernel:
	cd $(KERNEL_PATH); sh build-ccm2200.sh


.PHONY: modules_install
modules_install:
	-rm -rf buildroot/buildroot-2.0/project_build_arm/ccm2200/root/lib/modules/*
	-rm -rf board/swarco/ccm2200/rootfs_overlay/lib/modules/*
	cd $(KERNEL_PATH); sh build-ccm2200.sh modules_install


.PHONY: swarco-usermode-tools
swarco-usermode-tools:
	make -C swarco-usermode-tools \
		CROSS_CC=../$(BUILDROOT_PATH)/build_arm/staging_dir/usr/bin/$(CROSS_CC) \
		CROSS_STRIP=../$(BUILDROOT_PATH)/build_arm/staging_dir/usr/bin/$(CROSS_STRIP) \
		CH_CONFIG_DIR=../$(CH_CONFIG_DIR)


.PHONY: prepare_tree
prepare_tree:
	sh prepare_tree.sh $(WEISS_CD_DIR)


TODAY = $(shell date +%Y%m%d)

# save modified versions from working directory back to Weiss-Embedded
# Linux-CD 
# cd $(U_BOOT_BASE); tar cvzf $(WEISS_CD_DIR)/sources/u-boot/u-boot-git-$(TODAY).tar.gz u-boot-git
.PHONY: u-boot-dist
u-boot-dist:
	cd $(U_BOOT_PATH); make distclean
	cd $(U_BOOT_BASE); tar xvzf $(WEISS_CD_DIR)/sources/u-boot/v2010.09/u-boot-git-v2010.09.tar.gz
	cd $(U_BOOT_BASE)/u-boot-git; make distclean
	-cd $(U_BOOT_BASE); diff -Nrup '--exclude=*~' --exclude=.depend --exclude=.git u-boot-git $(U_BOOT_DIR) >$(WEISS_CD_DIR)/sources/u-boot/v2010.09/u-boot-v2010.09-ccm2200-redu-$(TODAY).patch


KERNEL_ORIG = linux-orig
PATCH_FILE  = 201-swarco-ccm2200.patch
OUTPUT      = output-$(KERNEL_VERS)-ccm2200
KERNEL_CD_DIR= $(WEISS_CD_DIR)/sources/kernel/$(KERNEL_VERS)
CONFIG_CD    = $(KERNEL_CD_DIR)/kernel-config-$(KERNEL_VERS)-ccm2200

.PHONY: kernel-dist
kernel-dist:
	cp $(KERNEL_BASE)/$(OUTPUT)/.config $(CONFIG_CD)
	# extract a kernel with all patches except SWARCO CCM2200 patch!
	cd $(KERNEL_BASE) ; \
        ( \
	  \rm -rf $(KERNEL_ORIG) $(KERNEL_ACTUAL) ;\
	  # extract kernel                                      \
	  tar xjf $(KERNEL_CD_DIR)/linux-2.6.*.tar.bz2 ;\
	  mv $(KERNEL_ACTUAL) $(KERNEL_ORIG) ;\
	  cd linux-orig ;\
          \
	  # apply patches                                       \
	  for patch in $(KERNEL_CD_DIR)/[0-9]*.patch ;\
	  do \
	    if [ "$${patch##*/}" != "$(PATCH_FILE)" ] ; then \
	      echo applying patch: "$${patch##*/}" ;\
	      patch -p1 < $$patch ;\
	    fi ;\
	  done ;\
          \
#	  test -f $(KERNEL_CD_DIR)/cifs_1.44.tar.gz && tar xvzf $(KERNEL_CD_DIR)/cifs_1.44.tar.gz ;\
	)
	# create new SWARCO CCM2200 patch
	-cd $(KERNEL_BASE); diff -Nrub '--exclude=*~' $(KERNEL_ORIG) $(KERNEL_DIR) >$(KERNEL_CD_DIR)/new_$(PATCH_FILE)
#	\rm -rf $(KERNEL_ORIG)



# Local Variables:
# mode: makefile
# compile-command: "make"
# End:
