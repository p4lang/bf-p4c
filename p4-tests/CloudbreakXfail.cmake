set (CLOUDBREAK_XFAIL_TESTS
  # this is intentionally empty because xfails should be added with a reason.
  # look for the failure message in this file and add to an existing ticket
  # or open a new one.
  )

## Initial failures copied from JBayXFail.cmake

# Mirroring direction BOTH not supported on Tofino2 but is used by the P4Runtime
# implementation
p4c_add_xfail_reason("tofino3"
  "Error when creating clone session in target"
  extensions/p4_tests/p4_16/ptf/clone_v1model.p4
  )

# These tests compile successfuly and fail in the model when running the STF test
# the reasons need more characterization
if (HARLYN_STF_cb AND NOT ENABLE_STF2PTF)

  # ingress_port isn't being setup properly (STF harness bug)
  p4c_add_xfail_reason("tofino3"
    ".* expected packet.* on port .* not seen"
    testdata/p4_14_samples/gateway1.p4
    testdata/p4_14_samples/gateway2.p4
    testdata/p4_14_samples/gateway3.p4
    testdata/p4_14_samples/gateway4.p4
  )

  p4c_add_xfail_reason("tofino3"
    "mismatch from expected"
    extensions/p4_tests/p4_16/stf/parser_error.p4)

  # needs strided CLOT alloc
  p4c_add_xfail_reason("tofino3"
    ".* expected packet.* on port .* not seen|shorter than expected"
    extensions/p4_tests/p4_16/stf/parser_loop_3.p4
    extensions/p4_tests/p4_16/stf/parser_loop_4.p4
    extensions/p4_tests/p4_16/stf/header_stack_strided_alloc2.p4
    extensions/p4_tests/p4_16/stf/header_stack_strided_alloc1.p4
  )

  p4c_add_xfail_reason("tofino3"
    "mismatch from expected.* at byte .*"
    # Needs stateful init regs support in simple test harness, this test passes
    # on stf2ptf
    extensions/p4_tests/p4_14/stf/stateful_init_regs.p4
    # Need some work with CLOT allocation
    extensions/p4_tests/p4_14/stf/update_checksum_8.p4
    )

  p4c_add_xfail_reason("tofino3"
    "Assertion .* failed"  # model asserts
   extensions/p4_tests/p4_14/stf/decaf_1.p4 # 16-bit container repeated in FD
   # P4C-2999
   extensions/p4_tests/p4_14/stf/decaf_2.p4
   )

endif() # HARLYN_STF

# BEGIN: XFAILS that match glass XFAILS

p4c_add_xfail_reason("tofino3"
  "table .* Cannot match on multiple fields using lpm match type"
  testdata/p4_14_samples/issue60.p4
  )

#END: XFAILS that match glass XFAILS

if (ENABLE_STF2PTF AND PTF_REQUIREMENTS_MET)
endif() # ENABLE_STF2PTF AND PTF_REQUIREMENTS_MET

p4c_add_xfail_reason("tofino3"
  "address too large for table"
  testdata/p4_14_samples/saturated-bmv2.p4
)

p4c_add_xfail_reason("tofino3"
  "Field clone_spec is not a member of structure struct standard_metadata"
  extensions/p4_tests/p4_16/compile_only/clone-bmv2.p4
  extensions/p4_tests/p4_16/compile_only/clone-bmv2-i2e-and-e2e.p4
)

p4c_add_xfail_reason("tofino3"
  "error: Assignment source cannot be evaluated in the parser"
  testdata/p4_14_samples/axon.p4
)

p4c_add_xfail_reason("tofino3"
  "This action requires hash, which can only be done through the hit pathway"
  testdata/p4_14_samples/acl1.p4
)

#bf-rt has problems with dleft hash?
p4c_add_xfail_reason("tofino3"
  "'DLEFT_HASH'"
  extensions/p4_tests/p4_16/jbay/hwlearn4.p4
)

p4c_add_xfail_reason("tofino3"
# Fail on purpose due to indirect tables not being mutually exclusive
  "table .* and table .* cannot share Counter .* because use of the Counter .* is not mutually exclusive"
  testdata/p4_14_samples/12-Counters.p4
  testdata/p4_14_samples/13-Counters1and2.p4
)

p4c_add_xfail_reason("tofino3"
  "error: standard_metadata.packet_length is not accessible in the ingress pipe"
  testdata/p4_14_samples/queueing.p4
)

p4c_add_xfail_reason("tofino3"
  "Counter .* and .* must have identical addressing in .* as they share an address bus"
  testdata/p4_14_samples/counter.p4
)

p4c_add_xfail_reason("tofino3"
  "Only compile-time constants are supported for hash base offset and max value"
  testdata/p4_14_samples/flowlet_switching.p4
)

p4c_add_xfail_reason("tofino3"
  ": P4_14 extern type not fully supported"
  testdata/p4_14_samples/issue604.p4
)

p4c_add_xfail_reason("tofino3"
  "error: .*: no such field in standard_metadata"
  extensions/p4_tests/p4_14/bf_p4c_samples/sai_p4.p4
)

p4c_add_xfail_reason("tofino3"
  "standard_metadata.* is not accessible in the ingress pipe"
  testdata/p4_14_samples/p414-special-ops.p4
)

p4c_add_xfail_reason("tofino3"
  "Action profile .* does not have any action data"
  testdata/p4_14_samples/selector0.p4
  extensions/p4_tests/p4_14/bf_p4c_samples/port_vlan_mapping.p4
  testdata/p4_14_samples/const_default_action.p4
)

p4c_add_xfail_reason("tofino3"
  "error: .*: action spanning multiple stages."
  testdata/p4_14_samples/action_inline.p4
)

p4c_add_xfail_reason("tofino3"
  "multiple varbit fields in a parser state is currently unsupported"
  testdata/p4_14_samples/issue576.p4
)

p4c_add_xfail_reason("tofino3"
  "Assignment source cannot be evaluated in the parser"
  testdata/p4_14_samples/TLV_parsing.p4
)

p4c_add_xfail_reason("tofino3"
  "Unimplemented compiler support.*: Currently the compiler only supports allocation of meter color"
  testdata/p4_14_samples/meter.p4
  testdata/p4_14_samples/meter1.p4
)

p4c_add_xfail_reason("tofino3"
    "the packing is too complicated due to a too complex container instruction with a speciality action data combined with other action data"
    extensions/p4_tests/p4_14/stf/stateful5-psa.p4
)

p4c_add_xfail_reason("tofino3"
  "Unsupported type argument for Value Set"
  testdata/p4_14_samples/parser_value_set2.p4
)

p4c_add_xfail_reason("tofino3"
  "error: This program violates action constraints imposed by Tofino3"
  extensions/p4_tests/p4_16/ptf/int_transit.p4
  extensions/p4_tests/p4_16/customer/kaloom/p4c-2573-spine.p4
  extensions/p4_tests/p4_16/customer/kaloom/p4c-2410-spine.p4
  extensions/p4_tests/p4_16/customer/kaloom/spine-app.p4
)

p4c_add_xfail_reason("tofino3"
  "error: Ran out of chunks in field dictionary"
  extensions/p4_tests/p4_16/compile_only/p4c-1757-neg.p4
)

# These tests fail at runtime with the driver
if (PTF_REQUIREMENTS_MET)

p4c_add_xfail_reason("tofino3"
  "AssertionError: Expected packet was not received on device .*, port .*"
  extensions/p4_tests/p4_16/ptf/ingress_checksum.p4
  extensions/p4_tests/p4_14/ptf/easy_no_match.p4
  #tor.p4
  #extensions/p4_tests/p4-programs/programs/resubmit/resubmit.p4
)

# P4C-1228
#p4c_add_xfail_reason("tofino3"
#  "OSError: .* No such file or directory"
#  extensions/p4_tests/p4-programs/programs/multicast_test/multicast_test.p4
#  )

endif() # PTF_REQUIREMENTS_MET

p4c_add_xfail_reason("tofino3"
  "error: .*could not fit .* along with .* Counter"
  testdata/p4_14_samples/counter5.p4
)

p4c_add_xfail_reason("tofino3"
  "unexpected packet output on port 0"
  extensions/p4_tests/p4_16/stf/extract_slice.p4
)

p4c_add_xfail_reason("tofino3"
  "./p4c TIMEOUT|condition expression too complex"
  testdata/p4_14_samples/header-stack-ops-bmv2.p4
)

p4c_add_xfail_reason("tofino3"
  "The meter .* requires either an idletime or stats address bus"
  testdata/p4_14_samples/hash_action_two_same.p4
)

# P4C-539
p4c_add_xfail_reason("tofino3"
  "error: .*: declaration not found"
  # We fail to translate `generate_digest()`.
  testdata/p4_14_samples/issue1058.p4
  # We fail to translate `resubmit()`.
  testdata/p4_14_samples/resubmit.p4
  # Checksum16 is deprecated
  extensions/p4_tests/p4_16/stf/ipv4_options.p4
  # We fail to translate `standard_metadata.instance_type`.
  testdata/p4_14_samples/copy_to_cpu.p4
  testdata/p4_14_samples/packet_redirect.p4
  testdata/p4_14_samples/simple_nat.p4
  # truncate is not supported in jna
  testdata/p4_14_samples/truncate.p4
)

# P4C-1011
p4c_add_xfail_reason("tofino3"
  "standard_metadata.mcast_grp is not accessible in the egress pipe"
  extensions/p4_tests/p4_16/bf_p4c_samples/v1model-special-ops-bmv2.p4
)

p4c_add_xfail_reason("tofino3"
  "Varbit field size expression evaluates to non byte-aligned value"
  extensions/p4_tests/p4_16/compile_only/p4c-1478-neg.p4
  )

# Negative test. Directly attached resources (other than action data)
# are not allowed for ATCAM tables.
p4c_add_xfail_reason("tofino3"
  "error.*The ability to split directly addressed counters/meters/stateful resources across multiple logical tables of an algorithmic tcam match table is not currently supported.*"
  extensions/p4_tests/p4_16/compile_only/p4c-1601-neg.p4
)

# Expected failure
p4c_add_xfail_reason("tofino3"
  "error: standard_metadata.packet_length is not accessible in the ingress pipe"
  testdata/p4_14_samples/p414-special-ops-2-bmv2.p4
  testdata/p4_14_samples/p414-special-ops-3-bmv2.p4
  )

p4c_add_xfail_reason("tofino3"
  "HashAlgorithm_t.CSUM16: Invalid enum tag"
  testdata/p4_14_samples/issue894.p4
)

# Not being tracked by JBay regression yet
#p4c_add_xfail_reason("tofino3"
#  "Field key is not a member of structure header pktgen_recirc_header_t"
#  extensions/p4_tests/p4-programs/programs/stful/stful.p4
#)

p4c_add_xfail_reason("tofino3"
  "Field .* is not a member of structure header .*"
  extensions/p4_tests/p4_16/customer/extreme/p4c-1802.p4
)

#p4c_add_xfail_reason("tofino3"
#  "Name '.*' is used for multiple Register objects in the P4Info message"
#  p4_16_internal_p4_16_t2na_fifo
#)

p4c_add_xfail_reason("tofino3"
  "Unsupported condition && in mirror.emit"
  extensions/p4_tests/p4_16/compile_only/p4c-1150-nested-ifs.p4
)

# P4C-2091
# Expected failure (negative test)
p4c_add_xfail_reason("tofino3"
  "error.*PHV allocation was not successful"
  extensions/p4_tests/p4_16/compile_only/p4c-2091.p4
)

# Negative tests to test slice list creation
p4c_add_xfail_reason("tofino3"
  "you can introduce padding fields"
  extensions/p4_tests/p4_16/compile_only/p4c-1892.p4
)

# action synthesis can't figure out it can use an OR to set a single bit.
p4c_add_xfail_reason("tofino3"
  "the program requires an action impossible to synthesize for Tofino3 ALU"
  extensions/p4_tests/p4_14/stf/stateful4.p4
)

p4c_add_xfail_reason("tofino3"
  "All fields within the same byte-size chunk of the header must have the same 2 byte-alignment in the checksum list. Checksum engine is unable to read .* for .* checksum update"
  extensions/p4_tests/p4_16/compile_only/checksum_neg_test1.p4
)

p4c_add_xfail_reason("tofino3"
  "All fields within same byte of header must participate in the checksum list. Checksum engine is unable to read .* for .*checksum update"
  extensions/p4_tests/p4_16/compile_only/checksum_neg_test2.p4
)

p4c_add_xfail_reason("tofino3"
  "Each field's bit alignment in the packet should be equal to that in the checksum list. Checksum engine is unable to read .* for .* checksum update"
  extensions/p4_tests/p4_16/compile_only/checksum_neg_test3.p4
)

p4c_add_xfail_reason("tofino3"
  "Destination of saturation add was allocated to bigger container than the field itself.*"
  extensions/p4_tests/p4_16/compile_only/p4c-3172-xfail.p4
)

## new cloudbreak failures (different from JBay)

#driver does not yet work
p4c_add_xfail_reason("tofino3"
  "ERROR:PTF runner:Error when starting model & switchd"
  extensions/p4_tests/p4_14/ptf/easy_exact.p4
  extensions/p4_tests/p4_14/ptf/easy_no_match.p4
  extensions/p4_tests/p4_14/ptf/easy_no_match_with_gateway.p4
  extensions/p4_tests/p4_14/ptf/easy.p4
  extensions/p4_tests/p4_14/ptf/easy_ternary.p4
  extensions/p4_tests/p4_14/ptf/ecmp_pi.p4
  extensions/p4_tests/p4_14/ptf/ternary_match_constant_action_data.p4
  extensions/p4_tests/p4_16/ptf/adata_constant_out_of_range_for_immediate.p4
  extensions/p4_tests/p4_16/ptf/clone_v1model.p4
  extensions/p4_tests/p4_16/ptf/ingress_checksum.p4
  extensions/p4_tests/p4_16/ptf/ipv4_checksum.p4
  extensions/p4_tests/p4_16/ptf/large_action_data_constant.p4
  extensions/p4_tests/p4_16/ptf/multicast_basic.p4
  extensions/p4_tests/p4_16/ptf/udpv4_and_v6_checksum.p4
  extensions/p4_tests/p4_16/ptf/various_indirect_meters.p4
  extensions/p4_tests/p4_16/ptf/verify_checksum.p4
)

# ports are 11 bits on cloudbreak, so programs that assume 9 bits won't work
p4c_add_xfail_reason("tofino3"
  "Cannot unify type"
  extensions/p4_tests/p4_14/stf/egress_port_init.p4
  extensions/p4_tests/p4_16/compile_only/empty_header_stack.p4
  extensions/p4_tests/p4_16/compile_only/inline_subparser.p4
  extensions/p4_tests/p4_16/compile_only/p4c-1601-neg.p4
  extensions/p4_tests/p4_16/compile_only/p4c-1719.p4
  extensions/p4_tests/p4_16/compile_only/p4c-2490.p4
  extensions/p4_tests/p4_16/compile_only/too_many_pov_bits.p4
  extensions/p4_tests/p4_16/customer/extreme/npb-dark-phv-goal.p4
  extensions/p4_tests/p4_16/customer/extreme/npb-GA.p4
  extensions/p4_tests/p4_16/customer/extreme/npb-master-20200518.p4
  extensions/p4_tests/p4_16/customer/extreme/npb-master-20200813.p4
  extensions/p4_tests/p4_16/customer/extreme/p4c-1308-b.p4
  extensions/p4_tests/p4_16/customer/extreme/p4c-1323-b.p4
  extensions/p4_tests/p4_16/customer/extreme/p4c-1323-c2.p4
  extensions/p4_tests/p4_16/customer/extreme/p4c-1326.p4
  extensions/p4_tests/p4_16/customer/extreme/p4c-1458-a.p4
  extensions/p4_tests/p4_16/customer/extreme/p4c-1458-b.p4
  extensions/p4_tests/p4_16/customer/extreme/p4c-1460.p4
  extensions/p4_tests/p4_16/customer/extreme/p4c-1492.p4
  extensions/p4_tests/p4_16/customer/extreme/p4c-1557.p4
  extensions/p4_tests/p4_16/customer/extreme/p4c-1559.p4
  extensions/p4_tests/p4_16/customer/extreme/p4c-1560.p4
  extensions/p4_tests/p4_16/customer/extreme/p4c-1561.p4
  extensions/p4_tests/p4_16/customer/extreme/p4c-1562-1.p4
  extensions/p4_tests/p4_16/customer/extreme/p4c-1562-2.p4
  extensions/p4_tests/p4_16/customer/extreme/p4c-1565-2.p4
  extensions/p4_tests/p4_16/customer/extreme/p4c-1572-a.p4
  extensions/p4_tests/p4_16/customer/extreme/p4c-1572-b2.p4
  extensions/p4_tests/p4_16/customer/extreme/p4c-1585-a.p4
  extensions/p4_tests/p4_16/customer/extreme/p4c-1585-b2.p4
  extensions/p4_tests/p4_16/customer/extreme/p4c-1586.p4
  extensions/p4_tests/p4_16/customer/extreme/p4c-1587-a.p4
  extensions/p4_tests/p4_16/customer/extreme/p4c-1587-b2.p4
  extensions/p4_tests/p4_16/customer/extreme/p4c-1599.p4
  extensions/p4_tests/p4_16/customer/extreme/p4c-1680-2.p4
  extensions/p4_tests/p4_16/customer/extreme/p4c-1740.p4
  extensions/p4_tests/p4_16/customer/extreme/p4c-2238.p4
  extensions/p4_tests/p4_16/customer/extreme/p4c-2262-2.p4
  extensions/p4_tests/p4_16/customer/extreme/p4c-2358-2.p4
  extensions/p4_tests/p4_16/customer/extreme/p4c-2555-2.p4
  extensions/p4_tests/p4_16/customer/extreme/p4c-2641.p4
  extensions/p4_tests/p4_16/customer/extreme/p4c-2649.p4
  extensions/p4_tests/p4_16/customer/extreme/p4c-2794.p4
  extensions/p4_tests/p4_16/customer/extreme/p4c-2918-2.p4
  extensions/p4_tests/p4_16/customer/extreme/p4c-3001.p4
  extensions/p4_tests/p4_16/customer/extreme/p4c-3030-2.p4
  extensions/p4_tests/p4_16/customer/keysight/keysight-tf2.p4
  extensions/p4_tests/p4_16/customer/keysight/pktgen9_16.p4
  extensions/p4_tests/p4_16/customer/keysight/p4c-2554.p4
  extensions/p4_tests/p4_16/customer/microsoft/p4c-2387.p4
  extensions/p4_tests/p4_16/ptf/digest.p4
  extensions/p4_tests/p4_16/ptf/hash_driven_stats.p4
  extensions/p4_tests/p4_16/ptf/ONLab_packetio.p4
)

p4c_add_xfail_reason("tofino3"
  "Cannot operate on values with different types"
  testdata/p4_14_samples/issue-1426.p4
)

# pd scripts have problems with tofino3?
p4c_add_xfail_reason("tofino3"
  "error This program is intended to compile for Tofino P4 architecture only"
  extensions/p4_tests/p4_14/ptf/sful_split1.p4
  extensions/p4_tests/p4_14/ptf/p4c_1962.p4
)

p4c_add_xfail_reason("tofino3"
  "error: .*: Duplicates declaration .*"
  extensions/p4_tests/p4_16/compile_only/p4c-2495.p4
)

p4c_add_xfail_reason("tofino3"
  "error: .*: not defined on bit<9> and bit<11>"
  extensions/p4_tests/p4_16/customer/extreme/p4c-1308-d.p4
  extensions/p4_tests/p4_16/customer/extreme/p4c-1314.p4
  extensions/p4_tests/p4_16/customer/extreme/p4c-1323-a.p4
)

# P4 program error
p4c_add_xfail_reason("tofino3"
  ".* @dynamic_table_key_masks annotation only permissible with exact matches"
  extensions/p4_tests/p4_16/compile_only/dkm_invalid.p4
)

p4c_add_xfail_reason("tofino3"
  "error: Use of uninitialized parser value"
  testdata/p4_14_samples/issue2196.p4
  extensions/p4_tests/p4_16/compile_only/simple_l3_mcast.p4
)

# P4C-2694 - saturating arithmetic exceeding container width
p4c_add_xfail_reason("tofino3"
  "Saturating arithmetic operators may not exceed maximum PHV container width"
  extensions/p4_tests/p4_16/compile_only/p4c-2694.p4
)

# P4C-2836
p4c_add_xfail_reason("tofino3"
  "error: Some fields cannot be allocated because of unsatisfiable constraints."
  extensions/p4_tests/p4_16/compile_only/ssub_illegal_pack.p4
)

# P4C-2886
p4c_add_xfail_reason("tofino3"
  "CRASH with signal 6"
  extensions/p4_tests/p4_16/stf/parser_loop_2.p4
  extensions/p4_tests/p4_16/stf/parser_counter_12.p4
  extensions/p4_tests/p4_16/stf/parser_loop_1.p4
)

# Negative test, expected xfail
p4c_add_xfail_reason("tofino3"
  "error: table .*: Number of partitions are specified for table .* but the partition index .* is not found"
  extensions/p4_tests/p4_16/compile_only/atcam_match_wide1-neg.p4
)

# P4C-2141
p4c_add_xfail_reason("tofino3"
  "error: Can't access DW0 in parser"
  extensions/p4_tests/p4_14/stf/parser_error.p4
)

# digest fields related failures or expected to fail.
p4c_add_xfail_reason("tofino3"
  "invalid SuperCluster was formed"
  testdata/p4_14_samples/source_routing.p4
)

p4c_add_xfail_reason("tofino3"
  "In table table .*, the number of bits required to go through the immediate pathway 48 .* is greater than the available bits 32, and can not be allocated"
  # P4C-3093
  extensions/p4_tests/p4_16/jbay/ghost3.p4
)
