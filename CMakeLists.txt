####### Barefoot Compilers Toolchain
cmake_minimum_required (VERSION 3.0.2 FATAL_ERROR)

find_program(CCACHE_PROGRAM ccache)
if(CCACHE_PROGRAM)
    MESSAGE("-- Enabling ccache")
    set_property(GLOBAL PROPERTY RULE_LAUNCH_COMPILE "${CCACHE_PROGRAM}")
endif()

project (BFN_P4C)

# Get the version from bf-p4c/version.h
file (STRINGS "${BFN_P4C_SOURCE_DIR}/bf-p4c/version.h"
  __version
  REGEX "#define P4C_TOFINO_VERSION.*"
  )
string (REGEX MATCH ".*TOFINO_VERSION.*([0-9]+).([0-9]+).([0-9]+)([-0-9a-z]*).*"
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
execute_process (COMMAND git rev-parse --short HEAD
  OUTPUT_VARIABLE BFN_P4C_GIT_SHA
  OUTPUT_STRIP_TRAILING_WHITESPACE
  RESULT_VARIABLE rc)
MESSAGE(STATUS "p4c-tofino version: ${BFN_P4C_VERSION} (${BFN_P4C_GIT_SHA})")

add_subdirectory(bf-asm)
add_subdirectory(p4c)

add_custom_target(ctags-all
  COMMAND cd $(BFN_P4C_SOURCE_DIR)/bf-p4c &&
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
  DESTINATION ${CMAKE_INSTALL_PREFIX}/share/p4c)

set (CPACK_GENERATOR "DEB")
set (CPACK_PACKAGE_NAME "p4c-compilers")
set (CPACK_PACKAGE_VERSION_MAJOR ${BFN_P4C_VERSION_MAJOR})
set (CPACK_PACKAGE_VERSION_MINOR ${BFN_P4C_VERSION_MINOR})
set (CPACK_PACKAGE_VERSION_PATCH ${BFN_P4C_VERSION_PATCH})
set (CPACK_PACKAGE_VERSION "${BFN_P4C_VERSION}")
set (CPACK_PACKAGE_CONTACT "Barefoot Networks, Inc. <p4c@barefootnetworks.com>")
set (CPACK_PACKAGE_VENDOR "Barefoot Networks, Inc.")
set (CPACK_PACKAGE_DESCRIPTION_SUMMARY "P4C compilers for P4_14 and P4_16")
set (CPACK_PACKAGE_DESCRIPTION "P4C compilers for the Barefoot Networks Tofino architecture")
execute_process (COMMAND uname -m OUTPUT_VARIABLE __machine_arch
  OUTPUT_STRIP_TRAILING_WHITESPACE
  RESULT_VARIABLE rc)
if (${__machine_arch} STREQUAL "x86_64")
  set (CPACK_DEBIAN_PACKAGE_ARCHITECTURE "amd64")
else()
  set (CPACK_DEBIAN_PACKAGE_ARCHITECTURE "i386")
endif()
set (CPACK_DEBIAN_PACKAGE_DEPENDS "cpp (>= 4.8), python (> 2.7)")
set (CPACK_STRIP_FILES TRUE)
include (CPack)
