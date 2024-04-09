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
    )

  p4c_add_xfail_reason("tofino2"
    "Assertion .* failed"  # model asserts
   extensions/p4_tests/p4_14/stf/decaf_1.p4 # 16-bit container repeated in FD
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

# These tests fail at runtime with the driver
if (PTF_REQUIREMENTS_MET)
p4c_add_xfail_reason("tofino2"
  "AssertionError: Expected packet was not received on device .*, port .*"
  extensions/p4_tests/p4_16/ptf/ingress_checksum.p4
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

p4c_add_xfail_reason("tofino2"
  "standard_metadata.mcast_grp is not accessible in the egress pipe"
  extensions/p4_tests/p4_16/bf_p4c_samples/v1model-special-ops-bmv2.p4
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

p4c_add_xfail_reason("tofino2"
  "Use of uninitialized parser value"
  testdata/p4_14_samples/issue2196.p4
)

p4c_add_xfail_reason("tofino2"
  "error: Unable to resolve extraction source. This is likely due to the source having no absolute offset from the state"
  extensions/p4_tests/p4_16/compile_only/simple_l3_mcast.p4
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

p4c_add_xfail_reason("tofino2"
  "Table .* @dynamic_table_key_masks annotation only permissible with exact matches"
  extensions/p4_tests/p4_16/compile_only/dkm_invalid.p4
)

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

p4c_add_xfail_reason("tofino2"
  "mismatch from expected"
  extensions/p4_tests/p4_14/stf/parser_error.p4
)

p4c_add_xfail_reason("tofino2"
  "error: Cannot find a slicing to satisfy @pa_container_size|NO_SLICING_FOUND"
  extensions/p4_tests/p4_16/compile_only/ssub_illegal_pack.p4
)

p4c_add_xfail_reason("tofino2"
  "Inconsistent mirror selectors"
  extensions/p4_tests/p4_16/compile_only/mirror_5.p4
)

p4c_add_xfail_reason("tofino2"
  "PHV allocation was not successful|PHV fitting failed, 1 clusters cannot be allocated."
  extensions/p4_tests/p4_16/stf/auto_init_meta2.p4
)

# pd scripts have problems with tofino2?
p4c_add_xfail_reason("tofino2"
  "error This program is intended to compile for Tofino P4 architecture only"
  extensions/p4_tests/p4_14/ptf/sful_split1.p4
)

p4c_add_xfail_reason("tofino2"
  "AssertionError: Expected packet was not received"
  extensions/p4_tests/p4_16/ptf/ONLab_packetio.p4  # WORKS WITH TOFINO1 !!!
)

p4c_add_xfail_reason("tofino2"
  "mismatch from expected(.*) at byte .*"
  extensions/p4_tests/p4_16/stf/varbit_constant.p4
)

