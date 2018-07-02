include (ExternalProject)

# Switch P4-14 On Master (Release 8.1) (refpoint must be periodically updated)
set  (SWITCH_P4 ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/switch/p4src/switch.p4)
set  (SWITCH_PTF_DIR ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/switch/ptf-tests/base/api-tests)
set  (SWITCH_PTF_DIR_MIRROR ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/switch/ptf-tests/base/feature-tests)
set  (SWITCH_PTF_DIR_SAI ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/switch/ptf-tests/base/sai-ocp-tests)
set  (isXFail TRUE)
file (RELATIVE_PATH switchtest ${P4C_SOURCE_DIR} ${SWITCH_P4})
p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} FALSE
  "switch_dc_basic" ${switchtest} "${testExtraArgs} -DDC_BASIC_PROFILE")
p4c_add_test_label("tofino" "18Q2Goal" "switch_dc_basic")

p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} FALSE
    "switch_ent_fin_postcard" ${switchtest} "${testExtraArgs} -DENT_FIN_POSTCARD_PROFILE")
p4c_add_test_label("tofino" "18Q2Goal" "switch_ent_fin_postcard")

p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} FALSE
  "switch_ent_dc_general" ${switchtest} "${testExtraArgs} -DENT_DC_GENERAL_PROFILE")
p4c_add_test_label("tofino" "18Q2Goal" "switch_ent_dc_general")

p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} FALSE
  "switch_msdc" ${switchtest} "${testExtraArgs} -DMSDC_PROFILE -DP4_WRED_DEBUG")
p4c_add_test_label("tofino" "18Q2Goal" "switch_msdc")

p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} FALSE} 
    "switch_msdc_ipv4" ${switchtest} "${testExtraArgs} -DMSDC_IPV4_PROFILE")
p4c_add_test_label("tofino" "18Q2Goal" "switch_msdc_ipv4")

p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} FALSE
    "switch_msdc_l3" ${switchtest} "${testExtraArgs} -DMSDC_L3_PROFILE")
p4c_add_test_label("tofino" "18Q2Goal" "switch_msdc_l3")

p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} FALSE
    "switch_msdc_spine_int" ${switchtest} "${testExtraArgs} -DMSDC_SPINE_DTEL_INT_PROFILE")
p4c_add_test_label("tofino" "18Q2Goal" "switch_msdc_spine_int")

p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} FALSE
    "switch_msdc_leaf_int" ${switchtest} "${testExtraArgs} -DMSDC_LEAF_DTEL_INT_PROFILE")
p4c_add_test_label("tofino" "18Q2Goal" "switch_msdc_spine_int")

p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} FALSE
    "switch_l3_heavy_int_leaf" ${switchtest} "${testExtraArgs} -DL3_HEAVY_INT_LEAF_PROFILE")
p4c_add_test_label("tofino" "18Q2Goal" "switch_l3_heavy_int_leaf")

p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} FALSE
    "switch_generic_int_leaf" ${switchtest} "${testExtraArgs} -DGENERIC_INT_LEAF_PROFILE")
p4c_add_test_label("tofino" "18Q2Goal" "switch_generic_int_leaf")

# Switch On Release 8.2 (refpoint must be periodically updated)
set  (SWITCH_8.2_P4 ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/switch-8.2/p4src/switch.p4)
set  (SWITCH_8.2_PTF_DIR ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/switch-8.2/ptf-tests/base/api-tests)
set  (SWITCH_8.2_PTF_DIR_MIRROR ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/switch-8.2/ptf-tests/base/feature-tests)
set  (SWITCH_8.2_PTF_DIR_SAI ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/switch-8.2/ptf-tests/base/sai-ocp-tests)
set  (SWITCH_8.2_PTF_DIR_EGRESSACL ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/switch-8.2/ptf-tests/egress-acl/api-tests)
set  (SWITCH_8.2_PTF_DIR_WRED ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/switch-8.2/ptf-tests/wred/api-tests)
set  (isXFail TRUE)
file (RELATIVE_PATH switch_8.2_test ${P4C_SOURCE_DIR} ${SWITCH_8.2_P4})

p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} FALSE 
    "switch_8.2_dc_basic" ${switch_8.2_test} "${testExtraArgs} -DDC_BASIC_PROFILE")
p4c_add_test_label("tofino" "18Q2Goal" "switch_8.2_dc_basic")

p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} ${isXFail}
    "switch_8.2_ent_fin_postcard" ${switch_8.2_test} "${testExtraArgs} -DENT_FIN_POSTCARD_PROFILE")
p4c_add_test_label("tofino" "18Q2Goal" "switch_8.2_ent_fin_postcard")

p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} FALSE
    "switch_8.2_ent_dc_general" ${switch_8.2_test} "${testExtraArgs} -DENT_DC_GENERAL_PROFILE")
p4c_add_test_label("tofino" "18Q2Goal" "switch_8.2_ent_dc_general")

p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} FALSE 
    "switch_8.2_msdc" ${switch_8.2_test} "${testExtraArgs} -DMSDC_PROFILE -DP4_WRED_DEBUG")
p4c_add_test_label("tofino" "18Q2Goal" "switch_8.2_msdc")

p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} FALSE
    "switch_8.2_msdc_ipv4" ${switch_8.2_test} "${testExtraArgs} -DMSDC_IPV4_PROFILE")
p4c_add_test_label("tofino" "18Q2Goal" "switch_8.2_msdc_ipv4")

p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} FALSE
    "switch_8.2_msdc_l3" ${switch_8.2_test} "${testExtraArgs} -DMSDC_L3_PROFILE")
p4c_add_test_label("tofino" "18Q2Goal" "switch_8.2_msdc_l3")

p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} FALSE 
    "switch_8.2_msdc_spine_int" ${switch_8.2_test} "${testExtraArgs} -DMSDC_SPINE_DTEL_INT_PROFILE")
p4c_add_test_label("tofino" "18Q2Goal" "switch_8.2_msdc_spine_int")

p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} FALSE 
    "switch_8.2_msdc_leaf_int" ${switch_8.2_test} "${testExtraArgs} -DMSDC_LEAF_DTEL_INT_PROFILE")
p4c_add_test_label("tofino" "18Q2Goal" "switch_8.2_msdc_spine_int")

p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} FALSE
    "switch_8.2_l3_heavy_int_leaf" ${switch_8.2_test} "${testExtraArgs} -DL3_HEAVY_INT_LEAF_PROFILE")
p4c_add_test_label("tofino" "18Q2Goal" "switch_8.2_l3_heavy_int_leaf")

p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} FALSE
    "switch_8.2_generic_int_leaf" ${switch_8.2_test} "${testExtraArgs} -DGENERIC_INT_LEAF_PROFILE")
p4c_add_test_label("tofino" "18Q2Goal" "switch_8.2_generic_int_leaf")


# Switch P4-16
set  (SWITCH_P4_16 ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/switch/p4_16src/switch.p4)
file (RELATIVE_PATH switch_p4_16_test ${P4C_SOURCE_DIR} ${SWITCH_P4_16})
p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} FALSE
  "switch_p4_16" ${switch_p4_16_test} "${testExtraArgs} -bfrt -tofino -arch tna")

# Switch Rel 8.1 MSDC_PROFILE tests
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

# Switch Rel 8.1 DC_BASIC_PROFILE tests
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
        switch_tests.L2MplsPopTest
        switch_tests.L3VINhopGleanBGPTest
        switch_tests.L3VINhopGleanTest
        switch_tests.MalformedPacketsTest_tunnel
        switch_mcast.L3MulticastBidir
        switch_tests.SnapshotIgL2Test
        switch_tests.SnapshotEgL3Ipv4Test")

p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_dc_basic_set_9" ${SWITCH_P4}
        "${testExtraArgs} -DDC_BASIC_PROFILE -pd -to 12000" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_dc_basic_set_9"
        "switch_tests.L2GeneveUnicastBasicTest
        switch_tests.L2IPv4InIPv6VxlanUnicastBasicTest
        switch_tests.L2NvgreUnicastBasicTest
        switch_tests.L2VxlanArpUnicastBasicTest
        switch_tests.L2VxlanToGeneveUnicastBasicTest
        switch_tests.L2VxlanUnicastBasicTest
        switch_tunnel.L3VxlanUnicastMultiTunnelSMTest
        switch_tunnel.L3VxlanUnicastTunnelECMPLagReflectionSMTest
        switch_tunnel.L3VxlanUnicastTunnelSMTest")


p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_dc_basic_L3MulticastStatsTest" ${SWITCH_P4}
          "${testExtraArgs} -DDC_BASIC_PROFILE -pd" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_dc_basic_L3MulticastStatsTest"
          "switch_mcast.L3MulticastStatsTest")

# 500s timeout is too little for compiling and testing the entire switch, bumping it up
set_tests_properties("tofino/smoketest_switch_dc_basic" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_dc_basic_set_1" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_dc_basic_set_2" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_dc_basic_set_3" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_dc_basic_set_4" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_dc_basic_set_5" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_dc_basic_set_6" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_dc_basic_set_7" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_dc_basic_set_8" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_dc_basic_set_9" PROPERTIES TIMEOUT 12000)

# Switch Rel 8.1 ENT_DC_GENERAL_PROFILE tests
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
        switch_tests.L2DynamicMacMoveTest
        switch_tests.L2DynamicLearnAgeTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_ent_dc_general_set_2" ${SWITCH_P4}
        "${testExtraArgs} -DENT_DC_GENERAL_PROFILE -pd -to 12000" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_ent_dc_general_set_2"
        "switch_tests.L2FloodTest
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
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_ent_dc_general_set_4" ${SWITCH_P4}
        "${testExtraArgs} -DENT_DC_GENERAL_PROFILE -pd -to 12000" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_ent_dc_general_set_4"
	"switch_acl.IPAclStatsTest
	switch_acl.AclLabelTest
	switch_acl.IPIngressAclRangeTcamTest
	switch_acl.IPAclTest
	switch_acl.MirrorAclTest_i2e
	switch_hostif.HostIfRxTxTest
	switch_tunnel.L3VxlanUnicastTunnelECMPSMTest
	switch_tests.L3VIIPv4HostVlanTaggingTest
	switch_tests.L3IPv4HostTest
	switch_tests.ExceptionPacketsTest_IPV6")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_ent_dc_general_set_5" ${SWITCH_P4}
        "${testExtraArgs} -DENT_DC_GENERAL_PROFILE -pd -to 12000" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_ent_dc_general_set_5"
	"switch_tests.L3IPv6LagTest
	switch_tests.L2StpEgressBlockingTest
	switch_tests.L3IPv4SubIntfHostTest
	switch_tests.L3IPv6EcmpTest
	switch_tests.L3IPv6LpmTest
	switch_tests.L3IPv6HostTest
	switch_tests.L3IPv6LpmEcmpTest
	switch_tests.MalformedPacketsTest_tunnel
	switch_tests.L3VIIPv4HostFloodTest
	switch_tests.L3IPv4EcmpTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_ent_dc_general_set_6" ${SWITCH_P4}
        "${testExtraArgs} -DENT_DC_GENERAL_PROFILE -pd -to 12000" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_ent_dc_general_set_6"
	"switch_tests.L3IPv4LagTest
	switch_tests.L3IPv4HostJumboTest
	switch_tests.L3EcmpLagTest
	switch_tests.L3VIIPv4HostMacMoveTest
	switch_tests.L3IPv4LpmTest
	switch_tests.L3VINhopGleanTest
	switch_tests.ExceptionPacketsTest
	switch_tests.CpuTxTest
	switch_tests.HostIfV6Test
	switch_tests.L3VIIPv6HostTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_ent_dc_general_set_7" ${SWITCH_P4}
        "${testExtraArgs} -DENT_DC_GENERAL_PROFILE -pd -to 12000" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_ent_dc_general_set_7"
	"switch_tests.L3IPv4LpmEcmpTest
	switch_tests.L2StpTest
	switch_tests.L3VIIPv4LagTest
	switch_tests.L3IPv4HostModifyTest
        switch_tests.L2DynamicMacLearnTest
        switch_tests.L2LagFloodTest
        switch_tests.L2VxlanUnicastLagBasicTest
	switch_tests.L3VIIPv4HostTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_ent_dc_general_set_8" ${SWITCH_P4}
        "${testExtraArgs} -DENT_DC_GENERAL_PROFILE -pd -to 12000" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_ent_dc_general_set_8"
        "switch_tunnel.L3VxlanUnicastTunnelECMPLagReflectionSMTest
        switch_tunnel.L3VxlanUnicastTunnelSMTest
        switch_tests.L2VxlanUnicastBasicTest
        switch_tests.L2VxlanArpUnicastBasicTest")
# 500s timeout is too little for compiling and testing the entire switch, bumping it up
set_tests_properties("tofino/smoketest_switch_ent_dc_general" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_ent_dc_general_set_1" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_ent_dc_general_set_2" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_ent_dc_general_set_3" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_ent_dc_general_set_4" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_ent_dc_general_set_5" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_ent_dc_general_set_6" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_ent_dc_general_set_7" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_ent_dc_general_set_8" PROPERTIES TIMEOUT 12000)

# Switch Rel 8.2 MSDC_PROFILE tests
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.2_msdc" ${SWITCH_8.2_P4}
    "${testExtraArgs} -DMSDC_PROFILE -DP4_WRED_DEBUG -pd -to 12000" "${SWITCH_8.2_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.2_msdc"
        "switch_acl.MirrorSessionTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.2_msdc_set_1" ${SWITCH_8.2_P4}
    "${testExtraArgs} -DMSDC_PROFILE -DP4_WRED_DEBUG -pd -to 12000" "${SWITCH_8.2_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.2_msdc_set_1"
        "switch_acl.Acl_i2e_ErspanRewriteTest
        switch_acl.AclLabelTest
        switch_acl.IPAclTest
        switch_acl.IPAclStatsTest
        switch_acl.IPIngressAclRangeTcamTest
        switch_acl.MirrorAclTest_e2e
        switch_acl.MirrorAclTest_i2e")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.2_msdc_set_2" ${SWITCH_8.2_P4}
    "${testExtraArgs} -DMSDC_PROFILE -DP4_WRED_DEBUG -pd -to 12000" "${SWITCH_8.2_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.2_msdc_set_2"
        "switch_hostif.HostIfLagRxTxTest
        switch_hostif.HostIfRxTxTest
        switch_mirror.MirrorPortTest
        switch_tests.CpuTxTest
        switch_tests.ExceptionPacketsTest
        switch_tests.ExceptionPacketsTest_IPV6
        switch_tests.HostIfV6Test")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.2_msdc_set_3" ${SWITCH_8.2_P4}
    "${testExtraArgs} -DMSDC_PROFILE -DP4_WRED_DEBUG -pd -to 12000" "${SWITCH_8.2_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.2_msdc_set_3"
        "switch_tests.L2AccessToAccessVlanTest
        switch_tests.L2AccessToTrunkPriorityTaggingTest
        switch_tests.L2AccessToTrunkVlanJumboTest
        switch_tests.L2AccessToTrunkVlanTest
        switch_tests.L2AgingTest
        switch_tests.L2DynamicLearnAgeTest
        switch_tests.L2DynamicMacLearnTest
        switch_tests.L2DynamicMacMoveTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.2_msdc_set_4" ${SWITCH_8.2_P4}
    "${testExtraArgs} -DMSDC_PROFILE -DP4_WRED_DEBUG -pd -to 12000" "${SWITCH_8.2_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.2_msdc_set_4"
        "switch_tests.L2FloodTest
        switch_tests.L2LagTest
        switch_tests.L2LNStatsTest
        switch_tests.L2MacLearnTest
        switch_tests.L2StaticMacBulkDeleteTest
        switch_tests.L2StaticMacMoveBulkTest
        switch_tests.L2StaticMacMoveTest
        switch_tests.L2TrunkToAccessVlanTest
        switch_tests.L2TrunkToTrunkVlanTest
        switch_tests.L2VlanStatsTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.2_msdc_set_5" ${SWITCH_8.2_P4}
    "${testExtraArgs} -DMSDC_PROFILE -DP4_WRED_DEBUG -pd -to 12000" "${SWITCH_8.2_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.2_msdc_set_5"
        "switch_tests.L3EcmpLagTest
        switch_tests.L3IPv4EcmpTest
        switch_tests.L3IPv4HostTest
        switch_tests.L3IPv4HostJumboTest
        switch_tests.L3IPv4HostModifyTest
        switch_tests.L3IPv4LagTest
        switch_tests.L3IPv4LookupTest
        switch_tests.L3IPv4LpmEcmpTest
        switch_tests.L3IPv4LpmTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.2_msdc_set_6" ${SWITCH_8.2_P4}
    "${testExtraArgs} -DMSDC_PROFILE -DP4_WRED_DEBUG -pd -to 12000" "${SWITCH_8.2_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.2_msdc_set_6"
        "switch_tests.L3IPv4MtuTest
        switch_tests.L3IPv4SubIntfHostTest
        switch_tests.L3IPv6EcmpTest
        switch_tests.L3IPv6HostTest
        switch_tests.L3IPv6LagTest
        switch_tests.L3IPv6LookupTest
        switch_tests.L3IPv6LpmEcmpTest
        switch_tests.L3IPv6LpmTest
        switch_tests.L3VIFloodTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.2_msdc_set_7" ${SWITCH_8.2_P4}
    "${testExtraArgs} -DMSDC_PROFILE -DP4_WRED_DEBUG -pd -to 12000" "${SWITCH_8.2_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.2_msdc_set_7"
        "switch_tests.HostIfTest
        switch_tests.L3VIIPv4HostFloodTest
        switch_tests.L3VIIPv4HostMacMoveTest
        switch_tests.L3VIIPv4HostVlanTaggingTest
        switch_tests.L3VIIPv4HostTest
        switch_tests.L3VIIPv4LagTest
        switch_tests.L3VIIPv6HostTest
        switch_tests.L3VINhopGleanTest
        switch_tests.MalformedPacketsTest
        switch_tests.MalformedPacketsTest_ipv6")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.2_msdc_set_8" ${SWITCH_8.2_P4}
        "${testExtraArgs} -DMSDC_PROFILE -DP4_WRED_DEBUG -pd -to 12000" "${SWITCH_8.2_PTF_DIR_MIRROR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.2_msdc_set_8"
        "mirror_acl_slice_tests.IPv6MirrorAclSliceTest_i2e
        mirror_acl_slice_tests.MirrorAclSliceTest_i2e")
# 500s timeout is too little for compiling and testing the entire switch, bumping it up
set_tests_properties("tofino/smoketest_switch_8.2_msdc" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_8.2_msdc_set_1" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_8.2_msdc_set_2" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_8.2_msdc_set_3" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_8.2_msdc_set_4" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_8.2_msdc_set_5" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_8.2_msdc_set_6" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_8.2_msdc_set_7" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_8.2_msdc_set_8" PROPERTIES TIMEOUT 12000)

# Switch Rel 8.2 ENT_DC_GENERAL_PROFILE tests
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.2_ent_dc_general" ${SWITCH_8.2_P4}
    "${testExtraArgs} -DENT_DC_GENERAL_PROFILE -pd -to 12000" "${SWITCH_8.2_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.2_ent_dc_general"
        "switch_acl.MirrorSessionTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.2_ent_dc_general_set_1" ${SWITCH_8.2_P4}
    "${testExtraArgs} -DENT_DC_GENERAL_PROFILE -pd -to 12000" "${SWITCH_8.2_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.2_ent_dc_general_set_1"
        "switch_acl.AclLabelTest
        switch_acl.IPAclStatsTest
        switch_acl.IPAclTest
        switch_acl.IPIngressAclRangeTcamTest
        switch_acl.MirrorAclTest_i2e
        switch_hostif.HostIfLagRxTxTest
        switch_hostif.HostIfPtpTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.2_ent_dc_general_set_2" ${SWITCH_8.2_P4}
    "${testExtraArgs} -DENT_DC_GENERAL_PROFILE -pd -to 12000" "${SWITCH_8.2_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.2_ent_dc_general_set_2"
        "switch_hostif.HostIfRxTxTest
        switch_mirror.MirrorPortTest
        switch_tests.CpuTxTest
        switch_tests.ExceptionPacketsTest
        switch_tests.ExceptionPacketsTest_IPV6
        switch_tests.HostIfV6Test
        switch_tests.MalformedPacketsTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.2_ent_dc_general_set_3" ${SWITCH_8.2_P4}
    "${testExtraArgs} -DENT_DC_GENERAL_PROFILE -pd -to 12000" "${SWITCH_8.2_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.2_ent_dc_general_set_3"
        "switch_tests.MalformedPacketsTest_ipv6
        switch_tests.MalformedPacketsTest_tunnel
        switch_tests.L2AccessToAccessVlanTest
        switch_tests.L2AccessToTrunkPriorityTaggingTest
        switch_tests.L2AccessToTrunkVlanJumboTest
        switch_tests.L2AccessToTrunkVlanTest
        switch_tests.L2AgingTest
        switch_tests.L2DynamicLearnAgeTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.2_ent_dc_general_set_4" ${SWITCH_8.2_P4}
    "${testExtraArgs} -DENT_DC_GENERAL_PROFILE -pd -to 12000" "${SWITCH_8.2_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.2_ent_dc_general_set_4"
        "switch_tests.L2DynamicMacLearnTest
        switch_tests.L2DynamicMacMoveTest
        switch_tests.L2FloodTest
        switch_tests.L2LagFloodTest
        switch_tests.L2LagTest
        switch_tests.L2LNStatsTest
        switch_tests.L2LNSubIntfEncapTest
        switch_tests.L2MacLearnTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.2_ent_dc_general_set_5" ${SWITCH_8.2_P4}
    "${testExtraArgs} -DENT_DC_GENERAL_PROFILE -pd -to 12000" "${SWITCH_8.2_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.2_ent_dc_general_set_5"
        "switch_tests.L2StaticMacBulkDeleteTest
        switch_tests.L2StaticMacMoveBulkTest
        switch_tests.L2StaticMacMoveTest
        switch_tests.L2StpEgressBlockingTest
        switch_tests.L2StpTest
        switch_tests.L2TrunkToAccessVlanTest
        switch_tests.L2TrunkToTrunkVlanTest
        switch_tests.L2VlanStatsTest
        switch_tests.L2VxlanArpUnicastBasicTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.2_ent_dc_general_set_6" ${SWITCH_8.2_P4}
    "${testExtraArgs} -DENT_DC_GENERAL_PROFILE -pd -to 12000" "${SWITCH_8.2_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.2_ent_dc_general_set_6"
        "switch_tests.L2VxlanFloodBasicTest
        switch_tests.L2VxlanLearnBasicTest
        switch_tests.L2VxlanUnicastBasicTest
        switch_tests.L2VxlanUnicastLagBasicTest
        switch_tests.L3EcmpLagTest
        switch_tests.L3IPv4EcmpTest
        switch_tests.L3IPv4HostJumboTest
        switch_tests.L3IPv4HostModifyTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.2_ent_dc_general_set_7" ${SWITCH_8.2_P4}
    "${testExtraArgs} -DENT_DC_GENERAL_PROFILE -pd -to 12000" "${SWITCH_8.2_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.2_ent_dc_general_set_7"
        "switch_tests.L3IPv4HostTest
        switch_tests.L3IPv4LagTest
        switch_tests.L3IPv4LookupTest
        switch_tests.L3IPv4LpmEcmpTest
        switch_tests.L3IPv4LpmTest
        switch_tests.L3IPv4MtuTest
        switch_tests.L3IPv4SubIntfHostTest
        switch_tests.L3IPv6EcmpTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.2_ent_dc_general_set_8" ${SWITCH_8.2_P4}
    "${testExtraArgs} -DENT_DC_GENERAL_PROFILE -pd -to 12000" "${SWITCH_8.2_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.2_ent_dc_general_set_8"
        "switch_tests.L3IPv6HostTest
        switch_tests.L3IPv6LagTest
        switch_tests.L3IPv6LookupTest
        switch_tests.L3IPv6LpmEcmpTest
        switch_tests.L3IPv6LpmTest
        switch_tests.L3VIFloodTest
        switch_tests.L3VIIPv4HostFloodTest
        switch_tests.L3VIIPv4HostMacMoveTest
        switch_tests.L3VIIPv4HostTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.2_ent_dc_general_set_9" ${SWITCH_8.2_P4}
    "${testExtraArgs} -DENT_DC_GENERAL_PROFILE -pd -to 12000" "${SWITCH_8.2_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.2_ent_dc_general_set_9"
        "switch_tests.HostIfTest
        switch_tests.L3VIIPv4HostVlanTaggingTest
        switch_tests.L3VIIPv4LagTest
        switch_tests.L3VIIPv6HostTest
        switch_tests.L3VINhopGleanTest
        switch_tunnel.L3VxlanUnicastTunnelECMPLagReflectionSMTest
        switch_tunnel.L3VxlanUnicastTunnelECMPSMTest
        switch_tunnel.L3VxlanUnicastTunnelSMSVITest
        switch_tunnel.L3VxlanUnicastTunnelSMTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.2_ent_dc_general_set_10" ${SWITCH_8.2_P4}
    "${testExtraArgs} -DENT_DC_GENERAL_PROFILE -pd -to 12000" "${SWITCH_8.2_PTF_DIR_EGRESSACL}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.2_ent_dc_general_set_10"
        "switch_api_tests.IPEgressAclRangeTcamTest
        switch_api_tests.IPEgressAclTest")
# 500s timeout is too little for compiling and testing the entire switch, bumping it up
set_tests_properties("tofino/smoketest_switch_8.2_ent_dc_general" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_8.2_ent_dc_general_set_1" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_8.2_ent_dc_general_set_2" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_8.2_ent_dc_general_set_3" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_8.2_ent_dc_general_set_4" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_8.2_ent_dc_general_set_5" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_8.2_ent_dc_general_set_6" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_8.2_ent_dc_general_set_7" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_8.2_ent_dc_general_set_8" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_8.2_ent_dc_general_set_9" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_8.2_ent_dc_general_set_10" PROPERTIES TIMEOUT 12000)

# Switch Rel 8.2 MSDC_L3_PROFILE_BRIG tests
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.2_l3_msdc" ${SWITCH_8.2_P4}
    "${testExtraArgs} -DMSDC_L3_PROFILE -DP4_WRED_DEBUG -pd -to 12000" "${SWITCH_8.2_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.2_l3_msdc"
        "switch_acl.MirrorSessionTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.2_l3_msdc_set_1" ${SWITCH_8.2_P4}
    "${testExtraArgs} -DMSDC_L3_PROFILE -DP4_WRED_DEBUG -pd -to 12000" "${SWITCH_8.2_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.2_l3_msdc_set_1"
        "switch_acl.Acl_i2e_ErspanRewriteTest
        switch_acl.AclLabelTest
        switch_acl.IPAclStatsTest
        switch_acl.IPAclTest
        switch_acl.IPIngressAclRangeTcamTest
        switch_acl.MirrorAclTest_e2e
        switch_acl.MirrorAclTest_i2e
        switch_hostif.HostIfLagRxTxTest
        switch_hostif.HostIfRxTxTest
        switch_mirror.MirrorPortTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.2_l3_msdc_set_2" ${SWITCH_8.2_P4}
    "${testExtraArgs} -DMSDC_L3_PROFILE -DP4_WRED_DEBUG -pd -to 12000" "${SWITCH_8.2_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.2_l3_msdc_set_2"
        "switch_tests.CpuTxTest
        switch_tests.ExceptionPacketsTest
        switch_tests.ExceptionPacketsTest_IPV6
        switch_tests.HostIfV6Test
        switch_tests.IPinIPTest
        switch_tests.L2AccessToAccessVlanTest
        switch_tests.L2AccessToTrunkPriorityTaggingTest
        switch_tests.L2AccessToTrunkVlanJumboTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.2_l3_msdc_set_3" ${SWITCH_8.2_P4}
    "${testExtraArgs} -DMSDC_L3_PROFILE -DP4_WRED_DEBUG -pd -to 12000" "${SWITCH_8.2_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.2_l3_msdc_set_3"
        "switch_tests.L2AccessToTrunkVlanTest
        switch_tests.L2AgingTest
        switch_tests.L2DynamicLearnAgeTest
        switch_tests.L2DynamicMacLearnTest
        switch_tests.L2DynamicMacMoveTest
        switch_tests.L2FloodTest
        switch_tests.L2IPv4InIPv6VxlanUnicastBasicTest
        switch_tests.L2LagTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.2_l3_msdc_set_4" ${SWITCH_8.2_P4}
    "${testExtraArgs} -DMSDC_L3_PROFILE -DP4_WRED_DEBUG -pd -to 12000" "${SWITCH_8.2_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.2_l3_msdc_set_4"
        "switch_tests.L2LNStatsTest
        switch_tests.L2LNSubIntfEncapTest
        switch_tests.L2MacLearnTest
        switch_tests.L2StaticMacBulkDeleteTest
        switch_tests.L2StaticMacMoveBulkTest
        switch_tests.L2StaticMacMoveTest
        switch_tests.L2TrunkToAccessVlanTest
        switch_tests.L2TrunkToTrunkVlanTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.2_l3_msdc_set_5" ${SWITCH_8.2_P4}
    "${testExtraArgs} -DMSDC_L3_PROFILE -DP4_WRED_DEBUG -pd -to 12000" "${SWITCH_8.2_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.2_l3_msdc_set_5"
        "switch_tests.L2TunnelFloodEnhancedTest
        switch_tests.L2VlanStatsTest
        switch_tests.L2VxlanArpUnicastBasicTest
        switch_tests.L2VxlanUnicastBasicTest
        switch_tests.L2VxlanUnicastLagBasicTest
        switch_tests.L3IPv4EcmpTest
        switch_tests.L3IPv4HostJumboTest
        switch_tests.L3IPv4HostModifyTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.2_l3_msdc_set_6" ${SWITCH_8.2_P4}
    "${testExtraArgs} -DMSDC_L3_PROFILE -DP4_WRED_DEBUG -pd -to 12000" "${SWITCH_8.2_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.2_l3_msdc_set_6"
        "switch_tests.L3IPv4HostTest
        switch_tests.L3IPv4LagTest
        switch_tests.L3IPv4LookupTest
        switch_tests.L3IPv4LpmEcmpTest
        switch_tests.L3IPv4LpmTest
        switch_tests.L3IPv4MtuTest
        switch_tests.L3IPv4SubIntfHostTest
        switch_tests.L3IPv6EcmpTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.2_l3_msdc_set_7" ${SWITCH_8.2_P4}
    "${testExtraArgs} -DMSDC_L3_PROFILE -DP4_WRED_DEBUG -pd -to 12000" "${SWITCH_8.2_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.2_l3_msdc_set_7"
        "switch_tests.L3IPv6HostTest
        switch_tests.L3IPv6LagTest
        switch_tests.L3IPv6LookupTest
        switch_tests.L3IPv6LpmEcmpTest
        switch_tests.L3IPv6LpmTest
        switch_tests.L3VIIPv4HostFloodTest
        switch_tests.L3VIIPv4HostMacMoveTest
        switch_tests.L3VIIPv4HostVlanTaggingTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.2_l3_msdc_set_8" ${SWITCH_8.2_P4}
    "${testExtraArgs} -DMSDC_L3_PROFILE -DP4_WRED_DEBUG -pd -to 12000" "${SWITCH_8.2_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.2_l3_msdc_set_8"
        "switch_tests.HostIfTest
        switch_tests.L3VIFloodTest
        switch_tests.L3VIIPv4HostTest
        switch_tests.L3VIIPv4LagTest
        switch_tests.L3VIIPv6HostTest
        switch_tests.L3VINhopGleanTest
        switch_tests.MalformedPacketsTest_tunnel
        switch_tests.MalformedPacketsTest
        switch_tests.MalformedPacketsTest_ipv6")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.2_l3_msdc_set_9" ${SWITCH_8.2_P4}
    "${testExtraArgs} -DMSDC_L3_PROFILE -DP4_WRED_DEBUG -pd -to 12000" "${SWITCH_8.2_PTF_DIR_WRED}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.2_l3_msdc_set_9"
        "switch_wred.WredLookupTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.2_l3_msdc_WredIpv6Test" ${SWITCH_8.2_P4}
    "${testExtraArgs} -DMSDC_L3_PROFILE -DP4_WRED_DEBUG -pd -to 12000" "${SWITCH_8.2_PTF_DIR_WRED}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.2_l3_msdc_WredIpv6Test"
        "switch_wred.WredIpv6Test")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.2_l3_msdc_WredStatsTest" ${SWITCH_8.2_P4}
    "${testExtraArgs} -DMSDC_L3_PROFILE -DP4_WRED_DEBUG -pd -to 12000" "${SWITCH_8.2_PTF_DIR_WRED}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.2_l3_msdc_WredStatsTest"
        "switch_wred.WredStatsTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.2_l3_msdc_WredDropIpv4Test" ${SWITCH_8.2_P4}
    "${testExtraArgs} -DMSDC_L3_PROFILE -DP4_WRED_DEBUG -pd -to 12000" "${SWITCH_8.2_PTF_DIR_WRED}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.2_l3_msdc_WredDropIpv4Test"
    "switch_wred.WredDropIpv4Test")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.2_l3_msdc_WredIpv4Test" ${SWITCH_8.2_P4}
    "${testExtraArgs} -DMSDC_L3_PROFILE -DP4_WRED_DEBUG -pd -to 12000" "${SWITCH_8.2_PTF_DIR_WRED}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.2_l3_msdc_WredIpv4Test"
        "switch_wred.WredIpv4Test")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.2_l3_msdc_L3EcmpLagTest" ${SWITCH_8.2_P4}
    "${testExtraArgs} -DMSDC_L3_PROFILE -DP4_WRED_DEBUG -pd -to 12000" "${SWITCH_8.2_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.2_l3_msdc_L3EcmpLagTest"
        "switch_tests.L3EcmpLagTest")
# 500s timeout is too little for compiling and testing the entire switch, bumping it up
set_tests_properties("tofino/smoketest_switch_8.2_l3_msdc" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_8.2_l3_msdc_set_1" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_8.2_l3_msdc_set_2" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_8.2_l3_msdc_set_3" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_8.2_l3_msdc_set_4" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_8.2_l3_msdc_set_5" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_8.2_l3_msdc_set_6" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_8.2_l3_msdc_set_7" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_8.2_l3_msdc_set_8" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_8.2_l3_msdc_set_9" PROPERTIES TIMEOUT 12000)

# Switch Rel 8.2 DC_BASIC_PROFILE_BRIG tests
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.2_dc_basic" ${SWITCH_8.2_P4}
    "${testExtraArgs} -DDC_BASIC_PROFILE -pd -to 12000" "${SWITCH_8.2_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.2_dc_basic"
        "switch_acl.MirrorSessionTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.2_dc_basic_set_1" ${SWITCH_8.2_P4}
    "${testExtraArgs} -DDC_BASIC_PROFILE -pd -to 12000" "${SWITCH_8.2_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.2_dc_basic_set_1"
        "fast_reconfig_tests.FastReconfigBigTest
        fast_reconfig_tests.MultipleWarmInitTest
        fast_reconfig_tests.NormalthanWarmInitTest
        fast_reconfig_tests.RegularWarmInitTest
        switch_acl.Acl_i2e_ErspanRewriteTest
        switch_acl.AclLabelTest
        switch_acl.IPAclStatsTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.2_dc_basic_set_2" ${SWITCH_8.2_P4}
    "${testExtraArgs} -DDC_BASIC_PROFILE -pd -to 12000" "${SWITCH_8.2_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.2_dc_basic_set_2"
        "switch_acl.IPAclTest
        switch_acl.IPIngressAclRangeTcamTest
        switch_acl.IPv6RAclTest
        switch_acl.MirrorAclTest_e2e
        switch_acl.MirrorAclTest_i2e
        switch_get.AclGetTest
        switch_get.BufferGetTest
        switch_get.DeviceGetTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.2_dc_basic_set_3" ${SWITCH_8.2_P4}
    "${testExtraArgs} -DDC_BASIC_PROFILE -pd -to 12000" "${SWITCH_8.2_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.2_dc_basic_set_3"
        "switch_get.HostIfGetTest
        switch_get.InterfaceGetTest
        switch_get.L2GetTest
        switch_get.LagGetTest
        switch_get.MirrorGetTest
        switch_get.MtreeGetTest
        switch_get.NhopGetTest
        switch_get.PortGetTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.2_dc_basic_set_4" ${SWITCH_8.2_P4}
    "${testExtraArgs} -DDC_BASIC_PROFILE -pd -to 12000" "${SWITCH_8.2_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.2_dc_basic_set_4"
        "switch_get.QosGetTest
        switch_get.RifGetTest
        switch_get.VlanGetTest
        switch_get.VrfRmacGetTest
        switch_hostif.HostIfLagRxTxTest
        switch_hostif.HostIfPtpTest
        switch_hostif.HostIfRxTxTest
        switch_mirror.MirrorPortTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.2_dc_basic_set_5" ${SWITCH_8.2_P4}
    "${testExtraArgs} -DDC_BASIC_PROFILE -pd -to 12000" "${SWITCH_8.2_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.2_dc_basic_set_5"
        "switch_tests.DeviceInfoTest
        switch_tests.CpuTxTest
        switch_tests.ExceptionPacketsTest
        switch_tests.ExceptionPacketsTest_IPV6
        switch_tests.HostIfV6Test
        switch_tests.IPinIPTest
        switch_tests.IPNeighborTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.2_dc_basic_set_6" ${SWITCH_8.2_P4}
    "${testExtraArgs} -DDC_BASIC_PROFILE -pd -to 12000" "${SWITCH_8.2_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.2_dc_basic_set_6"
        "switch_tests.L2AccessToAccessVlanTest
        switch_tests.L2AccessToTrunkPriorityTaggingTest
        switch_tests.L2AccessToTrunkVlanJumboTest
        switch_tests.L2AccessToTrunkVlanTest
        switch_tests.L2AgingTest
        switch_tests.L2DynamicLearnAgeTest
        switch_tests.L2DynamicMacLearnTest
        switch_tests.L2DynamicMacMoveTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.2_dc_basic_set_7" ${SWITCH_8.2_P4}
    "${testExtraArgs} -DDC_BASIC_PROFILE -pd -to 12000" "${SWITCH_8.2_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.2_dc_basic_set_7"
        "switch_tests.L2FloodTest
        switch_tests.L2GeneveUnicastBasicTest
        switch_tests.L2GeneveUnicastLagBasicTest
        switch_tests.L2IPv4InIPv6VxlanUnicastBasicTest
        switch_tests.L2LagFloodTest
        switch_tests.L2LagTest
        switch_tests.L2LNStatsTest
        switch_tests.L2LNSubIntfEncapTest
        switch_tests.L2MacLearnTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.2_dc_basic_set_8" ${SWITCH_8.2_P4}
    "${testExtraArgs} -DDC_BASIC_PROFILE -pd -to 12000" "${SWITCH_8.2_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.2_dc_basic_set_8"
        "switch_tests.L2MplsPopTest
        switch_tests.L2MplsPushJumboTest
        switch_tests.L2MplsPushTest
        switch_tests.L2MplsSwapTest
        switch_tests.L2NvgreUnicastBasicTest
        switch_tests.L2NvgreUnicastLagBasicTest
        switch_tests.L2StaticMacBulkDeleteTest
        switch_tests.L2StaticMacMoveBulkTest
        switch_tests.L2StaticMacMoveTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.2_dc_basic_set_9" ${SWITCH_8.2_P4}
    "${testExtraArgs} -DDC_BASIC_PROFILE -pd -to 12000" "${SWITCH_8.2_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.2_dc_basic_set_9"
        "switch_tests.L2StpEgressBlockingTest
        switch_tests.L2StpTest
        switch_tests.L2TrunkToAccessVlanTest
        switch_tests.L2TrunkToTrunkVlanTest
        switch_tests.L2TunnelFloodEnhancedTest
        switch_tests.L2TunnelSplicingExtreme1Test
        switch_tests.L2TunnelSplicingExtreme2Test
        switch_tests.L2VlanStatsTest
        switch_tests.L2VxlanArpUnicastBasicTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.2_dc_basic_set_10" ${SWITCH_8.2_P4}
    "${testExtraArgs} -DDC_BASIC_PROFILE -pd -to 12000" "${SWITCH_8.2_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.2_dc_basic_set_10"
        "switch_tests.L2VxlanFloodBasicTest
        switch_tests.L2VxlanLearnBasicTest
        switch_tests.L2VxlanToGeneveUnicastBasicTest
        switch_tests.L2VxlanToGeneveUnicastEnhancedTest
        switch_tests.L2VxlanToGeneveUnicastLagBasicTest
        switch_tests.L2VxlanToGeneveUnicastLagEnhancedTest
        switch_tests.L2VxlanUnicastBasicTest
        switch_tests.L2VxlanUnicastLagBasicTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.2_dc_basic_set_11" ${SWITCH_8.2_P4}
    "${testExtraArgs} -DDC_BASIC_PROFILE -pd -to 12000" "${SWITCH_8.2_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.2_dc_basic_set_11"
        "switch_mcast.L3Multicast
        switch_mcast.L3MulticastBidir
        switch_mcast.L3MulticastStatsTest
        switch_mcast.L3MulticastToEcmp
        switch_tests.MalformedPacketsTest
        switch_tests.MalformedPacketsTest_tunnel
        switch_tests.MalformedPacketsTest_ipv6")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.2_dc_basic_set_12" ${SWITCH_8.2_P4}
    "${testExtraArgs} -DDC_BASIC_PROFILE -pd -to 12000" "${SWITCH_8.2_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.2_dc_basic_set_12"
        "switch_tests.L3EcmpLagTest
        switch_tests.L3IPv4EcmpTest
        switch_tests.L3IPv4HostJumboTest
        switch_tests.L3IPv4HostModifyTest
        switch_tests.L3IPv4HostTest
        switch_tests.L3IPv4LagTest
        switch_tests.L3IPv4LookupTest
        switch_tests.L3IPv4LpmEcmpTest
        switch_tests.L3IPv4LpmTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.2_dc_basic_set_13" ${SWITCH_8.2_P4}
    "${testExtraArgs} -DDC_BASIC_PROFILE -pd -to 12000" "${SWITCH_8.2_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.2_dc_basic_set_13"
        "switch_tests.L3IPv4MtuTest
        switch_tests.L3IPv4SubIntfHostTest
        switch_tests.L3IPv6EcmpTest
        switch_tests.L3IPv6HostTest
        switch_tests.L3IPv6LagTest
        switch_tests.L3IPv6LookupTest
        switch_tests.L3IPv6LpmEcmpTest
        switch_tests.L3IPv6LpmTest
        switch_tests.L3MplsPopTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.2_dc_basic_set_14" ${SWITCH_8.2_P4}
    "${testExtraArgs} -DDC_BASIC_PROFILE -pd -to 12000" "${SWITCH_8.2_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.2_dc_basic_set_14"
        "switch_tests.L3MplsPushTest
        switch_tests.L3RpfTest
        switch_tests.L3VIFloodTest
        switch_tests.L3VIIPv4HostFloodTest
        switch_tests.L3VIIPv4HostMacMoveTest
        switch_tests.L3VIIPv4HostTest
        switch_tests.L3VIIPv4HostVlanTaggingTest
        switch_tests.L3VIIPv4LagTest
        switch_tests.L3VIIPv6HostTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.2_dc_basic_set_15" ${SWITCH_8.2_P4}
    "${testExtraArgs} -DDC_BASIC_PROFILE -pd -to 12000" "${SWITCH_8.2_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.2_dc_basic_set_15"
        "switch_tests.HostIfTest
        switch_tests.L3VINhopGleanBGPTest
        switch_tests.L3VINhopGleanTest
        switch_tunnel.L3VxlanUnicastMultiTunnelSMTest
        switch_tunnel.L3VxlanUnicastTunnelECMPLagReflectionSMTest
        switch_tunnel.L3VxlanUnicastTunnelECMPSMTest
        switch_tunnel.L3VxlanUnicastTunnelSMSVITest
        switch_tunnel.L3VxlanUnicastTunnelSMTest")
# 500s timeout is too little for compiling and testing the entire switch, bumping it up
set_tests_properties("tofino/smoketest_switch_8.2_dc_basic" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_8.2_dc_basic_set_1" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_8.2_dc_basic_set_2" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_8.2_dc_basic_set_3" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_8.2_dc_basic_set_4" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_8.2_dc_basic_set_5" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_8.2_dc_basic_set_6" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_8.2_dc_basic_set_7" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_8.2_dc_basic_set_8" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_8.2_dc_basic_set_9" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_8.2_dc_basic_set_10" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_8.2_dc_basic_set_11" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_8.2_dc_basic_set_12" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_8.2_dc_basic_set_13" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_8.2_dc_basic_set_14" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_8.2_dc_basic_set_15" PROPERTIES TIMEOUT 12000)

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
