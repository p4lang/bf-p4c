include (ExternalProject)

# Switch P4-16
set (SWITCH_P4_16_ROOT ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/switch_16)
set (SWITCH_P4_16_INC ${SWITCH_P4_16_ROOT}/p4src/shared)
set (SWITCH_P4_16_PTF ${SWITCH_P4_16_ROOT}/ptf/api)

set (SWITCH_P4_16 ${SWITCH_P4_16_ROOT}/p4src/switch-tofino/switch.p4)
file (RELATIVE_PATH switch_p4_16 ${P4C_SOURCE_DIR} ${SWITCH_P4_16})
p4c_add_test_with_args("tofino2" ${P4C_RUNTEST} FALSE
  "smoketest_switch_16_compile" ${switch_p4_16} "$testExtraArgs}" "-I${SWITCH_P4_16_INC} -tofino2 -arch t2na")

set (SWITCH_P4_16_L0 ${SWITCH_P4_16_ROOT}/p4src/switch-tofino/switch_profile_l0.p4)
file (RELATIVE_PATH switch_p4_16_l0 ${P4C_SOURCE_DIR} ${SWITCH_P4_16_L0})
p4c_add_test_with_args("tofino2" ${P4C_RUNTEST} FALSE
  "smoketest_switch_16_compile_l0_profile" ${switch_p4_16_l0} "${testExtraArgs}" "-DL0_PROFILE -I${SWITCH_P4_16_INC} -tofino2 -arch t2na")

set (SWITCH_P4_16_C0 ${SWITCH_P4_16_ROOT}/p4src/switch-tofino2/switch_tofino2_c0.p4)
file (RELATIVE_PATH switch_p4_16_c0 ${P4C_SOURCE_DIR} ${SWITCH_P4_16_C0})
p4c_add_test_with_args("tofino2" ${P4C_RUNTEST} FALSE
  "smoketest_switch_16_compile_c0_profile" ${switch_p4_16_c0} "${testExtraArgs}" "-DC0_PROFILE
  -I${SWITCH_P4_16_INC} -tofino2 -arch t2na")
p4c_add_test_label("tofino2" "PR_REG_PTF" "smoketest_switch_16_compile_c0_profile")

set (SWITCH_P4_16_D0 ${SWITCH_P4_16_ROOT}/p4src/switch-tofino2/switch_tofino2_d0.p4)
file (RELATIVE_PATH switch_p4_16_d0 ${P4C_SOURCE_DIR} ${SWITCH_P4_16_D0})
p4c_add_test_with_args("tofino2" ${P4C_RUNTEST} FALSE
  "smoketest_switch_16_compile_d0_profile" ${switch_p4_16_d0} "${testExtraArgs}" "-DD0_PROFILE
  -I${SWITCH_P4_16_INC} -tofino2 -arch t2na")
p4c_add_test_label("tofino2" "PR_REG_PTF" "smoketest_switch_16_compile_d0_profile")

# Running switch-16 PTF tests on default profile
p4c_add_ptf_test_with_ptfdir ("tofino2" "smoketest_switch_16_Tests_t1" ${SWITCH_P4_16}
  "${testExtraArgs} -tofino2 -arch t2na -bfrt -profile t1_tofino2 -to 3600" ${SWITCH_P4_16_PTF})
# Cannot run some of the tests as they access ports outside the range of the set ports using veth_setup.sh
bfn_set_ptf_test_spec("tofino2" "smoketest_switch_16_Tests_t1"
        "all
        ^switch_tests.L3SVITest
        ^switch_tests.L2LagTest
        ^switch_tests.L3ECMPTest
        ^switch_tests.L3MulticastTest")
p4c_add_ptf_test_with_ptfdir ("tofino2" "smoketest_switch_16_Tests_c0" ${SWITCH_P4_16}
  "${testExtraArgs} -tofino2 -arch t2na -bfrt -profile c0_tofino2 -to 3600" ${SWITCH_P4_16_PTF})
# Cannot run some of the tests as they access ports outside the range of the set ports using veth_setup.sh
bfn_set_ptf_test_spec("tofino2" "smoketest_switch_16_Tests_c0"
        "all
        ^switch_tests.L3SVITest
        ^switch_tests.L2LagTest
        ^switch_tests.L3ECMPTest
        ^switch_tests.L3MulticastTest")
p4c_add_ptf_test_with_ptfdir ("tofino2" "smoketest_switch_16_Tests_d0" ${SWITCH_P4_16}
  "${testExtraArgs} -tofino2 -arch t2na -bfrt -profile d0_tofino2 -to 3600" ${SWITCH_P4_16_PTF})
# Cannot run some of the tests as they access ports outside the range of the set ports using veth_setup.sh
bfn_set_ptf_test_spec("tofino2" "smoketest_switch_16_Tests_d0"
        "all
        ^switch_tests.L3SVITest
        ^switch_tests.L2LagTest
        ^switch_tests.L3ECMPTest
        ^switch_tests.L3MulticastTest")

# All switch_16 tests should depend on the test being compiled, rather than
# relying on the first one to compile the test.
set_tests_properties(
  "tofino2/smoketest_switch_16_Tests_t1"
  "tofino2/smoketest_switch_16_Tests_c0"
  "tofino2/smoketest_switch_16_Tests_d0"
  PROPERTIES DEPENDS "tofino2/smoketest_switch_16_compile"
  )

# 500s timeout is too little for compiling and testing the entire switch, bumping it up
set_tests_properties("tofino2/smoketest_switch_16_compile" PROPERTIES TIMEOUT 1200)
set_tests_properties("tofino2/smoketest_switch_16_compile_l0_profile" PROPERTIES TIMEOUT 1200)
set_tests_properties("tofino2/smoketest_switch_16_compile_c0_profile" PROPERTIES TIMEOUT 1200)
set_tests_properties("tofino2/smoketest_switch_16_compile_d0_profile" PROPERTIES TIMEOUT 1200)
set_tests_properties("tofino2/smoketest_switch_16_Tests_t1" PROPERTIES TIMEOUT 3600)
set_tests_properties("tofino2/smoketest_switch_16_Tests_c0" PROPERTIES TIMEOUT 3600)
set_tests_properties("tofino2/smoketest_switch_16_Tests_d0" PROPERTIES TIMEOUT 3600)
