AC_PREREQ(2.64)
AC_INIT([p4c], [16], [cdodd@barefootnetworks.com])
m4_include([m4/ax_cxx_compile_stdcxx.m4])

AM_INIT_AUTOMAKE([foreign subdir-objects 1.14])
AM_SILENT_RULES([yes])

AC_CONFIG_MACRO_DIR([m4])
AC_PROG_CXX(g++ clang++ c++)
AC_PROG_CC
AC_PROG_LEX
AC_PROG_YACC
AX_CXX_COMPILE_STDCXX_11([noext],[mandatory])
AC_LANG(C++)

AC_CONFIG_HEADERS(config.h)
AC_CONFIG_FILES([Makefile])

AC_CANONICAL_HOST
case "${host_os}" in
    darwin*) AC_DEFINE([NO_UCONTEXT], [], [ucontext.h is not usable]);;
esac

AC_OUTPUT
