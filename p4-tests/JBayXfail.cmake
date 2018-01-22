set (JBAY_XFAIL_TESTS
  # this is intentionally empty because xfails should be added with a reason.
  # look for the failure message in this file and add to an existing ticket
  # or open a new one.
  )

# These tests compile successfuly and fail in the model when running the STF test
# the reasons need more characterization
if (HARLYN_STF_jbay AND NOT ENABLE_STF2PTF)

  p4c_add_xfail_reason("jbay"
    "Assertion .*kMemoryCoreSplit.* failed."

    # "jbay::MauSramRowReg::oflo_rd_b.* Assertion `(!kMemoryCoreSplit)"
    testdata/p4_14_samples/basic_routing.p4
    testdata/p4_14_samples/exact_match3.p4
    testdata/p4_14_samples/exact_match5.p4
    testdata/p4_14_samples/counter4.p4
  )

  # ingress_port isn't being setup properly (STF harness bug)
  p4c_add_xfail_reason("jbay"
    ".* expected packet.* on port .* not seen"
    testdata/p4_14_samples/repeater.p4
  )

  p4c_add_xfail_reason("jbay"
    "mismatch from expected.* at byte .*"
    testdata/p4_14_samples/bigfield1.p4
  )

endif() # HARLYN_STF

# BEGIN: XFAILS that match glass XFAILS
#END: XFAILS that match glass XFAILS

if (ENABLE_STF2PTF AND PTF_REQUIREMENTS_MET)
endif() # ENABLE_STF2PTF AND PTF_REQUIREMENTS_MET

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
  "Table .* is applied multiple times, and the next table information cannot correctly propagate through this multiple application"
  testdata/p4_14_samples/16-TwoReferences.p4
  )

p4c_add_xfail_reason("jbay"
  "PHV allocation creates a container action impossible within a Tofino ALU"
  testdata/p4_14_samples/action_inline.p4
  )

p4c_add_xfail_reason("jbay"
  "error: Assignment cannot be supported in the parser"
  testdata/p4_14_samples/axon.p4
  )


p4c_add_xfail_reason("jbay"
# Fail on purpose due to indirect tables not being mutually exclusive
  "Tables .* and .* are not mutually exclusive"
  testdata/p4_14_samples/12-Counters.p4
  testdata/p4_14_samples/13-Counters1and2.p4
  )

p4c_add_xfail_reason("jbay"
  "condition too complex"
  testdata/p4_14_samples/issue894.p4
  )

p4c_add_xfail_reason("jbay"
  "error: standard_metadata.packet_length is not accessible in the ingress pipe"
  testdata/p4_14_samples/queueing.p4
  )

p4c_add_xfail_reason("jbay"
  "error: Could not find declaration for .*"
  testdata/p4_14_samples/copy_to_cpu.p4
  testdata/p4_14_samples/issue1058.p4
  testdata/p4_14_samples/packet_redirect.p4
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
  )

p4c_add_xfail_reason("jbay"
  ": P4_14 extern type not fully supported"
  testdata/p4_14_samples/issue604.p4
  )

p4c_add_xfail_reason("jbay"
  "error: Invalid slice of .*"
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

# Brig/Glass do not follow P4_14 spec for 'drop' in the ingress pipeline
p4c_add_xfail_reason("jbay"
  "expected packet on port .* not seen"
  # CTD == these are expected to fail, but apparently drop_ctl doesn't reliably drop the packet?
  # testdata/p4_14_samples/gateway1.p4
  # testdata/p4_14_samples/gateway2.p4
  # testdata/p4_14_samples/gateway3.p4
  # testdata/p4_14_samples/gateway4.p4
  )

p4c_add_xfail_reason("jbay"
 "mismatch from expected.* at byte"
 testdata/p4_14_samples/bridge1.p4
 )

p4c_add_xfail_reason("jbay"
  "Floating point exception"
  # These tests start to fail after introducing PHV packing.
  testdata/p4_14_samples/instruct5.p4
  )

p4c_add_xfail_reason("jbay"
 "can only currently handle meter color in an 8 bit ALU operation"
 testdata/p4_14_samples/meter.p4
 testdata/p4_14_samples/meter1.p4
 )

# The following xfails are removed because of introducing the jbay-pov-hack
# "expected packet on port .* not seen"
# testdata/p4_14_samples/hash_action_two_separate.p4
# testdata/p4_14_samples/gateway7.p4
# testdata/p4_14_samples/gateway2.p4
# testdata/p4_14_samples/action_chain1.p4
# testdata/p4_14_samples/gateway6.p4
# testdata/p4_14_samples/exact_match_valid1.p4
# testdata/p4_14_samples/hash_action_gateway.p4
# testdata/p4_14_samples/gateway3.p4
# testdata/p4_14_samples/hash_action_basic.p4
# "mismatch from expected.* at byte"
# testdata/p4_14_samples/07-MultiProtocol.p4
