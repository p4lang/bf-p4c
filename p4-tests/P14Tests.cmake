
set (P14_XFAIL_TESTS
  extensions/p4_tests/p4_14/02-FlexCounterActionProfile.p4
  extensions/p4_tests/p4_14/test_config_172_stateful_heavy_hitter.p4
  extensions/p4_tests/p4_14/test_config_160_stateful_single_bit_mode.p4
  extensions/p4_tests/p4_14/test_config_185_first_lpf.p4
  extensions/p4_tests/p4_14/test_config_201_meter_constant_index.p4
  extensions/p4_tests/p4_14/test_config_163_stateful_table_math_unit.p4
  extensions/p4_tests/p4_14/test_config_195_stateful_predicate_output.p4
  extensions/p4_tests/p4_14/test_config_205_modify_field_from_hash.p4
  extensions/p4_tests/p4_14/test_config_214_full_stats.p4
  extensions/p4_tests/p4_14/shared_names.p4
  extensions/p4_tests/p4_14/c2/COMPILER-408/case2364.p4
  extensions/p4_tests/p4_14/c2/COMPILER-514/balancer_one.p4
  extensions/p4_tests/p4_14/c2/COMPILER-537/case2834.p4
  extensions/p4_tests/p4_14/c2/COMPILER-533/case2736.p4
  extensions/p4_tests/p4_14/c3/COMPILER-393/case2277.p4
  extensions/p4_tests/p4_14/jenkins/multi_device/multi_device.p4.p4
  extensions/p4_tests/p4_14/jenkins/meters/meters_one.p4
  extensions/p4_tests/p4_14/jenkins/drivers_test/drivers_test_one.p4
  extensions/p4_tests/p4_14/jenkins/pctr/pctr.p4
  extensions/p4_tests/p4_14/c1/COMPILER-263/case1795.p4
  extensions/p4_tests/p4_14/c1/COMPILER-264/case1822.p4
  extensions/p4_tests/p4_14/c1/COMPILER-271/case1834.p4
  extensions/p4_tests/p4_14/c1/COMPILER-273/case1832.p4
  extensions/p4_tests/p4_14/c1/COMPILER-275/case1841.p4
  extensions/p4_tests/p4_14/c1/COMPILER-276/case1844.p4
  extensions/p4_tests/p4_14/c1/COMPILER-282/case1864.p4
  extensions/p4_tests/p4_14/c1/COMPILER-347/switch_bug.p4
  extensions/p4_tests/p4_14/c1/COMPILER-352/netchain_one.p4
  extensions/p4_tests/p4_14/c1/COMPILER-355/netchain_two.p4
  extensions/p4_tests/p4_14/c1/COMPILER-384/case2240.p4
  extensions/p4_tests/p4_14/c1/COMPILER-385/case2247.p4
  extensions/p4_tests/p4_14/c1/COMPILER-499/case2560_min_2.p4
  extensions/p4_tests/p4_14/c2/COMPILER-392/case2266.p4
  extensions/p4_tests/p4_14/c2/COMPILER-400/case2314.p4
  extensions/p4_tests/p4_14/c2/COMPILER-401/case2308_bugged.p4
  extensions/p4_tests/p4_14/c2/COMPILER-420/case2433.p4
  extensions/p4_tests/p4_14/c2/COMPILER-421/case2434.p4
  extensions/p4_tests/p4_14/c2/COMPILER-426/case2475.p4
  extensions/p4_tests/p4_14/c2/COMPILER-443/case2514.p4
  extensions/p4_tests/p4_14/c2/COMPILER-466/case2563_with_nop.p4
  extensions/p4_tests/p4_14/c2/COMPILER-466/case2563_without_nop.p4
  extensions/p4_tests/p4_14/c2/COMPILER-475/case2600.p4
  extensions/p4_tests/p4_14/c2/COMPILER-502/case2675.p4
  extensions/p4_tests/p4_14/c2/COMPILER-510/case2682.p4
  extensions/p4_tests/p4_14/test_config_295_polynomial_hash.p4
  extensions/p4_tests/p4_14/test_config_308_hash_96b.p4
  extensions/p4_tests/p4_14/test_config_311_hash_adb.p4
  extensions/p4_tests/p4_14/test_config_307_dyn_selection.p4
  extensions/p4_tests/p4_14/test_config_309_wide_dyn_selection.p4
  extensions/p4_tests/p4_14/test_config_314_sym_hash.p4
  extensions/p4_tests/p4_14/test_config_315_sym_hash_neg_test_1.p4
  extensions/p4_tests/p4_14/test_config_316_sym_hash_neg_test_2.p4
  extensions/p4_tests/p4_14/test_config_317_sym_hash_neg_test_3.p4
  extensions/p4_tests/p4_14/test_config_318_sym_hash_neg_test_4.p4
  extensions/p4_tests/p4_14/test_config_319_sym_hash_neg_test_5.p4
  extensions/p4_tests/p4_14/c4/COMPILER-529/dnets_bng_case1.p4
  extensions/p4_tests/p4_14/c4/COMPILER-529/dnets_bng_case2.p4
  extensions/p4_tests/p4_14/c1/COMPILER-548/case2895.p4
  extensions/p4_tests/p4_14/c1/COMPILER-637/case3478.p4
  extensions/p4_tests/p4_14/c1/COMPILER-635/case3468.p4
  extensions/p4_tests/p4_14/c2/COMPILER-599/case3230.p4
  extensions/p4_tests/p4_14/c5/COMPILER-594/comp594.p4
  extensions/p4_tests/p4_14/c7/COMPILER-623/case3375.p4
# BRIG-28
  extensions/p4_tests/p4_14/switch/p4src/switch.p4
  )

set (P14_TEST_SUITES
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/*.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/c1/*/*.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/c2/*/*.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/c3/*/*.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/c4/*/*.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/c5/*/*.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/c6/*/*.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/c7/*/*.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/c8/*/*.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/switch/p4src/switch.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/jenkins/*/*.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/switch_*/switch.p4
  )

set (V12_DRIVER ${CMAKE_CURRENT_SOURCE_DIR}/test-v12-sample.sh)
 p4c_add_tests("p14_to_16" ${V12_DRIVER} "${P14_TEST_SUITES}" "${P14_XFAIL_TESTS}")
