

set (exclude_stateful "tofino/stateful_alu_blackbox" "tofino/stateful_alu")
set (BMV2_P4_14_DIRS
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/*.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/switch_*/switch.p4)

p4c_find_tests("${BMV2_P4_14_DIRS}" bmv2_p4_14_tests
  EXCLUDE "${exclude_stateful}")

p4c_find_tests("${CMAKE_CURRENT_SOURCE_DIR}/p4_16/*.p4" bmv2_p4_16_tests
  INCLUDE "${V1_SEARCH_PATTERNS}" EXCLUDE "${exclude_stateful}")
set (BMV2_TEST_SUITES
  ${bmv2_p4_14_tests}
  ${bmv2_p4_16_tests}
  )
set(BMV2_DRIVER ${CMAKE_CURRENT_SOURCE_DIR}/test-bmv2.sh)
p4c_add_tests("bmv2" ${BMV2_DRIVER} "${BMV2_TEST_SUITES}" "${BMV2_XFAIL_TESTS}")

