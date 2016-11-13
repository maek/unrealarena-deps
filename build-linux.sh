#!/bin/bash

# Copyright (C) 2015-2016  Unreal Arena
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Build all the external dependencies needed by Unreal Arena on Linux.


#-------------------------------------------------------------------------------
# Setup
#-------------------------------------------------------------------------------

# Dependencies version
DEPS_VERSION="5"

# Libraries versions
CURL_VERSION="7.43.0"
FREETYPE_VERSION="2.6"
GEOIP_VERSION="1.6.4"
GLEW_VERSION="1.12.0"
GMP_VERSION="6.0.0"
JPEG_VERSION="1.4.1"
LUA_VERSION="5.3.1"
NACLSDK_VERSION="44.0.2403.155"
NCURSES_VERSION="5.9"
NETTLE_VERSION="3.1.1"
OGG_VERSION="1.3.2"
OPENAL_VERSION="1.16.0"
OPUSFILE_VERSION="0.6"
OPUS_VERSION="1.1"
PNG_VERSION="1.6.18"
SDL2_VERSION="2.0.3"
THEORA_VERSION="1.1.1"
VORBIS_VERSION="1.3.5"
WEBP_VERSION="0.4.3"
ZLIB_VERSION="1.2.8"

# Build environment
ROOTDIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
BUILDDIR="${ROOTDIR}/build"
CACHEDIR="${ROOTDIR}/cache"
DESTDIR="${ROOTDIR}/linux-${DEPS_VERSION}"

# Compiler
# export CHOST="x86_64-unknown-linux-gnu"  # FIXME
# export CFLAGS="-m64 -fPIC -O3 -pipe"  # -fPIC is needed for 64-bit static libraries  # FIXME
# export CXXFLAGS="-m64 -fPIC -O3 -pipe"  # -fPIC is needed for 64-bit static libraries  # FIXME
export CFLAGS="-O3 -pipe"
export CXXFLAGS="-O3 -pipe"
export CPPFLAGS="${CPPFLAGS:-} -I${DESTDIR}/include"
export LDFLAGS="${LDFLAGS:-} -L${DESTDIR}/lib -L${DESTDIR}/lib64"
export PATH="${DESTDIR}/bin:${PATH}"
export PKG_CONFIG_PATH="${DESTDIR}/lib/pkgconfig:${DESTDIR}/lib64/pkgconfig:${PKG_CONFIG_PATH}"
export CMAKE_BUILD_TYPE="Release"

# Limit parallel jobs to avoid being killed by Travis CI
export MAKEFLAGS="-j$(($(nproc) < 8 ? $(nproc) : 8))"


#-------------------------------------------------------------------------------
# Utilities
#-------------------------------------------------------------------------------

# Download the archive and extract it
_get ()
{
	local URL="$1"
	local FILENAME="${URL##*/}"

	# Download
	if ! [[ -f "${CACHEDIR}/${FILENAME}" ]]
	then
		echo "> Downloading '${FILENAME}'..."
		curl -Lso "${CACHEDIR}/${FILENAME}" "${URL}"
	fi

	# Extract
	echo "> Extracting '${FILENAME}'..."
	case "${FILENAME}" in
		*.tar.bz2|*.tar.gz|*.tgz)
			tar xf "${CACHEDIR}/${FILENAME}" -C "${BUILDDIR}" --recursive-unlink
			;;
		*)
			echo "Error: unknown archive type '${FILENAME}'" >&2
			exit 1
			;;
	esac
}

# Change directory
_cd ()
{
	local LIBDIR="$1"

	cd "${BUILDDIR}/${LIBDIR}"
}

# Configure the build (configure)
_configure ()
{
	local LIBNAME="$1"
	local OPTIONS="${@:2}"

	echo "> Configuring '${LIBNAME}'..."
	./configure --build=x86_64-unknown-linux-gnu\
	            --prefix="${DESTDIR}"\
	            ${OPTIONS}
}

# Configure the build (cmake)
_cmake ()
{
	local LIBNAME="$1"
	local OPTIONS="${@:2}"

	cmake -DCMAKE_BUILD_TYPE="${CMAKE_BUILD_TYPE}"\
	      -DCMAKE_INSTALL_PREFIX="${DESTDIR}"\
	      ${OPTIONS}
}

# Build
_build ()
{
	local LIBNAME="$1"

	echo "> Building '${LIBNAME}'..."

	make
}

# Install
_install ()
{
	local LIBNAME="$1"

	echo "> Installing '${LIBNAME}'..."

	make install
}

# Success!
_done ()
{
	echo "> Success!"
}


#-------------------------------------------------------------------------------
# Subroutines
#-------------------------------------------------------------------------------

# Build curl
build_curl ()
{
	local LIBNAME="curl"

	_get "http://curl.haxx.se/download/curl-${CURL_VERSION}.tar.bz2"
	_cd "curl-${CURL_VERSION}"
	_configure "${LIBNAME}" --disable-shared\
	                        --disable-dict\
	                        --disable-file\
	                        --disable-gopher\
	                        --disable-imap\
	                        --disable-ldap\
	                        --disable-pop3\
	                        --disable-rtsp\
	                        --disable-smtp\
	                        --disable-telnet\
	                        --disable-tftp\
	                        --without-libidn\
	                        --without-librtmp\
	                        --without-libssh2\
	                        --without-ssl
	_build "${LIBNAME}"
	_install "${LIBNAME}"

	rm -rf "${DESTDIR}/bin/curl"*
	rm -rf "${DESTDIR}/lib/libcurl.la"
	rm -rf "${DESTDIR}/share/aclocal/libcurl.m4"
	rm -rf "${DESTDIR}/share/man/man1/curl"*
	rm -rf "${DESTDIR}/share/man/man3/curl"*
	rm -rf "${DESTDIR}/share/man/man3/CURL"*
	rm -rf "${DESTDIR}/share/man/man3/libcurl"*

	_done
}

# Build FreeType
build_freetype ()
{
	local LIBNAME="FreeType"

	_get "http://download.savannah.gnu.org/releases/freetype/freetype-${FREETYPE_VERSION}.tar.bz2"
	_cd "freetype-${FREETYPE_VERSION}"

	sed -i -e "/AUX.*.gxvalid/s@^# @@" -e "/AUX.*.otvalid/s@^# @@" modules.cfg
	# sed -ri -e 's:.*(#.*SUBPIXEL.*) .*:\1:' include/config/ftoption.h

	_configure "${LIBNAME}" --disable-shared\
	                        --without-bzip2\
	                        --without-harfbuzz\
	                        --without-png
	_build "${LIBNAME}"
	_install "${LIBNAME}"

	rm -rf "${DESTDIR}/bin/freetype-config"
	rm -rf "${DESTDIR}/lib/libfreetype.la"
	rm -rf "${DESTDIR}/share/aclocal/freetype2.m4"
	rm -rf "${DESTDIR}/share/man/man1/freetype-config.1"

	_done
}

# Build GeoIP
build_geoip ()
{
	local LIBNAME="GeoIP"

	_get "https://github.com/maxmind/geoip-api-c/archive/v${GEOIP_VERSION}.tar.gz"
	_cd "geoip-api-c-${GEOIP_VERSION}"

	autoreconf -fiv

	_configure "${LIBNAME}" --disable-shared
	_build "${LIBNAME}"
	_install "${LIBNAME}"

	rm -rf "${DESTDIR}/bin/geoiplookup"*
	rm -rf "${DESTDIR}/lib/libGeoIP.la"
	rm -rf "${DESTDIR}/share/man/man1/geoiplookup"*

	_done
}

# Build GLEW
build_glew ()
{
	local LIBNAME="GLEW"

	_get "http://downloads.sourceforge.net/glew/glew-${GLEW_VERSION}.tgz"
	_cd "glew-${GLEW_VERSION}"

	export GLEW_DEST="${DESTDIR}"

	_build "${LIBNAME}"
	_install "${LIBNAME}"

	rm -rf "${DESTDIR}/lib64/libGLEW.a"

	_done
}

# Build GMP
build_gmp ()
{
	local LIBNAME="GMP"

	_get "https://gmplib.org/download/gmp/gmp-${GMP_VERSION}a.tar.bz2"
	_cd "gmp-${GMP_VERSION}"
	_configure "${LIBNAME}" --disable-shared
	_build "${LIBNAME}"

	make check || exit 1

	_install "${LIBNAME}"

	rm -rf "${DESTDIR}/lib/libgmp.la"
	rm -rf "${DESTDIR}/share/info/dir"
	rm -rf "${DESTDIR}/share/info/gmp"*

	_done
}

# Build JPEG
build_jpeg ()
{
	local LIBNAME="JPEG"

	_get "http://downloads.sourceforge.net/libjpeg-turbo/libjpeg-turbo-${JPEG_VERSION}.tar.gz"
	_cd "libjpeg-turbo-${JPEG_VERSION}"

	sed -i -e "/^docdir/s:$:/libjpeg-turbo-${JPEG_VERSION}:" Makefile.in

	_configure "${LIBNAME}" --disable-shared\
	                        --with-jpeg8\
	                        --without-turbojpeg
	_build "${LIBNAME}"
	_install "${LIBNAME}"

	rm -rf "${DESTDIR}/bin/cjpeg"
	rm -rf "${DESTDIR}/bin/djpeg"
	rm -rf "${DESTDIR}/bin/jpegtran"
	rm -rf "${DESTDIR}/bin/rdjpgcom"
	rm -rf "${DESTDIR}/bin/wrjpgcom"
	rm -rf "${DESTDIR}/lib/libjpeg.la"
	rm -rf "${DESTDIR}/share/doc/libjpeg-turbo-${JPEG_VERSION}"
	rm -rf "${DESTDIR}/man/man1/cjpeg.1"
	rm -rf "${DESTDIR}/man/man1/djpeg.1"
	rm -rf "${DESTDIR}/man/man1/jpegtran.1"
	rm -rf "${DESTDIR}/man/man1/rdjpgcom.1"
	rm -rf "${DESTDIR}/man/man1/wrjpgcom.1"

	_done
}

# Build Lua
build_lua ()
{
	local LIBNAME="Lua"

	_get "http://www.lua.org/ftp/lua-${LUA_VERSION}.tar.gz"
	_cd "lua-${LUA_VERSION}"

	sed -i -e "/^PLAT=/s:none:linux:" -e "/^INSTALL_TOP=/s:/usr/local:${DESTDIR}:" Makefile
	# sed -i -e "/#define LUA_ROOT/s:/usr/local/:${DESTDIR}/:" src/luaconf.h

	_build "${LIBNAME}"

	echo "********************************************************************************"
	make test || exit 1
	echo "********************************************************************************"

	_install "${LIBNAME}"

	rm -rf "${DESTDIR}/bin/lua"*
	rm -rf "${DESTDIR}/man/man1/lua"*

	_done
}

# Build NaCl Ports
build_naclports ()
{
	local LIBNAME="NaCl Ports"

	_get "https://storage.googleapis.com/nativeclient-mirror/nacl/nacl_sdk/${NACLSDK_VERSION}/naclports.tar.bz2"
	_cd "pepper_${NACLSDK_VERSION%%.*}"

	echo "Installing '${LIBNAME}'..."

	mkdir -p "${DESTDIR}/pnacl_deps/include"
	mkdir -p "${DESTDIR}/pnacl_deps/lib"

	cp -a "ports/include/freetype2" "${DESTDIR}/pnacl_deps/include"
	cp -a "ports/include/lauxlib.h" "${DESTDIR}/pnacl_deps/include"
	cp -a "ports/include/luaconf.h" "${DESTDIR}/pnacl_deps/include"
	cp -a "ports/include/lua.h" "${DESTDIR}/pnacl_deps/include"
	cp -a "ports/include/lua.hpp" "${DESTDIR}/pnacl_deps/include"
	cp -a "ports/include/lualib.h" "${DESTDIR}/pnacl_deps/include"
	cp -a "ports/include/png.h" "${DESTDIR}/pnacl_deps/include"
	cp -a "ports/include/pngconf.h" "${DESTDIR}/pnacl_deps/include"
	cp -a "ports/include/libpng16" "${DESTDIR}/pnacl_deps/include"
	cp -a "ports/include/pnglibconf.h" "${DESTDIR}/pnacl_deps/include"
	cp -a "ports/lib/newlib_pnacl/Release/libfreetype.a" "${DESTDIR}/pnacl_deps/lib"
	cp -a "ports/lib/newlib_pnacl/Release/liblua.a" "${DESTDIR}/pnacl_deps/lib"
	cp -a "ports/lib/newlib_pnacl/Release/libpng16.a" "${DESTDIR}/pnacl_deps/lib"
	cp -a "ports/lib/newlib_pnacl/Release/libpng.a" "${DESTDIR}/pnacl_deps/lib"

	_done
}

# Build NaCl SDK
build_naclsdk ()
{
	local LIBNAME="NaCl SDK"

	_get "https://storage.googleapis.com/nativeclient-mirror/nacl/nacl_sdk/${NACLSDK_VERSION}/naclsdk_linux.tar.bz2"
	_cd "pepper_${NACLSDK_VERSION%%.*}"

	echo "Installing '${LIBNAME}'..."

	cp -a "tools/sel_ldr_x86_64" "${DESTDIR}/sel_ldr"
	cp -a "tools/irt_core_x86_64.nexe" "${DESTDIR}/irt_core-x86_64.nexe"
	cp -a "tools/nacl_helper_bootstrap_x86_64" "${DESTDIR}/nacl_helper_bootstrap"
	# cp -a "toolchain/linux_x86_newlib/bin/x86_64-nacl-gdb" "${DESTDIR}/nacl-gdb"
	cp -a "toolchain/linux_pnacl" "${DESTDIR}/pnacl"

	rm -rf "${DESTDIR}/pnacl/arm-nacl"
	rm -rf "${DESTDIR}/pnacl/arm_bc-nacl"
	rm -rf "${DESTDIR}/pnacl/bin/arm-nacl-"*
	rm -rf "${DESTDIR}/pnacl/bin/i686-nacl-"*
	rm -rf "${DESTDIR}/pnacl/bin/x86_64-nacl-"*
	rm -rf "${DESTDIR}/pnacl/docs"
	rm -rf "${DESTDIR}/pnacl/FEATURE_VERSION"
	rm -rf "${DESTDIR}/pnacl/i686_bc-nacl"
	rm -rf "${DESTDIR}/pnacl/include"
	rm -rf "${DESTDIR}/pnacl/pnacl_newlib"*
	rm -rf "${DESTDIR}/pnacl/README"
	rm -rf "${DESTDIR}/pnacl/REV"
	rm -rf "${DESTDIR}/pnacl/share"
	rm -rf "${DESTDIR}/pnacl/x86_64-nacl"
	rm -rf "${DESTDIR}/pnacl/x86_64_bc-nacl"

	_done
}

# Build Ncurses
build_ncurses ()
{
	local LIBNAME="Ncurses"

	_get "http://ftp.gnu.org/pub/gnu/ncurses/ncurses-${NCURSES_VERSION}.tar.gz"
	_cd "ncurses-${NCURSES_VERSION}"

	curl -Lso "ncurses-5.9-gcc5_buildfixes-1.patch" "http://www.linuxfromscratch.org/patches/downloads/ncurses/ncurses-5.9-gcc5_buildfixes-1.patch"
	patch -sNp1 -i ncurses-5.9-gcc5_buildfixes-1.patch
	sed -i '/LIBTOOL_INSTALL/d' c++/Makefile.in

	_configure "${LIBNAME}" --without-manpages\
	                        --without-progs\
	                        --without-tests\
	                        --without-debug\
	                        --enable-widec
	_build "${LIBNAME}"
	_install "${LIBNAME}"

	ln -s "libncursesw.a" "${DESTDIR}/lib/libcursesw.a"
	rm -rf "${DESTDIR}/bin/ncursesw5-config"
	rm -rf "${DESTDIR}/lib/terminfo"
	rm -rf "${DESTDIR}/share/tabset"
	rm -rf "${DESTDIR}/share/terminfo"

	_done
}

# Build Nettle
build_nettle ()
{
	local LIBNAME="Nettle"

	_get "http://www.lysator.liu.se/~nisse/archive/nettle-${NETTLE_VERSION}.tar.gz"
	_cd "nettle-${NETTLE_VERSION}"
	_configure "${LIBNAME}" --disable-shared\
	                        --disable-documentation
	_build "${LIBNAME}"
	_install "${LIBNAME}"

	rm -rf "${DESTDIR}/bin/nettle"*
	rm -rf "${DESTDIR}/bin/pkcs1-conv"
	rm -rf "${DESTDIR}/bin/sexp-conv"

	_done
}

# Build Ogg
build_ogg ()
{
	local LIBNAME="Ogg"

	_get "http://downloads.xiph.org/releases/ogg/libogg-${OGG_VERSION}.tar.gz"
	_cd "libogg-${OGG_VERSION}"
	_configure "${LIBNAME}" --disable-shared
	_build "${LIBNAME}"
	_install "${LIBNAME}"

	rm -rf "${DESTDIR}/lib/libogg.la"
	rm -rf "${DESTDIR}/share/aclocal/ogg.m4"
	rm -rf "${DESTDIR}/share/doc/libogg"

	_done
}

# Build OpenAL
build_openal ()
{
	local LIBNAME="OpenAL"

	_get "http://kcat.strangesoft.net/openal-releases/openal-soft-${OPENAL_VERSION}.tar.bz2"
	_cd "openal-soft-${OPENAL_VERSION}"
	_cmake "${LIBNAME}" -DALSOFT_UTILS=OFF\
	                    -DALSOFT_EXAMPLES=OFF
	_build "${LIBNAME}"
	_install "${LIBNAME}"

	rm -rf "${DESTDIR}/share/openal"

	_done
}

# Build Opus
build_opus ()
{
	local LIBNAME="Opus"

	_get "http://downloads.xiph.org/releases/opus/opus-${OPUS_VERSION}.tar.gz"
	_cd "opus-${OPUS_VERSION}"
	_configure "${LIBNAME}" --disable-shared\
	                        --disable-extra-programs\
	                        --disable-doc
	_build "${LIBNAME}"
	_install "${LIBNAME}"

	rm -rf "${DESTDIR}/lib/libopus.la"
	rm -rf "${DESTDIR}/share/aclocal/opus.m4"

	_done
}

# Build Opusfile
build_opusfile ()
{
	local LIBNAME="Opusfile"

	_get "http://downloads.xiph.org/releases/opus/opusfile-${OPUSFILE_VERSION}.tar.gz"
	_cd "opusfile-${OPUSFILE_VERSION}"
	_configure "${LIBNAME}" --disable-shared\
	                        --disable-http\
	                        --disable-doc
	_build "${LIBNAME}"
	_install "${LIBNAME}"

	rm -rf "${DESTDIR}/lib/libopusfile.la"
	rm -rf "${DESTDIR}/lib/libopusurl.la"
	rm -rf "${DESTDIR}/share/doc/opusfile"

	_done
}

# Build PNG
build_png ()
{
	local LIBNAME="PNG"

	_get "http://downloads.sourceforge.net/libpng/libpng-${PNG_VERSION}.tar.gz"
	_cd "libpng-${PNG_VERSION}"
	_configure "${LIBNAME}" --disable-shared
	_build "${LIBNAME}"
	_install "${LIBNAME}"

	rm -rf "${DESTDIR}/bin/libpng"*
	rm -rf "${DESTDIR}/bin/png"*
	rm -rf "${DESTDIR}/lib/libpng.la"
	rm -rf "${DESTDIR}/lib/libpng16.la"
	rm -rf "${DESTDIR}/share/man/man3/libpng"*
	rm -rf "${DESTDIR}/share/man/man5/png.5"

	_done
}

# Build SDL2
build_sdl2 ()
{
	local LIBNAME="SDL2"

	_get "https://www.libsdl.org/release/SDL2-${SDL2_VERSION}.tar.gz"
	_cd "SDL2-${SDL2_VERSION}"
	_configure "${LIBNAME}" --disable-alsatest
	_build "${LIBNAME}"
	_install "${LIBNAME}"

	rm -rf "${DESTDIR}/bin/sdl2-config"
	rm -rf "${DESTDIR}/lib/libSDL2.a"
	rm -rf "${DESTDIR}/lib/libSDL2.la"
	rm -rf "${DESTDIR}/lib/libSDL2_test.a"
	rm -rf "${DESTDIR}/share/aclocal/sdl2.m4"

	_done
}

# Build Theora
build_theora ()
{
	local LIBNAME="Theora"

	_get "http://downloads.xiph.org/releases/theora/libtheora-${THEORA_VERSION}.tar.bz2"
	_cd "libtheora-${THEORA_VERSION}"
	_configure "${LIBNAME}" --disable-shared\
	                        --disable-encode\
	                        --disable-examples
	_build "${LIBNAME}"
	_install "${LIBNAME}"

	rm -rf "${DESTDIR}/lib/libtheora.la"
	rm -rf "${DESTDIR}/lib/libtheoradec.la"
	rm -rf "${DESTDIR}/lib/libtheoraenc.la"
	rm -rf "${DESTDIR}/share/doc/libtheora-${THEORA_VERSION}"

	_done
}

# Build Vorbis
build_vorbis ()
{
	local LIBNAME="Vorbis"

	_get "http://downloads.xiph.org/releases/vorbis/libvorbis-${VORBIS_VERSION}.tar.gz"
	_cd "libvorbis-${VORBIS_VERSION}"
	_configure "${LIBNAME}" --disable-shared
	_build "${LIBNAME}"
	_install "${LIBNAME}"

	rm -rf "${DESTDIR}/lib/libvorbis.la"
	rm -rf "${DESTDIR}/lib/libvorbisenc.la"
	rm -rf "${DESTDIR}/lib/libvorbisfile.la"
	rm -rf "${DESTDIR}/share/aclocal/vorbis.m4"
	rm -rf "${DESTDIR}/share/doc/libvorbis-${VORBIS_VERSION}"

	_done
}

# Build WebP
build_webp ()
{
	local LIBNAME="WebP"

	_get "http://downloads.webmproject.org/releases/webp/libwebp-${WEBP_VERSION}.tar.gz"
	_cd "libwebp-${WEBP_VERSION}"
	_configure "${LIBNAME}" --disable-shared
	_build "${LIBNAME}"
	_install "${LIBNAME}"

	rm -rf "${DESTDIR}/bin/cwebp"
	rm -rf "${DESTDIR}/bin/dwebp"
	rm -rf "${DESTDIR}/lib/libwebp.la"
	rm -rf "${DESTDIR}/share/man/man1/cwebp.1"
	rm -rf "${DESTDIR}/share/man/man1/dwebp.1"

	_done
}

# Build zlib
build_zlib ()
{
	local LIBNAME="zlib"

	_get "http://zlib.net/zlib-${ZLIB_VERSION}.tar.gz"
	_cd "zlib-${ZLIB_VERSION}"
	_configure "${LIBNAME}" --const\
	                        --static
	_build "${LIBNAME}"
	_install "${LIBNAME}"

	rm -rf "${DESTDIR}/share/man/man3/zlib.3"

	_done
}


#-------------------------------------------------------------------------------
# Main
#-------------------------------------------------------------------------------

# Parse arguments
if [[ $# -gt 0 ]]
then
	echo "Usage: ${0##*/}" >&2
	exit 2
fi

# Create directories
mkdir -p "${BUILDDIR}"
mkdir -p "${CACHEDIR}"
rm -rf "${DESTDIR}"  # FIXME
mkdir -p "${DESTDIR}"

# Enable exit-on-error
set -e

# Build libraries
# build_curl
# build_freetype
# build_geoip
# build_glew
# build_gmp
# build_jpeg  # [need nasm]
build_lua
# build_naclports
# build_naclsdk
# build_ncurses
# build_nettle  # [need gmp]
# build_ogg
# build_openal
# build_opus
# build_opusfile  # [need ogg, opus]
# build_png
# build_sdl2
# build_vorbis  # [need ogg]
# build_theora  # [need ogg, vorbis, png]
# build_webp
# build_zlib
