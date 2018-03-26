
set (P14_XFAIL_TESTS
  extensions/p4_tests/p4_14/02-FlexCounterActionProfile.p4
  extensions/p4_tests/p4_14/test_config_172_stateful_heavy_hitter.p4
  extensions/p4_tests/p4_14/test_config_160_stateful_single_bit_mode.p4
  extensions/p4_tests/p4_14/test_config_185_first_lpf.p4
  extensions/p4_tests/p4_14/test_config_201_meter_constant_index.p4
  extensions/p4_tests/p4_14/test_config_195_stateful_predicate_output.p4
  extensions/p4_tests/p4_14/test_config_205_modify_field_from_hash.p4
  extensions/p4_tests/p4_14/shared_names.p4
  extensions/p4_tests/p4_14/c2/COMPILER-408/case2364.p4
  extensions/p4_tests/p4_14/c2/COMPILER-514/balancer_one.p4
  extensions/p4_tests/p4_14/c2/COMPILER-537/case2834.p4
  extensions/p4_tests/p4_14/c2/COMPILER-533/case2736.p4
  extensions/p4_tests/p4_14/c2/COMPILER-443/case2514.p4
  extensions/p4_tests/p4_14/c2/COMPILER-466/case2563_with_nop.p4
  extensions/p4_tests/p4_14/c2/COMPILER-466/case2563_without_nop.p4
  extensions/p4_tests/p4_14/c2/COMPILER-475/case2600.p4
  extensions/p4_tests/p4_14/c2/COMPILER-502/case2675.p4
  extensions/p4_tests/p4_14/c2/COMPILER-510/case2682.p4
  extensions/p4_tests/p4_14/test_config_295_polynomial_hash.p4
  extensions/p4_tests/p4_14/test_config_308_hash_96b.p4
  extensions/p4_tests/p4_14/test_config_311_hash_adb.p4
  extensions/p4_tests/p4_14/test_config_309_wide_dyn_selection.p4
  extensions/p4_tests/p4_14/test_config_314_sym_hash.p4
  extensions/p4_tests/p4_14/c1/COMPILER-548/case2895.p4
  extensions/p4_tests/p4_14/c1/COMPILER-637/case3478.p4
  extensions/p4_tests/p4_14/c1/COMPILER-635/case3468.p4
  extensions/p4_tests/p4_14/c2/COMPILER-599/case3230.p4
  extensions/p4_tests/p4_14/c5/COMPILER-594/comp594.p4
  extensions/p4_tests/p4_14/c7/COMPILER-623/case3375.p4
  # count_with_hash primitive unsupported
  extensions/p4_tests/p4_14/p4-tests/programs/hash_driven/hash_driven.p4
  # proprietary algorithms for hash
  extensions/p4_tests/p4_14/p4-tests/programs/dyn_hash/dyn_hash.p4
  extensions/p4_tests/p4_14/p4-tests/programs/exm_direct/exm_direct.p4
  # hash_test.p4(171): error: set_p: parameter p must be bound
  extensions/p4_tests/p4_14/p4-tests/programs/hash_test/hash_test.p4
  # knet_mgr_test.p4(10): error: add_cpu_header: parameter fabric_color must be bound
  extensions/p4_tests/p4_14/p4-tests/programs/knet_mgr_test/knet_mgr_test.p4
  # tofino hash function extensions not supported with p4test
  extensions/p4_tests/p4_14/brig-540.p4
  extensions/p4_tests/p4_14/brig-540-2.p4
  )

# p4-tests has all the includes at the same level with the programs.
set (BFN_EXCLUDE_PATTERNS "tofino.p4")
set (BFN_TESTS "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4-tests/programs/*/*.p4")
bfn_find_tests ("${BFN_TESTS}" BFN_TESTS_LIST EXCLUDE "${BFN_EXCLUDE_PATTERNS}")

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
  ${BFN_TESTS_LIST}
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/switch_*/switch.p4
  )

set (V12_DRIVER ${CMAKE_CURRENT_SOURCE_DIR}/test-v12-sample.sh)
 p4c_add_tests("p14_to_16" ${V12_DRIVER} "${P14_TEST_SUITES}" "${P14_XFAIL_TESTS}")
