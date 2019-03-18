
set (P14_XFAIL_TESTS
  extensions/p4_tests/p4_14/compile_only/02-FlexCounterActionProfile.p4
  ../glass/testsuite/p4_tests/arista/COMPILER-254/case1744.p4
  ../glass/testsuite/p4_tests/arista/COMPILER-260/case1799_1.p4
  ../glass/testsuite/p4_tests/arista/COMPILER-260/case1799.p4
  ../glass/testsuite/p4_tests/arista/COMPILER-262/case1804.p4
  ../glass/testsuite/p4_tests/arista/COMPILER-263/case1795.p4
  ../glass/testsuite/p4_tests/arista/COMPILER-264/case1822.p4
  ../glass/testsuite/p4_tests/arista/COMPILER-271/case1834.p4
  ../glass/testsuite/p4_tests/arista/COMPILER-273/case1832.p4
  ../glass/testsuite/p4_tests/arista/COMPILER-273/case1832.p4
  ../glass/testsuite/p4_tests/arista/COMPILER-275/case1841.p4
  ../glass/testsuite/p4_tests/arista/COMPILER-276/case1844.p4
  ../glass/testsuite/p4_tests/arista/COMPILER-282/case1864.p4
  ../glass/testsuite/p4_tests/arista/COMPILER-347/switch_bug.p4
  ../glass/testsuite/p4_tests/arista/COMPILER-532/case2807.p4
  ../glass/testsuite/p4_tests/arista/COMPILER-548/case2895.p4
  ../glass/testsuite/p4_tests/arista/COMPILER-548/case3011.p4
  ../glass/testsuite/p4_tests/arista/COMPILER-559/case2987.p4
  ../glass/testsuite/p4_tests/arista/COMPILER-562/case3005.p4
  ../glass/testsuite/p4_tests/arista/COMPILER-567/case2807.p4
  ../glass/testsuite/p4_tests/arista/COMPILER-568/case3026dce.p4
  ../glass/testsuite/p4_tests/arista/COMPILER-568/case3026.p4
  ../glass/testsuite/p4_tests/arista/COMPILER-575/case3041.p4
  ../glass/testsuite/p4_tests/arista/COMPILER-576/case3042.p4
  ../glass/testsuite/p4_tests/arista/COMPILER-577/comp577.p4
  ../glass/testsuite/p4_tests/arista/COMPILER-579/case3085.p4
  ../glass/testsuite/p4_tests/arista/COMPILER-585/comp585.p4
  ../glass/testsuite/p4_tests/arista/COMPILER-588/comp588dce.p4
  ../glass/testsuite/p4_tests/arista/COMPILER-588/comp588.p4
  ../glass/testsuite/p4_tests/arista/COMPILER-589/comp589.p4
  ../glass/testsuite/p4_tests/arista/COMPILER-593/case3011.p4
  ../glass/testsuite/p4_tests/arista/COMPILER-608/case3263.p4
  ../glass/testsuite/p4_tests/arista/COMPILER-635/case3468.p4
  ../glass/testsuite/p4_tests/arista/COMPILER-637/case3478.p4
  ../glass/testsuite/p4_tests/arista/COMPILER-954/case5730.p4
  ../glass/testsuite/p4_tests/rdp/COMPILER-408/case2364.p4
  ../glass/testsuite/p4_tests/rdp/COMPILER-443/case2514.p4
  ../glass/testsuite/p4_tests/rdp/COMPILER-466/case2563_with_nop.p4
  ../glass/testsuite/p4_tests/rdp/COMPILER-466/case2563_without_nop.p4
  ../glass/testsuite/p4_tests/rdp/COMPILER-475/case2600.p4
  ../glass/testsuite/p4_tests/rdp/COMPILER-502/case2675.p4
  ../glass/testsuite/p4_tests/rdp/COMPILER-510/case2682.p4
  ../glass/testsuite/p4_tests/rdp/COMPILER-514/balancer_one.p4
  ../glass/testsuite/p4_tests/rdp/COMPILER-533/case2736.p4
  ../glass/testsuite/p4_tests/rdp/COMPILER-537/case2834.p4
  ../glass/testsuite/p4_tests/rdp/COMPILER-599/case3230.p4
  ../glass/testsuite/p4_tests/cisco/COMPILER-393/case2277.p4
  ../glass/testsuite/p4_tests/zte/COMPILER-594/comp594.p4
  ../glass/testsuite/p4_tests/microsoft/COMPILER-623/case3375.p4
  extensions/p4_tests/p4_14/compile_only/mau_test_neg_test.p4
  extensions/p4_tests/p4-programs/programs/emulation/emulation.p4
  extensions/p4_tests/p4-programs/programs/fifo/fifo_pair.p4
  extensions/p4_tests/p4-programs/programs/ipv4_checksum/ipv4_checksum.p4
  extensions/p4_tests/p4-programs/programs/mau_test/mau_test.p4
  extensions/p4_tests/p4-programs/programs/opcode_test/opcode_test.p4
  extensions/p4_tests/p4-programs/programs/stful/stful.p4
  extensions/p4_tests/p4_14/compile_only/shared_names.p4
  extensions/p4_tests/p4_14/stf/stateful2.p4
  extensions/p4_tests/p4_14/stf/stateful3.p4
  extensions/p4_tests/p4_14/stf/stateful_init_regs.p4
  extensions/p4_tests/p4_14/switch/p4src/switch.p4
  ../glass/testsuite/p4_tests/mau/test_config_142_stateful_bfd.p4
  ../glass/testsuite/p4_tests/mau/test_config_160_stateful_single_bit_mode.p4
  ../glass/testsuite/p4_tests/mau/test_config_163_stateful_table_math_unit.p4
  ../glass/testsuite/p4_tests/mau/test_config_166_stateful_generic_counter.p4
  ../glass/testsuite/p4_tests/mau/test_config_167_stateful_flowlet_switching.p4
  ../glass/testsuite/p4_tests/mau/test_config_171_stateful_conga.p4
  ../glass/testsuite/p4_tests/mau/test_config_172_stateful_heavy_hitter.p4
  ../glass/testsuite/p4_tests/mau/test_config_173_stateful_bloom_filter.p4
  ../glass/testsuite/p4_tests/mau/test_config_174_stateful_flow_learning.p4
  ../glass/testsuite/p4_tests/mau/test_config_191_invalidate.p4
  ../glass/testsuite/p4_tests/mau/test_config_205_modify_field_from_hash.p4
  ../glass/testsuite/p4_tests/mau/test_config_295_polynomial_hash.p4
  ../glass/testsuite/p4_tests/mau/test_config_308_hash_96b.p4
  ../glass/testsuite/p4_tests/mau/test_config_309_wide_dyn_selection.p4
  ../glass/testsuite/p4_tests/mau/test_config_311_hash_adb.p4
  ../glass/testsuite/p4_tests/mau/test_config_314_sym_hash.p4
  # proprietary algorithms for hash
  extensions/p4_tests/p4-programs/programs/dyn_hash/dyn_hash.p4
  extensions/p4_tests/p4-programs/programs/exm_direct/exm_direct.p4
  # hash_test.p4(171): error: set_p: parameter p must be bound
  extensions/p4_tests/p4-programs/programs/hash_test/hash_test.p4
  # tofino hash function extensions not supported with p4test
  extensions/p4_tests/p4_14/compile_only/brig-540.p4
  extensions/p4_tests/p4_14/compile_only/brig-540-2.p4
  )

# p4-tests has all the includes at the same level with the programs.
set (BFN_EXCLUDE_PATTERNS "tofino\\.p4" ".*netcache.*")
set (BFN_TESTS "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/programs/*/*.p4")
bfn_find_tests ("${BFN_TESTS}" BFN_TESTS_LIST EXCLUDE "${BFN_EXCLUDE_PATTERNS}")

set (P14_TEST_SUITES
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/compile_only/*.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/stf/*.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/ptf/*.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/customer/*.p4
  # Disable these as they are overriding the added p4_14 tests
  # TODO: Add them with different names if we need both
  #${BFN_P4C_SOURCE_DIR}/glass/testsuite/p4_tests/c1/*/*.p4
  #${BFN_P4C_SOURCE_DIR}/glass/testsuite/p4_tests/c2/*/*.p4
  ${BFN_P4C_SOURCE_DIR}/glass/testsuite/p4_tests/cisco/*/*.p4
  ${BFN_P4C_SOURCE_DIR}/glass/testsuite/p4_tests/ixia/*/*.p4
  ${BFN_P4C_SOURCE_DIR}/glass/testsuite/p4_tests/zte/*/*.p4
  ${BFN_P4C_SOURCE_DIR}/glass/testsuite/p4_tests/embedway/*/*.p4
  ${BFN_P4C_SOURCE_DIR}/glass/testsuite/p4_tests/microsoft/*/*.p4
  ${BFN_P4C_SOURCE_DIR}/glass/testsuite/p4_tests/tudarmstadt/*/*.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/switch/p4src/switch.p4
  ${BFN_TESTS_LIST}
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/switch_*/switch.p4
  )

set (V12_DRIVER ${CMAKE_CURRENT_SOURCE_DIR}/test-v12-sample.sh)
 p4c_add_tests("p14_to_16" ${V12_DRIVER} "${P14_TEST_SUITES}" "${P14_XFAIL_TESTS}")
