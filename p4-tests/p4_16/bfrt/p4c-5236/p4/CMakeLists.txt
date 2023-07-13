add_custom_target(tofino ALL
  COMMAND ${BF_SDE}/install/bin/bf-p4c --std p4-16 --target tofino2 --arch t2na -o ${CMAKE_BINARY_DIR}/p4/out --bf-rt-schema ${CMAKE_BINARY_DIR}/p4/out/bf-rt.json --p4runtime-files ${CMAKE_BINARY_DIR}/p4/out/eagle.json  -I . -g eagle.p4
  WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}
)
