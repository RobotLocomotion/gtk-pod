DL_FILE := gtk+-bundle_3.6.4-20130921_win32.zip
DL_LINK := http://win32builder.gnome.org/
UNZIP_DIR := gtk3

# Figure out where to build the software.
#   Use BUILD_PREFIX if it was passed in.
#   If not, search up to four parent directories for a 'build' directory.
#   Otherwise, use ./build.
ifeq "$(BUILD_PREFIX)" ""
BUILD_PREFIX:=$(shell for pfx in .. ../.. ../../.. ../../../..; do d=`pwd`/$$pfx/build;\
	if [ -d $$d ]; then echo $$d; exit 0; fi; done; echo `pwd`/build)
endif
# create the build directory if needed, and normalize its path name
BUILD_PREFIX:=$(shell mkdir -p $(BUILD_PREFIX) && cd $(BUILD_PREFIX) && echo `pwd`)

GTK_DIR := $(shell pwd)/$(UNZIP_DIR)

define GLIB_PC
Name: glib-2.0
Description: GLIB as packaged by the GTK+ bundle
Requires: 
Version: 2.34.3
Libs: -L$(GTK_DIR)/lib -lglib-2.0 -lws2_32 -lwinmm
Cflags: -I$(GTK_DIR)/include/glib-2.0 -I$(GTK_DIR)/lib/glib-2.0/include
endef

define GTHREAD_PC
Name: gthread-2.0
Description: GThread as packaged by the GTK+ bundle
Requires: glib-2.0
Version: 2.34.3
Libs: -L$(GTK_DIR)/lib -lgthread-2.0
Cflags: 
endef


all: install

install: $(BUILD_PREFIX)/lib/pkgconfig/glib-2.0.pc $(BUILD_PREFIX)/lib/pkgconfig/gthread-2.0.pc

$(UNZIP_DIR)/bin/libglib-2.0-0.dll :
	@echo "\nDownloading GTK+ all-in-one bundle \n\n"
	wget -T 60 $(DL_LINK)/$(DL_FILE)
	@echo "\nunzipping to $(UNZIP_DIR) \n\n"
	unzip $(DL_FILE) -d $(UNZIP_DIR) && rm $(DL_FILE)
	@echo "\nBUILD_PREFIX: $(BUILD_PREFIX)\n\n"

$(BUILD_PREFIX)/lib/pkgconfig/glib-2.0.pc: $(BUILD_PREFIX)/lib/libglib-2.0-0.dll $(BUILD_PREFIX)/lib/libintl-8.dll
	echo "writing $@"
	$(file > $@,$(GLIB_PC))

$(BUILD_PREFIX)/lib/pkgconfig/gthread-2.0.pc: $(BUILD_PREFIX)/lib/libgthread-2.0-0.dll
	echo "writing $@"
	$(file > $@,$(GTHREAD_PC))

$(BUILD_PREFIX)/lib/% : $(UNZIP_DIR)/bin/%
	echo "installing $@"
	cp -f $< $@

clean:
	-( cd $(BUILD_PREFIX)/lib/pkgconfig && rm glib-2.0.pc gthread-2.0.pc )
	-( cd $(BUILD_PREFIX)/lib && rm libglib-2.0-0.dll libgthread-2.0-0.dll libintl-8.dll libiconv-2.dll pthreadGC2.dll )

# library dependencies (figured out using depends.exe)

$(BUILD_PREFIX)/lib/libintl-8.dll : $(BUILD_PREFIX)/lib/libiconv-2.dll $(BUILD_PREFIX)/lib/pthreadGC2.dll

$(BUILD_PREFIX)/lib/libgthread-2.0-0.dll : $(BUILD_PREFIX)/lib/libglib-2.0-0.dll


# Default to a less-verbose build.  If you want all the gory compiler output,
# run "make VERBOSE=1"
$(VERBOSE).SILENT:
