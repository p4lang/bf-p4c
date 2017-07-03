####### Tofino assembler
cmake_minimum_required (VERSION 3.0.2 FATAL_ERROR)

project (bf-asm)

OPTION(ASAN_ENABLED "Enable ASAN checks" OFF)

set (BFASM_LIB_DEPS)

find_package (BISON REQUIRED)
find_package (FLEX REQUIRED)
# other required libraries
include (CheckLibraryExists)
check_library_exists (gc GC_malloc "" HAVE_LIBGC)
if (HAVE_LIBGC)
  set (BFASM_LIB_DEPS "${BFASM_LIB_DEPS};gc")
endif()
# check includes
include (CheckIncludeFile)
check_include_file (execinfo.h HAVE_EXECINFO_H)
check_include_file (ucontext.h HAVE_UCONTEXT_H)

# Other configuration files that need to be generated
configure_file ("${CMAKE_SOURCE_DIR}/config.h.cmake" "${CMAKE_BINARY_DIR}/config.h")

add_subdirectory (walle)

include_directories(${CMAKE_SOURCE_DIR} ${CMAKE_BINARY_DIR})

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

set (TFAS_GEN_SOURCES
  ${CMAKE_BINARY_DIR}/asm-parse.cpp
  ${CMAKE_BINARY_DIR}/gen/uptr_sizes.h)


BISON_TARGET (asm-parse asm-parse.ypp ${CMAKE_CURRENT_BINARY_DIR}/asm-parse.cpp)

add_custom_command(OUTPUT lex-yaml.c
  COMMAND ${FLEX_EXECUTABLE} -t ${CMAKE_CURRENT_SOURCE_DIR}/lex-yaml.l > lex-yaml.c
  DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/lex-yaml.l
  COMMENT "Generating lex-yaml.cpp")

add_custom_command(OUTPUT gen/uptr_sizes.h
  COMMAND ${CMAKE_COMMAND} -E make_directory ${CMAKE_BINARY_DIR}/gen
  COMMAND mksizes > gen/uptr_sizes.h
  DEPENDS lex-yaml.c mksizes)

macro(genHeaderTemplate dir name json_name arch json_globals)
  set (__out_file ${CMAKE_BINARY_DIR}/gen/${dir}/${name}.h)
  set (__cfg_file ${CMAKE_BINARY_DIR}/templates/${dir}/${name}.cfg.json)
  set (__size_file ${CMAKE_BINARY_DIR}/templates/${dir}/${name}.size.json)
  if (NOT "${json_globals}" STREQUAL "")
    if(NOT ${json_globals} STREQUAL "+E")
      set (__gopt "-g")
    endif()
    set (__globals ${json_globals})
  else()
    set(__globals "")
    set(__gopt "")
  endif()
  add_custom_command(OUTPUT ${__out_file}
    COMMAND ${CMAKE_COMMAND} -E make_directory ${CMAKE_BINARY_DIR}/gen/${dir}
    COMMAND ${CMAKE_BINARY_DIR}/json2cpp +ehD ${__gopt} ${__globals} -N ${arch}
            -run '${json_name}' -c ${__cfg_file} ${__size_file} > ${__out_file}
    DEPENDS ${__cfg_file} ${__size_file} json2cpp)
endmacro(genHeaderTemplate)

macro(genSourceTemplate dir name json_name arch json_globals)
  set (__out_file ${CMAKE_BINARY_DIR}/gen/${dir}/${name}.cpp)
  set (__cfg_file ${CMAKE_BINARY_DIR}/templates/${dir}/${name}.cfg.json)
  set (__size_file ${CMAKE_BINARY_DIR}/templates/${dir}/${name}.size.json)
  if (NOT "${json_globals}" STREQUAL "")
    if(NOT ${json_globals} STREQUAL "+E")
      set (__gopt "-g")
    endif()
    set (__globals ${json_globals})
  else()
    set(__globals "")
    set(__gopt "")
  endif()
  add_custom_command(OUTPUT ${__out_file}
    COMMAND ${CMAKE_COMMAND} -E make_directory ${CMAKE_BINARY_DIR}/gen/${dir}
    COMMAND ${CMAKE_BINARY_DIR}/json2cpp +ehDD ${__gopt} ${__globals} -N ${arch}
            -run '${json_name}' -c ${__cfg_file} -I ${name}.h ${__size_file} > ${__out_file}
    DEPENDS ${__cfg_file} ${__size_file} json2cpp)
endmacro(genSourceTemplate)

macro(add_registers dir name json_name arch)
  MESSAGE("******** ${name} has ${ARGN}")
  if ("${ARGN}" STREQUAL "")
    genSourceTemplate(${dir} ${name} ${json_name} ${arch} "")
    genHeaderTemplate(${dir} ${name} ${json_name} ${arch} "")
  else()
    MESSAGE("******** ${name} adding ${ARGN}")
    genSourceTemplate(${dir} ${name} ${json_name} ${arch} ${ARGN})
    genHeaderTemplate(${dir} ${name} ${json_name} ${arch} ${ARGN})
  endif()
endmacro(add_registers)

add_subdirectory (tofino)
add_subdirectory (jbay)

set_source_files_properties (${TFAS_GEN_SOURCES} PROPERTIES GENERATED TRUE)
set (TFAS_SOURCES ${TFAS_COMMON_SOURCES} ${TFAS_GEN_SOURCES})
add_executable (tfas ${TFAS_SOURCES})
target_link_libraries (tfas tofino jbay ${BFASM_LIB_DEPS})

install (TARGETS tfas
  RUNTIME DESTINATION ${CMAKE_INSTALL_PREFIX}/bin)

# gen/disas.%.h: templates/%.size.json json2cpp
# 	@mkdir -p gen/$(dir $*)/.deps
# 	$(AM_V_GEN) ./json2cpp +hru -en $* $< >$@ || { rm $@; false; }
