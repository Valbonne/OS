-include .config

# Configuration
## Architecture to build Redox for (aarch64, i686, or x86_64)
ARCH?=x86_64
## Enable to use binary prefix (much faster)
PREFIX_BINARY?=1
## Enable to use binary packages (much faster)
REPO_BINARY?=0
## Name of the configuration to include in the image name e.g. desktop or server
CONFIG_NAME?=desktop
## Select filesystem config
FILESYSTEM_CONFIG?=config/$(ARCH)/$(CONFIG_NAME).toml
## Filesystem size in MB (default comes from filesystem_size in the FILESYSTEM_CONFIG)
FILESYSTEM_SIZE?=$(shell grep filesystem_size $(FILESYSTEM_CONFIG) | cut -d' ' -f3)
## Flags to pass to redoxfs-mkfs. Add --encrypt to set up disk encryption
REDOXFS_MKFS_FLAGS?=
## Set to 1 to enable Podman build, any other value will disable it
PODMAN_BUILD?=0
## The containerfile to use for the Podman base image
CONTAINERFILE?=podman/redox-base-containerfile

# Per host variables
# TODO: get host arch automatically
HOST_ARCH=x86_64
HOST_CARGO=env --unset=RUSTUP_TOOLCHAIN cargo
UNAME := $(shell uname)
ifeq ($(UNAME),Darwin)
	FUMOUNT=sudo umount
	export NPROC=sysctl -n hw.ncpu
	export REDOX_MAKE=make
	PREFIX_BINARY=0
	VB_AUDIO=coreaudio
	VBM=/Applications/VirtualBox.app/Contents/MacOS/VBoxManage
	HOST_TARGET ?= $(HOST_ARCH)-apple-darwin
else ifeq ($(UNAME),FreeBSD)
	FUMOUNT=sudo umount
	export NPROC=sysctl -n hw.ncpu
	export REDOX_MAKE=gmake
	PREFIX_BINARY=0
	VB_AUDIO=pulse # To check, will probaly be OSS on most setups
	VBM=VBoxManage
	HOST_TARGET ?= $(HOST_ARCH)-unknown-freebsd
else
	FUMOUNT=fusermount -u
	export NPROC=nproc
	export REDOX_MAKE=make
	VB_AUDIO=pulse
	VBM=VBoxManage
	HOST_TARGET ?= $(HOST_ARCH)-unknown-linux-gnu
endif

# Automatic variables
ROOT=$(CURDIR)
export RUST_COMPILER_RT_ROOT=$(ROOT)/rust/src/llvm-project/compiler-rt
export XARGO_RUST_SRC=$(ROOT)/rust/src

## Userspace variables
export TARGET=$(ARCH)-unknown-redox
BUILD=build/$(ARCH)/$(CONFIG_NAME)
INSTALLER=installer/target/release/redox_installer
ifeq ($(REPO_BINARY),0)
INSTALLER+=--cookbook=cookbook
REPO_TAG=$(BUILD)/repo.tag
endif

## Cross compiler variables
AR=$(TARGET)-gcc-ar
AS=$(TARGET)-as
CC=$(TARGET)-gcc
CXX=$(TARGET)-g++
LD=$(TARGET)-ld
NM=$(TARGET)-gcc-nm
OBJCOPY=$(TARGET)-objcopy
OBJDUMP=$(TARGET)-objdump
RANLIB=$(TARGET)-gcc-ranlib
READELF=$(TARGET)-readelf
STRIP=$(TARGET)-strip

## Rust cross compile variables
export AR_$(subst -,_,$(TARGET))=$(TARGET)-ar
export CC_$(subst -,_,$(TARGET))=$(TARGET)-gcc
export CXX_$(subst -,_,$(TARGET))=$(TARGET)-g++


## If Podman is being used, a container is required
ifeq ($(PODMAN_BUILD),1)
CONTAINER_TAG=build/container.tag
else
CONTAINER_TAG=
endif
