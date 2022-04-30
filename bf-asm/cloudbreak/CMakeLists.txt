set (GEN_CLOUDBREAK
  memories.cb_mem
  memories.pipe_addrmap
  memories.prsr_mem_main_rspec
  regs.dprsr_reg
  regs.epb_prsr4_reg
  regs.ipb_prsr4_reg
  regs.cb_reg
  regs.mau_addrmap
  regs.pipe_addrmap
  regs.pmerge_reg
  regs.prsr_reg_main_rspec
  )

foreach(f IN LISTS GEN_CLOUDBREAK)
  list (APPEND GEN_CLOUDBREAK_SRCS ${BFASM_BINARY_DIR}/gen/cloudbreak/${f}.cpp)
  list (APPEND GEN_CLOUDBREAK_HDRS ${BFASM_BINARY_DIR}/gen/cloudbreak/${f}.h)
endforeach()

add_custom_command(OUTPUT ${GEN_CLOUDBREAK_HDRS} ${GEN_CLOUDBREAK_SRCS}
  COMMAND ${BFASM_WALLE} --schema chip.schema --generate-cpp template_objects.yaml -o ${BFASM_BINARY_DIR}/gen/cloudbreak
  WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
  DEPENDS template_objects.yaml chip.schema ${WALLE_SOURCES}
  COMMENT "Generating cpp code for cloudbreak from cloudbreak/chip.schema")

set_source_files_properties(
  ${GEN_CLOUDBREAK_SRCS} ${GEN_CLOUDBREAK_HDRS}
  PROPERTIES GENERATED TRUE)

set (BFAS_CLOUDBREAK_SRCS
  cloudbreak/gateway.cpp
  cloudbreak/input_xbar.cpp
  cloudbreak/parser.cpp
  PARENT_SCOPE
  )

set (BFAS_CLOUDBREAK_HEADERS
  cloudbreak/gateway.h
  cloudbreak/input_xbar.h
  PARENT_SCOPE
  )

set (BFAS_CLOUDBREAK_HEADERS
  cloudbreak/gateway.h
  cloudbreak/input_xbar.h
  PARENT_SCOPE
  )

set (BFAS_CLOUDBREAK_HEADERS
  cloudbreak/gateway.h
  cloudbreak/input_xbar.h
  PARENT_SCOPE
  )

include_directories (${BFASM_BINARY_DIR}/gen/cloudbreak)
add_library (regs_cb ${GEN_CLOUDBREAK_SRCS} ${GEN_CLOUDBREAK_HDRS})
