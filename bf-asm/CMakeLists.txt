####### Tofino assembler
cmake_minimum_required (VERSION 3.0.2 FATAL_ERROR)

find_program(CCACHE_PROGRAM ccache)
if(CCACHE_PROGRAM)
    MESSAGE(STATUS "Enabling ccache")
    set_property(GLOBAL PROPERTY RULE_LAUNCH_COMPILE "${CCACHE_PROGRAM}")
endif()

project (BFASM)

set (CMAKE_MODULE_PATH ${BFN_P4C_SOURCE_DIR}/p4c/cmake)

include(UnifiedBuild)

MESSAGE("-- Adding bf-asm")

OPTION(ASAN_ENABLED "Enable ASAN checks" OFF)

# An option to configure the chunk size we use for unified builds in bf-asm. By
# default, this is tuned to use smaller chunks than the p4c repo uses. The goal
# is to gain most of the benefit of unified builds when many files change, while
# keeping the impact on recompilation time for individual files to a minimum.
set(BF_ASM_UNIFIED_SOURCE_CHUNK_SIZE "5" CACHE STRING
    "Target unified compilation chunk size for bf-asm (an integer or ALL)")

set (BFASM_LIB_DEPS "${LIBDYNHASH_LIBRARY}")
include_directories("${LIBDYNHASH_INCLUDE_DIR}")

find_package (BISON REQUIRED)
find_package (FLEX REQUIRED)
# other required libraries
include (CheckLibraryExists)
# check includes
include (CheckIncludeFile)
check_include_file (execinfo.h HAVE_EXECINFO_H)
check_include_file (ucontext.h HAVE_UCONTEXT_H)

set(BFASM_CXX_FLAGS "")
include(P4CUtils)
# add_cxx_compiler_option ("-Wall")
# add_cxx_compiler_option ("-Wextra")
# Disabling -Werror checks until all issues are fixed on all platforms
# add_cxx_compiler_option ("-Werror")
# add_cxx_compiler_option ("-Wno-unused")
# add_cxx_compiler_option ("-Wno-unused-parameter")
# add_cxx_compiler_option ("-Wno-pragmas")
# add_cxx_compiler_option ("-Wno-unknown-pragmas")
add_cxx_compiler_option ("-Wno-overloaded-virtual")
add_cxx_compiler_option ("-Wno-deprecated")
if (${CMAKE_SYSTEM_PROCESSOR} MATCHES i386|i586|i686)
  # on 32-bit platforms we get a lot of warnings when using the error macros
  add_cxx_compiler_option("-Wno-write-strings")
endif()
if (ENABLE_BAREFOOT_INTERNAL)
  add_definitions("-DBAREFOOT_INTERNAL=1")
endif()
add_definitions("-DBF_P4C_GIT_SHA=\"${BFN_P4C_GIT_SHA}\"")

get_schema_version(context_schema CONTEXT_SCHEMA_VERSION)
MESSAGE(STATUS "Found context schema version ${CONTEXT_SCHEMA_VERSION}")

set (BFN_P4C_LIB_DIR ${BFN_P4C_SOURCE_DIR}/p4c/lib)
include_directories(${BFASM_SOURCE_DIR} ${BFASM_BINARY_DIR} ${BFN_P4C_LIB_DIR} ${BFN_P4C_SOURCE_DIR})

# ASAN CHECKS
if (ASAN_ENABLED)
  # force this set of flags only
  set (CMAKE_CXX_FLAGS "-fsanitize=address -fsanitize=undefined -fno-omit-frame-pointer -fno-optimize-sibling-calls -g -O1")
endif()

set (CMAKE_CXX_STANDARD 11)
set (CMAKE_CXX_STANDARD_REQUIRED ON)

# json_diff
set (JSONDIFF_SOURCES json_diff.cpp json.cpp fdstream.cpp)
build_unified(JSONDIFF_SOURCES ALL)
add_executable (json_diff ${JSONDIFF_SOURCES})

# bfdumpbin
set (BFDUMPBIN_SOURCES bfdumpbin.cpp fdstream.cpp json.cpp bson.cpp)
build_unified(BFDUMPBIN_SOURCES ALL)
add_executable (bfdumpbin ${BFDUMPBIN_SOURCES})

# reflow
set (REFLOW_SOURCES reflow.cpp)
build_unified(REFLOW_SOURCES ALL)
add_executable (reflow ${REFLOW_SOURCES})

# b2j
set (B2J_SOURCES b2j.cpp json.cpp bson.cpp)
build_unified(B2J_SOURCES ALL)
add_executable (b2j ${B2J_SOURCES})

# j2b
set (J2B_SOURCES j2b.cpp json.cpp bson.cpp)
build_unified(J2B_SOURCES ALL)
add_executable (j2b ${J2B_SOURCES})

# mksizes
set (MKSIZES_SOURCES mksizes.cpp)
build_unified(MKSIZES ALL)
add_executable (mksizes ${MKSIZES_SOURCES})

set (BFAS_COMMON_SOURCES
  action_bus.cpp
  action_table.cpp
  asm-types.cpp
  atcam_match.cpp
  attached_table.cpp
  bfas.cpp
  bson.cpp
  counter.cpp
  crash.cpp
  deparser.cpp
  depositfield.cpp
  dynhash.cpp
  exact_match.cpp
  exename.cpp
  flexible_headers.cpp
  gateway.cpp
  hash_action.cpp
  hash_dist.cpp
  hashexpr.cpp
  idletime.cpp
  input_xbar.cpp
  instruction.cpp
  json.cpp
  match_table.cpp
  meter.cpp
  misc.cpp
  p4_table.cpp
  parser-tofino-jbay-cloudbreak.cpp
  phase0.cpp
  phv.cpp
  primitives.cpp
  proxy_hash.cpp
  salu_inst.cpp
  selection.cpp
  sram_match.cpp
  stage.cpp
  stateful.cpp
  synth2port.cpp
  tables.cpp
  target.cpp
  ternary_match.cpp
  top_level.cpp
  ubits.cpp
  vector.c
  widereg.cpp
  ${BFN_P4C_LIB_DIR}/hex.cpp
  ${BFN_P4C_LIB_DIR}/bitvec.cpp
  ${BFN_P4C_LIB_DIR}/log.cpp
  ${BFN_P4C_LIB_DIR}/indent.cpp
  )

SET (BFAS_COMMON_HEADERS
  action_bus.h
  asm-types.h
  bfas.h
  checked_array.h
  constants.h
  data_switchbox.h
  deparser.h
  depositfield.h
  escape.h
  exename.h
  fdstream.h
  hash_dist.h
  hashexpr.h
  input_xbar.h
  instruction.h
  json.h
  mask_counter.h
  match_source.h
  misc.h
  p4_table.h
  parser.h
  parser-tofino-jbay-cloudbreak.h
  phv.h
  power_ctl.h
  register_reference.h
  rvalue_reference_wrapper.h
  sections.h
  slist.h
  stage.h
  tables.h
  target.h
  top_level.h
  ubits.h
  widereg.h
  )

# \TODO: use the headers from p4c/lib for utilities
set (BFAS_UTIL_HEADERS
  map.h
  vector.h
  )

set (BFAS_GEN_SOURCES
  ${BFASM_BINARY_DIR}/asm-parse.cpp
  ${BFASM_BINARY_DIR}/gen/uptr_sizes.h)

# Versions of CMake before 3.7.2 require a filename argument to BISON_TARGET's
# VERBOSE option. Later versions "support" it, but they generate a file with
# the same name automatically anyway, and then issue a warning because the
# file gets overwritten, so we need this code to avoid warning spew during
# compilation.
if (CMAKE_VERSION VERSION_LESS "3.7.2")
  BISON_TARGET (asm-parse asm-parse.ypp ${CMAKE_CURRENT_BINARY_DIR}/asm-parse.cpp VERBOSE ${CMAKE_CURRENT_BINARY_DIR}/asm-parse.output)
else ()
  BISON_TARGET (asm-parse asm-parse.ypp ${CMAKE_CURRENT_BINARY_DIR}/asm-parse.cpp VERBOSE)
endif ()

set (CPPLINT_FILES
  ${JSON2CPP_SOURCES}
  ${REFLOW_SOURCES}
  ${MKSIZE_SOURCES}
  ${BFAS_COMMON_SOURCES}
  ${BFAS_TOFINO_SRCS}
  ${BFAS_JBAY_SRCS}
  ${BFAS_CLOUDBREAK_SRCS}
  ${BFAS_FLATROCK_SRCS}
  ${BFAS_UTIL_HEADERS}
  ${BFAS_COMMON_HEADERS}
  ${BFAS_TOFINO_HEADERS}
  ${BFAS_JBAY_HEADERS}
  ${BFAS_CLOUDBREAK_HEADERS}
  ${BFAS_FLATROCK_HEADERS}
  )
list(REMOVE_ITEM CPPLINT_FILES vector.c)
# FIXME -- somehow unified generated files end up in the list.  This FILTER should remove
# them but requires cmake 3.6 or later  !?#!cmake
#list(FILTER CPPLINT_FILES EXCLUDE REGEX /unified_)

add_custom_command(OUTPUT lex-yaml.c
  COMMAND ${FLEX_EXECUTABLE} -t ${CMAKE_CURRENT_SOURCE_DIR}/lex-yaml.l > lex-yaml.c
  DEPENDS ${BFASM_SOURCE_DIR}/lex-yaml.l
  COMMENT "Generating lex-yaml.cpp")

add_custom_command(OUTPUT gen/uptr_sizes.h
  COMMAND ${CMAKE_COMMAND} -E make_directory ${BFASM_BINARY_DIR}/gen
  COMMAND mksizes > gen/uptr_sizes.h
  DEPENDS lex-yaml.c mksizes)

set (BFASM_WALLE ${BFASM_SOURCE_DIR}/walle/walle.py)
set (WALLE_SOURCES
      ${BFASM_SOURCE_DIR}/walle/chip.py
      ${BFASM_SOURCE_DIR}/walle/csr.py
      ${BFASM_SOURCE_DIR}/walle/walle.py)

add_subdirectory (tofino)
set (HAVE_TOFINO 1)
set (BFASM_LIBS regs_tofino)
if (ENABLE_JBAY)
  add_subdirectory (jbay)
  set (HAVE_JBAY 1)
  set (BFASM_LIBS ${BFASM_LIBS} regs_jbay)
endif()
if (ENABLE_CLOUDBREAK)
  add_subdirectory (cloudbreak)
  set (HAVE_CLOUDBREAK 1)
  set (BFASM_LIBS ${BFASM_LIBS} regs_cb)
endif()
if (ENABLE_FLATROCK)
  add_subdirectory (flatrock)
  set (HAVE_FLATROCK 1)
  set (BFASM_LIBS ${BFASM_LIBS} regs_ftr)
endif()

# Other configuration files that need to be generated
configure_file ("${BFASM_SOURCE_DIR}/cmake/config.h.in" "${BFASM_BINARY_DIR}/config.h")

set_source_files_properties (${BFAS_GEN_SOURCES} ${BFASM_BINARY_DIR}/lex-yaml.c
  PROPERTIES GENERATED TRUE)
set (BFAS_SOURCES ${BFAS_COMMON_SOURCES} ${BFAS_GEN_SOURCES}
  ${BFAS_TOFINO_SRCS}
  ${BFAS_JBAY_SRCS}
  ${BFAS_CLOUDBREAK_SRCS}
  ${BFAS_FLATROCK_SRCS}
)

build_unified(BFAS_SOURCES ${BF_ASM_UNIFIED_SOURCE_CHUNK_SIZE})
set_source_files_properties(${BFAS_SOURCES} PROPERTIES COMPILE_FLAGS ${BFASM_CXX_FLAGS})
add_executable (bfas ${BFAS_SOURCES})
target_link_libraries (bfas ${BFASM_LIBS} ${BFASM_LIB_DEPS})

install (TARGETS bfas
  RUNTIME DESTINATION bin)

add_custom_target(check-asm
  COMMAND export BUILDDIR=${BFASM_BINARY_DIR} && cd ${BFASM_SOURCE_DIR}/test &&
          ./runtests asm/*.tfa asm/*.jba asm/*.bfa asm/*.stf)

# This is broken and it doesn't make sense to use p4 tests here anyways
# add_custom_target(check-all-asm
#   COMMAND export BUILDDIR=${BFASM_BINARY_DIR} && cd ${BFASM_SOURCE_DIR}/test &&
#           ./runtests -f asm/*.tfa *.p4 mau/*.p4
#   COMMAND export BUILDDIR=${BFASM_BINARY_DIR} && cd ${BFASM_SOURCE_DIR}/test &&
#           ./runtests -f -b stf/*.stf brig/*.p4)

add_custom_target(check-sanity
  COMMAND export BUILDDIR=${BFASM_BINARY_DIR} && cd ${BFASM_SOURCE_DIR}/test &&
  ./runtests *.p4)

set (CPPLINT_CMD ${BFN_P4C_SOURCE_DIR}/p4c/tools/cpplint.py)
set (CPPLINT_ARGS --root=${BFASM_SOURCE_DIR}/.. --extensions=h,hpp,cpp,ypp,l)
add_custom_target(cpplint-asm
  COMMAND ${CPPLINT_CMD} ${CPPLINT_ARGS} ${CPPLINT_FILES}
  WORKING_DIRECTORY ${BFASM_SOURCE_DIR}
  COMMENT "cpplint")
add_custom_target(cpplint-asm-quiet
  COMMAND ${CPPLINT_CMD} --quiet ${CPPLINT_ARGS} ${CPPLINT_FILES}
  WORKING_DIRECTORY ${BFASM_SOURCE_DIR}
  COMMENT "cpplint quietly")

string(CONFIGURE "/^DECLARE_(ABSTRACT_)?TABLE_TYPE\(([a-zA-Z0-9_]+)/2/c/" CTAGS_CXX_REGEXP @ONLY)
add_custom_target(ctags-asm
  COMMAND ctags -R -I VECTOR --exclude=test --exclude=submodules
              "--regex-C++=${CTAGS_CXX_REGEXP}"
  COMMENT "Generating ctags")

if (ENABLE_GTESTS)
  # TODO Components need to be built, once, into intermediate libraries.
  # These lib would then be linked to unit-tests and also linked into larger components/executable.
  # The exact shape, size, hierarchy of components is to be decided.
  # For now we will allow the source to be built twice, once for 'bfas', and once for
  # gtest/CMakeList.txt as a single monolithic component 'bfas_lib'.
  # TODO ASAP refactor bfas.cpp, moving main() into its own file.
  #           add_executable (bfas asm_main.cpp)
  #           target_link_libraries (bfas bfas_lib ${BFASM_LIBS} ${BFASM_LIB_DEPS})

  add_library (bfas_lib ${BFAS_SOURCES})
  target_compile_definitions(bfas_lib PRIVATE BUILDING_FOR_GTEST)  # removes main()
  target_link_libraries (bfas_lib PRIVATE ${BFASM_LIBS} ${BFASM_LIB_DEPS})

  set(BFAS_GTEST_SOURCES
    gtest/gtestasm.cpp
    gtest/asm-types.cpp
    gtest/deparser.cpp
    gtest/depositfield.cpp
    gtest/mirror.cpp
    gtest/parser-test.cpp
    gtest/flatrock-parser.cpp
    gtest/register-matcher.h
          gtest/register-matcher.cpp)
  add_executable (gtestasm ${BFAS_GTEST_SOURCES})
  include_directories(
    ${BFN_P4C_SOURCE_DIR}/p4c/test/frameworks/gtest/googletest/include
  )
  target_link_libraries (gtestasm PRIVATE bfas_lib gtest)
  target_compile_options (gtestasm PRIVATE -Wall -Wextra -ggdb -O3
                          -Wno-unused-parameter -Wno-sign-compare)

  # Add to CTests - but this is in the BFASM project viz build/bf-asm, not build/p4c
  add_test (NAME gtestasm COMMAND gtestasm WORKING_DIRECTORY ${P4C_BINARY_DIR})
  set_tests_properties (gtestasm PROPERTIES LABELS "gtest")
endif ()
