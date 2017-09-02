set (GEN_JBAY
  memories.jbay_mem
  memories.pipe_addrmap
  memories.prsr_mem_main_rspec
  regs.epb_regs
  regs.ipb_csr_regs
  regs.prsr_reg_main_rspec
  regs.pipe_addrmap regs.pmerge_reg
  regs.mau_addrmap
  regs.dprsr_reg
  regs.jbay_reg
  )

set (ARCH "JBay")

foreach(f IN LISTS GEN_JBAY)
  list (APPEND GEN_JBAY_SRCS ${BFASM_BINARY_DIR}/gen/jbay/${f}.cpp)
  list (APPEND GEN_JBAY_HDRS ${BFASM_BINARY_DIR}/gen/jbay/${f}.h)
  list (APPEND GEN_TEMPLATES_CFG  ${BFASM_BINARY_DIR}/templates/jbay/${f}.cfg.json)
  list (APPEND GEN_TEMPLATES_SIZE ${BFASM_BINARY_DIR}/templates/jbay/${f}.size.json)
  add_registers ("jbay" ${f} ${f} ${ARCH})
endforeach()

set_source_files_properties(
  ${GEN_JBAY_SRCS} ${GEN_JBAY_HDRS}
  ${GEN_TEMPLATES_CFG} ${GEN_TEMPLATES_SIZE}
  PROPERTIES GENERATED TRUE)

add_custom_command(OUTPUT ${GEN_TEMPLATES_CFG} ${GEN_TEMPLATES_SIZE}
  COMMAND ${CMAKE_COMMAND} -E make_directory ${BFASM_BINARY_DIR}/templates/jbay
  COMMAND ${BFASM_WALLE} --schema chip.schema --generate-templates template_objects.yaml -o ${BFASM_BINARY_DIR}/templates/jbay
  WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
  DEPENDS template_objects.yaml chip.schema walle
  COMMENT "Generating walle templates for jbay")


include_directories (${BFASM_BINARY_DIR}/gen/jbay)
add_library (regs_jbay ${GEN_JBAY_SRCS} ${GEN_JBAY_HDRS})

# Do we still need this? What do we need to do?
# # if there's a symlink 'p4c-templates' to somewhere with new reg schema, copy them
# $(srcdir)/jbay/%: $(srcdir)/p4c-templates/%
# 	if [ $< -nt $@ ]; then cp $< $@; fi
