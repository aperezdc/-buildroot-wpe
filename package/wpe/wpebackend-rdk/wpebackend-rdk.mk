################################################################################
#
# wpebackend-rdk
#
################################################################################

WPEBACKEND_RDK_VERSION = bff90468cbda5276357ccb34a3674b62c65e0150
WPEBACKEND_RDK_SITE = $(call github,WebPlatformForEmbedded,WPEBackend-rdk,$(WPEBACKEND_RDK_VERSION))
WPEBACKEND_RDK_LICENSE = BSD-2-Clause
WPEBACKEND_RDK_DEPENDENCIES = libegl libinput wpebackend

# The following require dependencies which are not available in Buildroot.
WPEBACKEND_RDK_CONF_OPTS = \
	-DUSE_BACKEND_BCM_NEXUS=OFF \
	-DUSE_BACKEND_BCM_NEXUS_WAYLAND=OFF \
	-DUSE_BACKEND_INTEL_CE=OFF \
	-DUSE_BACKEND_WPEFRAMEWORK=OFF \
	-DUSE_BACKEND_WESTEROS=OFF \
	-DUSE_HOLE_PUNCH_GSTREAMER=OFF \
	-DUSE_INPUT_WAYLAND=OFF \
	-DUSE_VIRTUAL_KEYBOARD=OFF \
	-DUSE_WESTEROS_SINK=OFF

# The currently supported build modes (bcm-rpi, wayland-egl) both require
# usage of libinput, which is always built with udev support in Buildroot.
WPEBACKEND_RDK_CONF_OPTS += -DUSE_INPUT_LIBINPUT=ON -DUSE_INPUT_UDEV=ON

ifeq ($(BR2_PACKAGE_WPEBACKEND_RDK_BCM_RPI),y)
WPEBACKEND_RDK_CONF_OPTS += -DUSE_BACKEND_BCM_RPI=ON
else
WPEBACKEND_RDK_CONF_OPTS += -DUSE_BACKEND_BCM_RPI=OFF
endif

ifeq ($(BR2_PACKAGE_WPEBACKEND_RDK_WAYLAND_EGL),y)
WPEBACKEND_RDK_CONF_OPTS += -DUSE_BACKEND_WAYLAND_EGL=ON
else
WPEBACKEND_RDK_CONF_OPTS += -DUSE_BACKEND_WAYLAND_EGL=OFF
endif

# The installation makes a libWPEBackend-default.so symlink, but we want to
# control its creation ourselves. Remove it for now.
define BR2_PACKAGE_WPEBACKEND_RDK_REMOVE_SYMLINK
	rm -vf $(TARGET_DIR)/usr/lib/libWPEBackend-default.so
endef

WPEBACKEND_RDK_POST_INSTALL_TARGET_HOOKS += \
	BR2_PACKAGE_WPEBACKEND_RDK_REMOVE_SYMLINK

$(eval $(cmake-package))
