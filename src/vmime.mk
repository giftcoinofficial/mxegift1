# This file is part of MXE. See LICENSE.md for licensing information.

PKG             := vmime
$(PKG)_IGNORE   :=
$(PKG)_VERSION  := b133ce8
$(PKG)_CHECKSUM := a81eed5ceda803ce3d250cc2c9bbc5ed7eab33308b81dee64747c5c7aa889e59
$(PKG)_SUBDIR   := kisli-vmime-$($(PKG)_VERSION)
$(PKG)_FILE     := $(PKG)-$($(PKG)_VERSION).tar.gz
$(PKG)_URL      := https://github.com/kisli/vmime/tarball/$($(PKG)_VERSION)/$($(PKG)_FILE)
$(PKG)_DEPS     := gcc gnutls libiconv libgsasl pthreads zlib

$(PKG)_UPDATE    = $(call MXE_GET_GITHUB_SHA, kisli/vmime, master) | $(SED) 's/^\(.......\).*/\1/;'

define $(PKG)_BUILD
    # The following hint is probably needed for ICU:
    # -DICU_LIBRARIES="`'$(TARGET)-pkg-config' --libs-only-l icu-i18n`"

    cd '$(1)' && '$(TARGET)-cmake' \
        -DCMAKE_AR='$(PREFIX)/bin/$(TARGET)-ar' \
        -DCMAKE_RANLIB='$(PREFIX)/bin/$(TARGET)-ranlib' \
        -DVMIME_HAVE_MESSAGING_PROTO_SENDMAIL=False \
        -DVMIME_HAVE_MLANG_H=False \
        -DCMAKE_CXX_FLAGS='-DWINVER=0x0501 -DAI_ADDRCONFIG=0x0400 -DIPV6_V6ONLY=27' \
        -DVMIME_BUILD_STATIC_LIBRARY=$(CMAKE_STATIC_BOOL) \
        -DVMIME_BUILD_SHARED_LIBRARY=$(CMAKE_SHARED_BOOL) \
        -DVMIME_BUILD_SAMPLES=OFF \
        -DVMIME_BUILD_DOCUMENTATION=OFF \
        -DCMAKE_MODULE_PATH='$(1)/cmake' \
        -DVMIME_CHARSETCONV_LIB=iconv \
        -DVMIME_TLS_SUPPORT_LIB=gnutls \
        -DVMIME_SHARED_PTR_USE_CXX=ON \
        -DCXX11_COMPILER_FLAGS=ON \
        -C '$(PWD)/src/vmime-TryRunResults.cmake' \
        .

    $(MAKE) -C '$(1)' -j '$(JOBS)'
    $(MAKE) -C '$(1)' -j 1 install
    $(SED) -i 's,^\(Libs.private:.* \)$(PREFIX)/$(TARGET)/lib/libiconv\.a,\1-liconv,g' '$(PREFIX)/$(TARGET)/lib/pkgconfig/vmime.pc'
    $(if $(BUILD_STATIC),$(SED) -i 's/^\(Cflags:.* \)/\1 -DVMIME_STATIC /g' '$(PREFIX)/$(TARGET)/lib/pkgconfig/vmime.pc')
    $(if $(BUILD_SHARED),$(INSTALL) -m644 '$(1)/build/bin/libvmime.dll' '$(PREFIX)/$(TARGET)/bin/')

    $(SED) -i 's/posix/windows/g;' '$(1)/examples/example6.cpp'
    $(TARGET)-g++ -s -std=c++0x -o '$(1)/examples/test-vmime.exe' \
        '$(1)/examples/example6.cpp' \
        `'$(TARGET)-pkg-config' vmime --cflags --libs`
    $(INSTALL) -m755 '$(1)/examples/test-vmime.exe' '$(PREFIX)/$(TARGET)/bin/'
endef