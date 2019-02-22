
set (SWITCH_VERSION 8.7)

set (TOFINO_MUST_PASS_TESTS
  extensions/p4_tests/p4_14/easy_no_match_with_gateway.p4
  extensions/p4_tests/p4_14/easy_ternary.p4
  extensions/p4_tests/p4_14/easy_exact.p4
  extensions/p4_tests/p4_14/easy.p4
  extensions/p4_tests/p4_14/easy_no_match.p4
  extensions/p4_tests/p4_14/ecmp_pi.p4
  extensions/p4_tests/p4_14/ternary_match_constant_action_data.p4
  extensions/p4_tests/p4_16/google-tor/p4/spec/tor.p4
  extensions/p4_tests/p4_16/hash_driven_stats.p4
  extensions/p4_tests/p4_16/ONLab_packetio.p4
  extensions/p4_tests/p4_16/p4_16/bf-onos-new/pipelines/fabric/src/main/resources/fabric-tofino.p4

  # p4-tests programs
  extensions/p4_tests/p4_14/p4-tests/programs/basic_swithching/basic_switching.p4
  extensions/p4_tests/p4_14/p4-tests/programs/emulation/emulation.p4
  extensions/p4_tests/p4_14/p4-tests/programs/fast_reconfig/fast_reconfig.p4
  extensions/p4_tests/p4_14/p4-tests/programs/mirror_test/mirror_test.p4
  extensions/p4_tests/p4_14/p4-tests/programs/multicast_test/multicast_test.p4
  extensions/p4_tests/p4_14/p4-tests/programs/pcie_pkt_test/pcie_pkt_test.p4
  extensions/p4_tests/p4_14/p4-tests/programs/pgrs/pgrs.p4
  extensions/p4_tests/p4_14/p4-tests/programs/resubmit/resubmit.p4
  extensions/p4_tests/p4_14/p4-tests/programs/smoke_large_tbls/smoke_large_tbls.p4
  extensions/p4_tests/p4_14/p4-tests/programs/deparse_zero/deparse_zero.p4
  extensions/p4_tests/p4_14/p4-tests/programs/tcam_search/tcam_search.p4
  extensions/p4_tests/p4_14/p4-tests/programs/mau_mem_test/mau_mem_test.p4
  extensions/p4_tests/p4_14/p4-tests/programs/multi_thread_test/multi_thread_test.p4
  extensions/p4_tests/p4_14/p4-tests/programs/drivers_test/drivers_test.p4
  extensions/p4_tests/p4_14/p4-tests/programs/mau_tcam_test/mau_tcam_test.p4
  extensions/p4_tests/p4_14/p4-tests/programs/chksum/chksum.p4
  extensions/p4_tests/p4_14/p4-tests/programs/atomic_mod/atomic_mod.p4
  extensions/p4_tests/p4_14/p4-tests/programs/ecmp_pi/ecmp_pi.p4
  extensions/p4_tests/p4_14/p4-tests/programs/action_spec_format/action_spec_format.p4
  extensions/p4_tests/p4_14/p4-tests/programs/knet_mgr_test/knet_mgr_test.p4
  extensions/p4_tests/p4_14/p4-tests/programs/dkm/dkm.p4
  extensions/p4_tests/p4_14/p4-tests/programs/range/range.p4
  extensions/p4_tests/p4_14/p4-tests/programs/parser_intr_md/parser_intr_md.p4
  extensions/p4_tests/p4_14/p4-tests/programs/pvs/pvs.p4
  extensions/p4_tests/p4_14/p4-tests/programs/tofino_diag/tofino_diag.p4
  extensions/p4_tests/p4_14/p4-tests/programs/dyn_hash/dyn_hash.p4
  extensions/p4_tests/p4_14/p4-tests/programs/iterator/iterator.p4
  extensions/p4_tests/p4_14/p4-tests/programs/stats_pi/stats_pi.p4
  extensions/p4_tests/p4_14/p4-tests/programs/parser_error/parser_error.p4
  extensions/p4_tests/p4_14/p4-tests/programs/default_entry/default_entry.p4
  extensions/p4_tests/p4_14/p4-tests/programs/multicast_scale/multicast_scale.p4
  extensions/p4_tests/p4_14/p4-tests/programs/perf_test/perf_test.p4
  extensions/p4_tests/p4_14/p4-tests/programs/ha/ha.p4
  smoketest_programs_alpm_test
  smoketest_programs_basic_ipv4
  smoketest_programs_dkm
  smoketest_programs_exm_direct
  smoketest_programs_exm_direct_1
  smoketest_programs_exm_indirect_1
  smoketest_programs_exm_smoke_test
  smoketest_programs_stful
  smoketest_programs_meters
  smoketest_programs_hash_driven

  # need to enable once we pass the correct arguments to bf-syslibs
  # extensions/p4_tests/p4_14/p4-tests/programs/perf_test_alpm/perf_test_alpm.p4
  
  # p4-tests tna programs
  p4_16_programs_simple_switch
  p4_16_programs_tna_32q_multiprogram_a
  p4_16_programs_tna_32q_multiprogram_b
  p4_16_programs_tna_32q_2pipe
  p4_16_programs_tna_action_profile
  p4_16_programs_tna_action_selector
  p4_16_programs_tna_counter
  p4_16_programs_tna_digest
  p4_16_programs_tna_dkm
  p4_16_programs_tna_dyn_hashing
  p4_16_programs_tna_exact_match
  p4_16_programs_tna_idletimeout
  p4_16_programs_tna_lpm_match
  p4_16_programs_tna_meter_bytecount_adjust
  p4_16_programs_tna_meter_lpf_wred
  p4_16_programs_tna_operations
  p4_16_programs_tna_port_metadata
  p4_16_programs_tna_port_metadata_extern
  p4_16_programs_tna_pvs
  p4_16_programs_tna_range_match
  p4_16_programs_tna_register
  p4_16_programs_tna_ternary_match

  # Switch compile only
  switch_dc_basic
  switch_ent_dc_general
  switch_msdc
  switch_${SWITCH_VERSION}_dc_basic
  switch_${SWITCH_VERSION}_ent_dc_general
  switch_${SWITCH_VERSION}_msdc  
  smoketest_switch_16_compile
  )
