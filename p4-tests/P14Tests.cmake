
# FIXME -- most of these programs fail due to the test repo reorg -- since the paths no
# FIXME -- longer contain the string 'p4_14' they get compiled as p4_16, which fails.
set (P14_XFAIL_TESTS
  extensions/p4_tests/p4_14/compile_only/02-FlexCounterActionProfile.p4
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
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/switch/p4src/switch.p4
  ${BFN_TESTS_LIST}
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/switch_*/switch.p4
  )

set (V12_DRIVER ${CMAKE_CURRENT_SOURCE_DIR}/test-v12-sample.sh)
 p4c_add_tests("p14_to_16" ${V12_DRIVER} "${P14_TEST_SUITES}" "${P14_XFAIL_TESTS}")

# tests which aren't supported by bf-p4c
# =======================================

p4c_add_xfail_reason("tofino"
  "There are issues with the following indirect externs"
  testdata/p4_14_samples/counter.p4
)

# assembler error
p4c_add_xfail_reason("tofino"
  "error: constant value .* too large for stateful alu"
  extensions/p4_tests/p4_14/compile_only/mau_test_neg_test.p4
)

p4c_add_xfail_reason("tofino"
  "error: .*: unsupported 64-bit select"
  testdata/p4_14_samples/simple_nat.p4
  testdata/p4_14_samples/copy_to_cpu.p4
  testdata/p4_14_samples/axon.p4
  testdata/p4_14_samples/source_routing.p4
)
