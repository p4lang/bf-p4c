
set (SWITCH_VERSION 8.7)

set (TOFINO_MUST_PASS_TESTS
  extensions/p4_tests/p4_14/ptf/easy_exact.p4
  extensions/p4_tests/p4_14/ptf/easy_no_match_with_gateway.p4
  extensions/p4_tests/p4_14/ptf/easy_no_match.p4
  extensions/p4_tests/p4_14/ptf/easy_ternary.p4
  extensions/p4_tests/p4_14/ptf/easy.p4
  extensions/p4_tests/p4_14/ptf/ecmp_pi.p4
  extensions/p4_tests/p4_14/ptf/ternary_match_constant_action_data.p4
  extensions/p4_tests/p4_16/google-tor/p4/spec/tor.p4
  extensions/p4_tests/p4_16/ptf/hash_driven_stats.p4
  extensions/p4_tests/p4_16/ptf/ONLab_packetio.p4
  extensions/p4_tests/p4-programs/p4_16_programs/bf-onos/pipelines/fabric/src/main/resources/fabric-tofino.p4

  # p4-tests programs
  extensions/p4_tests/p4-programs/internal_p4_14/action_spec_format/action_spec_format.p4
  extensions/p4_tests/p4-programs/internal_p4_14/atomic_mod/atomic_mod.p4
  extensions/p4_tests/p4-programs/internal_p4_14/emulation/emulation.p4
  extensions/p4_tests/p4-programs/internal_p4_14/mau_mem_test/mau_mem_test.p4
  extensions/p4_tests/p4-programs/internal_p4_14/mau_tcam_test/mau_tcam_test.p4
  extensions/p4_tests/p4-programs/internal_p4_14/multi_thread_test/multi_thread_test.p4
  extensions/p4_tests/p4-programs/internal_p4_14/multicast_scale/multicast_scale.p4
  extensions/p4_tests/p4-programs/internal_p4_14/range/range.p4
  extensions/p4_tests/p4-programs/internal_p4_14/simple_l3_checksum_taken_default_ingress/simple_l3_checksum_taken_default_ingress.p4
  extensions/p4_tests/p4-programs/internal_p4_14/tcam_search/tcam_search.p4
  extensions/p4_tests/p4-programs/internal_p4_14/tofino_diag/tofino_diag.p4
  extensions/p4_tests/p4-programs/programs/basic_swithching/basic_switching.p4
  extensions/p4_tests/p4-programs/programs/chksum/chksum.p4
  extensions/p4_tests/p4-programs/programs/default_entry/default_entry.p4
  extensions/p4_tests/p4-programs/programs/deparse_zero/deparse_zero.p4
  extensions/p4_tests/p4-programs/programs/dkm/dkm.p4
  extensions/p4_tests/p4-programs/programs/drivers_test/drivers_test.p4
  extensions/p4_tests/p4-programs/programs/dyn_hash/dyn_hash.p4
  extensions/p4_tests/p4-programs/programs/ecmp_pi/ecmp_pi.p4
  extensions/p4_tests/p4-programs/programs/fast_reconfig/fast_reconfig.p4
  extensions/p4_tests/p4-programs/programs/ha/ha.p4
  extensions/p4_tests/p4-programs/programs/iterator/iterator.p4
  extensions/p4_tests/p4-programs/programs/knet_mgr_test/knet_mgr_test.p4
  extensions/p4_tests/p4-programs/programs/mirror_test/mirror_test.p4
  extensions/p4_tests/p4-programs/programs/multicast_test/multicast_test.p4
  extensions/p4_tests/p4-programs/programs/parser_error/parser_error.p4
  extensions/p4_tests/p4-programs/programs/parser_intr_md/parser_intr_md.p4
  extensions/p4_tests/p4-programs/programs/pcie_pkt_test/pcie_pkt_test.p4
  extensions/p4_tests/p4-programs/programs/perf_test/perf_test.p4
  extensions/p4_tests/p4-programs/programs/pgrs/pgrs.p4
  extensions/p4_tests/p4-programs/programs/pvs/pvs.p4
  extensions/p4_tests/p4-programs/programs/resubmit/resubmit.p4
  extensions/p4_tests/p4-programs/programs/smoke_large_tbls/smoke_large_tbls.p4
  extensions/p4_tests/p4-programs/programs/stats_pi/stats_pi.p4
  smoketest_programs_alpm_test
  smoketest_programs_basic_ipv4
  smoketest_programs_dkm
  smoketest_programs_exm_direct
  smoketest_programs_exm_direct_1
  smoketest_programs_exm_indirect_1
  smoketest_programs_exm_smoke_test
  smoketest_programs_hash_driven
  smoketest_programs_meters
# REL-462 is preventing a model update. Remove this once fixed
# smoketest_programs_stful

  # p4-tests tna programs
  p4_16_programs_tna_32q_2pipe
  p4_16_programs_tna_32q_multiprogram_a
  p4_16_programs_tna_32q_multiprogram_b
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
  p4_16_programs_tna_simple_switch
  p4_16_programs_tna_ternary_match

  # Switch compile only
  smoketest_switch_16_compile_a0_profile
  smoketest_switch_16_compile_b0_profile
  smoketest_switch_16_compile_l0_profile
  smoketest_switch_16_compile
  switch_${SWITCH_VERSION}_dc_basic
  switch_${SWITCH_VERSION}_ent_dc_general
  switch_${SWITCH_VERSION}_msdc
  switch_dc_basic
  switch_ent_dc_general
  switch_msdc

  # Customer profiles
  extensions/p4_tests/p4_16/customer/arista/p4c-1214.p4
  extensions/p4_tests/p4_16/customer/arista/p4c-1813.p4
# extensions/p4_tests/p4_16/customer/arista/p4c-2012.p4
  extensions/p4_tests/p4_16/customer/arista/p4c-2030.p4
  extensions/p4_tests/p4_16/customer/arista/p4c-2032.p4
  extensions/p4_tests/p4_16/customer/arista/p4c-2370.p4
  extensions/p4_tests/p4_16/customer/arista/obfuscated-default.p4
  extensions/p4_tests/p4_16/customer/arista/obfuscated-firewall.p4
  extensions/p4_tests/p4_16/customer/arista/obfuscated-l2subintf.p4
  extensions/p4_tests/p4_16/customer/arista/obfuscated-map.p4
  extensions/p4_tests/p4_16/customer/arista/obfuscated-media.p4
  extensions/p4_tests/p4_16/customer/arista/obfuscated-mpls_baremetal.p4
  extensions/p4_tests/p4_16/customer/arista/obfuscated-nat.p4
  extensions/p4_tests/p4_16/customer/arista/obfuscated-packet_filter.p4
  extensions/p4_tests/p4_16/customer/arista/obfuscated-small_scale_test.p4
  extensions/p4_tests/p4_16/customer/arista/obfuscated-stateless_load_balance_v4v6.p4
  extensions/p4_tests/p4_16/customer/extreme/p4c-1562-1.p4
  extensions/p4_tests/p4_16/customer/extreme/p4c-1572-b1.p4
  extensions/p4_tests/p4_16/customer/extreme/p4c-1809-1.p4
  extensions/p4_tests/p4_16/customer/extreme/p4c-1812-1.p4
  extensions/p4_tests/p4_16/customer/extreme/p4c-2313.p4
  extensions/p4_tests/p4_16/customer/kaloom/p4c-1832.p4
  extensions/p4_tests/p4_16/customer/kaloom/p4c-2410-leaf.p4
  extensions/p4_tests/p4_16/customer/kaloom/p4c-2410-spine.p4
  extensions/p4_tests/p4_16/customer/kaloom/p4c-2573-leaf.p4
  extensions/p4_tests/p4_16/customer/kaloom/p4c-2573-spine.p4
  extensions/p4_tests/p4_16/customer/kaloom/p4c-2753.p4
  extensions/p4_tests/p4_16/customer/kaloom/p4c-3678-leaf.p4
  extensions/p4_tests/p4_16/customer/kaloom/p4c-3678-spine.p4
  extensions/p4_tests/p4_16/customer/kaloom/p4c-3678-upf_0.p4
  extensions/p4_tests/p4_16/customer/kaloom/p4c-3678-upf_1.p4
  extensions/p4_tests/p4_16/customer/kaloom/p4c-3678-upf_2.p4
  extensions/p4_tests/p4_16/customer/kaloom/p4c-3678-upf_3.p4
  extensions/p4_tests/p4_16/customer/keysight/keysight-tf1.p4
  extensions/p4_tests/p4_16/customer/keysight/pktgen9_16.p4
  extensions/p4_tests/p4_14/customer/ruijie/p4c-2250.p4
)
