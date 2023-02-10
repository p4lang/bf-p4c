# XFAILS: tests that *temporarily* fail
# =====================================
#
# Xfails are _temporary_ failures: the tests should work but we haven't fixed
# the compiler yet.
#
# Tests that are _always_ expected to fail should be placed in an 'errors'
# directory, e.g., p4-tests/p4_16/errors/, and added to CloudbreakErrors.cmake.

set (CLOUDBREAK_XFAIL_TESTS
  # this is intentionally empty because xfails should be added with a reason.
  # look for the failure message in this file and add to an existing ticket
  # or open a new one.
  )

## Initial failures copied from JBayXFail.cmake

# These tests compile successfuly and fail in the model when running the STF test
# the reasons need more characterization
if (HARLYN_STF_cb AND NOT ENABLE_STF2PTF)

  # ingress_port isn't being setup properly (STF harness bug)
  p4c_add_xfail_reason("tofino3"
    ".* expected packet.* on port .* not seen"
    #testdata/p4_14_samples/gateway1.p4
    #testdata/p4_14_samples/gateway2.p4
    #testdata/p4_14_samples/gateway3.p4
    #testdata/p4_14_samples/gateway4.p4
  )

  p4c_add_xfail_reason("tofino3"
    "mismatch from expected"
    extensions/p4_tests/p4_16/stf/parser_error.p4)

  # needs strided CLOT alloc
  p4c_add_xfail_reason("tofino3"
    ".* expected packet.* on port .* not seen|shorter than expected"
    extensions/p4_tests/p4_16/stf/parser_loop_3.p4
    #extensions/p4_tests/p4_16/stf/parser_loop_4.p4
    extensions/p4_tests/p4_16/stf/header_stack_strided_alloc1.p4
    extensions/p4_tests/p4_16/stf/header_stack_strided_alloc2.p4
  )

  p4c_add_xfail_reason("tofino3"
    "mismatch from expected"
    extensions/p4_tests/p4_16/stf/parser_loop_4.p4
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
  "table .* Cannot match on multiple fields using the LPM match type"
  #testdata/p4_14_samples/issue60.p4
  )

#END: XFAILS that match glass XFAILS

if (ENABLE_STF2PTF AND PTF_REQUIREMENTS_MET)
endif() # ENABLE_STF2PTF AND PTF_REQUIREMENTS_MET

p4c_add_xfail_reason("tofino3"
  "address too large for table"
  #testdata/p4_14_samples/saturated-bmv2.p4
)

p4c_add_xfail_reason("tofino3"
  "Field clone_spec is not a member of structure struct standard_metadata"
  extensions/p4_tests/p4_16/compile_only/clone-bmv2.p4
  extensions/p4_tests/p4_16/compile_only/clone-bmv2-i2e-and-e2e.p4
)

p4c_add_xfail_reason("tofino3"
  "error: Assignment source cannot be evaluated in the parser"
  #testdata/p4_14_samples/axon.p4
  #testdata/p4_14_samples/simple_nat.p4
)

p4c_add_xfail_reason("tofino3"
  "This action requires hash, which can only be done through the hit pathway"
  #testdata/p4_14_samples/acl1.p4
  extensions/p4_tests/p4_16/jbay/hwlearn4.p4
)

p4c_add_xfail_reason("tofino3"
# Fail on purpose due to indirect tables not being mutually exclusive
  "table .* and table .* cannot share Counter .* because use of the Counter .* is not mutually exclusive"
  #testdata/p4_14_samples/12-Counters.p4
  #testdata/p4_14_samples/13-Counters1and2.p4
)

p4c_add_xfail_reason("tofino3"
  "error: standard_metadata.packet_length is not accessible in the ingress pipe"
  #testdata/p4_14_samples/queueing.p4
)

p4c_add_xfail_reason("tofino3"
  "There are issues with the following indirect externs"
  #testdata/p4_14_samples/counter.p4
)

p4c_add_xfail_reason("tofino3"
  "Only compile-time constants are supported for hash base offset and max value"
  #testdata/p4_14_samples/flowlet_switching.p4
)

p4c_add_xfail_reason("tofino3"
  ": P4_14 extern type not fully supported"
  #testdata/p4_14_samples/issue604.p4
)

p4c_add_xfail_reason("tofino3"
  "error: .*: no such field in standard_metadata"
  extensions/p4_tests/p4_14/bf_p4c_samples/sai_p4.p4
)

p4c_add_xfail_reason("tofino3"
  "standard_metadata.* is not accessible in the ingress pipe"
  #testdata/p4_14_samples/p414-special-ops.p4
)

p4c_add_xfail_reason("tofino3"
  "Action profile .* does not have any action data"
  #testdata/p4_14_samples/selector0.p4
  extensions/p4_tests/p4_14/bf_p4c_samples/port_vlan_mapping.p4
  #testdata/p4_14_samples/const_default_action.p4
)

p4c_add_xfail_reason("tofino3"
  "error: .*: action spanning multiple stages."
  #testdata/p4_14_samples/action_inline.p4
)

p4c_add_xfail_reason("tofino3"
  "multiple varbit fields in a parser state are currently unsupported"
  #testdata/p4_14_samples/issue576.p4
)

p4c_add_xfail_reason("tofino3"
  "Assignment source cannot be evaluated in the parser"
  #testdata/p4_14_samples/TLV_parsing.p4
)

p4c_add_xfail_reason("tofino3"
  "Unsupported type argument for Value Set"
  #testdata/p4_14_samples/parser_value_set2.p4
)

p4c_add_xfail_reason("tofino3"
  "error: This program violates action constraints imposed by Tofino3|error: Trivial allocator has found unsatisfiable constraints."
  extensions/p4_tests/p4_16/customer/kaloom/p4c-2573-spine.p4
  extensions/p4_tests/p4_16/customer/kaloom/p4c-2410-spine.p4
  extensions/p4_tests/p4_16/customer/kaloom/spine-app.p4
)

p4c_add_xfail_reason("tofino3"
  "error: This program violates action constraints imposed by Tofino3|error: Trivial allocator has found unsatisfiable constraints."
  extensions/p4_tests/p4_16/ptf/int_transit.p4
)

# These tests fail at runtime with the driver
if (PTF_REQUIREMENTS_MET)

# P4C-1228
#p4c_add_xfail_reason("tofino3"
#  "OSError: .* No such file or directory"
#  extensions/p4_tests/p4-programs/programs/multicast_test/multicast_test.p4
#  )

endif() # PTF_REQUIREMENTS_MET

p4c_add_xfail_reason("tofino3"
  "error: .*could not fit .* along with .* Counter"
  #testdata/p4_14_samples/counter5.p4
)

p4c_add_xfail_reason("tofino3"
  "condition expression too complex"
  #testdata/p4_14_samples/header-stack-ops-bmv2.p4
)

p4c_add_xfail_reason("tofino3"
  "The meter .* requires either an idletime or stats address bus"
  #testdata/p4_14_samples/hash_action_two_same.p4
)

# P4C-539
p4c_add_xfail_reason("tofino3"
  "error: .*: declaration not found"
  # We fail to translate `generate_digest()`.
  #testdata/p4_14_samples/issue1058.p4
  # Checksum16 is deprecated
  extensions/p4_tests/p4_16/stf/ipv4_options.p4
  # We fail to translate `standard_metadata.instance_type`.
  #testdata/p4_14_samples/copy_to_cpu.p4
  #testdata/p4_14_samples/packet_redirect.p4
  # truncate is not supported in jna
  #testdata/p4_14_samples/truncate.p4
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

# Expected failure
p4c_add_xfail_reason("tofino3"
  "error: standard_metadata.packet_length is not accessible in the ingress pipe"
  #testdata/p4_14_samples/p414-special-ops-2-bmv2.p4
  #testdata/p4_14_samples/p414-special-ops-3-bmv2.p4
  )

p4c_add_xfail_reason("tofino3"
  "HashAlgorithm_t.CSUM16: Invalid enum tag"
  #testdata/p4_14_samples/issue894.p4
)

# Not being tracked by JBay regression yet
#p4c_add_xfail_reason("tofino3"
#  "Field key is not a member of header pktgen_recirc_header_t"
#  extensions/p4_tests/p4-programs/programs/stful/stful.p4
#)

#p4c_add_xfail_reason("tofino3"
#  "Name '.*' is used for multiple Register objects in the P4Info message"
#  p4_16_internal_p4_16_t2na_fifo
#)

# P4C-2091
# Expected failure (negative test)
p4c_add_xfail_reason("tofino3"
  "error.*PHV allocation was not successful|error: Trivial allocator has found unsatisfiable constraints."
  extensions/p4_tests/p4_16/compile_only/p4c-2091.p4
)

# Negative tests to test slice list creation
p4c_add_xfail_reason("tofino3"
  "you can introduce padding fields"
  extensions/p4_tests/p4_16/compile_only/p4c-1892.p4
)

if (NOT TEST_ALT_PHV_ALLOC)
    # action synthesis can't figure out it can use an OR to set a single bit.
    p4c_add_xfail_reason("tofino3"
      "the program requires an action impossible to synthesize for Tofino3 ALU"
      extensions/p4_tests/p4_14/stf/stateful4.p4
    )
endif()

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
  # Is this test even supported in compilers dev env?
  # Hitting BF_DVM ERROR - Program "tna_32q_2pipe" Pipeline "pipeline_profile_a" cannot be assigned to device 0 pipe 4, only 4 pipe(s) available
  # Need to debug
  p4_16_programs_tna_32q_2pipe
)

# ports are 11 bits on cloudbreak, so programs that assume 9 bits won't work
p4c_add_xfail_reason("tofino3"
  "Cannot cast implicitly type"
  extensions/p4_tests/p4_14/stf/egress_port_init.p4
  extensions/p4_tests/p4_14/stf/p4c-3551.p4
  extensions/p4_tests/p4_16/compile_only/empty_header_stack.p4
  extensions/p4_tests/p4_16/compile_only/inline_subparser.p4
  extensions/p4_tests/p4_16/compile_only/p4c-1601-neg.p4
  extensions/p4_tests/p4_16/compile_only/p4c-1719.p4
  extensions/p4_tests/p4_16/compile_only/p4c-2490.p4
  extensions/p4_tests/p4_16/compile_only/p4c-3453.p4
  extensions/p4_tests/p4_16/compile_only/too_many_pov_bits.p4
  extensions/p4_tests/p4_16/customer/extreme/npb-master-20210108.p4
  extensions/p4_tests/p4_16/customer/extreme/npb-master-20210202.p4
  extensions/p4_tests/p4_16/customer/extreme/npb-master-20210211.p4
  extensions/p4_tests/p4_16/customer/extreme/npb-master-20210225.p4
  extensions/p4_tests/p4_16/customer/extreme/npb-master-20210301.p4
  extensions/p4_tests/p4_16/customer/extreme/p4c-1308-b.p4
  extensions/p4_tests/p4_16/customer/extreme/p4c-1323-b.p4
  extensions/p4_tests/p4_16/customer/extreme/p4c-1323-c2.p4
  extensions/p4_tests/p4_16/customer/extreme/p4c-1326.p4
  extensions/p4_tests/p4_16/customer/extreme/p4c-1492.p4
  extensions/p4_tests/p4_16/customer/extreme/p4c-1557.p4
  extensions/p4_tests/p4_16/customer/extreme/p4c-1559.p4
  extensions/p4_tests/p4_16/customer/extreme/p4c-1560.p4
  extensions/p4_tests/p4_16/customer/extreme/p4c-1562-1.p4
  extensions/p4_tests/p4_16/customer/extreme/p4c-1562-2.p4
  extensions/p4_tests/p4_16/customer/extreme/p4c-1572-a.p4
  extensions/p4_tests/p4_16/customer/extreme/p4c-1585-a.p4
  extensions/p4_tests/p4_16/customer/extreme/p4c-1586.p4
  extensions/p4_tests/p4_16/customer/extreme/p4c-1587-a.p4
  extensions/p4_tests/p4_16/customer/extreme/p4c-1599.p4
  extensions/p4_tests/p4_16/customer/extreme/p4c-1680-2.p4
  extensions/p4_tests/p4_16/customer/extreme/p4c-2238.p4
  extensions/p4_tests/p4_16/customer/extreme/p4c-2262-2.p4
  extensions/p4_tests/p4_16/customer/extreme/p4c-2358-2.p4
  extensions/p4_tests/p4_16/customer/extreme/p4c-2641.p4
  extensions/p4_tests/p4_16/customer/extreme/p4c-2649.p4
  extensions/p4_tests/p4_16/customer/extreme/p4c-2794.p4
  extensions/p4_tests/p4_16/customer/extreme/p4c-2918-2.p4
  extensions/p4_tests/p4_16/customer/extreme/p4c-3001.p4
  extensions/p4_tests/p4_16/customer/extreme/p4c-3030-2.p4
  extensions/p4_tests/p4_16/customer/extreme/p4c-3454.p4
  extensions/p4_tests/p4_16/customer/extreme/p4c-3455.p4
  extensions/p4_tests/p4_16/customer/extreme/p4c-3455_2.p4
  extensions/p4_tests/p4_16/customer/extreme/p4c-3476.p4
  extensions/p4_tests/p4_16/customer/keysight/keysight-tf2.p4
  extensions/p4_tests/p4_16/customer/keysight/pktgen9_16.p4
  extensions/p4_tests/p4_16/customer/keysight/p4c-2554.p4
  extensions/p4_tests/p4_16/customer/microsoft/p4c-2387.p4
  extensions/p4_tests/p4_16/ptf/digest.p4
  extensions/p4_tests/p4_16/ptf/ONLab_packetio.p4
)

p4c_add_xfail_reason("tofino3"
  "<: not defined on bit<11> and bit<9>"
  # Caused by the fact that port number in v1model is bit<9> but in Tofino 3 port
  # number is bit<11> and type inference of the constants happens before translation
  # from v1model to t3na architecture.
  # Therefore this error happens during translation from v1model to t3na.
  extensions/p4_tests/p4_16/ptf/hash_driven_stats.p4
)

p4c_add_xfail_reason("tofino3"
  "Cannot operate on values with different types"
  #testdata/p4_14_samples/issue-1426.p4
)

# pd scripts have problems with tofino3?
p4c_add_xfail_reason("tofino3"
  "error This program is intended to compile for Tofino P4 architecture only"
  extensions/p4_tests/p4_14/ptf/sful_split1.p4
  extensions/p4_tests/p4_14/ptf/p4c_1962.p4
)

p4c_add_xfail_reason("tofino3"
  "with type 'bit<9>' cannot be compared to .* with type 'bit<11>"
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
  #testdata/p4_14_samples/issue2196.p4
)

p4c_add_xfail_reason("tofino3"
  "error: Unable to resolve extraction source. This is likely due to the source having no absolute offset from the state"
  extensions/p4_tests/p4_16/compile_only/simple_l3_mcast.p4
)

# P4C-2694 - saturating arithmetic exceeding container width
p4c_add_xfail_reason("tofino3"
  "Saturating arithmetic operators may not exceed maximum PHV container width"
  extensions/p4_tests/p4_16/compile_only/p4c-2694.p4
)

# P4C-2836
p4c_add_xfail_reason("tofino3"
  "error: Some fields cannot be allocated because of unsatisfiable constraints.|error: Trivial allocator has found unsatisfiable constraints."
  extensions/p4_tests/p4_16/compile_only/ssub_illegal_pack.p4
)

p4c_add_xfail_reason("tofino3"
  "CRASH with signal 6"
  # P4C-2886
  extensions/p4_tests/p4_16/stf/parser_loop_2.p4
  extensions/p4_tests/p4_16/stf/parser_counter_12.p4
  extensions/p4_tests/p4_16/stf/parser_loop_1.p4
)

p4c_add_xfail_reason("tofino3"
  "Inconsistent mirror selectors"
  extensions/p4_tests/p4_16/compile_only/mirror_5.p4
)

p4c_add_xfail_reason("tofino3"
  "PHV allocation was not successful|PHV fitting failed, 1 clusters cannot be allocated."
  extensions/p4_tests/p4_16/stf/auto_init_meta2.p4
)

# Negative test, expected xfail
p4c_add_xfail_reason("tofino3"
  "error: table .*: Number of partitions are specified for table .* but the partition index .* is not found"
  extensions/p4_tests/p4_16/compile_only/atcam_match_wide1-neg.p4
)

# P4C-2141
p4c_add_xfail_reason("tofino3"
  "mismatch from expected"
  extensions/p4_tests/p4_14/stf/parser_error.p4
)

# digest fields related failures or expected to fail.
p4c_add_xfail_reason("tofino3"
  "invalid SuperCluster was formed"
  #testdata/p4_14_samples/source_routing.p4
)

p4c_add_xfail_reason("tofino3"
  "The stage specified for table .* is .*, but we could not place it until stage .*"
  # P4C-3093
  extensions/p4_tests/p4_16/jbay/ghost3.p4
)

# P4C-3435
p4c_add_xfail_reason("tofino3"
  "1 expected packet on port 0 not seen"
  extensions/p4_tests/p4_16/stf/failed_elim_valid_bit.p4
)

# This is really expected to fail (with this particular error message)
p4c_add_xfail_reason("tofino3"
   "error: Inferred incompatible container alignments for field egress::eg_md.field:[\r\n\t ]*.*p4c-3431.p4.77.: alignment = 6 .*[\r\n\t ]*.*eg_md.field = parse_1_md.field.*[\r\n\t ]*.*[\r\n\t ]*Previously inferred alignments:[\r\n\t ]*.*p4c-3431.p4.68.: alignment = 0 .*[\r\n\t ]*.*eg_md.field = hdr.field"
   extensions/p4_tests/p4_16/compile_only/p4c-3431.p4
)

# P4C-3402
p4c_add_xfail_reason("tofino3"
  "error: Two or more assignments of .* inside the register action .* are not mutually exclusive and thus cannot be implemented in Tofino Stateful ALU."
  extensions/p4_tests/p4_16/compile_only/p4c-3402.p4
)

p4c_add_xfail_reason("tofino3"
  "error: You can only have more than one binary operator in a statement"
  extensions/p4_tests/p4_16/compile_only/p4c-3402-err.p4
)

p4c_add_xfail_reason("tofino3"
  "error: Tofino3 requires byte-aligned headers, but header bridge_h is not byte-aligned"
  extensions/p4_tests/p4_16/stf/p4c-3761.p4
)

if (NOT TEST_ALT_PHV_ALLOC)
    # P4C-3914
    p4c_add_xfail_reason("tofino3"
      "error: Size of learning quanta is [0-9]+ bytes, greater than the maximum allowed 48 bytes.
Compiler will improve allocation of learning fields in future releases.
Temporary fix: try to apply @pa_container_size pragma to small fields allocated to large container in. Here are possible useful progmas you can try: .*"
      extensions/p4_tests/p4_16/compile_only/p4c-3914.p4
    )
endif()

p4c_add_xfail_reason("tofino3"
  "cb_test_harness: .*/queueing.cpp:.* cb::Queueing::enqueue_die.*: Assertion .* failed."
  extensions/p4_tests/p4_16/stf/p4c-4055.p4
)

# P4C-3220
p4c_add_xfail_reason("tofino3"
  "error: Incompatible outputs in RegisterAction: mem_lo and mem_hi"
  extensions/p4_tests/p4_16/compile_only/p4c-3220_1.p4
)

#P4C-4498
p4c_add_xfail_reason("tofino3"
  "error: table .* should not have empty const entries list."
  extensions/p4_tests/p4_16/compile_only/p4c-4498.p4
)

# p4c_add_xfail_reason("tofino3"
#   "AssertionError: Expected packet was not received"
#   # Packet is received, but 2 bytes are different than expected for unknown reason.
#   extensions/p4_tests/p4_16/ptf/inner_checksum_payload_offset.p4
#   extensions/p4_tests/p4_14/ptf/inner_checksum_l4.p4
#   # Packet is received, but 1 byte is different than expected for unknown reason.
#   # This is already in JBay and Tofino Xfails, too.
#   extensions/p4_tests/p4_16/ptf/ingress_checksum.p4
# )

# p4c_add_xfail_reason("tofino3"
#   "Error when creating clone session in target"
#   # Error during runtime, unknown reason.
#   extensions/p4_tests/p4_16/ptf/clone_v1model.p4
# )

p4c_add_xfail_reason("tofino3"
  "error: Mixing non-greedy and greedy extracted fields in select statement is unsupported"
  extensions/p4_tests/p4_16/cloudbreak/p4c-4841.p4
)

# (2022-10-20) Tofino 3 driver does not yet support fast reconfig used by
# ptf_runner.py and there also no way to run P4 runtime tests without fast
# reconfig. So for now at least we can check that the tests compile and then
# fail in loading.
# TODO: after fixing this, uncoment the following sets of xfails above
#  - "AssertionError: Expected packet was not received"
#  - "Error when creating clone session in target"
p4c_add_xfail_reason("tofino3"
  "\"grpc_message\":\"Error in second phase of device update\""
  extensions/p4_tests/p4_14/ptf/easy.p4
  extensions/p4_tests/p4_14/ptf/easy_exact.p4
  extensions/p4_tests/p4_14/ptf/easy_no_match.p4
  extensions/p4_tests/p4_14/ptf/easy_no_match_with_gateway.p4
  extensions/p4_tests/p4_14/ptf/easy_ternary.p4
  extensions/p4_tests/p4_14/ptf/ecmp_pi.p4
  extensions/p4_tests/p4_14/ptf/inner_checksum_l4.p4
  extensions/p4_tests/p4_14/ptf/ternary_match_constant_action_data.p4
  extensions/p4_tests/p4_16/ptf/adata_constant_out_of_range_for_immediate.p4
  extensions/p4_tests/p4_16/ptf/checksum_if_else_cond.p4
  extensions/p4_tests/p4_16/ptf/clone_v1model.p4
  extensions/p4_tests/p4_16/ptf/ingress_checksum.p4
  extensions/p4_tests/p4_16/ptf/inner_checksum.p4
  extensions/p4_tests/p4_16/ptf/ipv4_checksum.p4
  extensions/p4_tests/p4_16/ptf/ipv6_checksum.p4
  extensions/p4_tests/p4_16/ptf/large_action_data_constant.p4
  extensions/p4_tests/p4_16/ptf/large_indirect_count.p4
  extensions/p4_tests/p4_16/ptf/multicast_basic.p4
  extensions/p4_tests/p4_16/ptf/options_invalid.p4
  extensions/p4_tests/p4_16/ptf/p4c-4137.p4
  extensions/p4_tests/p4_16/ptf/p4c_4490.p4
  extensions/p4_tests/p4_16/ptf/register_action_predicate.p4
  extensions/p4_tests/p4_16/ptf/saturation.p4
  extensions/p4_tests/p4_16/ptf/tofino2_a0_header_checksum_workaround.p4
  extensions/p4_tests/p4_16/ptf/udpv4_and_v6_checksum.p4
  extensions/p4_tests/p4_16/ptf/various_indirect_meters.p4
  extensions/p4_tests/p4_16/ptf/verify_checksum.p4
)

if (NOT TEST_ALT_PHV_ALLOC)
    p4c_add_xfail_reason("tofino3"
      "\"grpc_message\":\"Error in second phase of device update\""
      extensions/p4_tests/p4_16/ptf/inner_checksum_payload_offset.p4
    )
endif()

# ALT-PHV: tests that do not work yet with the alternative allocator.
# If you make an ALT-PHV test pass (or get close to it but if fails on later
# error), please update the xfails accordingly.
if (TEST_ALT_PHV_ALLOC)
    # bugs
    p4c_add_xfail_reason("tofino3"
      "bfa:.*: error: forward_if_ethernet_parsed_0 gateway sharing search bus 4.0 with table1_0, but wants a different match group"
      extensions/p4_tests/p4_16/stf/parser_scratch_reg_3.p4
    )

    # PHV errors
    p4c_add_xfail_reason("tofino3"
        "error: invalid SuperCluster was formed:"
        extensions/p4_tests/p4_16/ptf/inner_checksum_payload_offset.p4
    )

    p4c_add_xfail_reason("tofino3"
        "error: PHV allocation creates an invalid container action within a Tofino ALU"
        extensions/p4_tests/p4_16/stf/meter_dest_16_32_flexible.p4
    )

    # PTF and STF test errors
    p4c_add_xfail_reason("tofino3"
        "cb_test_harness FAILED"
        extensions/p4_tests/p4_16/stf/stage_layout1.p4
    )

    p4c_add_xfail_reason("tofino3"
        "ERROR:PTF runner:Error when running PTF tests"
        p4_16_programs_tna_action_selector
        p4_16_programs_tna_snapshot
    )

    # Tests that take way too long with ALT-PHV
    p4c_add_xfail_reason("tofino3"
        "TIMEOUT"
        extensions/p4_tests/p4_16/stf/p4c-4535.p4
    )
endif (TEST_ALT_PHV_ALLOC)
