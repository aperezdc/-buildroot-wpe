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
WPEWEBKIT_DEPENDENCIES = gstreamer1 gst1-libav gst1-plugins-base \
	gst1-plugins-good gst1-plugins-bad host-ruby host-flex host-bison \
	host-gperf harfbuzz icu jpeg libegl libepoxy libgcrypt libsecret \
	libsoup libxml2 libxslt sqlite webp wpebackend
WPEWEBKIT_CONF_OPTS = \
	-DPORT=WPE

# ARM needs NEON for JIT
# i386 & x86_64 don't seem to have any special requirements
ifeq ($(BR2_ARM_CPU_HAS_NEON)$(BR2_i386)$(BR2_x86_64),y)
WPEWEBKIT_CONF_OPTS += -DENABLE_JIT=ON
else
WPEWEBKIT_CONF_OPTS += -DENABLE_JIT=OFF
endif

$(eval $(cmake-package))
