# XFAILS: tests that *temporarily* fail
# =====================================
#
# Xfails are _temporary_ failures: the tests should work but we haven't fixed
# the compiler yet.
#
# Tests that are _always_ expected to fail should be placed in an 'errors'
# directory, e.g., p4-tests/p4_16/errors/, and added to TofinoErrors.cmake
#
#
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
    # testdata/p4_16_samples/table-entries-ser-enum-bmv2.p4
    )

  # Brig/Glass do not follow P4_14 spec for 'drop' in the ingress pipeline
  p4c_add_xfail_reason("tofino"
    "expected packet[s]* on port .* not seen"
    testdata/p4_14_samples/gateway1.p4
    testdata/p4_14_samples/gateway2.p4
    testdata/p4_14_samples/gateway3.p4
    testdata/p4_14_samples/gateway4.p4
    testdata/p4_16_samples/issue1000-bmv2.p4
    testdata/p4_16_samples/issue1755-bmv2.p4
    testdata/p4_16_samples/issue774-4-bmv2.p4
    testdata/p4_16_samples/match-on-exprs-bmv2.p4
    testdata/p4_16_samples/subparser-with-header-stack-bmv2.p4
    )

  p4c_add_xfail_reason("tofino"
    "mismatch from expected(.*) at byte .*"
    testdata/p4_16_samples/parser-inline/parser-inline-test5.p4
    testdata/p4_16_samples/parser-inline/parser-inline-test6.p4
    parser-inline-opt/testdata/p4_16_samples/parser-inline/parser-inline-test5.p4
    parser-inline-opt/testdata/p4_16_samples/parser-inline/parser-inline-test6.p4
    )

  p4c_add_xfail_reason("tofino"
    "expected packet[s]* on port .* not seen"
    testdata/p4_16_samples/parser-inline/parser-inline-test7.p4
    parser-inline-opt/testdata/p4_16_samples/parser-inline/parser-inline-test7.p4
    testdata/p4_16_samples/parser-inline/parser-inline-test8.p4
    testdata/p4_16_samples/parser-inline/parser-inline-test9.p4
    testdata/p4_16_samples/parser-inline/parser-inline-test10.p4
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
    )

  p4c_add_xfail_reason("tofino"
    "AssertionError: .*: wrong (packets|bytes) count: expected [0-9]+ not [0-9]+"
    # counter3 fails because it receives 64 bytes: for PTF the test should be adjusted to send more than 8 bytes
    testdata/p4_14_samples/counter3.p4
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
    "AssertionError: Expected packet was not received on device"
    extensions/p4_tests/p4_16/ptf/ingress_checksum.p4    #TODO(zma) use @calculated_field_update_location to force ingress update
    )

endif() # PTF_REQUIREMENTS_MET


# add the failures with no reason
p4c_add_xfail_reason("tofino" "" ${TOFINO_XFAIL_TESTS})

p4c_add_xfail_reason("tofino"
  "Attached object .* in table .* is executed in some actions and not executed in others"
  testdata/p4_16_samples/issue364-bmv2.p4
  testdata/p4_16_samples/named_meter_1-bmv2.p4
  testdata/p4_16_samples/named_meter_bmv2.p4
  testdata/p4_16_samples/unused-counter-bmv2.p4
  )

# Fails due to complex expressions in the parser that our hardware can't support.
p4c_add_xfail_reason("tofino"
  "error: Assignment source cannot be evaluated in the parser"
  testdata/p4_16_samples/issue1765-1-bmv2.p4
  testdata/p4_16_samples/stack_complex-bmv2.p4
  testdata/p4_16_samples/checksum-l4-bmv2.p4
  testdata/p4_16_samples/issue1001-1-bmv2.p4
  testdata/p4_16_samples/psa-variable-index.p4
)

p4c_add_xfail_reason("tofino"
  "Action profile .* does not have any action data"
  extensions/p4_tests/p4_14/bf_p4c_samples/port_vlan_mapping.p4
  extensions/p4_tests/p4_14/compile_only/02-FlexCounterActionProfile.p4
  testdata/p4_14_samples/const_default_action.p4
  testdata/p4_14_samples/selector0.p4
  testdata/p4_16_samples/action_selector_shared-bmv2.p4
  )


# BRIG-956, parser wide match
p4c_add_xfail_reason("tofino"
  "error.*Ran out of parser match registers for"
  testdata/p4_16_samples/issue995-bmv2.p4
  testdata/p4_16_samples/v1model-p4runtime-most-types1.p4
  testdata/p4_16_samples/v1model-p4runtime-enumint-types1.p4
  testdata/p4_16_samples/psa-example-select_tuple.p4
  testdata/p4_16_samples/psa-example-select_tuple-wc.p4
  testdata/p4_16_samples/psa-example-select_tuple-1.p4
  testdata/p4_16_samples/psa-example-select_tuple-mask.p4
  )

# unsupported match type combination on tofino
p4c_add_xfail_reason("tofino"
  "table ipv4_lpm Cannot match on both ternary and LPM fields"
  testdata/p4_16_samples/basic2-bmv2.p4
  )

p4c_add_xfail_reason("tofino"
  "Unsupported type argument for Value Set"
  testdata/p4_14_samples/parser_value_set2.p4
  testdata/p4_16_samples/pvs-nested-struct.p4
  )

p4c_add_xfail_reason("tofino"
  "HashAlgorithm_t.CSUM16: Invalid enum tag"
  testdata/p4_14_samples/issue894.p4
)

p4c_add_xfail_reason("tofino"
  "error.*Ran out of parser match registers for"
  extensions/p4_tests/p4_16/compile_only/missing_checksumID.p4
)

p4c_add_xfail_reason("tofino"
  "Tofino requires byte-aligned headers"
  extensions/p4_tests/p4_16/compile_only/tagalong_mdinit_switch.p4
)

p4c_add_xfail_reason("tofino"
  "error: Use of uninitialized parser value"
  testdata/p4_16_samples/issue692-bmv2.p4
  testdata/p4_16_samples/parser-if.p4
)

p4c_add_xfail_reason("tofino"
# Fail on purpose due to indirect tables not being mutually exclusive
  "table .* and table .* cannot share .*"
  extensions/p4_tests/p4_14/compile_only/action_profile_next_stage.p4
  extensions/p4_tests/p4_14/compile_only/action_profile_not_shared.p4
  testdata/p4_14_samples/12-Counters.p4
  testdata/p4_14_samples/13-Counters1and2.p4
  testdata/p4_16_samples/psa-action-profile3.p4
  )

p4c_add_xfail_reason("tofino"
  "error.*condition too complex"
  extensions/p4_tests/p4_14/compile_only/07-MacAddrCheck.p4
  extensions/p4_tests/p4_14/compile_only/08-MacAddrCheck1.p4
  extensions/p4_tests/p4_14/compile_only/p4smith_regression/kindlings_0.p4
  testdata/p4_16_samples/issue1544-bmv2.p4
  testdata/p4_16_samples/issue2148.p4
  )

# BRIG_132
p4c_add_xfail_reason("tofino"
  "Unsupported type header_union"
  testdata/p4_16_samples/bvec_union-bmv2.p4
  testdata/p4_16_samples/issue1897-bmv2.p4
  testdata/p4_16_samples/issue561-bmv2.p4
  testdata/p4_16_samples/issue561-1-bmv2.p4
  testdata/p4_16_samples/issue561-2-bmv2.p4
  testdata/p4_16_samples/issue561-3-bmv2.p4
  testdata/p4_16_samples/issue561-4-bmv2.p4
  testdata/p4_16_samples/issue561-5-bmv2.p4
  testdata/p4_16_samples/issue561-6-bmv2.p4
  testdata/p4_16_samples/issue561-7-bmv2.p4
  testdata/p4_16_samples/union-bmv2.p4
  testdata/p4_16_samples/union-valid-bmv2.p4
  testdata/p4_16_samples/union1-bmv2.p4
  testdata/p4_16_samples/union2-bmv2.p4
  testdata/p4_16_samples/union3-bmv2.p4
  testdata/p4_16_samples/union4-bmv2.p4
  # p4c update 2021-11-08
  testdata/p4_16_samples/invalid-hdr-warnings5.p4
  testdata/p4_16_samples/invalid-hdr-warnings6.p4
  testdata/p4_16_samples/wrong-warning.p4
  #p4c update 2022-04-25
  testdata/p4_16_samples/extract_for_header_union.p4
  #p4c update 2022-06-22
  testdata/p4_16_samples/parser-unroll-test7.p4
  )

p4c_add_xfail_reason("tofino"
  "Conditions in an action must be simple comparisons of an action data parameter"
  testdata/p4_16_samples/issue1412-bmv2.p4
  testdata/p4_16_samples/issue420.p4
  testdata/p4_16_samples/issue2248.p4
  testdata/p4_16_samples/issue2330-1.p4
  testdata/p4_16_samples/issue2330.p4
  testdata/p4_16_samples/issue-2123-3-bmv2.p4
  testdata/p4_16_samples/issue-2123-2-bmv2.p4
  testdata/p4_16_samples/issue512.p4
  testdata/p4_16_samples/psa-dpdk-errorcode-1.p4
  testdata/p4_16_samples/hdr_stacks2345.p4
  testdata/p4_16_samples/xor_test.p4
  testdata/p4_16_samples/issue2345.p4
  testdata/p4_16_samples/nested_if_statement.p4
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
  "expected a method call"
  testdata/p4_16_samples/issue1538.p4
  )

p4c_add_xfail_reason("tofino"
  "Static entries are not supported for lpm-match"
  testdata/p4_16_samples/table-entries-lpm-bmv2.p4
  testdata/p4_16_samples/v1model-const-entries-bmv2.p4
  )

p4c_add_xfail_reason("tofino"
  "error: table .* and table .* cannot share .*"
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
  )

p4c_add_xfail_reason("tofino"
  "error: : shift count must be a constant in"
  testdata/p4_16_samples/arith3-bmv2.p4
  testdata/p4_16_samples/arith4-bmv2.p4
  testdata/p4_16_samples/arith5-bmv2.p4
  testdata/p4_16_samples/issue2190.p4
  # p4c update 2022-04-25
  testdata/p4_16_samples/psa-dpdk-binary-operations.p4
  testdata/p4_16_samples/psa-dpdk-binary-operations-1.p4
  )

p4c_add_xfail_reason("tofino"
  "error: destination of modify_field must be a field"
  testdata/p4_16_samples/v1model-digest-containing-ser-enum.p4
  testdata/p4_16_samples/v1model-digest-custom-type.p4
)

p4c_add_xfail_reason("tofino"
  "Exiting with SIGSEGV"
  # Same Name Conversion Bug
  extensions/p4_tests/p4_14/compile_only/shared_names.p4
  # Issue with no default branch in switch
  testdata/p4_16_samples/psa-switch-expression-without-default.p4
  )

p4c_add_xfail_reason("tofino"
  "The hash offset must be a power of 2 in a hash calculation"
  testdata/p4_16_samples/issue1049-bmv2.p4
  testdata/p4_16_samples/issue584-1-bmv2.p4
)

p4c_add_xfail_reason("tofino"
  "condition too complex"
  testdata/p4_16_samples/psa-unicast-or-drop-corrected-bmv2.p4
  testdata/p4_16_samples/psa-i2e-cloning-basic-bmv2.p4
)

p4c_add_xfail_reason("tofino"
  "Unknown command mc_mgrp_create"
  testdata/p4_16_samples/psa-multicast-basic-corrected-bmv2.p4
  testdata/p4_16_samples/psa-multicast-basic-bmv2.p4
)

p4c_add_xfail_reason("tofino"
  "Cannot cast implicitly type"
  extensions/p4_tests/p4_16/stf/onlab_packet_io.p4
)

p4c_add_xfail_reason("tofino"
  "Expected type T in digest to be a typeName"
  testdata/p4_16_samples/issue430-1-bmv2.p4
  )

p4c_add_xfail_reason("tofino"
  "In checksum update list, fields before .* do not add up to a multiple of 8 bits. Total bits until .* : .*"
  extensions/p4_tests/p4_14/compile_only/p4smith_regression/but_0.p4
  extensions/p4_tests/p4_14/compile_only/p4smith_regression/mariano_0.p4
)

p4c_add_xfail_reason("tofino"
  "Action .* must be rewritten, because it requires too many sources"
  extensions/p4_tests/p4_14/compile_only/14-MultipleActionsInAContainer.p4
)

p4c_add_xfail_reason("tofino"
  "PHV allocation was not successful|PHV fitting failed"
  extensions/p4_tests/p4_14/compile_only/04-FullPHV3.p4
  testdata/p4_14_samples/05-FullTPHV.p4
  testdata/p4_14_samples/06-FullTPHV1.p4
  testdata/p4_14_samples/08-FullTPHV3.p4
  extensions/p4_tests/p4_14/compile_only/20-SimpleTrillTwoStep.p4

  extensions/p4_tests/p4_14/compile_only/p4smith_regression/mask_slices_2.p4
  )

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
  "Conditional emit b.emit.* not supported"
  testdata/p4_16_samples/issue887.p4
)

p4c_add_xfail_reason("tofino"
  "error: Advancing by a non-constant distance is not supported on Tofino"
  testdata/p4_16_samples/issue1755-1-bmv2.p4
  )


p4c_add_xfail_reason("tofino"
  "[Tt]able .* is applied in multiple places, and the next-table information cannot correctly propagate"
  testdata/p4_16_samples/issue986-bmv2.p4
  )

p4c_add_xfail_reason("tofino"
  "table .* Cannot match on multiple fields using the LPM match type"
  testdata/p4_14_samples/issue60.p4
  )

# START: XFAILs with translation
# invalid tests, issue604.p4 is a v1.1 testcase
# P4-14 program can not define extern
p4c_add_xfail_reason("tofino"
  "P4_14 extern not fully supported"
  testdata/p4_14_samples/issue604.p4
  )

p4c_add_xfail_reason("tofino"
  "error: .*: no such field in standard_metadata"
  extensions/p4_tests/p4_14/bf_p4c_samples/sai_p4.p4
  )

p4c_add_xfail_reason("tofino"
  "Only compile-time constants are supported for hash base offset and max value"
  testdata/p4_14_samples/flowlet_switching.p4
  testdata/p4_16_samples/crc32-bmv2.p4
  testdata/p4_16_samples/flowlet_switching-bmv2.p4
  )

# ingress parser need access pkt_length
p4c_add_xfail_reason("tofino"
  "error: standard_metadata.packet_length is not accessible in the ingress pipe"
  testdata/p4_14_samples/queueing.p4
  )

# resubmit size is 32 bytes which exceeds max size for tofino (8 bytes).
p4c_add_xfail_reason("tofino"
  "__resubmit_header_t digest limited to 64 bits"
  extensions/p4_tests/p4_14/compile_only/13-ResubmitMetadataSize.p4
  )

# END: XFAILs with translation

p4c_add_xfail_reason("tofino"
  "error: .*: action spanning multiple stages."
  extensions/p4_tests/p4_14/compile_only/p4smith_regression/murdoch_0.p4
  extensions/p4_tests/p4_14/compile_only/p4smith_regression/photostats_0.p4
  extensions/p4_tests/p4_14/compile_only/p4smith_regression/sidestepped_0.p4
  testdata/p4_14_samples/action_inline.p4
  )

p4c_add_xfail_reason("tofino"
    "error: : Currently in p4c, the table sucker_0 cannot perform a range match on key ingress::suitably.litheness as the key does not fit in under 5 PHV nibbles"
  extensions/p4_tests/p4_14/compile_only/p4smith_regression/licensee_0.p4
)

# p4smith regression XFAILs

# real error. fails because gateway condition too complex and cannot fit in a TCAM.
p4c_add_xfail_reason("tofino"
  "error.*condition too complex"
  extensions/p4_tests/p4_14/compile_only/p4smith_regression/grab_0.p4
  testdata/p4_16_samples/issue1544-1-bmv2.p4
  testdata/p4_16_samples/issue1544-2-bmv2.p4
)

p4c_add_xfail_reason("tofino"
  "error: .*: could not infer a width"
  extensions/p4_tests/p4_14/compile_only/p4smith_regression/chauncey_0.p4
  extensions/p4_tests/p4_14/compile_only/p4smith_regression/corroding_0.p4
  extensions/p4_tests/p4_14/compile_only/p4smith_regression/undercut_0.p4
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
  extensions/p4_tests/p4_14/compile_only/p4smith_regression/dup_decl_random.p4
  extensions/p4_tests/p4_14/compile_only/p4smith_regression/jenningss_0.p4
)

p4c_add_xfail_reason("tofino"
  ".* duplicates .*"
  extensions/p4_tests/p4_14/compile_only/p4smith_regression/dup_decl_clone.p4
  extensions/p4_tests/p4_14/compile_only/p4smith_regression/dup_decl_struct.p4
)

# BRIG-924
# Compiler Bug: unable to reference global instance from non-control block
p4c_add_xfail_reason("tofino"
  "Unable to reference global instance .* from non-control block"
  extensions/p4_tests/p4_14/compile_only/p4smith_regression/popularity_0.p4
)

# expected failure -- rng must be on hit path
p4c_add_xfail_reason("tofino"
  "action requires rng.*hit pathway.*driver can only currently program the miss pathway"
  extensions/p4_tests/p4_14/compile_only/p4smith_regression/hash_table_column_duplicated.p4
  extensions/p4_tests/p4_14/compile_only/p4smith_regression/metadata_dependency.p4
)

p4c_add_xfail_reason("tofino"
  "Cannot extract field .* from .* which has type .*"
  testdata/p4_16_samples/issue1210.p4
)

p4c_add_xfail_reason("tofino"
  "Number of fields .* in initializer different than number of fields"
  testdata/p4_16_samples/issue2303.p4
)

# This test attempts to match on a field of `error` type.
p4c_add_xfail_reason("tofino"
  "PHV details for .* not found"
  testdata/p4_16_samples/issue1062-1-bmv2.p4
  testdata/p4_16_samples/issue1062-bmv2.p4
)

# BRIG-934: this issue is not resolved, need fix in ConvertEnums.
p4c_add_xfail_reason("tofino"
  "condition expression too complex"
  testdata/p4_16_samples/issue1325-bmv2.p4
)

# BRIG-934
p4c_add_xfail_reason("tofino"
  "Found extract ingress::"
  testdata/p4_16_samples/issue510-bmv2.p4
  testdata/p4_16_samples/parser-unroll-test10.p4
)

p4c_add_xfail_reason("tofino"
  "error: standard_metadata.mcast_grp is not accessible in the egress pipe"
  extensions/p4_tests/p4_16/bf_p4c_samples/v1model-special-ops-bmv2.p4
  testdata/p4_16_samples/ipv6-switch-ml-bmv2.p4
  )

p4c_add_xfail_reason("tofino"
  "The random declaration .* max size must be a power of two"
  testdata/p4_16_samples/issue1517-bmv2.p4
)

# test program error
p4c_add_xfail_reason("tofino"
  "The random declaration .* min size must be zero"
  extensions/p4_tests/p4_14/compile_only/p4smith_regression/perusal_0.p4
)

# Negative test. >66 bytes of ternary match key fields used.
p4c_add_xfail_reason("tofino"
  "error.*Ternary table.*uses.*as ternary match key. Maximum number of bits allowed is.*"
  extensions/p4_tests/p4_16/compile_only/too_many_ternary_match_key_bits.p4
)

p4c_add_xfail_reason("tofino"
  "error.*This program violates action constraints imposed by Tofino.|Trivial allocator has found unsatisfiable constraints"
  extensions/p4_tests/p4_16/compile_only/multi-constraint.p4
)

p4c_add_xfail_reason("tofino"
  "error.*This program violates action constraints imposed by Tofino."
# Negative tests for violation of action constraints.
  extensions/p4_tests/p4_14/compile_only/action_conflict_1.p4
  extensions/p4_tests/p4_14/compile_only/action_conflict_3.p4
  extensions/p4_tests/p4_14/compile_only/action_conflict_7.p4
)

p4c_add_xfail_reason("tofino"
  "This program violates action constraints imposed by Tofino|Trivial allocator has found unsatisfiable constraints"
  extensions/p4_tests/p4_16/ptf/int_transit.p4 # ACTION_CANNOT_BE_SYNTHESIZED
)

p4c_add_xfail_reason("tofino"
  "This program violates action constraints imposed by Tofino|ACTION_CANNOT_BE_SYNTHESIZED"
  testdata/p4_16_samples/strength3.p4
  testdata/p4_16_samples/strength6.p4
  testdata/p4_16_samples/issue1713-bmv2.p4
)

p4c_add_xfail_reason("tofino"
  "Unsupported type header_union U"
  testdata/p4_16_samples/header-bool-bmv2.p4
)

# Errors because pa_container_size pragmas used in these tests cannot be satisfy all constraints.
p4c_add_xfail_reason("tofino"
  "Cannot find a slicing to satisfy @pa_container_size|NO_SLICING_FOUND"
  extensions/p4_tests/p4_16/compile_only/ssub_illegal_pack.p4
  )

p4c_add_xfail_reason("tofino"
  "Currently in p4c, any table using an action profile is required to use the same actions, and the following actions don't appear in all table using the action profile"
  testdata/p4_16_samples/psa-action-profile4.p4
  testdata/p4_16_samples/psa-example-dpdk-varbit-bmv2.p4
  )

# Valid XFAIL
p4c_add_xfail_reason("tofino"
  "extern .* does not have method matching this call"
  testdata/p4_16_samples/psa-example-dpdk-counter.p4
  )

# BRIG-604
p4c_add_xfail_reason("tofino"
  "Compiler Bug.*Operand.*of instruction.*operating on container.*must be a PHV"
  extensions/p4_tests/p4_16/compile_only/deparse-zero-clustering.p4
  testdata/p4_16_samples/issue983-bmv2.p4
  )

p4c_add_xfail_reason("tofino"
  "error: .*: declaration not found"
  testdata/p4_16_samples/issue2201-bmv2.p4
  testdata/p4_16_samples/action_profile-bmv2.p4
  testdata/p4_16_samples/issue1768-bmv2.p4
  testdata/p4_16_samples/issue297-bmv2.p4
  # EliminateTypeDef pass does not work properly?
  testdata/p4_16_samples/issue677-bmv2.p4
  # We fail to translate `generate_digest()`.
  testdata/p4_14_samples/issue1058.p4
  # shared register between ingress and egress is not supported
  testdata/p4_16_samples/issue1097-2-bmv2.p4
  testdata/p4_16_samples/std_meta_inlining.p4
  # no support for checksum verify/update
  testdata/p4_16_samples/checksum2-bmv2.p4
  testdata/p4_16_samples/checksum3-bmv2.p4
  # no support for parser_error
  testdata/p4_16_samples/parser_error-bmv2.p4
  # Checksum16 is deprecated
  extensions/p4_tests/p4_16/stf/ipv4_options.p4
  # We fail to translate `standard_metadata.instance_type`.
  testdata/p4_14_samples/packet_redirect.p4
  # truncate is not supported in tna
  testdata/p4_14_samples/truncate.p4
  testdata/p4_16_samples/action_profile_max_group_size_annotation.p4
  testdata/p4_16_samples/issue1824-bmv2.p4
  testdata/p4_16_samples/p4rt_digest_complex.p4
  # no support for log_msg
  testdata/p4_16_samples/logging-bmv2.p4
  # new tests added to p4c
  testdata/p4_16_samples/test-parserinvalidargument-error-bmv2.p4
  # error: eg_intr_md_from_parser: declaration not found (2023-05-19 p4c update)
  testdata/p4_16_samples/psa-parser-error-test-bmv2.p4
  )

p4c_add_xfail_reason("tofino"
   "Assignment source cannot be evaluated in the parser"
   testdata/p4_16_samples/issue1001-bmv2.p4
)

# checksum only support bit<16> output
p4c_add_xfail_reason("tofino"
  "Cannot unify type"
  extensions/p4_tests/p4_14/compile_only/p4smith_regression/gradations_0.p4
  extensions/p4_tests/p4_14/compile_only/p4smith_regression/soured_0.p4
  extensions/p4_tests/p4_14/compile_only/p4smith_regression/tofino-bug-1.p4
  extensions/p4_tests/p4_14/compile_only/p4smith_regression/tofino-bug-5.p4
)

# broken tests that don't set egress_spec
p4c_add_xfail_reason("tofino"
  ".* expected packet.* on port .* not seen"
  testdata/p4_16_samples/issue447-bmv2.p4
  testdata/p4_16_samples/checksum1-bmv2.p4
  #testdata/p4_16_samples/issue1025-bmv2.p4
  testdata/p4_16_samples/issue2147-bmv2.p4
  testdata/p4_16_samples/issue2176-bmv2.p4
  testdata/p4_16_samples/issue2225-bmv2.p4
  testdata/p4_16_samples/issue2383-bmv2.p4
  testdata/p4_16_samples/issue2375-1-bmv2.p4
  testdata/p4_16_samples/issue2375-bmv2.p4
  testdata/p4_16_samples/issue2392-bmv2.p4
)
p4c_add_xfail_reason("tofino"
  "PHV allocation was not successful|NO_VALID_SC_ALLOC_ALIGNMENT"
  testdata/p4_16_samples/issue1025-bmv2.p4
)

p4c_add_xfail_reason("tofino"
  ".* expected packet on port .* not seen"
  testdata/p4_16_samples/table-entries-range-bmv2.p4
)

p4c_add_xfail_reason("tofino"
  "unexpected packet output on port .*"
  testdata/p4_16_samples/table-entries-priority-bmv2.p4
)

p4c_add_xfail_reason("tofino"
  "longer than expected"
  testdata/p4_16_samples/table-entries-exact-ternary-bmv2.p4
  testdata/p4_16_samples/table-entries-optional-bmv2.p4
  testdata/p4_16_samples/table-entries-ternary-bmv2.p4
)

p4c_add_xfail_reason("tofino"
  "standard_metadata.* is not accessible in the ingress pipe"
  testdata/p4_14_samples/p414-special-ops.p4
)

p4c_add_xfail_reason("tofino"
  "use of varbit field is only supported in parser and deparser currently"
  testdata/p4_16_samples/equality-bmv2.p4
)

p4c_add_xfail_reason("tofino"
  "error: .*: cannot assign varbit field."
  testdata/p4_16_samples/issue447-5-bmv2.p4
)

p4c_add_xfail_reason("tofino"
  "error: .*: cannot assign header that contains a varbit field."
  testdata/p4_16_samples/equality-varbit-bmv2.p4
)

p4c_add_xfail_reason("tofino"
  "multiple varbit fields in a parser state are currently unsupported"
  testdata/p4_16_samples/issue447-1-bmv2.p4
  testdata/p4_14_samples/issue576.p4
)

p4c_add_xfail_reason("tofino"
  "Assignment source cannot be evaluated in the parser"
  testdata/p4_14_samples/TLV_parsing.p4
  testdata/p4_16_samples/parser-unroll-test1.p4
)

p4c_add_xfail_reason("tofino"
  "Varbit field size expression evaluates to non byte-aligned value"
  # unbounded varbit expr
  testdata/p4_16_samples/issue447-2-bmv2.p4
  testdata/p4_16_samples/issue447-3-bmv2.p4
  testdata/p4_16_samples/issue447-4-bmv2.p4
)

# varbit related ends

# Expected failure
p4c_add_xfail_reason("tofino"
  "error: standard_metadata.packet_length is not accessible in the ingress pipe"
  testdata/p4_14_samples/p414-special-ops-2-bmv2.p4
  testdata/p4_14_samples/p414-special-ops-3-bmv2.p4
)

# negative test.
p4c_add_xfail_reason("tofino"
  "Not a phv field in the lpf execute"
  extensions/p4_tests/p4_16/compile_only/neg_test_1_lpf_constant_param.p4
)

p4c_add_xfail_reason("tofino"
  "error: Use of uninitialized parser value"
  # unable to resolve "lookahead" expression in resolve_parser_values.cpp
  testdata/p4_16_samples/issue1409-bmv2.p4
  testdata/p4_14_samples/issue2196.p4
  # p4c update 2021-11-08
  testdata/p4_16_samples/parser-unroll-test6.p4
)

p4c_add_xfail_reason("tofino"
  "error: Unable to resolve extraction source. This is likely due to the source having no absolute offset from the state"
  extensions/p4_tests/p4_16/compile_only/simple_l3_mcast.p4
)

p4c_add_xfail_reason("tofino"
  "Field clone_spec is not a member of structure struct standard_metadata"
  extensions/p4_tests/p4_16/compile_only/clone-bmv2-i2e-and-e2e.p4
  extensions/p4_tests/p4_16/compile_only/clone-bmv2.p4
)

p4c_add_xfail_reason("tofino"
  "error: Assignment source cannot be evaluated in the parser"
  testdata/p4_16_samples/issue1937-2-bmv2.p4
  # p4c update 2022-12-01
  testdata/p4_16_samples/parser-unroll-test9.p4
)

p4c_add_xfail_reason("tofino"
  "error: Tofino does not support nested checksum updates"
  extensions/p4_tests/p4_14/stf/update_checksum_7.p4
  extensions/p4_tests/p4_14/stf/update_checksum_12.p4
  extensions/p4_tests/p4_14/ptf/inner_checksum_l4.p4
  extensions/p4_tests/p4_14/compile_only/p4smith_regression/shillings_0.p4
)

# Requires Pipe prefix support to avoid duplicate names
p4c_add_xfail_reason("tofino"
  "error: Found .* duplicate name.* in the P4Info"
  extensions/p4_tests/p4_16/compile_only/multiple_apply2.p4
)

# program error
p4c_add_xfail_reason("tofino"
  "Attached object .* in table .* is executed in some actions and not executed in others."
  testdata/p4_16_samples/psa-counter4.p4
  testdata/p4_16_samples/psa-meter5.p4
  testdata/p4_16_samples/psa-meter4.p4
)

p4c_add_xfail_reason("tofino"
  # 2023-03-17 update
  " Header fields cannot be used in wide arithmetic ops"
  testdata/p4_16_samples/nonstandard_table_names-bmv2.p4
)

p4c_add_xfail_reason("tofino"
  #"header fields cannot be used in wide arithmetic ops"
  "error: Expression [(]bit<32>[)][(]bit<9>[)]ig_intr_md.ingress_port is too complex to handle"
  testdata/p4_16_samples/psa-recirculate-no-meta-bmv2.p4
)

# no support for runtime-variable indexing
p4c_add_xfail_reason("tofino"
  "For Tofino, Index of the header stack.*has to be a const value and can't be a variable.*"
  testdata/p4_16_samples/runtime-index-bmv2.p4
  testdata/p4_16_samples/runtime-index-2-bmv2.p4
  testdata/p4_16_samples/predication_issue_2.p4
  testdata/p4_16_samples/issue2726-bmv2.p4
  testdata/p4_16_samples/issue1989-bmv2.p4
  # p4c update 2021-12-06
  testdata/p4_16_samples/control-hs-index-test1.p4
  testdata/p4_16_samples/control-hs-index-test2.p4
  testdata/p4_16_samples/control-hs-index-test3.p4
  testdata/p4_16_samples/control-hs-index-test4.p4
  testdata/p4_16_samples/control-hs-index-test5.p4
  testdata/p4_16_samples/control-hs-index-test6.p4
)

# select ranges not supported
p4c_add_xfail_reason("tofino"
  "error: Ran out of parser match registers"
  testdata/p4_16_samples/pvs-struct-3-bmv2.p4
)

if (NOT TEST_ALT_PHV_ALLOC)
    p4c_add_xfail_reason("tofino"
      "error: Ran out of tcam space in ingress parser"
      extensions/p4_tests/p4_16/compile_only/simple_l3_nexthop_ipv6_options.p4
    )
endif()

p4c_add_xfail_reason("tofino"
  "Not all applies of table .* are mutually exclusive"
  testdata/p4_16_samples/psa-table-hit-miss.p4
  testdata/p4_16_samples/issue2344.p4
  testdata/p4_16_samples/psa-action-selector4.p4
  testdata/p4_16_samples/psa-dpdk-table-key-consolidation-if.p4
  testdata/p4_16_samples/psa-dpdk-table-key-consolidation-if-1.p4
)

p4c_add_xfail_reason("tofino"
  "Checksum destination field .* is not byte-aligned in the header. Checksum engine is unable to update a field if it is not byte-aligned"
  extensions/p4_tests/p4_14/compile_only/p4smith_regression/checksum_align.p4
)

p4c_add_xfail_reason("tofino"
  "All fields within the same byte-size chunk of the header must have the same 2 byte-alignment in the checksum list. Checksum engine is unable to read .* for .* checksum update"
  extensions/p4_tests/p4_16/compile_only/checksum_neg_test1.p4
)

p4c_add_xfail_reason("tofino"
  "All fields within same byte of header must participate in the checksum list. Checksum engine is unable to read .* for .* checksum update"
  extensions/p4_tests/p4_16/compile_only/checksum_neg_test2.p4
)

p4c_add_xfail_reason("tofino"
  "Each field's bit alignment in the packet should be equal to that in the checksum list. Checksum engine is unable to read .* for .* checksum update"
  extensions/p4_tests/p4_16/compile_only/checksum_neg_test3.p4
)

p4c_add_xfail_reason("tofino"
  "Compiler Bug.*: The compiler failed in slicing the following group of fields related by parser alignment and MAU constraints"
  extensions/p4_tests/p4_14/compile_only/19-SimpleTrill.p4
)

# P4 program error
p4c_add_xfail_reason("tofino"
  ".* @dynamic_table_key_masks annotation only permissible with exact matches"
  extensions/p4_tests/p4_16/compile_only/dkm_invalid.p4
)

#new p4c tests that fail
p4c_add_xfail_reason("tofino"
  "Compiler Bug.*: expected a method call"
  testdata/p4_16_samples/issue2221-bmv2.p4
  testdata/p4_16_samples/issue2343-bmv2.p4
)

p4c_add_xfail_reason("tofino"
  "1 expected packet on port 0 not seen"
  testdata/p4_16_samples/issue2170-bmv2.p4
)

p4c_add_xfail_reason("tofino"
  "error: .*: action spanning multiple stages"
  testdata/p4_16_samples/nested_if_lvalue_dependencies.p4
  testdata/p4_16_samples/nested_if_else.p4
  testdata/p4_16_samples/proliferation1.p4
)

p4c_add_xfail_reason("tofino"
  "Compiler Bug.*: .*expected a method call"
  testdata/p4_16_samples/issue2287-bmv2.p4
  testdata/p4_16_samples/issue2205-bmv2.p4
  testdata/p4_16_samples/issue2488-bmv2.p4
)

p4c_add_xfail_reason("tofino"
  "Compiler Bug.*: .*too many side-effect in one expression"
  testdata/p4_16_samples/issue2289.p4
)

p4c_add_xfail_reason("tofino"
  "Compiler Bug.*: .*unexpected statement with call"
  testdata/p4_16_samples/issue2205-1-bmv2.p4
  testdata/p4_16_samples/issue3001-1.p4
  # p4c update 2022-05-09
  testdata/p4_16_samples/issue2291-bmv2.p4
  testdata/p4_16_samples/issue2355.p4
)

p4c_add_xfail_reason("tofino"
  "error:.*Conditional execution in actions unsupported on this target"
  testdata/p4_16_samples/issue2359.p4
)

p4c_add_xfail_reason("tofino"
  "error:.*Registers support only calls or assignments of the following forms"
  testdata/p4_16_samples/psa-register-complex-bmv2.p4
)

p4c_add_xfail_reason("tofino"
  "Varbit field size expression evaluates to .* packet.extract"
  testdata/p4_16_samples/issue1879-bmv2.p4
)

p4c_add_xfail_reason("tofino"
  "error: : source of modify_field invalid"
  extensions/p4_tests/p4_16/stf/arith_compare.p4
)

# Negative test, expected xfail
p4c_add_xfail_reason("tofino"
  "error: table .*: Number of partitions are specified for table .* but the partition index .* is not found"
  extensions/p4_tests/p4_16/compile_only/atcam_match_wide1-neg.p4
)

# PSA on tofino new failures
p4c_add_xfail_reason("tofino"
  "Cannot unify type"
  testdata/p4_16_samples/psa-multicast-basic-2-bmv2.p4
  testdata/p4_16_samples/psa-unicast-or-drop-bmv2.p4
  testdata/p4_16_samples/psa-end-of-ingress-test-bmv2.p4
  # p4c update 2022-04-25
  testdata/p4_16_samples/psa-dpdk-struct-field.p4
  testdata/p4_16_samples/psa-dpdk-token-too-big.p4
  testdata/p4_16_samples/psa-dpdk-checksum-arg-header.p4
)

# digest fields related failures or expected to fail.
p4c_add_xfail_reason("tofino"
  "invalid SuperCluster was formed"
  # Expected to fail, which means that constraint conflicts are being correctly detected.
  extensions/p4_tests/p4_14/compile_only/01-FlexCounter.p4
  extensions/p4_tests/p4_14/compile_only/03-VlanProfile.p4
)

p4c_add_xfail_reason("tofino"
  "error: .*: type Counter has no matching constructor"
  extensions/p4_tests/p4_16/ptf/large_indirect_count.p4
)

# p4c dd7c0eb1
p4c_add_xfail_reason("tofino"
  ".*error: Field.*header.*cannot have type.*"
  testdata/p4_16_samples/issue2345-multiple_dependencies.p4
  testdata/p4_16_samples/issue2345-2.p4
  testdata/p4_16_samples/predication_issue.p4
  testdata/p4_16_samples/issue2345-1.p4
  testdata/p4_16_samples/issue2345-with_nested_if.p4
)

# p4c 84467391
p4c_add_xfail_reason("tofino"
  "1 expected packet on port 0 not seen"
  testdata/p4_16_samples/issue2498-bmv2.p4
  testdata/p4_16_samples/issue2614-bmv2.p4
)

p4c_add_xfail_reason("tofino"
  "Inconsistent mirror selectors"
  extensions/p4_tests/p4_16/compile_only/mirror_5.p4
)

# p4c 7fbc2a4
p4c_add_xfail_reason("tofino"
  ".*error: The table .* with no key cannot have the action .*"
  extensions/p4_tests/p4_14/compile_only/p4smith_regression/mask_slices.p4
)

p4c_add_xfail_reason("tofino"
  "Internal compiler error. Please submit a bug report with your code."
  extensions/p4_tests/p4_14/compile_only/p4smith_regression/shrubs_0.p4
)

p4c_add_xfail_reason("tofino"
  "condition too complex"
  testdata/p4_16_samples/psa-e2e-cloning-basic-bmv2.p4
)

p4c_add_xfail_reason("tofino"
  "partly placed: table .*"
  extensions/p4_tests/p4_14/compile_only/p4smith_regression/utes_0.p4
)

p4c_add_xfail_reason("tofino"
  ".*error: Non-mutualy exclusive actions .* and .* both trying to use MyIC.reg"
  testdata/p4_16_samples/psa-register-read-write-2-bmv2.p4
)

# PSA_MeterColor_t
p4c_add_xfail_reason("tofino"
  "error: Cannot extract field .* from PSA_MeterColor_t which has type Type"
  testdata/p4_16_samples/psa-meter7-bmv2.p4
  testdata/p4_16_samples/psa-meter3.p4
  testdata/p4_16_samples/psa-example-dpdk-meter1.p4
  testdata/p4_16_samples/psa-example-dpdk-meter.p4
  testdata/p4_16_samples/psa-example-dpdk-externs.p4
  testdata/p4_16_samples/psa-example-dpdk-byte-alignment_1.p4
  testdata/p4_16_samples/psa-example-dpdk-byte-alignment_2.p4
  testdata/p4_16_samples/psa-example-dpdk-byte-alignment_3.p4
  testdata/p4_16_samples/psa-example-dpdk-byte-alignment_5.p4
  testdata/p4_16_samples/psa-example-dpdk-byte-alignment_6.p4
  testdata/p4_16_samples/psa-example-dpdk-byte-alignment_7.p4
  testdata/p4_16_samples/psa-example-dpdk-byte-alignment_8.p4
  testdata/p4_16_samples/psa-example-dpdk-byte-alignment_9.p4
)

# P4C update 2021-07-12
# At frontend because there is
# a MethodCallExpression that is not inside a BlockStatement
p4c_add_xfail_reason("tofino"
  "Null stat"
  testdata/p4_16_samples/issue2258-bmv2.p4
)

# This one fails beause we do not support multistage actions
p4c_add_xfail_reason("tofino"
  "action spanning multiple stages"
  testdata/p4_16_samples/issue2321.p4
)

p4c_add_xfail_reason("tofino"
  "unexpected statement with call"
  testdata/p4_16_samples/predication_issue_1.p4
)

p4c_add_xfail_reason("tofino"
  "expected a method call"
  testdata/p4_16_samples/predication_issue_3.p4
  testdata/p4_16_samples/predication_issue_4.p4
)

p4c_add_xfail_reason("tofino"
  "no definitions found for"
  testdata/p4_16_samples/issue2362-bmv2.p4
)
# P4C update 2021-07-12

# P4C update 2021-08-16
p4c_add_xfail_reason("tofino"
  "source of modify_field invalid"
  testdata/p4_16_samples/psa-dpdk-table-key-isValid2.p4
  testdata/p4_16_samples/psa-dpdk-table-key-isValid3.p4
  testdata/p4_16_samples/psa-dpdk-table-key-isValid4.p4
  testdata/p4_16_samples/psa-dpdk-table-key-isValid5.p4
  testdata/p4_16_samples/psa-dpdk-table-key-isValid6.p4
)
p4c_add_xfail_reason("tofino"
  "extern Checksum does not have method matching this call"
  testdata/p4_16_samples/internet_checksum1-bmv2.p4
  testdata/p4_16_samples/psa-example-parser-checksum.p4
  testdata/p4_16_samples/psa-example-dpdk-byte-alignment_4.p4
)

p4c_add_xfail_reason("tofino"
  "error: Unable to resolve extraction source. This is likely due to the source having no absolute offset from the state"
  testdata/p4_16_samples/parser-inline/parser-inline-test1.p4
  testdata/p4_16_samples/parser-inline/parser-inline-test2.p4
  testdata/p4_16_samples/parser-inline/parser-inline-test3.p4
  testdata/p4_16_samples/parser-inline/parser-inline-test4.p4
  testdata/p4_16_samples/parser-inline/parser-inline-test11.p4
  testdata/p4_16_samples/parser-inline/parser-inline-test12.p4
  parser-inline-opt/testdata/p4_16_samples/parser-inline/parser-inline-test1.p4
  parser-inline-opt/testdata/p4_16_samples/parser-inline/parser-inline-test2.p4
  parser-inline-opt/testdata/p4_16_samples/parser-inline/parser-inline-test3.p4
  parser-inline-opt/testdata/p4_16_samples/parser-inline/parser-inline-test4.p4
  parser-inline-opt/testdata/p4_16_samples/parser-inline/parser-inline-test11.p4
  parser-inline-opt/testdata/p4_16_samples/parser-inline/parser-inline-test12.p4
)
p4c_add_xfail_reason("tofino"
  "error: Current path with historic data usage has an intersection with a previously analyzed historic data path at node"
  parser-inline-opt/testdata/p4_16_samples/parser-inline/parser-inline-test8.p4
  parser-inline-opt/testdata/p4_16_samples/parser-inline/parser-inline-test9.p4
  parser-inline-opt/testdata/p4_16_samples/parser-inline/parser-inline-test10.p4
)
p4c_add_xfail_reason("tofino"
  "error: Field '__bfp4c_fields' of 'header __bfp4c_bridged_metadata_header' cannot have type 'struct fields'"
  testdata/p4_16_samples/parser-inline/parser-inline-test13.p4
  parser-inline-opt/testdata/p4_16_samples/parser-inline/parser-inline-test13.p4
)

# p4_14_nightly_tofino
p4c_add_xfail_reason("tofino"
  "error: add: action spanning multiple stages."
  extensions/p4_tests/p4_14/compile_only/p4smith_regression/vindemiatrixs_0.p4
)
p4c_add_xfail_reason("tofino"
  "error: : condition too complex"
  extensions/p4_tests/p4_14/compile_only/p4smith_regression/basseterre_0.p4
)

p4c_add_xfail_reason("tofino"
  "mismatch from expected"
  extensions/p4_tests/p4_14/stf/stateful6.p4
)
p4c_add_xfail_reason("tofino"
  "Compiler Bug: invalid SuperCluster was formed"
  extensions/p4_tests/p4_14/compile_only/cylinder_0.p4
  extensions/p4_tests/p4_14/compile_only/action_conflict_2.p4
)

# p4factory update
p4c_add_xfail_reason("tofino"
  "longer than expected"
  testdata/p4_16_samples/table-entries-ser-enum-bmv2.p4
)

p4c_add_xfail_reason("tofino"
  "AssertionError: Expected packet was not received"
  extensions/p4_tests/p4_14/ptf/sful_split1.p4
)

# P4C update 2021-10-19
p4c_add_xfail_reason("tofino"
  "error: Assignment source cannot be evaluated in the parser"
  testdata/p4_16_samples/invalid-hdr-warnings1.p4
)
p4c_add_xfail_reason("tofino"
  "Can only switch on table"
  testdata/p4_16_samples/invalid-hdr-warnings3-bmv2.p4
  testdata/p4_16_samples/issue3374.p4
  testdata/p4_16_samples/issue3650.p4
)

p4c_add_xfail_reason("tofino"
  "multi-assignment in parser"
  testdata/p4_14_samples/11-MultiTags.p4
)

# p4c update 02/2022
p4c_add_xfail_reason("tofino"
  "error: Inferred incompatible container alignments for field"
  testdata/p4_16_samples/bool_to_bit_cast.p4
)
p4c_add_xfail_reason("tofino"
  "error: Verify statement not supported"
  testdata/p4_16_samples/psa-dpdk-errorcode-2.p4
)

if (NOT TEST_ALT_PHV_ALLOC)
  # p4c update 03/03/2022 (new test)
  p4c_add_xfail_reason("tofino"
    "error: PHV allocation was not successful"
    testdata/p4_16_samples/structure-valued-expr-ok-1-bmv2.p4
  )
endif()

# p4c update (new test)
p4c_add_xfail_reason("tofino"
  "Conditions in an action must be simple comparisons of an action data parameter"
  testdata/p4_16_samples/psa-dpdk-flatten-local-struct.p4
)

# p4c update 04/26/2022 (new tests)
p4c_add_xfail_reason("tofino"
  "error: '[(]bit<.*>[)]"
  testdata/p4_16_samples/m_psa-dpdk-non-zero-arg-default-action-08.p4
  testdata/p4_16_samples/psa-dpdk-non-zero-arg-default-action-01.p4
  testdata/p4_16_samples/psa-dpdk-non-zero-arg-default-action-02.p4
  testdata/p4_16_samples/psa-dpdk-non-zero-arg-default-action-03.p4
  testdata/p4_16_samples/psa-dpdk-non-zero-arg-default-action-04.p4
  testdata/p4_16_samples/psa-dpdk-non-zero-arg-default-action-05.p4
  testdata/p4_16_samples/psa-dpdk-non-zero-arg-default-action-06.p4
  testdata/p4_16_samples/psa-dpdk-non-zero-arg-default-action-07.p4
  testdata/p4_16_samples/psa-dpdk-non-zero-arg-default-action-08.p4
  testdata/p4_16_samples/psa-dpdk-non-zero-arg-default-action-09.p4
  testdata/p4_16_samples/psa-dpdk-128bitCast.p4
)

# p4c update 2022-06-02
p4c_add_xfail_reason("tofino"
  "does not have method matching this call"
  testdata/p4_16_samples/psa-hash-06.p4
  testdata/p4_16_samples/psa-hash-07.p4
  testdata/p4_16_samples/psa-hash-08.p4
)
p4c_add_xfail_reason("tofino"
  "Null cTypeSpec"
  testdata/p4_16_samples/psa-hash-09.p4
  testdata/p4_16_samples/psa-hash-10.p4
)

# p4c update 2022-07-04
p4c_add_xfail_reason("tofino"
  "Unsupported architecture \"v1model\" for parser minimum depth enforcement"
  testdata/p4_16_samples/issue3394.p4
)

# p4c update 2022-08-01
# The error happens in FrontEnd pass TypeInference and is probably caused
# by different definitions in psa.p4 in bf-p4c (for Tofino) and in p4c
p4c_add_xfail_reason("tofino"
  "Cannot unify type 'PortId_t' with type 'bit<32>'"
  testdata/p4_16_samples/psa-subtract-inst1.p4
)

# p4c update 2022-08-09
p4c_add_xfail_reason("tofino"
  "Currently in p4c, the table .* cannot perform a range match on key .* as the key does not fit in under 5 PHV nibbles"
  testdata/p4_16_samples/psa-example-range-match.p4
)

# p4c update 2022-09-22 (new test)
p4c_add_xfail_reason("tofino"
  "Conditions in an action must be simple comparisons of an action data parameter"
  testdata/p4_16_samples/psa-dpdk-large-struct-fields.p4
)
p4c_add_xfail_reason("tofino"
  "Cannot unify type 'PortId_t' with type 'bit<32>'"
  testdata/p4_16_samples/psa-dpdk-hdr-field-non-align.p4
)

# p4c update 2022-10-10 (new tests)
p4c_add_xfail_reason("tofino"
  "The hash offset must be a power of 2 in a hash calculation"
  testdata/p4_16_samples/hashing-non-tuple-bmv2.p4
)

p4c_add_xfail_reason("tofino"
  "error: Unsupported type"
  testdata/p4_16_samples/parser-unroll-test8.p4
)

p4c_add_xfail_reason("tofino"
  "Currently in p4c, the table .* cannot perform a range match on key .* as the key does not fit in under 5 PHV nibbles"
  testdata/p4_16_samples/issue3550.p4
)

p4c_add_xfail_reason("tofino"
  "declaration not found"
  testdata/p4_16_samples/psa-dpdk-header-union-typedef.p4
)

# p4c update 2022-10-24 (new test)
p4c_add_xfail_reason("tofino"
  "Conditions in an action must be simple comparisons of an action data parameter"
  testdata/p4_16_samples/psa-dpdk-large-header-fields.p4
)

# p4c update 2022-11-07 (new tests)
p4c_add_xfail_reason("tofino"
  "Cannot extract field .* from PSA_MeterColor_t which has type .*"
  testdata/p4_16_samples/psa-example-dpdk-directmeter.p4
)

# p4c update 2022-11-21 (new tests)
p4c_add_xfail_reason("tofino"
  "error: Verify statement not supported"
  testdata/p4_16_samples/psa-dpdk-tmp-mask-align.p4
)
p4c_add_xfail_reason("tofino"
  "Cannot extract field .* from PSA_MeterColor_t which has type .*"
  testdata/p4_16_samples/psa-example-dpdk-meter-execute-err.p4
)

# p4c update 2022-12-19 (new tests)
p4c_add_xfail_reason("tofino"
  "Not all applies of table .* are mutually exclusive"
  testdata/p4_16_samples/psa-action-selector6.p4
)

p4c_add_xfail_reason("tofino"
  "mismatch from expected"
  extensions/p4_tests/p4_16/stf/parser_multi_write_checksum_verify_2.p4
)

# Failure due to old version of p4runtime installed in jarvis docker images -- fixed by
# updating p4runtime.  Can use PYTHONPATH=/mnt/build/_deps/p4runtime-src/py:$PYTHONPATH
p4c_add_xfail_reason("tofino"
  "google.protobuf.text_format.ParseError: .*:3 : Message type \"p4.config.v1.Table\" has no field named \"has_initial_entries\""
  extensions/p4_tests/p4_16/ptf/static_entries.p4
)

p4c_add_xfail_reason("tofino"
  "mismatch from expected(.*) at byte .*"
  extensions/p4_tests/p4_16/stf/varbit_constant.p4
)

# p4c update 2024-04-11 (new tests)
p4c_add_xfail_reason("tofino"
  "error: Action profile ActionProfile IngressI.ap on table IngressI.indirect does not have any action data"
  testdata/p4_16_samples/action_profile_sum_of_members_annotation.p4
)
