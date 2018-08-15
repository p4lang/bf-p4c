# Searches for an installed version of the bfutils library
# Sets the following variables:
#
# LIBBFUTILS_INCLUDE_DIR
# LIBBFUTILS_LIBRARY
#


# save the suffixes
set(__cmake_find_lib_suffixes ${CMAKE_FIND_LIBRARY_SUFFIXES})
# force finding a static version of the library
set(CMAKE_FIND_LIBRARY_SUFFIXES .a)

find_path(LIBDYNHASH_INCLUDE_DIR NAMES dynamic_hash/dynamic_hash.h
  PATHS
  ${BFN_P4C_SOURCE_DIR}/../tofino_install/include/bfutils
  ${BFN_P4C_SOURCE_DIR}/../jbay_install/include/bfutils
  ${CMAKE_INSTALL_PREFIX}/include/bfutils
  /usr/local/include/bfutils
  /usr/include/bfutils
  )

find_library(LIBDYNHASH_LIBRARY NAMES dynhash
  HINTS
  ${BFN_P4C_SOURCE_DIR}/../tofino_install/lib
  ${BFN_P4C_SOURCE_DIR}/../jbay_install/lib
  ${CMAKE_INSTALL_PREFIX}/lib
  /usr/local/lib
  /usr/lib
  )

# restore suffixes
set(CMAKE_FIND_LIBRARY_SUFFIXES ${__cmake_find_lib_suffixes})

message("info ${LIBDYNHASH_LIBRARY} ${LIBDYNHASH_INCLUDE_DIR}")

set(HAVE_LIBDYNHASH 1)
include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(LibDynHash
  REQUIRED_VARS LIBDYNHASH_LIBRARY LIBDYNHASH_INCLUDE_DIR HAVE_LIBDYNHASH
  )
mark_as_advanced(LIBDYNHASH_INCLUDE_DIR LIBDYNHASH_LIBRARY HAVE_LIBDYNHASH)
