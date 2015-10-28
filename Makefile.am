SUBDIRS = mau

lib_LTLIBRARIES = libTofino.la
libTofino_la_SOURCES = dummy.cc  
# see http://www.gnu.org/software/automake/manual/html_node/Libtool-Convenience-Libraries.html
# for an explanation of why dummy.cc is here
libTofino_la_LIBADD = $(srcdir)/mau/libMau.la


