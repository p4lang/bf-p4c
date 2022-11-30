set (GEN_JBAY
  memories.jbay_mem
  memories.pipe_addrmap
  memories.prsr_mem_main_rspec
  regs.dprsr_reg
  regs.epb_prsr4_reg
  regs.ipb_prsr4_reg
  regs.jbay_reg
  regs.mau_addrmap
  regs.pipe_addrmap
  regs.pmerge_reg
  regs.prsr_reg_main_rspec
  )

foreach(f IN LISTS GEN_JBAY)
  list (APPEND GEN_JBAY_SRCS ${BFASM_BINARY_DIR}/gen/jbay/${f}.cpp)
  list (APPEND GEN_JBAY_HDRS ${BFASM_BINARY_DIR}/gen/jbay/${f}.h)
endforeach()

add_custom_command(OUTPUT ${GEN_JBAY_HDRS} ${GEN_JBAY_SRCS}
  COMMAND ${BFASM_WALLE} --schema chip.schema --generate-cpp template_objects.yaml -o ${BFASM_BINARY_DIR}/gen/jbay
  WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
  DEPENDS template_objects.yaml chip.schema ${WALLE_SOURCES}
  COMMENT "Generating cpp code for jbay from jbay/chip.schema")

set_source_files_properties(
  ${GEN_JBAY_SRCS} ${GEN_JBAY_HDRS}
  PROPERTIES GENERATED TRUE)

set (BFAS_JBAY_SRCS
  jbay/gateway.cpp
  jbay/input_xbar.cpp
  jbay/stateful.cpp
  jbay/parser.cpp
  PARENT_SCOPE
  )

set (BFAS_JBAY_HEADERS
  jbay/counter.h
  jbay/gateway.h
  jbay/input_xbar.h
  jbay/meter.h
  jbay/stateful.h
  PARENT_SCOPE
  )

include_directories (${BFASM_BINARY_DIR}/gen/jbay)
add_library (regs_jbay ${GEN_JBAY_SRCS} ${GEN_JBAY_HDRS})
