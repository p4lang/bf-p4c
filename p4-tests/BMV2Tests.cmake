
set (BMV2_XFAIL_TESTS
  extensions/p4_tests/p4_14/02-FlexCounterActionProfile.p4
  extensions/p4_tests/p4_14/bug_metadata_mutex_1.p4
  extensions/p4_tests/p4_14/exclusive_cf_one_action_fail_after.p4
  extensions/p4_tests/p4_14/exclusive_cf_one_action_fail_before.p4
  extensions/p4_tests/p4_14/gateway1.p4
  extensions/p4_tests/p4_14/gateway2.p4
  extensions/p4_tests/p4_14/gateway3.p4
  extensions/p4_tests/p4_14/gateway4.p4
  extensions/p4_tests/p4_14/metadata_mutex_1.p4
  extensions/p4_tests/p4_14/opcode_test_signed.p4
  extensions/p4_tests/p4_14/pa_do_not_bridge.p4
  extensions/p4_tests/p4_14/shared_names.p4
  extensions/p4_tests/p4_14/test_checksum.p4
  extensions/p4_tests/p4_14/test_config_125_meter_pre_color.p4
  extensions/p4_tests/p4_14/test_config_126_meter_pre_color_2.p4
  extensions/p4_tests/p4_14/test_config_127_meter_pre_color_3.p4
  extensions/p4_tests/p4_14/test_config_132_meter_pre_color_4.p4
  extensions/p4_tests/p4_14/test_config_144_recirculate.p4
  extensions/p4_tests/p4_14/test_config_182_warp_primitive.p4
  extensions/p4_tests/p4_14/test_config_183_sample_e2e.p4
  extensions/p4_tests/p4_14/test_config_185_first_lpf.p4
  extensions/p4_tests/p4_14/test_config_191_invalidate.p4
  extensions/p4_tests/p4_14/test_config_201_meter_constant_index.p4
  extensions/p4_tests/p4_14/test_config_205_modify_field_from_hash.p4
  extensions/p4_tests/p4_14/test_config_284_swap_primitive.p4
  extensions/p4_tests/p4_14/test_config_295_polynomial_hash.p4
  extensions/p4_tests/p4_14/test_config_308_hash_96b.p4
  extensions/p4_tests/p4_14/test_config_309_wide_dyn_selection.p4
  extensions/p4_tests/p4_14/test_config_311_hash_adb.p4
  extensions/p4_tests/p4_14/test_config_313_neg_test_addr_modes.p4
  extensions/p4_tests/p4_14/test_config_314_sym_hash.p4
  extensions/p4_tests/p4_16/stack_valid.p4
  )


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
