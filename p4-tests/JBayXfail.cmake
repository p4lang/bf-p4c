set (JBAY_XFAIL_TESTS
  # this is intentionally empty because xfails should be added with a reason.
  # look for the failure message in this file and add to an existing ticket
  # or open a new one.
  )

# All ptf tests xfail due to lack of jbay driver support...
p4c_add_xfail_reason("jbay"
  "ERROR:PTF runner:Error when running PTF tests"
  extensions/p4_tests/p4_16/ONLab_packetio.p4
  extensions/p4_tests/p4_16/ingress_checksum.p4
  )

# These tests compile successfuly and fail in the model when running the STF test
# the reasons need more characterization
if (HARLYN_STF_jbay AND NOT ENABLE_STF2PTF)

  # ingress_port isn't being setup properly (STF harness bug)
  p4c_add_xfail_reason("jbay"
    ".* expected packet.* on port .* not seen"
    testdata/p4_14_samples/repeater.p4
    extensions/p4_tests/p4_14/hash_calculation_32.p4
    testdata/p4_14_samples/gateway1.p4
    testdata/p4_14_samples/gateway2.p4
    testdata/p4_14_samples/gateway3.p4
    testdata/p4_14_samples/gateway4.p4
    testdata/p4_14_samples/basic_routing.p4
  )

  p4c_add_xfail_reason("jbay"
    "mismatch from expected.* at byte .*"
    extensions/p4_tests/p4_14/action_chain_limits.p4
    # clot-phv interaction bug?
    extensions/p4_tests/p4_16/brig-532.p4
    testdata/p4_14_samples/instruct5.p4
    testdata/p4_14_samples/bridge1.p4
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
  testdata/p4_14_samples/05-FullTPHV.p4
  testdata/p4_14_samples/06-FullTPHV1.p4
  testdata/p4_14_samples/07-FullTPHV2.p4
  testdata/p4_14_samples/08-FullTPHV3.p4
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
  extensions/p4_tests/p4_14/overlay_add_header.p4
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
  "Only compile-time constants are supported for hash base offset and max value"
  testdata/p4_14_samples/flowlet_switching.p4
  )

p4c_add_xfail_reason("jbay"
  ": P4_14 extern type not fully supported"
  testdata/p4_14_samples/issue604.p4
  )

p4c_add_xfail_reason("jbay"
  "Structure header ingress_intrinsic_metadata_t does not have a field ucast_egress_port"
  testdata/p4_14_samples/sai_p4.p4
  )

p4c_add_xfail_reason("jbay"
  "error: No format in action table"
  testdata/p4_14_samples/selector0.p4
  testdata/p4_14_samples/port_vlan_mapping.p4
  )

p4c_add_xfail_reason("jbay"
  "Compiler Bug.*: .*: Cannot find declaration for"
  testdata/p4_14_samples/TLV_parsing.p4
  )

p4c_add_xfail_reason("jbay"
 "the packing is too complicated .* speciality action data combined with other action data"
 testdata/p4_14_samples/meter.p4
 testdata/p4_14_samples/meter1.p4
 testdata/p4_14_samples/issue894.p4
 )

# BRIG-421
p4c_add_xfail_reason("jbay"
  "condition too complex"
# PHV packs POV bits incorrectly
  )

p4c_add_xfail_reason("jbay"
  "counter cnt virtual value .*"
  testdata/p4_14_samples/counter2.p4
  )

p4c_add_xfail_reason("jbay"
  "Too much data for parse matcher"
  testdata/p4_14_samples/source_routing.p4
  )

# Checksum16 is deprecated
p4c_add_xfail_reason("jbay"
  "Could not find declaration for"
  extensions/p4_tests/p4_16/ipv4_options.p4
  )

p4c_add_xfail_reason("jbay"
  "warning: Instruction selection creates an instruction that the rest of the compiler cannot correctly interpret"
  extensions/p4_tests/p4_16/brig-42.p4
  )

# backend support for pvs
p4c_add_xfail_reason("jbay"
  "Too much data for parse matcher, not enough register"
  testdata/p4_14_samples/parser_value_set2.p4
  )

# This test fails because two fields are mutually exclusive in the parser, but
# one is added in the MAU while the other is live.  This behavior matches glass
# but is known to be incorrect.
p4c_add_xfail_reason("jbay"
  "instruction slot [0-9]+ used multiple times in action"
  # testdata/p4_14_samples/instruct5.p4
  )

p4c_add_xfail_reason("jbay"
  "test.IPv4ChecksumUpdateTest ... FAIL"
  # needs tna to jna translation
  extensions/p4_tests/p4_16/ipv4_checksum.p4
  )

p4c_add_xfail_reason("jbay"
  "PHV allocation was not successful"
  extensions/p4_tests/p4_16/int_transit.p4
  )

# These tests fail at runtime with the driver
if (PTF_REQUIREMENTS_MET)

p4c_add_xfail_reason("jbay"
  "AssertionError: A packet was received on device .*, port .*, but we expected no packets"
  extensions/p4_tests/p4_16/verify_checksum.p4
  )

p4c_add_xfail_reason("jbay"
  "AssertionError: Expected packet was not received on device .*, port .*"
  extensions/p4_tests/p4_16/ingress_checksum.p4
  extensions/p4_tests/p4_16/ONLab_packetio.p4
  extensions/p4_tests/p4_14/easy.p4
  extensions/p4_tests/p4_14/easy_no_match.p4
  fabric.p4
  tor.p4
  )

endif() # PTF_REQUIREMENTS_MET

# BRIG-528
p4c_add_xfail_reason("jbay"
  ".* expected packet on port .* not seen"
  extensions/p4_tests/p4_14/bug_metadata_mutex_1.p4
  testdata/p4_14_samples/action_chain1.p4
)

p4c_add_xfail_reason("jbay"
  "Rendezvous of RPC that terminated with"
  extensions/p4_tests/p4_16/hash_driven_stats.p4
)

# This test is tailored to fill Tofino's PHV.  It is expected to fail on JBay
# until the compiler can take full advantage of all PHV container types.  (And
# maybe even after that.)
p4c_add_xfail_reason("jbay"
  "PHV allocation was not successful"
  extensions/p4_tests/p4_14/deparser_group_allocation_1.p4
)

p4c_add_xfail_reason("jbay"
  "Could not place table : The table .* could not fit"
   extensions/p4_tests/p4_14/stateful3.p4
)

p4c_add_xfail_reason("jbay"
  "unexpected packet output on port .*"
  extensions/p4_tests/p4_16/stack_valid.p4
)

p4c_add_xfail_reason("jbay"
  "condition expression too complex"
  testdata/p4_14_samples/header-stack-ops-bmv2.p4
)

# BRIG-640
p4c_add_xfail_reason("jbay"
  "Compiler Bug.*: Shifting extract to negative position"
  extensions/p4_tests/p4_16/jbay/triv_ipv4.p4
  extensions/p4_tests/p4_16/jbay/hwlearn1.p4
)
