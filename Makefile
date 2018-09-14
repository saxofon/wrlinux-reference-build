# Default settings
HOSTNAME 	?= $(shell hostname)
USER		?= $(shell whoami)

# Optional configuration
-include hostconfig-$(HOSTNAME).mk
-include userconfig-$(USER).mk

TOP := $(shell pwd)

SHELL := /bin/bash

# Define V=1 to echo everything
V ?= 0
ifneq ($(V),1)
	Q=@
endif

RM = $(Q)rm -f

WRL_URL ?= https://github.com/WindRiver-Labs/wrlinux-x.git
WRL_REL ?= WRLINUX_10_17_BASE_UPDATE0011

MACHINE=qemuarm64

DISTRO=wrlinux

IMAGE=wrlinux-image-glibc-std

WRLS_OPTS += --dl-layers
WRLS_OPTS += --accept-eula yes
WRLS_OPTS += --distros $(DISTRO)
WRLS_OPTS += --machines $(MACHINE)
#WRLS_OPTS += --templates feature/test

define bitbake
	cd build ; \
	source ./environment-setup-x86_64-wrlinuxsdk-linux ; \
	source ./oe-init-build-env ; \
	bitbake $(1)
endef

define bitbake-task
	cd build ; \
	source ./environment-setup-x86_64-wrlinuxsdk-linux ; \
	source ./oe-init-build-env ; \
	bitbake $(1) -c $(2)
endef

all: image

# create wrlinux platform
#
.PHONY: build
build:
	$(Q)if [ ! -d $@ ]; then \
		mkdir -p $@ ; \
		cd $@ ; \
		git clone --branch $(WRL_REL) $(WRL_URL) ; \
		./wrlinux-x/setup.sh $(WRLS_OPTS) ; \
	fi

# create bitbake build
#
.PHONY: build/build
build/build: build $(LAYERS)
	$(Q)if [ ! -d $@ ]; then \
		cd build ; \
		source ./environment-setup-x86_64-wrlinuxsdk-linux ; \
		source ./oe-init-build-env ; \
		$(foreach layer, $(LAYERS), bitbake-layers add-layer $(layer);) \
	fi

bbs: build/build
	$(Q)cd build ; \
	source ./environment-setup-x86_64-wrlinuxsdk-linux ; \
	source ./oe-init-build-env ; \
	bash || true

image: build/build
	$(call bitbake, $(IMAGE))

sdk: build/build
	$(call bitbake-task, $(IMAGE), populate_sdk)

esdk: build/build
	$(call bitbake-task, $(IMAGE), populate_sdk_ext)

clean:
	$(RM) -r build/build

distclean:
	$(RM) -r build
