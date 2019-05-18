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
    extensions/p4_tests/p4_14/stf/stateful_init_regs.p4
    extensions/p4_tests/p4_16/stf/p4c-1426.p4
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
    testdata/p4_16_samples/issue1755-bmv2.p4
    testdata/p4_16_samples/subparser-with-header-stack-bmv2.p4
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

  p4c_add_xfail_reason("tofino"
    "ERROR:PTF runner:Error when running PTF tests"
    smoketest_programs_meters
    smoketest_programs_hash_driven
    )

endif() # ENABLE_STF2PTF AND PTF_REQUIREMENTS_MET

if (PTF_REQUIREMENTS_MET)

# DRV-2380
  p4c_add_xfail_reason("tofino"
    "TTransportException"
    extensions/p4_tests/p4-programs/programs/perf_test_alpm/perf_test_alpm.p4
    )

  p4c_add_xfail_reason("tofino"
    "AssertionError: Expected packet was not received on device"
    extensions/p4_tests/p4_16/ptf/ingress_checksum.p4    #TODO(zma) use @calculated_field_update_location to force ingress update
    basic_switching
    )

  p4c_add_xfail_reason("tofino"
    "AssertionError: 50 not less than 30"
    extensions/p4_tests/p4_16/ptf/various_indirect_meters.p4
    )

# BRIG-686
# NameError: global name 'smoke_large_tbls_idle_stats_tbl_match_spec_t' is not defined
  p4c_add_xfail_reason("tofino"
    "NameError: global name"
    p4testgen_smoke_large_tbls
    )

endif() # PTF_REQUIREMENTS_MET


# add the failures with no reason
p4c_add_xfail_reason("tofino" "" ${TOFINO_XFAIL_TESTS})

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
  testdata/p4_16_samples/array-copy-bmv2.p4
  testdata/p4_16_samples/issue1765-1-bmv2.p4
  testdata/p4_16_samples/stack_complex-bmv2.p4
  )

p4c_add_xfail_reason("tofino"
  "Action profile .* does not have any action data"
  testdata/p4_14_samples/selector0.p4
  extensions/p4_tests/p4_14/bf_p4c_samples/port_vlan_mapping.p4
  extensions/p4_tests/p4_14/compile_only/02-FlexCounterActionProfile.p4
  testdata/p4_14_samples/const_default_action.p4
  extensions/p4_tests/p4_14/compile_only/p4smith_regression/tofino-bug-2.p4
  testdata/p4_16_samples/action_selector_shared-bmv2.p4
  )


# BRIG-956, parser wide match
p4c_add_xfail_reason("tofino"
  "Ran out of parser match registers"
  testdata/p4_16_samples/issue995-bmv2.p4
  )

p4c_add_xfail_reason("tofino"
  "Unsupported type parameter for Value Set"
  testdata/p4_14_samples/parser_value_set2.p4
  testdata/p4_16_samples/pvs-nested-struct.p4
  )

p4c_add_xfail_reason("tofino"
  "Expression for parser counter is not supported"
  extensions/p4_tests/p4-programs/internal_p4_14/pctr/pctr.p4
  )


p4c_add_xfail_reason("tofino"
  "Unimplemented compiler support.*Cannot allocate >4 immediate bytes for logical table"
  switch_msdc_l3
  switch_8.7_msdc_l3
  )

p4c_add_xfail_reason("tofino"
  "error.*tofino supports up to 12 stages"
  ../glass/testsuite/p4_tests/phv/COMPILER-546/switch_comp546.p4
  ../glass/testsuite/p4_tests/phv/COMPILER-788/comp_788.p4
  ../glass/testsuite/p4_tests/phv/COMPILER-243/comp243.p4
  ../glass/testsuite/p4_tests/mau/COMPILER-362/icmp_typecode.p4
  extensions/p4_tests/p4_16/compile_only/flex_packing_switch.p4
  extensions/p4_tests/p4-programs/internal_p4_14/fr_test/fr_test.p4
  extensions/p4_tests/p4_16/customer/arista/p4c-1652.p4
  extensions/p4_tests/p4-programs/internal_p4_14/netcache/netcache.p4
)

p4c_add_xfail_reason("tofino"
  "error.*Can't split table.*with indirect attached MAU::StatefulAlu"
  switch_8.7_ent_fin_postcard
  switch_ent_fin_postcard
  ../glass/testsuite/p4_tests/phv/COMPILER-587/l4l.p4
  ../glass/testsuite/p4_tests/phv/COMPILER-828/meta_init_problem.p4
  ../glass/testsuite/p4_tests/phv/COMPILER-706/terminate_parsing.p4
)

p4c_add_xfail_reason("tofino"
  "error: The stage specified for .* could not place it until stage"
  extensions/p4_tests/p4-programs/internal_p4_14/ecc/ecc.p4
  extensions/p4_tests/p4-programs/internal_p4_14/mau_test/mau_test.p4  #P4C-1123
  switch_l3_heavy_int_leaf
  switch_msdc_leaf_int
  switch_8.7_msdc_leaf_int
  switch_8.7_l3_heavy_int_leaf
  switch_generic_int_leaf
  switch_8.7_generic_int_leaf
  )

p4c_add_xfail_reason("tofino"
  "error.*Power worst case estimated budget exceeded by*"
  extensions/p4_tests/p4-programs/internal_p4_14/clpm/clpm.p4
  )

p4c_add_xfail_reason("tofino"
  "Did not receive pkt on 2"
  smoketest_switch_dtel_int_spine_dtel_INTL45_Transit_DoDTest
  smoketest_switch_dtel_int_spine_dtel_QueueReport_DoD_Test
  smoketest_switch_dtel_int_spine_dtel_MirrorOnDropDoDTest
  )

p4c_add_xfail_reason("tofino"
  "A packet was received on device"
  smoketest_switch_ent_dc_general_egress_acl
  )

p4c_add_xfail_reason("tofino"
# Fail on purpose due to indirect tables not being mutually exclusive
  "Tables .* and .* are not mutually exclusive"
  extensions/p4_tests/p4_14/compile_only/action_profile_not_shared.p4
  extensions/p4_tests/p4_14/compile_only/action_profile_next_stage.p4
  testdata/p4_14_samples/12-Counters.p4
  testdata/p4_14_samples/13-Counters1and2.p4
  ../glass/testsuite/p4_tests/mau/COMPILER-1068/comp_1068.p4
  ../glass/testsuite/p4_tests/phv/COMPILER-1065/comp_1065.p4
  )

p4c_add_xfail_reason("tofino"
  "error: : condition too complex"
  extensions/p4_tests/p4_14/compile_only/07-MacAddrCheck.p4
  extensions/p4_tests/p4_14/compile_only/08-MacAddrCheck1.p4
  extensions/p4_tests/p4_14/compile_only/p4smith_regression/kindlings_0.p4
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
  testdata/p4_16_samples/issue561-1-bmv2.p4
  testdata/p4_16_samples/issue561-2-bmv2.p4
  testdata/p4_16_samples/issue561-3-bmv2.p4
  testdata/p4_16_samples/issue1897-bmv2.p4
  )

p4c_add_xfail_reason("tofino"
  "Unexpected method call in parser"
  # needs parser "verify" support
  # testdata/p4_16_samples/verify-bmv2.p4
  )

p4c_add_xfail_reason("tofino"
  "" # TIMEOUT -- appears to hang in parser unrolling.
  # FIXME -- how to have an expected timeout?
  # Following tests timeout due to infinite loop in table placement
  ../glass/testsuite/p4_tests/mau/COMPILER-726/comp_726.p4
  )

p4c_add_xfail_reason("tofino"
  "Conditions in an action must be simple comparisons of an action data parameter"
  testdata/p4_16_samples/issue420.p4
  testdata/p4_16_samples/issue1412-bmv2.p4
)

p4c_add_xfail_reason("tofino"
  "The meter .* requires either an idletime or stats address bus"
  testdata/p4_14_samples/hash_action_two_same.p4
)

p4c_add_xfail_reason("tofino"
  "This action requires hash, which can only be done through the hit pathway"
  testdata/p4_14_samples/acl1.p4
)

p4c_add_xfail_reason("tofino"
  "Can't fit table .* in input xbar by itself"
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
  "error: Tables .* and .* are not mutually exclusive, yet share"
  testdata/p4_16_samples/issue1566.p4
  testdata/p4_16_samples/issue1566-bmv2.p4
  )

p4c_add_xfail_reason("tofino"
  "error: constant value .* out of range for immediate"
  extensions/p4_tests/p4_14/compile_only/p4smith_regression/blatz_0.p4
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
  testdata/p4_16_samples/issue512.p4
  )

p4c_add_xfail_reason("tofino"
  "error: : shift count must be a constant in"
  testdata/p4_16_samples/arith3-bmv2.p4
  testdata/p4_16_samples/arith4-bmv2.p4
  testdata/p4_16_samples/arith5-bmv2.p4
  )

p4c_add_xfail_reason("tofino"
  "Exiting with SIGSEGV"
  # Same Name Conversion Bug
  extensions/p4_tests/p4_14/compile_only/shared_names.p4
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
    "The hash offset must be a power of 2 in a hash calculation"
    testdata/p4_16_samples/issue1049-bmv2.p4
    )

p4c_add_xfail_reason("tofino"
  "Ran out of tcam space in .* parser"
  testdata/p4_14_samples/issue583.p4
  # Intended to test infinite recursive in tryAllocSliceList.
  extensions/p4_tests/p4_14/compile_only/conditional_constraints_infinite_loop.p4
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
  "The input .* cannot be found on the hash input"
  ../glass/testsuite/p4_tests/phv/COMPILER-724/comp_724.p4
)

p4c_add_xfail_reason("tofino"
  "In checksum update list, fields before .* do not add up to a multiple of 8 bits. Total bits until .* : .*"
  extensions/p4_tests/p4_14/compile_only/p4c-1162.p4
  extensions/p4_tests/p4_14/compile_only/p4smith_regression/mariano_0.p4
  extensions/p4_tests/p4_14/compile_only/p4smith_regression/soured_0.p4
  extensions/p4_tests/p4_14/compile_only/p4smith_regression/but_0.p4
)

p4c_add_xfail_reason("tofino"
  "PHV allocation was not successful"
  testdata/p4_14_samples/source_routing.p4
  testdata/p4_14_samples/05-FullTPHV.p4
  testdata/p4_14_samples/06-FullTPHV1.p4
  testdata/p4_14_samples/08-FullTPHV3.p4
  testdata/p4_16_samples/issue1713-bmv2.p4
  extensions/p4_tests/p4_14/compile_only/04-FullPHV3.p4
  extensions/p4_tests/p4_16/compile_only/tagalong_mdinit_switch.p4
  ../glass/testsuite/p4_tests/mau/COMPILER-815/int_heavy.p4
  ../glass/testsuite/p4_tests/phv/COMPILER-1065/comp_1065.p4
  ../glass/testsuite/p4_tests/phv/COMPILER-1094/comp_1094.p4

  # parde physical adjacency constraint violated by mau phv_no_pack constraint
  extensions/p4_tests/p4_14/compile_only/19-SimpleTrill.p4

  # Expected to fail, which means that action analysis is working correctly.
  extensions/p4_tests/p4_14/compile_only/action_conflict_2.p4
  extensions/p4_tests/p4_14/compile_only/action_conflict_3.p4
  extensions/p4_tests/p4_14/compile_only/14-MultipleActionsInAContainer.p4

  # Expected to fail, until we have better user-facing messages.
  extensions/p4_tests/p4_16/stf/cast_widening_add.p4

  # Expected to fail, which means that constraint conflicts are being correctly detected.
  extensions/p4_tests/p4_14/compile_only/mau_test_neg_test.p4
  ../glass/testsuite/p4_tests/parde/COMPILER-612/leaf.p4
  extensions/p4_tests/p4_14/compile_only/03-VlanProfile.p4
  extensions/p4_tests/p4_14/compile_only/01-FlexCounter.p4

  # p4smith generated file used to debug key with zero mask. Fails PHV for an unknown reason.
  extensions/p4_tests/p4_14/compile_only/p4c-1162.p4
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

p4c_add_xfail_reason("tofino"
  "Tofino does not support conditional checksum verification"
  testdata/p4_16_samples/issue1739-bmv2.p4
  testdata/p4_16_samples/v1model-special-ops-bmv2.p4
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
  "error: Advancing by a non-constant distance is not supported on Tofino"
  testdata/p4_16_samples/issue1755-1-bmv2.p4
  )


# BEGIN: XFAILS that match glass XFAILS

p4c_add_xfail_reason("tofino"
  "Table .* is applied multiple times, and the next table information cannot correctly propagate"
  testdata/p4_16_samples/issue986-bmv2.p4
  )

p4c_add_xfail_reason("tofino"
  "table .* Cannot match on multiple fields using lpm match type"
  ../glass/testsuite/p4_tests/mau/case1770.p4
  testdata/p4_14_samples/issue60.p4
  )

#END: XFAILS that match glass XFAILS

# START: XFAILs with translation
# invalid tests, issue604.p4 is a v1.1 testcase
# P4-14 program can not define extern
p4c_add_xfail_reason("tofino"
  "P4_14 extern not fully supported"
  testdata/p4_14_samples/issue604.p4
  )
# are we going to retire these switch profiles?
p4c_add_xfail_reason("tofino"
  "error: .*: no such field in standard_metadata"
  extensions/p4_tests/p4_14/bf_p4c_samples/sai_p4.p4
  )

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
  extensions/p4_tests/p4_14/compile_only/13-ResubmitMetadataSize.p4
  )

# END: XFAILs with translation

p4c_add_xfail_reason("tofino"
  "error: .*: Unsupported action spanning multiple stages."
  testdata/p4_16_samples/issue983-bmv2.p4
  testdata/p4_14_samples/action_inline.p4
  extensions/p4_tests/p4_14/compile_only/p4smith_regression/murdoch_0.p4
  p4testgen_laymen_0
  extensions/p4_tests/p4_14/compile_only/p4smith_regression/photostats_0.p4
  extensions/p4_tests/p4_14/compile_only/p4smith_regression/sidestepped_0.p4
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
  "Unimplemented compiler support.*: Currently the compiler only supports allocation of meter color destination field"
  testdata/p4_14_samples/meter.p4
  testdata/p4_14_samples/meter1.p4
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
  "The method call of read and write on a Register is currently not supported in p4c"
  testdata/p4_16_samples/issue1097-bmv2.p4
  testdata/p4_16_samples/issue907-bmv2.p4
  extensions/p4_tests/p4_14/compile_only/p4smith_regression/utes_0.p4
  extensions/p4_tests/p4_14/compile_only/p4smith_regression/licensee_0.p4
  testdata/p4_16_samples/psa-register1.p4
  testdata/p4_16_samples/psa-register2.p4
  testdata/p4_16_samples/psa-register3.p4
  testdata/p4_16_samples/psa-example-register2-bmv2.p4
  testdata/p4_14_samples/issue894.p4
  testdata/p4_16_samples/issue298-bmv2.p4
  testdata/p4_14_samples/register.p4
  testdata/p4_16_samples/issue1520-bmv2.p4
  testdata/p4_16_samples/slice-def-use1.p4
  testdata/p4_16_samples/issue1814-bmv2.p4
  testdata/p4_16_samples/issue1814-1-bmv2.p4
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
  extensions/p4_tests/p4_14/compile_only/p4smith_regression/grab_0.p4
  testdata/p4_16_samples/issue1544-1-bmv2.p4
  testdata/p4_16_samples/issue1544-2-bmv2.p4
)

# BRIG-779
# error: SelectExpression: Cannot unify bit<8> to int<8>
# p4c_add_xfail_reason("tofino"
#   "SelectExpression: Cannot unify bit<.*> to int<.*>"
# )

# P4C-990
p4c_add_xfail_reason("tofino"
  "error: .*: could not infer a width"
  extensions/p4_tests/p4_14/compile_only/p4smith_regression/chauncey_0.p4
  extensions/p4_tests/p4_14/compile_only/p4smith_regression/corroding_0.p4
  extensions/p4_tests/p4_14/compile_only/p4smith_regression/undercut_0.p4
  )

# BRIG-811
# error: Output of checksum calculation can only be stored in a 16-bit field:
p4c_add_xfail_reason("tofino"
  "Output of checksum calculation can only be stored in a 16-bit field"
  extensions/p4_tests/p4_14/compile_only/p4smith_regression/gradations_0.p4
)

# error: Tofino only supports "csum16" for checksum calculation
p4c_add_xfail_reason("tofino"
  "Tofino only supports \"csum16\" for checksum calculation"
  extensions/p4_tests/p4_14/compile_only/p4smith_regression/globule_0.p4
  extensions/p4_tests/p4_14/compile_only/p4smith_regression/quotas_0.p4
)

# BRIG-816
# error: pipe: Duplicates declaration header pipe
p4c_add_xfail_reason("tofino"
  "Duplicates declaration .*"
  extensions/p4_tests/p4_14/compile_only/p4smith_regression/jenningss_0.p4
  extensions/p4_tests/p4_14/compile_only/p4smith_regression/dup_decl_random.p4
)

p4c_add_xfail_reason("tofino"
  ".* duplicates .*"
  extensions/p4_tests/p4_14/compile_only/p4smith_regression/dup_decl_struct.p4
  extensions/p4_tests/p4_14/compile_only/p4smith_regression/dup_decl_clone.p4
)

# BRIG-924
# Compiler Bug: unable to reference global instance from non-control block
p4c_add_xfail_reason("tofino"
  "Unable to reference global instance .* from non-control block"
  extensions/p4_tests/p4_14/compile_only/p4smith_regression/popularity_0.p4
)

# P4C-993
# error: .* has more than two update conditions. The compiler currently can only support up to two conditions on each calculated field.
p4c_add_xfail_reason("tofino"
  "has more than two update conditions"
  extensions/p4_tests/p4_14/compile_only/p4smith_regression/cooperated_0.p4
)

# P4C-1059
# Expected failure
p4c_add_xfail_reason("tofino"
  "In checksum update list, fields before .* do not add up to a multiple of 8 bits. Total bits until .* : .*"
  extensions/p4_tests/p4_14/compile_only/p4smith_regression/tofino-bug-1.p4
)

# P4C-1650
p4c_add_xfail_reason("tofino"
  "Table .* has a metadata dependency, but doesn't appear in the TableGraph?"
  extensions/p4_tests/p4_14/compile_only/p4smith_regression/metadata_dependency.p4
)

# P4C-1067
# Expected failure, negative test.
p4c_add_xfail_reason("tofino"
  "Operands of arithmetic operations cannot be greater than 64 bits"
  extensions/p4_tests/p4_16/customer/jeju/p4c-1067-neg.p4
)

# P4C-1067
# Expected failure, negative test.
p4c_add_xfail_reason("tofino"
  "Operand field bit .* of wide arithmetic operation cannot have even and odd container placement constraints"
  extensions/p4_tests/p4_16/customer/jeju/p4c-1067-neg2.p4
)

p4c_add_xfail_reason("tofino"
  "Currently in p4c, the table .* cannot perform a range match on key .* as the key does not fit in under 5 PHV nibbles"
  extensions/p4_tests/p4_14/compile_only/p4smith_regression/basseterre_0.p4
)


# BRIG-584
p4c_add_xfail_reason("tofino"
  "Unimplemented compiler support.*: Cannot extract to a field slice in the parser"
  extensions/p4_tests/p4_16/stf/extract_slice.p4
  ../glass/testsuite/p4_tests/phv/COMPILER-423/diag_power.p4
  ../glass/testsuite/p4_tests/mau/COMPILER-702/comp_702.p4
  ../glass/testsuite/p4_tests/mau/COMPILER-710/comp_710.p4
)

p4c_add_xfail_reason("tofino"
  "Exiting with SIGSEGV"
  testdata/p4_16_samples/issue1043-bmv2.p4
)

p4c_add_xfail_reason("tofino"
  "Cannot extract field .* from .* which has type .*"
  testdata/p4_16_samples/issue1210.p4
)

# backend does not support this example
p4c_add_xfail_reason("tofino"
  "Attached object .* in table .* is executed in some actions and not executed in others"
  testdata/p4_16_samples/psa-counter6.p4
)

# psa.p4 bug, frontend failure
p4c_add_xfail_reason("tofino"
  "Action parameter color has a type which is not bit<>, int<>, bool, type or serializable enum"
  testdata/p4_16_samples/psa-meter1.p4
)

# psa.p4 bug, cannot test equal with bits and PSA_Meter_Color_t
p4c_add_xfail_reason("tofino"
  "==: not defined on bit<8> and MeterColor_t"
  testdata/p4_16_samples/psa-meter3.p4
)

p4c_add_xfail_reason("tofino"
  "error:  Field ingress::.*of size 0 not supported"
  testdata/p4_16_samples/psa-example-digest-bmv2.p4
  testdata/p4_16_samples/psa-example-counters-bmv2.p4
)

p4c_add_xfail_reason("tofino"
  "direct attached objects must be enabled in all hit actions"
  testdata/p4_16_samples/psa-meter6.p4
)

# BRIG-923
p4c_add_xfail_reason("tofino"
  "error: ALU ops cannot operate on slices"
  extensions/p4_tests/p4_14/compile_only/p4smith_regression/shrubs_0.p4
)

# This test attempts to match on a field of `error` type.
p4c_add_xfail_reason("tofino"
  "error: Unsupported error: width not well-defined"
  testdata/p4_16_samples/issue1062-bmv2.p4
  testdata/p4_16_samples/issue1062-1-bmv2.p4
  testdata/p4_16_samples/psa-example-parser-checksum.p4
)

# BRIG-934
p4c_add_xfail_reason("tofino"
  "error.*Field.*of size 0 not supported on Tofino"
  testdata/p4_16_samples/issue1325-bmv2.p4
  extensions/p4_tests/p4_16/fabric-psa/fabric.p4
  testdata/p4_16_samples/issue510-bmv2.p4
  testdata/p4_16_samples/psa-multicast-basic-corrected-bmv2.p4
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
  "parser counter is currently unsupported"
  extensions/p4_tests/p4_16/compile_only/ipv6_tlv.p4
# P4C-590
  ../glass/testsuite/p4_tests/phv/test_config_294_parser_loop.p4
  ../glass/testsuite/p4_tests/mau/COMPILER-667/itch.p4
  ../glass/testsuite/p4_tests/parde/COMPILER-760/test_config_377_parser_counter.p4
  ../glass/testsuite/p4_tests/parde/COMPILER-612/leaf.p4
  )

# test program error
p4c_add_xfail_reason("tofino"
  "The random declaration .* min size must be zero"
  extensions/p4_tests/p4_14/compile_only/p4smith_regression/perusal_0.p4
)

# Negative test
p4c_add_xfail_reason("tofino"
  "error: mirror.emit: requires two arguments: mirror_id and field_list"
  extensions/p4_tests/p4_16/compile_only/brig-neg-1259.p4
)

p4c_add_xfail_reason("tofino"
  "mirror field does not exist"
  testdata/p4_16_samples/issue562-bmv2.p4
  testdata/p4_16_samples/issue1642-bmv2.p4
  testdata/p4_16_samples/issue383-bmv2.p4
  testdata/p4_16_samples/issue1653-complex-bmv2.p4
)

# Negative test. >66 bytes of ternary match key fields used.
p4c_add_xfail_reason("tofino"
  "error.*Ternary table.*uses.*as ternary match key. Maximum number of bits allowed is.*"
  extensions/p4_tests/p4_16/compile_only/too_many_ternary_match_key_bits.p4
)

# Negative tests for violation of action constraints.
p4c_add_xfail_reason("tofino"
  "error.*This program violates action constraints imposed by Tofino."
  extensions/p4_tests/p4_16/customer/noviflow/p4c-1288.p4
  extensions/p4_tests/p4_16/customer/kaloom/p4c-1299.p4
  extensions/p4_tests/p4_14/compile_only/action_conflict_1.p4
  extensions/p4_tests/p4_14/compile_only/action_conflict_3.p4
  extensions/p4_tests/p4_14/compile_only/action_conflict_7.p4
  extensions/p4_tests/p4_16/ptf/int_transit.p4
  ../glass/testsuite/p4_tests/mau/COMPILER-970/comp_970.p4
  ../glass/testsuite/p4_tests/mau/COMPILER-968/comp_968.p4
)

# Negative test. Constant extractor destination whose sources need more than 3 bits to express must
# go 8b containers.
p4c_add_xfail_reason("tofino"
  "error.*Tofino requires the field to go to 8b containers because of hardware constraints."
  extensions/p4_tests/p4_16/compile_only/constant_extract_neg.p4
)

p4c_add_xfail_reason("tofino"
  "The table .* with no key cannot have the action .*"
  extensions/p4_tests/p4_14/compile_only/test_config_101_switch_msdc.p4
  ../glass/testsuite/p4_tests/phv/COMPILER-961/jk_msdc.p4
)

p4c_add_xfail_reason("tofino"
  "invalid slice on slice"
  testdata/p4_16_samples/strength3.p4
)

# p4runtime issue with flattenHeaders pass
# Also P4C-1446
p4c_add_xfail_reason("tofino"
  "Inferred valid container ranges"
  extensions/p4_tests/p4_16/compile_only/serializer-struct.p4
  extensions/p4_tests/p4_16/compile_only/serializer.p4
)

p4c_add_xfail_reason("tofino"
  "Compiler Bug.*FieldLVal contains unexpected value"
  extensions/p4_tests/p4_16/compile_only/serializer2.p4
)

p4c_add_xfail_reason("tofino"
  "Could not find declaration for b"
  testdata/p4_16_samples/issue1660-bmv2.p4
)

p4c_add_xfail_reason("tofino"
  "Field .* of header .* cannot have type bool"
  testdata/p4_16_samples/header-bool-bmv2.p4
  testdata/p4_16_samples/issue1653-bmv2.p4
)

# P4C-1451 -- requires action splitting to avoid the error
p4c_add_xfail_reason("tofino"
  "Action Data Argument .* cannot be used in a hash generation expression"
  extensions/p4_tests/p4_14/customer/barefoot_academy/p4c-1451.p4
)

# Glass test suite bugs

# P4C-1371
# Errors because pa_container_size pragmas used in these tests cannot be satisfy all constraints.
p4c_add_xfail_reason("tofino"
  "No way to slice the following to satisfy @pa_container_size"
  ../glass/testsuite/p4_tests/phv/test_config_262_req_packing.p4
  ../glass/testsuite/p4_tests/phv/test_config_593_reduce_extraction_bandwidth_32.p4
  ../glass/testsuite/p4_tests/phv/test_config_227_set_meta_packing.p4
  ../glass/testsuite/p4_tests/phv/test_config_275_match_key_range.p4
  )

# Valid XFAIL
# Fails due to complex expressions in the parser that our hardware can't support.
p4c_add_xfail_reason("tofino"
  "error: Assignment cannot be supported in the parser"
  ../glass/testsuite/p4_tests/phv/test_config_402_parser_sub.p4
  )

# P4C-1372
# Inferred valid container ranges N[0..2147483646]b and N[0..-113]b for field
# ingress::m.ingress_port which cannot both be satisfied for a field of size 9b"
p4c_add_xfail_reason("tofino"
  "Inferred valid container ranges"
  ../glass/testsuite/p4_tests/phv/COMPILER-679/case3769.p4
  )

# P4C-1299
p4c_add_xfail_reason("tofino"
    # Depending on VM Load these tests may timeout before displaying the PHV
    # alloc unsuccessful message and fail travis, we use both messages to check
    # xfails
    "PHV allocation was not successful|./p4c TIMEOUT"
  ../glass/testsuite/p4_tests/phv/COMPILER-136/06-FullTPHV1.p4
# bigger problem is that the container conflict free table placement is 15 stages for the following
# program.
  c2_COMPILER-537_case2834
  c2_COMPILER-514_balancer_one
  c2_COMPILER-510_case2682
  ../glass/testsuite/p4_tests/arista/COMPILER-868/comp_868.p4
  )

p4c_add_xfail_reason("tofino"
  "PHV allocation was not successful|./p4c TIMEOUT"
  ../glass/testsuite/p4_tests/rdp/COMPILER-443/case2514.p4
  ../glass/testsuite/p4_tests/rdp/COMPILER-466/case2563_without_nop.p4
  ../glass/testsuite/p4_tests/rdp/COMPILER-466/case2563_with_nop.p4
  ../glass/testsuite/p4_tests/rdp/COMPILER-502/case2675.p4
  # funnel shift not supported
  ../glass/testsuite/p4_tests/rdp/COMPILER-533/case2736.p4
  )

# P4C-1375
p4c_add_xfail_reason("tofino"
  "Field .* written to more than once in action .*"
  ../glass/testsuite/p4_tests/phv/COMPILER-761/simple_l3_mirror.p4
  )

# Valid XFAIL
p4c_add_xfail_reason("tofino"
  "Currently in p4c, the table .* cannot perform a range match on key .* as the key does not fit in under 5 PHV nibbles"
  ../glass/testsuite/p4_tests/mau/test_config_324_tcam_range_11.p4
  )

# P4C-1376
p4c_add_xfail_reason("tofino"
  "Currently in p4c, any table using an action profile is required to use the same actions, and the following actions don't appear in all table using the action profile"
  ../glass/testsuite/p4_tests/mau/COMPILER-445/comp_445.p4
  )

# P4C-1165
p4c_add_xfail_reason("tofino"
  "Cannot unify bit<.*> to bit<.*>"
  ../glass/testsuite/p4_tests/parde/COMPILER-350/ipv4_issue.p4
  ../glass/testsuite/p4_tests/phv/COMPILER-394/comp394.p4
  )

# Valid XFAIL
p4c_add_xfail_reason("tofino"
  "error: calling indirect .* with no index"
  ../glass/testsuite/p4_tests/mau/test_config_410_neg_stateful_no_idx.p4
  )

# P4C-1379
p4c_add_xfail_reason("tofino"
  "Unsupported primitive invalidate_clone"
  ../glass/testsuite/p4_tests/mau/test_config_400_disable_reserved_i2e.p4
  ../glass/testsuite/p4_tests/mau/test_config_396_invalidate_clone.p4
  )

# Valid XFAIL
p4c_add_xfail_reason("tofino"
  "Expected 2 operands for execute"
  ../glass/testsuite/p4_tests/mau/test_config_411_neg_meter_no_idx.p4
  )

p4c_add_xfail_reason("tofino"
  "error: The stage specified for table .* is .*, but we could not place it until stage .*"
  ../glass/testsuite/p4_tests/arista/DRV-543/case2499.p4
  )

# Valid XFAIL
p4c_add_xfail_reason("tofino"
  "The attached .* is addressed by both hash and index in table"
  ../glass/testsuite/p4_tests/mau/test_config_313_neg_test_addr_modes.p4
  )

# Existing p4lang/p4c issue
# Need to update test case in glass
p4c_add_xfail_reason("tofino"
  "Tofino requires byte-aligned headers, but header .* is not byte-aligned"
  ../glass/testsuite/p4_tests/mau/test_config_160_stateful_single_bit_mode.p4
  )

# P4C-1382
p4c_add_xfail_reason("tofino"
  "invalid operand"
  ../glass/testsuite/p4_tests/mau/test_config_191_invalidate.p4
  )

# Valid XFAIL
p4c_add_xfail_reason("tofino"
  "extern .* does not have method matching this call"
  ../glass/testsuite/p4_tests/mau/test_config_412_neg_lpf_no_idx.p4
  ../glass/testsuite/p4_tests/mau/test_config_413_neg_wred_no_idx.p4
  )

# P4C-1383
p4c_add_xfail_reason("tofino"
  "Unimplemented compiler support.*Cannot allocate >4 immediate bytes for logical table"
  ../glass/testsuite/p4_tests/mau/test_config_205_modify_field_from_hash.p4
  ../glass/testsuite/p4_tests/arista/COMPILER-964/test_config_401_random_num.p4
  ../glass/testsuite/p4_tests/arista/COMPILER-1105/case8039.p4
  )

# P4C-1323
# Could not place table capture_timestamp_1_0: The table capture_timestamp_1_1 could not fit within a single input crossbar in an MAU stage
p4c_add_xfail_reason("tofino"
  "Could not place table"
  ../glass/testsuite/p4_tests/mau/COMPILER-572/hct.p4
  ../glass/testsuite/p4_tests/mau/COMPILER-268/netflow_3.p4
  )

# P4C-1384
p4c_add_xfail_reason("tofino"
  "error.*To fit hash destinations in less than 4 immediate bytes"
  ../glass/testsuite/p4_tests/mau/test_config_311_hash_adb.p4
  )

# P4C-1385
p4c_add_xfail_reason("tofino"
  "Compiler Bug.*: No object named .*CloneType.E2E"
  ../glass/testsuite/p4_tests/mau/test_config_183_sample_e2e.p4
  )

# P4C-1386
p4c_add_xfail_reason("tofino"
  "The initial offset for a hash calculation function has to be zero"
  ../glass/testsuite/p4_tests/mau/test_config_345_hash_with_base.p4
  )

# P4C-1387
p4c_add_xfail_reason("tofino"
  "Unrecognized algorithm for a hash expression:"
  ../glass/testsuite/p4_tests/mau/test_config_408_xor_hashes.p4
  ../glass/testsuite/p4_tests/parde/test_config_423_zeros_as_ones.p4
  )

# P4C-1389
p4c_add_xfail_reason("tofino"
  "Tables .* and .* are not mutually exclusive"
  ../glass/testsuite/p4_tests/mau/COMPILER-445/comp_445_counter.p4
  ../glass/testsuite/p4_tests/mau/COMPILER-531/test_config_320_pragma_ignore_dep.p4
  ../glass/testsuite/p4_tests/mau/COMPILER-1068/comp_1068.p4
  ../glass/testsuite/p4_tests/parde/COMPILER-1091/comp_1091.p4
  )

# BRIG-604
p4c_add_xfail_reason("tofino"
  "PHV read has no allocation"
  ../glass/testsuite/p4_tests/mau/COMPILER-628/case3431.p4
  ../glass/testsuite/p4_tests/mau/COMPILER-630/case3431b.p4
  extensions/p4_tests/p4_14/compile_only/p4smith_regression/clue_0.p4
  testdata/p4_16_samples/issue983-bmv2.p4
  )

# Valid XFAIL
p4c_add_xfail_reason("tofino"
  "Attached object .* in table .* is executed in some actions and not executed in others"
  ../glass/testsuite/p4_tests/mau/COMPILER-478/test_config_310_hash_write_issue.p4
  )

# Valid XFAIL
p4c_add_xfail_reason("tofino"
  "Maximum width for counter .* is 128 bits"
  ../glass/testsuite/p4_tests/mau/COMPILER-1108/comp_1108.p4
  )

# Valid XFAIL
p4c_add_xfail_reason("tofino"
  "Unexpected type for constant varbit"
  ../glass/testsuite/p4_tests/mau/COMPILER-556/variable.p4
  )

# P4C-539
p4c_add_xfail_reason("tofino"
  "error: .*: Not found declaration"
  ../glass/testsuite/p4_tests/parde/COMPILER-319/mirror-eg_intr_md-all.p4
  ../glass/testsuite/p4_tests/parde/COMPILER-319/mirror-eg_intr_md_from_parser_aux.p4
  ../glass/testsuite/p4_tests/parde/COMPILER-675/select_on_egress_port.p4
  ../glass/testsuite/p4_tests/mau/COMPILER-837/comp_837_2.p4
  testdata/p4_16_samples/action_profile-bmv2.p4
  testdata/p4_16_samples/issue297-bmv2.p4
  # EliminateTypeDef pass does not work properly?
  testdata/p4_16_samples/issue677-bmv2.p4
  testdata/p4_16_samples/issue1001-bmv2.p4
  # We fail to translate `generate_digest()`.
  testdata/p4_14_samples/issue1058.p4
  # shared register between ingress and egress is not supported
  testdata/p4_16_samples/issue1097-2-bmv2.p4
  testdata/p4_16_samples/issue1660-bmv2.p4
  testdata/p4_16_samples/issue1768-bmv2.p4
  # We fail to translate `resubmit()`.
  testdata/p4_14_samples/resubmit.p4
  testdata/p4_16_samples/std_meta_inlining.p4
  # no support for checksum verify/update
  testdata/p4_16_samples/checksum2-bmv2.p4
  testdata/p4_16_samples/checksum3-bmv2.p4
  # no support for parser_error
  testdata/p4_16_samples/parser_error-bmv2.p4
  # Checksum16 is deprecated
  extensions/p4_tests/p4_16/stf/ipv4_options.p4
  # We fail to translate `standard_metadata.instance_type`.
  testdata/p4_14_samples/copy_to_cpu.p4
  testdata/p4_14_samples/packet_redirect.p4
  testdata/p4_14_samples/simple_nat.p4
  # truncate is not supported in tna
  testdata/p4_14_samples/truncate.p4
  testdata/p4_16_samples/p4rt_digest_complex.p4
  testdata/p4_16_samples/issue1824-bmv2.p4
  testdata/p4_16_samples/action_profile_max_group_size_annotation.p4
  # new tests added to p4c
  testdata/p4_16_samples/v1model-digest-containing-ser-enum.p4
  testdata/p4_16_samples/test-parserinvalidargument-error-bmv2.p4
  )

# P4C-1390
p4c_add_xfail_reason("tofino"
  "expected a field list"
  ../glass/testsuite/p4_tests/parde/test_start_coalesced_state.p4
  )

# BRIG-920 need bridged metadata overlay
p4c_add_xfail_reason("tofino"
  "invalid parser checksum unit"
  ../glass/testsuite/p4_tests/parde/test_checksum.p4
  )

# BRIG-956, parser wide match
p4c_add_xfail_reason("tofino"
  "Ran out of parser match registers"
  ../glass/testsuite/p4_tests/parde/COMPILER-368/out.p4
  testdata/p4_16_samples/v1model-p4runtime-most-types1.p4
  )

# P4C-1393
p4c_add_xfail_reason("tofino"
  "error.*This program violates action constraints imposed by Tofino."
  ../glass/testsuite/p4_tests/mau/COMPILER-728/ipu.p4
  )

# P4C-1395
p4c_add_xfail_reason("tofino"
  "Inferred incompatible alignments for field .*"
  ../glass/testsuite/p4_tests/phv/COMPILER-908/compiler-908.p4
  )

# P4C-1396
p4c_add_xfail_reason("tofino"
  "Incompatible types bit<1> and bool"
  ../glass/testsuite/p4_tests/noviflow/COMPILER-687/case3769.p4
  ../glass/testsuite/p4_tests/noviflow/COMPILER-842/comp_842.p4
  ../glass/testsuite/p4_tests/noviflow/DRV-1092/drv_1092.p4
  )

# P4C-1397
p4c_add_xfail_reason("tofino"
  "Total size of containers used for.*POV allocation is .*b, greater than the allowed limit of 256b|./p4c TIMEOUT"
  ../glass/testsuite/p4_tests/rdp/COMPILER-475/case2600.p4
  )

# P4C-1400
p4c_add_xfail_reason("tofino"
  "The stage specified for table .* is .*, but we could not place it until stage .*"
  ../glass/testsuite/p4_tests/phv/COMPILER-733/ipu_ingress.p4
  )

# Valid XFAIL
p4c_add_xfail_reason("tofino"
  "Phase0 pragma set but table - .* is not a valid Phase0"
  ../glass/testsuite/p4_tests/mau/test_config_330_phase0_pragma_neg.p4
  )

# P4C-1401
p4c_add_xfail_reason("tofino"
  "Expression cast.* cannot be the target of an assignment"
  ../glass/testsuite/p4_tests/phv/COMPILER-777/switch_comp_777.p4
  ../glass/testsuite/p4_tests/mau/COMPILER-770/switch_comp_770.p4
  ../glass/testsuite/p4_tests/mau/DRV-1081/switch_drv_1081.p4
  ../glass/testsuite/p4_tests/mau/COMPILER-814/comp_814.p4
  )

# P4C-1404
p4c_add_xfail_reason("tofino"
  "Different POV bit found"
  ../glass/testsuite/p4_tests/mau/COMPILER-815/int_heavy.p4
  )

# P4C doesn't support use_container_valid pragma?
p4c_add_xfail_reason("tofino"
  "error: Field isValid is not a member of structure struct ingress_intrinsic_metadata_for_tm_t"
  ../glass/testsuite/p4_tests/mau/test_config_420_intr_md_tcam_valid.p4
  )

# P4C-1522, previously P4C-1374
p4c_add_xfail_reason("tofino"
  "Miscoordination of what hash groups are on the search bus vs. what hash groups are in the table format"
  ../glass/testsuite/p4_tests/phv/COMPILER-587/l4l.p4
  )

# P4C-1577
p4c_add_xfail_reason("tofino"
  "Table .* .* invoked from two different controls: Apply and Apply"
  ../glass/testsuite/p4_tests/phv/COMPILER-1134/comp_1134.p4
  )

# P4C-1576
p4c_add_xfail_reason("tofino"
  "More than one field written to by field"
  ../glass/testsuite/p4_tests/parde/test_config_421_elim_calc_ops.p4
  ../glass/testsuite/p4_tests/parde/test_config_422_exit_calc_upd.p4
  )

p4c_add_xfail_reason("tofino"
   "Assignment cannot be supported in the parser"
   testdata/p4_14_samples/axon.p4
)

p4c_add_xfail_reason("tofino"
   "FieldLVal contains unexpected value"
   extensions/p4_tests/p4_16/compile_only/serializer2.p4
)

p4c_add_xfail_reason("tofino"
   "PHV allocation creates a container action impossible within a Tofino ALU"
  extensions/p4_tests/p4_16/customer/arista/p4c-1494.p4
)

p4c_add_xfail_reason("tofino"
  "The following operation is not yet supported"
  ../glass/testsuite/p4_tests/mau/COMPILER-815/int_heavy.p4
)

# p4lang/p4c #1724
p4c_add_xfail_reason("tofino"
  "error: The following operation is not yet supported:"
  testdata/p4_14_samples/issue-1559.p4
)

p4c_add_xfail_reason("tofino"
  "Invalid entry in checksum calculation"
  testdata/p4_16_samples/issue1765-bmv2.p4
)

# varbit related starts
p4c_add_xfail_reason("tofino"
  "No varbit length encoding variable in"
  testdata/p4_16_samples/issue561-bmv2.p4
)

p4c_add_xfail_reason("tofino"
  "Cannot find declaration for"
  testdata/p4_14_samples/issue576.p4
  testdata/p4_14_samples/TLV_parsing.p4
)

p4c_add_xfail_reason("tofino"
  "1 expected packet on port 0 not seen"
  testdata/p4_16_samples/issue447-bmv2.p4
)

# P4C-1753
p4c_add_xfail_reason("tofino"
  ".* expected packet on port .* not seen"
  testdata/p4_16_samples/match-on-exprs-bmv2.p4
  testdata/p4_16_samples/table-entries-range-bmv2.p4
  testdata/p4_16_samples/table-entries-ternary-bmv2.p4
  testdata/p4_16_samples/bvec-hdr-bmv2.p4
)

# P4C-1753
p4c_add_xfail_reason("tofino"
  "unexpected packet output on port .*"
  testdata/p4_16_samples/table-entries-exact-ternary-bmv2.p4
  testdata/p4_16_samples/table-entries-priority-bmv2.p4
)

p4c_add_xfail_reason("tofino"
  ".* cannot be translated, you cannot use it in your program"
  testdata/p4_14_samples/p414-special-ops.p4
)

p4c_add_xfail_reason("tofino"
  "use of varbit field is only supported in parser and deparser currently"
  testdata/p4_16_samples/equality-bmv2.p4
  testdata/p4_16_samples/equality-varbit-bmv2.p4
  testdata/p4_16_samples/issue447-5-bmv2.p4
)

p4c_add_xfail_reason("tofino"
  "multiple varbit fields in a parser state is currently unsupported"
  testdata/p4_16_samples/issue447-1-bmv2.p4
)

p4c_add_xfail_reason("tofino"
  "Varbit field size expression evaluates to non byte-aligned value"
  # unbounded varbit expr
  extensions/p4_tests/p4_16/compile_only/p4c-1478-neg.p4
  testdata/p4_16_samples/issue447-2-bmv2.p4
  testdata/p4_16_samples/issue447-3-bmv2.p4
  testdata/p4_16_samples/issue447-4-bmv2.p4
  testdata/p4_16_samples/issue1879-bmv2.p4
)
# varbit related ends

# Expected failure
p4c_add_xfail_reason("tofino"
  "error: standard_metadata.packet_length is not accessible in the ingress pipe"
  testdata/p4_14_samples/p414-special-ops-2-bmv2.p4
  testdata/p4_14_samples/p414-special-ops-3-bmv2.p4
)

# funnel-shift not supported
p4c_add_xfail_reason("tofino"
  "PHV allocation was not successful"
  ../glass/testsuite/p4_tests/mau/test_config_235_funnel_shift.p4
  ../glass/testsuite/p4_tests/arista/COMPILER-1113/case8138.p4
)

# negative test.
p4c_add_xfail_reason("tofino"
  "Not a phv field in the lpf execute: 1"
  extensions/p4_tests/p4_16/compile_only/neg_test_1_lpf_constant_param.p4
)

p4c_add_xfail_reason("tofino"
  "Duplicate phv name"
  extensions/p4_tests/p4_16/compile_only/test_config_3_unused_parsers.p4
)

# Negative test: ensure the compiler does not seg fault
p4c_add_xfail_reason("tofino"
  "error: mirror.emit: Unsupported unconditional mirror.emit"
  extensions/p4_tests/p4_16/customer/noviflow/p4c-1588-neg.p4
  )

p4c_add_xfail_reason("tofino"
  "Exiting with SIGSEGV"
  testdata/p4_16_samples/issue561-4-bmv2.p4
  testdata/p4_16_samples/issue561-5-bmv2.p4
  testdata/p4_16_samples/issue561-6-bmv2.p4
  testdata/p4_16_samples/issue561-7-bmv2.p4
)

p4c_add_xfail_reason("tofino"
  "error: Select on uninitialized value"
  extensions/p4_tests/p4_16/compile_only/p4c-1561-neg.p4
  # unable to resolve "lookahead" expression in resolve_parser_values.cpp
  testdata/p4_16_samples/issue1409-bmv2.p4
  testdata/p4_16_samples/checksum1-bmv2.p4
  testdata/p4_16_samples/issue1025-bmv2.p4
  testdata/p4_16_samples/issue355-bmv2.p4
  testdata/p4_16_samples/issue1560-bmv2.p4
  testdata/p4_16_samples/issue692-bmv2.p4
  testdata/p4_16_samples/issue1607-bmv2.p4
  extensions/p4_tests/p4_16/compile_only/serializer3.p4
)

p4c_add_xfail_reason("tofino"
  "error: Tofino does not support nested checksum updates"
  extensions/p4_tests/p4_14/stf/update_checksum_7.p4
  extensions/p4_tests/p4_14/compile_only/p4smith_regression/soured_0.p4
  extensions/p4_tests/p4_14/compile_only/p4smith_regression/shillings_0.p4
  ../glass/testsuite/p4_tests/mau/galaxy_0.p4
  ../glass/testsuite/p4_tests/parde/test_checksum.p4
)

# Slicing issue
p4c_add_xfail_reason("tofino"
  "Compiler Bug.*Slice point cannot be -1 at this point"
  ../glass/testsuite/p4_tests/arista/COMPILER-1114/case8156.p4
)

# P4C-1445, DRV-2667
# Requires Pipe prefix support to avoid duplicate names
p4c_add_xfail_reason("tofino"
  "error: Found .* duplicate name.* in the P4Info"
  extensions/p4_tests/p4_16/compile_only/test_config_11_multi_pipe_multi_parsers.p4
  extensions/p4_tests/p4_16/compile_only/simple_32q.p4
  extensions/p4_tests/p4_16/compile_only/multiple_apply2.p4
  extensions/p4_tests/p4_16/compile_only/brig-814-2.p4
  testdata/p4_16_samples/psa-counter6.p4
)

p4c_add_xfail_reason("tofino"
  "syntax error, unexpected IDENTIFIER"
  testdata/p4_16_samples/psa-unicast-or-drop-bmv2.p4
  testdata/p4_16_samples/psa-recirculate-no-meta-bmv2.p4
  testdata/p4_16_samples/psa-basic-counter-bmv2.p4
  testdata/p4_16_samples/psa-unicast-or-drop-corrected-bmv2.p4
)

p4c_add_xfail_reason("tofino"
  "error:  Field .* of size 0 not supported on Tofino"
  testdata/p4_16_samples/psa-multicast-basic-bmv2.p4
)
