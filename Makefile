# Makefile for building and installing bada toolchain in GNU/Linux
# Copyright (C) 2012 Adrian Matoga
#
# bali-sdk is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# bali-sdk is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with bali-sdk.  If not, see <http://www.gnu.org/licenses/>.

MAIN_ARCHIVE      := bada_SDK_2.0.0.zip
TOOLCHAIN_ARCHIVE := bada-g++-4.5-3-src.tar.bz2

BINUTILS_DIR      := src/binutils-2.21
ZLIB_DIR          := src/zlib-1.2.5
GMP_DIR           := src/gmp-5.0.2
MPFR_DIR          := src/mpfr-3.0.1
PPL_DIR           := src/ppl-0.11.2
CLOOG_DIR         := src/cloog-parma-0.16.1
GCC_DIR           := src/gcc-4.5.3

EXPAT_DIR         := src/expat-2.0.1
GDB_DIR           := src/gdb-7.2
LIBICONV_DIR      := src/libiconv-1.13.1
MPC_DIR           := src/mpc-0.9
NEWLIB_DIR        := src/newlib-1.19.0

PKGCONF           := bada
BUGURL            := 

ASCIIDOC           = asciidoc -o $@ -a doctime

HOST     := $(shell gcc -v 2>&1 | grep '\-\-build=' | sed -e 's/^.*--build=//' | sed -e 's/\s.*$$//')
TARGET   := arm-bada-eabi
TEMPINST := $(shell pwd)/tempinst

announce = ( tput bold; tput setf 2; echo Starting ${@:stamps/%=%}; tput sgr0 ) >/dev/stderr
touch = mkdir -p stamps && touch $@ && ( tput bold; tput setf 6; echo ${@:stamps/%=%}; tput sgr0 ) >/dev/stderr

all: stamps/tidyup
.PHONY: all

# doc

doc: README.html

README.html: README.asciidoc
	$(ASCIIDOC) $<

# unpack

stamps/unpack_main: $(MAIN_ARCHIVE)
	unzip $(MAIN_ARCHIVE) $(TOOLCHAIN_ARCHIVE) && $(touch)

stamps/unpack_toolchain: stamps/unpack_main
	tar jxf $(TOOLCHAIN_ARCHIVE) --exclude="build*.sh" && $(touch)

# binutils

stamps/binutils_configured: stamps/gmp_checked stamps/mpfr_checked stamps/cloog_checked stamps/mpc_checked stamps/ppl_installed
	@$(announce) && \
	( mkdir -p build/binutils && cd build/binutils && ../../$(BINUTILS_DIR)/configure \
		--host="$(HOST)" \
		--build="$(HOST)" \
		--target="$(TARGET)" \
		--prefix="$(TEMPINST)" \
		--libdir="$(TEMPINST)/lib" \
		--with-pkgversion="$(PKGCONF)" \
		--with-bugurl="$(BTURL)" \
		--with-gmp-include="$(PREFIX)"/include \
		--with-gmp-lib="$(PREFIX)"/lib \
		--with-mpfr-include="$(PREFIX)"/include \
		--with-mpfr-lib="$(PREFIX)"/lib \
		--with-mpc-include="$(PREFIX)"/include \
		--with-mpc-lib="$(PREFIX)"/lib \
		--with-ppl-include="$(PREFIX)"/include \
		--with-ppl-lib="$(PREFIX)"/lib \
		--with-cloog-include="$(PREFIX)"/include \
		--with-cloog-lib="$(PREFIX)"/lib \
		--disable-nls ) \
	&& $(touch)

stamps/binutils_built: stamps/binutils_configured
	@$(announce) && \
	( cd build/binutils && $(MAKE) ) \
	&& $(touch)

stamps/binutils_installed: stamps/binutils_built
	@$(announce) && \
	( cd build/binutils && $(MAKE) install ) \
	&& $(touch)

# zlib

stamps/zlib_configured: stamps/unpack_toolchain
	@$(announce) && \
	( cd $(ZLIB_DIR) && ./configure \
		--prefix="$(TEMPINST)" ) \
	&& $(touch)

stamps/zlib_built: stamps/zlib_configured
	@$(announce) && \
	( cd $(ZLIB_DIR) && $(MAKE) ) \
	&& $(touch)

stamps/zlib_installed: stamps/zlib_built
	@$(announce) && \
	( cd $(ZLIB_DIR) && $(MAKE) install ) \
	&& $(touch)

# gmp

stamps/gmp_configured: stamps/unpack_toolchain
	@$(announce) && \
	( mkdir -p build/gmp && cd build/gmp && \
		export LD_LIBRARY_PATH=$(TEMPINST)/lib:"$$LD_LIBRARY_PATH" && \
		../../$(GMP_DIR)/configure \
		--host=$(HOST) \
		--build=$(HOST) \
		--target=$(HOST) \
		--prefix=$(TEMPINST) \
		--libdir=$(TEMPINST)/lib \
		--disable-shared \
		--enable-cxx ) \
	&& $(touch)

stamps/gmp_built: stamps/gmp_configured
	@$(announce) && \
	( cd build/gmp && $(MAKE) ) \
	&& $(touch)

stamps/gmp_installed: stamps/gmp_built
	@$(announce) && \
	( cd build/gmp && $(MAKE) install ) \
	&& $(touch)

stamps/gmp_checked: stamps/gmp_installed
	@$(announce) && \
	( cd build/gmp && $(MAKE) CFLAGS='-O2 -g' check ) \
	&& $(touch)

# mpfr

stamps/mpfr_configured: stamps/gmp_checked
	@$(announce) && \
	( mkdir -p build/mpfr && cd build/mpfr && ../../$(MPFR_DIR)/configure \
		--host=$(HOST) \
		--build=$(HOST) \
		--target=$(TARGET) \
		--prefix=$(TEMPINST) \
		--libdir=$(TEMPINST)/lib \
		--disable-shared \
		--with-gmp=$(TEMPINST) ) \
	&& $(touch)

stamps/mpfr_built: stamps/mpfr_configured
	@$(announce) && \
	( cd build/mpfr && $(MAKE) ) \
	&& $(touch)

stamps/mpfr_installed: stamps/mpfr_built
	@$(announce) && \
	( cd build/mpfr && $(MAKE) install ) \
	&& $(touch)

stamps/mpfr_checked: stamps/mpfr_installed
	@$(announce) && \
	( cd build/mpfr && $(MAKE) check ) \
	&& $(touch)

# mpc

stamps/mpc_configured: stamps/gmp_checked stamps/mpfr_checked
	@$(announce) && \
	( mkdir -p build/mpc && cd build/mpc && ../../$(MPC_DIR)/configure \
		--host=$(HOST) \
		--build=$(HOST) \
		--target=$(TARGET) \
		--prefix=$(TEMPINST) \
		--libdir=$(TEMPINST)/lib \
		--disable-shared \
		--with-gmp=$(TEMPINST) \
		--with-mpfr-lib=$(TEMPINST)/lib \
		--with-mpfr-include=$(TEMPINST)/include ) \
	&& $(touch)

stamps/mpc_built: stamps/mpc_configured
	@$(announce) && \
	( cd build/mpc && $(MAKE) ) \
	&& $(touch)

stamps/mpc_installed: stamps/mpc_built
	@$(announce) && \
	( cd build/mpc && $(MAKE) install ) \
	&& $(touch)

stamps/mpc_checked: stamps/mpc_installed
	@$(announce) && \
	( cd build/mpc && $(MAKE) check ) \
	&& $(touch)

# ppl

stamps/ppl_configured: stamps/gmp_checked
	@$(announce) && \
	( mkdir -p build/ppl && cd build/ppl && ../../$(PPL_DIR)/configure \
		--host=$(HOST) \
		--build=$(HOST) \
		--target=$(TARGET) \
		--prefix=$(TEMPINST) \
		--libdir=$(TEMPINST)/lib \
		--disable-shared \
		--disable-nls \
		--with-libgmp-prefix=$(TEMPINST) ) \
	&& $(touch)

stamps/ppl_built: stamps/ppl_configured
	@$(announce) && \
	( cd build/ppl && $(MAKE) ) \
	&& $(touch)

stamps/ppl_installed: stamps/ppl_built
	@$(announce) && \
	( cd build/ppl && $(MAKE) install ) \
	&& $(touch)

# cloog

stamps/cloog_configured: stamps/gmp_checked stamps/ppl_installed
	@$(announce) && \
	( mkdir -p build/cloog && cd build/cloog && \
		../../$(CLOOG_DIR)/configure \
			--host=$(HOST) \
			--build=$(HOST) \
			--target=$(TARGET) \
			--prefix=$(TEMPINST) \
			--libdir=$(TEMPINST)/lib \
			--disable-shared \
			--disable-nls \
			--with-gmp-prefix=$(TEMPINST) \
			--with-ppl-prefix=$(TEMPINST) ) \
	&& $(touch)

stamps/cloog_built: stamps/cloog_configured
	@$(announce) && \
	( cd build/cloog && $(MAKE) ) \
	&& $(touch)

stamps/cloog_installed: stamps/cloog_built
	@$(announce) && \
	( cd build/cloog && $(MAKE) install ) \
	&& $(touch)

stamps/cloog_checked: stamps/cloog_installed
	@$(announce) && \
	( cd build/cloog && $(MAKE) check ) \
	&& $(touch)

# gcc pre

stamps/gcc_pre_configured: stamps/zlib_installed stamps/gmp_checked stamps/mpfr_checked stamps/mpc_checked stamps/ppl_installed stamps/cloog_checked stamps/binutils_installed
	@$(announce) && \
	( mkdir -p build/gcc_pre && cd build/gcc_pre && \
		export AR_FOR_TARGET=$(TARGET)-ar && \
		export NM_FOR_TARGET=$(TARGET)-nm && \
		export OBJDUMP_FOR_TARGET=$(TARGET)-objdump && \
		export STRIP_FOR_TARGET=$(TARGET)-strip && \
		export LD_LIBRARY_PATH="$$LD_LIBRARY_PATH":$(TEMPINST)/lib && \
		export CPATH="$$CPATH":$(TEMPINST)/include && \
		../../$(GCC_DIR)/configure \
			--build=$(HOST) \
			--host=$(HOST) \
			--target=$(TARGET) \
			--disable-libmudflap \
			--disable-libstdcxx-pch \
			--enable-extra-sgxx-multilibs \
			--with-mode=arm \
			--with-arch=armv5te \
			--with-float=soft \
			--with-gnu-as \
			--with-gnu-ld \
			--with-specs='%{save-temps: -fverbose-asm}' \
			--disable-lto \
			--with-pkgversion="$(PKGCONF)" \
			--with-bugurl="$(BTURL)" \
			--disable-nls \
			--prefix=$(TEMPINST) \
			--disable-shared \
			--disable-threads \
			--disable-libssp \
			--disable-libgomp \
			--without-headers \
			--with-newlib \
			--disable-decimal-float \
			--disable-libffi \
			--enable-languages=c \
			--with-gmp-include=$(TEMPINST)/include \
			--with-gmp-lib=$(TEMPINST)/lib \
			--with-mpfr-include=$(TEMPINST)/include \
			--with-mpfr-lib=$(TEMPINST)/lib \
			--with-mpc-include=$(TEMPINST)/include \
			--with-mpc-lib=$(TEMPINST)/lib \
			--with-ppl-include=$(TEMPINST)/include \
			--with-ppl-lib=$(TEMPINST)/lib \
			--with-host-libstdcxx="-static-libgcc -Wl,-Bstatic,-lstdc++,-Bdynamic -lm" \
			--with-cloog=$(TEMPINST) \
			--enable-poison-system-directories \
			--with-build-time-tools=$(TEMPINST)/$(TARGET)/bin \
			--with-pic=yes \
			--enable-clocale=auto ) \
	&& $(touch)

stamps/gcc_pre_built: stamps/gcc_pre_configured
	@$(announce) && \
	( cd build/gcc_pre && \
		export AR_FOR_TARGET=$(TARGET)-ar && \
		export NM_FOR_TARGET=$(TARGET)-nm && \
		export OBJDUMP_FOR_TARGET=$(TARGET)-objdump && \
		export STRIP_FOR_TARGET=$(TARGET)-strip && \
		$(MAKE) ) \
	&& $(touch)

stamps/gcc_pre_installed: stamps/gcc_pre_built
	@$(announce) && \
	( cd build/gcc_pre && $(MAKE) install ) \
	&& $(touch)

# newlib

stamps/newlib_configured: stamps/gcc_pre_installed
	@$(announce) && \
	( mkdir -p build/newlib && cd build/newlib && \
		export PATH=$$PATH:$(TEMPINST)/bin && \
		../../$(NEWLIB_DIR)/configure \
		--host=$(HOST) \
		--build=$(HOST) \
		--target=$(TARGET) \
		--prefix=$(TEMPINST) \
		--enable-newlib-io-long-long \
		--disable-newlib-supplied-syscalls \
		--enable-shared \
		--disable-libgloss \
		--disable-newlib-supplied-syscalls \
		--disable-nls ) \
	&& $(touch)

stamps/newlib_built: stamps/newlib_configured
	@$(announce) && \
	( cd build/newlib && \
		export PATH=$$PATH:$(TEMPINST)/bin && \
		$(MAKE) ) \
	&& $(touch)

stamps/newlib_installed: stamps/newlib_built
	@$(announce) && \
	( cd build/newlib && \
		export PATH=$$PATH:$(TEMPINST)/bin && \
		$(MAKE) install ) \
	&& $(touch)

# gcc post

stamps/gcc_configured: stamps/newlib_installed
	@$(announce) && \
	( mkdir -p build/gcc_post && cd build/gcc_post && \
		export AR_FOR_TARGET=$TARGET-ar && \
		export NM_FOR_TARGET=$TARGET-nm && \
		export OBJDUMP_FOR_TARGET=$TARGET-objdump && \
		export STRIP_FOR_TARGET=$TARGET-strip && \
		../../$(GCC_DIR)/configure \
			--build=$(HOST) \
			--host=$(HOST) \
			--target=$(TARGET) \
			--enable-threads \
			--disable-libmudflap \
			--disable-libssp \
			--disable-libstdcxx-pch \
			--enable-extra-sgxx-multilibs \
			--with-mode=arm \
			--with-arch=armv5te \
			--with-float=soft \
			--with-gnu-as \
			--with-gnu-ld \
			--with-specs='%{save-temps: -fverbose-asm}' \
			--enable-languages=c,c++ \
			--enable-shared \
			--disable-lto \
			--with-newlib \
			--with-pkgversion="$(PKGCONF)" \
			--with-bugurl="$(BTURL)" \
			--disable-nls \
			--prefix=$(TEMPINST) \
			--with-headers=yes \
			--enable-decimal-float=bid \
			--with-gmp-include=$(TEMPINST)/include \
			--with-gmp-lib=$(TEMPINST)/lib \
			--with-mpfr-include=$(TEMPINST)/include \
			--with-mpfr-lib=$(TEMPINST)/lib \
			--with-mpc-include=$(TEMPINST)/include \
			--with-mpc-lib=$(TEMPINST)/lib \
			--with-ppl-include=$(TEMPINST)/include \
			--with-ppl-lib=$(TEMPINST)/lib \
			--with-host-libstdcxx="-static-libgcc -Wl,-Bstatic,-lstdc++,-Bdynamic -lm" \
			--with-cloog=$(TEMPINST) \
			--disable-libgomp \
			--enable-poison-system-directories \
			--with-build-time-tools=$(TEMPINST)/$(TARGET)/bin \
			--with-pic=yes \
			--enable-clocale=auto ) \
	&& $(touch)

stamps/gcc_built: stamps/gcc_configured
	@$(announce) && \
	( cd build/gcc_post && \
		export AR_FOR_TARGET=$(TARGET)-ar && \
		export NM_FOR_TARGET=$(TARGET)-nm && \
		export OBJDUMP_FOR_TARGET=$(TARGET)-objdump && \
		export STRIP_FOR_TARGET=$(TARGET)-strip && \
		$(MAKE) ) \
	&& $(touch)

stamps/gcc_installed: stamps/gcc_built
	@$(announce) && \
	( cd build/gcc_post && $(MAKE) install ) \
	&& $(touch)

# tidyup

stamps/tidyup: stamps/gcc_installed
	@$(announce) && \
	( find $(TEMPINST) -name libiberty.a -exec rm '{}' ';' && \
		find $(TEMPINST) -name *.la -exec rm '{}' ';' && \
		find $(TEMPINST)/bin -type f -perm /111 -exec strip '{}' ';' && \
		find $(TEMPINST)/$(TARGET)/bin -type f -perm /111 -exec strip '{}' ';' ) \
	&& $(touch)

# install

install: stamps/gcc_installed
	@test -n "$(INSTPREFIX)" || ( echo "you need to define INSTPREFIX=/path/to/toolchain/instalation/dir/of/your/choice" && exit 1 )
	@echo -n "installing in $(INSTPREFIX)... "
	@mkdir -p "$(INSTPREFIX)" && cp -r $(TEMPINST)/* "$(INSTPREFIX)/" && \
		printf "export CROSS_COMPILE=$(TARGET)-\nexport PATH=\$$PATH:$(INSTPREFIX)/bin\n" >$(INSTPREFIX)/init.sh || exit 1
	@echo "done"
	
# clean

clean:
	rm -rf stamps build $(TEMPINST)
	rm -f $(TOOLCHAIN_ARCHIVE)
	rm -rf src
	rm -f README.html

.PHONY:clean

