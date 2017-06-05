###############################################################################
#
# dyz-shm
#
###############################################################################

DYZ_SHM_VERSION = master
DYZ_SHM_SITE = https://github.com/aperezdc/dyz-shm
DYZ_SHM_SITE_METHOD = git
DYZ_SHM_DEPENDENCIES = wpewebkit wpebackend-shm

DYZ_SHM_CONF_OPTS = -DGRAPHICS=cairo

$(eval $(cmake-package))
