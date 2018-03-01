################################################################################
#
# wpewebkit
#
################################################################################

WPEWEBKIT_VERSION = 2.18.0.9
WPEWEBKIT_SITE = http://people.igalia.com/aperez/files/wpe
WPEWEBKIT_SOURCE = wpewebkit-$(WPEWEBKIT_VERSION).tar.xz
WPEWEBKIT_INSTALL_STAGING = YES
WPEWEBKIT_LICENSE = LGPv2.1+, BSD-2-Clause
WPEWEBKIT_LICENSE_FILES = \
	Source/WebCore/LICENSE-APPLE \
	Source/WebCore/LICENSE-LGPL-2.1
WPEWEBKIT_DEPENDENCIES = host-ruby host-flex host-bison host-gperf \
	harfbuzz icu jpeg libegl libepoxy libgcrypt libsecret libsoup libxml2 \
	libxslt sqlite webp wpebackend
WPEWEBKIT_CONF_OPTS = \
	-DPORT=WPE

# ARM needs NEON for JIT
# i386 & x86_64 don't seem to have any special requirements
ifeq ($(BR2_ARM_CPU_HAS_NEON)$(BR2_i386)$(BR2_x86_64),y)
WPEWEBKIT_CONF_OPTS += -DENABLE_JIT=ON
else
WPEWEBKIT_CONF_OPTS += -DENABLE_JIT=OFF
endif

ifeq ($(BR2_PACKAGE_WPEWEBKIT_MULTIMEDIA),y)
WPEWEBKIT_CONF_OPTS += \
	-DENABLE_VIDEO=ON \
	-DENABLE_WEB_AUDIO=ON
WPEWEBKIT_DEPENDENCIES += gstreamer1 gst1-libav gst1-plugins-base \
	gst1-plugins-good gst1-plugins-bad
else
# ENABLE_MEDIA_STREAM has to be explicitly disabled because there is a missing
# feature dependency in the WPEWebKit CMake files. This can be removed once
# https://bugs.webkit.org/show_bug.cgi?id=174940 makes it into a release.
WPEWEBKIT_CONF_OPTS += \
	-DENABLE_VIDEO=OFF \
	-DENABLE_WEB_AUDIO=OFF \
	-DENABLE_MEDIA_STREAM=OFF
endif

ifeq ($(BR2_PACKAGE_WPEWEBKIT_WEBDRIVER),y)
WPEWEBKIT_CONF_OPTS += -DENABLE_WEBDRIVER=ON
else
WPEWEBKIT_CONF_OPTS += -DENABLE_WEBDRIVER=OFF
endif

$(eval $(cmake-package))
