set (JBAY_XFAIL_TESTS
  # this is intentionally empty because xfails should be added with a reason.
  # look for the failure message in this file and add to an existing ticket
  # or open a new one.
  )

# Mirroring direction BOTH not supported on Tofino2 but is used by the P4Runtime
# implementation
p4c_add_xfail_reason("tofino2"
  "Error when creating clone session in target"
  extensions/p4_tests/p4_16/ptf/clone_v1model.p4
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

  # P4C-2141
  p4c_add_xfail_reason("tofino2"
    "error: deposit-field dest can't be dark or mocha phv|mismatch from expected"
    extensions/p4_tests/p4_14/stf/parser_error.p4
    extensions/p4_tests/p4_16/stf/parser_error.p4)

  # needs strided CLOT alloc
  p4c_add_xfail_reason("tofino2"
    ".* expected packet.* on port .* not seen|shorter than expected"
    extensions/p4_tests/p4_16/stf/parser_loop_1.p4
    extensions/p4_tests/p4_16/stf/parser_loop_2.p4
  )

  p4c_add_xfail_reason("tofino2"
    "mismatch from expected.* at byte .*"
    # Needs stateful init regs support in simple test harness, this test passes
    # on stf2ptf
    extensions/p4_tests/p4_14/stf/stateful_init_regs.p4
    # Need some work with CLOT allocation
    extensions/p4_tests/p4_14/stf/update_checksum_8.p4

    # header in loop state cannot be in CLOT (no static ordering)
    extensions/p4_tests/p4_16/stf/parser_counter_12.p4
    )

  p4c_add_xfail_reason("tofino2"
    "Assertion .* failed"  # model asserts
   extensions/p4_tests/p4_14/stf/decaf_1.p4 # 16-bit container repeated in FD
   extensions/p4_tests/p4_14/stf/decaf_8.p4 # clot?
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
  extensions/p4_tests/p4_16/customer/extreme/p4c-1565-2.p4
  extensions/p4_tests/p4_16/customer/extreme/p4c-1572-b2.p4
  extensions/p4_tests/p4_16/customer/extreme/p4c-1587-b2.p4
  extensions/p4_tests/p4_16/customer/extreme/p4c-1680-2.p4
)

p4c_add_xfail_reason("tofino2"
  "error: Parser match .* too large, Tofino only supports 32 bits"
  testdata/p4_14_samples/source_routing.p4
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
# Fail on purpose due to indirect tables not being mutually exclusive
  "table .* and table .* are not mutually exclusive"
  testdata/p4_14_samples/12-Counters.p4
  testdata/p4_14_samples/13-Counters1and2.p4
)

p4c_add_xfail_reason("tofino2"
  "error: standard_metadata.packet_length is not accessible in the ingress pipe"
  testdata/p4_14_samples/queueing.p4
)

p4c_add_xfail_reason("tofino2"
  "Both .* and .* require the .* address hardware, and cannot be on the same table"
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
  "error: .*: Unsupported action spanning multiple stages."
  testdata/p4_14_samples/action_inline.p4
)

p4c_add_xfail_reason("tofino2"
  "Compiler Bug.*: .*: Cannot find declaration for"
  testdata/p4_14_samples/TLV_parsing.p4
  testdata/p4_14_samples/issue576.p4
)

p4c_add_xfail_reason("tofino2"
  "Unimplemented compiler support.*: Currently the compiler only supports allocation of meter color"
  testdata/p4_14_samples/meter.p4
  testdata/p4_14_samples/meter1.p4
)

p4c_add_xfail_reason("tofino2"
  "The method call of read and write on a Register is currently not supported in p4c"
  testdata/p4_14_samples/register.p4
)

p4c_add_xfail_reason("tofino2"
  "Unsupported type parameter for Value Set"
  testdata/p4_14_samples/parser_value_set2.p4
  )

p4c_add_xfail_reason("tofino2"
  "warning: Instruction selection creates an instruction that the rest of the compiler cannot correctly interpret"
  extensions/p4_tests/p4_16/compile_only/brig-42.p4
)

p4c_add_xfail_reason("tofino2"
  "Compiler Bug.*More than one field written to .* in action"
  extensions/p4_tests/p4_16/ptf/int_transit.p4
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

# BRIG-584
p4c_add_xfail_reason("tofino2"
  "ingress::local_metadata.f received an incomplete allocation"
  extensions/p4_tests/p4_16/stf/extract_slice.p4
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
  "error: .*: Not found declaration"
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

# P4C-1665
p4c_add_xfail_reason("tofino2"
  "Table placement cannot make any more progress"
  extensions/p4_tests/p4_16/jbay/hwlearn4.p4
)

p4c_add_xfail_reason("tofino2"
  "HashAlgorithm_t.CSUM16: Invalid enum tag"
  testdata/p4_14_samples/issue894.p4
)

# P4C-1445, DRV-2667
# Requires Pipe prefix support to avoid duplicate names
p4c_add_xfail_reason("tofino2"
  "error: Found .* duplicate name.* in the P4Info"
  extensions/p4_tests/p4_16/jbay/multistage_fifo.p4
)

# Not being tracked by JBay regression yet
p4c_add_xfail_reason("tofino2"
  "Field key is not a member of structure header pktgen_recirc_header_t"
  extensions/p4_tests/p4-programs/programs/stful/stful.p4
)

p4c_add_xfail_reason("tofino2"
  "Dynamic hashes must have the same field list and sets of algorithm for each get call"
  extensions/p4_tests/p4_16/customer/extreme/p4c-1458-a.p4
  extensions/p4_tests/p4_16/customer/extreme/p4c-1458-b.p4
  extensions/p4_tests/p4_16/customer/extreme/p4c-1460.p4
  extensions/p4_tests/p4_16/customer/extreme/p4c-1557.p4
  extensions/p4_tests/p4_16/customer/extreme/p4c-1585-a.p4
  extensions/p4_tests/p4_16/customer/extreme/p4c-1586.p4
  extensions/p4_tests/p4_16/customer/extreme/p4c-1587-a.p4
  extensions/p4_tests/p4_16/customer/extreme/p4c-1599.p4
)

p4c_add_xfail_reason("tofino2"
  "Metadata initialization analysis incorrect.  Live ranges between .* and .* overlap|./p4c TIMEOUT"
  extensions/p4_tests/p4_16/customer/extreme/p4c-1492.p4
)

p4c_add_xfail_reason("tofino2"
  "The input .* cannot be found on the hash input"
  extensions/p4_tests/p4_16/customer/extreme/p4c-1323-a.p4
  extensions/p4_tests/p4_16/customer/extreme/p4c-1323-b.p4
)

p4c_add_xfail_reason("tofino2"
  "Slicing the following supercluster is taking too long"
  extensions/p4_tests/p4_16/customer/extreme/p4c-1326.p4
)

p4c_add_xfail_reason("tofino2"
  ".* is not allocated contiguously by bit on the input xbar and cannot be resolved"
  extensions/p4_tests/p4_16/customer/extreme/p4c-1308-a.p4
)

p4c_add_xfail_reason("tofino2"
  "the packing is too complicated due to a too complex container instruction with a speciality action data combined with other action data"
  extensions/p4_tests/p4_16/customer/extreme/p4c-1308-d.p4
)

p4c_add_xfail_reason("tofino2"
  "Field .* is not a member of structure header .*"
  extensions/p4_tests/p4_16/customer/extreme/p4c-1802.p4
)

p4c_add_xfail_reason("tofino2"
  "Use of uninitialized parser value"
  extensions/p4_tests/p4_16/customer/extreme/p4c-1561.p4
  extensions/p4_tests/p4_16/customer/extreme/p4c-1740.p4
)

p4c_add_xfail_reason("tofino2"
  "Name '.*' is used for multiple Register objects in the P4Info message"
  p4_16_internal_p4_16_t2na_fifo
  p4_16_internal_p4_16_t2na_pgr
)

# P4C-2091
# Expected failure (negative test)
p4c_add_xfail_reason("tofino2"
  "error.*PHV allocation was not successful"
  extensions/p4_tests/p4_16/compile_only/p4c-2091.p4
)
