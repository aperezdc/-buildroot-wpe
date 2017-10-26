################################################################################
#
# dinghy
#
################################################################################

DINGHY_VERSION = master
DINGHY_SITE = $(call github,aperezdc,dinghy,$(DINGHY_VERSION))
DINGHY_LICENSE = BSD-2-Clause
DINGHY_DEPENDENCIES += wpewebkit

$(eval $(cmake-package))
