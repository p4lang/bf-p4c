set (JBAY_XFAIL_TESTS
  # this is intentionally empty because xfails should be added with a reason.
  # look for the failure message in this file and add to an existing ticket
  # or open a new one.
  )

# These tests compile successfuly and fail in the model when running the STF test
# the reasons need more characterization
if (HARLYN_STF_jbay AND NOT ENABLE_STF2PTF)

  # ingress_port isn't being setup properly (STF harness bug)
  p4c_add_xfail_reason("tofino2"
    ".* expected packet.* on port .* not seen"
    testdata/p4_14_samples/gateway1.p4
    testdata/p4_14_samples/gateway2.p4
    testdata/p4_14_samples/gateway3.p4
    testdata/p4_14_samples/gateway4.p4
  )

  p4c_add_xfail_reason("tofino2"
    "mismatch from expected"
    extensions/p4_tests/p4_16/stf/parser_error.p4
    extensions/p4_tests/p4_16/stf/header_stack_strided_alloc2.p4
  )

  # needs strided CLOT alloc
  p4c_add_xfail_reason("tofino2"
    ".* expected packet.* on port .* not seen|shorter than expected"
    extensions/p4_tests/p4_16/stf/parser_loop_3.p4
    extensions/p4_tests/p4_16/stf/parser_loop_4.p4
  )

  p4c_add_xfail_reason("tofino2"
    "mismatch from expected.* at byte .*"
    # Needs stateful init regs support in simple test harness, this test passes
    # on stf2ptf
    extensions/p4_tests/p4_14/stf/stateful_init_regs.p4
    # Need some work with CLOT allocation
    extensions/p4_tests/p4_14/stf/update_checksum_8.p4
    )

  p4c_add_xfail_reason("tofino2"
    "Assertion .* failed"  # model asserts
   extensions/p4_tests/p4_14/stf/decaf_1.p4 # 16-bit container repeated in FD
   # P4C-2999
   extensions/p4_tests/p4_14/stf/decaf_2.p4
   )

endif() # HARLYN_STF

# BEGIN: XFAILS that match glass XFAILS

p4c_add_xfail_reason("tofino2"
  "table .* Cannot match on multiple fields using lpm match type"
  testdata/p4_14_samples/issue60.p4
  )

#END: XFAILS that match glass XFAILS

if (ENABLE_STF2PTF AND PTF_REQUIREMENTS_MET)
endif() # ENABLE_STF2PTF AND PTF_REQUIREMENTS_MET

p4c_add_xfail_reason("tofino2"
  "address too large for table"
  testdata/p4_14_samples/saturated-bmv2.p4
)

p4c_add_xfail_reason("tofino2"
  "Field clone_spec is not a member of structure struct standard_metadata"
  extensions/p4_tests/p4_16/compile_only/clone-bmv2.p4
  extensions/p4_tests/p4_16/compile_only/clone-bmv2-i2e-and-e2e.p4
)

p4c_add_xfail_reason("tofino2"
  "PHV allocation was not successful"
  extensions/p4_tests/p4_16/compile_only/lrn1.p4
  extensions/p4_tests/p4_16/customer/extreme/p4c-1323-c2.p4
  extensions/p4_tests/p4_16/customer/extreme/p4c-1572-b2.p4
  extensions/p4_tests/p4_16/customer/extreme/p4c-1587-b2.p4
  extensions/p4_tests/p4_16/customer/extreme/p4c-1680-2.p4
  # P4C-2743
  extensions/p4_tests/p4_16/customer/extreme/npb-dark-phv-goal.p4
)

p4c_add_xfail_reason("tofino2"
  "Could not place table .udf_vlist_mac_ip_tbl: Can't split this table across stages and it's too big for one stage"
  extensions/p4_tests/p4_16/customer/keysight/pktgen9_16.p4
)

p4c_add_xfail_reason("tofino2"
  "error: Assignment source cannot be evaluated in the parser"
  testdata/p4_14_samples/axon.p4
)

p4c_add_xfail_reason("tofino2"
  "This action requires hash, which can only be done through the hit pathway"
  testdata/p4_14_samples/acl1.p4
)

p4c_add_xfail_reason("tofino2"
  "Could not place table .* The table .* could not fit"
  extensions/p4_tests/p4_16/jbay/hwlearn4.p4
)

p4c_add_xfail_reason("tofino2"
# Fail on purpose due to indirect tables not being mutually exclusive
  "table .* and table .* cannot share .*"
  testdata/p4_14_samples/12-Counters.p4
  testdata/p4_14_samples/13-Counters1and2.p4
)

p4c_add_xfail_reason("tofino2"
  "error: standard_metadata.packet_length is not accessible in the ingress pipe"
  testdata/p4_14_samples/queueing.p4
)

p4c_add_xfail_reason("tofino2"
  "Counter .* and .* must have identical addressing in .* as they share an address bus"
  testdata/p4_14_samples/counter.p4
)

p4c_add_xfail_reason("tofino2"
  "Only compile-time constants are supported for hash base offset and max value"
  testdata/p4_14_samples/flowlet_switching.p4
)

p4c_add_xfail_reason("tofino2"
  ": P4_14 extern type not fully supported"
  testdata/p4_14_samples/issue604.p4
)

p4c_add_xfail_reason("tofino2"
  "error: .*: no such field in standard_metadata"
  extensions/p4_tests/p4_14/bf_p4c_samples/sai_p4.p4
)

p4c_add_xfail_reason("tofino2"
  "standard_metadata.* is not accessible in the ingress pipe"
  testdata/p4_14_samples/p414-special-ops.p4
)

p4c_add_xfail_reason("tofino2"
  "Action profile .* does not have any action data"
  testdata/p4_14_samples/selector0.p4
  extensions/p4_tests/p4_14/bf_p4c_samples/port_vlan_mapping.p4
  testdata/p4_14_samples/const_default_action.p4
)

p4c_add_xfail_reason("tofino2"
  "error: .*: action spanning multiple stages."
  testdata/p4_14_samples/action_inline.p4
)

p4c_add_xfail_reason("tofino2"
  "multiple varbit fields in a parser state is currently unsupported"
  testdata/p4_14_samples/issue576.p4
)

p4c_add_xfail_reason("tofino2"
  "Assignment source cannot be evaluated in the parser"
  testdata/p4_14_samples/TLV_parsing.p4
)

p4c_add_xfail_reason("tofino2"
  "Unimplemented compiler support.*: Currently the compiler only supports allocation of meter color"
  testdata/p4_14_samples/meter.p4
  testdata/p4_14_samples/meter1.p4
)

p4c_add_xfail_reason("tofino2"
    "the packing is too complicated due to a too complex container instruction with a speciality action data combined with other action data"
    extensions/p4_tests/p4_14/stf/stateful5-psa.p4
)

p4c_add_xfail_reason("tofino2"
  "Unsupported type argument for Value Set"
  testdata/p4_14_samples/parser_value_set2.p4
)

p4c_add_xfail_reason("tofino2"
  "This program violates action constraints imposed by"
  extensions/p4_tests/p4_16/ptf/int_transit.p4
)

p4c_add_xfail_reason("tofino2"
  "error: Ran out of chunks in field dictionary"
  extensions/p4_tests/p4_16/compile_only/p4c-1757-neg.p4

  # P4C-2555
  extensions/p4_tests/p4_16/customer/extreme/p4c-2555-2.p4
)

# These tests fail at runtime with the driver
if (PTF_REQUIREMENTS_MET)

p4c_add_xfail_reason("tofino2"
  "AssertionError: Expected packet was not received on device .*, port .*"
  extensions/p4_tests/p4_16/ptf/ingress_checksum.p4
  extensions/p4_tests/p4_14/ptf/easy_no_match.p4
  tor.p4
  extensions/p4_tests/p4-programs/programs/resubmit/resubmit.p4
)

# P4C-1228
p4c_add_xfail_reason("tofino2"
  "OSError: .* No such file or directory"
  extensions/p4_tests/p4-programs/programs/multicast_test/multicast_test.p4
  )

endif() # PTF_REQUIREMENTS_MET

p4c_add_xfail_reason("tofino2"
  "Could not place table .*: The table .* could not fit"
  extensions/p4_tests/p4_14/stf/stateful3.p4
  testdata/p4_14_samples/counter5.p4
)

p4c_add_xfail_reason("tofino2"
  "./p4c TIMEOUT|condition expression too complex"
  testdata/p4_14_samples/header-stack-ops-bmv2.p4
)

p4c_add_xfail_reason("tofino2"
  "The meter .* requires either an idletime or stats address bus"
  testdata/p4_14_samples/hash_action_two_same.p4
)

# P4C-539
p4c_add_xfail_reason("tofino2"
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
p4c_add_xfail_reason("tofino2"
  "standard_metadata.mcast_grp is not accessible in the egress pipe"
  extensions/p4_tests/p4_16/bf_p4c_samples/v1model-special-ops-bmv2.p4
)

# p4lang/p4c #1724
p4c_add_xfail_reason("tofino2"
  "error: The following operation is not yet supported:"
  testdata/p4_14_samples/issue-1559.p4
)

p4c_add_xfail_reason("tofino2"
  "Varbit field size expression evaluates to non byte-aligned value"
  extensions/p4_tests/p4_16/compile_only/p4c-1478-neg.p4
  )

# Negative test. Directly attached resources (other than action data)
# are not allowed for ATCAM tables.
p4c_add_xfail_reason("tofino2"
  "error.*The ability to split directly addressed counters/meters/stateful resources across multiple logical tables of an algorithmic tcam match table is not currently supported.*"
  extensions/p4_tests/p4_16/compile_only/p4c-1601-neg.p4
)

# Expected failure
p4c_add_xfail_reason("tofino2"
  "error: standard_metadata.packet_length is not accessible in the ingress pipe"
  testdata/p4_14_samples/p414-special-ops-2-bmv2.p4
  testdata/p4_14_samples/p414-special-ops-3-bmv2.p4
  )

p4c_add_xfail_reason("tofino2"
  "Nested checksum updates is currently unsupported"
  extensions/p4_tests/p4_14/stf/update_checksum_7.p4
)

p4c_add_xfail_reason("tofino2"
  "HashAlgorithm_t.CSUM16: Invalid enum tag"
  testdata/p4_14_samples/issue894.p4
)

# Not being tracked by JBay regression yet
p4c_add_xfail_reason("tofino2"
  "Field key is not a member of structure header pktgen_recirc_header_t"
  extensions/p4_tests/p4-programs/programs/stful/stful.p4
)

p4c_add_xfail_reason("tofino2"
  "This program violates action constraints imposed by Tofino2"
  extensions/p4_tests/p4_16/customer/extreme/p4c-1460.p4
)

# P4C-2604
p4c_add_xfail_reason("tofino2"
  "PHV allocation creates an invalid container action within a Tofino ALU"
  extensions/p4_tests/p4_16/customer/extreme/p4c-1326.p4
  extensions/p4_tests/p4_16/customer/extreme/npb-master-20200813.p4
)

# P4C-2141
p4c_add_xfail_reason("tofino2"
  "PHV allocation creates an invalid container action within a Tofino ALU"
  extensions/p4_tests/p4_14/stf/parser_error.p4
)

p4c_add_xfail_reason("tofino2"
  "Field .* is not a member of structure header .*"
  extensions/p4_tests/p4_16/customer/extreme/p4c-1802.p4
)

p4c_add_xfail_reason("tofino2"
  "Use of uninitialized parser value"
  extensions/p4_tests/p4_16/customer/extreme/p4c-1561.p4
  extensions/p4_tests/p4_16/customer/extreme/p4c-1740.p4
  extensions/p4_tests/p4_16/compile_only/simple_l3_mcast.p4
  testdata/p4_14_samples/issue2196.p4
)

p4c_add_xfail_reason("tofino2"
  "Name '.*' is used for multiple Register objects in the P4Info message"
  p4_16_internal_p4_16_t2na_fifo
)

p4c_add_xfail_reason("tofino2"
  "Unsupported condition && in mirror.emit"
  extensions/p4_tests/p4_16/compile_only/p4c-1150-nested-ifs.p4
)

# P4C-2091
# Expected failure (negative test)
p4c_add_xfail_reason("tofino2"
  "error.*PHV allocation was not successful"
  extensions/p4_tests/p4_16/compile_only/p4c-2091.p4
)

p4c_add_xfail_reason("tofino2"
  "PHV allocation is invalid for container"
  extensions/p4_tests/p4_16/customer/extreme/p4c-2358-2.p4
  p4c_1585_b
)

# Negative tests to test slice list creation
p4c_add_xfail_reason("tofino2"
  "you must introduce padding fields around the above slice"
  extensions/p4_tests/p4_16/compile_only/p4c-1892.p4
)

# stateful table too big to fit in one half of jbay stage -- needs two home rows (top and bottom)
p4c_add_xfail_reason("tofino2"
  "error:.* Could not place table .* could not fit in stage .* with .* entries"
  extensions/p4_tests/p4_14/stf/stateful4.p4
)

p4c_add_xfail_reason("tofino2"
  "unexpected packet output on port 0"
  extensions/p4_tests/p4_14/stf/egress_port_init.p4
  extensions/p4_tests/p4_16/stf/extract_slice.p4
)

p4c_add_xfail_reason("tofino2"
  "All fields within the same byte-size chunk of the header must have the same 2 byte-alignment in the checksum list. Checksum engine is unable to read .* for .* checksum update"
  extensions/p4_tests/p4_16/compile_only/checksum_neg_test1.p4
)

p4c_add_xfail_reason("tofino2"
  "All fields within same byte of header must participate in the checksum list. Checksum engine is unable to read .* for .*checksum update"
  extensions/p4_tests/p4_16/compile_only/checksum_neg_test2.p4
)

p4c_add_xfail_reason("tofino2"
  "Each field's bit alignment in the packet should be equal to that in the checksum list. Checksum engine is unable to read .* for .* checksum update"
  extensions/p4_tests/p4_16/compile_only/checksum_neg_test3.p4
)

# P4 program error
p4c_add_xfail_reason("tofino2"
  "Dynamic hashes must have the same field list and sets of algorithm for each get call, as these must change simultaneously at runtime"
  p4c_1585_a
)

p4c_add_xfail_reason("tofino2"
  "Table .* @dynamic_table_key_masks annotation only permissible with exact matches"
  extensions/p4_tests/p4_16/compile_only/dkm_invalid.p4
)

# P4C-2572
p4c_add_xfail_reason("tofino2"
  "parser error allocated to multiple containers?"
  extensions/p4_tests/p4_16/customer/keysight/p4c-2554.p4
)

# P4C-2694 - saturating arithmetic exceeding container width
p4c_add_xfail_reason("tofino2"
  "Saturating arithmetic operators may not exceed maximum PHV container width"
  extensions/p4_tests/p4_16/compile_only/p4c-2694.p4
)

# P4C-2799
p4c_add_xfail_reason("tofino2"
  "error: PHV allocation was not successful"
  # P4C-3043
  extensions/p4_tests/p4_16/customer/arista/obfuscated-ref-baremetal_tofino2_2.p4
)

p4c_add_xfail_reason("tofino2"
  "invalid SuperCluster was formed|Too many heap sections: Increase MAXHINCR or MAX_HEAP_SECTS"
  # P4C-2953
  extensions/p4_tests/p4_16/customer/arista/obfuscated-ref-noname_tofino2_2.p4
  # P4C-2800 
  extensions/p4_tests/p4_16/customer/arista/obfuscated-ref-noname_tofino2_3.p4
  # P4C-3091
  extensions/p4_tests/p4_16/customer/arista/obfuscated-ref-noname_tofino2_4.p4
)

# P4C-2836
p4c_add_xfail_reason("tofino2"
  "error: Some fields cannot be allocated because of unsatisfiable constraints."
  extensions/p4_tests/p4_16/compile_only/ssub_illegal_pack.p4
)

# P4C-2886
p4c_add_xfail_reason("tofino2"
  "CRASH with signal 6"
  extensions/p4_tests/p4_16/stf/parser_loop_2.p4
  extensions/p4_tests/p4_16/stf/parser_counter_12.p4
  extensions/p4_tests/p4_16/stf/parser_loop_1.p4
)

# Negative test, expected xfail
p4c_add_xfail_reason("tofino2"
  "error: table .*: Number of partitions are specified for table .* but the partition index .* is not found"
  extensions/p4_tests/p4_16/compile_only/atcam_match_wide1-neg.p4
)

p4c_add_xfail_reason ("tofino2"
  "error: tofino2 supports up to 20 stages, using 23"
  extensions/p4_tests/p4_16/compile_only/p4c-2828.p4
)

# DRV-3528
p4c_add_xfail_reason ("tofino2"
  "TTransportException: TSocket read 0 bytes"
  extensions/p4_tests/p4-programs/programs/ha/ha.p4
)

p4c_add_xfail_reason("tofino2"
  "error: Cannot find a slicing to satisfy @pa_container_size"
  extensions/p4_tests/p4_16/compile_only/ssub_illegal_pack.p4
)

p4c_add_xfail_reason("tofino2"
  "invalid SuperCluster was formed"
  # digest fields related failures.
  testdata/p4_14_samples/source_routing.p4
)

p4c_add_xfail_reason("tofino2"
  "Could not place table .* The table .* could not fit"
  extensions/p4_tests/p4_16/compile_only/p4c-1601-neg.p4
)

# P4C-3059
p4c_add_xfail_reason("tofino2"
  "Expected packet was not received on device 0, port 2"
  p4c_1587
)

# P4C-3060
p4c_add_xfail_reason("tofino2"
  "error: PHV allocation creates an invalid container action within a Tofino ALU"
  p4c_2527
  p4c-3001
)
