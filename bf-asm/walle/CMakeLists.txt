####### Tofino binary generator
cmake_minimum_required (VERSION 3.0.2 FATAL_ERROR)

project(WALLE)

find_package (PythonInterp REQUIRED)
find_program (PYINSTALLER pyinstaller)
if (NOT PYINSTALLER)
  MESSAGE(FATAL_ERROR "Pyinstaller is required")
endif()

set (WALLE_SRC ${WALLE_SOURCE_DIR}/walle.py)
set (WALLE_SRCS chip.py csr.py walle.py)
# \TODO: would be better if the chip.schema files were to live within
# this project but for now, we leave them with the assembler templates
set (CHIP_SCHEMA_FILES
  ${BFASM_SOURCE_DIR}/tofino/chip.schema
  ${BFASM_SOURCE_DIR}/jbay/chip.schema
  )

add_custom_command (OUTPUT ${WALLE_BINARY_DIR}/walle
  COMMAND ${PYINSTALLER} --distpath ${WALLE_BINARY_DIR} --onefile --strip ${WALLE_SRC}
  --add-data '${BFASM_SOURCE_DIR}/tofino/chip.schema:lib/tofino'
  --add-data '${BFASM_SOURCE_DIR}/jbay/chip.schema:lib/jbay'
  DEPENDS ${WALLE_SRCS} ${CHIP_SCHEMA_FILES}
  COMMENT "Generating walle binary")

add_custom_target (walle ALL
  DEPENDS ${WALLE_BINARY_DIR}/walle)

install (PROGRAMS ${CMAKE_CURRENT_BINARY_DIR}/walle
  DESTINATION ${CMAKE_INSTALL_PREFIX}/bin)
