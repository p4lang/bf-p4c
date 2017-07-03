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
  list (APPEND GEN_TOFINO_SRCS ${CMAKE_BINARY_DIR}/gen/tofino/${f}.cpp)
  list (APPEND GEN_TOFINO_HDRS ${CMAKE_BINARY_DIR}/gen/tofino/${f}.h)
  list (APPEND GEN_TEMPLATES_CFG  ${CMAKE_BINARY_DIR}/templates/tofino/${f}.cfg.json)
  list (APPEND GEN_TEMPLATES_SIZE ${CMAKE_BINARY_DIR}/templates/tofino/${f}.size.json)
endforeach()

set_source_files_properties(
  ${GEN_TOFINO_SRCS} ${GEN_TOFINO_HDRS}
  ${GEN_TEMPLATES_CFG} ${GEN_TEMPLATES_SIZE}
  PROPERTIES GENERATED TRUE)

add_custom_command(OUTPUT ${GEN_TEMPLATES_CFG} ${GEN_TEMPLATES_SIZE}
  COMMAND ${CMAKE_COMMAND} -E make_directory ${CMAKE_BINARY_DIR}/templates/tofino
  COMMAND ${CMAKE_BINARY_DIR}/walle/walle --schema chip.schema --generate-templates template_objects.yaml -o ${CMAKE_BINARY_DIR}/templates/tofino
  WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
  DEPENDS template_objects.yaml chip.schema walle
  COMMENT "Generating walle templates for tofino")

set (ARCH "Tofino")
add_registers ("tofino" "memories.prsr_mem_main_rspec" "memories.all.parser.%s" ${ARCH})
add_registers ("tofino" "regs.dprsr_hdr" "regs.all.deparser.header_phase" ${ARCH} "fde_phv")
add_registers ("tofino" "regs.dprsr_inp" "regs.all.deparser.input_phase" ${ARCH} "fde_pov")
add_registers ("tofino" "regs.mau_addrmap" "regs.match_action_stage.%02x" ${ARCH})
add_registers ("tofino" "regs.ibp_rspec" "regs.all.parser.ingress" ${ARCH})
add_registers ("tofino" "regs.ebp_rspec" "regs.all.parser.egress" ${ARCH})
add_registers ("tofino" "regs.prsr_reg_merge_rspec" "regs.all.parse_merge" ${ARCH})
add_registers ("tofino" "regs.tofino" "regs.top" ${ARCH})
add_registers ("tofino" "regs.pipe_addrmap" "regs.pipe" "${ARCH}" "+E")
add_registers ("tofino" "memories.pipe_top_level" "memories.top" ${ARCH})
add_registers ("tofino" "memories.pipe_addrmap" "memories.pipe" ${ARCH})

include_directories (${CMAKE_BINARY_DIR}/gen/tofino)
add_library (tofino ${GEN_TOFINO_SRCS} ${GEN_TOFINO_HDRS})

install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/chip.schema
  DESTINATION ${CMAKE_INSTALL_PREFIX}/share/p4c/tofino)


# Do we still need this? What do we need to do?
# # if there's a symlink 'p4c-templates' to somewhere with new reg schema, copy them
# $(srcdir)/tofino/%: $(srcdir)/p4c-templates/%
# 	if [ $< -nt $@ ]; then cp $< $@; fi
