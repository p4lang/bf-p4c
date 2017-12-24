# set TNA as the default architecture
set (DEFAULT_TARGET_ARCHITECTURE "tofino-native-barefoot")

# for the developer setup
add_custom_target(reset-target-arch ALL
  COMMAND sed -e 's/bmv2-ss-p4org/${DEFAULT_TARGET_ARCHITECTURE}/'
          ${BFN_P4C_BINARY_DIR}/p4c/p4c_src/main.py > ${BFN_P4C_BINARY_DIR}/p4c/p4c_src/main.py.tmp &&
          mv ${BFN_P4C_BINARY_DIR}/p4c/p4c_src/main.py.tmp ${BFN_P4C_BINARY_DIR}/p4c/p4c_src/main.py
  DEPENDS p4c_driver
  COMMENT "set default target to ${DEFAULT_TARGET_ARCHITECTURE}"
  )

# and for the installed version
install (CODE "set (DEFAULT_TARGET_ARCHITECTURE ${DEFAULT_TARGET_ARCHITECTURE})")
install (CODE "set (P4C_ARTIFACTS_OUTPUT_DIRECTORY ${CMAKE_INSTALL_PREFIX}/share/p4c)")
install (CODE "set (CPACK_TEMPORARY_DIRECTORY ${CPACK_TEMPORARY_DIRECTORY})")
install (SCRIPT "${CMAKE_CURRENT_SOURCE_DIR}/PostInstall.cmake")
