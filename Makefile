default: ofed modules
all: default

OFED_VERSION=3.3
LIVE_KERNEL_VER=$(shell uname -r)
LIVE_KERNEL_ARCH=$(shell uname -m)
LIVE_KERNEL_DIR=/lib/modules/$(shell uname -r)/build
LIVE_KERNEL_GCC=$(shell sed 's/.*gcc version \([^ ]*\) .*/\1/' < /proc/version)
LIVE_GCC=$(shell gcc -v 2>&1 | sed -e '/^gcc/!d;s/.*gcc version \([^ ]*\) .*/\1/;'| cut -d' ' -f 3)
PATH := $(PATH):/sbin:/usr/sbin

NVMEOF_PWD  := $(shell pwd)
export NVMEOF_PWD

# configure build directory
ifndef KERNEL_VER
KERNEL_VER=$(LIVE_KERNEL_VER)
endif

ifndef KERNEL_ARCH
KERNEL_ARCH=$(LIVE_KERNEL_ARCH)
endif

ifndef KERNEL_DIR
KERNEL_DIR=$(LIVE_KERNEL_DIR)
endif

PATCH_IB_PACK_H=0
IB_PACK_PATH=0
UBUNTU_1404_CHK=0
CENTOS72_CHK=0
CENTOS73_CHK=0
CENTOS73PLUS_CHK=0
CENTOS72_514_CHK=0
CENTOS_CHK=$(shell cat /proc/version | grep -c -o centos)
UBUNTU_CHK=$(shell cat /etc/*-release | grep -c -o Ubuntu)
SUSE_CHK=$(shell cat /etc/*-release | grep -c -o SUSE)
OEL_CHK=$(shell cat /etc/*-release | grep -c -o "Oracle Linux")

ifeq ($(CENTOS_CHK),0)
CENTOS_CHK=$(shell cat /etc/*-release | grep -c -o redhat)
endif
ifneq ($(CENTOS_CHK),0)
CENTOS6X_CHK=$(shell cat /etc/redhat-release | grep -c -o -e 6.5 -e 6.6 -e 6.7 -e 6.8)
CENTOS72_CHK=$(shell cat /etc/redhat-release | grep -c -o -e 7.2)
CENTOS73_CHK=$(shell cat /etc/redhat-release | grep -c -o -e 7.3)
endif
ifneq ($(CENTOS72_CHK),0)
CENTOS72PLUS_DEFS=-DCENTOS72PLUS
EXTRA_CFLAGS+=$(CENTOS72PLUS_DEFS)
CENTOS72_514_CHK=$(shell cat /proc/version | grep -c -o -e 3.10.0-514)
endif
ifneq ($(CENTOS73_CHK),0)
CENTOS72PLUS_DEFS=-DCENTOS72PLUS
EXTRA_CFLAGS+=$(CENTOS72PLUS_DEFS)
CENTOS72_514_CHK=$(shell cat /etc/redhat-release | grep -c -o -e 7.3)
endif
ifneq ($(CENTOS72_514_CHK),0)
OFED_VERSION=3.4
endif


RDMA_DIR=/lib/modules/$(shell uname -r)/build/include/rdma
RDMA_ORIG_DIR=/lib/modules/$(shell uname -r)/build/include/rdma.orig
UAPI_RDMA_DIR=/lib/modules/$(shell uname -r)/build/include/uapi/rdma
UAPI_RDMA_ORIG_DIR=/lib/modules/$(shell uname -r)/build/include/uapi/rdma.orig

ifneq ($(UBUNTU_CHK),0)
UBUNTU_1404_CHK=$(shell cat /etc/*release | grep -c -o -e 14.04 -e 16.04)
MOD_SYMVER= /usr/src/linux-headers-$(shell uname -r)/Module.symvers
MOD_SYMVER_ORIG= /usr/src/linux-headers-$(shell uname -r)/Module.symvers.orig
DKMS_OFED_DIR=/var/lib/dkms/mlnx-ofed-kernel/$(OFED_VERSION)/build/
MOFED_FILE=mofed_ksym_fix_ubuntu.sh
KERNEL_COMPILE_DIR=/lib/modules/`uname -r`/updates/dkms
CREATE_MOD_SYMVERS=/var/lib/dkms/mlnx-ofed-kernel/$(OFED_VERSION)/build/ofed_scripts/create_Module.symvers.sh
UBUNTU_DEFS=-DUBUNTU
EXTRA_CFLAGS+=$(UBUNTU_DEFS)
PATCH_FILE=./ib_addr_patch.txt
endif
ifneq ($(UBUNTU_1404_CHK),0)
UBUNTU1404_DEFS=-DUBUNTU_1404
EXTRA_CFLAGS+=$(UBUNTU1404_DEFS)
endif

ifneq ($(CENTOS_CHK),0)
MOD_SYMVER=/usr/src/kernels/$(shell uname -r)/Module.symvers
MOD_SYMVER_ORIG=/usr/src/kernels/$(shell uname -r)/Module.symvers.orig
DKMS_OFED_DIR=/usr/src/ofa_kernel-$(OFED_VERSION)/build
MOFED_FILE=mofed_ksym_fix_centos.sh
KERNEL_COMPILE_DIR=/lib/modules/`uname -r`/extra/mlnx-ofa_kernel/drivers
CREATE_MOD_SYMVERS=/usr/src/ofa_kernel-$(OFED_VERSION)/ofed_scripts/create_Module.symvers.sh
CENTOS_DEFS=-DCENTOS
EXTRA_CFLAGS+=$(CENTOS_DEFS)
PATCH_FILE=./ib_addr_patch.txt
endif
ifneq ($(CENTOS72_514_CHK),0)
CENTOS72_514_DEFS=-DCENTOS72_514
EXTRA_CFLAGS+=$(CENTOS72_514_DEFS)
PATCH_FILE=$(PATCH_THIS_FILE)
endif
ifneq ($(CENTOS6X_CHK),0)
CENTOS6X_DEFS=-DCENTOS6X
EXTRA_CFLAGS+=$(CENTOS6X_DEFS)
PATCH_IB_PACK_H=/usr/src/ofa_kernel-$(OFED_VERSION)/include/rdma/ib_pack.h
IB_PACK_PATH=./ib_pack.patch
PATCH_FILE=./ib_addr_patch.suse
endif

ifneq ($(SUSE_CHK),0)
SUSE_KERNEL_SRC=`readlink /lib/modules/\`uname -r\`/source`
SUSE_KERNEL_BUILD=`readlink /lib/modules/\`uname -r\`/build`
RDMA_DIR=$(SUSE_KERNEL_SRC)/include/rdma
RDMA_ORIG_DIR=$(SUSE_KERNEL_SRC)/include/rdma.orig
UAPI_RDMA_DIR=$(SUSE_KERNEL_SRC)/include/uapi/rdma
UAPI_RDMA_ORIG_DIR=$(SUSE_KERNEL_SRC)/include/uapi/rdma.orig
MOD_SYMVER= $(SUSE_KERNEL_BUILD)/Module.symvers
MOD_SYMVER_ORIG= $(SUSE_KERNEL_BUILD)/Module.symvers.orig
DKMS_OFED_DIR=/usr/src/ofa_kernel-$(OFED_VERSION)/build
MOFED_FILE=mofed_ksym_fix_suse.sh
KERNEL_COMPILE_DIR=/lib/modules/`uname -r`/updates/drivers
CREATE_MOD_SYMVERS=/usr/src/ofa_kernel-$(OFED_VERSION)/ofed_scripts/create_Module.symvers.sh
SUSE_DEFS=-DSUSE

SUSE_11_4_CHK=$(shell cat /etc/*-release | grep -c -o 11.4)
ifneq ($(SUSE_11_4_CHK),0)
SUSE_DEFS+=-DSUSE_11_4
endif

SUSE_12_2_CHK=$(shell cat /etc/*-release | grep -c -o 12.2)
ifneq ($(SUSE_12_2_CHK),0)
SUSE_DEFS+=-DSUSE_12_2
endif

EXTRA_CFLAGS+=$(SUSE_DEFS)
PATCH_FILE=./ib_addr_patch.suse
endif

ifneq ($(OEL_CHK),0)
PATCH_FILE=./ib_addr_patch.txt
KERNEL_COMPILE_DIR=/lib/modules/`uname -r`/extra/mlnx-ofa_kernel/drivers
CREATE_MOD_SYMVERS=/usr/src/ofa_kernel-$(OFED_VERSION)/ofed_scripts/create_Module.symvers.sh
DKMS_OFED_DIR=/usr/src/ofa_kernel-$(OFED_VERSION)/build
MOD_SYMVER=/usr/src/kernels/$(shell uname -r)/Module.symvers
MOD_SYMVER_ORIG=/usr/src/kernels/$(shell uname -r)/Module.symvers.orig
MOFED_FILE=mofed_ksym_fix_centos.sh
OEL_7_1_CHK=$(shell cat /etc/*-release | grep -c -o 7.1)
ifneq ($(OEL_7_1_CHK),0)
OEL_DEFS+=-DOEL_7_1
endif
EXTRA_CFLAGS+=$(OEL_DEFS)
endif

PATCH_THIS_FILE=/usr/src/ofa_kernel-$(OFED_VERSION)/include/rdma/ib_addr.h

OFED_DEFS=
STR_3_15_0=3.15.0
KERNEL_VERS=$(shell uname -r)
BASH_VERSION=0
BASH_VERSION=$(shell echo $BASH_VERSION)
BELOW_3_15_VERSION=$(shell echo "$(KERNEL_VERS)\n3.15.0" |  sort -g -r)
CHECK_FOR_KERN=$(shell echo $(BELOW_3_15_VERSION) | cut -d" " -f2)
ifneq ($(BASH_VERSION),0)
CMP_VER_STR=$(shell echo "$(KERNEL_VERS) 3.15.0")
BELOW_3_15_VERSION=$(shell echo $(CMP_VER_STR)|tr " " "\n"|sort -r|tr "\n" " ")
CHECK_FOR_KERN=$(shell echo $(BELOW_3_15_VERSION) | cut -d" " -f2)
endif
ifneq ($(CHECK_FOR_KERN),3.15.0)
ifndef OFED_DIR
OFA=/usr/src/ofa_kernel-$(OFED_VERSION)/
else
OFA=$(OFED_DIR)
endif
OFA_INCLUDE=-I$(OFA)/include -I$(OFA)/include/rdma
OFED_DEFS=-DOFED_BUILD
endif

ofed:
	@echo "$(CHECK_FOR_KERN) $(OFED_DEFS)"; \
	if [ "$(STR_3_15_0)" != "$(CHECK_FOR_KERN)" ]; \
	then echo "Kernel Version less then $(STR_3_15_0)"; \
	if [ ! -d $(RDMA_ORIG_DIR) ] ; then mv $(RDMA_DIR) $(RDMA_ORIG_DIR) ; \
	mv $(UAPI_RDMA_DIR) $(UAPI_RDMA_ORIG_DIR); \
	patch $(PATCH_THIS_FILE) < $(PATCH_FILE); \
	patch $(PATCH_IB_PACK_H) < $(IB_PACK_PATH); \
	cd $(KERNEL_COMPILE_DIR); \
	$(CREATE_MOD_SYMVERS); \
	if [ ! -d $(DKMS_OFED_DIR) ] ; then mkdir $(DKMS_OFED_DIR); fi; \
	cp ./Module.symvers $(DKMS_OFED_DIR); \
	cp $(MOD_SYMVER) $(MOD_SYMVER_ORIG); \
	mkdir -p /root/tmp; \
	cd $(PAVILION_NVMEOF_PWD); \
	./$(MOFED_FILE); \
	cp /tmp/Module.symvers.new $(MOD_SYMVER); \
	/etc/init.d/openibd stop; \
	/etc/init.d/openibd start; \
	if [ -d $(DKMS_OFED_DIR) ] ; then cp $(DKMS_OFED_DIR)/Module.symvers . ; fi; \
	fi; \
	fi;


TARGETDIR=$(KERNEL_VER)/$(KERNEL_ARCH)

$(TARGETDIR):
	@mkdir -p $(TARGETDIR)

targetdir: $(TARGETDIR)

# build the driver
#
ifneq ($(KERNELRELEASE),)
    # call from kernel build system
include $(PAVILION_NVMEOF_PWD)/config.mk
EXTRA_CFLAGS+=-ggdb -g3 -Wall -Werror $(COMMON_INC) $(OFED_DEFS) $(OFA_INCLUDE)


obj-$(CONFIG_NVME_CORE)                 += nvme-core.o
nvme-core-y                             := core.o
obj-$(CONFIG_NVME_FABRICS)              += nvme-fabrics.o
nvme-fabrics-y                          := fabrics.o
obj-$(CONFIG_NVME_RDMA)                 += nvme-rdma.o
nvme-rdma-y                             := rdma.o

else

PAVILION_NVMEOF_PWD  := $(shell pwd)
export PAVILION_NVMEOF_PWD

SRC_FILES=	core.c		\
		fabrics.c	\
		rdma.c

modules:
	@if [ ! -d $(TARGETDIR) ] ; then make targetdir ; fi ; \
	Files=`ls *.c *.h Makefile config.mk` ; \
	for f in $$Files; do \
		ln -sf ../../$$f $(TARGETDIR) ; \
	done ; \
	#unset ARCH ;
	$(MAKE) $(VERBOSE) -C $(KERNEL_DIR) M=$(PAVILION_NVMEOF_PWD)/$(TARGETDIR) modules ;\
	#$(CC) pds_no_latency.c -o pds_no_latency ;\
	#$(MAKE) $(VERBOSE) -C $(KERNEL_DIR) M=$(PWD) modules ; \
        if [ $$? -ne 0 ]; then \
            exit 1; \
        fi; \

.PHONY:	root_test
root_test:
	@if [ `id -u` != "0" ]; then \
		echo ""; \
		echo "ERROR - You must be root"; \
		echo ""; \
		exit 1; \
	fi

modules_install: root_test
	@$(MAKE) $(VERBOSE) -C $(KERNEL_DIR) M=$(PAVILION_NVMEOF_PWD)/$(TARGETDIR) \
		LDDINC=$(PAVILION_NVMEOF_PWD)/../include modules_install ; \
        if [ $$? -ne 0 ]; then \
            exit 1; \
	else \
	    echo ""; \
	    echo "Installed Pavilion nvmeof kernel module file (not loaded)"; \
	    cp pds_no_latency /bin; \
        fi;
	@-depmod -a

endif

clean:
	@rm -rf *.o *~ core .depend .*.cmd *.mod.c pds_no_latency .tmp_versions $(TARGETDIR)

clobber:	clean

depend .depend dep:		$(TARGETDIR)
	$(CC) $(CFLAGS) -M *.c > $(TARGETDIR)/.depend

install: modules_install
ifeq ($(KERNEL_VER).$(KERNEL_ARCH),$(LIVE_KERNEL_VER).$(LIVE_KERNEL_ARCH))
	@grep -q -w "^nvme-core" /proc/modules; \
	if [ $$? -eq 0 ]; then \
	    rmmod nvme-core.ko; \
	    if [ $$? -ne 0 ]; then \
		    echo "WARNING - rmmod nvme-core failed"; \
		    echo ""; \
	    else \
		    echo "Unloaded nvme-core kernel module"; \
	    fi; \
	fi;
	@grep -q -w "^nvme-fabrics" /proc/modules; \
        if [ $$? -eq 0 ]; then \
            rmmod nvme-fabrics.ko; \
            if [ $$? -ne 0 ]; then \
                    echo "WARNING - rmmod nvme-core failed"; \
                    echo ""; \
            else \
                    echo "Unloaded nvme-core kernel module"; \
            fi; \
        fi;
	@grep -q -w "^nvme-rdma" /proc/modules; \
        if [ $$? -eq 0 ]; then \
            rmmod nvme-rdma.ko; \
            if [ $$? -ne 0 ]; then \
                    echo "WARNING - rmmod nvme-core failed"; \
                    echo ""; \
            else \
                    echo "Unloaded nvme-core kernel module"; \
            fi; \
        fi;
endif
	echo "";

uninstall: root_test
	@echo ""
	@if [ ! -e /lib/modules/$(KERNEL_VER)/extra/nvme-core.ko ]; then \
	    echo "ERROR - driver not found to uninstall"; \
	    echo ""; \
	    exit 1; \
	fi;
ifeq ($(KERNEL_VER).$(KERNEL_ARCH),$(LIVE_KERNEL_VER).$(LIVE_KERNEL_ARCH))
	@grep -q -w "^nvme-" /proc/modules; \
	if [ $$? -eq 0 ]; then \
	    rmmod nvme-core.ko; \
	    if [ $$? -ne 0 ]; then \
		    echo "WARNING - rmmod nvme-core failed"; \
		    echo ""; \
	    else \
		    echo "Unloaded nvme-core kernel module"; \
	    fi; \
	fi;
endif
	@rm -f /lib/modules/$(KERNEL_VER)/extra/nvme-core.ko;
	@rm -f /lib/modules/$(KERNEL_VER)/extra/nvme-fabrics.ko;
	@rm -f /lib/modules/$(KERNEL_VER)/extra/nvme-rdma.ko;
	@echo "Removed nvme-core.ko nvme-fabrics.ko nvme-rdma.ko kernel module file";
	@rm -f /bin/pds_no_latency;
	@echo "";
	@-depmod -a
