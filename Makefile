
ifeq ($(shell uname -o 2> /dev/null),Cygwin)

ifeq (,$(findstring Win64,$(CMAKE_FLAGS)))
DL_FILE := gtk+-bundle_3.6.4-20130921_win32.zip
else
DL_FILE := gtk+-bundle_3.6.4-20131201_win64.zip
endif
DL_LINK := http://win32builder.gnome.org/
UNZIP_DIR := gtk3

BUILD_SYSTEM:=$(OS)
ifeq ($(BUILD_SYSTEM),Windows_NT)
BUILD_SYSTEM:=$(shell uname -o 2> NUL || echo Windows_NT) # set to Cygwin if appropriate
else
BUILD_SYSTEM:=$(shell uname -s)
endif
BUILD_SYSTEM:=$(strip $(BUILD_SYSTEM))

# Figure out where to build the software.
#   Use BUILD_PREFIX if it was passed in.
#   If not, search up to four parent directories for a 'build' directory.
#   Otherwise, use ./build.
ifeq ($(BUILD_SYSTEM), Windows_NT)
ifeq "$(BUILD_PREFIX)" ""
BUILD_PREFIX:=$(shell (for %%x in (. .. ..\.. ..\..\.. ..\..\..\..) do ( if exist %cd%\%%x\build ( echo %cd%\%%x\build & exit ) )) & echo %cd%\build )
endif
# don't clean up and create build dir as I do in linux.  instead create it during configure.
else
ifeq "$(BUILD_PREFIX)" ""
BUILD_PREFIX:=$(shell for pfx in ./ .. ../.. ../../.. ../../../..; do d=`pwd`/$$pfx/build;\
               if [ -d $$d ]; then echo $$d; exit 0; fi; done; echo `pwd`/build)
endif
# create the build directory if needed, and normalize its path name
BUILD_PREFIX:=$(shell mkdir -p $(BUILD_PREFIX) && cd $(BUILD_PREFIX) && echo `pwd`)
endif

ifeq "$(BUILD_SYSTEM)" "Cygwin"
  BUILD_PREFIX:=$(shell cygpath -m $(BUILD_PREFIX))
endif

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
	@echo "BUILD_PREFIX: $(BUILD_PREFIX)"

$(BUILD_PREFIX)/lib/pkgconfig/glib-2.0.pc: $(BUILD_PREFIX)/lib/libglib-2.0-0.dll $(BUILD_PREFIX)/lib/libintl-8.dll
	echo "writing $@"
	$(file > $@,$(GLIB_PC))

$(BUILD_PREFIX)/lib/pkgconfig/gthread-2.0.pc: $(BUILD_PREFIX)/lib/libgthread-2.0-0.dll
	echo "writing $@"
	$(file > $@,$(GTHREAD_PC))

$(BUILD_PREFIX)/lib/% : $(UNZIP_DIR)/bin/%
	echo "installing $@"
ifeq ($(BUILD_SYSTEM), Windows_NT)
	copy $< $@
else
	cp -f $< $@
endif

clean:
	-( cd $(BUILD_PREFIX)/lib/pkgconfig && rm glib-2.0.pc gthread-2.0.pc )
	-( cd $(BUILD_PREFIX)/lib && rm libglib-2.0-0.dll libgthread-2.0-0.dll libintl-8.dll libiconv-2.dll pthreadGC2.dll )

# library dependencies (figured out using depends.exe)

$(BUILD_PREFIX)/lib/libintl-8.dll : $(BUILD_PREFIX)/lib/libiconv-2.dll $(BUILD_PREFIX)/lib/pthreadGC2.dll

$(BUILD_PREFIX)/lib/libgthread-2.0-0.dll : $(BUILD_PREFIX)/lib/libglib-2.0-0.dll


# Default to a less-verbose build.  If you want all the gory compiler output,
# run "make VERBOSE=1"
$(VERBOSE).SILENT:

else

# if not windows/cygwin, then do nothing

all: 

clean: 

endif
