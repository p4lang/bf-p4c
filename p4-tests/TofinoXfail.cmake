# Some of these failures are still P4 v1.0 front-end bugs.
# Others are due to non-standard extensions to P4:
# The *meter* tests use direct meters and execute_meter calls with 4 arguments (not in spec)
# The *recircualte* tests use a different (non standard?) reciculate primitive
# The *stateful* tests use extensions to P4 not in spec
# FlexCounter, action_profile use a non-standard Algorithm
# TwoReferences invokes a table twice - maybe it should become a negative test?
# *range* match type is not supported by BMv2 (used also in error_detection*.p4)
set (TOFINO_XFAIL_TESTS # this is intentionally empty because xfails should be added with a reason.
  # look for the failure message in this file and add to an existing ticket
  # or open a new one.
  )

# These tests compile successfuly and fail in the model when running the STF test
# the reasons need more characterization
if (HARLYN_STF_tofino AND NOT ENABLE_STF2PTF)
set (TOFINO_XFAIL_TESTS ${TOFINO_XFAIL_TESTS}
  extensions/p4_tests/p4_14/hash_calculation_32.p4
  # default drop packet instead of writing to port 0
  testdata/p4_16_samples/issue635-bmv2.p4
  testdata/p4_16_samples/issue655-bmv2.p4
  )

  p4c_add_xfail_reason("tofino"
    "mismatch from expected(.*) at byte .*"
    extensions/p4_tests/p4_16/cast_widening_set.p4
    )

  # Brig/Glass do not follow P4_14 spec for 'drop' in the ingress pipeline
  p4c_add_xfail_reason("tofino"
    "expected packet[s]* on port .* not seen"
    testdata/p4_14_samples/gateway1.p4
    testdata/p4_14_samples/gateway2.p4
    testdata/p4_14_samples/gateway3.p4
    testdata/p4_14_samples/gateway4.p4
    testdata/p4_16_samples/issue774-4-bmv2.p4
    testdata/p4_16_samples/issue1000-bmv2.p4
    )

endif() # HARLYN_STF_tofino

# Tests that run packets:
# Better to have these at the beginning of the file so that we
# do not overwrite any of the compilation errors.

if (ENABLE_STF2PTF AND PTF_REQUIREMENTS_MET)
  # STF2PTF tests that fail

  p4c_add_xfail_reason("tofino"
    "AssertionError: Expected packet was not received on device"
    extensions/p4_tests/p4_14/no_match_miss.p4
    testdata/p4_16_samples/issue635-bmv2.p4
    testdata/p4_16_samples/issue655-bmv2.p4
    # Brig/Glass do not follow P4_14 spec for 'drop' in the ingress pipeline
    testdata/p4_14_samples/gateway1.p4
    testdata/p4_14_samples/gateway2.p4
    testdata/p4_14_samples/gateway3.p4
    testdata/p4_14_samples/gateway4.p4
    )

  p4c_add_xfail_reason("tofino"
    "AssertionError: .*: wrong (packets|bytes) count: expected [0-9]+ not [0-9]+"
    # counter3 fails because it receives 64 bytes: for PTF the test should be adjusted to send more than 8 bytes
    testdata/p4_14_samples/counter3.p4
    )

  # P4runtime p4info.proto gen
  p4c_add_xfail_reason("tofino"
    "Match field .* is too complicated to represent in P4Runtime"
    testdata/p4_14_samples/exact_match_mask1.p4
    )

# BRIG-241
  p4c_add_xfail_reason("tofino"
    "AssertionError: Invalid match name .* for table .*"
    testdata/p4_14_samples/exact_match_mask1.p4
    )


  p4c_add_xfail_reason("tofino"
    "stf2ptf.STF2ptf ... ERROR"
    # Detailed: "KeyError: (0, 10)"
    testdata/p4_14_samples/parser_dc_full.p4
    # Detailed: "Error when adding match entry to target"
    testdata/p4_14_samples/exact_match3.p4
    )

  p4c_add_xfail_reason("tofino"
    "Error when trying to push config to bf_switchd"
    extensions/p4_tests/p4_14/sful_1bit.p4
    extensions/p4_tests/p4_14/stateful2.p4
    )

endif() # ENABLE_STF2PTF AND PTF_REQUIREMENTS_MET

if (PTF_REQUIREMENTS_MET)

  p4c_add_xfail_reason("tofino"
    "The following operation is not yet supported"
    extensions/p4_tests/p4_14/p4-tests/programs/opcode_test/opcode_test.p4
    )

  p4c_add_xfail_reason("tofino"
    "AssertionError: .* != .*"
    #extensions/p4_tests/p4_14/p4-tests/programs/multicast_test/multicast_test.p4
    extensions/p4_tests/p4_14/p4-tests/programs/stful/stful.p4
    )

  p4c_add_xfail_reason("tofino"
    "AttributeError: Client instance has no attribute .*"
    smoketest_programs_alpm_test_TestIdleTime
    extensions/p4_tests/p4_14/p4-tests/programs/exm_direct_1/exm_direct_1.p4
    extensions/p4_tests/p4_14/p4-tests/programs/exm_smoke_test/exm_smoke_test.p4
    extensions/p4_tests/p4_14/p4-tests/programs/perf_test_alpm/perf_test_alpm.p4
    extensions/p4_tests/p4_14/p4-tests/programs/multicast_test/multicast_test.p4
    )

  p4c_add_xfail_reason("tofino"
    "AssertionError: Expected packet was not received on device"
    extensions/p4_tests/p4_14/p4-tests/programs/exm_indirect_1/exm_indirect_1.p4
    extensions/p4_tests/p4_14/p4-tests/programs/resubmit/resubmit.p4
    04-simple_l3_nexthop
    05-simple_l3_arping
    smoketest_switch_dc_basic_L2GeneveUnicastBasicTest
    smoketest_switch_dc_basic_L2IPv4InIPv6VxlanUnicastBasicTest
    smoketest_switch_dc_basic_L2MplsPopTest
    smoketest_switch_dc_basic_L2NvgreUnicastBasicTest
    smoketest_switch_dc_basic_L2VxlanArpUnicastBasicTest
    smoketest_switch_dc_basic_L2VxlanToGeneveUnicastBasicTest
    smoketest_switch_dc_basic_L2VxlanUnicastBasicTest
    smoketest_switch_dc_basic_L3VxlanUnicastMultiTunnelSMTest
    smoketest_switch_dc_basic_L3VxlanUnicastTunnelECMPLagReflectionSMTest
    smoketest_switch_dc_basic_L3VxlanUnicastTunnelSMTest
    p4testgen_emulation
    smoketest_switch_ent_dc_general_IPAclStatsTest
    smoketest_switch_ent_dc_general_AclLabelTest
    smoketest_switch_ent_dc_general_IPIngressAclRangeTcamTest
    smoketest_switch_ent_dc_general_IPAclTest
    smoketest_switch_ent_dc_general_MirrorAclTest_i2e
    smoketest_switch_ent_dc_general_HostIfRxTxTest
    smoketest_switch_ent_dc_general_L3VxlanUnicastTunnelSMTest
    smoketest_switch_ent_dc_general_L3VIIPv4HostVlanTaggingTest
    smoketest_switch_ent_dc_general_L3IPv4HostTest
    smoketest_switch_ent_dc_general_ExceptionPacketsTest_IPV6
    smoketest_switch_ent_dc_general_L3IPv4SubIntfHostTest
    smoketest_switch_ent_dc_general_L3IPv6LpmTest
    smoketest_switch_ent_dc_general_L3IPv6HostTest
    smoketest_switch_ent_dc_general_MalformedPacketsTest_tunnel
    smoketest_switch_ent_dc_general_L3VIIPv4HostFloodTest
    smoketest_switch_ent_dc_general_L3IPv4HostJumboTest
    smoketest_switch_ent_dc_general_L3VIIPv4HostMacMoveTest
    smoketest_switch_ent_dc_general_L3IPv4LpmTest
    smoketest_switch_ent_dc_general_L3VINhopGleanTest
    smoketest_switch_ent_dc_general_ExceptionPacketsTest
    smoketest_switch_ent_dc_general_HostIfV6Test
    smoketest_switch_ent_dc_general_L3VIIPv6HostTest
    smoketest_switch_ent_dc_general_L2VxlanUnicastBasicTest
    smoketest_switch_ent_dc_general_L3IPv4HostModifyTest
    smoketest_switch_ent_dc_general_L3VIIPv4HostTest
    smoketest_switch_ent_dc_general_L2VxlanArpUnicastBasicTest
    )

  p4c_add_xfail_reason("tofino"
    "AssertionError: Did not receive any expected packet on any of ports"
    smoketest_switch_ent_dc_general_L3VxlanUnicastTunnelECMPLagReflectionSMTest
    smoketest_switch_ent_dc_general_L3VxlanUnicastTunnelECMPSMTest
    smoketest_switch_ent_dc_general_L3IPv6LagTest
    smoketest_switch_ent_dc_general_L3IPv6EcmpTest
    smoketest_switch_ent_dc_general_L3IPv6LpmEcmpTest
    smoketest_switch_ent_dc_general_L3IPv4EcmpTest
    smoketest_switch_ent_dc_general_L3IPv4LagTest
    smoketest_switch_ent_dc_general_L3EcmpLagTest
    smoketest_switch_ent_dc_general_L3IPv4EcmpSeedTest
    smoketest_switch_ent_dc_general_L3IPv4LpmEcmpTest
    smoketest_switch_ent_dc_general_L2VxlanUnicastLagBasicTest   
    smoketest_switch_ent_dc_general_L3VIIPv4LagTest 
    )

  p4c_add_xfail_reason("tofino"
    "AssertionError: Received packet that we expected not to receive on device"
    smoketest_switch_ent_dc_general_L2StpTest
    )

  p4c_add_xfail_reason("tofino"
    "AssertionError: A packet was received on device"
    smoketest_switch_ent_dc_general_L2StpEgressBlockingTest
    )

  # TypeError: format_failure() takes exactly 2 arguments (1 given)
  p4c_add_xfail_reason("tofino"
    "TypeError: format_failure"
    smoketest_switch_ent_dc_general_CpuTxTest
    )
    
  p4c_add_xfail_reason("tofino"
    ".*InvalidSnapshotOperation.*"
    smoketest_programs_alpm_test_TestSnapshot
    )

# BRIG-686
# NameError: global name 'smoke_large_tbls_idle_stats_tbl_match_spec_t' is not defined
  p4c_add_xfail_reason("tofino"
    "NameError: global name"
    p4testgen_smoke_large_tbls
    )

  # Timeouts -- need a better way to handle timeouts!!
  # p4c_add_xfail_reason("tofino"
  #   "Test time = 500.*sec"
  #   extensions/p4_tests/p4_14/p4-tests/programs/exm_direct/exm_direct.p4
  #   extensions/p4_tests/p4_14/p4-tests/programs/meters/meters.p4
  #   )

  # Inner UDP length field is "corrupted" for test.SpgwDownlinkMPLS_INT_Test.
  # See BRIG-578
  p4c_add_xfail_reason("tofino"
    "Expected packet was not received on device"
    fabric-DWITH_SPGW-DWITH_INT_TRANSIT
    )

  # fails also with Glass.
  p4c_add_xfail_reason("tofino"
    ".* is splitted, but it should not."
    11-simple_l3_mirror
    )
  # broken test: https://github.com/barefootnetworks/p4examples/issues/5
  p4c_add_xfail_reason("tofino"
    "SyntaxError: invalid syntax"
    30-p4calc
    )

  # broken test: https://github.com/barefootnetworks/p4examples/issues/6
  p4c_add_xfail_reason("tofino"
    "ImportError: No module named simple_l3.p4_pd_rpc.ttypes"
    06-simple_l3_dir_cntr
    )

  # default action not programmed by drivers
  p4c_add_xfail_reason("tofino"
    "Expected packet was not received on device"
    extensions/p4_tests/p4_16/large_action_data_constant.p4
    )

endif() # PTF_REQUIREMENTS_MET


# add the failures with no reason
p4c_add_xfail_reason("tofino" "" ${TOFINO_XFAIL_TESTS})

# This test fails because two fields are mutually exclusive in the parser, but
# one is added in the MAU while the other is live.  This behavior matches glass
# but is known to be incorrect.
p4c_add_xfail_reason("tofino"
  "instruction slot [0-9]+ used multiple times in action"
  extensions/p4_tests/p4_14/overlay_add_header.p4
  )

# BRIG-104
#p4c_add_xfail_reason("tofino"
#  "Unhandled action bitmask constraint"
#  extensions/p4_tests/p4_14/13-IngressEgressConflict.p4
#  )

# Fails due to complex expressions in the parser that our hardware can't support.
p4c_add_xfail_reason("tofino"
  "error: Assignment cannot be supported in the parser"
  testdata/p4_16_samples/scalarmeta-bmv2.p4
  testdata/p4_14_samples/axon.p4
  testdata/p4_16_samples/stack_complex-bmv2.p4
  testdata/p4_16_samples/issue737-bmv2.p4
  testdata/p4_16_samples/psa-ether-wire.p4
  testdata/p4_16_samples/array-copy-bmv2.p4
  )

p4c_add_xfail_reason("tofino"
  "more than can fit in the 32 byte input buffer"
  testdata/p4_14_samples/port_vlan_mapping.p4
  )

p4c_add_xfail_reason("tofino"
  "metadata arrays not handled in InstanceRef::InstanceRef"
  testdata/p4_16_samples/equality-bmv2.p4
)

p4c_add_xfail_reason("tofino"
  "error: Field .* of header .* cannot have type header"
  testdata/p4_16_samples/subparser-with-header-stack-bmv2.p4
  testdata/p4_16_samples/issue281.p4
  )

p4c_add_xfail_reason("tofino"
  "error: Could not find declaration for action_.*"
  testdata/p4_16_samples/action_profile-bmv2.p4
  testdata/p4_16_samples/issue297-bmv2.p4
  )

# BRIG-108
p4c_add_xfail_reason("tofino"
  "No format in action table"
  testdata/p4_14_samples/selector0.p4
  #testdata/p4_16_samples/action_profile-bmv2.p4
  #testdata/p4_16_samples/issue297-bmv2.p4
  testdata/p4_14_samples/port_vlan_mapping.p4
  )

# Too big a select key (96 bits) for tofino to match in one parser state.  Could be split into
# mulitple states?
p4c_add_xfail_reason("tofino"
  "error: Too much data for parse matcher"
  testdata/p4_16_samples/issue995-bmv2.p4
  )

# varbit extracts don't work in parser
p4c_add_xfail_reason("tofino"
  "Wrong number of arguments for method call"
  testdata/p4_16_samples/equality-varbit-bmv2.p4
  testdata/p4_16_samples/issue447-bmv2.p4
  testdata/p4_16_samples/issue447-1-bmv2.p4
  testdata/p4_16_samples/issue447-2-bmv2.p4
  testdata/p4_16_samples/issue447-3-bmv2.p4
  testdata/p4_16_samples/issue447-4-bmv2.p4
  testdata/p4_16_samples/issue1025-bmv2.p4
  )
# varbit not handled in backend
p4c_add_xfail_reason("tofino"
  "Unhandled InstanceRef type"
  testdata/p4_16_samples/issue447-5-bmv2.p4
  )

# # BRIG-112
# p4c_add_xfail_reason("tofino"
#   "ALU ops cannot operate on slices"
#   extensions/p4_tests/p4_14/c1/COMPILER-228/case1644.p4
#   )

p4c_add_xfail_reason("tofino"
  "Too much data for parse matcher"
  testdata/p4_14_samples/source_routing.p4
  )

# Checksum16 is deprecated
p4c_add_xfail_reason("tofino"
  "Could not find declaration for"
  extensions/p4_tests/p4_16/ipv4_options.p4
  )

p4c_add_xfail_reason("tofino"
  "Expression for parser counter is not supported"
  #   extensions/p4_tests/p4_14/c1/COMPILER-384/case2240.p4
  extensions/p4_tests/p4_14/p4-tests/programs/pctr/pctr.p4
  )

p4c_add_xfail_reason("tofino"
  "error: No format in action table"
  extensions/p4_tests/p4_14/02-FlexCounterActionProfile.p4
  )

p4c_add_xfail_reason("tofino"
  "PHV allocation creates a container action impossible within a Tofino ALU"
  extensions/p4_tests/p4_14/test_config_172_stateful_heavy_hitter.p4
  )

p4c_add_xfail_reason("tofino"
  "In table .*, the number of bytes required to go through the immediate pathway"
  extensions/p4_tests/p4_14/test_config_311_hash_adb.p4
  )

# BRIG-102
p4c_add_xfail_reason("tofino"
  "The following operation is not yet supported"
  extensions/p4_tests/p4_14/test_config_235_funnel_shift.p4
  extensions/p4_tests/p4_14/p4-tests/programs/opcode_test/opcode_test.p4
  )

p4c_add_xfail_reason("tofino"
  "error: tofino supports up to 12 stages"
  extensions/p4_tests/p4_14/p4-tests/programs/clpm/clpm.p4
  extensions/p4_tests/p4_14/p4-tests/programs/fr_test/fr_test.p4
  switch_7.0_l2
  switch_msdc_l3
  )

# BRIG-113
p4c_add_xfail_reason("tofino"
  "Input xbar hash.*conflict in"
  extensions/p4_tests/p4_14/hash_calculation_multiple.p4
  )

p4c_add_xfail_reason("tofino"
# Fail on purpose due to indirect tables not being mutually exclusive
  "Tables .* and .* are not mutually exclusive"
  extensions/p4_tests/p4_14/action_profile_not_shared.p4
  extensions/p4_tests/p4_14/action_profile_next_stage.p4
  testdata/p4_16_samples/action_selector_shared-bmv2.p4
#   extensions/p4_tests/p4_14/c1/COMPILER-235/vag1662.p4
  testdata/p4_14_samples/12-Counters.p4
  testdata/p4_14_samples/13-Counters1and2.p4
  )

p4c_add_xfail_reason("tofino"
  "error: : condition too complex"
  extensions/p4_tests/p4_14/07-MacAddrCheck.p4
  extensions/p4_tests/p4_14/08-MacAddrCheck1.p4
  testdata/p4_14_samples/issue894.p4
  )

p4c_add_xfail_reason("tofino"
  "Unhandled InstanceRef type header_union"
  testdata/p4_16_samples/union-valid-bmv2.p4
  )
# BRIG_132
p4c_add_xfail_reason("tofino"
  "Unhandled InstanceRef type"
  testdata/p4_16_samples/union-bmv2.p4
  testdata/p4_16_samples/union1-bmv2.p4
  testdata/p4_16_samples/union2-bmv2.p4
  testdata/p4_16_samples/union3-bmv2.p4
  testdata/p4_16_samples/union4-bmv2.p4
  testdata/p4_16_samples/verify-bmv2.p4
  )


p4c_add_xfail_reason("tofino"
  "Could not place table : "
  extensions/p4_tests/p4_14/p4-tests/programs/power/power.p4
  )

# p4c_add_xfail_reason("tofino"
#   "error: No format field or table named"
#    extensions/p4_tests/p4_14/c8/COMPILER-616/case3331.p4
#   )

# various stateful
# Signed 1-bit field not allowed in P4_16 (and really makes no sense?)
p4c_add_xfail_reason("tofino"
  "error: int<1>: Signed types cannot be 1-bit wide"
  extensions/p4_tests/p4_14/test_config_160_stateful_single_bit_mode.p4
  )

p4c_add_xfail_reason("tofino"
  "Unrecognized AttribLocal combined_predicate"
  #extensions/p4_tests/p4_14/c1/COMPILER-355/netchain_two.p4
  )

# conflict between blackbox meter and builtin meter
p4c_add_xfail_reason("tofino"
  "P4_14 extern type not fully supported"
  extensions/p4_tests/p4_14/test_config_185_first_lpf.p4
  extensions/p4_tests/p4_14/test_config_201_meter_constant_index.p4
  )

p4c_add_xfail_reason("tofino"
  "" # TIMEOUT -- appears to hang in parser unrolling.
  # FIXME -- how to have an expected timeout?
  #extensions/p4_tests/p4_14/c1/COMPILER-385/case2247.p4
  #extensions/p4_tests/p4_14/c2/COMPILER-392/case2266.p4
  #extensions/p4_tests/p4_14/c2/COMPILER-420/case2433.p4
  #extensions/p4_tests/p4_14/c2/COMPILER-421/case2434.p4
  #extensions/p4_tests/p4_14/c2/COMPILER-426/case2475.p4
  #extensions/p4_tests/p4_14/c2/COMPILER-599/case3230.p4
  )

# COMPILER-540
p4c_add_xfail_reason("tofino"
  "error: : direct access to indirect register"
  extensions/p4_tests/p4_14/test_config_171_stateful_conga.p4
  extensions/p4_tests/p4_14/test_config_173_stateful_bloom_filter.p4
  extensions/p4_tests/p4_14/test_config_174_stateful_flow_learning.p4
  # extensions/p4_tests/p4_14/c1/COMPILER-254/case1744.p4
  # extensions/p4_tests/p4_14/c1/COMPILER-260/case1799.p4
  # extensions/p4_tests/p4_14/c1/COMPILER-260/case1799_1.p4
  # extensions/p4_tests/p4_14/c1/COMPILER-262/case1804.p4
  )

# BRIG-271
p4c_add_xfail_reason("tofino"
  "error: : conditional assignment not supported"
  extensions/p4_tests/p4_14/p4-tests/programs/entry_read_from_hw/entry_read_from_hw.p4
  extensions/p4_tests/p4_14/test_config_219_modify_field_conditionally.p4
  testdata/p4_16_samples/issue232-bmv2.p4
  testdata/p4_16_samples/issue420.p4
  testdata/p4_16_samples/issue512.p4
  extensions/p4_tests/p4_14/p4-tests/programs/mod_field_conditionally/mod_field_conditionally.p4
  )


# BRIG-138
p4c_add_xfail_reason("tofino"
  "error: : action .* appears multiple times in table"
  # extensions/p4_tests/p4_14/c1/COMPILER-447/case2527.p4
  # extensions/p4_tests/p4_14/c1/COMPILER-448/case2526.p4
  # extensions/p4_tests/p4_14/c1/COMPILER-451/case2537.p4
  # extensions/p4_tests/p4_14/c1/COMPILER-477/case2602.p4
  # extensions/p4_tests/p4_14/c1/COMPILER-482/case2622.p4
  # extensions/p4_tests/p4_14/c1/COMPILER-483/case2619.p4
  # extensions/p4_tests/p4_14/c1/COMPILER-503/case2678.p4
  # extensions/p4_tests/p4_14/c1/COMPILER-505/case2690.p4
  # extensions/p4_tests/p4_14/c1/COMPILER-532/case2807.p4
  # extensions/p4_tests/p4_14/c1/COMPILER-548/case3011.p4
  # extensions/p4_tests/p4_14/c1/COMPILER-559/case2987.p4
  # extensions/p4_tests/p4_14/c1/COMPILER-562/case3005.p4
  # extensions/p4_tests/p4_14/c1/COMPILER-567/case2807.p4
  # extensions/p4_tests/p4_14/c1/COMPILER-568/case3026.p4
  # extensions/p4_tests/p4_14/c1/COMPILER-568/case3026dce.p4
  # extensions/p4_tests/p4_14/c1/COMPILER-575/case3041.p4
  # extensions/p4_tests/p4_14/c1/COMPILER-576/case3042.p4
  # extensions/p4_tests/p4_14/c1/COMPILER-577/comp577.p4
  # extensions/p4_tests/p4_14/c1/COMPILER-579/case3085.p4
  # extensions/p4_tests/p4_14/c1/COMPILER-585/comp585.p4
  # extensions/p4_tests/p4_14/c1/COMPILER-588/comp588.p4
  # extensions/p4_tests/p4_14/c1/COMPILER-588/comp588dce.p4
  # extensions/p4_tests/p4_14/c1/COMPILER-589/comp589.p4
  # extensions/p4_tests/p4_14/c1/COMPILER-593/case3011.p4
  # extensions/p4_tests/p4_14/c1/COMPILER-608/case3263.p4
  # extensions/p4_tests/p4_14/c1/COMPILER-632/case3459.p4
  # extensions/p4_tests/p4_14/c1/DRV-543/case2499.p4
  extensions/p4_tests/p4_14/p4-tests/programs/iterator/iterator.p4
  # extensions/p4_tests/p4_14/c1/COMPILER-271/case1834.p4
  # extensions/p4_tests/p4_14/c1/COMPILER-263/case1795.p4
  # extensions/p4_tests/p4_14/c1/COMPILER-264/case1822.p4
  # extensions/p4_tests/p4_14/c1/COMPILER-273/case1832.p4
  # extensions/p4_tests/p4_14/c1/COMPILER-275/case1841.p4
  # extensions/p4_tests/p4_14/c1/COMPILER-276/case1844.p4
  # extensions/p4_tests/p4_14/c1/COMPILER-282/case1864.p4
  )

# p4c_add_xfail_reason("tofino"
#   "Action for .* has some unbound arguments"
#   # requires pragma action_default_only
#   extensions/p4_tests/p4_14/c1/COMPILER-548/case2895.p4
#   )

# # BRIG-243
# p4c_add_xfail_reason("tofino"
#   "conflicting memory use between .* and .*"
#   # This is an ATCAM failure due to a stage split being in the same stage.  Much more subtle
#   extensions/p4_tests/p4_14/c1/COMPILER-494/case2560_min.p4
#   extensions/p4_tests/p4_14/c1/COMPILER-499/case2560_min_2.p4
#   )

# p4c_add_xfail_reason("tofino"
#   "Multiple synth2port require overflow"
#   extensions/p4_tests/p4_14/p4-tests/programs/entry_read_from_hw/entry_read_from_hw.p4
#   )

p4c_add_xfail_reason("tofino"
  "Can't fit table .* in input xbar by itself"
  )

p4c_add_xfail_reason("tofino"
  "Wrong number of arguments for method call"
  testdata/p4_16_samples/checksum1-bmv2.p4
  )

# Specifically to save the error message
p4c_add_xfail_reason("tofino"
  "(throwing|uncaught exception).*Backtrack::trigger"
)

#
p4c_add_xfail_reason("tofino"
  "error: : source of modify_field invalid"
  testdata/p4_16_samples/arith1-bmv2.p4
  testdata/p4_16_samples/arith2-bmv2.p4
  testdata/p4_16_samples/concat-bmv2.p4
  )

p4c_add_xfail_reason("tofino"
  "error: : shift count must be a constant in"
  testdata/p4_16_samples/arith3-bmv2.p4
  testdata/p4_16_samples/arith4-bmv2.p4
  testdata/p4_16_samples/arith5-bmv2.p4
  )

p4c_add_xfail_reason("tofino"
  "Invalid select case expression"
  testdata/p4_16_samples/issue361-bmv2.p4
  )

# This program tries to assign an error value to a metadata field.
p4c_add_xfail_reason("tofino"
  "Couldn't resolve computed value for extract"
  testdata/p4_16_samples/issue510-bmv2.p4
  )

p4c_add_xfail_reason("tofino"
  "Exiting with SIGSEGV"
  # extensions/p4_tests/p4_14/c1/COMPILER-635/case3468.p4
  # extensions/p4_tests/p4_14/c1/COMPILER-637/case3478.p4
  # Same Name Conversion Bug
  extensions/p4_tests/p4_14/shared_names.p4
  )

# new p4lang/p4c tests that fail
p4c_add_xfail_reason("tofino"
    "Failed to transform the program into a P4Runtime-compatible form"
    testdata/p4_16_samples/issue841.p4
    )
p4c_add_xfail_reason("tofino"
    "visitor returned non-MethodCallExpression type"
    testdata/p4_16_samples/issue955.p4
    )
p4c_add_xfail_reason("tofino"
    "No table to place"
    testdata/p4_16_samples/issue986-1-bmv2.p4
    )
p4c_add_xfail_reason("tofino"
    "error: : The hash offset must be a power of 2 in a hash calculation Hash.get"
    testdata/p4_16_samples/issue1049-bmv2.p4
    )

p4c_add_xfail_reason("tofino"
  "Ran out of tcam space in .* parser"
  testdata/p4_14_samples/issue583.p4
  )

p4c_add_xfail_reason("tofino"
  "Tofino does not allow stats to use different address schemes on one table"
  testdata/p4_14_samples/counter.p4
  )

p4c_add_xfail_reason("tofino"
  "Expected type T in digest to be a typeName"
  testdata/p4_16_samples/issue430-1-bmv2.p4
  )

p4c_add_xfail_reason("tofino"
  "warning: : Currently the Barefoot HW compiler cannot handle any non direct assignment instruction that has missized rvalues"
  extensions/p4_tests/p4_16/cast_narrowing_add.p4
  extensions/p4_tests/p4_16/cast_widening_add.p4
  )

p4c_add_xfail_reason("tofino"
  "PHV allocation was not successful"
  testdata/p4_14_samples/05-FullTPHV.p4
  testdata/p4_14_samples/06-FullTPHV1.p4
  testdata/p4_14_samples/08-FullTPHV3.p4
  extensions/p4_tests/p4_14/04-FullPHV3.p4
  extensions/p4_tests/p4_14/test_config_101_switch_msdc.p4
  extensions/p4_tests/p4_16/int_transit.p4

  # Expected to fail, which means that action analysis is working correctly.
  extensions/p4_tests/p4_14/action_conflict_1.p4
  extensions/p4_tests/p4_14/action_conflict_2.p4
  #extensions/p4_tests/p4_14/c4/COMPILER-529/dnets_bng_case1.p4
  #extensions/p4_tests/p4_14/c4/COMPILER-529/dnets_bng_case2.p4
  #extensions/p4_tests/p4_14/c5/COMPILER-594/comp594.p4
  #extensions/p4_tests/p4_14/c3/COMPILER-393/case2277.p4
  #extensions/p4_tests/p4_14/c1/COMPILER-347/switch_bug.p4
  )

# We can't (without some complex acrobatics) support conditional computed
# checksums on Tofino. In P4-14, these are operations of the form:
#   update ipv4_checksum if(ipv4.ihl == 5);
# Glass's Tofino backend rejects these programs as well; they're really designed
# for BMV2.
p4c_add_xfail_reason("tofino"
  "Encountered invalid code in computed checksum control"
  testdata/p4_16_samples/issue134-bmv2.p4
)

# These programs include non-byte-aligned headers, which are not supported on
# Tofino.
# XXX(seth): We're obviously losing some test coverage here; perhaps we should
# adjust some of these tests to not trigger this error?
p4c_add_xfail_reason("tofino"
  "header .* is not byte-aligned"
  testdata/p4_14_samples/14-SplitEthernetVlan.p4
  testdata/p4_14_samples/02-BadSizeField.p4
  testdata/p4_14_samples/14-GatewayGreaterThan.p4
  testdata/p4_16_samples/table-entries-priority-bmv2.p4
  testdata/p4_16_samples/table-entries-valid-bmv2.p4
  testdata/p4_16_samples/inline-stack-bmv2.p4
  testdata/p4_16_samples/table-entries-range-bmv2.p4
  testdata/p4_16_samples/table-entries-lpm-bmv2.p4
  testdata/p4_16_samples/table-entries-exact-bmv2.p4
  testdata/p4_16_samples/table-entries-ternary-bmv2.p4
  testdata/p4_16_samples/table-entries-exact-ternary-bmv2.p4
  testdata/p4_16_samples/issue134-bmv2.p4
)

# error in resolve_computed.cpp
p4c_add_xfail_reason("tofino"
  "Too much data for parse matcher, not enough register"
  testdata/p4_14_samples/parser_value_set2.p4
  )

# Incorrect P4_14->16 conversion for varbit extract
p4c_add_xfail_reason("tofino"
  "Wrong number of arguments for method call: packet.extract"
  testdata/p4_14_samples/09-IPv4OptionsUnparsed.p4
  testdata/p4_14_samples/issue781.p4
  # extensions/p4_tests/p4_14/c2/COMPILER-379/case2210.p4
  )

# Also incorrect P4_14->16 conversion for varbit extract, but a different
# symptom.
p4c_add_xfail_reason("tofino"
  "Cannot find declaration for len"
  testdata/p4_14_samples/TLV_parsing.p4
  )

p4c_add_xfail_reason("tofino"
  "visitor returned non-Statement type"
  testdata/p4_16_samples/issue887.p4
)

p4c_add_xfail_reason("tofino"
  " Encountered invalid code in computed checksum control"
  #extensions/p4_tests/p4_14/switch_l2_profile.p4
)

p4c_add_xfail_reason("tofino"
  "Header present in IR not under Member"
  testdata/p4_16_samples/issue907-bmv2.p4
  testdata/p4_16_samples/issue1210.p4
  )

# BEGIN: XFAILS that match glass XFAILS

# parde physical adjacency constraint violated by mau phv_no_pack constraint
p4c_add_xfail_reason("tofino"
  "Header field .* is required to be allocated contiguously"
  extensions/p4_tests/p4_14/01-FlexCounter.p4
  extensions/p4_tests/p4_14/03-VlanProfile.p4
  extensions/p4_tests/p4_14/19-SimpleTrill.p4
  )

p4c_add_xfail_reason("tofino"
  "Action.* writes fields using the same assignment type but different source operands"
  extensions/p4_tests/p4_14/14-MultipleActionsInAContainer.p4
  )

# p4c_add_xfail_reason("tofino"
#   "Not all applies of table .* are mutually exclusive"
#   extensions/p4_tests/p4_14/c1/COMPILER-100/exclusive_cf_one_action_fail_after.p4
#   extensions/p4_tests/p4_14/c1/COMPILER-100/exclusive_cf_one_action_fail_before.p4
#   )

p4c_add_xfail_reason("tofino"
  "Table .* is applied multiple times, and the next table information cannot correctly propagate"
  # extensions/p4_tests/p4_14/c1/COMPILER-100/exclusive_cf_multiple_actions.p4
  # extensions/p4_tests/p4_14/c1/COMPILER-100/exclusive_cf_fail_next_ptr.p4
  # extensions/p4_tests/p4_14/c1/COMPILER-100/exclusive_cf_one_action.p4
  testdata/p4_14_samples/16-TwoReferences.p4
  # extensions/p4_tests/p4_14/c1/COMPILER-125/16-TwoReferences.p4
  testdata/p4_16_samples/issue986-bmv2.p4
  )

#END: XFAILS that match glass XFAILS

# This code contains an implicit cast in an assignment in the parser; we need to
# convert it into a slice instead of just ignoring the cast.
p4c_add_xfail_reason("tofino"
  "Inferred incompatible alignments for field .*"
  extensions/p4_tests/p4_14/test_config_101_switch_msdc.p4
)

# p4c_add_xfail_reason("tofino"
#   "Due to complexity in action bus, can only currently handle meter color in an 8 bit ALU"
#   extensions/p4_tests/p4_14/c1/COMPILER-353/case2088.p4
#   extensions/p4_tests/p4_14/c1/COMPILER-351/case2079.p4
# )

p4c_add_xfail_reason("tofino"
  "Stage pragma provided to table .* has multiple parameters, while Brig currently"
  extensions/p4_tests/p4_14/test_config_131_placement_with_pragma.p4
  # extensions/p4_tests/p4_14/c1/COMPILER-351/case2079.p4
  # extensions/p4_tests/p4_14/c1/COMPILER-353/case2088.p4
  # extensions/p4_tests/p4_14/c1/COMPILER-364/case2115.p4
)

# START: XFAILs with translation
# We fail to translate `resubmit()`.
p4c_add_xfail_reason("tofino"
  "Could not find declaration for standard_metadata"
  testdata/p4_14_samples/resubmit.p4
  testdata/p4_16_samples/drop-bmv2.p4
  testdata/p4_16_samples/std_meta_inlining.p4
  )
# We fail to translate `standard_metadata.instance_type`.
p4c_add_xfail_reason("tofino"
  "Could not find declaration for standard_metadata"
  # extensions/p4_tests/p4_14/c1/COMPILER-559/case2987.p4
  testdata/p4_14_samples/copy_to_cpu.p4
  testdata/p4_14_samples/packet_redirect.p4
  testdata/p4_14_samples/simple_nat.p4
  )
# We fail to translate `generate_digest()`.
p4c_add_xfail_reason("tofino"
  "Could not find declaration for standard_metadata"
  testdata/p4_14_samples/issue1058.p4
  )
# invalid tests, eg_intr_md.egress_port is read-only
p4c_add_xfail_reason("tofino"
  "Expression .* cannot be the target of an assignment"
  extensions/p4_tests/p4_14/test_config_249_simple_bridge.p4
  extensions/p4_tests/p4_14/test_config_6_sram_and_tcam_allocation.p4
  )
# invalid tests, issue604.p4 is a v1.1 testcase
# P4-14 program can not define extern
p4c_add_xfail_reason("tofino"
  "P4_14 extern not fully supported"
  testdata/p4_14_samples/issue604.p4
  )
# are we going to retire these switch profiles?
p4c_add_xfail_reason("tofino"
  "Structure header .* does not have a field"
  testdata/p4_14_samples/sai_p4.p4
  )

# # BRIG-109
# p4c_add_xfail_reason("tofino"
#   "resolve computed"
#   extensions/p4_tests/p4_14/c1/COMPILER-217/port_parser.p4
#   )

p4c_add_xfail_reason("tofino"
  "Only compile-time constants are supported for hash base offset and max value"
  testdata/p4_14_samples/flowlet_switching.p4
  testdata/p4_16_samples/flowlet_switching-bmv2.p4
  )

# ingress parser need access pkt_length
p4c_add_xfail_reason("tofino"
  "error: standard_metadata.packet_length is not accessible in the ingress pipe"
  testdata/p4_14_samples/queueing.p4
  )
# resubmit size is 32 bytes which exceeds max size for tofino (8 bytes).
p4c_add_xfail_reason("tofino"
  "error: resubmit digest limited to 8 bytes"
  extensions/p4_tests/p4_14/13-ResubmitMetadataSize.p4
  extensions/p4_tests/p4_14/p4-tests/programs/mau_test/mau_test.p4
  )

# translation bug: smeta
p4c_add_xfail_reason("tofino"
  "Could not find declaration for smeta"
  testdata/p4_16_samples/issue677-bmv2.p4
  )

# missing support in backend: parser counter
# parser counter translation error.
p4c_add_xfail_reason("tofino"
  "warning: can't find field 'ig_prsr_ctrl_parser_counter.get'"
  extensions/p4_tests/p4_14/test_config_294_parser_loop.p4
  )
p4c_add_xfail_reason("tofino"
  "does not have a PHV allocation though it is used in an action"
  )

p4c_add_xfail_reason("tofino"
  "Could not find declaration for x"
  testdata/p4_16_samples/issue1001-bmv2.p4
  )

# END: XFAILs with translation

p4c_add_xfail_reason("tofino"
  "error: : No size count in action"
  extensions/p4_tests/p4_14/p4-tests/programs/ecc/ecc.p4
  )

# XXX(cole): Temporarily override previous XFAILs with new failures related to
# PHV allocation.
p4c_add_xfail_reason("tofino"
  "PHV allocation was not successful"
  extensions/p4_tests/p4_14/03-VlanProfile.p4
  extensions/p4_tests/p4_14/19-SimpleTrill.p4
  extensions/p4_tests/p4_14/01-FlexCounter.p4
  # extensions/p4_tests/p4_14/c1/COMPILER-129/compiler129.p4
  )

# BRIG-219
p4c_add_xfail_reason("tofino"
  "PHV allocation creates a container action impossible within a Tofino ALU"
  # extensions/p4_tests/p4_14/14-MultipleActionsInAContainer.p4
  # extensions/p4_tests/p4_14/test_config_184_stateful_bug1.p4
  # extensions/p4_tests/p4_14/test_config_190_modify_with_expr.p4
  # extensions/p4_tests/p4_14/c1/COMPILER-235/case1737.p4
  # extensions/p4_tests/p4_14/c7/COMPILER-623/case3375.p4
  # extensions/p4_tests/p4_14/c1/COMPILER-415/case2386.p4
  # extensions/p4_tests/p4_14/c1/COMPILER-414/case2387_1.p4
  # extensions/p4_tests/p4_14/c1/COMPILER-437/case2387_1.p4
  # extensions/p4_tests/p4_14/c1/COMPILER-414/case2387.p4

  # Instruction adjustment needs to synthesize a bitmasked-set but does not.
  # extensions/p4_tests/p4_14/c1/COMPILER-235/case1737_1.p4
  # extensions/p4_tests/p4_14/test_config_50_action_data_different_size_fields.p4

  # Action analysis failures.
  # extensions/p4_tests/p4_14/test_config_252_pa_required_packing.p4
  # extensions/p4_tests/p4_14/test_config_256_pa_problem_4.p4
  # extensions/p4_tests/p4_14/c1/COMPILER-235/case1737.p4
  # extensions/p4_tests/p4_14/c1/COMPILER-235/case1737_1.p4
  # extensions/p4_tests/p4_14/c1/COMPILER-357/case2100.p4
  # extensions/p4_tests/p4_14/c1/COMPILER-358/case2110.p4
  # extensions/p4_tests/p4_14/p4-tests/programs/stful/stful.p4
  )


# BRIG-426, and maybe BRIG-421
p4c_add_xfail_reason("tofino"
  "No phv record"
  extensions/p4_tests/p4_14/action_conflict_3.p4
  )

# p4c_add_xfail_reason("tofino"
#   "Brig currently only supports one parameter"
#   extensions/p4_tests/p4_14/c1/COMPILER-415/case2386.p4
#   extensions/p4_tests/p4_14/c1/COMPILER-414/case2387_1.p4
#   extensions/p4_tests/p4_14/c1/COMPILER-437/case2387_1.p4
#   extensions/p4_tests/p4_14/c1/COMPILER-414/case2387.p4
#   extensions/p4_tests/p4_14/c1/COMPILER-326/case2035.p4
#   )


p4c_add_xfail_reason("tofino"
  "Operands of arithmetic operations cannot be greater than 32b, but field .* has .*"
  extensions/p4_tests/p4_14/test_config_296_pragma_container.p4
  extensions/p4_tests/p4_14/test_config_258_wide_add.p4
  testdata/p4_16_samples/arith-bmv2.p4
  )

p4c_add_xfail_reason("tofino"
  "warning: .* may be uninitialized"
  # extensions/p4_tests/p4_14/c1/COMPILER-217/port_parser.p4
  extensions/p4_tests/p4_14/p4-tests/programs/parser_intr_md/parser_intr_md.p4
  )

p4c_add_xfail_reason("tofino"
  "invalid exact key expression"
  # This test attempts to match on a field of `error` type.
  testdata/p4_16_samples/issue1062-bmv2.p4
  )

p4c_add_xfail_reason("tofino"
  "header hdr is not byte-aligned"
  testdata/p4_16_samples/issue1062-1-bmv2.p4
  )

p4c_add_xfail_reason("tofino"
  "Instruction selection creates an instruction that the rest of the compiler cannot correctly interpret"
  testdata/p4_16_samples/issue983-bmv2.p4
  )

p4c_add_xfail_reason("tofino"
  "the packing is too complicated .* speciality action data combined with other action data"
  extensions/p4_tests/p4_14/test_config_96_hash_data.p4
  extensions/p4_tests/p4_14/test_config_157_random_number_generator.p4
  extensions/p4_tests/p4_14/test_config_295_polynomial_hash.p4
  extensions/p4_tests/p4_14/test_config_205_modify_field_from_hash.p4
  testdata/p4_14_samples/meter1.p4
  testdata/p4_16_samples/named_meter_1-bmv2.p4
  testdata/p4_16_samples/named_meter_bmv2.p4
  testdata/p4_14_samples/issue894.p4
  testdata/p4_14_samples/meter.p4
  testdata/p4_14_samples/meter.p4
  extensions/p4_tests/p4_14/hash_calculation_max_size.p4
  extensions/p4_tests/p4_14/p4-tests/programs/hash_test/hash_test.p4
  )

# missing support for random in extract_maupipe
p4c_add_xfail_reason("tofino"
  "source of modify_field invalid"
  # extensions/p4_tests/p4_14/c1/COMPILER-129/compiler129.p4
  )

#-------- New tests, new failures
p4c_add_xfail_reason("tofino"
  "multiple calls to execute in action"
  extensions/p4_tests/p4_14/test_config_313_neg_test_addr_modes.p4
  extensions/p4_tests/p4_14/p4-tests/programs/pgrs/pgrs.p4
  )

p4c_add_xfail_reason("tofino"
  "error: Expression .* cannot be the target of an assignment"
  testdata/p4_16_samples/issue1079-bmv2.p4
  )

# dynamic hash
p4c_add_xfail_reason("tofino"
  "Unknown method execute_from_hash in wred"
  extensions/p4_tests/p4_14/p4-tests/programs/dyn_hash/dyn_hash.p4
  )

# shared register between ingress and egress is not supported
p4c_add_xfail_reason("tofino"
  "error: Could not find declaration for r"
  testdata/p4_16_samples/issue1097-2-bmv2.p4
  )

# # BRIG-372
# p4c_add_xfail_reason("tofino"
#   "error: Could not find declaration for key_1"
#   extensions/p4_tests/p4_14/c1/BRIG-372/case4346.p4
#   )

# BRIG-400
p4c_add_xfail_reason("tofino"
  "non-header in *"
  testdata/p4_16_samples/issue1127-bmv2.p4
  )

p4c_add_xfail_reason("tofino"
  "Currently in p4c, the table .* cannot perform a range match on key .* as the key does not fit in under 5 PHV nibbles"
  extensions/p4_tests/p4_14/test_config_324_tcam_range_11.p4
  )

# BRIG-435
p4c_add_xfail_reason("tofino"
  "unexpected reads expression"
  testdata/p4_16_samples/issue486-bmv2.p4
  )

# This test is expected to fail (for now) because it includes multiple writes
# to the same field in the same action.  However, in this case the sources are
# constants, which could theoretically be merged into one write by the
# compiler.
#p4c_add_xfail_reason("tofino"
#  "Field .* written to more than once in action .*"
#  testdata/p4_16_samples/slice-def-use1.p4
#  )

p4c_add_xfail_reason("tofino"
  "error: Can't find .* on the input xbar"
  #extensions/p4_tests/p4_14/c1/COMPILER-352/netchain_one.p4
  )

p4c_add_xfail_reason("tofino"
  "Trying to accumulate too many fields in CCGF"
  #extensions/p4_tests/p4_14/c2/COMPILER-401/case2308_bugged.p4
  )

# Should fail because meaningless invalidate operand.
p4c_add_xfail_reason("tofino"
  "invalid operand"
  extensions/p4_tests/p4_14/test_config_191_invalidate.p4
)

p4c_add_xfail_reason("tofino"
  "PHV allocation was not successful"
  switch_7.0_dc_basic
  switch_7.0_l2
  smoketest_programs_netcache
)

p4c_add_xfail_reason("tofino"
  "Unimplemented compiler support.*: metadata arrays not handled"
  testdata/p4_16_samples/header-stack-ops-bmv2.p4
)

# Flaky.
p4c_add_xfail_reason("tofino"
  "Currently non contiguous byte allocation in table format"
  # extensions/p4_tests/p4_14/test_config_215_nondphv.p4
)

p4c_add_xfail_reason("tofino"
  "expected packet on port .* not seen"
  testdata/p4_14_samples/action_chain1.p4
)

p4c_add_xfail_reason("tofino"
  "Identifier with no name"
  testdata/p4_16_samples/issue1208-1.p4
)

p4c_add_xfail_reason("tofino"
  "source of modify_field invalid"
  testdata/p4_16_samples/saturated-bmv2.p4
)

p4c_add_xfail_reason("tofino"
  "condition expression too complex"
  testdata/p4_14_samples/header-stack-ops-bmv2.p4
)

p4c_add_xfail_reason("tofino"
  "Compiler Bug.*: Type_Name is not a canonical type"
  testdata/p4_16_samples/pvs-nested-struct.p4
  testdata/p4_16_samples/pvs-struct.p4
)

# p4smith and p4testgen regression XFAILs

# BRIG-647
p4c_add_xfail_reason("tofino"
  "Fields involved in the same MAU operations have conflicting PARDE alignment requirements"
  extensions/p4_tests/p4_14/p4smith_regression/grab_0.p4
)

# BRIG-650
p4c_add_xfail_reason("tofino"
  "error: constant value .* out of range for immediate"
  extensions/p4_tests/p4_14/p4smith_regression/surnames_0.p4
)

# BRIG-651
p4c_add_xfail_reason("tofino"
  "PHV read has no allocation"
  extensions/p4_tests/p4_14/p4smith_regression/clue_0.p4
)

# BRIG-652
p4c_add_xfail_reason("tofino"
  "condition too complex, one operand must be constant"
  extensions/p4_tests/p4_14/p4smith_regression/injection_0.p4
)

# BRIG-653
p4c_add_xfail_reason("tofino"
  "No casts should ever reach this point in the Tofino backend"
  extensions/p4_tests/p4_14/p4smith_regression/murdoch_0.p4
)

# BRIG-654
p4c_add_xfail_reason("tofino"
  "Two containers in the same action are at the same place?"
  extensions/p4_tests/p4_14/p4smith_regression/selenium_0.p4
)

# https://github.com/barefootnetworks/p4v/issues/362
p4c_add_xfail_reason("tofino"
  "AssertionError: Expected packet was not received on device"
  p4testgen_laymen_0
)

# BRIG-677
# error: MAU::TableSeq: duplicated name (MAU::TableSeq is previous instance)
p4c_add_xfail_reason("tofino"
  "duplicated name"
  extensions/p4_tests/p4_14/p4smith_regression/basseterre_0.p4
)

# BRIG-678
p4c_add_xfail_reason("tofino"
  "Split cannot work on this scenario"
  extensions/p4_tests/p4_14/p4smith_regression/underpin_0.p4
)

# BRIG-648
p4c_add_xfail_reason("tofino"
  "Unhandled expression in BuildGatewayMatch"
  extensions/p4_tests/p4_14/p4smith_regression/drunkards_0.p4
)

# BRIG-682
p4c_add_xfail_reason("tofino"
  "Some fields cannot be allocated because of unsatisfiable constraints"
  extensions/p4_tests/p4_14/p4smith_regression/photostats_0.p4
)

# BRIG-679
# error: Gateway match key chubs.dr not in matching hash column
p4c_add_xfail_reason("tofino"
  "not in matching hash column"
  extensions/p4_tests/p4_14/p4smith_regression/vindemiatrixs_0.p4
)

# BRIG-680
# Compiler Bug: sidestepped_0.p4(95): RangeMatch source (ingress::discontinuitys.soupcons[7:4];) misaligned at 34..34
p4c_add_xfail_reason("tofino"
  "RangeMatch source"
  extensions/p4_tests/p4_14/p4smith_regression/sidestepped_0.p4
)

# BRIG-683
# error: Upper word match of tracker.medicos for range gateway not a multiple of 4 bits
p4c_add_xfail_reason("tofino"
  "for range gateway not a multiple of 4 bits"
  extensions/p4_tests/p4_14/p4smith_regression/motowns_0.p4
)

# BRIG-684
# error: hash expression width mismatch (2 != 1)
p4c_add_xfail_reason("tofino"
  "hash expression width mismatch"
  extensions/p4_tests/p4_14/p4smith_regression/ghosted_0.p4
)

# BRIG-681
p4c_add_xfail_reason("tofino"
  "AssertionError: Expected packet was not received on device"
  p4testgen_faecess_0
)

# BRIG-691
p4c_add_xfail_reason("tofino"
  "TTransportException: TSocket read 0 bytes"
  p4testgen_signets_0
)

# BRIG-584
p4c_add_xfail_reason("tofino"
  "Unimplemented compiler support.*: Cannot extract to a field slice in the parser"
  extensions/p4_tests/p4_16/extract_slice.p4
)

# BRIG-673
p4c_add_xfail_reason("tofino"
  "no definitions"
  extensions/p4_tests/p4_14/p4-tests/programs/pvs/pvs.p4
)

# 05/31/2018: Need to update p4c refpoint to take commit 8319d32, The update is
# currently blocked by a P4Runtime PR that Antonin's working on. Once the
# P4Runtime PR is in and p4c refpoint is updated. this xfail can then be
# removed.
p4c_add_xfail_reason("tofino"
  "Exiting with SIGSEGV"
  easy-ternary-archive
  tor-archive
)
