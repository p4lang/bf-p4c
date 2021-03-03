# These tests must pass, even when specified as XFAIL in JBayXfail.cmake.

set (JBAY_MUST_PASS_TESTS
  extensions/p4_tests/p4_14/ptf/easy_exact.p4
  extensions/p4_tests/p4_14/ptf/easy_no_match_with_gateway.p4
  extensions/p4_tests/p4_14/ptf/easy_ternary.p4

  # p4-tests programs
  extensions/p4_tests/p4-programs/internal_p4_14/atomic_mod/atomic_mod.p4
  extensions/p4_tests/p4-programs/internal_p4_14/emulation/emulation.p4
  extensions/p4_tests/p4-programs/programs/basic_switching/basic_switching.p4
  extensions/p4_tests/p4-programs/programs/chksum/chksum.p4
  extensions/p4_tests/p4-programs/programs/deparse_zero/deparse_zero.p4
  extensions/p4_tests/p4-programs/programs/fast_reconfig/fast_reconfig.p4
  extensions/p4_tests/p4-programs/programs/mirror_test/mirror_test.p4
  extensions/p4_tests/p4-programs/programs/multicast_test/multicast_test.p4
  extensions/p4_tests/p4-programs/programs/pcie_pkt_test/pcie_pkt_test.p4
  extensions/p4_tests/p4-programs/programs/resubmit/resubmit.p4

  # p4-tests tna programs
  p4_16_programs_tna_32q_2pipe
  p4_16_programs_tna_32q_multiprogram_a
  p4_16_programs_tna_32q_multiprogram_b
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
  p4_16_programs_tna_simple_switch
  p4_16_programs_tna_ternary_match

  # Switch compile only
  smoketest_switch_16_compile_c0_profile
  smoketest_switch_16_compile_d0_profile
  smoketest_switch_16_compile

  # Customer profiles
  extensions/p4_tests/p4_16/customer/extreme/npb-master-20210108.p4
  extensions/p4_tests/p4_16/customer/extreme/npb-master-20210202.p4
  extensions/p4_tests/p4_16/customer/extreme/npb-master-20210211.p4
  # P4C-3610
  #extensions/p4_tests/p4_16/customer/extreme/npb-master-20210225.p4
  # P4C-3610
  #extensions/p4_tests/p4_16/customer/extreme/npb-master-20210301.p4
  extensions/p4_tests/p4_16/customer/extreme/p4c-3455.p4
  extensions/p4_tests/p4_16/customer/extreme/p4c-3455_2.p4
  extensions/p4_tests/p4_16/customer/arista/obfuscated-msee_tofino2_lkg.p4
  extensions/p4_tests/p4_16/customer/arista/obfuscated-p416_baremetal_tofino2.p4
  p4c-3171
  extensions/p4_tests/p4_16/customer/keysight/keysight-tf2.p4
  extensions/p4_tests/p4_16/customer/keysight/keysight-eagle-tf2.p4
  # extensions/p4_tests/p4_16/customer/keysight/p4c-2554.p4
  )
