set (GEN_FLATROCK
  memories.ftr_mem
  memories.pipe_addrmap
  regs.ftr_reg
  regs.mau_addrmap
  regs.pipe_addrmap
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
  flatrock/input_xbar.cpp
  PARENT_SCOPE
  )

include_directories (${BFASM_BINARY_DIR}/gen/flatrock)
add_library (regs_ftr ${GEN_FLATROCK_SRCS} ${GEN_FLATROCK_HDRS})
