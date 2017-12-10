set (JBAY_XFAIL_TESTS
  # this is intentionally empty because xfails should be added with a reason.
  # look for the failure message in this file and add to an existing ticket
  # or open a new one.
  )

# These tests compile successfuly and fail in the model when running the STF test
# the reasons need more characterization
if (HARLYN_STF_jbay AND NOT ENABLE_STF2PTF)

  p4c_add_xfail_reason("jbay"
    ".*"

    # "jbay::MauSramRowReg::oflo_rd_b.* Assertion `(!kMemoryCoreSplit)"
    testdata/p4_14_samples/exact_match3.p4
    testdata/p4_14_samples/exact_match5.p4
    testdata/p4_14_samples/counter4.p4
  )

  p4c_add_xfail_reason("jbay"
    ".* expected packet.* on port .* not seen"

    testdata/p4_14_samples/repeater.p4
    testdata/p4_14_samples/gateway2.p4
    testdata/p4_14_samples/gateway3.p4
    testdata/p4_14_samples/action_chain1.p4

    # "ERROR: .*mau-instr-store-common.cpp.* (instr_add_simple_op)"
    testdata/p4_14_samples/gateway4.p4
    testdata/p4_14_samples/gateway5.p4
    testdata/p4_14_samples/gateway6.p4
    testdata/p4_14_samples/gateway7.p4
    testdata/p4_14_samples/gateway8.p4

    # "ERROR: .*mau-dependencies.cpp.* (report_bad_delay)"
    testdata/p4_14_samples/hash_action_gateway.p4
    testdata/p4_14_samples/07-MultiProtocol.p4
    testdata/p4_14_samples/hash_action_two_separate.p4
    testdata/p4_14_samples/hash_action_basic.p4
  )

  p4c_add_xfail_reason("jbay"
    "PHV allocation creates a container action impossible"
    testdata/p4_14_samples/instruct5.p4
  )
endif() # HARLYN_STF

# BEGIN: XFAILS that match glass XFAILS
#END: XFAILS that match glass XFAILS

if (ENABLE_STF2PTF AND PTF_REQUIREMENTS_MET)
endif() # ENABLE_STF2PTF AND PTF_REQUIREMENTS_MET

p4c_add_xfail_reason("jbay"
  "used by both ingress and egress deparser"
  )

p4c_add_xfail_reason("jbay"
  "Ran out of tcam space in .* parser"
  testdata/p4_14_samples/issue583.p4
  )

p4c_add_xfail_reason("jbay"
  "PHV allocation was not successful"
  testdata/p4_14_samples/01-BigMatch.p4
  testdata/p4_14_samples/02-FullPHV1.p4
  testdata/p4_14_samples/03-FullPHV2.p4
  testdata/p4_14_samples/05-FullTPHV.p4
  testdata/p4_14_samples/06-FullTPHV1.p4
  testdata/p4_14_samples/07-FullTPHV2.p4
  testdata/p4_14_samples/08-FullTPHV3.p4
  testdata/p4_14_samples/action_bus1.p4
  testdata/p4_14_samples/hash_action_two_same.p4
  testdata/p4_14_samples/parser1.p4
  testdata/p4_14_samples/parser2.p4
  testdata/p4_14_samples/parser4.p4
  testdata/p4_14_samples/parser_dc_full.p4
  testdata/p4_14_samples/port_vlan_mapping.p4
  testdata/p4_14_samples/source_routing.p4
  )

p4c_add_xfail_reason("jbay"
  "JBay requires byte-aligned headers, but header .* is not byte-aligned"
  testdata/p4_14_samples/02-BadSizeField.p4
  testdata/p4_14_samples/14-SplitEthernetVlan.p4
  testdata/p4_14_samples/14-GatewayGreaterThan.p4
  )

p4c_add_xfail_reason("jbay"
  "Wrong number of arguments for method call: packet.extract"
  testdata/p4_14_samples/09-IPv4OptionsUnparsed.p4
  testdata/p4_14_samples/issue781.p4
  )

p4c_add_xfail_reason("jbay"
  "No field named .*_addr in format"
  testdata/p4_14_samples/13-Counters1and2.p4
  testdata/p4_14_samples/14-Counter.p4
  )

p4c_add_xfail_reason("jbay"
  "Table .* is applied multiple times, and the next table information cannot correctly propagate through this multiple application"
  testdata/p4_14_samples/16-TwoReferences.p4
  )

p4c_add_xfail_reason("jbay"
  "PHV allocation creates a container action impossible within a Tofino ALU"
  testdata/p4_14_samples/action_inline.p4
  testdata/p4_14_samples/instruct1.p4
  )

p4c_add_xfail_reason("jbay"
  "error: Assignment cannot be supported in the parser"
  testdata/p4_14_samples/axon.p4
  )

p4c_add_xfail_reason("jbay"
  "FIXME method call checksum.update in deparser not yet supported"
  testdata/p4_14_samples/basic_routing.p4
  testdata/p4_14_samples/checksum1.p4
  testdata/p4_14_samples/checksum.p4
  testdata/p4_14_samples/issue894.p4
  testdata/p4_14_samples/simple_router.p4
  )


p4c_add_xfail_reason("jbay"
  "error: Could not find declaration for .*"
  testdata/p4_14_samples/copy_to_cpu.p4
  testdata/p4_14_samples/issue1058.p4
  testdata/p4_14_samples/packet_redirect.p4
  testdata/p4_14_samples/queueing.p4
  testdata/p4_14_samples/resubmit.p4
  testdata/p4_14_samples/simple_nat.p4
  )

p4c_add_xfail_reason("jbay"
  "Tofino does not allow stats to use different address schemes on one table."
  testdata/p4_14_samples/counter.p4
  )

p4c_add_xfail_reason("jbay"
  "error: : The hash offset must be a power of 2 in a hash calculation"
  testdata/p4_14_samples/flowlet_switching.p4
  )

p4c_add_xfail_reason("jbay"
  "error: Syntax error,"
  testdata/p4_14_samples/issue1013.p4
  testdata/p4_14_samples/issue1057.p4
  )

p4c_add_xfail_reason("jbay"
  ": P4_14 extern type not fully supported"
  testdata/p4_14_samples/issue604.p4
  )

p4c_add_xfail_reason("jbay"
  "Unhandled action bitmask constraint"
  testdata/p4_14_samples/mac_rewrite.p4
  )

p4c_add_xfail_reason("jbay"
  "Structure header ingress_intrinsic_metadata_t does not have a field ucast_egress_port"
  testdata/p4_14_samples/sai_p4.p4
  )

p4c_add_xfail_reason("jbay"
  "error: No format in action table"
  testdata/p4_14_samples/selector0.p4
  )

p4c_add_xfail_reason("jbay"
  "Compiler Bug.*: .*: Cannot find declaration for"
  testdata/p4_14_samples/TLV_parsing.p4
  )

