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
    testdata/p4_16_samples/table-entries-ser-enum-bmv2.p4
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
    testdata/p4_16_samples/subparser-with-header-stack-bmv2.p4
    )

  p4c_add_xfail_reason("tofino"
    "mismatch from expected(.*) at byte .*"
    # Needs some fixes to ternary static entries/gateway payload for TCAM
    extensions/p4_tests/p4_16/stf/p4c-2772-c.p4
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

  p4c_add_xfail_reason("tofino"
    "ERROR:PTF runner:Error when running PTF tests"
    smoketest_programs_hash_driven
    smoketest_programs_meters
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
  )

p4c_add_xfail_reason("tofino"
  "Action profile .* does not have any action data"
  extensions/p4_tests/p4_14/bf_p4c_samples/port_vlan_mapping.p4
  extensions/p4_tests/p4_14/compile_only/02-FlexCounterActionProfile.p4
  testdata/p4_14_samples/const_default_action.p4
  testdata/p4_14_samples/selector0.p4
  testdata/p4_16_samples/action_selector_shared-bmv2.p4
  ../glass/testsuite/p4_tests/tudarmstadt/COMPILER-743/case4181.p4
  ../glass/testsuite/p4_tests/tudarmstadt/COMPILER-743/case4181_fix.p4
  )


# BRIG-956, parser wide match
p4c_add_xfail_reason("tofino"
  "error.*Ran out of parser match registers for"
  testdata/p4_16_samples/issue995-bmv2.p4
  ../glass/testsuite/p4_tests/parde/COMPILER-368/out.p4
  testdata/p4_16_samples/v1model-p4runtime-most-types1.p4
  testdata/p4_16_samples/v1model-p4runtime-enumint-types1.p4
  )

p4c_add_xfail_reason("tofino"
  "Unsupported type argument for Value Set"
  testdata/p4_14_samples/parser_value_set2.p4
  testdata/p4_16_samples/pvs-nested-struct.p4
  )

p4c_add_xfail_reason("tofino"
  "Unsupported condition && in mirror.emit"
  extensions/p4_tests/p4_16/compile_only/p4c-1150-nested-ifs.p4
)

p4c_add_xfail_reason("tofino"
  "HashAlgorithm_t.CSUM16: Invalid enum tag"
  testdata/p4_14_samples/issue894.p4
)

p4c_add_xfail_reason("tofino"
  "the following .* not written in .* will be overwritten illegally"
  switch_msdc_l3
  )

p4c_add_xfail_reason("tofino"
  "error.*tofino supports up to 12 stages"
  extensions/p4_tests/p4_16/customer/extreme/p4c-1458-a.p4
  extensions/p4_tests/p4_16/customer/extreme/p4c-1797-1.p4
  extensions/p4_tests/p4_16/customer/arista/p4c-2534.p4
  extensions/p4_tests/p4_16/customer/arista/p4c-2143.p4
  extensions/p4_tests/p4_16/customer/arista/p4c-2189.p4
  extensions/p4_tests/p4_16/customer/arista/p4c-2191.p4
  extensions/p4_tests/p4_16/customer/arista/p4c-2257.p4
  extensions/p4_tests/p4_16/customer/arista/p4c-2378.p4
  extensions/p4_tests/p4-programs/internal_p4_14/clpm/clpm.p4
  extensions/p4_tests/p4-programs/internal_p4_14/fr_test/fr_test.p4
  extensions/p4_tests/p4-programs/internal_p4_14/netcache/netcache.p4
  ../glass/testsuite/p4_tests/arista/COMPILER-282/case1864.p4
  ../glass/testsuite/p4_tests/arista/COMPILER-347/switch_bug.p4
  ../glass/testsuite/p4_tests/arista/COMPILER-351/case2079.p4
  ../glass/testsuite/p4_tests/arista/COMPILER-353/case2088.p4
  ../glass/testsuite/p4_tests/arista/COMPILER-357/case2100.p4
  ../glass/testsuite/p4_tests/arista/COMPILER-358/case2110.p4
  ../glass/testsuite/p4_tests/arista/COMPILER-364/case2115.p4
  ../glass/testsuite/p4_tests/arista/COMPILER-414/case2387_1.p4
  ../glass/testsuite/p4_tests/arista/COMPILER-414/case2387.p4
  ../glass/testsuite/p4_tests/arista/COMPILER-415/case2386.p4
  ../glass/testsuite/p4_tests/arista/COMPILER-447/case2527.p4
  ../glass/testsuite/p4_tests/arista/COMPILER-448/case2526.p4
  ../glass/testsuite/p4_tests/arista/COMPILER-451/case2537.p4
  ../glass/testsuite/p4_tests/arista/COMPILER-477/case2602.p4
  ../glass/testsuite/p4_tests/arista/COMPILER-483/case2619.p4
  ../glass/testsuite/p4_tests/arista/COMPILER-503/case2678.p4
  ../glass/testsuite/p4_tests/arista/COMPILER-505/case2690.p4
  ../glass/testsuite/p4_tests/arista/COMPILER-548/case2895.p4
  ../glass/testsuite/p4_tests/arista/COMPILER-650/case3597.p4
  ../glass/testsuite/p4_tests/arista/COMPILER-666/case3696.p4
  ../glass/testsuite/p4_tests/arista/COMPILER-725/comp_725.p4
  ../glass/testsuite/p4_tests/arista/DRV-543/case2499.p4
  ../glass/testsuite/p4_tests/netscout/P4C-1605/filter_bf_p414.p4
  ../glass/testsuite/p4_tests/phv/COMPILER-733/ipu_ingress.p4
  ../glass/testsuite/p4_tests/ucloud/COMPILER-1042/uxr.p4
  ../glass/testsuite/p4_tests/ucloud/COMPILER-1045/case6975.p4
  ../glass/testsuite/p4_tests/zte/COMPILER-594/comp594.p4
)

p4c_add_xfail_reason("tofino"
  "error.*tofino supports up to 12 stages|./p4c TIMEOUT"
  ../glass/testsuite/p4_tests/mau/COMPILER-362/icmp_typecode.p4
  ../glass/testsuite/p4_tests/phv/COMPILER-243/comp243.p4
  ../glass/testsuite/p4_tests/phv/COMPILER-546/switch_comp546.p4
  extensions/p4_tests/p4_16/customer/arista/p4c-2012.p4
  extensions/p4_tests/p4_16/customer/arista/p4c-2178.p4
  extensions/p4_tests/p4_16/customer/arista/p4c-2257.p4
)

p4c_add_xfail_reason("tofino"
  "Internal compiler error"
  ../glass/testsuite/p4_tests/ixia/COMPILER-549/case2898.p4
)

p4c_add_xfail_reason("tofino"
  "Compiler Bug.*: Metadata initialization analysis incorrect.  Live ranges .* overlap"
  ../glass/testsuite/p4_tests/phv/COMPILER-706/terminate_parsing.p4
)

# timeout
p4c_add_xfail_reason("tofino"
  "PHV allocation was not successful|./p4c TIMEOUT"
  ../glass/testsuite/p4_tests/phv/COMPILER-828/meta_init_problem.p4
  extensions/p4_tests/p4_16/customer/extreme/p4c-2200.p4
)

p4c_add_xfail_reason("tofino"
  "Unimplemented .*: Split attached table with some match and some attached in the same stage, but not all in one stage"
  ../glass/testsuite/p4_tests/fox/COMPILER-957/case6123.p4
  extensions/p4_tests/p4_16/compile_only/missing_checksumID.p4
)

p4c_add_xfail_reason("tofino"
  "Compiler Bug.*: Conflicting alloc in the action data xbar between .*"
  ../glass/testsuite/p4_tests/phv/COMPILER-587/l4l.p4
)

p4c_add_xfail_reason("tofino"
  "error.*Ran out of parser match registers for"
  ../glass/testsuite/p4_tests/mau/COMPILER-1068/comp_1068.p4
  extensions/p4_tests/p4_16/compile_only/missing_checksumID.p4
)

# P4C-1400, P4C-1123
p4c_add_xfail_reason("tofino"
  "error: constant value.*too large for stateful alu"
  extensions/p4_tests/p4-programs/internal_p4_14/mau_test/mau_test.p4
)

p4c_add_xfail_reason("tofino"
  "Tofino requires byte-aligned headers"
  extensions/p4_tests/p4_16/compile_only/tagalong_mdinit_switch.p4
  # Brig failure: No byte multiple requirement for a metadata header
  ../glass/testsuite/p4_tests/arista/COMPILER-1181/case8969.p4
)

p4c_add_xfail_reason("tofino"
  "error: Use of uninitialized parser value"
  testdata/p4_16_samples/issue692-bmv2.p4
  testdata/p4_16_samples/parser-if.p4
)

p4c_add_xfail_reason("tofino"
  "error.*Field is extracted in the parser into multiple containers"
  extensions/p4_tests/p4_16/customer/arista/p4c-1494.p4
)

p4c_add_xfail_reason("tofino"
  "Did not receive pkt on 2"
  smoketest_switch_dtel_int_spine_dtel_INTL45_Transit_DoDTest
  smoketest_switch_dtel_int_spine_dtel_MirrorOnDropDoDTest
  smoketest_switch_dtel_int_spine_dtel_QueueReport_DoD_Test
  )

p4c_add_xfail_reason("tofino"
  "A packet was received on device"
  smoketest_switch_ent_dc_general_egress_acl
  )

p4c_add_xfail_reason("tofino"
# Fail on purpose due to indirect tables not being mutually exclusive
  "table .* and table .* cannot share .*"
  extensions/p4_tests/p4_14/compile_only/action_profile_next_stage.p4
  extensions/p4_tests/p4_14/compile_only/action_profile_not_shared.p4
  testdata/p4_14_samples/12-Counters.p4
  testdata/p4_14_samples/13-Counters1and2.p4
  ../glass/testsuite/p4_tests/arista/COMPILER-235/vag1662.p4
  testdata/p4_16_samples/psa-action-profile3.p4
  )

p4c_add_xfail_reason("tofino"
  "error.*condition too complex"
  extensions/p4_tests/p4_14/compile_only/07-MacAddrCheck.p4
  extensions/p4_tests/p4_14/compile_only/08-MacAddrCheck1.p4
  extensions/p4_tests/p4_14/compile_only/p4smith_regression/kindlings_0.p4
  testdata/p4_16_samples/issue1544-bmv2.p4
  testdata/p4_16_samples/issue2148.p4
  ../glass/testsuite/p4_tests/arista/COMPILER-588/comp588dce.p4
  ../glass/testsuite/p4_tests/arista/COMPILER-818/case4954_new_fail.p4
  )

# BRIG_132
p4c_add_xfail_reason("tofino"
  "Unsupported type header_union"
  testdata/p4_16_samples/bvec_union-bmv2.p4
  testdata/p4_16_samples/issue1897-bmv2.p4
  testdata/p4_16_samples/issue561-1-bmv2.p4
  testdata/p4_16_samples/issue561-2-bmv2.p4
  testdata/p4_16_samples/issue561-3-bmv2.p4
  testdata/p4_16_samples/union-bmv2.p4
  testdata/p4_16_samples/union-valid-bmv2.p4
  testdata/p4_16_samples/union1-bmv2.p4
  testdata/p4_16_samples/union2-bmv2.p4
  testdata/p4_16_samples/union3-bmv2.p4
  testdata/p4_16_samples/union4-bmv2.p4
  )

p4c_add_xfail_reason("tofino"
  "Conditions in an action must be simple comparisons of an action data parameter"
  testdata/p4_16_samples/issue1412-bmv2.p4
  testdata/p4_16_samples/issue420.p4
  testdata/p4_16_samples/issue2248.p4
)

p4c_add_xfail_reason("tofino"
  "The meter .* requires either an idletime or stats address bus"
  testdata/p4_14_samples/hash_action_two_same.p4
)

p4c_add_xfail_reason("tofino"
  "This action requires hash, which can only be done through the hit pathway"
  extensions/p4_tests/p4_14/compile_only/test_config_101_switch_msdc.p4
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
  extensions/p4_tests/p4_16/compile_only/p4c-2056.p4
  )

p4c_add_xfail_reason("tofino"
  "error: : shift count must be a constant in"
  testdata/p4_16_samples/arith3-bmv2.p4
  testdata/p4_16_samples/arith4-bmv2.p4
  testdata/p4_16_samples/arith5-bmv2.p4
  testdata/p4_16_samples/issue2190.p4
  )

p4c_add_xfail_reason("tofino"
  "Exiting with SIGSEGV"
  # Same Name Conversion Bug
  extensions/p4_tests/p4_14/compile_only/shared_names.p4
  )

p4c_add_xfail_reason("tofino"
  "The hash offset must be a power of 2 in a hash calculation"
  testdata/p4_16_samples/issue1049-bmv2.p4
)

p4c_add_xfail_reason("tofino"
  "Both .* require the .* address hardware, and cannot be on the same table"
  testdata/p4_14_samples/counter.p4
)

p4c_add_xfail_reason("tofino"
  "condition too complex"
  testdata/p4_16_samples/psa-unicast-or-drop-bmv2.p4
  testdata/p4_16_samples/psa-unicast-or-drop-corrected-bmv2.p4
)

p4c_add_xfail_reason("tofino"
  "Unknown command mc_mgrp_create"
  testdata/p4_16_samples/psa-multicast-basic-corrected-bmv2.p4
  testdata/p4_16_samples/psa-multicast-basic-bmv2.p4
)

p4c_add_xfail_reason("tofino"
  "SelectExpression: Cannot unify type int with PortIdUint_t"
  extensions/p4_tests/p4_16/stf/onlab_packet_io.p4
  extensions/p4_tests/p4_16/fabric-psa/fabric.p4
)

p4c_add_xfail_reason("tofino"
    "Conditions in an action must be simple comparisons of an action data parameter"
    testdata/p4_16_samples/issue-2123-3-bmv2.p4
    testdata/p4_16_samples/issue-2123-2-bmv2.p4
)

p4c_add_xfail_reason("tofino"
  "Expected type T in digest to be a typeName"
  testdata/p4_16_samples/issue430-1-bmv2.p4
  )

p4c_add_xfail_reason("tofino"
  "The input .* cannot be found on the hash input|./p4c TIMEOUT"
  ../glass/testsuite/p4_tests/phv/COMPILER-724/comp_724.p4
)

p4c_add_xfail_reason("tofino"
  "In checksum update list, fields before .* do not add up to a multiple of 8 bits. Total bits until .* : .*"
  extensions/p4_tests/p4_14/compile_only/p4smith_regression/but_0.p4
  extensions/p4_tests/p4_14/compile_only/p4smith_regression/mariano_0.p4
)

p4c_add_xfail_reason("tofino"
  "PHV allocation was not successful"
  extensions/p4_tests/p4_14/compile_only/04-FullPHV3.p4
  testdata/p4_14_samples/05-FullTPHV.p4
  testdata/p4_14_samples/06-FullTPHV1.p4
  testdata/p4_14_samples/08-FullTPHV3.p4
  testdata/p4_16_samples/issue1713-bmv2.p4
  testdata/p4_16_samples/strength6.p4

  # Expected to fail, which means that action analysis is working correctly.
  extensions/p4_tests/p4_14/compile_only/14-MultipleActionsInAContainer.p4
  extensions/p4_tests/p4_14/compile_only/action_conflict_2.p4

  # Expected to fail, until we have better user-facing messages.
  extensions/p4_tests/p4_16/stf/cast_widening_add.p4

  # Expected to fail, which means that constraint conflicts are being correctly detected.
  extensions/p4_tests/p4_14/compile_only/01-FlexCounter.p4
  extensions/p4_tests/p4_14/compile_only/03-VlanProfile.p4
  extensions/p4_tests/p4_14/compile_only/mau_test_neg_test.p4

  # p4smith mask issues - P4C-2093
  extensions/p4_tests/p4_14/compile_only/p4smith_regression/mask_slices_2.p4
  extensions/p4_tests/p4_14/compile_only/p4smith_regression/mask_slices.p4

  # broke by flexible packing PR
  extensions/p4_tests/p4_16/compile_only/lrn1.p4

  ba101_20-simple_l2

  # P4C-1778
  # fit if
  ../glass/testsuite/p4_tests/arista/COMPILER-1168/comp_1168.p4
  ../glass/testsuite/p4_tests/arista/COMPILER-1169/case8847.p4
  ../glass/testsuite/p4_tests/arista/COMPILER-1189/case9294.p4
  ../glass/testsuite/p4_tests/arista/COMPILER-264/case1822.p4
  ../glass/testsuite/p4_tests/arista/COMPILER-276/case1844.p4
  ../glass/testsuite/p4_tests/arista/COMPILER-326/case2035.p4
  ../glass/testsuite/p4_tests/arista/COMPILER-437/case2387_1.p4
  ../glass/testsuite/p4_tests/arista/COMPILER-674/case3730.p4
  ../glass/testsuite/p4_tests/arista/COMPILER-721/case4015.p4
  ../glass/testsuite/p4_tests/arista/COMPILER-752/test_config_372_init_issue.p4
  ../glass/testsuite/p4_tests/arista/COMPILER-786/comp_786.p4
  ../glass/testsuite/p4_tests/arista/COMPILER-799/case4571.p4
  ../glass/testsuite/p4_tests/arista/COMPILER-818/case4954.p4
  ../glass/testsuite/p4_tests/arista/COMPILER-823/pipeline2-failing.p4
  ../glass/testsuite/p4_tests/arista/COMPILER-883/case5521.p4
  ../glass/testsuite/p4_tests/kpn/COMPILER-896/case5546.p4
  ../glass/testsuite/p4_tests/mau/COMPILER-1160/comp_1160.p4
  ../glass/testsuite/p4_tests/phv/COMPILER-1094/comp_1094.p4
  ../glass/testsuite/p4_tests/rdp/COMPILER-510/case2682.p4
  ../glass/testsuite/p4_tests/rdp/COMPILER-514/balancer_one.p4
  ../glass/testsuite/p4_tests/rdp/COMPILER-537/case2834.p4

  ../glass/testsuite/p4_tests/arista/COMPILER-1152/case8686.p4
  ../glass/testsuite/p4_tests/arista/MODEL-475/case9192.p4

  testdata/p4_14_samples/source_routing.p4
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
  "Conditional emit b.emit not supported"
  testdata/p4_16_samples/issue887.p4
)

p4c_add_xfail_reason("tofino"
  "error: Advancing by a non-constant distance is not supported on Tofino"
  testdata/p4_16_samples/issue1755-1-bmv2.p4
  )


# BEGIN: XFAILS that match glass XFAILS

p4c_add_xfail_reason("tofino"
  "[Tt]able .* is applied in multiple places, and the next-table information cannot correctly propagate"
  testdata/p4_16_samples/issue986-bmv2.p4
  ../glass/testsuite/p4_tests/arista/COMPILER-100/exclusive_cf_fail_next_ptr.p4
  )

p4c_add_xfail_reason("tofino"
  "Table .* has incompatible next-table chains"
  ../glass/testsuite/p4_tests/arista/COMPILER-100/exclusive_cf_multiple_actions.p4
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
  p4testgen_laymen_0
  testdata/p4_14_samples/action_inline.p4
  ../glass/testsuite/p4_tests/microsoft/COMPILER-606/case3259.p4
  extensions/p4_tests/p4_16/compile_only/p4c-2336.p4
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

p4c_add_xfail_reason("tofino"
  "error: .*: Duplicates declaration .*"
  extensions/p4_tests/p4_14/compile_only/p4smith_regression/utes_0.p4
  testdata/p4_16_samples/psa-example-register2-bmv2.p4
  testdata/p4_16_samples/psa-register-read-write-bmv2.p4
  extensions/p4_tests/p4_14/compile_only/p4smith_regression/shillings_0.p4
)

p4c_add_xfail_reason("tofino"
  "error: : Currently the field .* in action .* is assigned in a way too complex for the compiler to currently handle.  Please consider simplifying this action around this parameter"
  testdata/p4_16_samples/slice-def-use1.p4
)

p4c_add_xfail_reason("tofino"
    "error: : Currently in p4c, the table sucker_0 cannot perform a range match on key ingress::suitably.litheness as the key does not fit in under 5 PHV nibbles"
  extensions/p4_tests/p4_14/compile_only/p4smith_regression/licensee_0.p4
)

p4c_add_xfail_reason("tofino"
    "the packing is too complicated due to a too complex container instruction with a speciality action data combined with other action data"
    extensions/p4_tests/p4_14/stf/stateful5-psa.p4
    extensions/p4_tests/p4_16/stf/stateful5-psa.p4
)

# p4smith and p4testgen regression XFAILs

# real error. fails because gateway condition too complex and cannot fit in a TCAM.
p4c_add_xfail_reason("tofino"
  "error.*condition too complex"
  extensions/p4_tests/p4_14/compile_only/p4smith_regression/grab_0.p4
  testdata/p4_16_samples/issue1544-1-bmv2.p4
  testdata/p4_16_samples/issue1544-2-bmv2.p4
)

# P4C-990
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

# P4C-1650
p4c_add_xfail_reason("tofino"
  "Table .* has a metadata dependency, but doesn't appear in the TableGraph?"
  extensions/p4_tests/p4_14/compile_only/p4smith_regression/metadata_dependency.p4
)

# expected failure -- rng must be on hit path
p4c_add_xfail_reason("tofino"
  "action requires rng.*hit pathway.*driver can only currently program the miss pathway"
  extensions/p4_tests/p4_14/compile_only/p4smith_regression/hash_table_column_duplicated.p4
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
  ../glass/testsuite/p4_tests/kaust/COMPILER-1077/countmin.p4
)

p4c_add_xfail_reason("tofino"
  "p4c TIMEOUT"
  ../glass/testsuite/p4_tests/kaloom/COMPILER-839/leaf.p4
)

p4c_add_xfail_reason("tofino"
  "Could not place table .* The table .* could not fit within a single input crossbar in an MAU stage"
  ../glass/testsuite/p4_tests/phv/COMPILER-423/diag_power.p4
  ../glass/testsuite/p4_tests/mau/COMPILER-572/hct.p4
)

p4c_add_xfail_reason("tofino"
  "error: Field is extracted in the parser.*incompatible alignment"
  ../glass/testsuite/p4_tests/mau/COMPILER-702/comp_702.p4
)

p4c_add_xfail_reason("tofino"
  "error: Field is extracted in the parser into multiple containers, but the container slices after the first aren't byte aligned"
  ../glass/testsuite/p4_tests/mau/COMPILER-710/comp_710.p4
)

p4c_add_xfail_reason("tofino"
  "Cannot extract field .* from .* which has type .*"
  testdata/p4_16_samples/issue1210.p4
)

p4c_add_xfail_reason("tofino"
  "Number of fields .* in initializer different than number of fields"
  testdata/p4_16_samples/issue2303.p4
)

# psa.p4 bug, frontend failure
p4c_add_xfail_reason("tofino"
  "Action parameter color has a type which is not bit<>, int<>, bool, type or serializable enum"
  testdata/p4_16_samples/psa-meter1.p4
)

# p4c_add_xfail_reason("tofino"
#   "direct attached objects must be enabled in all hit actions"
#   testdata/p4_16_samples/psa-meter6.p4
# )

# P4C-1499
p4c_add_xfail_reason("tofino"
  "Direct Extern .* of type .* is used in action .*"
  testdata/p4_16_samples/psa-meter6.p4
)

p4c_add_xfail_reason("tofino"
  "PHV allocation was not successful"
  testdata/p4_16_samples/psa-example-digest-bmv2.p4
)

# This test attempts to match on a field of `error` type.
p4c_add_xfail_reason("tofino"
  "error: error: width not well-defined"
  testdata/p4_16_samples/issue1062-1-bmv2.p4
  testdata/p4_16_samples/issue1062-bmv2.p4
  testdata/p4_16_samples/psa-example-parser-checksum.p4
)

# BRIG-934: this issue is not resolved, need fix in ConvertEnums.
p4c_add_xfail_reason("tofino"
  "condition expression too complex"
  testdata/p4_16_samples/issue1325-bmv2.p4
)

# BRIG-934
p4c_add_xfail_reason("tofino"
  "Found extract ingress::meta.parser_error"
  testdata/p4_16_samples/issue510-bmv2.p4
)

# P4C-1011
p4c_add_xfail_reason("tofino"
  "error: standard_metadata.mcast_grp is not accessible in the egress pipe"
  extensions/p4_tests/p4_16/bf_p4c_samples/v1model-special-ops-bmv2.p4
  testdata/p4_16_samples/ipv6-switch-ml-bmv2.p4
  )

p4c_add_xfail_reason("tofino"
  "The random declaration .* max size must be a power of two"
  testdata/p4_16_samples/issue1517-bmv2.p4
)

# v1model translation issue
p4c_add_xfail_reason("tofino"
  "error: meter_color_t: declaration not found"
  testdata/p4_16_samples/issue1989-bmv2.p4
)

# test program error
p4c_add_xfail_reason("tofino"
  "The random declaration .* min size must be zero"
  extensions/p4_tests/p4_14/compile_only/p4smith_regression/perusal_0.p4
)

# Negative test
p4c_add_xfail_reason("tofino"
  "Unsupported unconditional mirror.emit"
  extensions/p4_tests/p4_16/compile_only/brig-neg-1259.p4
)

# Negative test. >66 bytes of ternary match key fields used.
p4c_add_xfail_reason("tofino"
  "error.*Ternary table.*uses.*as ternary match key. Maximum number of bits allowed is.*"
  extensions/p4_tests/p4_16/compile_only/too_many_ternary_match_key_bits.p4
)

# Negative test. Directly attached resources (other than action data)
# are not allowed for ATCAM tables.
p4c_add_xfail_reason("tofino"
  "error.*The ability to split directly addressed counters/meters/stateful resources across multiple logical tables of an algorithmic tcam match table is not currently supported.*"
  extensions/p4_tests/p4_16/compile_only/p4c-1601-neg.p4
)

p4c_add_xfail_reason("tofino"
  "error.*This program violates action constraints imposed by Tofino.|./p4c TIMEOUT"
# Investigate this
  extensions/p4_tests/p4_16/customer/arista/p4c-1652.p4
# Negative tests for violation of action constraints.
  extensions/p4_tests/p4_14/compile_only/action_conflict_1.p4
  extensions/p4_tests/p4_14/compile_only/action_conflict_3.p4
  extensions/p4_tests/p4_14/compile_only/action_conflict_7.p4
  extensions/p4_tests/p4_14/customer/arista/obfuscated-1.p4
  extensions/p4_tests/p4_16/customer/kaloom/p4c-1299.p4
  extensions/p4_tests/p4_16/customer/noviflow/p4c-1288.p4
  extensions/p4_tests/p4_16/compile_only/multi-constraint.p4
  ../glass/testsuite/p4_tests/fujitsu/COMPILER-1141/static_acl_tun_tel.p4
  ../glass/testsuite/p4_tests/mau/COMPILER-968/comp_968.p4
  ../glass/testsuite/p4_tests/mau/COMPILER-970/comp_970.p4
  ../glass/testsuite/p4_tests/rdp/COMPILER-466/case2563_with_nop.p4
  ../glass/testsuite/p4_tests/rdp/COMPILER-466/case2563_without_nop.p4
)

p4c_add_xfail_reason("tofino"
  "This program violates action constraints imposed by Tofino"
  extensions/p4_tests/p4_16/ptf/int_transit.p4
)

p4c_add_xfail_reason("tofino"
  "The table .* with no key cannot have the action .*"
  ../glass/testsuite/p4_tests/phv/COMPILER-961/jk_msdc.p4
)

p4c_add_xfail_reason("tofino"
  "PHV allocation was not successful"
  testdata/p4_16_samples/strength3.p4
  extensions/p4_tests/p4_14/customer/arista/p4c-2661.p4
)

p4c_add_xfail_reason("tofino"
  "Unsupported type header_union U"
  testdata/p4_16_samples/header-bool-bmv2.p4
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
  "Cannot find a slicing to satisfy @pa_container_size"
  extensions/p4_tests/p4_14/customer/arista/p4c-1814.p4
  ../glass/testsuite/p4_tests/arista/COMPILER-1114/case8156.p4
  ../glass/testsuite/p4_tests/phv/test_config_275_match_key_range.p4
  ../glass/testsuite/p4_tests/phv/test_config_593_reduce_extraction_bandwidth_32.p4
  )

# Valid XFAIL
# Fails due to complex expressions in the parser that our hardware can't support.
p4c_add_xfail_reason("tofino"
  "error: Assignment source cannot be evaluated in the parser"
  ../glass/testsuite/p4_tests/phv/test_config_402_parser_sub.p4
  )

# P4C-1299
p4c_add_xfail_reason("tofino"
    # Depending on VM Load these tests may timeout before displaying the PHV
    # alloc unsuccessful message and fail travis, we use both messages to check
    # xfails
    "PHV allocation was not successful|./p4c TIMEOUT"
  ../glass/testsuite/p4_tests/phv/COMPILER-136/06-FullTPHV1.p4
  )

p4c_add_xfail_reason("tofino"
  "PHV allocation was not successful|./p4c TIMEOUT"
  ../glass/testsuite/p4_tests/rdp/COMPILER-443/case2514.p4
  ../glass/testsuite/p4_tests/rdp/COMPILER-502/case2675.p4
  # funnel shift not supported
  ../glass/testsuite/p4_tests/rdp/COMPILER-533/case2736.p4
  extensions/p4_tests/p4_14/compile_only/p4smith_regression/shrubs_0.p4
  )

# P4C-1375
p4c_add_xfail_reason("tofino"
  "Field .* written to more than once in action .*"
  ../glass/testsuite/p4_tests/phv/COMPILER-761/simple_l3_mirror.p4
  )

p4c_add_xfail_reason("tofino"
  "Cannot operate on values with different widths"
  ba102_simple_l3_mirror
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
  testdata/p4_16_samples/psa-action-profile4.p4
  )

# P4C-1165
p4c_add_xfail_reason("tofino"
  "Cannot unify bit<.*> to bit<.*>"
  ../glass/testsuite/p4_tests/nus/COMPILER-858/comp_858.p4
  ../glass/testsuite/p4_tests/parde/COMPILER-350/ipv4_issue.p4
  ../glass/testsuite/p4_tests/phv/COMPILER-394/comp394.p4
  ../glass/testsuite/p4_tests/ucsd/COMPILER-1022/comp_1022.p4
  )

# Valid XFAIL
p4c_add_xfail_reason("tofino"
  "error: calling indirect .* with no index"
  ../glass/testsuite/p4_tests/mau/test_config_410_neg_stateful_no_idx.p4
  )

# P4C-1379
p4c_add_xfail_reason("tofino"
  "Unsupported primitive invalidate_clone"
  ../glass/testsuite/p4_tests/mau/test_config_396_invalidate_clone.p4
  ../glass/testsuite/p4_tests/mau/test_config_400_disable_reserved_i2e.p4
  )

# P4C-2134
p4c_add_xfail_reason("tofino"
  "Unsupported primitive modify_field_with_hash_based_offset"
  ../glass/testsuite/p4_tests/arista/COMPILER-635/case3468.p4
  ../glass/testsuite/p4_tests/arista/COMPILER-637/case3478.p4
  ../glass/testsuite/p4_tests/arista/COMPILER-648/comp648.p4
  )

# Valid XFAIL
p4c_add_xfail_reason("tofino"
  "Expected 2 operands for execute"
  ../glass/testsuite/p4_tests/mau/test_config_411_neg_meter_no_idx.p4
  )

# Valid XFAIL
p4c_add_xfail_reason("tofino"
  "The attached .* is addressed by both hash and index in table"
  ../glass/testsuite/p4_tests/arista/COMPILER-482/case2622.p4
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

# P4C-1323
# Could not place table capture_timestamp_1_0: The table capture_timestamp_1_1 could not fit within a single input crossbar in an MAU stage
p4c_add_xfail_reason("tofino"
  "Could not place table"
  ../glass/testsuite/p4_tests/mau/COMPILER-268/netflow_3.p4
  ../glass/testsuite/p4_tests/noviflow/COMPILER-1175/comp_1175.p4
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
  )

# BRIG-604
p4c_add_xfail_reason("tofino"
  "Compiler Bug.*Operand.*of instruction.*operating on container.*must be a PHV"
  extensions/p4_tests/p4_14/compile_only/p4smith_regression/clue_0.p4
  extensions/p4_tests/p4_16/compile_only/deparse-zero-clustering.p4
  testdata/p4_16_samples/issue983-bmv2.p4
  ../glass/testsuite/p4_tests/arista/COMPILER-548/case3011.p4
  )

# Valid XFAIL
p4c_add_xfail_reason("tofino"
  "Attached object .* in table .* is executed in some actions and not executed in others"
  ../glass/testsuite/p4_tests/mau/COMPILER-478/test_config_310_hash_write_issue.p4
  )

# Valid XFAIL
p4c_add_xfail_reason("tofino"
  "Maximum width for byte counter .* is 64 bits"
  ../glass/testsuite/p4_tests/arista/COMPILER-532/case2807.p4
  ../glass/testsuite/p4_tests/mau/COMPILER-1108/comp_1108.p4
  )

# Valid XFAIL
p4c_add_xfail_reason("tofino"
  "Unexpected type for constant"
  ../glass/testsuite/p4_tests/mau/COMPILER-556/variable.p4
  testdata/p4_16_samples/issue2261.p4
  )

# P4C-539
p4c_add_xfail_reason("tofino"
  "error: .*: declaration not found"
  testdata/p4_16_samples/action_profile-bmv2.p4
  testdata/p4_16_samples/issue1768-bmv2.p4
  testdata/p4_16_samples/issue297-bmv2.p4
  # EliminateTypeDef pass does not work properly?
  testdata/p4_16_samples/issue677-bmv2.p4
  # We fail to translate `generate_digest()`.
  testdata/p4_14_samples/issue1058.p4
  # shared register between ingress and egress is not supported
  testdata/p4_16_samples/issue1097-2-bmv2.p4
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
  testdata/p4_16_samples/action_profile_max_group_size_annotation.p4
  testdata/p4_16_samples/issue1824-bmv2.p4
  testdata/p4_16_samples/p4rt_digest_complex.p4
  # new tests added to p4c
  testdata/p4_16_samples/test-parserinvalidargument-error-bmv2.p4
  testdata/p4_16_samples/v1model-digest-containing-ser-enum.p4
  # glass testsuite failures
  ../glass/testsuite/p4_tests/arista/BRIG-5/case1715.p4
  ../glass/testsuite/p4_tests/arista/COMPILER-242/case1679.p4
  ../glass/testsuite/p4_tests/harveymudd/COMPILER-900/case4813.p4
  ../glass/testsuite/p4_tests/keysight/COMPILER-996/pktgen8.p4
  ../glass/testsuite/p4_tests/mau/COMPILER-837/comp_837_2.p4
  ../glass/testsuite/p4_tests/parde/COMPILER-319/mirror-eg_intr_md_from_parser_aux.p4
  ../glass/testsuite/p4_tests/parde/COMPILER-319/mirror-eg_intr_md-all.p4
  ../glass/testsuite/p4_tests/parde/COMPILER-675/select_on_egress_port.p4
  )

# Symmetric Hash Negative Tests
p4c_add_xfail_reason("tofino"
  "The two symmetric fields are not the same size"
  ../glass/testsuite/p4_tests/mau/test_config_315_sym_hash_neg_test_1.p4
)

p4c_add_xfail_reason("tofino"
  "A field .* cannot be symmetric to itself"
  ../glass/testsuite/p4_tests/mau/test_config_316_sym_hash_neg_test_2.p4
)

p4c_add_xfail_reason("tofino"
  "symmetric hash is only supported to work with CRC algorithms"
  ../glass/testsuite/p4_tests/mau/test_config_317_sym_hash_neg_test_3.p4
)

p4c_add_xfail_reason("tofino"
  "The key .* in the symmetric annotation does not appear within the field list"
  ../glass/testsuite/p4_tests/mau/test_config_318_sym_hash_neg_test_4.p4
)

p4c_add_xfail_reason("tofino"
  "The key .* in the symmetric annotation has already been declared symmetric with another field"
  ../glass/testsuite/p4_tests/mau/test_config_319_sym_hash_neg_test_5.p4
)

# P4C-1390
p4c_add_xfail_reason("tofino"
  "expected a field list"
  ../glass/testsuite/p4_tests/parde/test_start_coalesced_state.p4
  )

# P4C-1393
p4c_add_xfail_reason("tofino"
  "error.*This program violates action constraints imposed by Tofino."
  ../glass/testsuite/p4_tests/mau/COMPILER-728/ipu.p4
  ../glass/testsuite/p4_tests/rdp/COMPILER-475/case2600.p4
  )

# Failed after bridged packing, fix with a follow-up PR
p4c_add_xfail_reason("tofino"
  "PHV allocation was not successful|./p4c TIMEOUT"
  ../glass/testsuite/p4_tests/phv/COMPILER-908/compiler-908.p4
)

# Failed after bridged packing, fix with a follow-up PR
p4c_add_xfail_reason("tofino"
  "Fields involved in the same MAU operations have conflicting PARDE alignment requirements"
  extensions/p4_tests/p4_16/customer/arista/p4c-2226.p4
)

# P4C-1396
p4c_add_xfail_reason("tofino"
  "Incompatible types bit<1> and bool"
  ../glass/testsuite/p4_tests/noviflow/case9296.p4
  ../glass/testsuite/p4_tests/noviflow/COMPILER-687/case3769.p4
  ../glass/testsuite/p4_tests/noviflow/COMPILER-842/comp_842.p4
  ../glass/testsuite/p4_tests/noviflow/DRV-1092/drv_1092.p4
  ../glass/testsuite/p4_tests/noviflow/P4C-1984/p4c_1984_1.p4
  ../glass/testsuite/p4_tests/noviflow/P4C-1984/p4c_1984_2.p4
  ../glass/testsuite/p4_tests/noviflow/P4C-1984/p4c_1984_3.p4
  ../glass/testsuite/p4_tests/noviflow/P4C-1984/p4c_1984_4.p4
  )

p4c_add_xfail_reason("tofino"
  "tofino supports up to 12 stages, using 13|./p4c TIMEOUT"
  extensions/p4_tests/p4_16/customer/arista/p4c-2058.p4
  )

p4c_add_xfail_reason("tofino"
  "No PHV allocation for field used as a POV bit in the deparser|./p4c TIMEOUT"
  extensions/p4_tests/p4_16/customer/arista/p4c-2077.p4
  )

# Valid XFAIL
p4c_add_xfail_reason("tofino"
  "Phase0 pragma set but table - .* is not a valid Phase0"
  ../glass/testsuite/p4_tests/arista/COMPILER-632/case3459.p4
  ../glass/testsuite/p4_tests/mau/test_config_330_phase0_pragma_neg.p4
  )

# P4C-1401
p4c_add_xfail_reason("tofino"
  "Expression cast.* cannot be the target of an assignment"
  ../glass/testsuite/p4_tests/mau/COMPILER-770/switch_comp_770.p4
  ../glass/testsuite/p4_tests/mau/COMPILER-814/comp_814.p4
  ../glass/testsuite/p4_tests/mau/DRV-1081/switch_drv_1081.p4
  ../glass/testsuite/p4_tests/phv/COMPILER-777/switch_comp_777.p4
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

p4c_add_xfail_reason("tofino"
   "Assignment source cannot be evaluated in the parser"
   testdata/p4_14_samples/axon.p4
   testdata/p4_16_samples/issue1001-bmv2.p4
)

p4c_add_xfail_reason("tofino"
  "The following operation is not yet supported"
  ../glass/testsuite/p4_tests/mau/COMPILER-815/int_heavy.p4
  extensions/p4_tests/p4-programs/internal_p4_14/get_hash/get_hash.p4
)

# checksum only support bit<16> output
p4c_add_xfail_reason("tofino"
  "Cannot unify .* to .*"
  ../glass/testsuite/p4_tests/mau/galaxy_0.p4
  extensions/p4_tests/p4_14/compile_only/p4smith_regression/gradations_0.p4
  extensions/p4_tests/p4_14/compile_only/p4smith_regression/soured_0.p4
  extensions/p4_tests/p4_14/compile_only/p4smith_regression/tofino-bug-1.p4
  extensions/p4_tests/p4_14/compile_only/p4smith_regression/tofino-bug-5.p4
  P4C-1021-1
)

# p4lang/p4c #1724
p4c_add_xfail_reason("tofino"
  "error: The following operation is not yet supported:"
  testdata/p4_14_samples/issue-1559.p4
)

# varbit related starts
p4c_add_xfail_reason("tofino"
  "No varbit length encoding variable in"
  testdata/p4_16_samples/issue561-bmv2.p4
)

# broken tests that don't set egress_spec
p4c_add_xfail_reason("tofino"
  ".* expected packet.* on port .* not seen"
  testdata/p4_16_samples/issue447-bmv2.p4
  testdata/p4_16_samples/checksum1-bmv2.p4
  testdata/p4_16_samples/issue1025-bmv2.p4
  testdata/p4_16_samples/issue2176-bmv2.p4
  testdata/p4_16_samples/issue2225-bmv2.p4
  testdata/p4_16_samples/issue2383-bmv2.p4
  testdata/p4_16_samples/issue2375-1-bmv2.p4
  testdata/p4_16_samples/issue2375-bmv2.p4
  testdata/p4_16_samples/issue2392-bmv2.p4
)

# These should be compilation errors due to Tofino's lack of support
# of clear-on-write semantic in the parser. We give warnings for now.
p4c_add_xfail_reason("tofino"
  ".* expected packet on port .* not seen"
  extensions/p4_tests/p4_16/stf/parser_multi_write_2.p4
  extensions/p4_tests/p4_16/stf/parser_multi_write_8.p4
)

# P4C-1753
p4c_add_xfail_reason("tofino"
  ".* expected packet on port .* not seen"
  testdata/p4_16_samples/match-on-exprs-bmv2.p4
  testdata/p4_16_samples/table-entries-range-bmv2.p4
  testdata/p4_16_samples/table-entries-ternary-bmv2.p4
)

# P4C-1753
p4c_add_xfail_reason("tofino"
  "unexpected packet output on port .*"
  testdata/p4_16_samples/table-entries-exact-ternary-bmv2.p4
  testdata/p4_16_samples/table-entries-priority-bmv2.p4

  extensions/p4_tests/p4_16/stf/extract_slice.p4
)

p4c_add_xfail_reason("tofino"
  "standard_metadata.* is not accessible in the ingress pipe"
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
  testdata/p4_14_samples/issue576.p4
)

p4c_add_xfail_reason("tofino"
  "Assignment source cannot be evaluated in the parser"
  testdata/p4_14_samples/TLV_parsing.p4
)

p4c_add_xfail_reason("tofino"
  "Varbit field size expression evaluates to non byte-aligned value"
  # unbounded varbit expr
  extensions/p4_tests/p4_16/compile_only/p4c-1478-neg.p4
  testdata/p4_16_samples/issue447-2-bmv2.p4
  testdata/p4_16_samples/issue447-3-bmv2.p4
  testdata/p4_16_samples/issue447-4-bmv2.p4
)

p4c_add_xfail_reason("tofino"
  "Unsupported type header_union prot_host_addr_t"
  testdata/p4_16_samples/issue1879-bmv2.p4
)

# P4C-2133
p4c_add_xfail_reason("tofino"
  "Varbit extract requires too many parser branches to implement"
  ../glass/testsuite/p4_tests/rdp/COMPILER-379/case2210.p4
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
  ../glass/testsuite/p4_tests/arista/COMPILER-1105/case8039.p4
  ../glass/testsuite/p4_tests/arista/COMPILER-1113/case8138.p4
  ../glass/testsuite/p4_tests/mau/test_config_235_funnel_shift.p4
)

# negative test.
p4c_add_xfail_reason("tofino"
  "Not a phv field in the lpf execute: 1"
  extensions/p4_tests/p4_16/compile_only/neg_test_1_lpf_constant_param.p4
)

p4c_add_xfail_reason("tofino"
  "Unsupported unconditional mirror.emit"
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
  "error: Use of uninitialized parser value"
  extensions/p4_tests/p4_16/compile_only/p4c-1561-neg.p4
  extensions/p4_tests/p4_16/compile_only/simple_l3_mcast.p4
  extensions/p4_tests/p4_16/compile_only/p4c-2752.p4
  extensions/p4_tests/p4_16/customer/extreme/p4c-1561.p4
  # unable to resolve "lookahead" expression in resolve_parser_values.cpp
  testdata/p4_16_samples/issue1409-bmv2.p4
  testdata/p4_14_samples/issue2196.p4
)

p4c_add_xfail_reason("tofino"
  "Field clone_spec is not a member of structure struct standard_metadata"
  extensions/p4_tests/p4_16/compile_only/clone-bmv2-i2e-and-e2e.p4
  extensions/p4_tests/p4_16/compile_only/clone-bmv2.p4
)

p4c_add_xfail_reason("tofino"
  "error: Assignment source cannot be evaluated in the parser"
  testdata/p4_16_samples/issue1937-2-bmv2.p4
)

p4c_add_xfail_reason("tofino"
  "error: Tofino does not support nested checksum updates"
  extensions/p4_tests/p4_14/stf/update_checksum_7.p4
  ../glass/testsuite/p4_tests/alibaba/COMPILER-1129/comp_1129.p4
  ../glass/testsuite/p4_tests/alibaba/COMPILER-1129b/comp_1129b.p4
  ../glass/testsuite/p4_tests/alibaba/COMPILER-1130/comp_1130b.p4
  ../glass/testsuite/p4_tests/cisco/COMPILER-393/case2277.p4
  ../glass/testsuite/p4_tests/parde/test_checksum.p4
)

p4c_add_xfail_reason("tofino"
  "Compiler Bug.*Slicing the following supercluster is taking too long...|./p4c TIMEOUT"
  ../glass/testsuite/p4_tests/arista/COMPILER-568/case3026.p4
  ../glass/testsuite/p4_tests/arista/COMPILER-568/case3026dce.p4
  ../glass/testsuite/p4_tests/arista/COMPILER-575/case3041.p4
  ../glass/testsuite/p4_tests/arista/COMPILER-577/comp577.p4
)

# P4C-1445, DRV-2667
# Requires Pipe prefix support to avoid duplicate names
p4c_add_xfail_reason("tofino"
  "error: Found .* duplicate name.* in the P4Info"
  extensions/p4_tests/p4_16/compile_only/brig-814-2.p4
  extensions/p4_tests/p4_16/compile_only/multiple_apply2.p4
  extensions/p4_tests/p4_16/compile_only/test_config_11_multi_pipe_multi_parsers.p4
)

# Tna cannot support same direct counter on multiple tables
p4c_add_xfail_reason("tofino"
  "Name 'MyIC.counter0' is used for multiple direct counter objects in the P4Info message"
  testdata/p4_16_samples/psa-counter6.p4
)

# program error
p4c_add_xfail_reason("tofino"
  "Attached object .* in table .* is executed in some actions and not executed in others."
  testdata/p4_16_samples/psa-counter4.p4
  testdata/p4_16_samples/psa-meter5.p4
  testdata/p4_16_samples/psa-meter4.p4
)

# program error
p4c_add_xfail_reason("tofino"
  "Both Counter .* and .* require the stats address hardware"
  testdata/p4_16_samples/psa-counter2.p4
)

p4c_add_xfail_reason("tofino"
  "header fields cannot be used in wide arithmetic ops"
  testdata/p4_16_samples/psa-recirculate-no-meta-bmv2.p4
)

# no support for runtime-variable indexing
p4c_add_xfail_reason("tofino"
  "Compiler Bug.*: No PhvInfo::header for header"
  testdata/p4_16_samples/runtime-index-bmv2.p4
  testdata/p4_16_samples/runtime-index-2-bmv2.p4
)

# optional match type not supported
p4c_add_xfail_reason("tofino"
  "error: optional: declaration not found"
  testdata/p4_16_samples/table-entries-optional-bmv2.p4
)

# select ranges not supported
p4c_add_xfail_reason("tofino"
  "error: Ran out of parser match registers"
  testdata/p4_16_samples/pvs-struct-3-bmv2.p4
)

# Tna does not support more than one action_profile?
p4c_add_xfail_reason("tofino"
  "Expected implementation property value for table MyIC.tbl to resolve to an extern instance: implementation"
  testdata/p4_16_samples/psa-action-profile2.p4
)

p4c_add_xfail_reason("tofino"
  "error: Exceeded hardware limit for deparser field dictionary entries"
  extensions/p4_tests/p4_16/compile_only/p4c-1757-neg.p4
  ../glass/testsuite/p4_tests/embedway/COMPILER-765/parser_tcp_ip_option_mul.p4
  extensions/p4_tests/p4_16/compile_only/simple_l3_nexthop_ipv6_options.p4
)

p4c_add_xfail_reason("tofino"
  "The table .* could not fit within a single input crossbar in an MAU stage"
  extensions/p4_tests/p4_14/compile_only/p4c-2271.p4
)

p4c_add_xfail_reason("tofino"
  "Invalid args to MakeSlice"
  ../glass/testsuite/p4_tests/mau/adb_issue_from_faster.p4
)

p4c_add_xfail_reason("tofino"
  "Cannot unify bit<8> to int<8>"
  extensions/p4_tests/p4_16/compile_only/brig-305.p4
)

# Expected failures due to program error
p4c_add_xfail_reason("tofino"
  "Dynamic hashes must have the same field list and sets of algorithm for each get call|./p4c TIMEOUT"
  extensions/p4_tests/p4_16/customer/extreme/p4c-1492.p4
  extensions/p4_tests/p4_16/customer/extreme/p4c-1587-a.p4
)

p4c_add_xfail_reason("tofino"
  "Conditions in an action must be simple comparisons of an action data parameter"
  extensions/p4_tests/p4_16/customer/extreme/p4c-1672-1.p4
)

# P4C-1862
p4c_add_xfail_reason("tofino"
  "AttributeError: 'Client' object has no attribute"
  extensions/p4_tests/p4-programs/internal_p4_14/ecc/ecc.p4
)

p4c_add_xfail_reason("tofino"
  "Unsupported on target"
  # Unsupported on target Action profile .* on table .* does not have any action data
  ../glass/testsuite/p4_tests/arista/COMPILER-559/case2987.p4
  ../glass/testsuite/p4_tests/arista/COMPILER-593/case3011.p4
  ../glass/testsuite/p4_tests/keysight/COMPILER-1049/case7268.p4
)

# P4C-2076
p4c_add_xfail_reason("tofino"
  "error: : Currently the field .* in action .* is assigned in a way too complex for the compiler to currently handle."
  extensions/p4_tests/p4_16/customer/arista/p4c-2076.p4
)

# P4C-2132
p4c_add_xfail_reason("tofino"
  "deparser checksum unit 2 used in both ingress and egress"
  ../glass/testsuite/p4_tests/cisco/COMPILER-1140/comp_1140.p4
)

# P4C-2131
p4c_add_xfail_reason("tofino"
  "CalculatedField: same name as CalculatedField"
  ../glass/testsuite/p4_tests/cisco/COMPILER-1147/comp_1147.p4
)

# XFAIL_NEG_TEST
p4c_add_xfail_reason("tofino"
  "syntax error, unexpected"
  ../glass/testsuite/p4_tests/stordis/COMPILER-1095/case7871.p4
)

# P4C-2129
p4c_add_xfail_reason("tofino"
  "condition_lo used and not specified"
  ../glass/testsuite/p4_tests/medialinks/COMPILER-1000/clone_field_list_bug.p4
)

# P4C-2128
p4c_add_xfail_reason("tofino"
  "Failed to place tables that Register .* is attached to in the same stage"
  ../glass/testsuite/p4_tests/medialinks/COMPILER-682/case3764.p4
)

# P4C-2126
p4c_add_xfail_reason("tofino"
  "Value too large for unsigned int"
  ../glass/testsuite/p4_tests/microsoft/COMPILER-713/case3975.p4
)

# P4C-2126
p4c_add_xfail_reason("tofino"
  "Value too large for int"
  ../glass/testsuite/p4_tests/microsoft/COMPILER-983/case6463.p4
  ../glass/testsuite/p4_tests/princeton/COMPILER-676/case3736.p4
)

# P4C-2125
p4c_add_xfail_reason("tofino"
  "Invalid Width cannot be negative or zero"
  ../glass/testsuite/p4_tests/arista/COMPILER-1200/case9376.p4
  ../glass/testsuite/p4_tests/microsoft/COMPILER-991/vag6589.p4
)

#P4C-2080
p4c_add_xfail_reason("tofino"
  "Compiler Bug.*Expression not found"
  extensions/p4_tests/p4_16/compile_only/p4c-2080-min.p4
)

# P4C-2091
# Expected failure (negative test)
p4c_add_xfail_reason("tofino"
  "error.*PHV allocation was not successful"
  extensions/p4_tests/p4_16/compile_only/p4c-2091.p4
)

# P4C-2127
p4c_add_xfail_reason("tofino"
  "PHV allocation was not successful"
  ../glass/testsuite/p4_tests/arista/COMPILER-1170/case8862.p4
)

# P4C-2123
p4c_add_xfail_reason("tofino"
  "Not all applies of table .* are mutually exclusive"
  ../glass/testsuite/p4_tests/arista/COMPILER-100/exclusive_cf_one_action_fail_after.p4
  ../glass/testsuite/p4_tests/arista/COMPILER-100/exclusive_cf_one_action_fail_before.p4
)

# P4C-2115
p4c_add_xfail_reason("tofino"
  "ATCAM tables can at most have only one overhead word"
  ../glass/testsuite/p4_tests/arista/COMPILER-209/sizing.p4
)

# P4C-2122
p4c_add_xfail_reason("tofino"
  "Table .* has neither action table nor immediate actions"
  ../glass/testsuite/p4_tests/arista/COMPILER-262/case1804.p4
)

# P4C-923
p4c_add_xfail_reason("tofino"
  "ALU ops cannot operate on slices|./p4c TIMEOUT"
  ../glass/testsuite/p4_tests/arista/COMPILER-228/case1644.p4
  ../glass/testsuite/p4_tests/arista/COMPILER-562/case3005.p4
  ../glass/testsuite/p4_tests/arista/COMPILER-567/case2807.p4
  ../glass/testsuite/p4_tests/arista/COMPILER-576/case3042.p4
  ../glass/testsuite/p4_tests/arista/COMPILER-579/case3085.p4
  ../glass/testsuite/p4_tests/arista/COMPILER-585/comp585.p4
  ../glass/testsuite/p4_tests/arista/COMPILER-588/comp588.p4
  ../glass/testsuite/p4_tests/arista/COMPILER-589/comp589.p4
  ../glass/testsuite/p4_tests/arista/COMPILER-608/case3263.p4
)

# P4C-1957
# Compiler Bug: Extracted range byte[4..24) with size 160 doesn't match destination container TH7 with size 16
p4c_add_xfail_reason("tofino"
  "doesn't match destination container .* with size .*|./p4c TIMEOUT"
  ../glass/testsuite/p4_tests/arista/COMPILER-744/comp_744.p4
  ../glass/testsuite/p4_tests/arista/COMPILER-751/case4256.p4
)

# P4C-1948
p4c_add_xfail_reason("tofino"
  "At this point in the compilation typechecking should not infer new types anymore, but it did"
  ../glass/testsuite/p4_tests/keysight/COMPILER-924/case5801.p4
)

# P4C-1906
p4c_add_xfail_reason("tofino"
  "Depth of way doesn't match number of rams in table|./p4c TIMEOUT"
  ../glass/testsuite/p4_tests/arista/COMPILER-868/comp_868.p4
)

# Negative tests to test slice list creation
p4c_add_xfail_reason("tofino"
  "you must introduce padding fields around the above slice"
  extensions/p4_tests/p4_16/compile_only/p4c-2025.p4
  extensions/p4_tests/p4_16/compile_only/p4c-1892.p4
  # parde physical adjacency constraint violated by mau phv_no_pack constraint
  extensions/p4_tests/p4_14/compile_only/19-SimpleTrill.p4
)

p4c_add_xfail_reason("tofino"
  "Checksum destination field .* is not byte-aligned in the header. Checksum engine is unable to update a field if it is not byte-aligned"
  extensions/p4_tests/p4_14/compile_only/p4smith_regression/checksum_align.p4
  extensions/p4_tests/p4_14/compile_only/p4c-1162.p4
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

# P4 program error
p4c_add_xfail_reason("tofino"
  "Dynamic hashes must have the same field list and sets of algorithm for each get call, as these must change simultaneously at runtime"
  p4c_1585_a
)

p4c_add_xfail_reason("tofino"
  "PHV allocation was not successful"
  extensions/p4_tests/p4_16/customer/extreme/p4c-1458-b.p4
  ../glass/testsuite/p4_tests/parde/COMPILER-612/leaf.p4
)

# p4c-2581
p4c_add_xfail_reason("tofino"
  "PHV allocation requires the following field slices to be packed together"
  extensions/p4_tests/p4_16/customer/arista/p4c-2534.p4
)

p4c_add_xfail_reason("tofino"
  "This program violates action constraints imposed by Tofino"
  extensions/p4_tests/p4_16/customer/extreme/p4c-1460.p4
)

p4c_add_xfail_reason("tofino"
  "The compiler failed in slicing the following group of fields related by parser alignment and MAU constraints"
  extensions/p4_tests/p4_14/compile_only/cylinder_0.p4
)

# power.p4 PTF failure
# hw team uses it to do some manual testing
# to measure the SRAM and TCAM power draw
# keeping it in regression for compile_only
p4c_add_xfail_reason("tofino"
  "TypeError: %d format: a number is required, not NoneType"
  extensions/p4_tests/p4-programs/internal_p4_14/power/power.p4
)

p4c_add_xfail_reason("tofino"
  "Assignment to a header field in the deparser is only allowed when the source is checksum update, mirror, resubmit or learning digest"
  extensions/p4_tests/p4_16/compile_only/p4c-1858_neg.p4
  extensions/p4_tests/p4_16/compile_only/p4c-1867.p4
)

p4c_add_xfail_reason("tofino"
  "error: Use of uninitialized parser value"
  testdata/p4_16_samples/array-copy-bmv2.p4
  testdata/p4_16_samples/issue1607-bmv2.p4
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
  "Conditions in an action must be simple comparisons of an action data parameter"
  testdata/p4_16_samples/issue512.p4
)

p4c_add_xfail_reason("tofino"
  "1 expected packet on port 0 not seen"
  testdata/p4_16_samples/issue2170-bmv2.p4
)

p4c_add_xfail_reason("tofino"
  "error: MyPacketTypes: declaration not found"
  testdata/p4_16_samples/v1model-digest-custom-type.p4
)

p4c_add_xfail_reason("tofino"
  "error: Tofino requires byte-aligned headers, but header .* is not byte-aligned"
  testdata/p4_16_samples/custom-type-restricted-fields.p4
)

p4c_add_xfail_reason("tofino"
  "error: .*: action spanning multiple stages"
  testdata/p4_16_samples/nested_if_lvalue_dependencies.p4
  testdata/p4_16_samples/nested_if_else.p4
  testdata/p4_16_samples/nested_if_statement.p4
)

p4c_add_xfail_reason("tofino"
  "Compiler Bug.*: .*expected a method call"
  testdata/p4_16_samples/issue2287-bmv2.p4
  testdata/p4_16_samples/issue2205-bmv2.p4
)

p4c_add_xfail_reason("tofino"
  "Compiler Bug.*: .*too many side-effect in one expression"
  testdata/p4_16_samples/issue2289.p4
)

p4c_add_xfail_reason("tofino"
  "Compiler Bug.*: .*unexpected statement with call"
  testdata/p4_16_samples/issue2291-bmv2.p4
  testdata/p4_16_samples/issue2205-1-bmv2.p4
  testdata/p4_16_samples/issue2355.p4
)

p4c_add_xfail_reason("tofino"
  "Compiler Bug.*: .*visitor returned non-Statement type"
  testdata/p4_16_samples/issue2359.p4
)

p4c_add_xfail_reason("tofino"
  "Compiler Bug.*: .*Invalid register call statement"
  testdata/p4_16_samples/psa-register-complex-bmv2.p4
)

# error in flattening nested header
p4c_add_xfail_reason("tofino"
  "Field __bfp4c_fields is not a member of structure header __bfp4c_bridged_metadata_header"
  testdata/p4_16_samples/issue1879-bmv2.p4
)

# Test that fails due to extra sanity checking in fronend def_use pass
# P4C-2612
p4c_add_xfail_reason("tofino"
  "Compiler Bug.*: Overwriting definitions"
  ../glass/testsuite/p4_tests/mau/test_config_163_stateful_table_math_unit.p4
)

p4c_add_xfail_reason("tofino"
  "error: Parser state .* requires fields from an earlier state which have been lost"
  ../glass/testsuite/p4_tests/phv/COMPILER-679/case3769.p4
)

# P4C-2694 - saturating arithmetic exceeding container width
p4c_add_xfail_reason("tofino"
  "Saturating arithmetic operators may not exceed maximum PHV container width"
  extensions/p4_tests/p4_16/compile_only/p4c-2694.p4
)

# P4C-2817
p4c_add_xfail_reason("tofino"
  "error: tofino supports up to 12 stages, using .*"
  extensions/p4_tests/p4_16/customer/arista/obfuscated-ref-nat-static_3.p4
  extensions/p4_tests/p4_16/customer/arista/obfuscated-ref-qinq.p4
)

# P4C-2818
p4c_add_xfail_reason("tofino"
  "The compiler failed in slicing the following group of fields related by parser alignment and MAU constraints"
  extensions/p4_tests/p4_16/customer/arista/obfuscated-ref-firewall.p4
)

# P4C-2614
p4c_add_xfail_reason("tofino"
  "error: syntax error, unexpected '.'"
  extensions/p4_tests/p4_16/customer/arista/obfuscated-ref-nat-static_2.p4
)

# P4C-2836
p4c_add_xfail_reason("tofino"
  "error: Some fields cannot be allocated because of unsatisfiable constraints."
  extensions/p4_tests/p4_16/compile_only/ssub_illegal_pack.p4
)

p4c_add_xfail_reason("tofino"
  "error: PHV allocation creates an invalid container action within a Tofino ALU"
  extensions/p4_tests/p4_16/customer/ruijie/p4c-2350-1.p4
)

# P4C-2783
p4c_add_xfail_reason("tofino"
  "error: : source of modify_field invalid"
  extensions/p4_tests/p4_16/stf/arith_compare.p4
)

# Negative test, expected xfail
p4c_add_xfail_reason("tofino"
  "error: table .*: Number of partitions are specified for table .* but the partition index .* is not found"
  extensions/p4_tests/p4_16/compile_only/p4c-2035-name-neg.p4
  extensions/p4_tests/p4_16/compile_only/atcam_match_wide1-neg.p4
)
