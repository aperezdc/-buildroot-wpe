################################################################################
#
# wpebackend-fix-symlink
#
################################################################################

WPEBACKEND_FIX_SYMLINK_VERSION := 1
WPEBACKEND_FIX_SYMLINK_SOURCE :=
WPEBACKEND_FIX_SYMLINK_SITE :=
WPEBACKEND_FIX_SYMLINK_SITE_METHOD := local
WPEBACKEND_FIX_SYMLINK_INSTALL_STAGING := NO
WPEBACKEND_FIX_SYMLINK_INSTALL_TARGET := YES
WPEBACKEND_FIX_SYMLINK_DEPENDENCIES :=

ifeq ($(BR2_PACKAGE_WPEBACKEND_RDK),y)
  WPEBACKEND_FIX_SYMLINK_DEPENDENCIES += wpebackend-rdk
endif
ifeq ($(BR2_PACKAGE_WPEBACKEND_SHM),y)
  WPEBACKEND_FIX_SYMLINK_DEPENDENCIES += wpebackend-shm
endif

WPEBACKEND_FIX_SYMLINK_EXTRACT_CMDS := @:
WPEBACKEND_FIX_SYMLINK_CONFIGURE_CMDS := @:
WPEBACKEND_FIX_SYMLINK_BUILD_CMDS := @:

ifeq ($(BR2_PACKAGE_WPEWEBKIT_DEFAULT_WPEBACKEND),)
  $(error No default WPE backend set (BR2_PACKAGE_WPEWEBKIT_DEFAULT_WPEBACKEND is empty))
endif

define WPEBACKEND_FIX_SYMLINK_INSTALL_TARGET_CMDS
	ln -sf libWPEBackend-$(BR2_PACKAGE_WPEWEBKIT_DEFAULT_WPEBACKEND).so \
		$(TARGET_DIR)/usr/lib/libWPEBackend-default.so
endef

$(eval $(generic-package))
