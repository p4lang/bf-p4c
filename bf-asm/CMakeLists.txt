####### Tofino assembler
cmake_minimum_required (VERSION 3.0.2 FATAL_ERROR)

project (BFASM)

MESSAGE("-- Adding bf-asm")

OPTION(ASAN_ENABLED "Enable ASAN checks" OFF)

set (BFASM_LIB_DEPS)

find_package (BISON REQUIRED)
find_package (FLEX REQUIRED)
# other required libraries
include (CheckLibraryExists)
# check includes
include (CheckIncludeFile)
check_include_file (execinfo.h HAVE_EXECINFO_H)
check_include_file (ucontext.h HAVE_UCONTEXT_H)

# Other configuration files that need to be generated
configure_file ("${BFASM_SOURCE_DIR}/cmake/config.h.cmake" "${BFASM_BINARY_DIR}/config.h")

add_subdirectory (walle)

include_directories(${BFASM_SOURCE_DIR} ${BFASM_BINARY_DIR})

# ASAN CHECKS
if (ASAN_ENABLED)
  # force this set of flags only
  set (CMAKE_CXX_FLAGS "-fsanitize=address -fsanitize=undefined -fno-omit-frame-pointer -fno-optimize-sibling-calls -g -O1")
endif()

set (CMAKE_CXX_STANDARD 11)
set (CMAKE_CXX_STANDARD_REQUIRED ON)


install (PROGRAMS tflink
  DESTINATION ${CMAKE_INSTALL_PREFIX}/bin)

# json2cpp
set (JSON2CPP_SOURCES json2cpp.cpp json.cpp)
add_executable (json2cpp ${JSON2CPP_SOURCES})

# json_diff
set (JSONDIFF_SOURCES json_diff.cpp json.cpp fdstream.cpp)
add_executable (json_diff ${JSONDIFF_SOURCES})

#hashdump_SOURCES = hashdump.cpp json.cpp ubits.cpp

# reflow
set (REFLOW_SOURCES reflow.cpp)
add_executable (reflow ${REFLOW_SOURCES})

# mksizes
set (MKSIZES_SOURCES mksizes.cpp)
add_executable (mksizes ${MKSIZES_SOURCES})

set (TFAS_COMMON_SOURCES
  action_bus.cpp
  action_table.cpp
  asm-types.cpp
  bitvec.cpp
  counter.cpp
  crash.cpp
  deparser.cpp
  exact_match.cpp
  gateway.cpp
  hash_action.cpp
  hash_dist.cpp
  hashexpr.cpp
  hex.cpp
  idletime.cpp
  input_xbar.cpp
  instruction.cpp
  json.cpp
  meter.cpp
  misc.cpp
  p4_table.cpp
  parser.cpp
  phase0.cpp
  phv.cpp
  power_ctl.cpp
  salu_inst.cpp
  selection.cpp
  stage.cpp
  stateful.cpp
  synth2port.cpp
  tables.cpp
  target.cpp
  ternary_match.cpp
  tfas.cpp
  top_level.cpp
  ubits.cpp
  vector.c
  widereg.cpp
  )

SET (TFAS_COMMON_HEADERS
  action_bus.h
  asm-types.h
  checked_array.h
  constants.h
  data_switchbox.h
  deparser.h
  escape.h
  fdstream.h
  hash_dist.h
  hashexpr.h
  input_xbar.h
  instruction.h
  json.h
  misc.h
  p4_table.h
  parser.h
  phv.h
  rvalue_reference_wrapper.h
  sections.h
  stage.h
  tables.h
  target.h
  tfas.h
  top_level.h
  ubits.h
  widereg.h
  )

# \TODO: use the headers from p4c/lib for utilities
set (TFAS_UTIL_HEADERS
  algorithm.h
  alloc.h
  bitops.h
  bitvec.h
  hex.h
  indent.h
  log.h
  map.h
  ordered_map.h
  range.h
  slist.h
  vector.h
  )

set (TFAS_GEN_SOURCES
  ${BFASM_BINARY_DIR}/asm-parse.cpp
  ${BFASM_BINARY_DIR}/gen/uptr_sizes.h)


BISON_TARGET (asm-parse asm-parse.ypp ${CMAKE_CURRENT_BINARY_DIR}/asm-parse.cpp)

set (CPPLINT_FILES
  ${JSON2CPP_SOURCES}
  ${REFLOW_SOURCES}
  ${MKSIZE_SOURCES}
  ${TFAS_COMMON_SOURCES}
  asm-parse.ypp
  ${TFAS_UTIL_HEADERS}
  ${TFAS_COMMON_HEADERS}
  )

add_custom_command(OUTPUT lex-yaml.c
  COMMAND ${FLEX_EXECUTABLE} -t ${CMAKE_CURRENT_SOURCE_DIR}/lex-yaml.l > lex-yaml.c
  DEPENDS ${BFASM_SOURCE_DIR}/lex-yaml.l
  COMMENT "Generating lex-yaml.cpp")

add_custom_command(OUTPUT gen/uptr_sizes.h
  COMMAND ${CMAKE_COMMAND} -E make_directory ${BFASM_BINARY_DIR}/gen
  COMMAND mksizes > gen/uptr_sizes.h
  DEPENDS lex-yaml.c mksizes)

set (BFASM_WALLE ${BFASM_SOURCE_DIR}/walle/walle.py)
include (cmake/BFNUtils.cmake) # for macros to generate registers

add_subdirectory (tofino)
add_subdirectory (jbay)

set_source_files_properties (${TFAS_GEN_SOURCES} ${BFASM_BINARY_DIR}/lex-yaml.c
  PROPERTIES GENERATED TRUE)
set (TFAS_SOURCES ${TFAS_COMMON_SOURCES} ${TFAS_GEN_SOURCES})
add_executable (tfas ${TFAS_SOURCES})
target_link_libraries (tfas regs_tofino regs_jbay ${BFASM_LIB_DEPS})

install (TARGETS tfas
  RUNTIME DESTINATION ${CMAKE_INSTALL_PREFIX}/bin)

# gen/disas.%.h: templates/%.size.json json2cpp
# 	@mkdir -p gen/$(dir $*)/.deps
# 	$(AM_V_GEN) ./json2cpp +hru -en $* $< >$@ || { rm $@; false; }

add_custom_target(check-asm
  COMMAND export BUILDDIR=${BFASM_BINARY_DIR} && cd ${BFASM_SOURCE_DIR}/test &&
          ./runtests -f asm/*.tfa *.p4 mau/*.p4
  COMMAND export BUILDDIR=${BFASM_BINARY_DIR} && cd ${BFASM_SOURCE_DIR}/test &&
          ./runtests -f -b stf/*.stf brig/*.p4)

add_custom_target(check-sanity
  COMMAND export BUILDDIR=${BFASM_BINARY_DIR} && cd ${BFASM_SOURCE_DIR}/test &&
  ./runtests *.p4)

set (CPPLINT_CMD ${BFN_P4C_SOURCE_DIR}/p4c/tools/cpplint.py)
set (CPPLINT_ARGS --root=${BFASM_SOURCE_DIR} --extensions=h,hpp,cpp,ypp,l)
add_custom_target(cpplint-asm
  COMMAND ${CPPLINT_CMD} ${CPPLINT_ARGS} ${CPPLINT_FILES}
  WORKING_DIRECTORY ${BFASM_SOURCE_DIR}
  COMMENT "cpplint")
add_custom_target(cpplint-asm-quiet
  COMMAND ${CPPLINT_CMD} --quiet ${CPPLINT_ARGS} ${CPPLINT_FILES}
  WORKING_DIRECTORY ${BFASM_SOURCE_DIR}
  COMMENT "cpplint quietly")

string(CONFIGURE "/^DECLARE_(ABSTRACT_)?TABLE_TYPE(([a-zA-Z0-9_]+)/2/c/" CTAGS_CXX_REGEXP @ONLY)
add_custom_target(ctags-asm
  COMMAND ctags -R -I VECTOR --exclude=test --exclude=submodules
              --regex-C++=${CTAGS_CXX_REGEXP}
  COMMENT "Generating ctags")
