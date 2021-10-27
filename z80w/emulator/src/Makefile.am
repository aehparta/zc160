## Makefile.am for #SOFTWARE_NAME#

AUTOMAKE_OPTIONS = foreign

noinst_PROGRAMS = emuz80w
#lib_LTLIBRARIES = libexample.la

emuz80w_SOURCES = \
	main.c \
	emuz80w.c \
	mem.c \
	hd44780.c

#libexample_la_SOURCES = \
#	lib.c

emuz80w_LDFLAGS = @libddebug_LIBS@ @libstrvar_LIBS@ @z80ex_LIBS@ @net3_LIBS@
emuz80w_CFLAGS = @libddebug_CFLAGS@ @libstrvar_CFLAGS@ @z80ex_CFLAGS@ @net3_CFLAGS@
#libexample_la_LIBADD = -lm -lpthread

#include_HEADERS = header.h

pkgconfigdir = @libdir@/pkgconfig
pkgconfig_DATA = @PACKAGE_NAME@.pc

