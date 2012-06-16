ifeq ($(CROSS_COMPILE),)
$(error CROSS_COMPILE not defined, source the init.sh script from the bali-sdk installation folder)
endif

APPID   := 93bt1p123e
APPNAME := hello

BADA_GENHTB         = bada-genhtb
BADA_BROKER         = bada-broker
BADA_SIGNING        = bada-signing

bada_toolchain_path := $(shell which $(CROSS_COMPILE)gcc | sed -e "s/\\/bin\\/$(CROSS_COMPILE)gcc//")
bada_include_path   := $(bada_toolchain_path)/arm-bada-eabi/include/bada
bada_model_path     := $(bada_toolchain_path)/usr/share/bada/model
bada_crypto_path    := $(bada_toolchain_path)/usr/share/bada/crypto

bada_appdir        := $(APPID)
bada_appexe        := $(bada_appdir)/Bin/$(APPNAME).exe
bada_manifest      := $(bada_appdir)/Info/manifest.xml
bada_hashtable     := $(bada_appdir)/Info/$(APPNAME).htb
bada_signature     := $(bada_appdir)/signature.xml

cxx_sources        := $(wildcard *.cpp)
c_sources          := $(wildcard *.c)

cxx_objs           := $(patsubst %.cpp,build/%.o,$(cxx_sources))
c_objs             := $(patsubst %.c,build/%.o,$(c_sources))
deps               := $(patsubst %,build/%.dep,$(cxx_sources) $(c_sources))

LD                 := $(CROSS_COMPILE)g++
CC                 := $(CROSS_COMPILE)gcc
CXX                := $(CROSS_COMPILE)g++
CPP                := $(CROSS_COMPILE)cpp

CPPFLAGS           := -DSHP -I. -I"$(bada_include_path)"
CFLAGS             := -O2 -Wall -fpic -fno-dwarf2-cfi-asm -fshort-wchar -march=armv5te -mlittle-endian -mthumb -mthumb-interwork -mfloat-abi=soft
CXXFLAGS           := -O2 -Wall -fpic -fno-dwarf2-cfi-asm -fshort-wchar -march=armv5te -mlittle-endian -mthumb -mthumb-interwork -mfloat-abi=soft
LDFLAGS            := -nostartfiles -Wl,-u__gnu_thumb1_case_si,-u__gnu_thumb1_case_sqi,-u__gnu_thumb1_case_uqi,-u__gnu_thumb1_case_shi,-u__gnu_thumb1_case_uhi -shared -lgcc_sa

LIBOBJS            += $(bada_model_path)/WaveWQVGA/Target/osp_rt0.a
LIBOBJS            += $(bada_model_path)/WaveWQVGA/Target/FOsp.so
LIBOBJS            += $(bada_model_path)/WaveWQVGA/Target/StubDynCast.so

all: $(bada_signature)
.PHONY: all

$(bada_hashtable): $(bada_appexe) $(bada_manifest)
	@echo HASH $@ && mkdir -p $(dir $@) && $(BADA_GENHTB) "$(bada_manifest)" "$<" "$@"
	
$(bada_signature): $(bada_appexe) $(bada_hashtable) $(bada_manifest)
	@echo SIGN $@ && mkdir -p $(dir $@) && $(BADA_SIGNING) --app-path="$(bada_appdir)" --app-name="$(APPNAME)" --crypto-path="$(bada_crypto_path)" --output="$@"

$(bada_appexe): $(cxx_objs) $(c_objs)
	@echo LD   $@ && mkdir -p $(dir $@) && $(LD) $(LDFLAGS) $^ $(LIBOBJS) -o $@

build/%.dep: %
	@echo CPP  $@ && mkdir -p $(dir $@) && $(CPP) -MM $< $(CPPFLAGS) | sed "s,\(.*\)\.o[ :]*,$(@D)/\1.o $@ : ,g" >$@

build/%.o: %.cpp
	@echo C++  $@ && mkdir -p $(dir $@) && $(CXX) $(CPPFLAGS) $(CXXFLAGS) -c $< -o $@

build/%.o: %.c
	@echo CC   $@ && mkdir -p $(dir $@) && $(CC) $(CPPFLAGS) $(CFLAGS) -c $< -o $@

install: all
	@echo INSTALL && $(BADA_BROKER) install $(APPID)
.PHONY: install

-include $(deps)

clean:
	rm -f $(cxx_objs) $(c_objs) $(bada_appexe) $(bada_hashtable) $(bada_signature) $(deps)
.PHONY: clean
