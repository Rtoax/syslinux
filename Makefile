## -----------------------------------------------------------------------
##  $Id$
##
##   Copyright 1998-2001 H. Peter Anvin - All Rights Reserved
##
##   This program is free software; you can redistribute it and/or modify
##   it under the terms of the GNU General Public License as published by
##   the Free Software Foundation, Inc., 675 Mass Ave, Cambridge MA 02139,
##   USA; either version 2 of the License, or (at your option) any later
##   version; incorporated herein by reference.
##
## -----------------------------------------------------------------------

#
# Main Makefile for SYSLINUX
#

NASM	= nasm
CC	= gcc
CFLAGS	= -Wall -O2 -fomit-frame-pointer
LDFLAGS	= -O2 -s

BINDIR  = /usr/bin

VERSION = $(shell cat version)

.c.o:
	$(CC) $(CFLAGS) -c $<

#
# The BTARGET refers to objects that are derived from ldlinux.asm; we
# like to keep those uniform for debugging reasons; however, distributors 
# want to recompile the installers (ITARGET).
#
SOURCES = ldlinux.asm syslinux.asm syslinux.c copybs.asm \
	  pxelinux.asm pxe.inc mbr.asm gethostip.c
BTARGET = bootsect.bin ldlinux.sys ldlinux.bin ldlinux.lst pxelinux.0 mbr.bin
ITARGET = syslinux.com syslinux copybs.com gethostip
DOCS    = COPYING NEWS README TODO *.doc sample
OTHER   = Makefile bin2c.pl now.pl genstupid.pl keytab-lilo.pl version \
	  sys2ansi.pl
OBSOLETE = pxelinux.bin

# Things to install in /usr/bin
INSTALL_BIN = syslinux gethostip

all:	$(BTARGET) $(ITARGET) samples
	ls -l $(BTARGET) $(ITARGET)

installer: $(ITARGET) samples
	ls -l $(BTARGET) $(ITARGET)

samples:
	$(MAKE) -C sample all

# The DATE is set on the make command line when building binaries for
# official release.  Otherwise, substitute a hex string that is pretty much
# guaranteed to be unique to be unique from build to build.
ifndef HEXDATE
HEXDATE := $(shell perl now.pl ldlinux.asm pxelinux.asm)
endif
ifndef DATE
DATE    := $(HEXDATE)
endif

ldlinux.bin: ldlinux.asm
	$(NASM) -f bin -dVERSION="'$(VERSION)'" -dDATE_STR="'$(DATE)'" -dHEXDATE="$(HEXDATE)" -l ldlinux.lst -o ldlinux.bin ldlinux.asm
	perl genstupid.pl < ldlinux.lst

pxelinux.0: pxelinux.asm
	$(NASM) -f bin -dVERSION="'$(VERSION)'" -dDATE_STR="'$(DATE)'" -dHEXDATE="$(HEXDATE)" -l pxelinux.lst -o pxelinux.0 pxelinux.asm

bootsect.bin: ldlinux.bin
	dd if=ldlinux.bin of=bootsect.bin bs=512 count=1

ldlinux.sys: ldlinux.bin
	dd if=ldlinux.bin of=ldlinux.sys  bs=512 skip=1

mbr.bin: mbr.asm
	$(NASM) -f bin -l mbr.lst -o mbr.bin mbr.asm

syslinux.com: syslinux.asm bootsect.bin ldlinux.sys stupid.inc
	$(NASM) -f bin -l syslinux.lst -o syslinux.com syslinux.asm

copybs.com: copybs.asm
	$(NASM) -f bin -l copybs.lst -o copybs.com copybs.asm

bootsect_bin.c: bootsect.bin bin2c.pl
	perl bin2c.pl bootsect < bootsect.bin > bootsect_bin.c

ldlinux_bin.c: ldlinux.sys bin2c.pl
	perl bin2c.pl ldlinux < ldlinux.sys > ldlinux_bin.c

syslinux: syslinux.o bootsect_bin.o ldlinux_bin.o stupid.o
	$(CC) $(LDFLAGS) -o syslinux \
		syslinux.o bootsect_bin.o ldlinux_bin.o stupid.o

ldlinux.lst: ldlinux.bin
	: Generated by side effect

stupid.c: ldlinux.lst genstupid.pl
	perl genstupid.pl < ldlinux.lst

stupid.inc: stupid.c
	: Generated by side effect

stupid.o: stupid.c

gethostip.o: gethostip.c

gethostip: gethostip.o

install: all
	install -c $(INSTALL_BIN) $(BINDIR)

tidy:
	rm -f syslinux.lst copybs.lst *.o *_bin.c stupid.* pxelinux.lst
	rm -f $(OBSOLETE)

clean: tidy
	rm -f $(ITARGET)
	$(MAKE) -C sample clean

dist: tidy
	rm -f *~ \#* core

spotless: clean dist
	rm -f $(BTARGET)

#
# Hook to add private Makefile targets for the maintainer.
#
-include Makefile.private
