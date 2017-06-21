################################################################################
#
# smem
#
################################################################################

SMEM_VERSION = 1.4
SMEM_SOURCE = smem-$(SMEM_VERSION).tar.gz
SMEM_SITE = https://www.selenic.com/smem/download
SMEM_LICENSE = GPLv2+
SMEM_LICENSE_FILES = COPYING

ifneq ($(BR2_PACKAGE_SMEM_ONLY_SMEMCAP),y)
SMEM_DEPENDENCIES += python2
endif

define SMEM_BUILD_CMDS
	PATH=$(BR_PATH) $(TARGET_CC) $(TARGET_CFLAGS) -o $(@D)/smemcap $(@D)/smemcap.c $(TARGET_LDFLAGS)
endef

ifeq ($(BR2_PACKAGE_SMEM_ONLY_SMEMCAP),y)
define SMEM_INSTALL_TARGET_CMDS
	$(INSTALL) -D $(@D)/smemcap $(TARGET_DIR)/usr/bin/smemcap
endef
else
define SMEM_INSTALL_TARGET_CMDS
	$(INSTALL) -D $(@D)/smemcap $(TARGET_DIR)/usr/bin/smemcap
	$(INSTALL) -D $(@D)/smem $(TARGET_DIR)/usr/bin/smem
endef
endif

$(eval $(generic-package))
