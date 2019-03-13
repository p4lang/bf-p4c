
set (P4_XFAIL_TESTS
  extensions/p4_tests/p4_16/ptf/ipv4_checksum.p4
  extensions/p4_tests/p4_16/compile_only/net_flow.p4
  extensions/p4_tests/p4_16/compile_only/test_compiler_macro_defs.p4
  )

set (P16_TEST_SUITES
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/compile_only/*.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/stf/*.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/ptf/*.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/customer/*.p4
  )
set (P4TEST_DRIVER ${P4C_SOURCE_DIR}/backends/p4test/run-p4-sample.py)
p4c_add_tests("p4" ${P4TEST_DRIVER} "${P16_TEST_SUITES}" "${P4_XFAIL_TESTS}")
