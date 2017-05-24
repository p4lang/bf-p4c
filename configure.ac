AC_PREREQ(2.64)
AC_INIT([p4c], [16], [cdodd@barefootnetworks.com])
m4_include([m4/ax_cxx_compile_stdcxx.m4])

AM_INIT_AUTOMAKE([foreign subdir-objects 1.14])
AM_SILENT_RULES([yes])

AC_CONFIG_MACRO_DIR([m4])

# add pyinstaller for walle installation
AC_ARG_VAR(PYINSTALLER, "pyinstaller executable")
AC_PATH_PROG([PYINSTALLER], [pyinstaller],[:])
if test "$ac_cv_path_PYINSTALLER" = ":" ; then
   AC_MSG_ERROR([pyinstaller not found. Install from 'http://www.pyinstaller.org'])
fi

# add python for walle installation
AM_PATH_PYTHON
# Set user flags empty, to be overridden
: ${CFLAGS=""}
: ${CXXFLAGS=""}
AC_PROG_CXX(g++ clang++ c++)
AC_PROG_CC
AC_PROG_LEX
AC_PROG_YACC
AX_CXX_COMPILE_STDCXX_11([noext],[mandatory])
AC_LANG(C++)

AC_CHECK_HEADERS([execinfo.h])
AC_CHECK_HEADERS([ucontext.h])

AC_CONFIG_HEADERS(config.h)
AC_CONFIG_FILES([Makefile])

# Please override CFLAGS and CXXFLAGS with "-g -O1' while using asan checks
# ./configure CFLAGS="-g -O1" CXXFLAGS="-g -O1" --enable-asan-checks
AC_ARG_ENABLE([asan-checks],
              [AS_HELP_STRING([--enable-asan-checks],
                              [Build with address sanitizer checking])],
              [enable_asan=yes],
              [enable_asan=no])
AM_CONDITIONAL([IS_ASAN_ENABLED], [test "x$enable_asan" = "xyes"])

AC_OUTPUT

