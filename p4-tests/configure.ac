AC_INIT(glass-test, version-0.1)
AM_INIT_AUTOMAKE([foreign])
AC_MSG_NOTICE([Checking for p4c-tofino dependences.])

dnl Import a macro for checking python modules.
m4_include([./../p4c-tofino/testsuite/m4/ax_python_module.m4])

dnl A nifty macro for nice section headings.
define(SECTION_TITLE,
[
    echo >& AS_MESSAGE_FD
    echo '   $1   ' | sed -e's/./-/g' >&AS_MESSAGE_FD
    echo '   $1' >& AS_MESSAGE_FD
    echo '   $1   ' | sed -e's/./-/g' >&AS_MESSAGE_FD
])


dnl Check for the libraries we need to run p4c-tofino.
SECTION_TITLE([Checking for python libraries.])

AX_PYTHON_MODULE(ply, fatal, python)
AX_PYTHON_MODULE(texttable, fatal, python)
AX_PYTHON_MODULE(p4_hlir, fatal, python)

dnl Process Makefile.in to create Makefile
SECTION_TITLE([Generating the makefile.])
AC_CONFIG_FILES([Makefile])
AC_OUTPUT
