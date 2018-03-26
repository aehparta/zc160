## Makefile.am for #SOFTWARE_NAME#

AUTOMAKE_OPTIONS = foreign

noinst_PROGRAMS = zc160vgaemu
#lib_LTLIBRARIES = libexample.la

#zc160emu_SOURCES = \
#	main.c \
#	zc160.c \
#	mem.c \
#	hd44780.c

zc160vgaemu_SOURCES = \
	main_vga.c \
	vga.c \
	mem.c \
	z80cpu.c

#zc160emu_LDFLAGS = @libddebug_LIBS@ @libstrvar_LIBS@ @z80ex_LIBS@ @net3_LIBS@
#zc160emu_CFLAGS = @libddebug_CFLAGS@ @libstrvar_CFLAGS@ @z80ex_CFLAGS@ @net3_CFLAGS@

zc160vgaemu_LDFLAGS = @libddebug_LIBS@ @libstrvar_LIBS@ @z80ex_LIBS@ @sdl2_LIBS@
zc160vgaemu_CFLAGS = @libddebug_CFLAGS@ @libstrvar_CFLAGS@ @z80ex_CFLAGS@ @sdl2_CFLAGS@

#include_HEADERS = header.h

#pkgconfigdir = @libdir@/pkgconfig
#pkgconfig_DATA = @PACKAGE_NAME@.pc

