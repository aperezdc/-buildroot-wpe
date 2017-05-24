#! /bin/bash
#
# wpe-opt-launcher.sh
# Copyright (C) 2017 Adrian Perez <aperez@igalia.com>
#
# Distributed under terms of the MIT license.
#
set -ef -o pipefail

: ${WPE_PREFIX:=$(realpath "${0%/*}/..")}
: ${WPE_BIN:=dyz-shm}

# Can be used e.g. to launch gdbserver
: ${WPE_COMMAND_PREFIX:=}

# Persistent cookie storage.
: ${WPE_SHELL_COOKIE_STORAGE:=0}

# Disable antialiasing by default.
: ${CAIRO_GL_COMPOSITOR:=msaa}

# Mesa3D driver.
: ${MESA_DRIVER:=llvmpipe}

WPE_URL='https://ddg.gg'
WPE_URL_SOURCE='default'

head-sans-comments () {
	local line
	while read -r line ; do
		if [[ ${line} =~ ^[[:space:]]*#? ]] ; then
			continue
		fi
		echo "${line}"
	done < "$1"
}


if [[ $# -eq 0 ]] ; then
	for path in "${HOME}/.wpe/url" /etc/wpe/url "${WPE_PREFIX}/url" ; do
		if [[ -r ${path} ]] ; then
			WPE_URL=$(head-sans-comments "${path}")
			if [[ -n ${WPE_URL} ]] ; then
				WPE_URL_SOURCE=${path}
				break
			fi
		fi
	done
elif [[ $# -ne 1 ]] ; then
	echo "${0##*/}: Invalid command line. (Hint: Use -h/--help.)"
	exit 1
elif [[ $1 = -h || $1 == --help ]] ; then
	cat <<-EOF
	Usage: ${0##*/} [URL]
	The following environment variables affect the behaviour of WPE:

	WPE_BIN (currently '${WPE_BIN}')
	    Executable to use as WPE launcher.

	WPE_URL (currently '${WPE_URL:-https://ddg.gg}'${WPE_URL_SOURCE+ - ${WPE_URL_SOURCE}})
	    Initial URL to load on startup. If an URL is passed as first parameter
	    it will be used instead.

	WPE_PREFIX (currently '${WPE_PREFIX}')
	    WPE installation directory, including needed dependencies.

	WPE_COMMAND_PREFIX (currently '${WPE_COMMAND_PREFIX}')
	    Command prepended to the WPELauncher binary. This can be used e.g.
	    for debugging it with "gdbserver".

	WPE_SHELL_COOKIE_STORAGE (currently '${WPE_SHELL_COOKIE_STORAGE}')
	    Whether to enable (1) or disable (0) persistent cookie storage.

	CAIRO_GL_COMPOSITOR (currently '${CAIRO_GL_COMPOSITOR}')
	    Rendering mode used by Cairo-GL. Possible values: "msaa", "noaa".
	    The latter disables antialised rendering.

	MESA_DRIVER (currently '${MESA_DRIVER}')
	    Select the Mesa3D driver used for rendering. Possible values: "swr",
	    "softpipe", "llvmpipe".

	LP_NUM_THREADS (currently '${LP_NUM_THREADS:-}')
	    Number of rendering threads used by the llvmpipe Mesa3D driver.

	EOF
	exit 0
else
	WPE_URL=$1
	WPE_URL_SOURCE=commandline
fi

export WPE_SHELL_COOKIE_STORAGE CAIRO_GL_COMPOSITOR

declare -A export_vars

addpath () {
	local position=$1
	local variable=$2

	local value=${export_vars[${variable}]:-}

	# If empty, try to pick the value from the environment, or if that is in
	# turn empty as well, use the default value passed to the function.
	if [[ -z ${value} ]] ; then
		eval eval "local env_value=\\'\${${variable}:-}\\'"
		if [[ -n ${env_value} ]] ; then
			value=${env_value}
		elif [[ $3 != - ]] ; then
			value=$3
		fi
	fi
	shift 3

	local -a items=( )
	local -A seen

	# Add first elements either from the existing value, or the old one.
	local item saved_IFS=${IFS}
	IFS=':'
	for item in ${value} ; do
		if [[ -z ${seen[${item}]:-} ]] ; then
			seen["${item}"]=1
			items+=( "${item}" )
		fi
	done

	# Add now additional elements given as positional arguments.
	for item in "$@" ; do
		item=$(realpath "${WPE_PREFIX}/${item}")
		if [[ -z ${seen[${item}]:-} ]] ; then
			seen["${item}"]=1
			case ${position} in
				-p | --prepend)
					items=( "${item}" "${items[@]}" )
					;;
				-a | --append)
					items+=( "${item}" )
					;;
			esac
		fi
	done

	# Reassemble back the value.
	value=''
	for item in "${items[@]}" ; do
		value="${value}:${item}"
	done
	export_vars[${variable}]=${value:1}  # Remove the leading colon.
}

addvar () {
	export_vars[$1]=$2
}

addpath --prepend PATH /bin:/sbin:/usr/bin:/usr/sbin bin
addpath --prepend LD_LIBRARY_PATH     - lib
addpath --prepend GST_PLUGIN_PATH_1_0 - lib/gstreamer-1.0
addpath --prepend LIBGL_DRIVERS_PATH  - lib/dri
addpath --prepend EGL_DRIVERS_PATH    - lib/dri
addpath --prepend XDG_DATA_DIRS       /usr/share share
addpath --prepend XDG_CONFIG_DIRS     /etc/xdg etc/xdg

addvar GST_REGISTRY_1_0 /tmp/.wpe.gstreamer-1.0.registry
addvar GALLIUM_DRIVER "${MESA_DRIVER}"
addvar LP_NUM_THREADS "${LP_NUM_THREADS:-}"
addvar EGL_PLATFORM "${EGL_PLATFORM:-wayland}"
addvar LIBGL_ALWAYS_SOFTWARE 1
addvar GBM_ALWAYS_SOFTWARE 1
addvar XDG_RUNTIME_DIR "${XDG_RUNTIME_DIR:-/tmp}"
addvar GST_PLUGIN_SCANNER "${WPE_PREFIX}/bin/gst-plugin-scanner"

if [[ ${MESA_DRIVER} = llvmpipe && -z ${LP_NUM_THREADS:-} ]] ; then
	CPUS=$(grep -c ^processor /proc/cpuinfo)
	(( CPUS-- ))
	if [[ ${CPUS} -le 0 ]] ; then
		CPUS=1
	fi
	addvar LP_NUM_THREADS ${CPUS}
	unset CPUS
fi

cat <<EOF
WPE_URL                  : ${WPE_URL:-}
WPE_URL_SOURCE           : ${WPE_URL_SOURCE:-}
WPE_PREFIX               : ${WPE_PREFIX:-}
WPE_COMMAND_PREFIX       : ${WPE_COMMAND_PREFIX:-}
WPE_SHELL_COOKIE_STORAGE : ${WPE_SHELL_COOKIE_STORAGE:-}
CAIRO_GL_COMPOSITOR      : ${CAIRO_GL_COMPOSITOR:-}
MESA_DRIVER              : ${MESA_DRIVER:-}

Environment
EOF

for v in "${!export_vars[@]}" ; do
	echo "  ${v}=${export_vars[${v}]}"
	eval "export ${v}='${export_vars[${v}]}'"
done

if [[ -z ${WPE_BIN:-} || ! -x ${WPE_PREFIX}/bin/${WPE_BIN} ]] ; then
	WPE_BIN=''
	for bin in dyz-shm WPELauncher ; do
		if [[ -x ${WPE_PREFIX}/bin/${bin} ]] ; then
			WPE_BIN=${bin}
			break
		fi
	done
fi

if [[ -z ${WPE_BIN:-} ]] ; then
	echo "${0##*/}: No WPE launcher binary available." 1>&2
	exit 1
fi

exec ${WPE_COMMAND_PREFIX} "${WPE_PREFIX}/bin/${WPE_BIN}" "${WPE_URL}"
