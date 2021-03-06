################################################################################
#
# libprovision
#
################################################################################

ifeq ($(BR2_PACKAGE_CPPSDK),y)
LIBPROVISION_VERSION = b8d14e82101f9c5f7ef73d7d33927009298d0612
else
LIBPROVISION_VERSION = 0822c06193c0bf8d815781fe37cda1cba1df1740
endif

LIBPROVISION_SITE_METHOD = git
LIBPROVISION_SITE = git@github.com:Metrological/libprovision.git
LIBPROVISION_LICENSE = PROPRIETARY
LIBPROVISION_REDISTRIBUTE = NO
LIBPROVISION_INSTALL_STAGING = YES

ifeq ($(BR2_PACKAGE_CPPSDK),y)
LIBPROVISION_DEPENDENCIES = openssl cppsdk
else
LIBPROVISION_DEPENDENCIES = openssl
endif

$(eval $(cmake-package))
