include (ExternalProject)

# Switch P4-16
set (SWITCH_P4_16_ROOT ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/switch_16)
set (SWITCH_P4_16_INC ${SWITCH_P4_16_ROOT}/p4src/shared)
set (SWITCH_P4_16_PTF ${SWITCH_P4_16_ROOT}/ptf/api)

set (SWITCH_P4_16 ${SWITCH_P4_16_ROOT}/p4src/switch-tofino2/switch_tofino2_y0.p4)
file (RELATIVE_PATH switch_p4_16 ${P4C_SOURCE_DIR} ${SWITCH_P4_16})
p4c_add_test_with_args("tofino2" ${P4C_RUNTEST} FALSE
  "smoketest_switch_16_compile" ${switch_p4_16} "$testExtraArgs}" "-I${SWITCH_P4_16_INC} -tofino2 -arch t2na")

# Need to confirm the p4 path once a new profile is created for L0 on tofino2
set (SWITCH_P4_16_Y3 ${SWITCH_P4_16_ROOT}/p4src/switch-tofino2/switch_tofino2_y3.p4)
file (RELATIVE_PATH switch_p4_16_y3 ${P4C_SOURCE_DIR} ${SWITCH_P4_16_Y3})
p4c_add_test_with_args("tofino2" ${P4C_RUNTEST} FALSE
  "smoketest_switch_16_compile_y3_profile" ${switch_p4_16_y3} "${testExtraArgs}" "-DY3_PROFILE -I${SWITCH_P4_16_INC} -tofino2 -arch t2na")

set (SWITCH_P4_16_Y1 ${SWITCH_P4_16_ROOT}/p4src/switch-tofino2/switch_tofino2_y1.p4)
file (RELATIVE_PATH switch_p4_16_y1 ${P4C_SOURCE_DIR} ${SWITCH_P4_16_Y1})
p4c_add_test_with_args("tofino2" ${P4C_RUNTEST} FALSE
  "smoketest_switch_16_compile_y1_profile" ${switch_p4_16_y1} "${testExtraArgs}" "-DY1_PROFILE
  -I${SWITCH_P4_16_INC} -tofino2 -arch t2na")
p4c_add_test_label("tofino2" "PR_REG_PTF" "smoketest_switch_16_compile_y1_profile")

set (SWITCH_P4_16_Y2 ${SWITCH_P4_16_ROOT}/p4src/switch-tofino2/switch_tofino2_y2.p4)
file (RELATIVE_PATH switch_p4_16_y2 ${P4C_SOURCE_DIR} ${SWITCH_P4_16_Y2})
p4c_add_test_with_args("tofino2" ${P4C_RUNTEST} FALSE
  "smoketest_switch_16_compile_y2_profile" ${switch_p4_16_y2} "${testExtraArgs}" "-DY2_PROFILE
  -I${SWITCH_P4_16_INC} -tofino2 -arch t2na")
p4c_add_test_label("tofino2" "PR_REG_PTF" "smoketest_switch_16_compile_y2_profile")

# Running switch-16 PTF tests on default profile
p4c_add_ptf_test_with_ptfdir ("tofino2" "smoketest_switch_16_Tests_y1" ${SWITCH_P4_16_Y1}
  "${testExtraArgs} -tofino2 -arch t2na -bfrt -profile y1_tofino2 -to 3600" ${SWITCH_P4_16_PTF})
# Cannot run some of the tests as they access ports outside the range of the set ports using veth_setup.sh
bfn_set_ptf_test_spec("tofino2" "smoketest_switch_16_Tests_y1"
        "all
        ^switch_l3.L3SVITest
        ^switch_l2.L2LagTest
        ^switch_l3.L3ECMPTest
        ^switch_l3.L3MulticastTest")
p4c_add_ptf_test_with_ptfdir ("tofino2" "smoketest_switch_16_Tests_y2" ${SWITCH_P4_16_Y2}
  "${testExtraArgs} -tofino2 -arch t2na -bfrt -profile y2_tofino2 -to 3600" ${SWITCH_P4_16_PTF})
# Cannot run some of the tests as they access ports outside the range of the set ports using veth_setup.sh
bfn_set_ptf_test_spec("tofino2" "smoketest_switch_16_Tests_y2"
        "all
        ^switch_l3.L3SVITest
        ^switch_l2.L2LagTest
        ^switch_l3.L3ECMPTest
        ^switch_l3.L3MulticastTest")
p4c_add_ptf_test_with_ptfdir ("tofino2" "smoketest_switch_16_Tests_y0" ${SWITCH_P4_16}
  "${testExtraArgs} -tofino2 -arch t2na -bfrt -profile y0_tofino2 -to 3600" ${SWITCH_P4_16_PTF})
# Cannot run some of the tests as they access ports outside the range of the set ports using veth_setup.sh
bfn_set_ptf_test_spec("tofino2" "smoketest_switch_16_Tests_y0"
        "all
        ^switch_l3.L3SVITest
        ^switch_l2.L2LagTest
        ^switch_l3.L3ECMPTest
        ^switch_l3.L3MulticastTest")

# All switch_16 tests should depend on the test being compiled, rather than
# relying on the first one to compile the test.
set_tests_properties(
  "tofino2/smoketest_switch_16_Tests_y1"
  "tofino2/smoketest_switch_16_Tests_y2"
  "tofino2/smoketest_switch_16_Tests_y0"
  PROPERTIES DEPENDS "tofino2/smoketest_switch_16_compile"
  )

# 500s timeout is too little for compiling and testing the entire switch, bumping it up
set_tests_properties("tofino2/smoketest_switch_16_compile_y1_profile" PROPERTIES TIMEOUT 1200)
set_tests_properties("tofino2/smoketest_switch_16_compile_y2_profile" PROPERTIES TIMEOUT 1200)
set_tests_properties("tofino2/smoketest_switch_16_compile_y3_profile" PROPERTIES TIMEOUT 1200)
set_tests_properties("tofino2/smoketest_switch_16_compile" PROPERTIES TIMEOUT 1200)
set_tests_properties("tofino2/smoketest_switch_16_Tests_y1" PROPERTIES TIMEOUT 3600)
set_tests_properties("tofino2/smoketest_switch_16_Tests_y2" PROPERTIES TIMEOUT 3600)
set_tests_properties("tofino2/smoketest_switch_16_Tests_y0" PROPERTIES TIMEOUT 3600)
