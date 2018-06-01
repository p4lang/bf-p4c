include (ExternalProject)

# Switch On Release 7.0
set  (SWITCH_7.0_P4 ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/switch-7.0/p4src/switch.p4)
set  (isXFail TRUE)
file (RELATIVE_PATH switch_7.0_test ${P4C_SOURCE_DIR} ${SWITCH_7.0_P4})
p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} ${isXFail}
  "switch_7.0_ent_fin_leaf" ${switch_7.0_test} "${testExtraArgs} -DENT_FIN_LEAF_PROFILE")
p4c_add_test_label("tofino" "17Q4Goal" "switch_7.0_ent_fin_leaf")

p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} FALSE
  "switch_7.0_dc_basic" ${switch_7.0_test} "${testExtraArgs} -DDC_BASIC_PROFILE")
p4c_add_test_label("tofino" "17Q4Goal" "switch_7.0_dc_basic")

p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} FALSE
  "switch_7.0_ent_dc_general" ${switch_7.0_test} "${testExtraArgs} -DENT_DC_GENERAL_PROFILE")
p4c_add_test_label("tofino" "17Q4Goal" "switch_7.0_ent_dc_general")

p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} FALSE
  "switch_7.0_ent_dc_aggr" ${switch_7.0_test} "${testExtraArgs} -DENT_DC_AGGR_PROFILE")
p4c_add_test_label("tofino" "17Q4Goal" "switch_7.0_ent_dc_aggr")

p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} FALSE
  "switch_7.0_msdc" ${switch_7.0_test} "${testExtraArgs} -DMSDC_PROFILE")
p4c_add_test_label("tofino" "17Q4Goal" "switch_7.0_msdc")

p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} FALSE
  "switch_7.0_l2" ${switch_7.0_test} "${testExtraArgs} -DL2_PROFILE")

# Switch P4-14 On Master (refpoint must be periodically updated)
set  (SWITCH_P4 ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/switch/p4src/switch.p4)
set  (SWITCH_PTF_DIR ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/switch/ptf-tests/base/api-tests)
set  (SWITCH_PTF_DIR_MIRROR ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/switch/ptf-tests/base/feature-tests)
set  (isXFail TRUE)
file (RELATIVE_PATH switchtest ${P4C_SOURCE_DIR} ${SWITCH_P4})
p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} FALSE
  "switch_dc_basic" ${switchtest} "${testExtraArgs} -DDC_BASIC_PROFILE")
p4c_add_test_label("tofino" "18Q2Goal" "switch_dc_basic")

p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} ${isXFail}
    "switch_ent_fin_postcard" ${switchtest} "${testExtraArgs} -DENT_FIN_POSTCARD_PROFILE")
p4c_add_test_label("tofino" "18Q2Goal" "switch_ent_fin_postcard")

p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} FALSE
  "switch_ent_dc_general" ${switchtest} "${testExtraArgs} -DENT_DC_GENERAL_PROFILE")
p4c_add_test_label("tofino" "18Q2Goal" "switch_ent_dc_general")

p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} FALSE
  "switch_msdc" ${switchtest} "${testExtraArgs} -DMSDC_PROFILE -DP4_WRED_DEBUG")
p4c_add_test_label("tofino" "18Q2Goal" "switch_msdc")

p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} ${isXFail}
    "switch_msdc_ipv4" ${switchtest} "${testExtraArgs} -DMSDC_IPV4_PROFILE")
p4c_add_test_label("tofino" "18Q2Goal" "switch_msdc_ipv4")

p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} FALSE
    "switch_msdc_l3" ${switchtest} "${testExtraArgs} -DMSDC_L3_PROFILE")
p4c_add_test_label("tofino" "18Q2Goal" "switch_msdc_l3")

p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} ${isXFail}
    "switch_msdc_spine_int" ${switchtest} "${testExtraArgs} -DMSDC_SPINE_DTEL_INT_PROFILE")
p4c_add_test_label("tofino" "18Q2Goal" "switch_msdc_spine_int")

p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} ${isXFail}
    "switch_msdc_leaf_int" ${switchtest} "${testExtraArgs} -DMSDC_LEAF_DTEL_INT_PROFILE")
p4c_add_test_label("tofino" "18Q2Goal" "switch_msdc_spine_int")

p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} FALSE
    "switch_msdc_l3_heavy_int_leaf" ${switchtest} "${testExtraArgs} -DMSDC_L3_HEAVY_INT_LEAF_PROFILE")
p4c_add_test_label("tofino" "18Q2Goal" "switch_msdc_l3_heavy_int_leaf")

p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} FALSE
    "switch_msdc_generic_int_leaf" ${switchtest} "${testExtraArgs} -DMSDC_GENERIC_INT_LEAF_PROFILE")
p4c_add_test_label("tofino" "18Q2Goal" "switch_msdc_generic_int_leaf")

# Switch P4-16
set  (SWITCH_P4_16 ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/switch/p4_16src/switch.p4)
file (RELATIVE_PATH switch_p4_16_test ${P4C_SOURCE_DIR} ${SWITCH_P4_16})
p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} FALSE
  "switch_p4_16" ${switch_p4_16_test} "${testExtraArgs} -nop4info")

p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_msdc" ${SWITCH_P4}
    "${testExtraArgs} -DMSDC_PROFILE -DP4_WRED_DEBUG -pd -to 12000" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_msdc"
        "switch_hostif.HostIfRxTxTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_msdc_set_1" ${SWITCH_P4}
    "${testExtraArgs} -DMSDC_PROFILE -DP4_WRED_DEBUG -pd -to 12000" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_msdc_set_1"
        "switch_tests.CpuTxTest
        switch_tests.ExceptionPacketsTest
        switch_tests.ExceptionPacketsTest_IPV6
        switch_tests.HostIfTest
        switch_tests.HostIfV6Test
        switch_tests.L2AccessToAccessVlanTest
        switch_tests.L2AccessToTrunkPriorityTaggingTest
        switch_tests.L2AccessToTrunkVlanJumboTest
        switch_tests.L2AccessToTrunkVlanTest
        switch_tests.L2AgingTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_msdc_set_2" ${SWITCH_P4}
    "${testExtraArgs} -DMSDC_PROFILE -DP4_WRED_DEBUG -pd -to 12000" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_msdc_set_2"
        "switch_tests.L2DynamicLearnAgeTest
        switch_tests.L2DynamicMacLearnTest
        switch_tests.L2DynamicMacMoveTest
        switch_tests.L2FloodTest
        switch_tests.L2LagTest
        switch_tests.L2LNStatsTest
            switch_tests.L2MacLearnTest
        switch_tests.L2StaticMacBulkDeleteTest
        switch_tests.L2StaticMacMoveTest
        switch_tests.L2TrunkToAccessVlanTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_msdc_set_3" ${SWITCH_P4}
    "${testExtraArgs} -DMSDC_PROFILE -DP4_WRED_DEBUG -pd -to 12000" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_msdc_set_3"
        "switch_tests.L2TrunkToTrunkVlanTest
    switch_tests.L2VlanStatsTest
        switch_tests.L3EcmpLagTest
        switch_tests.L3IPv4EcmpTest
    switch_tests.L3IPv4HostJumboTest
        switch_tests.L3IPv4HostModifyTest
        switch_tests.L3IPv4HostTest
        switch_tests.L3IPv4LagTest
        switch_tests.L3IPv4LookupTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_msdc_set_4" ${SWITCH_P4}
    "${testExtraArgs} -DMSDC_PROFILE -DP4_WRED_DEBUG -pd -to 12000" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_msdc_set_4"
        "switch_tests.L3IPv4LpmEcmpTest
        switch_tests.L3IPv4LpmTest
        switch_tests.L3IPv4MtuTest
        switch_tests.L3IPv4SubIntfHostTest
        switch_tests.L3IPv6EcmpTest
        switch_tests.L3IPv6HostTest
        switch_tests.L3IPv6LagTest
        switch_tests.L3IPv6LookupTest
        switch_tests.L3IPv6LpmEcmpTest
        switch_tests.L3IPv6LpmTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_msdc_set_5" ${SWITCH_P4}
    "${testExtraArgs} -DMSDC_PROFILE -DP4_WRED_DEBUG -pd -to 12000" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_msdc_set_5"
        "switch_tests.L3VIFloodTest
        switch_tests.L3VIIPv4HostFloodTest
        switch_tests.L3VIIPv4HostMacMoveTest
        switch_tests.L3VIIPv4HostTest
        switch_tests.L3VIIPv4HostVlanTaggingTest
        switch_tests.L3VIIPv4LagTest
        switch_tests.L3VIIPv6HostTest
        switch_tests.L3VINhopGleanTest
        switch_tests.MalformedPacketsTest
        switch_tests.MalformedPacketsTest_ipv6")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_msdc_set_6" ${SWITCH_P4}
        "${testExtraArgs} -DMSDC_PROFILE -DP4_WRED_DEBUG -pd -to 12000" "${SWITCH_PTF_DIR_MIRROR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_msdc_set_6"
        "mirror_acl_slice_tests.IPv6MirrorAclSliceTest_i2e
        mirror_acl_slice_tests.MirrorAclSliceTest_i2e")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_msdc_set_7" ${SWITCH_P4}
        "${testExtraArgs} -DMSDC_PROFILE -DP4_WRED_DEBUG -pd -to 12000" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_msdc_set_7"
        "switch_acl.Acl_i2e_ErspanRewriteTest
        switch_acl.AclLabelTest
        switch_acl.IPAclStatsTest
        switch_acl.IPAclTest
        switch_acl.IPIngressAclRangeTcamTest
        switch_acl.MirrorAclTest_e2e
        switch_acl.MirrorAclTest_i2e
        switch_acl.MirrorSessionTest")
# 500s timeout is too little for compiling and testing the entire switch, bumping it up
set_tests_properties("tofino/smoketest_switch_msdc" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_msdc_set_1" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_msdc_set_2" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_msdc_set_3" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_msdc_set_4" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_msdc_set_5" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_msdc_set_6" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_msdc_set_7" PROPERTIES TIMEOUT 12000)

p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_dc_basic" ${SWITCH_P4}
        "${testExtraArgs} -DDC_BASIC_PROFILE -pd -to 12000" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_dc_basic"
        "switch_hostif.HostIfRxTxTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_dc_basic_set_1" ${SWITCH_P4}
        "${testExtraArgs} -DDC_BASIC_PROFILE -pd -to 12000" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_dc_basic_set_1"
        "fast_reconfig_tests.FastReconfigBigTest
        fast_reconfig_tests.MultipleWarmInitTest
        fast_reconfig_tests.NormalthanWarmInitTest
        fast_reconfig_tests.RegularWarmInitTest
        switch_acl.Acl_i2e_ErspanRewriteTest
        switch_acl.AclLabelTest
        switch_acl.IPAclStatsTest
        switch_acl.IPAclTest
        switch_acl.IPIngressAclRangeTcamTest
        switch_acl.IPv6RAclTest
        switch_acl.MirrorAclTest_e2e
        switch_acl.MirrorAclTest_i2e
        switch_acl.MirrorSessionTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_dc_basic_set_2" ${SWITCH_P4}
        "${testExtraArgs} -DDC_BASIC_PROFILE -pd -to 12000" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_dc_basic_set_2"
        "switch_get.AclGetTest
        switch_get.BufferGetTest
        switch_get.DeviceGetTest
        switch_get.HostIfGetTest
        switch_get.InterfaceGetTest
        switch_get.L2GetTest
        switch_get.LagGetTest
        switch_get.MirrorGetTest
        switch_get.MtreeGetTest
        switch_get.NhopGetTest
        switch_get.PortGetTest
        switch_get.QosGetTest
        switch_get.RifGetTest
        switch_get.VlanGetTest
        switch_get.VrfRmacGetTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_dc_basic_set_3" ${SWITCH_P4}
        "${testExtraArgs} -DDC_BASIC_PROFILE -pd -to 12000" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_dc_basic_set_3"
        "switch_mcast.L3Multicast
        switch_mcast.L3MulticastBidir
        switch_mcast.L3MulticastStatsTest
        switch_mcast.L3MulticastToEcmp
        switch_tests.CpuTxTest
        switch_tests.DeviceInfoTest
        switch_tests.ExceptionPacketsTest
        switch_tests.ExceptionPacketsTest_IPV6
        switch_tests.IPinIPTest
        switch_tests.IPNeighborTest
        switch_tests.L2VxlanToGeneveUnicastLagBasicTest
        switch_tests.L2VxlanUnicastLagBasicTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_dc_basic_set_4" ${SWITCH_P4}
        "${testExtraArgs} -DDC_BASIC_PROFILE -pd -to 12000" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_dc_basic_set_4"
        "switch_tests.L2AccessToAccessVlanTest
        switch_tests.L2AccessToTrunkPriorityTaggingTest
        switch_tests.L2AccessToTrunkVlanJumboTest
        switch_tests.L2AccessToTrunkVlanTest
        switch_tests.L2AgingTest
        switch_tests.L2DynamicLearnAgeTest
        switch_tests.L2DynamicMacLearnTest
        switch_tests.L2DynamicMacMoveTest
        switch_tests.L2FloodTest
        switch_tests.L2GeneveUnicastLagBasicTest
        switch_tests.L2LagFloodTest
        switch_tests.L2LagTest
        switch_tests.L2LNStatsTest
        switch_tests.L2LNSubIntfEncapTest
        switch_tests.L2MacLearnTest
        switch_tests.L2NvgreUnicastLagBasicTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_dc_basic_set_5" ${SWITCH_P4}
        "${testExtraArgs} -DDC_BASIC_PROFILE -pd -to 12000" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_dc_basic_set_5"
        "switch_tests.L2MplsPushJumboTest
        switch_tests.L2MplsPushTest
        switch_tests.L2MplsSwapTest
        switch_tests.L2StaticMacBulkDeleteTest
        switch_tests.L2StaticMacMoveTest
        switch_tests.L2StpEgressBlockingTest
        switch_tests.L2StpTest
        switch_tests.L2TrunkToAccessVlanTest
        switch_tests.L2TrunkToTrunkVlanTest
        switch_tests.L2TunnelFloodEnhancedTest
        switch_tests.L2TunnelSplicingExtreme1Test
        switch_tests.L2TunnelSplicingExtreme2Test
        switch_tests.L2VlanStatsTest
        switch_tests.L2VxlanFloodBasicTest
        switch_tests.L2VxlanLearnBasicTest
        switch_tests.L2VxlanToGeneveUnicastEnhancedTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_dc_basic_set_6" ${SWITCH_P4}
        "${testExtraArgs} -DDC_BASIC_PROFILE -pd -to 12000" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_dc_basic_set_6"
        "switch_tests.L2VxlanToGeneveUnicastLagEnhancedTest
        switch_tests.L3EcmpLagTest
        switch_tests.L3IPv4EcmpTest
        switch_tests.L3IPv4HostJumboTest
        switch_tests.L3IPv4HostModifyTest
        switch_tests.L3IPv4HostTest
        switch_tests.L3IPv4LagTest
        switch_tests.L3IPv4LookupTest
        switch_tests.L3IPv4LpmEcmpTest
        switch_tests.L3IPv4LpmTest
        switch_tests.L3IPv4MtuTest
        switch_tests.L3IPv4SubIntfHostTest
        switch_tests.L3IPv6EcmpTest
        switch_tests.L3IPv6HostTest
        switch_tests.L3IPv6LagTest
        switch_tests.L3IPv6LookupTest
        switch_tests.L3IPv6LpmEcmpTest
        switch_tests.L3IPv6LpmTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_dc_basic_set_7" ${SWITCH_P4}
        "${testExtraArgs} -DDC_BASIC_PROFILE -pd -to 12000" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_dc_basic_set_7"
        "switch_tests.L3MplsPopTest
        switch_tests.L3MplsPushTest
        switch_tests.L3RpfTest
        switch_tests.L3VIFloodTest
        switch_tests.L3VIIPv4HostFloodTest
        switch_tests.L3VIIPv4HostMacMoveTest
        switch_tests.L3VIIPv4HostTest
        switch_tests.L3VIIPv4HostVlanTaggingTest
        switch_tests.L3VIIPv4LagTest
        switch_tests.L3VIIPv6HostTest
        switch_tests.MalformedPacketsTest
        switch_tests.MalformedPacketsTest_ipv6
        switch_tunnel.L3VxlanUnicastTunnelECMPSMTest
        switch_tunnel.L3VxlanUnicastTunnelSMSVITest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_dc_basic_set_8" ${SWITCH_P4}
        "${testExtraArgs} -DDC_BASIC_PROFILE -pd -to 12000" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_dc_basic_set_8"
        "switch_hostif.HostIfPtpTest
        switch_tests.HostIfTest
        switch_tests.HostIfV6Test
        switch_tests.L3VINhopGleanBGPTest
        switch_tests.L3VINhopGleanTest
        switch_tests.MalformedPacketsTest_tunnel")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_dc_basic_L2GeneveUnicastBasicTest" ${SWITCH_P4}
        "${testExtraArgs} -DDC_BASIC_PROFILE -pd" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_dc_basic_L2GeneveUnicastBasicTest"
        "switch_tests.L2GeneveUnicastBasicTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_dc_basic_L2IPv4InIPv6VxlanUnicastBasicTest" ${SWITCH_P4}
        "${testExtraArgs} -DDC_BASIC_PROFILE -pd" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_dc_basic_L2IPv4InIPv6VxlanUnicastBasicTest"
        "switch_tests.L2IPv4InIPv6VxlanUnicastBasicTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_dc_basic_L2MplsPopTest" ${SWITCH_P4}
        "${testExtraArgs} -DDC_BASIC_PROFILE -pd" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_dc_basic_L2MplsPopTest"
        "switch_tests.L2MplsPopTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_dc_basic_L2NvgreUnicastBasicTest" ${SWITCH_P4}
        "${testExtraArgs} -DDC_BASIC_PROFILE -pd" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_dc_basic_L2NvgreUnicastBasicTest"
        "switch_tests.L2NvgreUnicastBasicTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_dc_basic_L2VxlanArpUnicastBasicTest" ${SWITCH_P4}
        "${testExtraArgs} -DDC_BASIC_PROFILE -pd" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_dc_basic_L2VxlanArpUnicastBasicTest"
        "switch_tests.L2VxlanArpUnicastBasicTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_dc_basic_L2VxlanToGeneveUnicastBasicTest" ${SWITCH_P4}
        "${testExtraArgs} -DDC_BASIC_PROFILE -pd" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_dc_basic_L2VxlanToGeneveUnicastBasicTest"
        "switch_tests.L2VxlanToGeneveUnicastBasicTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_dc_basic_L2VxlanUnicastBasicTest" ${SWITCH_P4}
        "${testExtraArgs} -DDC_BASIC_PROFILE -pd" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_dc_basic_L2VxlanUnicastBasicTest"
        "switch_tests.L2VxlanUnicastBasicTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_dc_basic_L3VxlanUnicastMultiTunnelSMTest" ${SWITCH_P4}
        "${testExtraArgs} -DDC_BASIC_PROFILE -pd" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_dc_basic_L3VxlanUnicastMultiTunnelSMTest"
        "switch_tunnel.L3VxlanUnicastMultiTunnelSMTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_dc_basic_L3VxlanUnicastTunnelECMPLagReflectionSMTest" ${SWITCH_P4}
        "${testExtraArgs} -DDC_BASIC_PROFILE -pd" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_dc_basic_L3VxlanUnicastTunnelECMPLagReflectionSMTest"
        "switch_tunnel.L3VxlanUnicastTunnelECMPLagReflectionSMTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_dc_basic_L3VxlanUnicastTunnelSMTest" ${SWITCH_P4}
        "${testExtraArgs} -DDC_BASIC_PROFILE -pd" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_dc_basic_L3VxlanUnicastTunnelSMTest"
        "switch_tunnel.L3VxlanUnicastTunnelSMTest")
# 500s timeout is too little for compiling and testing the entire switch, bumping it up
set_tests_properties("tofino/smoketest_switch_dc_basic" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_dc_basic_set_1" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_dc_basic_set_2" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_dc_basic_set_3" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_dc_basic_set_4" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_dc_basic_set_5" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_dc_basic_set_6" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_dc_basic_set_7" PROPERTIES TIMEOUT 12000)

p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_ent_dc_general" ${SWITCH_P4}
        "${testExtraArgs} -DENT_DC_GENERAL_PROFILE -pd -to 12000" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_ent_dc_general"
        "switch_hostif.HostIfPtpTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_ent_dc_general_set_1" ${SWITCH_P4}
        "${testExtraArgs} -DENT_DC_GENERAL_PROFILE -pd -to 12000" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_ent_dc_general_set_1"
        "switch_acl.MirrorSessionTest
        switch_tests.HostIfTest
        switch_tests.L2AccessToAccessVlanTest
        switch_tests.L2AccessToTrunkPriorityTaggingTest
        switch_tests.L2AccessToTrunkVlanJumboTest
        switch_tests.L2AccessToTrunkVlanTest
        switch_tests.L2AgingTest
        switch_tests.L2DynamicMacLearnTest
        switch_tests.L2DynamicMacMoveTest
        switch_tests.L2DynamicLearnAgeTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_ent_dc_general_set_2" ${SWITCH_P4}
        "${testExtraArgs} -DENT_DC_GENERAL_PROFILE -pd -to 12000" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_ent_dc_general_set_2"
        "switch_tests.L2FloodTest
        switch_tests.L2LagFloodTest
        switch_tests.L2LagTest
        switch_tests.L2LNStatsTest
        switch_tests.L2LNSubIntfEncapTest
        switch_tests.L2MacLearnTest
        switch_tests.L2StaticMacBulkDeleteTest
        switch_tests.L2StaticMacMoveTest
        switch_tests.L2TrunkToAccessVlanTest
        switch_tests.L2TrunkToTrunkVlanTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_ent_dc_general_set_3" ${SWITCH_P4}
        "${testExtraArgs} -DENT_DC_GENERAL_PROFILE -pd -to 12000" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_ent_dc_general_set_3"
        "switch_tests.L2VlanStatsTest
        switch_tests.L2VxlanFloodBasicTest
        switch_tests.L2VxlanLearnBasicTest
        switch_tests.L3IPv4LookupTest
        switch_tests.L3IPv4MtuTest
        switch_tests.L3IPv6LookupTest
        switch_tests.L3VIFloodTest
        switch_tests.MalformedPacketsTest
        switch_tests.MalformedPacketsTest_ipv6
        switch_tunnel.L3VxlanUnicastTunnelSMSVITest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_ent_dc_general_IPAclStatsTest" ${SWITCH_P4}
        "${testExtraArgs} -DENT_DC_GENERAL_PROFILE -pd" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_ent_dc_general_IPAclStatsTest"
        "switch_acl.IPAclStatsTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_ent_dc_general_AclLabelTest" ${SWITCH_P4}
        "${testExtraArgs} -DENT_DC_GENERAL_PROFILE -pd" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_ent_dc_general_AclLabelTest"
        "switch_acl.AclLabelTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_ent_dc_general_IPIngressAclRangeTcamTest" ${SWITCH_P4}
        "${testExtraArgs} -DENT_DC_GENERAL_PROFILE -pd" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_ent_dc_general_IPIngressAclRangeTcamTest"
        "switch_acl.IPIngressAclRangeTcamTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_ent_dc_general_IPAclTest" ${SWITCH_P4}
        "${testExtraArgs} -DENT_DC_GENERAL_PROFILE -pd" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_ent_dc_general_IPAclTest"
        "switch_acl.IPAclTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_ent_dc_general_MirrorAclTest_i2e" ${SWITCH_P4}
        "${testExtraArgs} -DENT_DC_GENERAL_PROFILE -pd" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_ent_dc_general_MirrorAclTest_i2e"
        "switch_acl.MirrorAclTest_i2e")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_ent_dc_general_HostIfRxTxTest" ${SWITCH_P4}
        "${testExtraArgs} -DENT_DC_GENERAL_PROFILE -pd" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_ent_dc_general_HostIfRxTxTest"
        "switch_hostif.HostIfRxTxTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_ent_dc_general_L3VxlanUnicastTunnelECMPLagReflectionSMTest" ${SWITCH_P4}
        "${testExtraArgs} -DENT_DC_GENERAL_PROFILE -pd" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_ent_dc_general_L3VxlanUnicastTunnelECMPLagReflectionSMTest"
        "switch_tunnel.L3VxlanUnicastTunnelECMPLagReflectionSMTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_ent_dc_general_L3VxlanUnicastTunnelECMPSMTest" ${SWITCH_P4}
        "${testExtraArgs} -DENT_DC_GENERAL_PROFILE -pd" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_ent_dc_general_L3VxlanUnicastTunnelECMPSMTest"
        "switch_tunnel.L3VxlanUnicastTunnelECMPSMTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_ent_dc_general_L3VxlanUnicastTunnelSMTest" ${SWITCH_P4}
        "${testExtraArgs} -DENT_DC_GENERAL_PROFILE -pd" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_ent_dc_general_L3VxlanUnicastTunnelSMTest"
        "switch_tunnel.L3VxlanUnicastTunnelSMTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_ent_dc_general_L3VIIPv4HostVlanTaggingTest" ${SWITCH_P4}
        "${testExtraArgs} -DENT_DC_GENERAL_PROFILE -pd" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_ent_dc_general_L3VIIPv4HostVlanTaggingTest"
        "switch_tests.L3VIIPv4HostVlanTaggingTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_ent_dc_general_L3IPv4HostTest" ${SWITCH_P4}
        "${testExtraArgs} -DENT_DC_GENERAL_PROFILE -pd" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_ent_dc_general_L3IPv4HostTest"
        "switch_tests.L3IPv4HostTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_ent_dc_general_ExceptionPacketsTest_IPV6" ${SWITCH_P4}
        "${testExtraArgs} -DENT_DC_GENERAL_PROFILE -pd" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_ent_dc_general_ExceptionPacketsTest_IPV6"
        "switch_tests.ExceptionPacketsTest_IPV6")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_ent_dc_general_L3IPv6LagTest" ${SWITCH_P4}
        "${testExtraArgs} -DENT_DC_GENERAL_PROFILE -pd" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_ent_dc_general_L3IPv6LagTest"
        "switch_tests.L3IPv6LagTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_ent_dc_general_L2StpEgressBlockingTest" ${SWITCH_P4}
        "${testExtraArgs} -DENT_DC_GENERAL_PROFILE -pd" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_ent_dc_general_L2StpEgressBlockingTest"
        "switch_tests.L2StpEgressBlockingTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_ent_dc_general_L3IPv4SubIntfHostTest" ${SWITCH_P4}
        "${testExtraArgs} -DENT_DC_GENERAL_PROFILE -pd" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_ent_dc_general_L3IPv4SubIntfHostTest"
        "switch_tests.L3IPv4SubIntfHostTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_ent_dc_general_L3IPv6EcmpTest" ${SWITCH_P4}
        "${testExtraArgs} -DENT_DC_GENERAL_PROFILE -pd" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_ent_dc_general_L3IPv6EcmpTest"
        "switch_tests.L3IPv6EcmpTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_ent_dc_general_L3IPv6LpmTest" ${SWITCH_P4}
        "${testExtraArgs} -DENT_DC_GENERAL_PROFILE -pd" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_ent_dc_general_L3IPv6LpmTest"
        "switch_tests.L3IPv6LpmTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_ent_dc_general_L3IPv6HostTest" ${SWITCH_P4}
        "${testExtraArgs} -DENT_DC_GENERAL_PROFILE -pd" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_ent_dc_general_L3IPv6HostTest"
        "switch_tests.L3IPv6HostTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_ent_dc_general_L3IPv6LpmEcmpTest" ${SWITCH_P4}
        "${testExtraArgs} -DENT_DC_GENERAL_PROFILE -pd" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_ent_dc_general_L3IPv6LpmEcmpTest"
        "switch_tests.L3IPv6LpmEcmpTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_ent_dc_general_MalformedPacketsTest_tunnel" ${SWITCH_P4}
        "${testExtraArgs} -DENT_DC_GENERAL_PROFILE -pd" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_ent_dc_general_MalformedPacketsTest_tunnel"
        "switch_tests.MalformedPacketsTest_tunnel")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_ent_dc_general_L3VIIPv4HostFloodTest" ${SWITCH_P4}
        "${testExtraArgs} -DENT_DC_GENERAL_PROFILE -pd" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_ent_dc_general_L3VIIPv4HostFloodTest"
        "switch_tests.L3VIIPv4HostFloodTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_ent_dc_general_L3IPv4EcmpTest" ${SWITCH_P4}
        "${testExtraArgs} -DENT_DC_GENERAL_PROFILE -pd" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_ent_dc_general_L3IPv4EcmpTest"
        "switch_tests.L3IPv4EcmpTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_ent_dc_general_L3IPv4LagTest" ${SWITCH_P4}
        "${testExtraArgs} -DENT_DC_GENERAL_PROFILE -pd" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_ent_dc_general_L3IPv4LagTest"
        "switch_tests.L3IPv4LagTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_ent_dc_general_L3IPv4HostJumboTest" ${SWITCH_P4}
        "${testExtraArgs} -DENT_DC_GENERAL_PROFILE -pd" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_ent_dc_general_L3IPv4HostJumboTest"
        "switch_tests.L3IPv4HostJumboTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_ent_dc_general_L3EcmpLagTest" ${SWITCH_P4}
        "${testExtraArgs} -DENT_DC_GENERAL_PROFILE -pd" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_ent_dc_general_L3EcmpLagTest"
        "switch_tests.L3EcmpLagTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_ent_dc_general_L3VIIPv4HostMacMoveTest" ${SWITCH_P4}
        "${testExtraArgs} -DENT_DC_GENERAL_PROFILE -pd" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_ent_dc_general_L3VIIPv4HostMacMoveTest"
        "switch_tests.L3VIIPv4HostMacMoveTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_ent_dc_general_L3IPv4EcmpSeedTest" ${SWITCH_P4}
        "${testExtraArgs} -DENT_DC_GENERAL_PROFILE -pd" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_ent_dc_general_L3IPv4EcmpSeedTest"
        "switch_tests.L3IPv4EcmpSeedTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_ent_dc_general_L3IPv4LpmTest" ${SWITCH_P4}
        "${testExtraArgs} -DENT_DC_GENERAL_PROFILE -pd" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_ent_dc_general_L3IPv4LpmTest"
        "switch_tests.L3IPv4LpmTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_ent_dc_general_L3VINhopGleanTest" ${SWITCH_P4}
        "${testExtraArgs} -DENT_DC_GENERAL_PROFILE -pd" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_ent_dc_general_L3VINhopGleanTest"
        "switch_tests.L3VINhopGleanTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_ent_dc_general_ExceptionPacketsTest" ${SWITCH_P4}
        "${testExtraArgs} -DENT_DC_GENERAL_PROFILE -pd" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_ent_dc_general_ExceptionPacketsTest"
        "switch_tests.ExceptionPacketsTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_ent_dc_general_CpuTxTest" ${SWITCH_P4}
        "${testExtraArgs} -DENT_DC_GENERAL_PROFILE -pd" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_ent_dc_general_CpuTxTest"
        "switch_tests.CpuTxTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_ent_dc_general_HostIfV6Test" ${SWITCH_P4}
        "${testExtraArgs} -DENT_DC_GENERAL_PROFILE -pd" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_ent_dc_general_HostIfV6Test"
        "switch_tests.HostIfV6Test")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_ent_dc_general_L3VIIPv6HostTest" ${SWITCH_P4}
        "${testExtraArgs} -DENT_DC_GENERAL_PROFILE -pd" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_ent_dc_general_L3VIIPv6HostTest"
        "switch_tests.L3VIIPv6HostTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_ent_dc_general_L3IPv4LpmEcmpTest" ${SWITCH_P4}
        "${testExtraArgs} -DENT_DC_GENERAL_PROFILE -pd" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_ent_dc_general_L3IPv4LpmEcmpTest"
        "switch_tests.L3IPv4LpmEcmpTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_ent_dc_general_L2StpTest" ${SWITCH_P4}
        "${testExtraArgs} -DENT_DC_GENERAL_PROFILE -pd" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_ent_dc_general_L2StpTest"
        "switch_tests.L2StpTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_ent_dc_general_L2VxlanUnicastBasicTest" ${SWITCH_P4}
        "${testExtraArgs} -DENT_DC_GENERAL_PROFILE -pd" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_ent_dc_general_L2VxlanUnicastBasicTest"
        "switch_tests.L2VxlanUnicastBasicTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_ent_dc_general_L2VxlanUnicastLagBasicTest" ${SWITCH_P4}
        "${testExtraArgs} -DENT_DC_GENERAL_PROFILE -pd" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_ent_dc_general_L2VxlanUnicastLagBasicTest"
        "switch_tests.L2VxlanUnicastLagBasicTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_ent_dc_general_L3VIIPv4LagTest" ${SWITCH_P4}
        "${testExtraArgs} -DENT_DC_GENERAL_PROFILE -pd" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_ent_dc_general_L3VIIPv4LagTest"
        "switch_tests.L3VIIPv4LagTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_ent_dc_general_L3IPv4HostModifyTest" ${SWITCH_P4}
        "${testExtraArgs} -DENT_DC_GENERAL_PROFILE -pd" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_ent_dc_general_L3IPv4HostModifyTest"
        "switch_tests.L3IPv4HostModifyTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_ent_dc_general_L3VIIPv4HostTest" ${SWITCH_P4}
        "${testExtraArgs} -DENT_DC_GENERAL_PROFILE -pd" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_ent_dc_general_L3VIIPv4HostTest"
        "switch_tests.L3VIIPv4HostTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_ent_dc_general_L2VxlanArpUnicastBasicTest" ${SWITCH_P4}
        "${testExtraArgs} -DENT_DC_GENERAL_PROFILE -pd" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_ent_dc_general_L2VxlanArpUnicastBasicTest"
        "switch_tests.L2VxlanArpUnicastBasicTest")
# 500s timeout is too little for compiling and testing the entire switch, bumping it up
set_tests_properties("tofino/smoketest_switch_ent_dc_general" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_ent_dc_general_set_1" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_ent_dc_general_set_2" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_ent_dc_general_set_3" PROPERTIES TIMEOUT 12000)

set (SWITCH_SRC_DIR ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/switch)
# set_property(DIRECTORY PROPERTY EP_STEP_TARGETS update configure)

function(bfn_add_switch device)
  set (SWITCH_BIN_DIR ${CMAKE_CURRENT_BINARY_DIR}/p4_14/switch-${device})
  ExternalProject_Add(switch-${device}
    DEPENDS ${device}backend
    PREFIX ${SWITCH_SRC_DIR}
    SOURCE_DIR ${SWITCH_SRC_DIR}
    UPDATE_COMMAND ${SWITCH_SRC_DIR}/autogen.sh
    CONFIGURE_COMMAND P4CV6=yes P4C=${P4C_BINARY_DIR}/p4c ${SWITCH_SRC_DIR}/configure --enable-thrift --disable-static --with-${device} --with-switchsai --with-cpu-veth --prefix ${SWITCH_BIN_DIR}
    BINARY_DIR ${SWITCH_BIN_DIR}
    BUILD_COMMAND :
    # ${MAKE}
    INSTALL_DIR ${SWITCH_BIN_DIR}/install
    INSTALL_COMMAND :
    # ${MAKE} switchapi
    )
endfunction(bfn_add_switch)
