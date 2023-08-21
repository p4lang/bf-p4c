# XFAILS: tests that *temporarily* fail
# =====================================
#
# Xfails are _temporary_ failures: the tests should work but we haven't fixed
# the compiler yet.
#
# Tests that are _always_ expected to fail should be placed in an 'errors'
# directory, e.g., p4-tests/p4_16/errors/, and added to JBayErrors.cmake.


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

if (ENABLE_STF2PTF AND PTF_REQUIREMENTS_MET)
endif() # ENABLE_STF2PTF AND PTF_REQUIREMENTS_MET

p4c_add_xfail_reason("tofino2"
  "Field clone_spec is not a member of structure struct standard_metadata"
  extensions/p4_tests/p4_16/compile_only/clone-bmv2.p4
  extensions/p4_tests/p4_16/compile_only/clone-bmv2-i2e-and-e2e.p4
)

p4c_add_xfail_reason("tofino2"
  "The stage specified for table .* is .*, but we could not place it until stage .*"
  # P4C-3093
  extensions/p4_tests/p4_16/jbay/ghost3.p4
)

p4c_add_xfail_reason("tofino2"
  "error: .*: unsupported 64-bit select"
  testdata/p4_14_samples/simple_nat.p4
  testdata/p4_14_samples/copy_to_cpu.p4
  testdata/p4_14_samples/axon.p4
  testdata/p4_14_samples/source_routing.p4
)

p4c_add_xfail_reason("tofino2"
  "This action requires hash, which can only be done through the hit pathway"
  testdata/p4_14_samples/acl1.p4
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
  "There are issues with the following indirect externs"
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
  "table t1 Cannot match on more than one LPM field"
  testdata/p4_14_samples/issue60.p4
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
  "multiple varbit fields in a parser state are currently unsupported"
  testdata/p4_14_samples/issue576.p4
)

p4c_add_xfail_reason("tofino2"
  "Assignment source cannot be evaluated in the parser"
  testdata/p4_14_samples/TLV_parsing.p4
)

p4c_add_xfail_reason("tofino2"
  "Unsupported type argument for Value Set"
  testdata/p4_14_samples/parser_value_set2.p4
)

p4c_add_xfail_reason("tofino2"
  "This program violates action constraints imposed by|Trivial allocator has found unsatisfiable constraints"
  extensions/p4_tests/p4_16/ptf/int_transit.p4
)

p4c_add_xfail_reason("tofino2"
  "Destination of saturation add was allocated to bigger container than the field itself.*"
  extensions/p4_tests/p4_16/compile_only/p4c-3172-xfail.p4
)

# These tests fail at runtime with the driver
if (PTF_REQUIREMENTS_MET)

p4c_add_xfail_reason("tofino2"
  "AssertionError: Expected packet was not received on device .*, port .*"
  extensions/p4_tests/p4_16/ptf/ingress_checksum.p4
  tor.p4
)

endif() # PTF_REQUIREMENTS_MET

# don't support splitting counters, as they are not tracked in attached_info.cpp
p4c_add_xfail_reason("tofino2"
  "error: .*could not fit .* along with .* Counter"
  testdata/p4_14_samples/counter5.p4
)

p4c_add_xfail_reason("tofino2"
  "condition expression too complex"
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
  # Checksum16 is deprecated
  extensions/p4_tests/p4_16/stf/ipv4_options.p4
  testdata/p4_14_samples/packet_redirect.p4
  # truncate is not supported in jna
  testdata/p4_14_samples/truncate.p4
)

# P4C-1011
p4c_add_xfail_reason("tofino2"
  "standard_metadata.mcast_grp is not accessible in the egress pipe"
  extensions/p4_tests/p4_16/bf_p4c_samples/v1model-special-ops-bmv2.p4
)

p4c_add_xfail_reason("tofino2"
  "Varbit field size expression evaluates to non byte-aligned value"
  extensions/p4_tests/p4_16/compile_only/p4c-1478-neg.p4
  )

# Expected failure
p4c_add_xfail_reason("tofino2"
  "error: standard_metadata.packet_length is not accessible in the ingress pipe"
  testdata/p4_14_samples/p414-special-ops-2-bmv2.p4
  testdata/p4_14_samples/p414-special-ops-3-bmv2.p4
  )

p4c_add_xfail_reason("tofino2"
  "HashAlgorithm_t.CSUM16: Invalid enum tag"
  testdata/p4_14_samples/issue894.p4
)

# Not being tracked by JBay regression yet
p4c_add_xfail_reason("tofino2"
  "Field key is not a member of header pktgen_recirc_header_t"
  extensions/p4_tests/p4-programs/programs/stful/stful.p4
)

p4c_add_xfail_reason("tofino2"
  "This program violates action constraints imposed by Tofino2"
  # P4C-3155
  extensions/p4_tests/p4_16/customer/extreme/p4c-1323-c2.p4
  extensions/p4_tests/p4_16/customer/extreme/p4c-1680-2.p4
)

p4c_add_xfail_reason("tofino2"
  "Use of uninitialized parser value"
  testdata/p4_14_samples/issue2196.p4
)

p4c_add_xfail_reason("tofino2"
  "error: Unable to resolve extraction source. This is likely due to the source having no absolute offset from the state"
  extensions/p4_tests/p4_16/compile_only/simple_l3_mcast.p4
)

p4c_add_xfail_reason("tofino2"
  "Name '.*' is used for multiple Register objects in the P4Info message"
  p4_16_internal_p4_16_t2na_fifo
)

# P4C-2091
# Expected failure (negative test)
p4c_add_xfail_reason("tofino2"
  "error.*PHV allocation was not successful|Trivial allocator has found unsatisfiable constraints"
  extensions/p4_tests/p4_16/compile_only/p4c-2091.p4
)

# Negative tests to test slice list creation
p4c_add_xfail_reason("tofino2"
  "you can introduce padding fields"
  extensions/p4_tests/p4_16/compile_only/p4c-1892.p4
)

if (NOT TEST_ALT_PHV_ALLOC)
    # action synthesis can't figure out it can use an OR to set a single bit.
    p4c_add_xfail_reason("tofino2"
      "the program requires an action impossible to synthesize for Tofino2 ALU"
      extensions/p4_tests/p4_14/stf/stateful4.p4
    )
endif()

p4c_add_xfail_reason("tofino2"
  "unexpected packet output on port 0"
  extensions/p4_tests/p4_14/stf/egress_port_init.p4
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

# P4C-2694 - saturating arithmetic exceeding container width
p4c_add_xfail_reason("tofino2"
  "Saturating arithmetic operators may not exceed maximum PHV container width"
  extensions/p4_tests/p4_16/compile_only/p4c-2694.p4
)

# P4C-2886
p4c_add_xfail_reason("tofino2"
  "CRASH with signal 6"
  extensions/p4_tests/p4_16/stf/parser_loop_2.p4
  extensions/p4_tests/p4_16/stf/parser_counter_12.p4
)

# Negative test, expected xfail
p4c_add_xfail_reason("tofino2"
  "error: table .*: Number of partitions are specified for table .* but the partition index .* is not found"
  extensions/p4_tests/p4_16/compile_only/atcam_match_wide1-neg.p4
)

# P4C-2141
p4c_add_xfail_reason("tofino2"
  "mismatch from expected"
  extensions/p4_tests/p4_14/stf/parser_error.p4
)

p4c_add_xfail_reason("tofino2"
  "error: Cannot find a slicing to satisfy @pa_container_size|NO_SLICING_FOUND"
  extensions/p4_tests/p4_16/compile_only/ssub_illegal_pack.p4
)

p4c_add_xfail_reason("tofino2"
  "Could not place table .* table .* could not fit|The ability to split directly addressed counters/meters/stateful resources across multiple logical tables of an algorithmic tcam match table is not currently supported"
  extensions/p4_tests/p4_16/compile_only/p4c-1601-neg.p4
)

p4c_add_xfail_reason("tofino2"
  "Inconsistent mirror selectors"
  extensions/p4_tests/p4_16/compile_only/mirror_5.p4
)

p4c_add_xfail_reason("tofino2"
  "PHV allocation was not successful|PHV fitting failed, 1 clusters cannot be allocated."
  extensions/p4_tests/p4_16/stf/auto_init_meta2.p4
)

# P4C-3070
# This is a MustPass test, so we add an -Xp4c=--disable_split_attached in JBayTests.cmake
# to make it pass.  If that is removed, this failure will occur.
#p4c_add_xfail_reason("tofino2"
#  "Compiler Bug.*: Inconsistent tables added on merging program paths"
#  extensions/p4_tests/p4_16/customer/keysight/keysight-tf2.p4
#)

p4c_add_xfail_reason("tofino2"
  "warning: AssignmentStatement: Padding fields do not need to be explicitly set.* Tofino2 does not support action data/constant with rotated PHV source at the same time|Trivial allocator has found unsatisfiable constraints|PHV allocation creates an invalid container action within a Tofino ALU"
  extensions/p4_tests/p4_16/compile_only/p4c-3453.p4
)

p4c_add_xfail_reason("tofino2"
  "AssertionError: Expected packet was not received on device .*, port .*|array index 32 out of bounds"
  p4c-3614
)

p4c_add_xfail_reason("tofino2"
  "Ran out of parser match registers for .*"
  # P4C-3473
  extensions/p4_tests/p4_16/customer/extreme/p4c-3473-a2.p4
)

# This is really expected to fail (with this particular error message)
p4c_add_xfail_reason("tofino2"
   "error: Inferred incompatible container alignments for field egress::eg_md.field:[\r\n\t ]*.*p4c-3431.p4.77.: alignment = 6 .*[\r\n\t ]*.*eg_md.field = parse_1_md.field.*[\r\n\t ]*.*[\r\n\t ]*Previously inferred alignments:[\r\n\t ]*.*p4c-3431.p4.68.: alignment = 0 .*[\r\n\t ]*.*eg_md.field = hdr.field"
   extensions/p4_tests/p4_16/compile_only/p4c-3431.p4
)

# P4C-3402
p4c_add_xfail_reason("tofino2"
  "error: Two or more assignments of .* inside the register action .* are not mutually exclusive and thus cannot be implemented in Tofino Stateful ALU."
  extensions/p4_tests/p4_16/compile_only/p4c-3402.p4
)

p4c_add_xfail_reason("tofino2"
  "error: You can only have more than one binary operator in a statement"
  extensions/p4_tests/p4_16/compile_only/p4c-3402-err.p4
)

# pd scripts have problems with tofino2?
p4c_add_xfail_reason("tofino2"
  "error This program is intended to compile for Tofino P4 architecture only"
  extensions/p4_tests/p4_14/ptf/sful_split1.p4
)

if (NOT TEST_ALT_PHV_ALLOC)
    # P4C-3914
    p4c_add_xfail_reason("tofino2"
      "error: Size of learning quanta is [0-9]+ bytes, greater than the maximum allowed 48 bytes.
Compiler will improve allocation of learning fields in future releases.
Temporary fix: try to apply @pa_container_size pragma to small fields allocated to large container in. Here are possible useful progmas you can try: .*"
      extensions/p4_tests/p4_16/compile_only/p4c-3914.p4
    )
endif()

# P4C-3922 - Fail with both python3 + bf-pktpy and python2 + scapy environments
p4c_add_xfail_reason("tofino2"
  "AssertionError: Expected packet was not received"
  extensions/p4_tests/p4_16/ptf/ONLab_packetio.p4  # WORKS WITH TOFINO1 !!!
)

if (NOT TEST_ALT_PHV_ALLOC)
    # P4C-3876 / P4C-3999
    p4c_add_xfail_reason("tofino2"
      "AssertionError: Expected packet was not received"
      extensions/p4_tests/p4_14/ptf/inner_checksum_l4.p4
    )
endif()

# Tracked in P4C-3328
p4c_add_xfail_reason("tofino2"
  "AssertionError: Expected packet was not received on device .*, port .*."
  p4c_3043
)

# P4C-3220
p4c_add_xfail_reason("tofino2"
  "error: Incompatible outputs in RegisterAction: mem_lo and mem_hi"
  extensions/p4_tests/p4_16/compile_only/p4c-3220_1.p4
)

# P4C-4498
p4c_add_xfail_reason("tofino2"
  "error: table .* should not have empty const entries list."
  extensions/p4_tests/p4_16/compile_only/p4c-4498.p4
)

# ALT-PHV: tests that do not work yet with the alternative allocator.
# If you make an ALT-PHV test pass (or get close to it but if fails on later
# error), please update the xfails accordingly.
if (TEST_ALT_PHV_ALLOC)
    p4c_add_xfail_reason("tofino2"
        "FAIL: switch_acl.ACLTest"
        smoketest_switch_16_y2
    )
endif (TEST_ALT_PHV_ALLOC)

if (NOT TEST_ALT_PHV_ALLOC)
    # Failure only with traditional compilation.
    p4c_add_xfail_reason("tofino2"
        "PHV allocation was not successful"
        extensions/p4_tests/p4_16/customer/kaloom/p4c-5223-leaf-tof2.p4
    )                        

    # Failed after P4C-4507
    p4c_add_xfail_reason("tofino2"
      "tofino2 supports up to 20 stages, using|error: table allocation .* 20 stages. Allocation state: ALT_FINALIZE_TABLE"
      extensions/p4_tests/p4_16/compile_only/p4c-3175.p4
    )

endif()
