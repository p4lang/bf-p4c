
# FIXME -- most of these programs fail due to the test repo reorg -- since the paths no
# FIXME -- longer contain the string 'p4_14' they get compiled as p4_16, which fails.
set (P14_XFAIL_TESTS
  extensions/p4_tests/p4_14/compile_only/02-FlexCounterActionProfile.p4
  extensions/p4_tests/glass/arista/COMPILER-254/case1744.p4
  extensions/p4_tests/glass/arista/COMPILER-260/case1799_1.p4
  extensions/p4_tests/glass/arista/COMPILER-260/case1799.p4
  extensions/p4_tests/glass/arista/COMPILER-263/case1795.p4
  extensions/p4_tests/glass/arista/COMPILER-264/case1822.p4
  extensions/p4_tests/glass/arista/COMPILER-271/case1834.p4
  extensions/p4_tests/glass/arista/COMPILER-273/case1832.p4
  extensions/p4_tests/glass/arista/COMPILER-273/case1832.p4
  extensions/p4_tests/glass/arista/COMPILER-275/case1841.p4
  extensions/p4_tests/glass/arista/COMPILER-276/case1844.p4
  extensions/p4_tests/glass/arista/COMPILER-282/case1864.p4
  extensions/p4_tests/glass/arista/COMPILER-347/switch_bug.p4
  extensions/p4_tests/glass/arista/COMPILER-532/case2807.p4
  extensions/p4_tests/glass/arista/COMPILER-548/case2895.p4
  extensions/p4_tests/glass/arista/COMPILER-548/case3011.p4
  extensions/p4_tests/glass/arista/COMPILER-559/case2987.p4
  extensions/p4_tests/glass/arista/COMPILER-562/case3005.p4
  extensions/p4_tests/glass/arista/COMPILER-567/case2807.p4
  extensions/p4_tests/glass/arista/COMPILER-568/case3026dce.p4
  extensions/p4_tests/glass/arista/COMPILER-568/case3026.p4
  extensions/p4_tests/glass/arista/COMPILER-575/case3041.p4
  extensions/p4_tests/glass/arista/COMPILER-576/case3042.p4
  extensions/p4_tests/glass/arista/COMPILER-577/comp577.p4
  extensions/p4_tests/glass/arista/COMPILER-579/case3085.p4
  extensions/p4_tests/glass/arista/COMPILER-585/comp585.p4
  extensions/p4_tests/glass/arista/COMPILER-588/comp588dce.p4
  extensions/p4_tests/glass/arista/COMPILER-588/comp588.p4
  extensions/p4_tests/glass/arista/COMPILER-589/comp589.p4
  extensions/p4_tests/glass/arista/COMPILER-593/case3011.p4
  extensions/p4_tests/glass/arista/COMPILER-608/case3263.p4
  extensions/p4_tests/glass/arista/COMPILER-635/case3468.p4
  extensions/p4_tests/glass/arista/COMPILER-637/case3478.p4
  extensions/p4_tests/glass/arista/COMPILER-954/case5730.p4
  extensions/p4_tests/glass/cisco/COMPILER-393/case2277.p4
  extensions/p4_tests/glass/cisco/COMPILER-1140/case8399.p4
  extensions/p4_tests/glass/cisco/COMPILER-1140/comp_1140.p4
  extensions/p4_tests/glass/cisco/COMPILER-1143/case8542.p4
  extensions/p4_tests/glass/cisco/COMPILER-1146/case8575.p4
  extensions/p4_tests/glass/cisco/COMPILER-1147/comp_1147.p4
  extensions/p4_tests/glass/embedway/COMPILER-603/loop.p4
  extensions/p4_tests/glass/embedway/COMPILER-604/new_parser.p4
  extensions/p4_tests/glass/embedway/COMPILER-714/gtp_headers.p4
  extensions/p4_tests/glass/embedway/COMPILER-714/headers.p4
  extensions/p4_tests/glass/embedway/COMPILER-714/tcp_options_unit.p4
  extensions/p4_tests/glass/embedway/COMPILER-765/gtp_headers.p4
  extensions/p4_tests/glass/embedway/COMPILER-765/headers.p4
  extensions/p4_tests/glass/embedway/COMPILER-765/parser_tcp_ip_option_mul.p4
  extensions/p4_tests/glass/embedway/COMPILER-765/parser_tcp_option_mul.p4
  extensions/p4_tests/glass/embedway/COMPILER-921/comp_921.p4
  extensions/p4_tests/glass/ixia/COMPILER-522/case2774.p4
  extensions/p4_tests/glass/ixia/COMPILER-523/vag2774.p4
  extensions/p4_tests/glass/ixia/COMPILER-529/dnets_bng_case1.p4
  extensions/p4_tests/glass/ixia/COMPILER-529/dnets_bng_case2.p4
  extensions/p4_tests/glass/ixia/COMPILER-549/case2898.p4
  extensions/p4_tests/glass/ixia/COMPILER-550/vag2899.p4
  extensions/p4_tests/glass/ixia/COMPILER-590/case3179.p4
  extensions/p4_tests/glass/ixia/COMPILER-591/case3176.p4
  extensions/p4_tests/glass/microsoft/CASE-6342/case6342.p4
  extensions/p4_tests/glass/microsoft/COMPILER-606/case3259.p4
  extensions/p4_tests/glass/microsoft/COMPILER-623/case3375.p4
  extensions/p4_tests/glass/microsoft/COMPILER-713/case3975.p4
  extensions/p4_tests/glass/microsoft/COMPILER-982/case6409.p4
  extensions/p4_tests/glass/microsoft/COMPILER-983/case6463.p4
  extensions/p4_tests/glass/microsoft/COMPILER-991/vag6589.p4
  extensions/p4_tests/glass/rdp/COMPILER-408/case2364.p4
  extensions/p4_tests/glass/rdp/COMPILER-443/case2514.p4
  extensions/p4_tests/glass/rdp/COMPILER-466/case2563_with_nop.p4
  extensions/p4_tests/glass/rdp/COMPILER-466/case2563_without_nop.p4
  extensions/p4_tests/glass/rdp/COMPILER-475/case2600.p4
  extensions/p4_tests/glass/rdp/COMPILER-502/case2675.p4
  extensions/p4_tests/glass/rdp/COMPILER-510/case2682.p4
  extensions/p4_tests/glass/rdp/COMPILER-514/balancer_one.p4
  extensions/p4_tests/glass/rdp/COMPILER-533/case2736.p4
  extensions/p4_tests/glass/rdp/COMPILER-537/case2834.p4
  extensions/p4_tests/glass/rdp/COMPILER-599/case3230.p4
  extensions/p4_tests/glass/tudarmstadt/COMPILER-616/case3331.p4
  extensions/p4_tests/glass/tudarmstadt/COMPILER-779/case4343.p4
  extensions/p4_tests/glass/tudarmstadt/COMPILER-805/case4825.p4
  extensions/p4_tests/glass/tudarmstadt/COMPILER-1128/case8348.p4
  extensions/p4_tests/glass/zte/COMPILER-594/comp594.p4
  extensions/p4_tests/p4-programs/programs/alpm_test/alpm_test.p4
  extensions/p4_tests/p4-programs/programs/basic_ipv4/basic_ipv4.p4
  extensions/p4_tests/p4-programs/programs/basic_switching/basic_switching.p4
  extensions/p4_tests/p4-programs/programs/chksum/chksum.p4
  extensions/p4_tests/p4-programs/programs/default_entry/default_entry.p4
  extensions/p4_tests/p4-programs/programs/deparse_zero/deparse_zero.p4
  extensions/p4_tests/p4-programs/programs/dkm/dkm.p4
  extensions/p4_tests/p4-programs/programs/drivers_test/drivers_test.p4
  extensions/p4_tests/p4-programs/programs/emulation/emulation.p4
  extensions/p4_tests/p4-programs/programs/exm_direct_1/exm_direct_1.p4
  extensions/p4_tests/p4-programs/programs/exm_indirect_1/exm_indirect_1.p4
  extensions/p4_tests/p4-programs/programs/exm_smoke_test/exm_smoke_test.p4
  extensions/p4_tests/p4-programs/programs/fast_reconfig/fast_reconfig.p4
  extensions/p4_tests/p4-programs/programs/fifo/fifo_pair.p4
  extensions/p4_tests/p4-programs/programs/ha/ha.p4
  extensions/p4_tests/p4-programs/programs/hash_driven/hash_driven.p4
  extensions/p4_tests/p4-programs/programs/iterator/iterator.p4
  extensions/p4_tests/p4-programs/programs/ipv4_checksum/ipv4_checksum.p4
  extensions/p4_tests/p4-programs/programs/knet_mgr_test/knet_mgr_test.p4
  extensions/p4_tests/p4-programs/programs/mau_test/mau_test.p4
  extensions/p4_tests/p4-programs/programs/meters/meters.p4
  extensions/p4_tests/p4-programs/programs/mirror_test/mirror_test.p4
  extensions/p4_tests/p4-programs/programs/multicast_test/multicast_test.p4
  extensions/p4_tests/p4-programs/programs/multi_device/multi_device.p4
  extensions/p4_tests/p4-programs/programs/opcode_test/opcode_test.p4
  extensions/p4_tests/p4-programs/programs/parser_error/parser_error.p4
  extensions/p4_tests/p4-programs/programs/parser_intr_md/parser_intr_md.p4
  extensions/p4_tests/p4-programs/programs/pcie_pkt_test/pcie_pkt_test.p4
  extensions/p4_tests/p4-programs/programs/perf_test/perf_test.p4
  extensions/p4_tests/p4-programs/programs/perf_test_alpm/perf_test_alpm.p4
  extensions/p4_tests/p4-programs/programs/pgrs/pgrs.p4
  extensions/p4_tests/p4-programs/programs/pvs/pvs.p4
  extensions/p4_tests/p4-programs/programs/resubmit/resubmit.p4
  extensions/p4_tests/p4-programs/programs/smoke_large_tbls/smoke_large_tbls.p4
  extensions/p4_tests/p4-programs/programs/stful/stful.p4
  extensions/p4_tests/p4_14/compile_only/shared_names.p4
  extensions/p4_tests/p4_14/stf/hash_calculation_16.p4
  extensions/p4_tests/p4_14/stf/hash_calculation_32.p4
  extensions/p4_tests/p4_14/switch/p4src/switch.p4
  extensions/p4_tests/glass/mau/test_config_142_stateful_bfd.p4
  extensions/p4_tests/glass/mau/test_config_160_stateful_single_bit_mode.p4
  extensions/p4_tests/glass/mau/test_config_163_stateful_table_math_unit.p4
  extensions/p4_tests/glass/mau/test_config_166_stateful_generic_counter.p4
  extensions/p4_tests/glass/mau/test_config_167_stateful_flowlet_switching.p4
  extensions/p4_tests/glass/mau/test_config_171_stateful_conga.p4
  extensions/p4_tests/glass/mau/test_config_172_stateful_heavy_hitter.p4
  extensions/p4_tests/glass/mau/test_config_173_stateful_bloom_filter.p4
  extensions/p4_tests/glass/mau/test_config_174_stateful_flow_learning.p4
  extensions/p4_tests/glass/mau/test_config_191_invalidate.p4
  extensions/p4_tests/glass/mau/test_config_205_modify_field_from_hash.p4
  extensions/p4_tests/glass/mau/test_config_295_polynomial_hash.p4
  extensions/p4_tests/glass/mau/test_config_308_hash_96b.p4
  extensions/p4_tests/glass/mau/test_config_309_wide_dyn_selection.p4
  extensions/p4_tests/glass/mau/test_config_311_hash_adb.p4
  extensions/p4_tests/glass/mau/test_config_314_sym_hash.p4
  # proprietary algorithms for hash
  extensions/p4_tests/p4-programs/programs/dyn_hash/dyn_hash.p4
  extensions/p4_tests/p4-programs/programs/exm_direct/exm_direct.p4
  # hash_test.p4(171): error: set_p: parameter p must be bound
  extensions/p4_tests/p4-programs/programs/hash_test/hash_test.p4
  # tofino hash function extensions not supported with p4test
  extensions/p4_tests/p4_14/compile_only/brig-540-2.p4
  # some declarations not supported with p4test
  extensions/p4_tests/p4_14/compile_only/brig-814.p4
  # execute_meter errors with p4test
  extensions/p4_tests/p4_14/compile_only/mau_test_neg_test.p4
  # some types not supported with p4test: error: hash: Cannot unify .*
  extensions/p4_tests/p4_14/stf/hash_calculation_8.p4
  extensions/p4_tests/p4_14/stf/cond_checksum_update_3.p4
  extensions/p4_tests/p4_14/stf/update_checksum_9.p4
  # tofino primitives not supported with p4test
  extensions/p4_tests/p4_14/stf/header_validity_1.p4
  extensions/p4_tests/p4_14/stf/decaf_3.p4
  extensions/p4_tests/p4_14/ptf/p4c2662.p4
  # could not find type with p4test
  extensions/p4_tests/p4_14/stf/sful_sel1.p4
  # tofino specific p4
  extensions/p4_tests/p4_14/ptf/sful_split1.p4
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
  #${BFN_P4C_SOURCE_DIR}/extensions/p4_tests/glass/c1/*/*.p4
  #${BFN_P4C_SOURCE_DIR}/extensions/p4_tests/glass/c2/*/*.p4
  #${BFN_P4C_SOURCE_DIR}/extensions/p4_tests/glass/cisco/*/*.p4
  #${BFN_P4C_SOURCE_DIR}/extensions/p4_tests/glass/ixia/*/*.p4
  #${BFN_P4C_SOURCE_DIR}/extensions/p4_tests/glass/zte/*/*.p4
  #${BFN_P4C_SOURCE_DIR}/extensions/p4_tests/glass/embedway/*/*.p4
  #${BFN_P4C_SOURCE_DIR}/extensions/p4_tests/glass/microsoft/*/*.p4
  #${BFN_P4C_SOURCE_DIR}/extensions/p4_tests/glass/tudarmstadt/*/*.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/switch/p4src/switch.p4
  ${BFN_TESTS_LIST}
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/switch_*/switch.p4
  )

set (V12_DRIVER ${CMAKE_CURRENT_SOURCE_DIR}/test-v12-sample.sh)
 p4c_add_tests("p14_to_16" ${V12_DRIVER} "${P14_TEST_SUITES}" "${P14_XFAIL_TESTS}")
