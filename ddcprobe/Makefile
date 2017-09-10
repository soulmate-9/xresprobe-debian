ARCH := $(patsubst i%86,i386,$(shell uname -m))
ARCH := $(patsubst sparc%,sparc,$(ARCH))
ARCH := $(patsubst ppc%,ppc,$(ARCH))

CC = gcc
CFLAGS = -W -Wall  -g -O2 #-DDEBUG
TARGETS = ddcprobe ddcxinfo 
DDC_OBJS = vesamode.o common.o
DDC_LIBS =

ifeq ($(findstring $(ARCH),i386), $(ARCH))
TARGETS += svgamodes modetest libvbe.a
DDC_OBJS += x86-common.o lrmi.o vbe.o
else
ifeq ($(findstring $(ARCH),x86_64), $(ARCH))
DDC_OBJS += x86-common.o vbe.o thunk.o x86emu/libx86emu.a
else
ifeq ($(ARCH),ppc)
DDC_OBJS += of.o minifind.o
else
DDC_OBJS += stub.o
endif
endif
endif

ifeq (.depend,$(wildcard .depend))
TARGET=all
else
TARGET=depend all
endif

everything: $(TARGET)

all: $(TARGETS)

install: $(TARGETS)
	mkdir -p $(DESTDIR)/usr/sbin
	cp -a ddcprobe $(DESTDIR)/usr/sbin/ddcprobe

 
# i386 and ppc targets
ddcprobe: $(DDC_OBJS) ddcprobe.o
	$(CC) $(CFLAGS) -o ddcprobe $(DDC_OBJS) ddcprobe.o $(DDC_LIBS)
ddcxinfo: $(DDC_OBJS) ddcxinfo.o
	$(CC) $(CFLAGS) -o ddcxinfo $(DDC_OBJS) ddcxinfo.o $(DDC_LIBS)

x86emu/libx86emu.a:
	make -C x86emu libx86emu.a

# i386 targets
svgamodes: x86-common.o lrmi.o vesamode.o vbe.o svgamodes.o
modetest: x86-common.o lrmi.o vesamode.o vbe.o modetest.o
libvbe.a: x86-common.o lrmi.o vesamode.o vbe.o
	$(AR) cru $@ $^

install-lib: $(prefix)/include/vbe.h $(prefix)/lib/libvbe.a

$(prefix)/include/vbe.h:
	install -m 644 vbe.h $(prefix)/include/vbe.h

$(prefix)/lib/libvbe.a:
	install -m 644 libvbe.a $(prefix)/lib/libvbe.a

clean:
	$(RM) $(TARGETS) *.o .depend core
	make -C x86emu clean

depend:
	$(CPP) -M $(CFLAGS) *.c > .depend

ifeq (.depend,$(wildcard .depend))
include .depend
endif                                           
