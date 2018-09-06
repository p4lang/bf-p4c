####### Barefoot Compilers Toolchain
cmake_minimum_required (VERSION 3.0.2 FATAL_ERROR)

find_program(CCACHE_PROGRAM ccache)
if(CCACHE_PROGRAM)
    MESSAGE(STATUS "Enabling ccache")
    set_property(GLOBAL PROPERTY RULE_LAUNCH_COMPILE "${CCACHE_PROGRAM}")
endif()

project (BFN_P4C)

OPTION(ENABLE_JBAY "Enable JBay" ON)
OPTION(ENABLE_BAREFOOT_INTERNAL "Enable Barefoot Internal" ON)
OPTION(FIXED_LIBDYNHASH "Use future version of the Dynamic hash library" OFF)

list(APPEND CMAKE_MODULE_PATH "${PROJECT_SOURCE_DIR}/cmake")

set(BOOST_MIN_VERSION "1.58.0")
find_package(Boost ${BOOST_MIN_VERSION} REQUIRED)
# Look for the dynamic hash library
if (${FIXED_LIBDYNHASH})
  # In the p4factory env, the library will be generated later, so we
  # predefine the location
  set(LIBDYNHASH_INCLUDE_DIR "${CMAKE_INSTALL_PREFIX}/include/bfutils"
    CACHE STRING "Dynamic hash library include dirs" FORCE)
  set(LIBDYNHASH_LIBRARY "${CMAKE_INSTALL_PREFIX}/lib/libdynhash.a"
    CACHE STRING "Dynamic hash library" FORCE)
  set(HAVE_LIBDYNHASH 1)
else()
  find_package(LibDynHash REQUIRED)
endif()
include_directories(${LIBDYNHASH_INCLUDE_DIR})

# Additional P4C_CPP_FLAGS may be passed (via bootstrap_bfn_compilers.sh script)
# from p4factory when configuring bf-p4c-compilers to specify certain predefined
# features when building the compiler
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${P4C_CPP_FLAGS}")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${P4C_CPP_FLAGS}")

# Get the version from bf-p4c/version.h
file (STRINGS "${BFN_P4C_SOURCE_DIR}/bf-p4c/version.h"
  __version
  REGEX "#define BF_P4C_VERSION.*"
  )
string (REGEX MATCH ".*BF_P4C_VERSION.*([0-9]+)\\.([0-9]+)\\.([0-9]+)([-0-9a-z\\.]*).*"
  __bfn_p4c_version ${__version})
set (BFN_P4C_VERSION_MAJOR ${CMAKE_MATCH_1})
set (BFN_P4C_VERSION_MINOR ${CMAKE_MATCH_2})
set (BFN_P4C_VERSION_PATCH ${CMAKE_MATCH_3})
set (BFN_P4C_VERSION_RC ${CMAKE_MATCH_4})
set (BFN_P4C_VERSION
  "${BFN_P4C_VERSION_MAJOR}.${BFN_P4C_VERSION_MINOR}.${BFN_P4C_VERSION_PATCH}")
if (BFN_P4C_VERSION_RC)
  set (BFN_P4C_VERSION "${BFN_P4C_VERSION}${BFN_P4C_VERSION_RC}")
endif()
if (EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/.git)
  execute_process (COMMAND git rev-parse --short HEAD
    OUTPUT_VARIABLE BFN_P4C_GIT_SHA
    OUTPUT_STRIP_TRAILING_WHITESPACE
    RESULT_VARIABLE rc)
else()
  set (BFN_P4C_GIT_SHA "Unknown")
endif()
set (ENV{P4C_VERSION} "${BFN_P4C_VERSION} (SHA: ${BFN_P4C_GIT_SHA})")
MESSAGE(STATUS "p4c-barefoot version: $ENV{P4C_VERSION}")

# If we're on GCC, use the gold linker if available.
if (CMAKE_COMPILER_IS_GNUCC)
    execute_process(
            COMMAND ${CMAKE_C_COMPILER} -fuse-ld=gold -Wl,--version
            ERROR_QUIET OUTPUT_VARIABLE LD_VERSION)
    if ("${LD_VERSION}" MATCHES "GNU gold")
        set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fuse-ld=gold")
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fuse-ld=gold")
        message(STATUS "Using the GNU gold linker.")
    else ()
        message(STATUS "Using the default system linker.")
    endif ()
    unset(LD_VERSION)
endif ()

add_subdirectory(bf-asm)
add_subdirectory(p4c)

add_custom_target(ctags-all
  COMMAND cd ${BFN_P4C_SOURCE_DIR}/bf-p4c &&
          ctags -R --langmap=C++:+.def,Flex:+.l,YACC:+.ypp
                ${P4C_SOURCE_DIR}/frontends ${P4C_SOURCE_DIR}/ir
                ${P4C_SOURCE_DIR}/midend/ ${P4C_SOURCE_DIR}/lib .
  DEPENDS ctags-asm ctags
  COMMENT "Building ctags")

add_custom_target(cpplint-all
  DEPENDS cpplint-asm cpplint
  COMMENT "cpplint everything"
  )

set (CPACK_RESOURCE_FILE_LICENSE "${BFN_P4C_SOURCE_DIR}/LICENSE")
set (CPACK_RESOURCE_FILE_README "${BFN_P4C_SOURCE_DIR}/README")
install (FILES ${CPACK_RESOURCE_FILE_LICENSE} ${CPACK_RESOURCE_FILE_README}
  DESTINATION share/p4c)

set (CPACK_GENERATOR "DEB;TBZ2")
set (CPACK_PACKAGE_NAME "p4c-compilers")
set (CPACK_PACKAGE_VERSION_MAJOR ${BFN_P4C_VERSION_MAJOR})
set (CPACK_PACKAGE_VERSION_MINOR ${BFN_P4C_VERSION_MINOR})
set (CPACK_PACKAGE_VERSION_PATCH ${BFN_P4C_VERSION_PATCH})
set (CPACK_PACKAGE_VERSION "${BFN_P4C_VERSION}")
set (CPACK_PACKAGE_CONTACT "Barefoot Networks, Inc. <p4c@barefootnetworks.com>")
set (CPACK_PACKAGE_VENDOR "Barefoot Networks, Inc.")
set (CPACK_PACKAGE_DESCRIPTION_SUMMARY "P4C compilers for P4_14 and P4_16")
set (CPACK_PACKAGE_DESCRIPTION "P4C compilers for the Barefoot Networks Tofino architecture")
set (CPACK_PROJECT_CONFIG_FILE "${BFN_P4C_SOURCE_DIR}/CPackOptions.cmake")
set (CPACK_STRIP_FILES TRUE)

include (CPack)
