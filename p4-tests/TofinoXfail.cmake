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
  # default drop packet instead of writing to port 0
  testdata/p4_16_samples/issue635-bmv2.p4
  testdata/p4_16_samples/issue655-bmv2.p4
  )

  p4c_add_xfail_reason("tofino"
    "mismatch from expected(.*) at byte .*"
    # Needs stateful init regs support in simple test harness, this test passes
    # on stf2ptf
    extensions/p4_tests/p4_14/stateful_init_regs.p4
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
    "AssertionError"
    extensions/p4_tests/p4_14/p4-tests/programs/perf_test_alpm/perf_test_alpm.p4
    )

  p4c_add_xfail_reason("tofino"
    "AssertionError: Expected packet was not received on device"
    05-simple_l3_arping
    extensions/p4_tests/p4_16/ingress_checksum.p4    #TODO(zma) use @calculated_field_update_location to force ingress update
    basic_switching
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

p4c_add_xfail_reason("tofino"
  "Attached object .* in table .* is executed in some actions and not executed in others"
  testdata/p4_16_samples/named_meter_1-bmv2.p4
  testdata/p4_16_samples/issue364-bmv2.p4
  testdata/p4_16_samples/named_meter_bmv2.p4
  testdata/p4_16_samples/unused-counter-bmv2.p4
  )

# BRIG-104
#p4c_add_xfail_reason("tofino"
#  "Unhandled action bitmask constraint"
#  extensions/p4_tests/p4_14/13-IngressEgressConflict.p4
#  )

# Fails due to complex expressions in the parser that our hardware can't support.
p4c_add_xfail_reason("tofino"
  "error: Assignment cannot be supported in the parser"
  testdata/p4_14_samples/axon.p4
  testdata/p4_16_samples/array-copy-bmv2.p4
  testdata/p4_16_samples/issue281.p4
  testdata/p4_16_samples/issue737-bmv2.p4
  testdata/p4_16_samples/stack_complex-bmv2.p4
  )
p4c_add_xfail_reason("tofino"
  "Compiler Bug.*: Match register not allocated."
  testdata/p4_16_samples/issue1409-bmv2.p4
  extensions/p4_tests/p4_14/test_config_294_parser_loop.p4
  )

p4c_add_xfail_reason("tofino"
  "Local metadata array .* not supported"
  testdata/p4_16_samples/equality-bmv2.p4
  )

p4c_add_xfail_reason("tofino"
  "error: Field .* of header .* cannot have type header"
  testdata/p4_16_samples/subparser-with-header-stack-bmv2.p4
  )

p4c_add_xfail_reason("tofino"
  "error: Could not find declaration for action_.*"
  testdata/p4_16_samples/action_profile-bmv2.p4
  testdata/p4_16_samples/issue297-bmv2.p4
  )

p4c_add_xfail_reason("tofino"
  "Action profile .* does not have any action data"
  testdata/p4_14_samples/selector0.p4
  extensions/p4_tests/p4_14/bf_p4c_samples/port_vlan_mapping.p4
  extensions/p4_tests/p4_14/02-FlexCounterActionProfile.p4
  testdata/p4_14_samples/const_default_action.p4
  extensions/p4_tests/p4_14/p4smith_regression/tofino-bug-2.p4
  testdata/p4_16_samples/action_selector_shared-bmv2.p4
  )


# BRIG-956, parser wide match
p4c_add_xfail_reason("tofino"
  "Ran out of parser match registers"
  testdata/p4_16_samples/issue995-bmv2.p4
  testdata/p4_14_samples/source_routing.p4
  testdata/p4_14_samples/parser_value_set2.p4
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
  "Unsupported type varbit"
  testdata/p4_16_samples/issue447-5-bmv2.p4
  )

# Checksum16 is deprecated
p4c_add_xfail_reason("tofino"
  "Could not find declaration for"
  extensions/p4_tests/p4_16/ipv4_options.p4
  )

#p4c_add_xfail_reason("tofino"
#  "Expression for parser counter is not supported"
  #   extensions/p4_tests/p4_14/c1/COMPILER-384/case2240.p4
  # extensions/p4_tests/p4_14/p4-tests/programs/pctr/pctr.p4 # update path when test is added
#  )


p4c_add_xfail_reason("tofino"
  "Unimplemented compiler support.*Cannot allocate >4 immediate bytes for logical table"
  extensions/p4_tests/p4_14/test_config_205_modify_field_from_hash.p4
  switch_msdc_l3
  switch_8.5_msdc_l3
  )

p4c_add_xfail_reason("tofino"
  "error.*To fit hash destinations in less than 4 immediate bytes"
  extensions/p4_tests/p4_14/test_config_311_hash_adb.p4
  )

# BRIG-102
p4c_add_xfail_reason("tofino"
  "The following operation is not yet supported"
  extensions/p4_tests/p4_14/test_config_235_funnel_shift.p4
  extensions/p4_tests/p4_14/p4-tests/programs/opcode_test/opcode_test.p4
  )

p4c_add_xfail_reason("tofino"
  "error.*tofino supports up to 12 stages"
  extensions/p4_tests/p4_14/p4-tests/programs/fr_test/fr_test.p4
  switch_8.5_msdc_ipv4
  switch_msdc_ipv4
  )

p4c_add_xfail_reason("tofino"
  "error.*Can't split table.*with indirect attached MAU::StatefulAlu"
  switch_8.5_ent_fin_postcard
  switch_8.5_l3_heavy_int_leaf
  switch_ent_fin_postcard
  switch_l3_heavy_int_leaf
  switch_generic_int_leaf
)

p4c_add_xfail_reason("tofino"
  "No way to slice the following to satisfy @pa_container_size"
  switch_8.5_generic_int_leaf
  )

p4c_add_xfail_reason("tofino"
  "Compiler Bug.*Conflicting alloc in the action data xbar between.*"
  switch_8.5_msdc_leaf_int
  switch_8.5_l3_heavy_int_leaf
  switch_msdc_leaf_int
  )

p4c_add_xfail_reason("tofino"
  "error: The stage specified for .* could not place it until stage"
  smoketest_programs_netcache
  extensions/p4_tests/p4_14/p4-tests/programs/ecc/ecc.p4
  extensions/p4_tests/p4_14/p4-tests/programs/mau_test/mau_test.p4  #P4C-1123
  )

p4c_add_xfail_reason("tofino"
  "error.*Power worst case estimated budget exceeded by*"
  #extensions/p4_tests/p4_14/p4-tests/programs/clpm/clpm.p4 # update path when test is added
  )

# switch_spine_dtel_int and switch_l3_heavy_spine test failures
p4c_add_xfail_reason("tofino"
  "Received packet did not match expected packet"
  smoketest_switch_8.5_spine_dtel_int_set_2_INTL45_Transit_IngressMoDTest
  smoketest_switch_8.5_spine_dtel_int_set_2_MirrorOnDropHostifReasonCodeTest
  smoketest_switch_8.5_spine_dtel_int_set_2_MirrorOnDropIngressAclTest
  smoketest_switch_8.5_spine_dtel_int_set_2_MirrorOnDropNonDefaultRuleTest
  smoketest_switch_8.5_spine_dtel_int_set_2_QueueReport_Entropy_Test
  smoketest_switch_8.5_spine_dtel_int_set_2_QueueReport_Quota_Test
  smoketest_switch_8.5_spine_dtel_int_set_2_intl45_transitTest_hop2_stateless
  smoketest_switch_8.5_spine_dtel_int_set_2_INTL45_Transit_EgressMoDTest
  smoketest_switch_8.5_spine_dtel_int_set_2_MirrorOnDropEgrNonDefaultRuleTest
  smoketest_switch_8.5_spine_dtel_int_set_5_INGRESS_DROP_REPORT_Test
  smoketest_switch_marker_spine_dtel_intl45_transitTest_hop2_with_digest
  smoketest_switch_marker_spine_dtel_intl45_transitTest_hop2_qdepth
  smoketest_switch_marker_spine_dtel_intl45_transitTest_Metadata
  smoketest_switch_marker_spine_dtel_QueueReport_Entropy_Test
  smoketest_switch_marker_spine_dtel_QueueReport_Quota_Test
  smoketest_switch_marker_spine_dtel_MirrorOnDropHostifReasonCodeTest
  smoketest_switch_marker_spine_dtel_MirrorOnDropIngressAclTest
  smoketest_switch_marker_spine_dtel_MirrorOnDropNonDefaultRuleTest
  smoketest_switch_marker_spine_dtel_INTL45_Transit_IngressMoDTest
  smoketest_switch_marker_spine_dtel_MirrorOnDropEgressAclTest
  smoketest_switch_marker_spine_dtel_MirrorOnDropEgrNonDefaultRuleTest
  smoketest_switch_dtel_int_spine_dtel_INTL45_Transit_IngressMoDTest
  smoketest_switch_dtel_int_spine_dtel_QueueReport_Entropy_Test
  smoketest_switch_dtel_int_spine_dtel_QueueReport_Quota_Test
  smoketest_switch_dtel_int_spine_dtel_MirrorOnDropHostifReasonCodeTest
  smoketest_switch_dtel_int_spine_dtel_MirrorOnDropIngressAclTest
  smoketest_switch_dtel_int_spine_dtel_MirrorOnDropNonDefaultRuleTest
  smoketest_switch_dtel_int_spine_dtel_MirrorOnDropEgressAclTest
  smoketest_switch_dtel_int_spine_dtel_intl45_transitTest_hop2_stateless
  smoketest_switch_dtel_int_spine_dtel_INTL45_Transit_EgressMoDTest
  smoketest_switch_dtel_int_spine_dtel_MirrorOnDropEgrNonDefaultRuleTest
  smoketest_switch_dtel_int_spine_dtel_sai_INGRESS_DROP_REPORT_Test
  )

p4c_add_xfail_reason("tofino"
  "Did not receive pkt on 2"
  smoketest_switch_8.5_spine_dtel_int_set_3_INTL45_Transit_DoDTest
  smoketest_switch_8.5_spine_dtel_int_set_3_MirrorOnDropDoDTest
  smoketest_switch_8.5_spine_dtel_int_set_3_QueueReport_DoD_Test
  smoketest_switch_l3_heavy_spine_dtel_INTL45_Transit_DoDTest
  smoketest_switch_l3_heavy_spine_dtel_MirrorOnDropDoDTest
  smoketest_switch_l3_heavy_spine_dtel_QueueReport_DoD_Test
  smoketest_switch_l3_heavy_spine_dtel_MirrorOnDropEgressAclTest
  smoketest_switch_marker_spine_dtel_QueueReport_DoD_Test
  smoketest_switch_marker_spine_dtel_MirrorOnDropDoDTest
  smoketest_switch_marker_spine_dtel_INTL45_Transit_DoDTest
  smoketest_switch_dtel_int_spine_dtel_INTL45_Transit_DoDTest
  smoketest_switch_dtel_int_spine_dtel_QueueReport_DoD_Test
  smoketest_switch_dtel_int_spine_dtel_MirrorOnDropDoDTest
  )

p4c_add_xfail_reason("tofino"
  "Did not receive expected pkt*"
  smoketest_switch_8.5_spine_dtel_int_set_2_QueueReport_Over_ECMP_Test
  smoketest_switch_8.5_spine_dtel_int_set_2_QueueReport_MirrorTest
  smoketest_switch_8.5_spine_dtel_int_set_2_QueueReport_L2_MirrorTest
  smoketest_switch_marker_spine_dtel_QueueReport_Over_ECMP_Test
  smoketest_switch_marker_spine_dtel_QueueReport_MirrorTest
  smoketest_switch_marker_spine_dtel_QueueReport_L2_MirrorTest
  smoketest_switch_dtel_int_spine_dtel_QueueReport_Over_ECMP_Test
  smoketest_switch_dtel_int_spine_dtel_QueueReport_MirrorTest
  smoketest_switch_dtel_int_spine_dtel_QueueReport_L2_MirrorTest
  )

p4c_add_xfail_reason("tofino"
  "Expected packet was not received on device"
  smoketest_switch_l3_heavy_spine_dtel_intl45_transitTest_CHECKSUM
  smoketest_switch_marker_spine_HostIfPtpTest
  smoketest_switch_marker_spine_dtel_intl45_transitTest_Ebit
  smoketest_switch_marker_spine_dtel_INTL45_TransitTest_Enable
  smoketest_switch_marker_spine_dtel_intl45_transitTest_hop2_port_ids
  smoketest_switch_marker_spine_dtel_intl45_transitTest_switchid
  smoketest_switch_marker_spine_dtel_intl45_transitTest_CHECKSUM
  smoketest_switch_marker_spine_dtel_intl45_transitTest_hop2_stateless
  smoketest_switch_marker_spine_dtel_intl45_DSCP_TransitTest
  )

p4c_add_xfail_reason("tofino"
  "A packet was received on device"
  smoketest_switch_marker_spine_L2StpEgressBlockingTest
  )

p4c_add_xfail_reason("tofino"
  "Received packet that we expected not to receive on device"
  smoketest_switch_marker_spine_L2StpTest
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
#   extensions/p4_tests/p4_14/c1/COMPILER-235/vag1662.p4
  testdata/p4_14_samples/12-Counters.p4
  testdata/p4_14_samples/13-Counters1and2.p4
  )

p4c_add_xfail_reason("tofino"
  "error: : condition too complex"
  extensions/p4_tests/p4_14/07-MacAddrCheck.p4
  extensions/p4_tests/p4_14/08-MacAddrCheck1.p4
  extensions/p4_tests/p4_14/p4smith_regression/kindlings_0.p4
  testdata/p4_16_samples/issue1544-bmv2.p4
  )

# BRIG_132
p4c_add_xfail_reason("tofino"
  "Unsupported type header_union"
  testdata/p4_16_samples/union-bmv2.p4
  testdata/p4_16_samples/union-valid-bmv2.p4
  testdata/p4_16_samples/union1-bmv2.p4
  testdata/p4_16_samples/union2-bmv2.p4
  testdata/p4_16_samples/union3-bmv2.p4
  testdata/p4_16_samples/union4-bmv2.p4
  testdata/p4_16_samples/bvec_union-bmv2.p4
  )

p4c_add_xfail_reason("tofino"
  "Unexpected method call in parser"
  testdata/p4_16_samples/verify-bmv2.p4
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
  "error: calling indirect .* with no index"
  extensions/p4_tests/p4_14/test_config_160_stateful_single_bit_mode.p4
  extensions/p4_tests/p4_14/test_config_170_stateful_selection_table_update.p4
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
  testdata/p4_16_samples/issue420.p4
  testdata/p4_16_samples/issue512.p4
  testdata/p4_16_samples/issue1412-bmv2.p4
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
  # extensions/p4_tests/p4_14/c1/COMPILER-271/case1834.p4
  # extensions/p4_tests/p4_14/c1/COMPILER-263/case1795.p4
  # extensions/p4_tests/p4_14/c1/COMPILER-264/case1822.p4
  # extensions/p4_tests/p4_14/c1/COMPILER-273/case1832.p4
  # extensions/p4_tests/p4_14/c1/COMPILER-275/case1841.p4
  # extensions/p4_tests/p4_14/c1/COMPILER-276/case1844.p4
  # extensions/p4_tests/p4_14/c1/COMPILER-282/case1864.p4
  )

p4c_add_xfail_reason("tofino"
  "The meter .* requires either an idletime or stats address bus"
  testdata/p4_14_samples/hash_action_two_same.p4
)

p4c_add_xfail_reason("tofino"
  "This action requires hash, which can only be done through the hit pathway"
  testdata/p4_14_samples/acl1.p4
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
  extensions/p4_tests/p4_16/serializer.p4
  )

p4c_add_xfail_reason("tofino"
  "expected a method call"
  testdata/p4_16_samples/issue1538.p4
  )

p4c_add_xfail_reason("tofino"
  "Static entries are not supported for lpm-match"
  testdata/p4_16_samples/table-entries-lpm-bmv2.p4
  )

p4c_add_xfail_reason("tofino"
  "error: : An attached table can only be executed once per action"
  testdata/p4_16_samples/issue1566-bmv2.p4
  )

p4c_add_xfail_reason("tofino"
  "error: constant value .* out of range for immediate"
  extensions/p4_tests/p4_14/p4smith_regression/blatz_0.p4
  )

# Specifically to save the error message
p4c_add_xfail_reason("tofino"
  "(throwing|uncaught exception).*Backtrack::trigger"
)

#
p4c_add_xfail_reason("tofino"
  "source of modify_field invalid"
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

# This program tries to assign an error value to a metadata field.
p4c_add_xfail_reason("tofino"
  "error: metadata field of type error not supported on tofino"
  testdata/p4_16_samples/issue510-bmv2.p4
  )

p4c_add_xfail_reason("tofino"
  "Exiting with SIGSEGV"
  # extensions/p4_tests/p4_14/c1/COMPILER-635/case3468.p4
  # extensions/p4_tests/p4_14/c1/COMPILER-637/case3478.p4
  # Same Name Conversion Bug
  extensions/p4_tests/p4_14/shared_names.p4
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
  "Both .* require the .* address hardware, and cannot be on the same table"
  testdata/p4_14_samples/counter.p4
  testdata/p4_16_samples/psa-counter2.p4
)

p4c_add_xfail_reason("tofino"
  "Expected type T in digest to be a typeName"
  testdata/p4_16_samples/issue430-1-bmv2.p4
  )

p4c_add_xfail_reason("tofino"
  "warning: : Currently the Barefoot HW compiler cannot handle any non direct assignment instruction that has missized rvalues"
  extensions/p4_tests/p4_16/cast_widening_add.p4
  )

p4c_add_xfail_reason("tofino"
  "PHV allocation was not successful"
  testdata/p4_14_samples/05-FullTPHV.p4
  testdata/p4_14_samples/06-FullTPHV1.p4
  testdata/p4_14_samples/08-FullTPHV3.p4
  extensions/p4_tests/p4_14/04-FullPHV3.p4
  extensions/p4_tests/p4_14/test_config_101_switch_msdc.p4

  # Expected to fail, which means that action analysis is working correctly.
  extensions/p4_tests/p4_14/action_conflict_2.p4
  extensions/p4_tests/p4_14/action_conflict_3.p4
  extensions/p4_tests/p4_14/14-MultipleActionsInAContainer.p4

  # Expected to fail, until we have better user-facing messages.
  extensions/p4_tests/p4_14/p4smith_regression/mariano_0.p4
  extensions/p4_tests/p4_14/p4smith_regression/soured_0.p4

  # Expected to fail, which means that constraint conflicts are being correctly detected.
  extensions/p4_tests/p4_14/mau_test_neg_test.p4
  #extensions/p4_tests/p4_14/c4/COMPILER-529/dnets_bng_case1.p4
  #extensions/p4_tests/p4_14/c4/COMPILER-529/dnets_bng_case2.p4
  #extensions/p4_tests/p4_14/c5/COMPILER-594/comp594.p4
  #extensions/p4_tests/p4_14/c3/COMPILER-393/case2277.p4
  #extensions/p4_tests/p4_14/c1/COMPILER-347/switch_bug.p4
  )

# Errors because pa_container_size pragmas used in these tests cannot be satisfy all constraints.
p4c_add_xfail_reason("tofino"
  "No way to slice the following to satisfy @pa_container_size"
  extensions/p4_tests/p4_14/test_config_593_reduce_extraction_bandwidth_32.p4
  extensions/p4_tests/p4_14/test_config_227_set_meta_packing.p4
  extensions/p4_tests/p4_14/test_config_262_req_packing.p4
  extensions/p4_tests/p4_14/test_config_275_match_key_range.p4
  extensions/p4_tests/p4_14/c1/COMPILER-954/case5730.p4
  )


# We can't (without some complex acrobatics) support conditional computed
# checksums on Tofino. In P4-14, these are operations of the form:
#   update ipv4_checksum if(ipv4.ihl == 5);
# Glass's Tofino backend rejects these programs as well; they're really designed
# for BMV2.
p4c_add_xfail_reason("tofino"
  "Tofino only supports 1-bit checksum update condition in the deparser"
  testdata/p4_16_samples/issue134-bmv2.p4
)

# These programs include conditional checksums, which are not supported on
# Tofino.
p4c_add_xfail_reason("tofino"
  "Tofino does not support conditional checksum verification"
  testdata/p4_16_samples/v1model-special-ops-bmv2.p4
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
  "Cannot find declaration for"
  testdata/p4_14_samples/TLV_parsing.p4
  testdata/p4_14_samples/issue576.p4
  )

p4c_add_xfail_reason("tofino"
  "Conditional emit b.emit not supported"
  testdata/p4_16_samples/issue887.p4
)

p4c_add_xfail_reason("tofino"
  " Encountered invalid code in computed checksum control"
  #extensions/p4_tests/p4_14/switch_l2_profile.p4
)

p4c_add_xfail_reason("tofino"
  "No PhvInfo::header for header named "
  testdata/p4_16_samples/issue692-bmv2.p4
)


# BEGIN: XFAILS that match glass XFAILS

# parde physical adjacency constraint violated by mau phv_no_pack constraint
p4c_add_xfail_reason("tofino"
  "Header field .* is required to be allocated contiguously"
  extensions/p4_tests/p4_14/01-FlexCounter.p4
  extensions/p4_tests/p4_14/03-VlanProfile.p4
  extensions/p4_tests/p4_14/19-SimpleTrill.p4
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
  "The selected pack format for table .* could not fit given the input xbar allocation"
  extensions/p4_tests/p4_14/test_config_13_first_selection.p4
  09-simple_l3_lag_ecmp
)

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
# no support for parser_error
p4c_add_xfail_reason("tofino"
  "Could not find declaration for standard_metadata"
  testdata/p4_16_samples/parser_error-bmv2.p4
  )
# no support for checksum verify/update
p4c_add_xfail_reason("tofino"
  "Could not find declaration for standard_metadata"
  testdata/p4_16_samples/checksum2-bmv2.p4
  testdata/p4_16_samples/checksum3-bmv2.p4
  )

# EliminateTypeDef pass does not work properly?
p4c_add_xfail_reason("tofino"
  "Could not find declaration for smeta"
  testdata/p4_16_samples/issue677-bmv2.p4
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
  extensions/p4_tests/p4_14/bf_p4c_samples/sai_p4.p4
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
  testdata/p4_16_samples/crc32-bmv2.p4
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
  )

p4c_add_xfail_reason("tofino"
  "Could not find declaration for x"
  testdata/p4_16_samples/issue1001-bmv2.p4
  )

# END: XFAILs with translation

# XXX(cole): Temporarily override previous XFAILs with new failures related to
# PHV allocation.
p4c_add_xfail_reason("tofino"
  "PHV allocation was not successful"
  extensions/p4_tests/p4_14/03-VlanProfile.p4
  extensions/p4_tests/p4_14/19-SimpleTrill.p4
  extensions/p4_tests/p4_14/01-FlexCounter.p4
  # extensions/p4_tests/p4_14/c1/COMPILER-129/compiler129.p4
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
  "The action .* manipulates field .* that requires multiple stages from an action"
  testdata/p4_16_samples/issue983-bmv2.p4
  testdata/p4_14_samples/action_inline.p4
  extensions/p4_tests/p4_14/p4smith_regression/murdoch_0.p4
  p4testgen_laymen_0
  extensions/p4_tests/p4_14/p4smith_regression/photostats_0.p4
  extensions/p4_tests/p4_14/p4smith_regression/sidestepped_0.p4
  )

p4c_add_xfail_reason("tofino"
  "src2 must be phv register"
  p4testgen_faecess_0
  )


p4c_add_xfail_reason("tofino"
  "address too large for table"
  testdata/p4_14_samples/saturated-bmv2.p4
)

p4c_add_xfail_reason("tofino"
  "Malformed packet data"
  testdata/p4_16_samples/table-entries-range-bmv2.p4
  testdata/p4_16_samples/table-entries-ternary-bmv2.p4
  testdata/p4_16_samples/table-entries-exact-bmv2.p4
  testdata/p4_16_samples/table-entries-exact-ternary-bmv2.p4
  testdata/p4_16_samples/table-entries-priority-bmv2.p4
)

p4c_add_xfail_reason("tofino"
  "the packing is too complicated .* speciality action data combined with other action data"
  extensions/p4_tests/p4_14/test_config_96_hash_data.p4
  extensions/p4_tests/p4_14/test_config_295_polynomial_hash.p4
  extensions/p4_tests/p4_14/hash_calculation_max_size.p4
  )

p4c_add_xfail_reason("tofino"
  "Unimplemented compiler support.*: Currently the compiler only supports allocation of meter color destination field"
  testdata/p4_14_samples/meter.p4
  testdata/p4_14_samples/meter1.p4
  )

# missing support for random in extract_maupipe
p4c_add_xfail_reason("tofino"
  "source of modify_field invalid"
  # extensions/p4_tests/p4_14/c1/COMPILER-129/compiler129.p4
  )

# shared register between ingress and egress is not supported
p4c_add_xfail_reason("tofino"
  "error: Could not find declaration for r"
  testdata/p4_16_samples/issue1097-2-bmv2.p4
  )

# # BRIG-372
# p4c_add_xfail_reason("tofino"
#   "Stage pragma provided to table .* has multiple parameters"
#   extensions/p4_tests/p4_14/c1/BRIG-372/case4346.p4
#   )

p4c_add_xfail_reason("tofino"
  "Currently in p4c, the table .* cannot perform a range match on key .* as the key does not fit in under 5 PHV nibbles"
  extensions/p4_tests/p4_14/test_config_324_tcam_range_11.p4
  extensions/p4_tests/p4_14/p4smith_regression/basseterre_0.p4
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
  "The method call of read and write on a Register is currently not supported in p4c"
  testdata/p4_16_samples/issue1097-bmv2.p4
  testdata/p4_16_samples/issue907-bmv2.p4
  extensions/p4_tests/p4_14/p4smith_regression/utes_0.p4
  extensions/p4_tests/p4_14/p4smith_regression/licensee_0.p4
  testdata/p4_16_samples/psa-register1.p4
  testdata/p4_16_samples/psa-register2.p4
  testdata/p4_16_samples/psa-register3.p4
  testdata/p4_16_samples/psa-example-register2-bmv2.p4
  testdata/p4_14_samples/issue894.p4
  extensions/p4_tests/p4_14/p4smith_regression/shillings_0.p4
  testdata/p4_16_samples/issue298-bmv2.p4
  testdata/p4_14_samples/register.p4
  testdata/p4_16_samples/issue1520-bmv2.p4
  testdata/p4_16_samples/slice-def-use1.p4
)

p4c_add_xfail_reason("tofino"
  "The attached .* is addressed by both hash and index in table"
  extensions/p4_tests/p4_14/test_config_313_neg_test_addr_modes.p4
)

# Flaky.
p4c_add_xfail_reason("tofino"
  "Currently non contiguous byte allocation in table format"
  # extensions/p4_tests/p4_14/test_config_215_nondphv.p4
)

# p4smith and p4testgen regression XFAILs

# real error. fails because gateway condition too complex and cannot fit in a TCAM.
p4c_add_xfail_reason("tofino"
  "error.*condition too complex"
  extensions/p4_tests/p4_14/p4smith_regression/grab_0.p4
  testdata/p4_16_samples/issue1544-1-bmv2.p4
  testdata/p4_16_samples/issue1544-2-bmv2.p4
)

# BRIG-651
p4c_add_xfail_reason("tofino"
  "PHV read has no allocation"
  extensions/p4_tests/p4_14/p4smith_regression/clue_0.p4
)

# BRIG-652
p4c_add_xfail_reason("tofino"
  "error: No phv record gaff.craftspeople"
  extensions/p4_tests/p4_14/p4smith_regression/injection_0.p4
)

# BRIG-654
p4c_add_xfail_reason("tofino"
  "Two containers in the same action are at the same place?"
  extensions/p4_tests/p4_14/p4smith_regression/selenium_0.p4
)

# BRIG-678
p4c_add_xfail_reason("tofino"
  "Split cannot work on this scenario"
  extensions/p4_tests/p4_14/p4smith_regression/underpin_0.p4
)

# BRIG-679
# error: Gateway match key chubs.dr not in matching hash column
p4c_add_xfail_reason("tofino"
  "not in matching hash column"
  extensions/p4_tests/p4_14/p4smith_regression/vindemiatrixs_0.p4
)

# BRIG-779
# error: SelectExpression: Cannot unify bit<8> to int<8>
# p4c_add_xfail_reason("tofino"
#   "SelectExpression: Cannot unify bit<.*> to int<.*>"
# )

# P4C-990
p4c_add_xfail_reason("tofino"
  "error: .*: cannot infer bitwidth for untyped integer constant used in type parameter T"
  extensions/p4_tests/p4_14/p4smith_regression/chauncey_0.p4
  extensions/p4_tests/p4_14/p4smith_regression/corroding_0.p4
  extensions/p4_tests/p4_14/p4smith_regression/undercut_0.p4
  )

# BRIG-811
# error: Output of checksum calculation can only be stored in a 16-bit field:
p4c_add_xfail_reason("tofino"
  "Output of checksum calculation can only be stored in a 16-bit field"
  extensions/p4_tests/p4_14/p4smith_regression/gradations_0.p4
)

# error: Tofino only supports "csum16" for checksum calculation
p4c_add_xfail_reason("tofino"
  "Tofino only supports \"csum16\" for checksum calculation"
  extensions/p4_tests/p4_14/p4smith_regression/globule_0.p4
  extensions/p4_tests/p4_14/p4smith_regression/quotas_0.p4
)

# BRIG-816
# error: pipe: Duplicates declaration header pipe
p4c_add_xfail_reason("tofino"
  "Duplicates declaration header pipe"
  extensions/p4_tests/p4_14/p4smith_regression/jenningss_0.p4
)

# BRIG-924
# Compiler Bug: unable to reference global instance from non-control block
p4c_add_xfail_reason("tofino"
  "Unable to reference global instance .* from non-control block"
  extensions/p4_tests/p4_14/p4smith_regression/popularity_0.p4
)

# BRIG-925
# Compiler Bug: Select on field from different parent branches is not supported.
p4c_add_xfail_reason("tofino"
  "Select on field from different parent branches is not supported"
  extensions/p4_tests/p4_14/p4smith_regression/traditionalists_0.p4
)

# P4C-992
# Compiler Bug: stage should only decrease
p4c_add_xfail_reason("tofino"
  "stage should only decrease"
)

# P4C-993
# error: .* has more than two update conditions. The compiler currently can only support up to two conditions on each calculated field.
p4c_add_xfail_reason("tofino"
  "has more than two update conditions"
  extensions/p4_tests/p4_14/p4smith_regression/cooperated_0.p4
)

# P4C-1059
# Expected failure
p4c_add_xfail_reason("tofino"
  "error: Output of checksum calculation can only be stored in a 16-bit field"
  extensions/p4_tests/p4_14/p4smith_regression/tofino-bug-1.p4
)

# P4C-1060
# Compiler Bug: Could not place table : The table sf could not fit within a single input crossbar in an MAU stage
p4c_add_xfail_reason("tofino"
  "Could not place table"
  extensions/p4_tests/p4_14/p4-tests/programs/power/power.p4
)

# BRIG-584
p4c_add_xfail_reason("tofino"
  "Unimplemented compiler support.*: Cannot extract to a field slice in the parser"
  extensions/p4_tests/p4_16/extract_slice.p4
)

p4c_add_xfail_reason("tofino"
  "Exiting with SIGSEGV"
  testdata/p4_16_samples/issue1043-bmv2.p4
)

p4c_add_xfail_reason("tofino"
  "Cannot extract field .* from .* which has type .*"
  testdata/p4_16_samples/issue1210.p4
)

# truncate is not supported in tna
p4c_add_xfail_reason("tofino"
  "Could not find declaration for truncate"
  testdata/p4_14_samples/truncate.p4
)


# frontend does not support {} on psa_direct_counter table property
p4c_add_xfail_reason("tofino"
  "Expected .* property value for table .* to resolve to an extern instance"
  testdata/p4_16_samples/psa-counter5.p4
)

# backend does not support this example
p4c_add_xfail_reason("tofino"
  "Attached object .* in table .* is executed in some actions and not executed in others"
  testdata/p4_16_samples/psa-counter6.p4
)

p4c_add_xfail_reason("tofino"
  "Attached object .* requires multiple different types of meter addressing"
  extensions/p4_tests/p4_14/test_config_142_stateful_bfd.p4
)

# psa.p4 bug, frontend failure
p4c_add_xfail_reason("tofino"
  "Action parameter color has a type which is not bit<> or int<> or bool"
  testdata/p4_16_samples/psa-meter1.p4
)

# psa.p4 bug, cannot test equal with bits and PSA_Meter_Color_t
p4c_add_xfail_reason("tofino"
  "==: not defined on bit<8> and MeterColor_t"
  testdata/p4_16_samples/psa-meter3.p4
)

p4c_add_xfail_reason("tofino"
  "Assignment cannot be supported in the parser"
  testdata/p4_16_samples/psa-fwd-bmv2.p4
  testdata/p4_16_samples/psa-example-digest-bmv2.p4
  testdata/p4_16_samples/psa-example-counters-bmv2.p4
)

# BRIG-791
p4c_add_xfail_reason("tofino"
  "Split cannot work on this scenario"
  extensions/p4_tests/p4_14/p4smith_regression/ghosted_0.p4
)


p4c_add_xfail_reason("tofino"
  "direct attached objects must be enabled in all hit actions"
  testdata/p4_16_samples/psa-meter6.p4
)

p4c_add_xfail_reason("tofino"
  "Compiler Bug.*: No object named .*CloneType.E2E"
  extensions/p4_tests/p4_14/test_config_183_sample_e2e.p4
)

# BRIG-923
p4c_add_xfail_reason("tofino"
  "error: ALU ops cannot operate on slices"
  extensions/p4_tests/p4_14/p4smith_regression/shrubs_0.p4
)

# BRIG-927
p4c_add_xfail_reason("tofino"
  "the alignment of fields within the container renders the action impossible"
)

# BRIG-920 need bridged metadata overlay
p4c_add_xfail_reason("tofino"
  "invalid parser checksum unit"
  extensions/p4_tests/p4_14/test_checksum.p4
)

p4c_add_xfail_reason("tofino"
  "Invalid deparser checksum unit.*"
  extensions/p4_tests/p4_14/test_checksum.p4  #zma needs deparser checksum engine overlay
)

# BRIG-934
p4c_add_xfail_reason("tofino"
  "error: metadata field of type error not supported on tofino"
  testdata/p4_16_samples/issue1325-bmv2.p4
  )

p4c_add_xfail_reason("tofino"
  "error: error.NoError invalid key expression"
  testdata/p4_16_samples/issue1062-bmv2.p4
  )

p4c_add_xfail_reason("tofino"
  "error: metadata field of type error not supported on tofino"
  # This test attempts to match on a field of `error` type.
  testdata/p4_16_samples/issue1062-1-bmv2.p4
  )

# P4C-1011
p4c_add_xfail_reason("tofino"
  "Exiting with SIGSEGV"
  extensions/p4_tests/p4_16/bf_p4c_samples/v1model-special-ops-bmv2.p4
  )

p4c_add_xfail_reason("tofino"
  "The random declaration .* max size must be a power of two"
  testdata/p4_16_samples/issue1517-bmv2.p4
)

p4c_add_xfail_reason("tofino"
  "already set in .* to"
  extensions/p4_tests/p4_16/ipv6_tlv.p4
)

# test program error
p4c_add_xfail_reason("tofino"
  "The random declaration .* min size must be zero"
  extensions/p4_tests/p4_14/perusal_0.p4
)

# P4C-305
p4c_add_xfail_reason("tofino"
  "No casts should ever reach this point in the Tofino backend"
  extensions/p4_tests/p4_14/p4smith_regression/clue_0.p4
  fabric-new-DWITH_INT_TRANSIT
  fabric-new-DWITH_SPGW-DWITH_INT_TRANSIT
)

# Not a bug, brig is reporting the correct error message.
p4c_add_xfail_reason("tofino"
  "An attached table can only be executed once per action"
  testdata/p4_16_samples/issue1566.p4
)

# Negative test
p4c_add_xfail_reason("tofino"
  "error: mirror.emit: requires two arguments: mirror_id and field_list"
  extensions/p4_tests/p4_16/brig-neg-1259.p4
)

p4c_add_xfail_reason("tofino"
  "Wrong number of arguments for method call"
  testdata/p4_16_samples/issue1560-bmv2.p4
)

p4c_add_xfail_reason("tofino"
  "error.*Couldn't resolve computed value for extract in state"
  testdata/p4_16_samples/issue1607-bmv2.p4
)

p4c_add_xfail_reason("tofino"
  "mirror field does not exist"
  testdata/p4_16_samples/issue562-bmv2.p4
  testdata/p4_16_samples/issue1642-bmv2.p4
  testdata/p4_16_samples/issue383-bmv2.p4
)

p4c_add_xfail_reason("tofino"
  "error.*Can only do checksums on byte-aligned container slices"
  extensions/p4_tests/p4_14/p4smith_regression/but_0.p4
  )

# Negative test. >66 bytes of ternary match key fields used.
p4c_add_xfail_reason("tofino"
  "error.*Ternary table.*uses.*as ternary match key. Maximum number of bits allowed is.*"
  extensions/p4_tests/p4_16/too_many_ternary_match_key_bits.p4
)

# Negative tests for violation of action constraints.
p4c_add_xfail_reason("tofino"
  "error.*This program violates action constraints imposed by Tofino."
  extensions/p4_tests/p4_16/case7944.p4
  extensions/p4_tests/p4_16/case7756.p4
  extensions/p4_tests/p4_14/action_conflict_1.p4
  extensions/p4_tests/p4_14/action_conflict_3.p4
  extensions/p4_tests/p4_14/action_conflict_7.p4
# Need to mark padding field used in add as a padding field. Need to introduce annotation for the
# same.
  switch_msdc_l3
  switch_8.5_msdc_l3
)

# Negative test. Constant extractor destination whose sources need more than 3 bits to express must
# go 8b containers.
p4c_add_xfail_reason("tofino"
  "error.*Tofino requires the field to go to 8b containers because of hardware constraints."
  extensions/p4_tests/p4_16/constant_extract_neg.p4
)

p4c_add_xfail_reason("tofino"
  "metadata field of type header empty_t not supported on tofino"
  extensions/p4_tests/p4_16/fabric-psa/fabric.p4
)

#new p4c tests 1/9/19
p4c_add_xfail_reason("tofino"
  "error: Could not find declaration for"
  testdata/p4_16_samples/p4rt_digest_complex.p4
)

p4c_add_xfail_reason("tofino"
  "Compiler Bug.*: unexpected reads expression"
  testdata/p4_16_samples/bvec-hdr-bmv2.p4
)

p4c_add_xfail_reason("tofino"
  "Compiler Bug.*: Field slicing has created a slice list at a nonbyte boundary."
  ../glass/testsuite/p4_tests/c1/COMPILER-868/comp_868.p4
)

p4c_add_xfail_reason("tofino"
  "source of modify_field invalid"
  testdata/p4_16_samples/strength3.p4
)

# p4runtime issue with flattenHeaders pass
p4c_add_xfail_reason("tofino"
  "FH cannot find replacement for"
  extensions/p4_tests/p4_16/serializer-struct.p4
  extensions/p4_tests/p4_16/serializer.p4
  extensions/p4_tests/p4_16/serializer2.p4
)

p4c_add_xfail_reason("tofino"
  "Could not find declaration for b"
  testdata/p4_16_samples/issue1660-bmv2.p4
)
