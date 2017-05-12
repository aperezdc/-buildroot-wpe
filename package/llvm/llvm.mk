################################################################################
#
# llvm
#
################################################################################

LLVM_VERSION = 4.0.0
LLVM_SITE = http://llvm.org/releases/$(LLVM_VERSION)
LLVM_SOURCE = llvm-$(LLVM_VERSION).src.tar.xz
LLVM_LICENSE = University of Illinois/NCSA Open Source License
LLVM_LICENSE_FILES = LICENSE.TXT
LLVM_INSTALL_STAGING = YES
LLVM_INSTALL_TARGET = YES

HOST_LLVM_DEPENDENCIES = host-libxml2 host-zlib host-python host-cmake
LLVM_DEPENDENCIES = libxml2 zlib host-python host-cmake

# Determine the name of the LLVM target to enable depending on
# the Buildroot target settings.
#
ifeq ($(BR2_i386),y)
  _LLVM_TARGET_ARCH := X86
else ifeq ($(BR2_x86_64),y)
  _LLVM_TARGET_ARCH := X86
else ifeq ($(BR2_arm),y)
  _LLVM_TARGET_ARCH := ARM
else ifeq ($(BR2_armeb),y)
  _LLVM_TARGET_ARCH := ARM
else ifeq ($(BR2_aarch64),y)
  _LLVM_TARGET_ARCH := AArch64
else ifeq ($(BR2_mips),y)
  _LLVM_TARGET_ARCH := Mips
else ifeq ($(BR2_mipsel),y)
  _LLVM_TARGET_ARCH := Mips
else ifeq ($(BR2_mips64),y)
  _LLVM_TARGET_ARCH := Mips
else ifeq ($(BR2_mips64el),y)
  _LLVM_TARGET_ARCH := Mips
else ifeq ($(BR2_powerpc),y)
  _LLVM_TARGET_ARCH := PowerPC
else ifeq ($(BR2_powerpc64),y)
  _LLVM_TARGET_ARCH := PowerPC
else ifeq ($(BR2_powerpc64le),y)
  _LLVM_TARGET_ARCH := PowerPC
else ifeq ($(BR2_sparc),y)
  _LLVM_TARGET_ARCH := Sparc
else
  $(error Target architecture not supported by LLVM)
endif


# List of build options at:
#    http://llvm.org/docs/CMake.html
#
_LLVM_COMMON_CONF_OPTS := \
  -DLLVM_DEFAULT_TARGET_TRIPLE=$(GNU_TARGET_NAME) \
  -DLLVM_HOST_TRIPLE=$(GNU_TARGET_NAME) \
  -DLLVM_TARGETS_TO_BUILD=$(_LLVM_TARGET_ARCH) \
  -DLLVM_TARGET_ARCH=$(_LLVM_TARGET_ARCH) \
  -DLLVM_OPTIMIZED_TABLEGEN=YES \
  -DLLVM_ENABLE_ZLIB=YES \
  -DLLVM_INCLUDE_TOOLS=YES \
  -DLLVM_INCLUDE_UTILS=NO \
  -DLLVM_INCLUDE_EXAMPLES=NO \
  -DLLVM_INCLUDE_TESTS=NO \
  -DLLVM_BUILD_TESTS=NO \
  -DLLVM_BUILD_RUNTIME=NO \
  -DLLVM_ENABLE_PROJECTS=''


# The Go bindings have no CMake rules at the moment, but better remove the
# check preventively. For now building the Go bindings is not supported.
#
_LLVM_COMMON_CONF_OPTS += \
  -DGO_EXECUTABLE=GO_EXECUTABLE-NOTFOUND \
  -DOCAMLFIND=OCAMLFIND-NOTFOUND


# Building per-component shared libraries is NOT recommended by upstream.
# The all-in-one libLLVM-<version>.so is enabled with a different setting.
_LLVM_COMMON_CONF_OPTS += \
  -DBUILD_SHARED_LIBS=NO \
  -DLLVM_BUILD_LLVM_DYLIB=$(if $(BR2_STATIC_LIBS),NO,YES)


# Start with the common configuration options for both host and target builds.
HOST_LLVM_CONF_OPTS = $(_LLVM_COMMON_CONF_OPTS)
LLVM_CONF_OPTS = $(_LLVM_COMMON_CONF_OPTS)


# If a host-build of LLVM has been done, use its llvm-tblgen executable and
# save a bit of build time. The LLVM build system itself builds a host-native
# version if this option is not passed.
#
ifeq ($(BR2_PACKAGE_HOST_LLVM),y)
  LLVM_DEPENDENCIES += host-llvm
  LLVM_CONF_OPTS += -DLLVM_TABLEGEN='$(HOST_DIR)/usr/bin/llvm-tblgen'
endif

ifeq ($(BR2_PACKAGE_LLVM_ENABLE_FFI),y)
  LLVM_DEPENDENCIES += libffi
  LLVM_CONF_OPTS += -DLLVM_ENABLE_FFI=YES
else
  LLVM_CONF_OPTS += -DLLVM_ENABLE_FFI=NO
endif

ifeq ($(BR2_PACKAGE_LLVM_ENABLE_RTTI),y)
  LLVM_CONF_OPTS += -DLLVM_ENABLE_RTTI=YES
else
  LLVM_CONF_OPTS += -DLLVM_ENABLE_RTTI=NO
endif

ifeq ($(BR2_PACKAGE_LLVM_ENABLE_EH),y)
  LLVM_CONF_OPTS += -DLLVM_ENABLE_EH=YES
else
  LLVM_CONF_OPTS += -DLLVM_ENABLE_EH=NO
endif

# LLVM expects to always be built in a separate directory.
LLVM_SUPPORTS_IN_SOURCE_BUILD = NO

$(eval $(cmake-package))


# XXX: LLVM does include some support for building native tools. This is used
#      to build e.g. llvm-config, and a host-native llvm-tblgen if needed.
#      Unfortunately, Buildroot is overzealous about passing the parameters
#      needed for cross-building, and the CMake configuration for the native
#      tools ends up using the cross-toolchain. Once "cmake-package" has
#      defined LLVM_*_CMDS, this adds:
#
#        - A call to CMake which resets CMAKE_{C,CXX,ASM}_COMPILER with the
#          paths to the host-native ones. Note that using the *_NOCCACHE
#          variables is needed, otherwise CMake will choke.
#
#        - The file "BuildVariables.inc" is copied over from the cross-build
#          directory to the native one. This way a new "llvm-config" which
#          can run on the build host returns information about the target
#          build which gets installed in the sysroot. This is done as an
#          appended build command. Note that Make has to be re-invoked to
#          rebuild after copying the file over.
#
#        - Last but not least, "llvm-config" is copied into the sysroot with
#          the target triple prefix, because packages using sane build systems
#          will first try that.
#
# This is one of those disgusting hacks of which one ends up being proud of.
#
LLVM_CONFIGURE_CMDS += \
  && cd $(LLVM_BUILDDIR)/NATIVE \
  && PATH=$(BR_PATH) $(LLVM_CONF_ENV) $(BR2_CMAKE) $(LLVM_SRCDIR) \
     -DCMAKE_C_COMPILER='$(HOSTCC_NOCCACHE)' \
     -DCMAKE_ASM_COMPILER='$(HOSTCC_NOCCACHE)' \
     -DCMAKE_CXX_COMPILER='$(HOSTCXX_NOCCACHE)'

LLVM_BUILD_CMDS += \
  && cp $(LLVM_BUILDDIR)/tools/llvm-config/BuildVariables.inc \
     $(LLVM_BUILDDIR)/NATIVE/tools/llvm-config/BuildVariables.inc \
  && $(HOST_MAKE_ENV) $(LLVM_MAKE_ENV) $(LLVM_MAKE) $(LLVM_MAKE_OPTS) \
     -C $(LLVM_BUILDDIR)/NATIVE llvm-config

LLVM_INSTALL_STAGING_CMDS += \
  && install -Dm755 $(LLVM_BUILDDIR)/NATIVE/bin/llvm-config \
     $(STAGING_DIR)/usr/bin/$(GNU_TARGET_NAME)-llvm-config

# If only llvm-tblgen is to be built, define the install commands to directly
# copy over the binary, and fixup the commands using for building it *after*
# cmake-package has created the variables and targets.
#
ifeq ($(BR2_PACKAGE_HOST_LLVM_TBLGEN_ONLY),y)
  define HOST_LLVM_INSTALL_CMDS
  install -Dm755 $(HOST_LLVM_BUILDDIR)/bin/llvm-tblgen $(HOST_DIR)/usr/bin/llvm-tblgen
  endef
endif

$(eval $(host-cmake-package))

ifeq ($(BR2_PACKAGE_HOST_LLVM_TBLGEN_ONLY),y)
  HOST_LLVM_BUILD_CMDS += llvm-tblgen
endif
