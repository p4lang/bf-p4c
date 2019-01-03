# Searches for an installed version of the bfutils library
# Sets the following variables:
#
# LIBBFUTILS_INCLUDE_DIR
# LIBBFUTILS_LIBRARY
#

set (BFUTILS_INSTALL_DIR ${BFN_P4C_SOURCE_DIR}/../install)
if (INSTALL_LIBDYNHASH)
  message(STATUS "Installing bf-utils library ...")
  execute_process(COMMAND ${BFN_P4C_SOURCE_DIR}/scripts/make_and_install_dynhash.sh --install-dir ${BFUTILS_INSTALL_DIR} --no-sudo --repo ${BFN_P4C_SOURCE_DIR}/bf-utils --no-repo-update
    WORKING_DIRECTORY ${BFN_P4C_SOURCE_DIR}
    RESULT_VARIABLE bfutils_install
    OUTPUT_VARIABLE bfutils_output_log
    ERROR_VARIABLE bfutils_error_log
    )
  if (${bfutils_install})
    message(FATAL_ERROR "Failed to install bfutils library:\n${bfutils_output_log}\n${bfutils_error_log}")
  else()
    message(STATUS "Installed bfutils in ${BFUTILS_INSTALL_DIR}\n${bfutils_output_log}")
  endif()
endif()

# save the suffixes
set(__cmake_find_lib_suffixes ${CMAKE_FIND_LIBRARY_SUFFIXES})
# force finding a static version of the library
set(CMAKE_FIND_LIBRARY_SUFFIXES .a)

find_path(LIBDYNHASH_INCLUDE_DIR NAMES dynamic_hash/dynamic_hash.h
  PATHS
  ${BFUTILS_INSTALL_DIR}/include/bfutils
  ${CMAKE_INSTALL_PREFIX}/include/bfutils
  /usr/local/include/bfutils
  /usr/include/bfutils
  )

find_library(LIBDYNHASH_LIBRARY NAMES dynhash
  HINTS
  ${BFUTILS_INSTALL_DIR}/lib
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
