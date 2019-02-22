
set (JBAY_MUST_PASS_TESTS
  extensions/p4_tests/p4_14/easy_no_match_with_gateway.p4
  extensions/p4_tests/p4_14/easy_ternary.p4
  extensions/p4_tests/p4_14/easy_exact.p4

  # p4-tests programs
  extensions/p4_tests/p4_14/p4-tests/programs/emulation/emulation.p4
  extensions/p4_tests/p4_14/p4-tests/programs/atomic_mod/atomic_mod.p4
  extensions/p4_tests/p4_14/p4-tests/programs/basic_switching/basic_switching.p4
  extensions/p4_tests/p4_14/p4-tests/programs/chksum/chksum.p4
  extensions/p4_tests/p4_14/p4-tests/programs/deparse_zero/deparse_zero.p4
  extensions/p4_tests/p4_14/p4-tests/programs/ha/ha.p4
  extensions/p4_tests/p4_14/p4-tests/programs/pcie_pkt_test/pcie_pkt_test.p4
  extensions/p4_tests/p4_14/p4-tests/programs/resubmit/resubmit.p4
  extensions/p4_tests/p4_14/p4-tests/programs/multicast_test/multicast_test.p4
  extensions/p4_tests/p4_14/p4-tests/programs/mirror_test/mirror_test.p4
  extensions/p4_tests/p4_14/p4-tests/programs/fast_reconfig/fast_reconfig.p4

  # p4-tests tna programs
  p4_16_programs_simple_switch
  p4_16_programs_tna_32q_multiprogram_a
  p4_16_programs_tna_32q_multiprogram_b
  p4_16_programs_tna_32q_2pipe
  p4_16_programs_tna_action_profile
  p4_16_programs_tna_action_selector
  p4_16_programs_tna_counter
  p4_16_programs_tna_digest
  p4_16_programs_tna_dyn_hashing
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

  # Switch compile only
  smoketest_switch_16_compile
  )
