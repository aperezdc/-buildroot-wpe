#! /bin/bash
set -euf -o pipefail

readonly TARGET=$1
readonly OPTDIR='output/opt/wpe'
readonly ARGV0=${0##*/}
declare -a WPE_BINARIES=(
	"${TARGET}/usr/bin/WPEDatabaseProcess"
	"${TARGET}/usr/bin/WPENetworkProcess"
	"${TARGET}/usr/bin/WPEWebProcess"
	"${TARGET}/usr/libexec/gstreamer-1.0/gst-plugin-scanner"
)

die () {
	echo "${ARGV0}: $*"
	exit 1
} 1>&2

info () {
	printf '[[1;32m%s[0;0m] %s\n' "${ARGV0}" "$*"
} 1>&2

#
# Usage: config-value <symbol> [default]
#
config-value () {
	local value
	value=$(sed -e "/^${1//\//\\\/}=/s/^[^=]\\+=//p" -e d "${BR2_CONFIG}")
	if [[ ${value} = \"* || ${value} = \'* ]] ; then
		# Remove surrounding quotes
		value=${value:1:-1}
	fi
	if [[ -z ${value} && $# -gt 1 ]] ; then
		value=$2
	fi
	echo "${value}"
}

config-has () {
	[[ $(config-value "$1") = y ]]
}


#
# Add the binaries for the launchers enabled.
#
if config-has BR2_PACKAGE_WPELAUNCHER ; then
	WPE_BINARIES+=(	"${TARGET}/usr/bin/WPELauncher" )
fi
if config-has BR2_PACKAGE_DYZ_SHM ; then
	WPE_BINARIES+=( "${TARGET}/usr/bin/dyz-shm" )
fi
if config-has BR2_PACKAGE_GDB_SERVER ; then
	WPE_BINARIES+=( "${TARGET}/usr/bin/gdbserver" )
fi

#
# The logic for the following functions follows that of "package/Makefile.in"
#

if config-has BR2_PACKAGE_HAS_TOOLCHAIN_EXTERNAL ; then
	readonly TARGET_TRIPLE=$(config-value BR2_TOOLCHAIN_EXTERNAL_PREFIX)
else

	OS=linux
	if config-has BR2_BINFMT_FLAT ; then
		OS=uclinux
	fi
	readonly OS

	LIBC=gnu
	if config-has BR2_TOOLCHAIN_USES_UCLIBC ; then
		LIBC=uclibc
	elif config-has BR2_TOOLCHAIN_USES_MUSL ; then
		LIBC=musl
	fi
	readonly LIBC

	ABI=''
	if config-has BR2_arm || config-has BR2_armeb ; then
		if [[ ${LIBC} = uclibc ]] ; then
			ABI=gnueabi
		else
			ABI=eabi
		fi
		if config-has BR2_ARM_EABIHF ; then
			ABI=${ABI}hf
		fi
	elif config-has BR2_powerpc_SPE ; then
		ABI=spe
	fi
	readonly ABI

	# Read configuration values needed to assemble GNU_TARGET_TRIPLE
	readonly ARCH=$(config-value BR2_ARCH)
	readonly VENDOR=$(config-value BR2_TOOLCHAIN_VENDOR buildroot)

	# ...and assemble the target triple
	readonly TARGET_TRIPLE="${ARCH}-${VENDOR}-${OS}-${LIBC}${ABI}"
fi

tc-get-tool () {
	local path="output/host/usr/bin/${TARGET_TRIPLE}-$1"
	[[ -x ${path} ]] || die "Tool not found: ${path}"
	echo "${path}"
}

readonly TC_READELF=$(tc-get-tool readelf)

elf-dependency-find () {
	local path libpath libname=$1 ; shift
	case ${libname} in
		libc.so.* | libm.so.* | libdl.so.* | librt.so.* | libselinux.so.* | libgcc_s.so.* | libresolv.so.* | libtinfo.so.* )
			return
			;;
	esac
	for libpath in lib usr/lib "$@" ; do
		path="${TARGET}/${libpath}/${libname}"
		if [[ -r ${path} ]] ; then
			echo "${libname} ${libpath} ${path}"
			return
		fi
	done
	die "Cannot find: ${libname}"
}

elf-dependencies () {
	local path
	local -a needed rpath line

	while read -r -a line ; do
		if [[ ${#line[@]} -lt 2 ]] ; then
			continue
		fi

		# Extract last item. File names/paths are usually enclosed between
		# square brackets and need to be removed.
		path=${line[$(( ${#line[@]} - 1 ))]}
		if [[ ${path} = *\] ]] ; then
			path=${path:1:-1}
		fi

		if [[ ${line[1]} = \(RPATH\) ]] ; then
			rpath+=( "${path}" )
		elif [[ ${line[1]} = \(NEEDED\) ]] ; then
			needed+=( "${path}" )
		fi
	done < <( "${TC_READELF}" -W -d "$1" )

	for path in "${needed[@]}" ; do
		elf-dependency-find "${path}" "${rpath[@]}"
	done
}

# Usage: copy-lib <abspath> <destdir>
#   If <abspath> is a symbolic link, the pointed file is copied, and
#   a new relative symbolic link created in <destdir> pointed to the copy.
#
copy-lib () {
	if [[ -L $1 ]] ; then
		local linkdest
		linkdest=$(readlink -f "$1")
		cp -af "${linkdest}" "$2"
		ln -sf "${linkdest##*/}" "$2/${1##*/}"
	else
		cp -af "$1" "$2"
	fi
}

# Print some information.
info "Target: ${TARGET_TRIPLE}"

declare -A LIBPATH
readonly -a SPINNER=( '-' '\\' '|' '/' )
declare -i SPINPOS=0

spin () {
	printf '\r[K  %c %s\r' "${SPINNER[${SPINPOS}]}" "$*"
	SPINPOS=$(( ++SPINPOS % ${#SPINNER[@]} ))
}

inspect-elf-objects () {
	if [[ $# -eq 0 ]] ; then
		return
	fi

	spin "${1##*/}"

	local elfobj=$1 ; shift
	local -a pending

	local libname='' libpath='' abspath=''
	while read -r libname libpath abspath ; do
		if [[ -n ${LIBPATH[${abspath}]:-} ]] ; then
			continue
		fi
		LIBPATH[${abspath}]=${libpath}
		pending+=( "${abspath}" )
		case ${libpath} in
			lib)
				copy-lib "${abspath}" "${OPTDIR}/lib/"
				;;
			usr/*)
				copy-lib "${abspath}" "${OPTDIR}/${libpath#usr/}/"
				;;
			*)
				die 'This should not happen!'
				;;
		esac
	done < <( elf-dependencies "${elfobj}" )

	inspect-elf-objects "$@" "${pending[@]}"
}

info "Calculating dependencies..."

# Create target directories.
rm -rf "${OPTDIR}"
mkdir -p \
	"${OPTDIR}/etc/xdg" \
	"${OPTDIR}/bin" \
	"${OPTDIR}/lib/dri" \
	"${OPTDIR}/lib/gstreamer-1.0" \
	"${OPTDIR}/share/fonts"

# Main WPE binaries.
cp -a "${WPE_BINARIES[@]}" "${OPTDIR}/bin"
cp -a "${0%/*}/wpe-opt-launcher.sh" "${OPTDIR}/bin/wpe-launch"
inspect-elf-objects "${WPE_BINARIES[@]}"

# WPE backends
while read -r path ; do
	cp -a "${path}" "${OPTDIR}/lib/"
	inspect-elf-objects "${path}"
done < <( find "${TARGET}/usr/lib/" -name 'libWPEBackend*.so' )

# Mesa3D drivers.
while read -r path ; do
	cp -a "${path}" "${OPTDIR}/lib/dri/"
	inspect-elf-objects "${path}"
done < <( find "${TARGET}/usr/lib/dri" -name '*.so' )

# GStreamer elements.
while read -r path ; do
	cp -a "${path}" "${OPTDIR}/lib/gstreamer-1.0/"
	inspect-elf-objects "${path}"
done < <( find "${TARGET}/usr/lib/gstreamer-1.0" -name '*.so' )

# PulseAudio plug-ins.
if config-has BR2_PACKAGE_PULSEAUDIO ; then
	while read -r path ; do
		cp -a "${path}" "${OPTDIR}/lib/"
		inspect-elf-objects "${path}"
	done < <( find "${TARGET}/usr/lib/pulseaudio/" -name '*.so' )
fi

# Fonts and FontConfig configuration.
info 'Copying fonts...'

ln -sf ../fonts "${OPTDIR}/etc/xdg/fontconfig"
cp -a "${TARGET}/etc/fonts" "${OPTDIR}/etc/"

# Usage: copy-fontdir BR2_PACKAGE_FOO foo
declare -a FONT_DIRS=( )
copy-fontdir () {
	if config-has "$1" ; then
		spin "$2"
		cp -a "${TARGET}/usr/share/fonts/$2" "${OPTDIR}/share/fonts/"
		FONT_DIRS+=( "$2" )
	fi
}

copy-fontdir BR2_PACKAGE_DEJAVU dejavu

if [[ ${#FONT_DIRS[@]} -eq 0 ]] ; then
	die 'At least one font package must be available to use as fallback.'
fi

info 'Creating tarball...'
tar -cf output/wpe.tar -C output opt

info "Output: $(du -bh output/wpe.tar)"
