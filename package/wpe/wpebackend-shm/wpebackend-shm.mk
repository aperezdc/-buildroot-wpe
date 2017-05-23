################################################################################
#
# WPEBackend-shm
#
################################################################################

WPEBACKEND_SHM_VERSION := 0.20170601
WPEBACKEND_SHM_SITE := http://people.igalia.com/aperez/files
WPEBACKEND_SHM_SOURCE := WPEBackend-shm-v$(WPEBACKEND_SHM_VERSION).tar.gz
WPEBACKEND_SHM_DEPENDENCIES := wpebackend wpebackend-implementation wayland libglib2
WPEBACKEND_SHM_PROVIDES := wpebackend-implementation
WPEBACKEND_SHM_SUPPORTS_IN_SOURCE_BUILD := NO
WPEBACKEND_SHM_INSTALL_STAGING := YES
WPEBACKEND_SHM_CONF_OPTS := \
	-DCMAKE_C_FLAGS='$(TARGET_CFLAGS) -DMESA_EGL_NO_X11_HEADERS' \
	-DCMAKE_CXX_FLAGS='$(TARGET_CXXFLAGS) -DMESA_EGL_NO_X11_HEADERS'

$(eval $(cmake-package))
