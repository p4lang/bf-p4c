####### Barefoot Compilers Toolchain
cmake_minimum_required (VERSION 3.0.2 FATAL_ERROR)

find_program(CCACHE_PROGRAM ccache)
if(CCACHE_PROGRAM)
    MESSAGE(STATUS "Enabling ccache")
    set_property(GLOBAL PROPERTY RULE_LAUNCH_COMPILE "${CCACHE_PROGRAM}")
endif()

project (BFN_P4C)

OPTION(ENABLE_STATIC_LIBS OFF)
OPTION(ENABLE_JBAY "Enable JBay" ON)
OPTION(ENABLE_CLOUDBREAK "Enable Cloudbreak" ON)
OPTION(ENABLE_FLATROCK "Enable Flatrock" ON)
OPTION(ENABLE_BAREFOOT_INTERNAL "Enable Barefoot Internal" ON)
OPTION(ENABLE_TESTING "Enable generation of ctests" ON)
OPTION(ENABLE_GTESTS "Enable building and running GTest unit tests" ON)
OPTION(ENABLE_DOXYGEN "Build Doxygen-based developer documentation" ON)
OPTION(FIXED_LIBDYNHASH "Use future version of the Dynamic hash library" OFF)
OPTION(INSTALL_LIBDYNHASH "Install the Dynamic hash library" OFF)
OPTION(ENABLE_ALT_PHV_ALLOC "Enable the alternative PHV allocator" OFF)

# BUILD_STATIC_BFP4C_LIBS should never be used directly, see BUILD_STATIC_BFP4C_LIBS_INTERNAL below
OPTION(BUILD_STATIC_BFP4C_LIBS OFF "Build static libs (archives) of bf-p4c components \
                              (tofinobackend, bfn_p4runtime) for external usage. If not set, the \
                              libraries are build only as object and cannot be used easily by \
                              other projects compiled alongside. Building static libraries slows \
                              down compilation. Using CMake < 3.12 forces this to ON.")

# CMake < 3.12 will not work with OBJLIBs so we will need to build static libs regardless of the
# user's intent. However, we want to keep the option set as intended by the user so it will start
# working with newer cmake (and so that we don't need to override the OPTION).
set(BUILD_STATIC_BFP4C_LIBS_INTERNAL ${BUILD_STATIC_BFP4C_LIBS})
if(NOT BUILD_STATIC_BFP4C_LIBS_INTERNAL AND CMAKE_VERSION VERSION_LESS 3.12)
    set(BUILD_STATIC_BFP4C_LIBS_INTERNAL ON)
    message(WARNING "BUILD_STATIC_BFP4C_LIBS=OFF, but CMake ${CMAKE_VERSION} has insufficient support \
                     for OBJLIB so static libraries will be build anyway (3.12 needed for this to \
                     work")
endif()

list(APPEND CMAKE_MODULE_PATH "${PROJECT_SOURCE_DIR}/cmake")

if (ENABLE_STATIC_LIBS)
  # Look for static libraries when using find_library
  set(CMAKE_FIND_LIBRARY_SUFFIXES .a)
  # Force linking libstdc++ statically. Note that dependencies may bring in
  # dynamic versions of it, so that's why we look above for .a
  set(CMAKE_EXE_LINKER_FLAGS "-static-libgcc -static-libstdc++ -Wl,-z,muldefs")

  # Link Boost statically
  set(Boost_USE_STATIC_LIBS ON)
  set(Boost_USE_STATIC_RUNTIME OFF)
endif()

if (ENABLE_TESTING)
  enable_testing()
endif()

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

set(Z3_MIN_VERSION "4.8.7")
find_package(Z3 ${Z3_MIN_VERSION} REQUIRED)

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
    RESULT_VARIABLE rc
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR})
else()
  if(NOT DEFINED ENV{BFN_P4C_GIT_SHA})
    set (BFN_P4C_GIT_SHA "Unknown")
  else()
    set (BFN_P4C_GIT_SHA $ENV{BFN_P4C_GIT_SHA})
  endif()
endif()
set (ENV{P4C_VERSION} "${BFN_P4C_VERSION} (SHA: ${BFN_P4C_GIT_SHA})")
MESSAGE(STATUS "p4c-barefoot version: $ENV{P4C_VERSION}")

macro(get_schema_version schema_file schema_var)
  execute_process(
    COMMAND python3 -c "from ${schema_file} import get_schema_version;print(get_schema_version(), end='', flush=True)"
    OUTPUT_VARIABLE __schema_version
    RESULT_VARIABLE __schema_errcode
    ERROR_VARIABLE __schema_errstr
    WORKING_DIRECTORY ${BFN_P4C_SOURCE_DIR}/compiler_interfaces/schemas)
  if (${__schema_errcode})
    MESSAGE(FATAL_ERROR "Error retrieving ${schema_file} version ${__schema_errstr}")
  endif()
  set(${schema_var} ${__schema_version})
endmacro(get_schema_version)
# Now force cmake to rerun if any of the files that we depend on versions for
# change: context and manifest for now
# We generate a pair of dummy dependency files will be ignored
set(SCHEMA_FILES
  ${BFN_P4C_SOURCE_DIR}/compiler_interfaces/schemas/context_schema.py
  ${BFN_P4C_SOURCE_DIR}/compiler_interfaces/schemas/manifest_schema.py
  ${BFN_P4C_SOURCE_DIR}/compiler_interfaces/schemas/phv_schema.py
  ${BFN_P4C_SOURCE_DIR}/compiler_interfaces/schemas/power_schema.py
  ${BFN_P4C_SOURCE_DIR}/compiler_interfaces/schemas/resources_schema.py
  )
foreach (f ${SCHEMA_FILES})
  configure_file(${f} ${CMAKE_BINARY_DIR}/${f}.dep)
endforeach()

add_subdirectory(bf-asm)

# Override default settings in p4c.
set (ENABLE_BMV2 OFF CACHE BOOL "")
set (ENABLE_EBPF OFF CACHE BOOL "")
set (ENABLE_UBPF OFF CACHE BOOL "")
set (ENABLE_DPDK OFF CACHE BOOL "")
set (ENABLE_P4C_GRAPHS OFF CACHE BOOL "")
add_subdirectory(p4c)

# Gtest needs additional includes, add them here.
if (ENABLE_GTESTS)
  target_include_directories(gtestp4c
    PRIVATE "${BFN_P4C_SOURCE_DIR}/p4c/test/frameworks/gtest/googlemock/include"
    PRIVATE "${P4C_BINARY_DIR}/extensions/bf-p4c/logging"
    PRIVATE "bf-p4c/logging"
    PRIVATE "${P4C_BINARY_DIR}/control-plane/"
  )
endif()

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

if (ENABLE_DOXYGEN)
  find_package(Doxygen QUIET COMPONENTS dot)
  if(DOXYGEN_FOUND)
    set (doxyfile_in ${CMAKE_CURRENT_SOURCE_DIR}/Doxyfile.in)
    set (doxyfile ${CMAKE_CURRENT_BINARY_DIR}/Doxyfile)
    configure_file(${doxyfile_in} ${doxyfile} @ONLY)

    add_custom_target(doc
      COMMAND ${DOXYGEN_EXECUTABLE} ${doxyfile}
      DEPENDS genIR  # Generate ir-generated.h
      WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
      COMMENT "Building Doxygen documentation"
      VERBATIM)

    add_custom_target(doc-install
      # Place a symlink to the generated documentation to the /var/www/html
      # directory use cmake's create_symlink which must exist always and
      # overrides the target (`ls -sf` creates a link as bf-p4c-compiles/html if
      # bf-p4c-compiles already exists)
      COMMAND ${CMAKE_COMMAND} -E create_symlink ${CMAKE_CURRENT_BINARY_DIR}/html /var/www/html/bf-p4c-compilers
      COMMENT "Installing Doxygen documentation"
      VERBATIM)
  else()
    message(WARNING "Doxygen and dot are needed to build the documentation.")
  endif()
endif()

# Generate the LICENSE file. Do this before generating the build system so
# that CPack detects that the file exists.
execute_process(COMMAND "${BFN_P4C_SOURCE_DIR}/scripts/generate-license.sh")

set (CPACK_RESOURCE_FILE_LICENSE "${BFN_P4C_SOURCE_DIR}/LICENSE")
set (THIRD_PARTY_LICENSES "${BFN_P4C_SOURCE_DIR}/LICENSES.txt")
set (CPACK_RESOURCE_FILE_README "${BFN_P4C_SOURCE_DIR}/README")
install (FILES ${CPACK_RESOURCE_FILE_LICENSE} ${CPACK_RESOURCE_FILE_README}
  ${THIRD_PARTY_LICENSES}
  DESTINATION share/p4c)

set (CPACK_GENERATOR "TBZ2")
set (CPACK_PACKAGE_NAME "p4c")
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
