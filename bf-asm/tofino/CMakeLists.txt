set (GEN_TOFINO
  memories.pipe_addrmap
  memories.pipe_top_level
  memories.prsr_mem_main_rspec
  regs.dprsr_hdr
  regs.dprsr_inp
  regs.ebp_rspec
  regs.ibp_rspec
  regs.mau_addrmap
  regs.pipe_addrmap
  regs.prsr_reg_merge_rspec
  regs.tofino
  )

foreach(f IN LISTS GEN_TOFINO)
  list (APPEND GEN_TOFINO_SRCS ${BFASM_BINARY_DIR}/gen/tofino/${f}.cpp)
  list (APPEND GEN_TOFINO_HDRS ${BFASM_BINARY_DIR}/gen/tofino/${f}.h)
endforeach()

set_source_files_properties(
  ${GEN_TOFINO_SRCS} ${GEN_TOFINO_HDRS}
  PROPERTIES GENERATED TRUE)

add_custom_command(OUTPUT ${GEN_TOFINO_HDRS} ${GEN_TOFINO_SRCS}
  COMMAND ${BFASM_WALLE} --schema chip.schema --generate-cpp template_objects.yaml -o ${BFASM_BINARY_DIR}/gen/tofino
  WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
  DEPENDS template_objects.yaml chip.schema ${WALLE_SOURCES}
  COMMENT "Generating cpp code for tofino from tofino/chip.schema")

set (BFAS_TOFINO_SRCS
  tofino/exact_match.cpp
  tofino/gateway.cpp
  tofino/input_xbar.cpp
  tofino/parser.cpp
  tofino/sram_match.cpp
  tofino/ternary_match.cpp
  PARENT_SCOPE
  )

set (BFAS_TOFINO_HEADERS
  tofino/action_table.h
  tofino/exact_match.h
  tofino/gateway.h
  tofino/input_xbar.h
  tofino/phv.h
  tofino/ternary_match.h
  PARENT_SCOPE
  )

include_directories (${BFASM_BINARY_DIR}/gen/tofino)
add_library (regs_tofino ${GEN_TOFINO_SRCS} ${GEN_TOFINO_HDRS})
