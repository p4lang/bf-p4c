set (JBAY_XFAIL_TESTS
  # this is intentionally empty because xfails should be added with a reason.
  # look for the failure message in this file and add to an existing ticket
  # or open a new one.
  )

# These tests compile successfuly and fail in the model when running the STF test
# the reasons need more characterization
if (HARLYN_STF AND NOT ENABLE_STF2PTF)
set (JBAY_XFAIL_TESTS ${JBAY_XFAIL_TESTS})
endif() # HARLYN_STF

# tests that no longer fail when enable TNA translation
# possibly due to different PHV allocation
if (NOT ENABLE_TNA)
endif() # NOT ENABLE_TNA

# BEGIN: XFAILS that match glass XFAILS
#END: XFAILS that match glass XFAILS

if (ENABLE_STF2PTF AND PTF_REQUIREMENTS_MET)
endif() # ENABLE_STF2PTF AND PTF_REQUIREMENTS_MET

if (ENABLE_TNA)
endif()  # ENABLE_TNA

if (HARLYN_STF AND NOT ENABLE_STF2PTF AND ENABLE_TNA)
endif()  # STF FAILURE IN TNA


p4c_add_xfail_reason("jbay"
  ".*"
   testdata/p4_14_samples/action_inline2.p4
   testdata/p4_14_samples/selector0.p4
   testdata/p4_14_samples/gateway5.p4
   testdata/p4_14_samples/issue60.p4
   testdata/p4_14_samples/swap_1.p4
   testdata/p4_14_samples/checksum.p4
   testdata/p4_14_samples/resubmit.p4
   testdata/p4_14_samples/hash_action_gateway.p4
   testdata/p4_14_samples/copy_to_cpu.p4
   testdata/p4_14_samples/06-SimpleVlanStack.p4
   testdata/p4_14_samples/sai_p4.p4
   testdata/p4_14_samples/meter.p4
   testdata/p4_14_samples/basic_routing.p4
   testdata/p4_14_samples/03-Gateway.p4
   testdata/p4_14_samples/18-EmptyPipelines.p4
   testdata/p4_14_samples/16-TwoReferences.p4
   testdata/p4_14_samples/gateway4.p4
   testdata/p4_14_samples/gateway7.p4
   testdata/p4_14_samples/07-MultiProtocol.p4
   testdata/p4_14_samples/01-FullPHV.p4
   testdata/p4_14_samples/selector3.p4
   testdata/p4_14_samples/02-FullPHV1.p4
   testdata/p4_14_samples/parser4.p4
   testdata/p4_14_samples/01-JustEthernet.p4
   testdata/p4_14_samples/packet_redirect.p4
   testdata/p4_14_samples/tmvalid.p4
   testdata/p4_14_samples/exact_match9.p4
   testdata/p4_14_samples/hash_action_two_separate.p4
   testdata/p4_14_samples/mac_rewrite.p4
   testdata/p4_14_samples/hit.p4
   testdata/p4_14_samples/parser_dc_full.p4
   testdata/p4_14_samples/issue894.p4
   testdata/p4_14_samples/exact_match2.p4
   testdata/p4_14_samples/test_config_175_match_table_with_no_key.p4
   testdata/p4_14_samples/01-NoDeps.p4
   testdata/p4_14_samples/queueing.p4
   testdata/p4_14_samples/parser1.p4
   testdata/p4_14_samples/basic_conditionals.p4
   testdata/p4_14_samples/checksum1.p4
   testdata/p4_14_samples/port_vlan_mapping.p4
   testdata/p4_14_samples/hash_action_basic.p4
   testdata/p4_14_samples/12-MultiTagsNoLoop.p4
   testdata/p4_14_samples/acl1.p4
   testdata/p4_14_samples/axon.p4
   testdata/p4_14_samples/testgw.p4
   testdata/p4_14_samples/ternary_match2.p4
   testdata/p4_14_samples/13-MultiTagsCorrect.p4
   testdata/p4_14_samples/exact_match5.p4
   testdata/p4_14_samples/repeater.p4
   testdata/p4_14_samples/selector1.p4
   testdata/p4_14_samples/flowlet_switching.p4
   testdata/p4_14_samples/exact_match1.p4
   testdata/p4_14_samples/02-SplitEthernet.p4
   testdata/p4_14_samples/14-SplitEthernetVlan.p4
   testdata/p4_14_samples/register.p4
   testdata/p4_14_samples/instruct2.p4
   testdata/p4_14_samples/action_bus1.p4
   testdata/p4_14_samples/bridge1.p4
   testdata/p4_14_samples/gateway1.p4
   testdata/p4_14_samples/exact_match4.p4
   testdata/p4_14_samples/bigfield1.p4
   testdata/p4_14_samples/wide_action2.p4
   testdata/p4_14_samples/ternary_match0.p4
   testdata/p4_14_samples/exact_match8.p4
   testdata/p4_14_samples/07-FullTPHV2.p4
   testdata/p4_14_samples/action_inline.p4
   testdata/p4_14_samples/14-GatewayGreaterThan.p4
   testdata/p4_14_samples/test_config_23_same_container_modified.p4
   testdata/p4_14_samples/hitmiss.p4
   testdata/p4_14_samples/instruct1.p4
   testdata/p4_14_samples/hash_action_gateway2.p4
   testdata/p4_14_samples/parser2.p4
   testdata/p4_14_samples/13-Counters1and2.p4
   testdata/p4_14_samples/counter2.p4
   testdata/p4_14_samples/issue583.p4
   testdata/p4_14_samples/02-BadSizeField.p4
   testdata/p4_14_samples/misc_prim.p4
   testdata/p4_14_samples/09-IPv4OptionsUnparsed.p4
   testdata/p4_14_samples/issue780-8.p4
   testdata/p4_14_samples/06-FullTPHV1.p4
   testdata/p4_14_samples/hash_action_two_same.p4
   testdata/p4_14_samples/instruct3.p4
   testdata/p4_14_samples/05-FieldProblem.p4
   testdata/p4_14_samples/instruct4.p4
   testdata/p4_14_samples/gateway2.p4
   testdata/p4_14_samples/test_7_storm_control.p4
   testdata/p4_14_samples/triv_ipv4.p4
   testdata/p4_14_samples/wide_action3.p4
   testdata/p4_14_samples/simple_nat.p4
   testdata/p4_14_samples/gateway8.p4
   testdata/p4_14_samples/15-MultiProtocolIfElseMinimal.p4
   testdata/p4_14_samples/ternary_match4.p4
   testdata/p4_14_samples/07-SimpleVlanStackIP.p4
   testdata/p4_14_samples/action_chain1.p4
   testdata/p4_14_samples/swap_2.p4
   testdata/p4_14_samples/04-SimpleVlan.p4
   testdata/p4_14_samples/action_inline1.p4
   testdata/p4_14_samples/instruct6.p4
   testdata/p4_14_samples/05-SimpleVlan1.p4
   testdata/p4_14_samples/08-FullTPHV3.p4
   testdata/p4_14_samples/wide_action1.p4
   testdata/p4_14_samples/counter4.p4
   testdata/p4_14_samples/counter3.p4
   testdata/p4_14_samples/12-Counters.p4
   testdata/p4_14_samples/exact_match6.p4
   testdata/p4_14_samples/TLV_parsing.p4
   testdata/p4_14_samples/instruct5.p4
   testdata/p4_14_samples/issue1057.p4
   testdata/p4_14_samples/10-SelectPriorities.p4
   testdata/p4_14_samples/parser3.p4
   testdata/p4_14_samples/counter5.p4
   testdata/p4_14_samples/truncate.p4
   testdata/p4_14_samples/08-MultiProtocolIfElse.p4
   testdata/p4_14_samples/issue1058.p4
   testdata/p4_14_samples/issue604.p4
   testdata/p4_14_samples/exact_match_mask1.p4
   testdata/p4_14_samples/11-MultiTags.p4
   testdata/p4_14_samples/meter1.p4
   testdata/p4_14_samples/exact_match3.p4
   testdata/p4_14_samples/selector2.p4
   testdata/p4_14_samples/03-SplitEthernetCompact.p4
   testdata/p4_14_samples/14-Counter.p4
   testdata/p4_14_samples/counter.p4
   testdata/p4_14_samples/ternary_match3.p4
   testdata/p4_14_samples/simple_router.p4
   testdata/p4_14_samples/do_nothing.p4
   testdata/p4_14_samples/08-SimpleVlanStackIPSplitFlags.p4
   testdata/p4_14_samples/validate_outer_ethernet.p4
   testdata/p4_14_samples/05-FullTPHV.p4
   testdata/p4_14_samples/issue946.p4
   testdata/p4_14_samples/04-GatewayDefault.p4
   testdata/p4_14_samples/miss.p4
   testdata/p4_14_samples/gateway6.p4
   testdata/p4_14_samples/issue781.p4
   testdata/p4_14_samples/ternary_match1.p4
   testdata/p4_14_samples/03-FullPHV2.p4
   testdata/p4_14_samples/gateway3.p4
   testdata/p4_14_samples/triv_eth.p4
   testdata/p4_14_samples/exact_match7.p4
   testdata/p4_14_samples/source_routing.p4
   testdata/p4_14_samples/01-BigMatch.p4
   testdata/p4_14_samples/issue846.p4
   testdata/p4_14_samples/issue1013.p4
   testdata/p4_14_samples/exact_match_valid1.p4
   testdata/p4_14_samples/counter1.p4
)

p4c_add_xfail_reason("jbay"
  "error: Can't use .* in ingress and .* in egress in jbay parser"
  testdata/p4_14_samples/tp2a.p4
  testdata/p4_14_samples/tp2b.p4
  testdata/p4_14_samples/tp2c.p4
  testdata/p4_14_samples/tp3a.p4
  )
