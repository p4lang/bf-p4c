include (ExternalProject)

# Switch P4-16
set (SWITCH_P4_16_ROOT ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/switch_16)
set (SWITCH_P4_16_INC ${SWITCH_P4_16_ROOT}/p4src/shared)

set (SWITCH_P4_16_Y2 ${SWITCH_P4_16_ROOT}/p4src/switch-tofino2/switch_tofino2_y2.p4)
file (RELATIVE_PATH switch_p4_16_y2 ${P4C_SOURCE_DIR} ${SWITCH_P4_16_Y2})
p4c_add_test_with_args("tofino3" ${P4C_RUNTEST} FALSE
 "smoketest_switch_16_compile_y2_profile" ${switch_p4_16_y2} "${testExtraArgs}" "-DY2_PROFILE -I${SWITCH_P4_16_INC} -tofino3 -Xp4c=\"--auto-init-metadata\" -arch t3na")

## 500s timeout is too little for compiling and testing the entire switch, bumping it up
set_tests_properties("tofino3/smoketest_switch_16_compile_y2_profile" PROPERTIES TIMEOUT ${extended_timeout_4times})
