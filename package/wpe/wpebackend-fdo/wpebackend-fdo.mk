################################################################################
#
# wpebackend-fdo
#
################################################################################

WPEBACKEND_FDO_VERSION = 0         # TODO
WPEBACKEND_FDO_SITE = file:///tmp  # TODO
WPEBACKEND_FDO_LICENSE = BSD-2-Clause
WPEBACKEND_FDO_DEPENDENCIES = libegl wpebackend wayland libglib2

$(eval $(cmake-package))
