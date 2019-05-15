
# FIXME -- mostly missing header files -- utils.h, trivial_parser.h, etc
# FIXME -- need to add explicit -I args to the tests?
set (P4_XFAIL_TESTS
  extensions/p4_tests/p4_16/compile_only/filters.p4
  extensions/p4_tests/p4_16/compile_only/flex_packing_pvs_switch.p4
  extensions/p4_tests/p4_16/compile_only/flex_packing_switch.p4
  extensions/p4_tests/p4_16/compile_only/gateway_control_deps.p4
  extensions/p4_tests/p4_16/compile_only/idletime.p4
  extensions/p4_tests/p4_16/compile_only/indirect_filters.p4
  extensions/p4_tests/p4_16/compile_only/ipv6_tlv.p4
  extensions/p4_tests/p4_16/compile_only/meters_0.p4
  extensions/p4_tests/p4_16/compile_only/meters_shared.p4
  extensions/p4_tests/p4_16/compile_only/min_stage_tests.p4
  extensions/p4_tests/p4_16/compile_only/net_flow.p4
  extensions/p4_tests/p4_16/compile_only/serializer-1446.p4
  extensions/p4_tests/p4_16/compile_only/serializer2.p4
  extensions/p4_tests/p4_16/compile_only/serializer3.p4
  extensions/p4_tests/p4_16/compile_only/serializer.p4
  extensions/p4_tests/p4_16/compile_only/serializer-struct.p4
  extensions/p4_tests/p4_16/compile_only/simple_32q.p4
  extensions/p4_tests/p4_16/compile_only/tagalong_mdinit_switch.p4
  extensions/p4_tests/p4_16/compile_only/test_compiler_macro_defs.p4
  extensions/p4_tests/p4_16/compile_only/test_config_18_meter_color.p4
  extensions/p4_tests/p4_16/compile_only/upward_downward_prop.p4
  extensions/p4_tests/p4_16/ptf/hash_concat.p4
  extensions/p4_tests/p4_16/ptf/ipv4_checksum.p4
  extensions/p4_tests/p4_16/ptf/ixbar_expr3.p4
  extensions/p4_tests/p4_16/ptf/math_unit1.p4
  extensions/p4_tests/p4_16/ptf/math_unit2.p4
  extensions/p4_tests/p4_16/stf/apply_if.p4
  extensions/p4_tests/p4_16/stf/direct-action.p4
  extensions/p4_tests/p4_16/stf/gateway1.p4
  extensions/p4_tests/p4_16/stf/gateway2.p4
  extensions/p4_tests/p4_16/stf/hash_concat.p4
  extensions/p4_tests/p4_16/stf/ixbar_expr1.p4
  extensions/p4_tests/p4_16/stf/ixbar_expr2.p4
  extensions/p4_tests/p4_16/stf/ixbar_expr3.p4
  extensions/p4_tests/p4_16/stf/math_unit1.p4
  extensions/p4_tests/p4_16/stf/math_unit2.p4
  extensions/p4_tests/p4_16/stf/math_unit3.p4
  extensions/p4_tests/p4_16/stf/p4c-1022.p4
  extensions/p4_tests/p4_16/stf/p4c-1487.p4
  extensions/p4_tests/p4_16/stf/p4c-1548.p4
  extensions/p4_tests/p4_16/stf/sful_sel1.p4
  extensions/p4_tests/p4_16/stf/stateful1.p4
  extensions/p4_tests/p4_16/stf/stateful2.p4
  extensions/p4_tests/p4_16/stf/stateful2x16phv.p4
  extensions/p4_tests/p4_16/stf/stateful3.p4
  extensions/p4_tests/p4_16/stf/stateful4.p4
  extensions/p4_tests/p4_16/stf/stateful5.p4
  extensions/p4_tests/p4_16/stf/stateful6.p4
  extensions/p4_tests/p4_16/stf/stateful7.p4
  extensions/p4_tests/p4_16/stf/stateful_log1.p4
  extensions/p4_tests/p4_16/stf/synth-action.p4
  extensions/p4_tests/p4_16/stf/ternary1.p4
  )

set (P16_TEST_SUITES
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/compile_only/*.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/stf/*.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/ptf/*.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/customer/*.p4
  )
set (P4TEST_DRIVER ${P4C_SOURCE_DIR}/backends/p4test/run-p4-sample.py)
p4c_add_tests("p4" ${P4TEST_DRIVER} "${P16_TEST_SUITES}" "${P4_XFAIL_TESTS}"
  "-I${CMAKE_CURRENT_SOURCE_DIR}/p4_16/includes")

p4c_add_xfail_reason("p4"
  "error: port_metadata_unpack: functions or methods returning structures are not supported on this target"
  extensions/p4_tests/p4_16/compile_only/tagalong_mdinit_switch.p4
  )
