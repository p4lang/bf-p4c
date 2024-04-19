####### Barefoot Compilers Toolchain
cmake_minimum_required (VERSION 3.16.3 FATAL_ERROR)

find_program(CCACHE_PROGRAM ccache)
if(CCACHE_PROGRAM)
    MESSAGE(STATUS "Enabling ccache")
    set_property(GLOBAL PROPERTY RULE_LAUNCH_COMPILE "${CCACHE_PROGRAM}")
endif()

project (BFN_P4C)

# Variable to help code cleanup script
#
# Protect anything that should not be released as open source by enclosing in
#   if (CLOSED_SOURCE) ... endif (CLOSED_SOURCE)
# Other if statements may also be filtered by clean-up script
set(CLOSED_SOURCE TRUE)

OPTION(ENABLE_STATIC_LIBS OFF)
if (CLOSED_SOURCE)
  OPTION(ENABLE_CLOUDBREAK "Enable Cloudbreak" OFF)
  OPTION(ENABLE_FLATROCK "Enable Flatrock" OFF)
endif (CLOSED_SOURCE)
OPTION(ENABLE_BAREFOOT_INTERNAL "Enable Barefoot Internal" ON)
OPTION(ENABLE_TESTING "Enable generation of ctests" ON)
OPTION(ENABLE_GTESTS "Enable building and running GTest unit tests" ON)
OPTION(ENABLE_DOXYGEN "Build Doxygen-based developer documentation" ON)
OPTION(ENABLE_WERROR "Treat build warnings as errors" ON)
OPTION(FIXED_LIBDYNHASH "Use future version of the Dynamic hash library" OFF)
OPTION(INSTALL_LIBDYNHASH "Install the Dynamic hash library" OFF)
OPTION(ENABLE_ASSERTIONS "Enable assertions" ON)

OPTION(ENABLE_TEST_ISOLATION "Run tests in isolated network using Linux network namespaces. \
                              This allows running multiple PTF tests in parallel, but it makes \
                              then isolated from the normal network so it can make debugging \
                              harder (e.g. it is not possible to inspect PTF-set packets using \
                              packet sniffers). Requires running tests using user who has \
                              privileges to unshare namespaces (usually just root)" OFF)

# BUILD_STATIC_BFP4C_LIBS should never be used directly, see BUILD_STATIC_BFP4C_LIBS_INTERNAL below
OPTION(BUILD_STATIC_BFP4C_LIBS OFF "Build static libs (archives) of bf-p4c components \
                              (tofinobackend, bfn_p4runtime) for external usage. If not set, the \
                              libraries are build only as object and cannot be used easily by \
                              other projects compiled alongside. Building static libraries slows \
                              down compilation.")

if (CMAKE_BUILD_TYPE STREQUAL Release OR CMAKE_BUILD_TYPE STREQUAL RelWithDebInfo)
  add_definitions("-DRELEASE_BUILD=1")
endif()

# JBay is always enabled, the preprocessor guard is deprecated
add_definitions("-DHAVE_JBAY=1")

if (ENABLE_FLATROCK)
    message(FATAL_ERROR "Flatrock architecture is no longer supported, please remove or set -DENABLE_FLATROCK=OFF")
  add_definitions("-DHAVE_FLATROCK=1")
  if (NOT ENABLE_CLOUDBREAK)
    message(WARNING "Enabled Flatrock but not Cloudbreak, enabling Cloudbreak.")
    set(ENABLE_CLOUDBREAK ON CACHE BOOL "Enable Cloudbreak" FORCE)
  endif()
endif()
if (ENABLE_CLOUDBREAK)
    message(FATAL_ERROR "Cloudbreak architecture is no longer supported, please remove or set -DENABLE_CLOUDBREAK=OFF")
  add_definitions("-DHAVE_CLOUDBREAK=1")
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

# enable C++17
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
# set this explicitly for clarity, at this point, bfas uses ##__VA_ARGS__ which
# is an extension
set(CMAKE_CXX_EXTENSIONS ON)

# If unity builds are enabled, choose an aggressive batch size.
if (CMAKE_UNITY_BUILD)
  set(CMAKE_UNITY_BUILD_BATCH_SIZE 16 CACHE UNINITIALIZED "Set the unity build batch size.")
endif ()

if (ENABLE_ASSERTIONS)
  # NDEBUG is automatically defined on non-Debug builds by CMake.
  # To enable assertions, we need to explicitly undefine NDEBUG.
  if (NOT CMAKE_BUILD_TYPE STREQUAL "Debug")
    add_definitions( -UNDEBUG )
  endif()
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

# Generate the sha specific version file. It includes the GIT SHA.
# Because this version changes frequently, we include it separately from the normal version files.
configure_file("${CMAKE_CURRENT_SOURCE_DIR}/git_sha_version.h.in"
  "${CMAKE_CURRENT_BINARY_DIR}/git_sha_version.h" @ONLY)


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
  compiler_interfaces/schemas/context_schema.py
  compiler_interfaces/schemas/manifest_schema.py
  compiler_interfaces/schemas/phv_schema.py
  compiler_interfaces/schemas/power_schema.py
  compiler_interfaces/schemas/resources_schema.py
  )
foreach (f ${SCHEMA_FILES})
  configure_file(${BFN_P4C_SOURCE_DIR}/${f} ${CMAKE_BINARY_DIR}/${f}.dep)
endforeach()

if (ENABLE_WERROR)
  # fixme: we do want implicit-fallthrough to be an error, but we have to
  # supress in in p4c and in generated code somehow
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Werror -Wno-error=implicit-fallthrough")
endif()

if(ENABLE_LTO AND CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
  # On some older systems ar has no support for lto plugin. Use gcc-ar,
  # a wrapper around ar adding the appropriate --plugin option for GCC.
  # Note: option ENABLE_LTO is handled in p4c, but p4c does not officially
  # support systems older then Ubuntu 20, so we need to handle this case here.
  find_program(GCC_AR gcc-ar-9)
  # We use gcc/g++ 9, so try to find corresponding gcc-ar-9.
  if (GCC_AR)
    set(CMAKE_AR ${GCC_AR})
    set(CMAKE_C_ARCHIVE_CREATE "<CMAKE_AR> qcs <TARGET> <LINK_FLAGS> <OBJECTS>")
    set(CMAKE_C_ARCHIVE_FINISH true)
    set(CMAKE_CXX_ARCHIVE_CREATE "<CMAKE_AR> qcs <TARGET> <LINK_FLAGS> <OBJECTS>")
    set(CMAKE_CXX_ARCHIVE_FINISH true)
  endif()
endif()

add_subdirectory(bf-asm)

# Override default settings in p4c.
set (ENABLE_BMV2 OFF CACHE BOOL "")
set (ENABLE_EBPF OFF CACHE BOOL "")
set (ENABLE_UBPF OFF CACHE BOOL "")
set (ENABLE_DPDK OFF CACHE BOOL "")
set (ENABLE_P4TC OFF CACHE BOOL "")
set (ENABLE_P4C_GRAPHS OFF CACHE BOOL "")
add_subdirectory(p4c)

# Extend the libraries required for frontend-parser-gen
target_link_libraries(frontend-parser-gen absl::bits)

# Gtest needs additional includes, add them here.
if (ENABLE_GTESTS)
  target_include_directories(gtestp4c
    PRIVATE "${BFN_P4C_SOURCE_DIR}/p4c/test/frameworks/gtest/googlemock/include"
    PRIVATE "${P4C_BINARY_DIR}/extensions/bf-p4c/logging"
    PRIVATE "bf-p4c/logging"
    PRIVATE "${P4C_BINARY_DIR}/control-plane/"
  )
  # -Wdeprecated-copy warns in gtest, so out of our control
  # TODO: -Wno-unused-function warns in p4c, should be possible to fix it
  target_compile_options(gtestp4c PUBLIC -Wno-unused-function -Wno-deprecated-copy)
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
