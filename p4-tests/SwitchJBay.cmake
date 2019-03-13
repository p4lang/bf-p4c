include (ExternalProject)

# Switch P4-16
set (SWITCH_P4_16 ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/switch_16/p4src/switch-tofino/switch.p4)
set (SWITCH_P4_16_PTF ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/switch_16/ptf/api)
file (RELATIVE_PATH switch_p4_16 ${P4C_SOURCE_DIR} ${SWITCH_P4_16})
p4c_add_test_with_args("tofino2" ${P4C_RUNTEST} FALSE
  "smoketest_switch_16_compile" ${switch_p4_16} "$testExtraArgs}" "-tofino2 -arch t2na -bfrt -force-link")
p4c_add_ptf_test_with_ptfdir ("tofino2" "smoketest_switch_16_Tests" ${SWITCH_P4_16}
  "${testExtraArgs} -tofino2 -arch t2na -bfrt -to 3600" ${SWITCH_P4_16_PTF})
# Cannot run some of the tests as they access ports outside the range of the set ports using veth_setup.sh
bfn_set_ptf_test_spec("tofino2" "smoketest_switch_16_Tests"
        "all
        ^switch_tests.L2LagTest
        ^switch_tests.L3ECMPTest
        ^switch_tests.L3MulticastTest")

# All switch_16 tests should depend on the test being compiled, rather than
# relying on the first one to compile the test.
set_tests_properties(
  "tofino2/smoketest_switch_16_Tests"
  PROPERTIES DEPENDS "tofino2/smoketest_switch_16_compile"
  )

# 500s timeout is too little for compiling and testing the entire switch, bumping it up
set_tests_properties("tofino2/smoketest_switch_16_compile" PROPERTIES TIMEOUT 1200)
set_tests_properties("tofino2/smoketest_switch_16_Tests" PROPERTIES TIMEOUT 3600)

