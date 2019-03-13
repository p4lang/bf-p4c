
set (CODEGEN_SEARCH_PATTERNS "include.*(v1model|psa).p4" "main")
set (CODEGEN_EXCLUDE_PATTERNS "package" "extern")
set (P4TESTDATA ${P4C_SOURCE_DIR}/testdata)
set (P4TESTS_FOR_CODEGEN "${P4TESTDATA}/p4_16_samples/*.p4;${CMAKE_CURRENT_SOURCE_DIR}/p4_16/compile_only/*.p4;${CMAKE_CURRENT_SOURCE_DIR}/p4_16/stf/*.p4;${CMAKE_CURRENT_SOURCE_DIR}/p4_16/ptf/*.p4;${CMAKE_CURRENT_SOURCE_DIR}/p4_16/customer/*.p4")
p4c_find_tests("${P4TESTS_FOR_CODEGEN}" cgtests
  INCLUDE "${CODEGEN_SEARCH_PATTERNS}" EXCLUDE "${CODEGEN_EXCLUDE_PATTERNS}")


set(CODEGEN_RUNNER ${CMAKE_CURRENT_SOURCE_DIR}/codegen_runner.sh)

# set (CODEGEN_TEST_SUITES
#  ${cgtests}
#  )
#p4c_add_tests("codegen" ${CODEGEN_RUNNER} "${CODEGEN_TEST_SUITES}" "")

set  (SWITCH_P4 ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/switch/p4src/switch.p4)
file (RELATIVE_PATH switchtest ${P4C_SOURCE_DIR} ${SWITCH_P4})
p4c_add_test_with_args ("codegen" ${CODEGEN_RUNNER} FALSE
  "switch_dc_basic_uses_phase0" ${switchtest} "${testExtraArgs} -Tphase0:5" "-DDC_BASIC_PROFILE")
p4c_add_codegen_success_reason(
    "_ingress_port_mapping will be used as the phase 0 table"
    switch_dc_basic_uses_phase0
)

# p4c_add_codegen_success_reason (
#   "\\\\$phase0:"
#   testdata/p4_16_samples/action-synth.p4
#   )

# p4c_add_codegen_fail_reason (
#   "ethernet.\\\\$valid: B31\\\\(6\\\\)"
#   testdata/p4_16_samples/flag_lost-bmv2.p4
#   )


