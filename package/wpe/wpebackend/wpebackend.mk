################################################################################
#
# wpebackend
#
################################################################################

WPEBACKEND_VERSION = 0272534fcc3bf1aff56539e20703b8d53a0328cc
WPEBACKEND_SITE = $(call github,WebPlatformForEmbedded,WPEBackend,$(WPEBACKEND_VERSION))
WPEBACKEND_LICENSE = BSD-2-Clause
WPEBACKEND_INSTALL_STAGING = YES
WPEBACKEND_DEPENDENCIES += libegl

$(eval $(cmake-package))
