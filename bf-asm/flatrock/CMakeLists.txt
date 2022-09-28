set (GEN_FLATROCK
  memories.ftr_mem
  memories.pipe_addrmap
  memories.ingress_parser
  memories.ingress_deparser
  memories.egress_parser
  memories.egress_deparser
  regs.ftr_reg
  regs.mau_addrmap
  regs.pipe_addrmap
  regs.ingress_parser
  regs.ingress_deparser
  regs.egress_parser
  regs.egress_deparser
  )

foreach(f IN LISTS GEN_FLATROCK)
  list (APPEND GEN_FLATROCK_SRCS ${BFASM_BINARY_DIR}/gen/flatrock/${f}.cpp)
  list (APPEND GEN_FLATROCK_HDRS ${BFASM_BINARY_DIR}/gen/flatrock/${f}.h)
endforeach()

add_custom_command(OUTPUT ${GEN_FLATROCK_HDRS} ${GEN_FLATROCK_SRCS}
  COMMAND ${BFASM_WALLE} --schema chip.schema --generate-cpp template_objects.yaml -o ${BFASM_BINARY_DIR}/gen/flatrock
  WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
  DEPENDS template_objects.yaml chip.schema ${WALLE_SOURCES}
  COMMENT "Generating cpp code for flatrock from flatrock/chip.schema")

set_source_files_properties(
  ${GEN_FLATROCK_SRCS} ${GEN_FLATROCK_HDRS}
  PROPERTIES GENERATED TRUE)

set (BFAS_FLATROCK_SRCS
  flatrock/action_bus.cpp
  flatrock/action_table.cpp
  flatrock/exact_match.cpp
  flatrock/gateway.cpp
  flatrock/hash_action.cpp
  flatrock/hdr.cpp
  flatrock/instruction.cpp
  flatrock/input_xbar.cpp
  flatrock/parser.cpp
  flatrock/sram_match.cpp
  flatrock/tables.cpp
  flatrock/ternary_match.cpp
  PARENT_SCOPE
  )

set (BFAS_FLATROCK_HEADERS
  flatrock/action_bus.h
  flatrock/action_table.h
  flatrock/exact_match.h
  flatrock/gateway.h
  flatrock/hash_action.h
  flatrock/hdr.h
  flatrock/input_xbar.h
  flatrock/parser.h
  flatrock/sram_match.h
  flatrock/ternary_match.h
  PARENT_SCOPE
  )

include_directories (${BFASM_BINARY_DIR}/gen/flatrock)
add_library (regs_ftr ${GEN_FLATROCK_SRCS} ${GEN_FLATROCK_HDRS})
