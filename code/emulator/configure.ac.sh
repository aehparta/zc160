#!/bin/bash

bash=/bin/bash
set -a

# set and clear config
CONFIG="configure.ac"
echo "" > $CONFIG

# create pkgconfig-file (.pc) if needed
#$bash "./debian/pkgconfig.pc.sh" > "./src/$PACKAGE_NAME.pc"

# learn to use AC_DEFUN(macro_name, macro_func)!

echo "
DISABLE_PKGS=\"\"
DISABLE_LIBS=\"\"

dnl use this file with autoconf to produce a configure script.
AC_INIT([$PACKAGE_NAME], [$PACKAGE_VERSION])
CXXFLAGS=\"\"
#CFLAGS=\"--pedantic -Wall -std=c89\"
#CFLAGS="--pedantic -Wall"
#AC_DEFINE(_POSIX_C_SOURCE, 199309)

AC_ARG_ENABLE([debug], AC_HELP_STRING([--enable-debug], [Enable debug mode (default no)]), , AC_SUBST([enable_debug], [no]))

AC_MSG_CHECKING([debug mode])
if test x\$enable_debug == xyes ; then
    AC_DEFINE(_DEBUG, 1, [Debug mode])
    AC_SUBST(GDB_CFLAG, \"-g\")
    CFLAGS=\"-g -O0\"
fi
AC_MSG_RESULT([\$debug])


AC_CONFIG_SRCDIR([README])
AC_CANONICAL_TARGET
dnl Setup for automake
AM_INIT_AUTOMAKE

dnl POSIX enabled

dnl Some defined values
AC_DEFINE(PACKAGE_DESC, \"$PACKAGE_DESC\")
AC_DEFINE(PACKAGE_VERSION_MAJOR, $PACKAGE_VERSION_MAJOR)
AC_DEFINE(PACKAGE_VERSION_MINOR, $PACKAGE_VERSION_MINOR)
AC_DEFINE(PACKAGE_VERSION_MICRO, $PACKAGE_VERSION_MICRO)
AC_DEFINE(PACKAGE_BUILD, \"$PACKAGE_BUILD\")

dnl Check types and sizes
AC_CHECK_SIZEOF(short, 2)
AC_CHECK_SIZEOF(int, 4)
AC_CHECK_SIZEOF(long, 4)
AC_CHECK_SIZEOF(long long, 8)

dnl Check for tools
AC_PROG_CC
AM_PROG_LIBTOOL


AC_ARG_ENABLE([select], AC_HELP_STRING([--enable-select], [Enable select() instead of libev (default no)]), , AC_SUBST([enable_select], [no]))

AC_MSG_CHECKING([use select()])
if test x\$enable_select == xyes ; then
    AC_DEFINE(CONFIG_USE_SELECT, 1, [Use select])
    AC_DEFINE(CONFIG_NO_LIBEV, 1, [No ev])
    DISABLE_LIBS=\"ev\"
fi
AC_MSG_RESULT([\$enable_select])


" >> $CONFIG

for suffix in $PKGLIBSADD; do
    ADD=${suffix%:*}
    LIB=${suffix#*:}
    echo "PKG_CHECK_MODULES($ADD, $LIB)" >> $CONFIG
done

for suffix in $PKGLIBSADD_OPTIONAL; do
    ADD=${suffix%:*}
    LIB=${suffix#*:}
    echo "PKG_CHECK_MODULES($ADD, $LIB, AC_SUBST([$ADD], [yes]), AC_SUBST([$ADD], [no]))" >> $CONFIG

    LOWER=`echo $ADD | tr '[A-Z]' '[a-z]'`
    UPPER=`echo $ADD | tr '[a-z]' '[A-Z]'`

    echo "
    AC_ARG_ENABLE([$LOWER], AC_HELP_STRING([--enable-$LOWER], [enable us of $LOWER]), , AC_SUBST([enable_$LOWER], [\$$ADD]))

    for pkg in \$DISABLE_PKGS; do
        if test x\$pkg == x$ADD ; then
            AC_SUBST([enable_$LOWER], [no])
        fi
    done

    AC_MSG_CHECKING([use $LOWER])
    if test x\$enable_$LOWER == xyes ; then
        AC_DEFINE(CONFIG_USE_$UPPER, 1, [Use $LOWER])
    else
        AC_DEFINE(CONFIG_NO_$UPPER, 1, [No $LOWER])
    fi
    AC_MSG_RESULT([\$$ADD])
    " >> $CONFIG

done

for suffix in $LIBSADD; do
    ADD=${suffix%:*}
    FUNC=${suffix#*:}
    echo "
    AC_CHECK_LIB($ADD, $FUNC, AC_SUBST([$ADD], [yes]), AC_MSG_ERROR([library $ADD or $FUNC in $ADD not found!]))
    AC_SUBST([${ADD}_CFLAGS], [])
    AC_SUBST([${ADD}_LIBS], [-l$ADD])
    " >> $CONFIG
done

for suffix in $LIBSADD_OPTIONAL; do
    ADD=${suffix%:*}
    FUNC=${suffix#*:}
    echo "AC_CHECK_LIB($ADD, $FUNC, AC_SUBST([$ADD], [yes]), AC_SUBST([$ADD], [no]))" >> $CONFIG

    LOWER=`echo $ADD | tr '[A-Z]' '[a-z]'`
    UPPER=`echo $ADD | tr '[a-z]' '[A-Z]'`

    echo "
    AC_ARG_ENABLE([$LOWER], AC_HELP_STRING([--enable-$LOWER], [enable use of lib $LOWER]), , AC_SUBST([enable_$LOWER], [\$$ADD]))

    for lib in \$DISABLE_LIBS; do
        if test x\$lib == x$ADD ; then
            AC_SUBST([enable_$LOWER], [no])
        fi
    done

    AC_MSG_CHECKING([use $LOWER])
    if test x\$enable_$LOWER == xyes ; then
        AC_DEFINE(CONFIG_USE_$UPPER, 1, [Use $LOWER])
        AC_SUBST([${ADD}_CFLAGS], [])
        AC_SUBST([${ADD}_LIBS], [-l$ADD])
    else
        AC_DEFINE(CONFIG_NO_$UPPER, 1, [No $LOWER])
        AC_SUBST([${ADD}_CFLAGS], [])
        AC_SUBST([${ADD}_LIBS], [])
    fi
    AC_MSG_RESULT([\$$ADD])
    " >> $CONFIG

done

echo "
dnl Finally create all the generated files
AC_CONFIG_FILES([ Makefile
                  src/Makefile
                  src/Z80/Makefile
                  ])
AC_OUTPUT

echo \"
Use CFLAGS: \$CFLAGS

Configuration for \$PACKAGE_NAME \$PACKAGE_VERSION:
  debug mode:           \$enable_debug

\"
" >> $CONFIG

