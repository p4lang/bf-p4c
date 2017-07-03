####### Barefoot Compilers Toolchain
cmake_minimum_required (VERSION 3.0.2 FATAL_ERROR)

project (BFN_P4C)

add_subdirectory(bf-asm)
add_subdirectory(p4c)

add_custom_target(ctags-all
  COMMAND cd $(BFN_P4C_SOURCE_DIR)/bf-p4c &&
          ctags -R --langmap=C++:+.def,Flex:+.l,YACC:+.ypp
                ${P4C_SOURCE_DIR}/frontends ${P4C_SOURCE_DIR}/ir
                ${P4C_SOURCE_DIR}/midend/ ${P4C_SOURCE_DIR}/lib .
  DEPENDS ctags-asm ctags
  COMMENT "Building ctags")
