include (ExternalProject)

# Switch P4-14 On Master (refpoint must be periodically updated)
set  (SWITCH_P4 ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/switch/p4src/switch.p4)
set  (SWITCH_PTF_DIR ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/switch/ptf-tests/base/api-tests)
set  (SWITCH_PTF_DIR_MIRROR ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/switch/ptf-tests/base/feature-tests)
set  (SWITCH_PTF_DIR_EGRESS_ACL ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/switch/ptf-tests/egress-acl/api-tests)
set  (SWITCH_PTF_DIR_WRED ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/switch/ptf-tests/wred/api-tests)
set  (testExtraArgs "${testExtraArgs} -Xp4c=\"--disable-power-check\"")
set  (isXFail TRUE)

file (RELATIVE_PATH switchtest ${P4C_SOURCE_DIR} ${SWITCH_P4})
p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} FALSE
    "switch_dc_basic" ${switchtest} "${testExtraArgs}" "-DDC_BASIC_PROFILE")

p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} FALSE
    "switch_ent_fin_postcard" ${switchtest} "${testExtraArgs}" "-DENT_FIN_POSTCARD_PROFILE")

p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} FALSE
    "switch_ent_dc_general" ${switchtest} "${testExtraArgs}" "-DENT_DC_GENERAL_PROFILE")

p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} FALSE
    "switch_msdc" ${switchtest} "${testExtraArgs}" "-DMSDC_PROFILE -DP4_WRED_DEBUG")

p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} FALSE}
    "switch_msdc_ipv4" ${switchtest} "${testExtraArgs}" "-DMSDC_IPV4_PROFILE")

p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} FALSE
    "switch_msdc_l3" ${switchtest} "${testExtraArgs}" "-DMSDC_L3_PROFILE")

p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} FALSE
    "switch_msdc_spine_int" ${switchtest} "${testExtraArgs}" "-DMSDC_SPINE_DTEL_INT_PROFILE")

p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} FALSE
    "switch_msdc_leaf_int" ${switchtest} "${testExtraArgs}" "-DMSDC_LEAF_DTEL_INT_PROFILE")

p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} FALSE
    "switch_l3_heavy_int_leaf" ${switchtest} "${testExtraArgs}" "-DL3_HEAVY_INT_LEAF_PROFILE")

p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} FALSE
    "switch_generic_int_leaf" ${switchtest} "${testExtraArgs}" "-DGENERIC_INT_LEAF_PROFILE")

# Switch On Release 8.4 (refpoint must be periodically updated)
set  (SWITCH_8.4_P4 ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/switch-8.4/p4src/switch.p4)
set  (SWITCH_8.4_PTF_DIR ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/switch-8.4/ptf-tests/base/api-tests)
set  (SWITCH_8.4_PTF_DIR_MIRROR ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/switch-8.4/ptf-tests/base/feature-tests)
set  (SWITCH_8.4_PTF_DIR_SAI ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/switch-8.4/ptf-tests/base/sai-ocp-tests)
set  (SWITCH_8.4_PTF_DIR_SAI_DTEL ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/switch-8.4/ptf-tests/dtel/sai-tests)
set  (SWITCH_8.4_PTF_DIR_EGRESS_ACL ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/switch-8.4/ptf-tests/egress-acl/api-tests)
set  (SWITCH_8.4_PTF_DIR_WRED ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/switch-8.4/ptf-tests/wred/api-tests)
set  (SWITCH_8.4_PTF_DIR_DTEL ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/switch-8.4/ptf-tests/dtel/api-tests)
set  (SWITCH_8.4_PTF_DIR_QOS ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/switch-8.4/ptf-tests/qos/api-tests)
set  (isXFail TRUE)
file (RELATIVE_PATH switch_8.4_test ${P4C_SOURCE_DIR} ${SWITCH_8.4_P4})

p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} FALSE
    "switch_8.4_dc_basic" ${switch_8.4_test} "${testExtraArgs}" "-DDC_BASIC_PROFILE")

p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} ${isXFail}
    "switch_8.4_ent_fin_postcard" ${switch_8.4_test} "${testExtraArgs}" "-DENT_FIN_POSTCARD_PROFILE")

p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} FALSE
    "switch_8.4_ent_dc_general" ${switch_8.4_test} "${testExtraArgs}" "-DENT_DC_GENERAL_PROFILE")

p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} FALSE
    "switch_8.4_msdc" ${switch_8.4_test} "${testExtraArgs}" "-DMSDC_PROFILE -DP4_WRED_DEBUG")

p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} FALSE
    "switch_8.4_msdc_ipv4" ${switch_8.4_test} "${testExtraArgs}" "-DMSDC_IPV4_PROFILE")

p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} FALSE
    "switch_8.4_msdc_l3" ${switch_8.4_test} "${testExtraArgs}" "-DMSDC_L3_PROFILE")

p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} FALSE
    "switch_8.4_msdc_spine_int" ${switch_8.4_test} "${testExtraArgs}" "-DMSDC_SPINE_DTEL_INT_PROFILE")

p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} FALSE
    "switch_8.4_msdc_leaf_int" ${switch_8.4_test} "${testExtraArgs}" "-DMSDC_LEAF_DTEL_INT_PROFILE")

p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} FALSE
    "switch_8.4_l3_heavy_int_leaf" ${switch_8.4_test} "${testExtraArgs}" "-DL3_HEAVY_INT_LEAF_PROFILE")

p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} FALSE
    "switch_8.4_generic_int_leaf" ${switch_8.4_test} "${testExtraArgs}" "-DGENERIC_INT_LEAF_PROFILE")

# Switch P4-16
set  (SWITCH_P4_16 ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/switch_16/p4src/switch-tofino/switch.p4)
file (RELATIVE_PATH switch_p4_16_test ${P4C_SOURCE_DIR} ${SWITCH_P4_16})
p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} FALSE
  "switch_p4_16" ${switch_p4_16_test} "${testExtraArgs} -tofino -arch tna" "")
#p4c_add_test_with_args ("tofino2" ${P4C_RUNTEST} FALSE
#  "switch_p4_16" ${switch_p4_16_test} "${testExtraArgs} -tofino2 -arch t2na" "")

# Switch master MSDC_PROFILE tests
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_msdc" ${SWITCH_P4}
    "${testExtraArgs} -DMSDC_PROFILE -DP4_WRED_DEBUG -pd -to 12000" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_msdc"
        "switch_hostif.HostIfRxTxTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_msdc_set_1" ${SWITCH_P4}
    "${testExtraArgs} -DMSDC_PROFILE -DP4_WRED_DEBUG -pd -to 12000" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_msdc_set_1"
        "switch_hostif.HostIfLagRxTxTest
        switch_mirror.MirrorPortTest
        switch_tests.CpuTxTest
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
        switch_tests.L2StaticMacMoveBulkTest
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
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_msdc_set_8" ${SWITCH_P4}
        "${testExtraArgs} -DMSDC_PROFILE -DP4_WRED_DEBUG -pd -to 12000" "${SWITCH_PTF_DIR_WRED}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_msdc_set_8"
        "switch_wred.WredDropIpv4Test
        switch_wred.WredIpv6Test
        switch_wred.WredLookupTest
        switch_wred.WredStatsTest")

# 500s timeout is too little for compiling and testing the entire switch, bumping it up
set_tests_properties("tofino/smoketest_switch_msdc" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_msdc_set_1" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_msdc_set_2" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_msdc_set_3" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_msdc_set_4" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_msdc_set_5" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_msdc_set_6" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_msdc_set_7" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_msdc_set_8" PROPERTIES TIMEOUT 12000)

# Switch master DC_BASIC_PROFILE tests
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
        "switch_hostif.HostIfLagRxTxTest
        switch_hostif.HostIfPtpTest
        switch_mcast.L3Multicast
        switch_mcast.L3MulticastBidir
        switch_mcast.L3MulticastStatsTest
        switch_mcast.L3MulticastToEcmp
        switch_mirror.MirrorPortTest
        switch_tests.CpuTxTest
        switch_tests.DeviceInfoTest
        switch_tests.ExceptionPacketsTest
        switch_tests.ExceptionPacketsTest_IPV6")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_dc_basic_set_4" ${SWITCH_P4}
        "${testExtraArgs} -DDC_BASIC_PROFILE -pd -to 12000" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_dc_basic_set_4"
        "switch_tests.HostIfTest
        switch_tests.HostIfV6Test
        switch_tests.IPNeighborTest
        switch_tests.IPv4inIPv4Test
        switch_tests.IPv4inIPv6Test
        switch_tests.IPv6inIPv4Test
        switch_tests.IPv6inIPv6Test
        switch_tests.L2AccessToAccessVlanTest
        switch_tests.L2AccessToTrunkPriorityTaggingTest
        switch_tests.L2AccessToTrunkVlanJumboTest
        switch_tests.L2AccessToTrunkVlanTest
        switch_tests.L2AgingTest
        switch_tests.L2DynamicLearnAgeTest
        switch_tests.L2DynamicMacLearnTest
        switch_tests.L2DynamicMacMoveTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_dc_basic_set_5" ${SWITCH_P4}
        "${testExtraArgs} -DDC_BASIC_PROFILE -pd -to 12000" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_dc_basic_set_5"
        "switch_tests.L2FloodTest
        switch_tests.L2GeneveUnicastBasicTest
        switch_tests.L2GeneveUnicastLagBasicTest
        switch_tests.L2IPv4InIPv6VxlanUnicastBasicTest
        switch_tests.L2LagFloodTest
        switch_tests.L2LagTest
        switch_tests.L2LNStatsTest
        switch_tests.L2LNSubIntfEncapTest
        switch_tests.L2MacLearnTest
        switch_tests.L2MplsPopTest
        switch_tests.L2MplsPushJumboTest
        switch_tests.L2MplsPushTest
        switch_tests.L2MplsSwapTest
        switch_tests.L2NvgreUnicastLagBasicTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_dc_basic_set_6" ${SWITCH_P4}
        "${testExtraArgs} -DDC_BASIC_PROFILE -pd -to 12000" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_dc_basic_set_6"
        "switch_tests.L2StaticMacBulkDeleteTest
        switch_tests.L2StaticMacMoveBulkTest
        switch_tests.L2StaticMacMoveTest
        switch_tests.L2StpEgressBlockingTest
        switch_tests.L2StpTest
        switch_tests.L2TrunkToAccessVlanTest
        switch_tests.L2TrunkToTrunkVlanTest
        switch_tests.L2TunnelFloodEnhancedTest
        switch_tests.L2TunnelSplicingExtreme1Test
        switch_tests.L2TunnelSplicingExtreme2Test
        switch_tests.L2VlanStatsTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_dc_basic_set_7" ${SWITCH_P4}
        "${testExtraArgs} -DDC_BASIC_PROFILE -pd -to 12000" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_dc_basic_set_7"
        "switch_tests.L2VxlanArpUnicastBasicTest
        switch_tests.L2VxlanFloodBasicTest
        switch_tests.L2VxlanLearnBasicTest
        switch_tests.L2VxlanToGeneveUnicastBasicTest
        switch_tests.L2VxlanToGeneveUnicastEnhancedTest
        switch_tests.L2VxlanToGeneveUnicastLagBasicTest
        switch_tests.L2VxlanToGeneveUnicastLagEnhancedTest
        switch_tests.L2VxlanUnicastBasicTest
        switch_tests.L2VxlanUnicastLagBasicTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_dc_basic_set_8" ${SWITCH_P4}
        "${testExtraArgs} -DDC_BASIC_PROFILE -pd -to 12000" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_dc_basic_set_8"
        "switch_tests.L3EcmpLagTest
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
        switch_tests.L3IPv6LagTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_dc_basic_set_9" ${SWITCH_P4}
        "${testExtraArgs} -DDC_BASIC_PROFILE -pd -to 12000" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_dc_basic_set_9"
        "switch_tests.L3IPv6LookupTest
        switch_tests.L3IPv6LpmEcmpTest
        switch_tests.L3IPv6LpmTest
        switch_tests.L3MplsPopTest
        switch_tests.L3MplsPushTest
        switch_tests.L3RpfTest
        switch_tests.L3VIFloodTest
        switch_tests.L3VIIPv4HostFloodTest
        switch_tests.L3VIIPv4HostMacMoveTest
        switch_tests.L3VIIPv4HostTest
        switch_tests.L3VIIPv4HostVlanTaggingTest
        switch_tests.L3VIIPv4LagTest
        switch_tests.L3VIIPv6HostTest
        switch_tests.L3VINhopGleanBGPTest
        switch_tests.L3VINhopGleanTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_dc_basic_set_10" ${SWITCH_P4}
        "${testExtraArgs} -DDC_BASIC_PROFILE -pd -to 12000" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_dc_basic_set_10"
        "switch_tunnel.L3VxlanUnicastMultiTunnelSMTest
        switch_tunnel.L3VxlanUnicastTunnelECMPLagReflectionSMTest
        switch_tunnel.L3VxlanUnicastTunnelECMPSMTest
        switch_tunnel.L3VxlanUnicastTunnelSMSVITest
        switch_tunnel.L3VxlanUnicastTunnelSMTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_dc_basic_MalformedPacketsTest" ${SWITCH_P4}
        "${testExtraArgs} -DDC_BASIC_PROFILE -pd -to 12000" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_dc_basic_MalformedPacketsTest"
        "switch_tests.MalformedPacketsTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_dc_basic_MalformedPacketsTest_ipv6" ${SWITCH_P4}
        "${testExtraArgs} -DDC_BASIC_PROFILE -pd -to 12000" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_dc_basic_MalformedPacketsTest_ipv6"
        "switch_tests.MalformedPacketsTest_ipv6")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_dc_basic_MalformedPacketsTest_tunnel" ${SWITCH_P4}
        "${testExtraArgs} -DDC_BASIC_PROFILE -pd -to 12000" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_dc_basic_MalformedPacketsTest_tunnel"
        "switch_tests.MalformedPacketsTest_tunnel")

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
set_tests_properties("tofino/smoketest_switch_dc_basic_set_10" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_dc_basic_MalformedPacketsTest" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_dc_basic_MalformedPacketsTest_ipv6" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_dc_basic_MalformedPacketsTest_tunnel" PROPERTIES TIMEOUT 12000)

# Switch master ENT_DC_GENERAL_PROFILE tests
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_ent_dc_general" ${SWITCH_P4}
        "${testExtraArgs} -DENT_DC_GENERAL_PROFILE -pd -to 12000" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_ent_dc_general"
        "switch_mirror.MirrorPortTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_ent_dc_general_set_1" ${SWITCH_P4}
        "${testExtraArgs} -DENT_DC_GENERAL_PROFILE -pd -to 12000" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_ent_dc_general_set_1"
        "switch_tests.L2AccessToAccessVlanTest
        switch_tests.L2AccessToTrunkPriorityTaggingTest
        switch_tests.L2AccessToTrunkVlanJumboTest
        switch_tests.L2AccessToTrunkVlanTest
        switch_tests.L2AgingTest
        switch_tests.L2DynamicLearnAgeTest
        switch_tests.L2DynamicMacLearnTest
        switch_tests.L2DynamicMacMoveTest
        switch_tests.L2FloodTest
        switch_tests.L2LagFloodTest
        switch_tests.L2LagTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_ent_dc_general_set_2" ${SWITCH_P4}
        "${testExtraArgs} -DENT_DC_GENERAL_PROFILE -pd -to 12000" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_ent_dc_general_set_2"
        "switch_tests.L2LNStatsTest
        switch_tests.L2LNSubIntfEncapTest
        switch_tests.L2MacLearnTest
        switch_tests.L2StaticMacBulkDeleteTest
        switch_tests.L2StaticMacMoveBulkTest
        switch_tests.L2StaticMacMoveTest
        switch_tests.L2StpEgressBlockingTest
        switch_tests.L2StpTest
        switch_tests.L2TrunkToAccessVlanTest
        switch_tests.L2TrunkToTrunkVlanTest
        switch_tests.L2VlanStatsTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_ent_dc_general_set_3" ${SWITCH_P4}
        "${testExtraArgs} -DENT_DC_GENERAL_PROFILE -pd -to 12000" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_ent_dc_general_set_3"
        "switch_tests.L2VxlanArpUnicastBasicTest
        switch_tests.L2VxlanFloodBasicTest
        switch_tests.L2VxlanLearnBasicTest
        switch_tests.L2VxlanUnicastBasicTest
        switch_tests.L2VxlanUnicastLagBasicTest
        switch_tests.L3IPv4EcmpTest
        switch_tests.L3IPv4HostJumboTest
        switch_tests.L3IPv4HostModifyTest
        switch_tests.L3IPv4HostTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_ent_dc_general_set_4" ${SWITCH_P4}
        "${testExtraArgs} -DENT_DC_GENERAL_PROFILE -pd -to 12000" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_ent_dc_general_set_4"
        "switch_tests.L3IPv4LagTest
        switch_tests.L3IPv4LookupTest
        switch_tests.L3IPv4LpmTest
        switch_tests.L3IPv4SubIntfHostTest
        switch_tests.L3IPv6EcmpTest
        switch_tests.L3IPv6HostTest
        switch_tests.L3IPv6LagTest
        switch_tests.L3IPv6LookupTest
        switch_tests.L3IPv6LpmTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_ent_dc_general_set_5" ${SWITCH_P4}
        "${testExtraArgs} -DENT_DC_GENERAL_PROFILE -pd -to 12000" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_ent_dc_general_set_5"
        "switch_tests.L3VIFloodTest
        switch_tests.L3VIIPv4HostFloodTest
        switch_tests.L3VIIPv4HostMacMoveTest
        switch_tests.L3VIIPv4HostTest
        switch_tests.L3VIIPv4HostVlanTaggingTest
        switch_tests.L3VIIPv4LagTest
        switch_tests.L3VIIPv6HostTest
        switch_tunnel.L3VxlanUnicastTunnelECMPLagReflectionSMTest
        switch_tunnel.L3VxlanUnicastTunnelSMSVITest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_ent_dc_general_set_6" ${SWITCH_P4}
        "${testExtraArgs} -DENT_DC_GENERAL_PROFILE -pd -to 12000" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_ent_dc_general_set_6"
        "switch_acl.AclLabelTest
        switch_acl.IPAclStatsTest
        switch_acl.IPAclTest
        switch_acl.IPIngressAclRangeTcamTest
        switch_acl.MirrorAclTest_i2e
        switch_acl.MirrorSessionTest
        switch_tests.L3IPv6LpmEcmpTest
        switch_tests.L3EcmpLagTest
        switch_tests.L3IPv4LpmEcmpTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_ent_dc_general_set_7" ${SWITCH_P4}
        "${testExtraArgs} -DENT_DC_GENERAL_PROFILE -pd -to 12000" "${SWITCH_PTF_DIR_EGRESS_ACL}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_ent_dc_general_set_7"
        "switch_api_tests.IPEgressAclRangeTcamTest
        switch_api_tests.IPEgressAclTest")

# 500s timeout is too little for compiling and testing the entire switch, bumping it up
set_tests_properties("tofino/smoketest_switch_ent_dc_general" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_ent_dc_general_set_1" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_ent_dc_general_set_2" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_ent_dc_general_set_3" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_ent_dc_general_set_4" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_ent_dc_general_set_5" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_ent_dc_general_set_6" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_ent_dc_general_set_7" PROPERTIES TIMEOUT 12000)

# Switch Rel 8.4 MSDC_PROFILE tests
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.4_msdc" ${SWITCH_8.4_P4}
    "${testExtraArgs} -DMSDC_PROFILE -DP4_WRED_DEBUG -pd -to 12000" "${SWITCH_8.4_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.4_msdc"
        "switch_acl.AclLabelTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.4_msdc_set_1" ${SWITCH_8.4_P4}
    "${testExtraArgs} -DMSDC_PROFILE -DP4_WRED_DEBUG -pd -to 12000" "${SWITCH_8.4_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.4_msdc_set_1"
        "switch_acl.Acl_i2e_ErspanRewriteTest
        switch_acl.IPAclStatsTest
        switch_acl.IPAclTest
        switch_acl.IPIngressAclRangeTcamTest
        switch_acl.MirrorAclTest_e2e
        switch_acl.MirrorAclTest_i2e
        switch_acl.MirrorSessionTest
        switch_hostif.HostIfLagRxTxTest
        switch_hostif.HostIfRxTxTest
        switch_mirror.MirrorPortTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.4_msdc_set_2" ${SWITCH_8.4_P4}
    "${testExtraArgs} -DMSDC_PROFILE -DP4_WRED_DEBUG -pd -to 12000" "${SWITCH_8.4_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.4_msdc_set_2"
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
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.4_msdc_set_3" ${SWITCH_8.4_P4}
    "${testExtraArgs} -DMSDC_PROFILE -DP4_WRED_DEBUG -pd -to 12000" "${SWITCH_8.4_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.4_msdc_set_3"
        "switch_tests.L2DynamicLearnAgeTest
        switch_tests.L2DynamicMacLearnTest
        switch_tests.L2DynamicMacMoveTest
        switch_tests.L2FloodTest
        switch_tests.L2LNStatsTest
        switch_tests.L2LagTest
        switch_tests.L2MacLearnTest
        switch_tests.L2StaticMacBulkDeleteTest
        switch_tests.L2StaticMacMoveBulkTest
        switch_tests.L2StaticMacMoveTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.4_msdc_set_4" ${SWITCH_8.4_P4}
    "${testExtraArgs} -DMSDC_PROFILE -DP4_WRED_DEBUG -pd -to 12000" "${SWITCH_8.4_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.4_msdc_set_4"
        "switch_tests.L2TrunkToAccessVlanTest
        switch_tests.L2TrunkToTrunkVlanTest
        switch_tests.L2VlanStatsTest
        switch_tests.L3EcmpLagTest
        switch_tests.L3IPv4EcmpTest
        switch_tests.L3IPv4HostJumboTest
        switch_tests.L3IPv4HostModifyTest
        switch_tests.L3IPv4HostTest
        switch_tests.L3IPv4LagTest
        switch_tests.L3IPv4LookupTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.4_msdc_set_5" ${SWITCH_8.4_P4}
    "${testExtraArgs} -DMSDC_PROFILE -DP4_WRED_DEBUG -pd -to 12000" "${SWITCH_8.4_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.4_msdc_set_5"
        "switch_tests.L3IPv4LpmEcmpTest
        switch_tests.L3IPv4LpmTest
        switch_tests.L3IPv4MtuTest
        switch_tests.L3IPv4SubIntfHostTest
        switch_tests.L3IPv6EcmpTest
        switch_tests.L3IPv6HostTest
        switch_tests.L3IPv6LagTest
        switch_tests.L3IPv6LookupTest
        switch_tests.L3IPv6LpmEcmpTest
        switch_tests.L3IPv6LpmTest
        switch_tests.L3VIFloodTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.4_msdc_set_6" ${SWITCH_8.4_P4}
    "${testExtraArgs} -DMSDC_PROFILE -DP4_WRED_DEBUG -pd -to 12000" "${SWITCH_8.4_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.4_msdc_set_6"
        "switch_tests.L3VIIPv4HostFloodTest
        switch_tests.L3VIIPv4HostMacMoveTest
        switch_tests.L3VIIPv4HostTest
        switch_tests.L3VIIPv4HostVlanTaggingTest
        switch_tests.L3VIIPv4LagTest
        switch_tests.L3VIIPv6HostTest
        switch_tests.L3VINhopGleanTest
        switch_tests.MalformedPacketsTest
        switch_tests.MalformedPacketsTest_ipv6")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.4_msdc_set_7" ${SWITCH_8.4_P4}
        "${testExtraArgs} -DMSDC_PROFILE -DP4_WRED_DEBUG -pd -to 12000" "${SWITCH_8.4_PTF_DIR_MIRROR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.4_msdc_set_7"
        "mirror_acl_slice_tests.IPv6MirrorAclSliceTest_i2e
        mirror_acl_slice_tests.MirrorAclSliceTest_i2e")

# 500s timeout is too little for compiling and testing the entire switch, bumping it up
set_tests_properties("tofino/smoketest_switch_8.4_msdc" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_8.4_msdc_set_1" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_8.4_msdc_set_2" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_8.4_msdc_set_3" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_8.4_msdc_set_4" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_8.4_msdc_set_5" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_8.4_msdc_set_6" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_8.4_msdc_set_7" PROPERTIES TIMEOUT 12000)

# Switch Rel 8.4 ENT_DC_GENERAL_PROFILE tests
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.4_ent_dc_general" ${SWITCH_8.4_P4}
    "${testExtraArgs} -DENT_DC_GENERAL_PROFILE -pd -to 12000" "${SWITCH_8.4_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.4_ent_dc_general"
        "switch_acl.AclLabelTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.4_ent_dc_general_set_1" ${SWITCH_8.4_P4}
    "${testExtraArgs} -DENT_DC_GENERAL_PROFILE -pd -to 12000" "${SWITCH_8.4_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.4_ent_dc_general_set_1"
        "switch_acl.IPAclStatsTest
        switch_acl.IPAclTest
        switch_acl.IPIngressAclRangeTcamTest
        switch_acl.MirrorAclTest_i2e
        switch_acl.MirrorSessionTest
        switch_mirror.MirrorPortTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.4_ent_dc_general_set_2" ${SWITCH_8.4_P4}
    "${testExtraArgs} -DENT_DC_GENERAL_PROFILE -pd -to 12000" "${SWITCH_8.4_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.4_ent_dc_general_set_2"
        "switch_tests.L2AccessToAccessVlanTest
        switch_tests.L2AccessToTrunkPriorityTaggingTest
        switch_tests.L2AccessToTrunkVlanJumboTest
        switch_tests.L2AccessToTrunkVlanTest
        switch_tests.L2AgingTest
        switch_tests.L2DynamicLearnAgeTest
        switch_tests.L2DynamicMacLearnTest
        switch_tests.L2DynamicMacMoveTest
        switch_tests.L2FloodTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.4_ent_dc_general_set_3" ${SWITCH_8.4_P4}
    "${testExtraArgs} -DENT_DC_GENERAL_PROFILE -pd -to 12000" "${SWITCH_8.4_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.4_ent_dc_general_set_3"
        "switch_tests.L2LNStatsTest
        switch_tests.L2LNSubIntfEncapTest
        switch_tests.L2LagFloodTest
        switch_tests.L2LagTest
        switch_tests.L2MacLearnTest
        switch_tests.L2StaticMacBulkDeleteTest
        switch_tests.L2StaticMacMoveBulkTest
        switch_tests.L2StaticMacMoveTest
        switch_tests.L2StpEgressBlockingTest
        switch_tests.L2StpTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.4_ent_dc_general_set_4" ${SWITCH_8.4_P4}
    "${testExtraArgs} -DENT_DC_GENERAL_PROFILE -pd -to 12000" "${SWITCH_8.4_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.4_ent_dc_general_set_4"
        "switch_tests.L2TrunkToAccessVlanTest
        switch_tests.L2TrunkToTrunkVlanTest
        switch_tests.L2VlanStatsTest
        switch_tests.L2VxlanArpUnicastBasicTest
        switch_tests.L2VxlanFloodBasicTest
        switch_tests.L2VxlanLearnBasicTest
        switch_tests.L2VxlanUnicastBasicTest
        switch_tests.L2VxlanUnicastLagBasicTest
        switch_tests.L3IPv4EcmpTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.4_ent_dc_general_set_5" ${SWITCH_8.4_P4}
    "${testExtraArgs} -DENT_DC_GENERAL_PROFILE -pd -to 12000" "${SWITCH_8.4_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.4_ent_dc_general_set_5"
        "switch_tests.L3IPv4HostJumboTest
        switch_tests.L3IPv4HostModifyTest
        switch_tests.L3IPv4HostTest
        switch_tests.L3IPv4LagTest
        switch_tests.L3IPv4LookupTest
        switch_tests.L3IPv4LpmTest
        switch_tests.L3IPv4SubIntfHostTest
        switch_tests.L3IPv6EcmpTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.4_ent_dc_general_set_6" ${SWITCH_8.4_P4}
    "${testExtraArgs} -DENT_DC_GENERAL_PROFILE -pd -to 12000" "${SWITCH_8.4_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.4_ent_dc_general_set_6"
        "switch_tests.L3IPv6HostTest
        switch_tests.L3IPv6LagTest
        switch_tests.L3IPv6LookupTest
        switch_tests.L3IPv6LpmTest
        switch_tests.L3VIFloodTest
        switch_tests.L3VIIPv4HostFloodTest
        switch_tests.L3VIIPv4HostMacMoveTest
        switch_tests.L3VIIPv4HostTest
        switch_tests.L3VIIPv4HostVlanTaggingTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.4_ent_dc_general_set_7" ${SWITCH_8.4_P4}
    "${testExtraArgs} -DENT_DC_GENERAL_PROFILE -pd -to 12000" "${SWITCH_8.4_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.4_ent_dc_general_set_7"
        "switch_tests.L3VIIPv4LagTest
        switch_tests.L3VIIPv6HostTest
        switch_tunnel.L3VxlanUnicastTunnelECMPLagReflectionSMTest
        switch_tunnel.L3VxlanUnicastTunnelSMSVITest
        switch_tests.L3EcmpLagTest
        switch_tests.L3IPv4LpmEcmpTest
        switch_tests.L3IPv6LpmEcmpTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.4_ent_dc_general_set_8" ${SWITCH_8.4_P4}
    "${testExtraArgs} -DENT_DC_GENERAL_PROFILE -pd -to 12000" "${SWITCH_8.4_PTF_DIR_EGRESS_ACL}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.4_ent_dc_general_set_8"
        "switch_api_tests.IPEgressAclRangeTcamTest
        switch_api_tests.IPEgressAclTest")
# 500s timeout is too little for compiling and testing the entire switch, bumping it up
set_tests_properties("tofino/smoketest_switch_8.4_ent_dc_general" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_8.4_ent_dc_general_set_1" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_8.4_ent_dc_general_set_2" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_8.4_ent_dc_general_set_3" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_8.4_ent_dc_general_set_4" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_8.4_ent_dc_general_set_5" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_8.4_ent_dc_general_set_6" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_8.4_ent_dc_general_set_7" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_8.4_ent_dc_general_set_8" PROPERTIES TIMEOUT 12000)

# Switch Rel 8.4 MSDC_L3_PROFILE_BRIG tests
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.4_l3_msdc" ${SWITCH_8.4_P4}
    "${testExtraArgs} -DMSDC_L3_PROFILE -DP4_WRED_DEBUG -pd -to 12000" "${SWITCH_8.4_PTF_DIR}")
bfn_set_p4_build_flag("tofino" "smoketest_switch_8.4_l3_msdc"
    "-Xp4c=\"--disable-power-check\"")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.4_l3_msdc"
        "switch_acl.AclLabelTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.4_l3_msdc_set_1" ${SWITCH_8.4_P4}
    "${testExtraArgs} -DMSDC_L3_PROFILE -DP4_WRED_DEBUG -pd -to 12000" "${SWITCH_8.4_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.4_l3_msdc_set_1"
        "switch_acl.Acl_i2e_ErspanRewriteTest
        switch_acl.IPAclStatsTest
        switch_acl.IPAclTest
        switch_acl.IPIngressAclRangeTcamTest
        switch_acl.MirrorAclTest_e2e
        switch_acl.MirrorAclTest_i2e
        switch_acl.MirrorSessionTest
        switch_hostif.HostIfLagRxTxTest
        switch_hostif.HostIfRxTxTest
        switch_mirror.MirrorPortTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.4_l3_msdc_set_2" ${SWITCH_8.4_P4}
    "${testExtraArgs} -DMSDC_L3_PROFILE -DP4_WRED_DEBUG -pd -to 12000" "${SWITCH_8.4_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.4_l3_msdc_set_2"
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
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.4_l3_msdc_set_3" ${SWITCH_8.4_P4}
    "${testExtraArgs} -DMSDC_L3_PROFILE -DP4_WRED_DEBUG -pd -to 12000" "${SWITCH_8.4_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.4_l3_msdc_set_3"
        "switch_tests.L2DynamicLearnAgeTest
        switch_tests.L2DynamicMacLearnTest
        switch_tests.L2DynamicMacMoveTest
        switch_tests.L2FloodTest
        switch_tests.L2LNStatsTest
        switch_tests.L2LagTest
        switch_tests.L2MacLearnTest
        switch_tests.L2StaticMacBulkDeleteTest
        switch_tests.L2StaticMacMoveBulkTest
        switch_tests.L2StaticMacMoveTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.4_l3_msdc_set_4" ${SWITCH_8.4_P4}
    "${testExtraArgs} -DMSDC_L3_PROFILE -DP4_WRED_DEBUG -pd -to 12000" "${SWITCH_8.4_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.4_l3_msdc_set_4"
        "switch_tests.L2TrunkToAccessVlanTest
        switch_tests.L2TrunkToTrunkVlanTest
        switch_tests.L2VlanStatsTest
        switch_tests.L3EcmpLagTest
        switch_tests.L3IPv4EcmpTest
        switch_tests.L3IPv4HostJumboTest
        switch_tests.L3IPv4HostModifyTest
        switch_tests.L3IPv4HostTest
        switch_tests.L3IPv4LagTest
        switch_tests.L3IPv4LookupTest
        switch_tests.L3IPv4LpmEcmpTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.4_l3_msdc_set_5" ${SWITCH_8.4_P4}
    "${testExtraArgs} -DMSDC_L3_PROFILE -DP4_WRED_DEBUG -pd -to 12000" "${SWITCH_8.4_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.4_l3_msdc_set_5"
        "switch_tests.L3IPv4LpmTest
        switch_tests.L3IPv4MtuTest
        switch_tests.L3IPv4SubIntfHostTest
        switch_tests.L3IPv6EcmpTest
        switch_tests.L3IPv6HostTest
        switch_tests.L3IPv6LagTest
        switch_tests.L3IPv6LookupTest
        switch_tests.L3IPv6LpmEcmpTest
        switch_tests.L3IPv6LpmTest
        switch_tests.L3VIFloodTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.4_l3_msdc_set_6" ${SWITCH_8.4_P4}
    "${testExtraArgs} -DMSDC_L3_PROFILE -DP4_WRED_DEBUG -pd -to 12000" "${SWITCH_8.4_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.4_l3_msdc_set_6"
        "switch_tests.L3VIIPv4HostFloodTest
        switch_tests.L3VIIPv4HostMacMoveTest
        switch_tests.L3VIIPv4HostTest
        switch_tests.L3VIIPv4HostVlanTaggingTest
        switch_tests.L3VIIPv4LagTest
        switch_tests.L3VIIPv6HostTest
        switch_tests.L3VINhopGleanTest
        switch_tests.MalformedPacketsTest
        switch_tests.MalformedPacketsTest_ipv6")

# 500s timeout is too little for compiling and testing the entire switch, bumping it up
set_tests_properties("tofino/smoketest_switch_8.4_l3_msdc" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_8.4_l3_msdc_set_1" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_8.4_l3_msdc_set_2" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_8.4_l3_msdc_set_3" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_8.4_l3_msdc_set_4" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_8.4_l3_msdc_set_5" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_8.4_l3_msdc_set_6" PROPERTIES TIMEOUT 12000)

# Switch Rel 8.4 DC_BASIC_PROFILE_BRIG tests
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.4_dc_basic" ${SWITCH_8.4_P4}
    "${testExtraArgs} -DDC_BASIC_PROFILE -pd -to 12000" "${SWITCH_8.4_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.4_dc_basic"
        "switch_acl.AclLabelTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.4_dc_basic_set_1" ${SWITCH_8.4_P4}
    "${testExtraArgs} -DDC_BASIC_PROFILE -pd -to 12000" "${SWITCH_8.4_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.4_dc_basic_set_1"
        "switch_acl.Acl_i2e_ErspanRewriteTest
        switch_acl.IPAclStatsTest
        switch_acl.IPAclTest
        switch_acl.IPIngressAclRangeTcamTest
        switch_acl.IPv6RAclTest
        switch_acl.MirrorAclTest_e2e
        switch_acl.MirrorAclTest_i2e
        switch_acl.MirrorSessionTest
        switch_get.AclGetTest
        switch_get.BufferGetTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.4_dc_basic_set_2" ${SWITCH_8.4_P4}
    "${testExtraArgs} -DDC_BASIC_PROFILE -pd -to 12000" "${SWITCH_8.4_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.4_dc_basic_set_2"
        "switch_get.DeviceGetTest
        switch_get.HostIfGetTest
        switch_get.InterfaceGetTest
        switch_get.L2GetTest
        switch_get.LagGetTest
        switch_get.MirrorGetTest
        switch_get.MtreeGetTest
        switch_get.NhopGetTest
        switch_get.PortGetTest
        switch_get.QosGetTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.4_dc_basic_set_3" ${SWITCH_8.4_P4}
    "${testExtraArgs} -DDC_BASIC_PROFILE -pd -to 12000" "${SWITCH_8.4_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.4_dc_basic_set_3"
        "switch_get.RifGetTest
        switch_get.VlanGetTest
        switch_get.VrfRmacGetTest
        switch_hostif.HostIfLagRxTxTest
        switch_hostif.HostIfPtpTest
        switch_hostif.HostIfRxTxTest
        switch_mcast.L3MulticastStatsTest
        switch_mirror.MirrorPortTest
        switch_tests.CpuTxTest
        switch_tests.DeviceInfoTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.4_dc_basic_set_4" ${SWITCH_8.4_P4}
    "${testExtraArgs} -DDC_BASIC_PROFILE -pd -to 12000" "${SWITCH_8.4_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.4_dc_basic_set_4"
        "switch_tests.ExceptionPacketsTest
        switch_tests.ExceptionPacketsTest_IPV6
        switch_tests.HostIfTest
        switch_tests.HostIfV6Test
        switch_tests.IPNeighborTest
        switch_tests.IPv4inIPv4Test
        switch_tests.IPv4inIPv6Test
        switch_tests.IPv6inIPv4Test
        switch_tests.IPv6inIPv6Test")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.4_dc_basic_set_5" ${SWITCH_8.4_P4}
    "${testExtraArgs} -DDC_BASIC_PROFILE -pd -to 12000" "${SWITCH_8.4_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.4_dc_basic_set_5"
        "switch_tests.L2AccessToAccessVlanTest
        switch_tests.L2AccessToTrunkPriorityTaggingTest
        switch_tests.L2AccessToTrunkVlanJumboTest
        switch_tests.L2AccessToTrunkVlanTest
        switch_tests.L2AgingTest
        switch_tests.L2DynamicLearnAgeTest
        switch_tests.L2DynamicMacLearnTest
        switch_tests.L2DynamicMacMoveTest
        switch_tests.L2FloodTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.4_dc_basic_set_6" ${SWITCH_8.4_P4}
    "${testExtraArgs} -DDC_BASIC_PROFILE -pd -to 12000" "${SWITCH_8.4_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.4_dc_basic_set_6"
        "switch_tests.L2GeneveUnicastBasicTest
        switch_tests.L2GeneveUnicastLagBasicTest
        switch_tests.L2IPv4InIPv6VxlanUnicastBasicTest
        switch_tests.L2LNStatsTest
        switch_tests.L2LNSubIntfEncapTest
        switch_tests.L2LagFloodTest
        switch_tests.L2LagTest
        switch_tests.L2MacLearnTest
        switch_tests.L2MplsPopTest
        switch_tests.L2MplsPushJumboTest
        switch_tests.L2MplsPushTest
        switch_tests.L2MplsSwapTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.4_dc_basic_set_7" ${SWITCH_8.4_P4}
    "${testExtraArgs} -DDC_BASIC_PROFILE -pd -to 12000" "${SWITCH_8.4_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.4_dc_basic_set_7"
        "switch_tests.L2NvgreUnicastLagBasicTest
        switch_tests.L2StaticMacBulkDeleteTest
        switch_tests.L2StaticMacMoveBulkTest
        switch_tests.L2StaticMacMoveTest
        switch_tests.L2StpEgressBlockingTest
        switch_tests.L2StpTest
        switch_tests.L2TrunkToAccessVlanTest
        switch_tests.L2TrunkToTrunkVlanTest
        switch_tests.L2TunnelFloodEnhancedTest
        switch_tests.L2TunnelSplicingExtreme1Test
        switch_tests.L2TunnelSplicingExtreme2Test")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.4_dc_basic_set_8" ${SWITCH_8.4_P4}
    "${testExtraArgs} -DDC_BASIC_PROFILE -pd -to 12000" "${SWITCH_8.4_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.4_dc_basic_set_8"
        "switch_tests.L2VlanStatsTest
        switch_tests.L2VxlanArpUnicastBasicTest
        switch_tests.L2VxlanFloodBasicTest
        switch_tests.L2VxlanLearnBasicTest
        switch_tests.L2VxlanToGeneveUnicastBasicTest
        switch_tests.L2VxlanToGeneveUnicastEnhancedTest
        switch_tests.L2VxlanToGeneveUnicastLagBasicTest
        switch_tests.L2VxlanToGeneveUnicastLagEnhancedTest
        switch_tests.L2VxlanUnicastBasicTest
        switch_tests.L2VxlanUnicastLagBasicTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.4_dc_basic_set_9" ${SWITCH_8.4_P4}
    "${testExtraArgs} -DDC_BASIC_PROFILE -pd -to 12000" "${SWITCH_8.4_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.4_dc_basic_set_9"
        "switch_tests.L3EcmpLagTest
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
        switch_tests.L3IPv6EcmpTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.4_dc_basic_set_10" ${SWITCH_8.4_P4}
    "${testExtraArgs} -DDC_BASIC_PROFILE -pd -to 12000" "${SWITCH_8.4_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.4_dc_basic_set_10"
        "switch_tests.L3IPv6HostTest
        switch_tests.L3IPv6LagTest
        switch_tests.L3IPv6LookupTest
        switch_tests.L3IPv6LpmEcmpTest
        switch_tests.L3IPv6LpmTest
        switch_tests.L3MplsPopTest
        switch_tests.L3MplsPushTest
        switch_tests.L3RpfTest
        switch_tests.L3VIFloodTest
        switch_tests.L3VIIPv4HostFloodTest
        switch_tests.L3VIIPv4HostMacMoveTest
        switch_tests.L3VIIPv4HostTest
        switch_tests.L3VIIPv4HostVlanTaggingTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.4_dc_basic_set_11" ${SWITCH_8.4_P4}
    "${testExtraArgs} -DDC_BASIC_PROFILE -pd -to 12000" "${SWITCH_8.4_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.4_dc_basic_set_11"
        "switch_tests.L3VIIPv4LagTest
        switch_tests.L3VIIPv6HostTest
        switch_tests.L3VINhopGleanBGPTest
        switch_tests.L3VINhopGleanTest
        switch_tunnel.L3VxlanUnicastMultiTunnelSMTest
        switch_tunnel.L3VxlanUnicastTunnelECMPLagReflectionSMTest
        switch_tunnel.L3VxlanUnicastTunnelECMPSMTest
        switch_tunnel.L3VxlanUnicastTunnelSMSVITest
        switch_tunnel.L3VxlanUnicastTunnelSMTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.4_dc_basic_MalformedPacketsTest" ${SWITCH_8.4_P4}
    "${testExtraArgs} -DDC_BASIC_PROFILE -pd -to 12000" "${SWITCH_8.4_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.4_dc_basic_MalformedPacketsTest"
        "switch_tests.MalformedPacketsTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.4_dc_basic_MalformedPacketsTest_ipv6" ${SWITCH_8.4_P4}
    "${testExtraArgs} -DDC_BASIC_PROFILE -pd -to 12000" "${SWITCH_8.4_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.4_dc_basic_MalformedPacketsTest_ipv6"
        "switch_tests.MalformedPacketsTest_ipv6")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.4_dc_basic_MalformedPacketsTest_tunnel" ${SWITCH_8.4_P4}
    "${testExtraArgs} -DDC_BASIC_PROFILE -pd -to 12000" "${SWITCH_8.4_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.4_dc_basic_MalformedPacketsTest_tunnel"
        "switch_tests.MalformedPacketsTest_tunnel")

# 500s timeout is too little for compiling and testing the entire switch, bumping it up
set_tests_properties("tofino/smoketest_switch_8.4_dc_basic" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_8.4_dc_basic_set_1" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_8.4_dc_basic_set_2" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_8.4_dc_basic_set_3" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_8.4_dc_basic_set_4" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_8.4_dc_basic_set_5" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_8.4_dc_basic_set_6" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_8.4_dc_basic_set_7" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_8.4_dc_basic_set_8" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_8.4_dc_basic_set_9" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_8.4_dc_basic_set_10" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_8.4_dc_basic_set_11" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_8.4_dc_basic_MalformedPacketsTest" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_8.4_dc_basic_MalformedPacketsTest_ipv6" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_8.4_dc_basic_MalformedPacketsTest_tunnel" PROPERTIES TIMEOUT 12000)

# Switch Rel 8.4 MSDC_SPINE_DTEL_INT_PROFILE tests
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.4_spine_dtel_int" ${SWITCH_8.4_P4}
    "${testExtraArgs} -DMSDC_SPINE_DTEL_INT_PROFILE -pd -to 12000" "${SWITCH_8.4_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.4_spine_dtel_int"
        "all ^dynhash ^tunnel ^mpls ^urpf ^racl ^ipv6 ^mcast ^warminit ^stp ^ptp")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.4_spine_dtel_int_set_1" ${SWITCH_8.4_P4}
    "${testExtraArgs} -DMSDC_SPINE_DTEL_INT_PROFILE -pd -to 12000" "${SWITCH_8.4_PTF_DIR_MIRROR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.4_spine_dtel_int_set_1"
        "mirror_acl_slice_tests.MirrorAclSliceTest_i2e")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.4_spine_dtel_int_set_2" ${SWITCH_8.4_P4}
    "${testExtraArgs} -DMSDC_SPINE_DTEL_INT_PROFILE -pd -to 12000" "${SWITCH_8.4_PTF_DIR_DTEL}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.4_spine_dtel_int_set_2"
        "switch_int_l45_transit_digest.intl45_transitTest_hop2_with_digest
         switch_int_l45_transit.intl45_transitTest_Metadata
         switch_int_l45_transit.intl45_transitTest_hop2_latency
         switch_int_l45_transit.intl45_transitTest_hop2_port_ids
         switch_int_l45_transit.intl45_DSCP_TransitTest
         switch_int_l45_transit.intl45_transitTest_hop2_txutil_yet_supported")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.4_spine_dtel_int_set_2_part_2" ${SWITCH_8.4_P4}
    "${testExtraArgs} -DMSDC_SPINE_DTEL_INT_PROFILE -pd -to 12000" "${SWITCH_8.4_PTF_DIR_DTEL}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.4_spine_dtel_int_set_2_part_2"
        "switch_int_l45_transit.intl45_transitTest_switchid
         switch_int_l45_transit.intl45_transitTest_hop2_qdepth
         switch_int_l45_transit.intl45_transitTest_latency_shift
         switch_int_l45_transit.intl45_transitTest_Ebit
         switch_int_l45_transit.INTL45_Marker_TransitTest
         switch_mirror_on_drop.MirrorOnDropEgressAclTest
         switch_queue_report.QueueReport_Change_Test")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.4_spine_dtel_int_set_2_intl45_route_dtel_reports" ${SWITCH_8.4_P4}
    "${testExtraArgs} -DMSDC_SPINE_DTEL_INT_PROFILE -pd -to 12000" "${SWITCH_8.4_PTF_DIR_DTEL}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.4_spine_dtel_int_set_2_intl45_route_dtel_reports"
        "switch_int_l45_common.intl45_route_dtel_reports")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.4_spine_dtel_int_set_2_INTL45_TransitTest_Enable" ${SWITCH_8.4_P4}
    "${testExtraArgs} -DMSDC_SPINE_DTEL_INT_PROFILE -pd -to 12000" "${SWITCH_8.4_PTF_DIR_DTEL}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.4_spine_dtel_int_set_2_INTL45_TransitTest_Enable"
        "switch_int_l45_transit.INTL45_TransitTest_Enable")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.4_spine_dtel_int_set_2_intl45_transitTest_hop2_stateless" ${SWITCH_8.4_P4}
    "${testExtraArgs} -DMSDC_SPINE_DTEL_INT_PROFILE -pd -to 12000" "${SWITCH_8.4_PTF_DIR_DTEL}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.4_spine_dtel_int_set_2_intl45_transitTest_hop2_stateless"
        "switch_int_l45_transit_stless.intl45_transitTest_hop2_stateless")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.4_spine_dtel_int_set_2_INTL45_Transit_EgressMoDTest" ${SWITCH_8.4_P4}
    "${testExtraArgs} -DMSDC_SPINE_DTEL_INT_PROFILE -pd -to 12000" "${SWITCH_8.4_PTF_DIR_DTEL}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.4_spine_dtel_int_set_2_INTL45_Transit_EgressMoDTest"
        "switch_int_l45_transit.INTL45_Transit_EgressMoDTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.4_spine_dtel_int_set_2_INTL45_Transit_IngressMoDTest" ${SWITCH_8.4_P4}
    "${testExtraArgs} -DMSDC_SPINE_DTEL_INT_PROFILE -pd -to 12000" "${SWITCH_8.4_PTF_DIR_DTEL}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.4_spine_dtel_int_set_2_INTL45_Transit_IngressMoDTest"
        "switch_int_l45_transit.INTL45_Transit_IngressMoDTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.4_spine_dtel_int_set_2_MirrorOnDropEgrNonDefaultRuleTest" ${SWITCH_8.4_P4}
    "${testExtraArgs} -DMSDC_SPINE_DTEL_INT_PROFILE -pd -to 12000" "${SWITCH_8.4_PTF_DIR_DTEL}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.4_spine_dtel_int_set_2_MirrorOnDropEgrNonDefaultRuleTest"
        "switch_mirror_on_drop.MirrorOnDropEgrNonDefaultRuleTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.4_spine_dtel_int_set_2_MirrorOnDropHostifReasonCodeTest" ${SWITCH_8.4_P4}
    "${testExtraArgs} -DMSDC_SPINE_DTEL_INT_PROFILE -pd -to 12000" "${SWITCH_8.4_PTF_DIR_DTEL}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.4_spine_dtel_int_set_2_MirrorOnDropHostifReasonCodeTest"
        "switch_mirror_on_drop.MirrorOnDropHostifReasonCodeTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.4_spine_dtel_int_set_2_MirrorOnDropIngressAclTest" ${SWITCH_8.4_P4}
    "${testExtraArgs} -DMSDC_SPINE_DTEL_INT_PROFILE -pd -to 12000" "${SWITCH_8.4_PTF_DIR_DTEL}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.4_spine_dtel_int_set_2_MirrorOnDropIngressAclTest"
        "switch_mirror_on_drop.MirrorOnDropIngressAclTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.4_spine_dtel_int_set_2_MirrorOnDropNonDefaultRuleTest" ${SWITCH_8.4_P4}
    "${testExtraArgs} -DMSDC_SPINE_DTEL_INT_PROFILE -pd -to 12000" "${SWITCH_8.4_PTF_DIR_DTEL}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.4_spine_dtel_int_set_2_MirrorOnDropNonDefaultRuleTest"
        "switch_mirror_on_drop.MirrorOnDropNonDefaultRuleTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.4_spine_dtel_int_set_2_QueueReport_Entropy_Test" ${SWITCH_8.4_P4}
    "${testExtraArgs} -DMSDC_SPINE_DTEL_INT_PROFILE -pd -to 12000" "${SWITCH_8.4_PTF_DIR_DTEL}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.4_spine_dtel_int_set_2_QueueReport_Entropy_Test"
        "switch_queue_report.QueueReport_Entropy_Test")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.4_spine_dtel_int_set_2_QueueReport_Quota_Test" ${SWITCH_8.4_P4}
    "${testExtraArgs} -DMSDC_SPINE_DTEL_INT_PROFILE -pd -to 12000" "${SWITCH_8.4_PTF_DIR_DTEL}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.4_spine_dtel_int_set_2_QueueReport_Quota_Test"
        "switch_queue_report.QueueReport_Quota_Test")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.4_spine_dtel_int_set_2_QueueReport_Over_ECMP_Test" ${SWITCH_8.4_P4}
    "${testExtraArgs} -DMSDC_SPINE_DTEL_INT_PROFILE -pd -to 12000" "${SWITCH_8.4_PTF_DIR_DTEL}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.4_spine_dtel_int_set_2_QueueReport_Over_ECMP_Test"
        "switch_queue_report_multimirror.QueueReport_Over_ECMP_Test")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.4_spine_dtel_int_set_2_QueueReport_MirrorTest" ${SWITCH_8.4_P4}
    "${testExtraArgs} -DMSDC_SPINE_DTEL_INT_PROFILE -pd -to 12000" "${SWITCH_8.4_PTF_DIR_DTEL}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.4_spine_dtel_int_set_2_QueueReport_MirrorTest"
        "switch_queue_report_multimirror.QueueReport_MirrorTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.4_spine_dtel_int_set_2_QueueReport_L2_MirrorTest" ${SWITCH_8.4_P4}
    "${testExtraArgs} -DMSDC_SPINE_DTEL_INT_PROFILE -pd -to 12000" "${SWITCH_8.4_PTF_DIR_DTEL}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.4_spine_dtel_int_set_2_QueueReport_L2_MirrorTest"
        "switch_queue_report_multimirror.QueueReport_L2_MirrorTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.4_spine_dtel_int_set_3" ${SWITCH_8.4_P4}
    "${testExtraArgs} -DMSDC_SPINE_DTEL_INT_PROFILE -pd -to 12000" "${SWITCH_8.4_PTF_DIR_DTEL}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.4_spine_dtel_int_set_3"
        "transit_l45_dod
        ^switch_int_l45_transit.INTL45_Transit_DoDTest
        ^switch_mirror_on_drop.MirrorOnDropDoDTest
        ^switch_queue_report.QueueReport_DoD_Test")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.4_spine_dtel_int_set_3_INTL45_Transit_DoDTest" ${SWITCH_8.4_P4}
    "${testExtraArgs} -DMSDC_SPINE_DTEL_INT_PROFILE -pd -to 12000" "${SWITCH_8.4_PTF_DIR_DTEL}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.4_spine_dtel_int_set_3_INTL45_Transit_DoDTest"
        "switch_int_l45_transit.INTL45_Transit_DoDTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.4_spine_dtel_int_set_3_MirrorOnDropDoDTest" ${SWITCH_8.4_P4}
    "${testExtraArgs} -DMSDC_SPINE_DTEL_INT_PROFILE -pd -to 12000" "${SWITCH_8.4_PTF_DIR_DTEL}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.4_spine_dtel_int_set_3_MirrorOnDropDoDTest"
        "switch_mirror_on_drop.MirrorOnDropDoDTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.4_spine_dtel_int_set_3_QueueReport_DoD_Test" ${SWITCH_8.4_P4}
    "${testExtraArgs} -DMSDC_SPINE_DTEL_INT_PROFILE -pd -to 12000" "${SWITCH_8.4_PTF_DIR_DTEL}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.4_spine_dtel_int_set_3_QueueReport_DoD_Test"
        "switch_queue_report.QueueReport_DoD_Test")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.4_spine_dtel_int_set_4" ${SWITCH_8.4_P4}
    "${testExtraArgs} -DMSDC_SPINE_DTEL_INT_PROFILE -pd -to 12000" "${SWITCH_8.4_PTF_DIR_SAI}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.4_spine_dtel_int_set_4"
        "egress-acl mirror-acl")
bfn_set_ptf_port_map_file("tofino" "smoketest_switch_8.4_spine_dtel_int_set_4"
    "${SWITCH_8.4_PTF_DIR_SAI}/port_map.ini")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.4_spine_dtel_int_set_5" ${SWITCH_8.4_P4}
    "${testExtraArgs} -DMSDC_SPINE_DTEL_INT_PROFILE -pd -to 12000" "${SWITCH_8.4_PTF_DIR_SAI_DTEL}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.4_spine_dtel_int_set_5"
        "int_transit
        ^sai_mod.INGRESS_DROP_REPORT_Test")
bfn_set_ptf_port_map_file("tofino" "smoketest_switch_8.4_spine_dtel_int_set_5"
    "${SWITCH_8.4_PTF_DIR_SAI}/port_map.ini")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.4_spine_dtel_int_set_5_INGRESS_DROP_REPORT_Test" ${SWITCH_8.4_P4}
    "${testExtraArgs} -DMSDC_SPINE_DTEL_INT_PROFILE -pd -to 12000" "${SWITCH_8.4_PTF_DIR_SAI_DTEL}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.4_spine_dtel_int_set_5_INGRESS_DROP_REPORT_Test"
        "sai_mod.INGRESS_DROP_REPORT_Test")
bfn_set_ptf_port_map_file("tofino" "smoketest_switch_8.4_spine_dtel_int_set_5_INGRESS_DROP_REPORT_Test"
    "${SWITCH_8.4_PTF_DIR_SAI}/port_map.ini")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_8.4_spine_dtel_int_set_6" ${SWITCH_8.4_P4}
    "${testExtraArgs} -DMSDC_SPINE_DTEL_INT_PROFILE -pd -to 12000" "${SWITCH_8.4_PTF_DIR_SAI}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_8.4_spine_dtel_int_set_6"
        "saihostif.CoppStatTest")
bfn_set_ptf_port_map_file("tofino" "smoketest_switch_8.4_spine_dtel_int_set_6"
    "${SWITCH_8.4_PTF_DIR_SAI}/port_map.ini")
bfn_set_ptf_test_port("tofino" "smoketest_switch_8.4_spine_dtel_int_set_6"
    "3")
# 500s timeout is too little for compiling and testing the entire switch, bumping it up
set_tests_properties("tofino/smoketest_switch_8.4_spine_dtel_int" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_8.4_spine_dtel_int_set_1" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_8.4_spine_dtel_int_set_2" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_8.4_spine_dtel_int_set_3" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_8.4_spine_dtel_int_set_4" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_8.4_spine_dtel_int_set_5" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_8.4_spine_dtel_int_set_6" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_8.4_spine_dtel_int_set_2_part_2" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_8.4_spine_dtel_int_set_2_intl45_route_dtel_reports" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_8.4_spine_dtel_int_set_2_INTL45_TransitTest_Enable" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_8.4_spine_dtel_int_set_2_intl45_transitTest_hop2_stateless" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_8.4_spine_dtel_int_set_2_INTL45_Transit_EgressMoDTest" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_8.4_spine_dtel_int_set_2_INTL45_Transit_IngressMoDTest" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_8.4_spine_dtel_int_set_2_MirrorOnDropEgrNonDefaultRuleTest" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_8.4_spine_dtel_int_set_2_MirrorOnDropHostifReasonCodeTest" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_8.4_spine_dtel_int_set_2_MirrorOnDropIngressAclTest" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_8.4_spine_dtel_int_set_2_MirrorOnDropNonDefaultRuleTest" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_8.4_spine_dtel_int_set_2_QueueReport_Entropy_Test" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_8.4_spine_dtel_int_set_2_QueueReport_Quota_Test" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_8.4_spine_dtel_int_set_2_QueueReport_Over_ECMP_Test" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_8.4_spine_dtel_int_set_2_QueueReport_MirrorTest" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_8.4_spine_dtel_int_set_2_QueueReport_L2_MirrorTest" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_8.4_spine_dtel_int_set_3_INTL45_Transit_DoDTest" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_8.4_spine_dtel_int_set_3_MirrorOnDropDoDTest" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_8.4_spine_dtel_int_set_3_QueueReport_DoD_Test" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino/smoketest_switch_8.4_spine_dtel_int_set_5_INGRESS_DROP_REPORT_Test" PROPERTIES TIMEOUT 12000)

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
