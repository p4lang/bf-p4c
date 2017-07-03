####### Tofino binary generator
cmake_minimum_required (VERSION 3.0.2 FATAL_ERROR)

project(WALLE)

find_package (PythonInterp REQUIRED)
find_program (PYINSTALLER pyinstaller)
if (NOT PYINSTALLER)
  MESSAGE(FATAL_ERROR "Pyinstaller is required")
endif()

set (WALLE_SRC ${WALLE_SOURCE_DIR}/walle.py)

add_custom_command (OUTPUT ${WALLE_BINARY_DIR}/walle
  COMMAND ${PYINSTALLER} --distpath ${WALLE_BINARY_DIR} --onefile --strip ${WALLE_SRC}
  COMMENT "Generating walle binary")

add_custom_target (walle ALL
  DEPENDS ${WALLE_BINARY_DIR}/walle)

install (PROGRAMS walle
  DESTINATION ${CMAKE_INSTALL_PREFIX}/bin)
