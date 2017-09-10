DATADIR := /usr/share/xresprobe
SBINDIR := /usr/sbin

all:
	$(MAKE) -C ddcprobe

clean:
	$(MAKE) -C ddcprobe clean

install:
	$(MAKE) -C ddcprobe install DESTDIR="$(DESTDIR)"
	mkdir -p $(DESTDIR)$(DATADIR)/
	mkdir -p $(DESTDIR)$(SBINDIR)/
	install -m755 xresprobe $(DESTDIR)$(SBINDIR)/
	install -m755 xprobe.sh $(DESTDIR)$(DATADIR)/
	install -m755 ddcprobe.sh $(DESTDIR)$(DATADIR)/
	install -m755 lcdsize.sh $(DESTDIR)$(DATADIR)/
	install -m755 bitdepth.sh $(DESTDIR)$(DATADIR)/
	install -m755 rigprobe.sh $(DESTDIR)$(DATADIR)/
	install -m644 xorg.conf $(DESTDIR)$(DATADIR)/
