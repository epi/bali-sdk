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

PKGCONF           := GCC 4.5.3 for Bada
BUGURL            := https://support.codesourcery.com/GNUToolchain/

ASCIIDOC           = asciidoc -o $@ -a doctime

HOST     := $(shell gcc -v 2>&1 | grep '\-\-build=' | sed -e 's/^.*--build=//' | sed -e 's/\s.*$$//')
TARGET   := arm-bada-eabi
TEMPINST := $(shell pwd)/tempinst

touch = mkdir -p stamps && touch $@

all: stamps/gcc_installed
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

stamps/binutils_configured: stamps/unpack_toolchain
	( mkdir -p build/binutils && cd build/binutils && ../../$(BINUTILS_DIR)/configure \
		--host="$(HOST)" \
		--build="$(HOST)" \
		--target="$(TARGET)" \
		--prefix="$(TEMPINST)" \
		--with-pkgversion="$(PKGCONF)" \
		--with-bugurl="$(BTURL)" \
		--disable-nls \
		--disable-werror \
		--disable-poison-system-directories ) \
	&& $(touch)

stamps/binutils_built: stamps/binutils_configured
	( cd build/binutils && $(MAKE) ) \
	&& $(touch)

stamps/binutils_installed: stamps/binutils_built
	( cd build/binutils && $(MAKE) install ) \
	&& $(touch)

# zlib

stamps/zlib_configured: stamps/unpack_toolchain
	( cd $(ZLIB_DIR) && ./configure \
		--prefix="$(TEMPINST)" ) \
	&& $(touch)

stamps/zlib_built: stamps/zlib_configured
	( cd $(ZLIB_DIR) && $(MAKE) ) \
	&& $(touch)

stamps/zlib_installed: stamps/zlib_built
	( cd $(ZLIB_DIR) && $(MAKE) install ) \
	&& $(touch)

# gmp

#		--target=$(TARGET) \

stamps/gmp_configured: stamps/unpack_toolchain
	( mkdir -p build/gmp && cd build/gmp && \
		export LD_LIBRARY_PATH=$(TEMPINST)/lib:"$$LD_LIBRARY_PATH" && \
		../../$(GMP_DIR)/configure \
		--host=$(HOST) \
		--build=$(HOST) \
		--prefix=$(TEMPINST) \
		--disable-shared \
		--enable-cxx ) \
	&& $(touch)

stamps/gmp_built: stamps/gmp_configured
	( cd build/gmp && $(MAKE) ) \
	&& $(touch)

stamps/gmp_installed: stamps/gmp_built
	( cd build/gmp && $(MAKE) install ) \
	&& $(touch)

# mpfr

stamps/mpfr_configured: stamps/gmp_installed
	( mkdir -p build/mpfr && cd build/mpfr && ../../$(MPFR_DIR)/configure \
		--host=$(HOST) \
		--build=$(HOST) \
		--target=$(TARGET) \
		--prefix=$(TEMPINST) \
		--disable-shared \
		--disable-nls \
		--with-gmp=$(TEMPINST) ) \
	&& $(touch)

stamps/mpfr_built: stamps/mpfr_configured
	( cd build/mpfr && $(MAKE) ) \
	&& $(touch)

stamps/mpfr_installed: stamps/mpfr_built
	( cd build/mpfr && $(MAKE) install ) \
	&& $(touch)

# mpc

stamps/mpc_configured: stamps/gmp_installed stamps/mpfr_installed
	( mkdir -p build/mpc && cd build/mpc && ../../$(MPC_DIR)/configure \
		--host=$(HOST) \
		--build=$(HOST) \
		--target=$(TARGET) \
		--prefix=$(TEMPINST) \
		--disable-shared \
		--with-gmp=$(TEMPINST) \
		--with-mpfr-lib=$(TEMPINST)/lib \
		--with-mpfr-include=$(TEMPINST)/include ) \
	&& $(touch)

stamps/mpc_built: stamps/mpc_configured
	( cd build/mpc && $(MAKE) ) \
	&& $(touch)

stamps/mpc_installed: stamps/mpc_built
	( cd build/mpc && $(MAKE) install ) \
	&& $(touch)

# ppl

stamps/ppl_configured: stamps/gmp_installed
	( mkdir -p build/ppl && cd build/ppl && ../../$(PPL_DIR)/configure \
		--host=$(HOST) \
		--build=$(HOST) \
		--target=$(TARGET) \
		--prefix=$(TEMPINST) \
		--disable-shared \
		--disable-nls \
		--with-libgmp-prefix=$(TEMPINST) ) \
	&& $(touch)

stamps/ppl_built: stamps/ppl_configured
	( cd build/ppl && $(MAKE) ) \
	&& $(touch)

stamps/ppl_installed: stamps/ppl_built
	( cd build/ppl && $(MAKE) install ) \
	&& $(touch)

# cloog

stamps/cloog_configured: stamps/gmp_installed stamps/ppl_installed
	( mkdir -p build/cloog && cd build/cloog && \
		../../$(CLOOG_DIR)/configure \
			--host=$(HOST) \
			--build=$(HOST) \
			--target=$(TARGET) \
			--prefix=$(TEMPINST) \
			--disable-shared \
			--disable-nls \
			--with-gmp-prefix=$(TEMPINST) ) \
			--with-ppl-prefix=$(TEMPINST) ) \
	&& $(touch)

stamps/cloog_built: stamps/cloog_configured
	( cd build/cloog && \
		$(MAKE) ) \
	&& $(touch)

stamps/cloog_installed: stamps/cloog_built
	( cd build/cloog && \
		$(MAKE) install ) \
	&& $(touch)

# gcc pre

#			--with-gnu-ld '--with-specs=%{O2:%{!fno-remove-local-statics: -fremove-local-statics}} %{O*:%{O|O0|O1|O2|Os:;:%{!fno-remove-local-statics: -fremove-local-statics}}}' \

stamps/gcc_pre_configured: stamps/zlib_installed stamps/gmp_installed stamps/mpfr_installed stamps/mpc_installed stamps/ppl_installed stamps/cloog_installed stamps/binutils_installed
	( mkdir -p build/gcc_pre && cd build/gcc_pre && \
		export AR_FOR_TARGET=$(TARGET)-ar && \
		export NM_FOR_TARGET=$(TARGET)-nm && \
		export OBJDUMP_FOR_TARGET=$(TARGET)-objdump && \
		export STRIP_FOR_TARGET=$(TARGET)-strip && \
		export LD_LIBRARY_PATH="$$LD_LIBRARY_PATH":$(TEMPINST)/lib && \
		export CPATH="$$CPATH":$(TEMPINST)/include && \
		../../$(GCC_DIR)/configure \
			--host=$(HOST) \
			--build=$(HOST) \
			--target=$(TARGET) \
			--enable-threads \
			--disable-libmudflap \
			--disable-libssp \
			--disable-libstdcxx-pch \
			--enable-extra-sgxx-multilibs \
			--disable-multilib \
			--with-mode=thumb \
			--with-cpu=cortex-a8 \
			--with-float=hard \
			--with-gnu-as \
			--with-gnu-ld \
			--enable-languages=c,c++ \
			--enable-shared \
			--disable-lto \
			--with-newlib \
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
			--disable-libgomp \
			--disable-poison-system-directories \
			--with-build-time-tools=$(TEMPINST)/$(TARGET)/bin ) \
	&& $(touch)

stamps/gcc_pre_built: stamps/gcc_pre_configured
	( cd build/gcc_pre && \
		export AR_FOR_TARGET=$(TARGET)-ar && \
		export NM_FOR_TARGET=$(TARGET)-nm && \
		export OBJDUMP_FOR_TARGET=$(TARGET)-objdump && \
		export STRIP_FOR_TARGET=$(TARGET)-strip && \
		$(MAKE) ) \
	&& $(touch)

stamps/gcc_pre_installed: stamps/gcc_pre_built
	( cd build/gcc_pre && $(MAKE) install ) \
	&& $(touch)

# newlib

stamps/newlib_configured: stamps/gcc_pre_installed
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
	( cd build/newlib && \
		export PATH=$$PATH:$(TEMPINST)/bin && \
		$(MAKE) ) \
	&& $(touch)

stamps/newlib_installed: stamps/newlib_built
	( cd build/newlib && \
		export PATH=$$PATH:$(TEMPINST)/bin && \
		$(MAKE) install ) \
	&& $(touch)

# gcc post

#			'--with-specs=%{O2:%{!fno-remove-local-statics: -fremove-local-statics}} %{O*:%{O|O0|O1|O2|Os:;:%{!fno-remove-local-statics: -fremove-local-statics}}}' \

stamps/gcc_configured: stamps/newlib_installed
	( mkdir -p build/gcc_post && cd build/gcc_post && \
		export AR_FOR_TARGET=$TARGET-ar && \
		export NM_FOR_TARGET=$TARGET-nm && \
		export OBJDUMP_FOR_TARGET=$TARGET-objdump && \
		export STRIP_FOR_TARGET=$TARGET-strip && \
		../../$(GCC_DIR)/configure \
			--host=$(HOST) \
			--build=$(HOST) \
			--target=$(TARGET) \
			--enable-threads \
			--disable-libmudflap \
			--disable-libssp \
			--disable-libstdcxx-pch \
			--enable-extra-sgxx-multilibs \
			--disable-multilib \
			--with-mode=thumb \
			--with-cpu=cortex-a8 \
			--with-float=hard \
			--with-gnu-as \
			--with-gnu-ld \
			--enable-languages=c,c++ \
			--enable-shared \
			--disable-lto \
			--with-newlib \
			--with-pkgversion="$(PKGCONF)" \
			--with-bugurl="$(BTURL)" \
			--disable-nls \
			--prefix=$(TEMPINST) \
			--with-headers=yes \
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
			--disable-poison-system-directories \
			--with-build-time-tools=$(TEMPINST)/$(TARGET)/bin ) \
	&& $(touch)

stamps/gcc_built: stamps/gcc_configured
	( cd build/gcc_post && \
		export AR_FOR_TARGET=$(TARGET)-ar && \
		export NM_FOR_TARGET=$(TARGET)-nm && \
		export OBJDUMP_FOR_TARGET=$(TARGET)-objdump && \
		export STRIP_FOR_TARGET=$(TARGET)-strip && \
		$(MAKE) ) \
	&& $(touch)

stamps/gcc_installed: stamps/gcc_built
	( cd build/gcc_post && $(MAKE) install ) \
	&& $(touch)

# install

install: stamps/gcc_installed
	@test -n "$(INSTPREFIX)" || ( echo "you need to define INSTPREFIX=/path/to/toolchain/instalation/dir/of/your/choice" && exit 1 )
	@echo -n "installing at $(INSTPREFIX)... "
	@mkdir -p "$(INSTPREFIX)" && cp -r $(TEMPINST)/* "$(INSTPREFIX)/" && \
		printf "export CROSS_COMPILE=$(TARGET)-\nexport PATH=\$$PATH:$(INSTPREFIX)/bin\n" >$(INSTPREFIX)/init.sh || exit 1
	@echo "done"
	
# clean

clean:
	rm -rf stamps build $(TEMPINST)
	rm $(TOOLCHAIN_ARCHIVE)
	rm -rf src

.PHONY:clean

