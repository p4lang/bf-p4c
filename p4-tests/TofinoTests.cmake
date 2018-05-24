set (tofino_timeout 600)

# check for PTF requirements
packet_test_setup_check("tofino")
# experimental -- doesn't quite work yet
# bfn_add_switch("tofino")

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

set (V1_SEARCH_PATTERNS "include.*(v1model|psa).p4" "main|common_v1_test")
set (V1_EXCLUDE_PATTERNS "package" "extern")
set (P4TESTDATA ${P4C_SOURCE_DIR}/testdata)
set (P4TESTS_FOR_TOFINO "${P4TESTDATA}/p4_16_samples/*.p4")
p4c_find_tests("${P4TESTS_FOR_TOFINO}" v1tests INCLUDE "${V1_SEARCH_PATTERNS}" EXCLUDE "${V1_EXCLUDE_PATTERNS}")

set (P16_INCLUDE_PATTERNS "include.*(v1model|psa|tofino|tna).p4" "main|common_v1_test")
set (P16_EXCLUDE_PATTERNS "tofino.h")
set (P16_FOR_TOFINO "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/*.p4")
p4c_find_tests("${P16_FOR_TOFINO}" p16tests INCLUDE "${P16_INCLUDE_PATTERNS}" EXCLUDE "${P16_EXCLUDE_PATTERNS}")

set (TOFINO_TEST_SUITES
  ${P4C_SOURCE_DIR}/testdata/p4_14_samples/*.p4
  ${p16tests}
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/*.p4
  # temporarily disable all customer tests -- we're failing many of them
  # and we want to save some Travis time
  # ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/c1/*/*.p4
  # ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/c2/*/*.p4
  # ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/c3/*/*.p4
  # ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/c4/*/*.p4
  # ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/c5/*/*.p4
  # ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/c6/*/*.p4
  # ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/c7/*/*.p4
  # ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/c8/*/*.p4
  ${v1tests}
  # p4smith regression tests
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4smith_regression/*.p4
  )

p4c_add_bf_backend_tests("tofino" "base" "${TOFINO_TEST_SUITES}")

p4c_add_ptf_test_with_ptfdir (
    "tofino" tor.p4 ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/google-tor/p4/spec/tor.p4
    "${testExtraArgs}" ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/tor.ptf)

set (ONOS_FABRIC_P4 ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/bf-onos/pipelines/fabric/src/main/resources/fabric.p4)
# run all combinations of fabric.p4 by enabling / disabling SPGW and INT
# transit. This is achieved by passing the names of the PTF groups whose tests
# we want to run to the PTF runner.
p4c_add_ptf_test_with_ptfdir_and_spec (
    "tofino" fabric ${ONOS_FABRIC_P4}
    "${testExtraArgs} "
    ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/bf-onos-ptf/fabric.ptf "all ^spgw ^int_transit")
p4c_add_ptf_test_with_ptfdir_and_spec (
    "tofino" fabric-DWITH_SPGW ${ONOS_FABRIC_P4}
    "${testExtraArgs} -DWITH_SPGW"
    ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/bf-onos-ptf/fabric.ptf "all ^int_transit")
p4c_add_ptf_test_with_ptfdir_and_spec (
    "tofino" fabric-DWITH_SPGW-DWITH_INT_TRANSIT ${ONOS_FABRIC_P4}
    "${testExtraArgs} -DWITH_SPGW -DWITH_INT_TRANSIT"
    ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/bf-onos-ptf/fabric.ptf "all")
p4c_add_ptf_test_with_ptfdir_and_spec (
    "tofino" fabric-DWITH_INT_TRANSIT ${ONOS_FABRIC_P4}
    "${testExtraArgs} -DWITH_INT_TRANSIT"
    ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/bf-onos-ptf/fabric.ptf "all ^spgw")

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

# subset of p4factory tests that we want to run as part of regressions
# One # means it fails badly but should get it to run soon
# Two # means it is not required for switch, but we should still try to compile
set (P4FACTORY_REGRESSION_TESTS
  basic_switching
  # # # bf-diags
  # # clpm
  # # dkm
  emulation
  # exm_direct -- timeout on a single test!!
  exm_direct_1
  exm_indirect_1
  exm_smoke_test
  fast_reconfig
  # meters -- timeout on a single test!!
  mirror_test
  # # multicast_scale
  multicast_test
  # # multi-device
  opcode_test
  # opcode_test_signed
  # opcode_test_saturating
  # opcode_test_signed_and_saturating
  pcie_pkt_test
  # # pctr
  # # pgrs
  perf_test_alpm   # (a.k.a alpm-pd-perf)
  # # pvs
  resubmit
  smoke_large_tbls
  stful
  )

# p4-tests has all the includes at the same level with the programs.
set (BFN_EXCLUDE_PATTERNS "tofino.p4")
set (BFN_TESTS "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4-tests/programs/*/*.p4")
bfn_find_tests ("${BFN_TESTS}" ALL_BFN_TESTS EXCLUDE "${BFN_EXCLUDE_PATTERNS}")
# make a list of all the tests that we want to run PTF on
set (P4F_PTF_TESTS)
foreach (t IN LISTS P4FACTORY_REGRESSION_TESTS)
  list (APPEND P4F_PTF_TESTS
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4-tests/programs/${t}/${t}.p4")
endforeach()
bfn_add_p4factory_tests("tofino" "smoketest_programs" P4F_PTF_TESTS)

set (P4FACTORY_PROGRAMS_PATH "extensions/p4_tests/p4_14/p4-tests/programs")
# Add extra build flags for PD gen

bfn_set_pd_build_flag("tofino" "${P4FACTORY_PROGRAMS_PATH}/exm_direct_1/exm_direct_1.p4"
  "--gen-exm-test-pd")
bfn_set_pd_build_flag("tofino" "${P4FACTORY_PROGRAMS_PATH}/exm_indirect_1/exm_indirect_1.p4"
  "--gen-exm-test-pd")
bfn_set_pd_build_flag("tofino" "${P4FACTORY_PROGRAMS_PATH}/exm_smoke_test/exm_smoke_test.p4"
  "--gen-exm-test-pd")
bfn_set_pd_build_flag("tofino" "${P4FACTORY_PROGRAMS_PATH}/perf_test_alpm/perf_test_alpm.p4"
  "--gen-perf-test-pd")

# Pick a single test for the tests that are timing out:
bfn_set_ptf_test_spec("tofino" "${P4FACTORY_PROGRAMS_PATH}/exm_indirect_1/exm_indirect_1.p4"
  "test.TestActSelIterators
   test.TestDirectStats
   test.TestDirectStatsPkts28Bytes36
   test.TestDirectStatsPkts32bits
   test.TestIndirectStatPkt64bits
   test.TestIndirectStatsPkts32bits
   test.TestSelector
   test.TestSelectorScopes
   test.TestExmHashAction2")
bfn_set_ptf_test_spec("tofino" "${P4FACTORY_PROGRAMS_PATH}/multicast_test/multicast_test.p4"
  "test.TestBasic
   ^test.TestYid
   ^test.TestXid
   test.TestEcmp
   ^test.TestLag
   ^test.TestBackup
   ^test.TestGetEntry
   test.TestRegAccess")
bfn_set_ptf_test_spec("tofino" "${P4FACTORY_PROGRAMS_PATH}/smoke_large_tbls/smoke_large_tbls.p4"
  "test.TestAtcam
   test.TestAtcamTernaryValid")
bfn_set_ptf_test_spec("tofino" "${P4FACTORY_PROGRAMS_PATH}/stful/stful.p4"
  "test.TestDirectHashCounter
   test.TestDirectStateRestore
   test.TestDirectTcamCounter_default
   test.TestDirectTcamCounter_move
   ^test.TestDirectTcamCounter_twoStage
   test.TestGetEntry
   test.TestIndirectHashSampler
   test.TestInDirectTcamCounter_entries
   test.TestInDirectTcamCounter_rdwr
   test.TestNoKeySymSet
   test.TestOneBit
   test.TestPhase0Iterator
   test.TestPktGenClear
   test.TestResetAPIs
   test.TestTwoInstrNoIdx")
bfn_set_ptf_test_spec("tofino" "${P4FACTORY_PROGRAMS_PATH}/mirror_test/mirror_test.p4"
   "test.TestBasicForwarding
   test.TestBasicIngMir
   test.TestBasicEgrMir
   test.TestBatching")

# for all other p4factory tests, add them as compile only.
set (P4F_COMPILE_ONLY)
foreach (t IN LISTS ALL_BFN_TESTS)
  list (FIND P4F_PTF_TESTS ${t} found_as_ptf)
  if (${found_as_ptf} EQUAL -1)
    list (APPEND P4F_COMPILE_ONLY ${t})
  endif()
endforeach()
p4c_add_bf_backend_tests("tofino" "smoketest_programs" "${P4F_COMPILE_ONLY}")

# Other PD tests

p4c_add_ptf_test_with_ptfdir("tofino" "smoketest_programs_alpm_test" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4-tests/programs/alpm_test/alpm_test.p4"
  "${testExtraArgs} -pd -to 2000" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4-tests/ptf-tests/alpm_test")
bfn_set_ptf_test_spec("tofino" "smoketest_programs_alpm_test"
  "test.TestAddRoute
   ^test.TestCapacity
   test.TestCoveringPrefix
   test.TestDefaultEntry
   test.TestDrop
   test.TestManyEntries
   test.TestModify")

p4c_add_ptf_test_with_ptfdir("tofino" "smoketest_programs_alpm_test_2" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4-tests/programs/alpm_test/alpm_test.p4"
  "${testExtraArgs} -pd -to 2000" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4-tests/ptf-tests/alpm_test")
bfn_set_ptf_test_spec("tofino" "smoketest_programs_alpm_test_2"
   "test.TestStateRestore
   test.TestTcamMove")

p4c_add_ptf_test_with_ptfdir("tofino" "smoketest_programs_alpm_test_TestRealData" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4-tests/programs/alpm_test/alpm_test.p4"
  "${testExtraArgs} -pd -to 2000" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4-tests/ptf-tests/alpm_test")
bfn_set_ptf_test_spec("tofino" "smoketest_programs_alpm_test_TestRealData"
   "test.TestRealData")

p4c_add_ptf_test_with_ptfdir("tofino" "smoketest_programs_alpm_test_TestIdleTime" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4-tests/programs/alpm_test/alpm_test.p4"
  "${testExtraArgs} -pd -to 2000" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4-tests/ptf-tests/alpm_test")
bfn_set_ptf_test_spec("tofino" "smoketest_programs_alpm_test_TestIdleTime"
   "test.TestIdleTime")

p4c_add_ptf_test_with_ptfdir("tofino" "smoketest_programs_alpm_test_TestSnapshot" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4-tests/programs/alpm_test/alpm_test.p4"
  "${testExtraArgs} -pd -to 2000" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4-tests/ptf-tests/alpm_test")
bfn_set_ptf_test_spec("tofino" "smoketest_programs_alpm_test_TestSnapshot"
   "test.TestSnapshot")

p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_programs_basic_ipv4" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4-tests/programs/basic_ipv4/basic_ipv4.p4"
    "${testExtraArgs} -pd -to 2000" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4-tests/ptf-tests/basic_ipv4")
bfn_set_ptf_test_spec("tofino" "smoketest_programs_basic_ipv4"
        "test.TestAddHdr
         test.TestAddRemPort
         test.TestAddRoute
         test.TestAllHit
         test.TestAllStage
         test.TestDeepADT")

p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_programs_basic_ipv4_2" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4-tests/programs/basic_ipv4/basic_ipv4.p4"
    "${testExtraArgs} -pd -to 2000" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4-tests/ptf-tests/basic_ipv4")
bfn_set_ptf_test_spec("tofino" "smoketest_programs_basic_ipv4_2"
        "test.TestRange
         test.TestRangeTernaryValid
         test.TestSelector
         test.TestTcamDuplicateEntries
         test.TestTcamEntries
         test.TestTcamMove
         test.TestTernaryValidMatch
         test.TestExm4way3Entries
         test.TestExm6way4Entries")

p4c_add_ptf_test_with_ptfdir ("tofino" "miss_clause" ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/PD/miss_clause.p4
    "${testExtraArgs} -pd" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/PD/miss_clause.ptf")

# Barefoot academy tests
set (BA_TESTS_FOR_TOFINO "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/ba-101/labs/*/solution/p4src/*.p4")
p4c_find_tests("${BA_TESTS_FOR_TOFINO}" ba_tests INCLUDE "__TARGET_TOFINO__")
# message("BA-101 tests: ${ba_tests}")
foreach(t IN LISTS ba_tests)
  get_filename_component(__td ${t} DIRECTORY)
  string (REGEX REPLACE "ba-101/labs/([0-9]+[a-z0-9_-]+)/solution.*" "\\1" __t ${__td})
  if (CMAKE_MATCH_1)
    set (testname ${CMAKE_MATCH_1})
  endif()
  set (ptfdir "${__td}/../ptf-tests")
  if (EXISTS ${ptfdir})
    p4c_add_ptf_test_with_ptfdir ("tofino" ${testname} ${t} "${testExtraArgs} -pd" ${ptfdir})
  else()
    file(RELATIVE_PATH testfile ${P4C_SOURCE_DIR} ${t})
    p4c_add_test_with_args("tofino" ${P4C_RUNTEST} FALSE ${testname} ${testfile} "${testExtraArgs}")
  endif()
  p4c_add_test_label("tofino" "BA-101" ${testname})
endforeach()


include(TofinoMustPass.cmake)
include(TofinoXfail.cmake)

#
# Commented out because we're not yet ready to run all these failed profiles
# and save cycles on testing
# p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} ${isXFail}
#   "switch_acl_ip4v" ${switchtest} "${testExtraArgs} -DACL_IPV4_PROFILE")
# p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} ${isXFail}
#   "switch_bfd_offload" ${switchtest} "${testExtraArgs} -DBFD_OFFLOAD_PROFILE")
# p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} ${isXFail}
#   "switch_dc_maxsizes" ${switchtest} "${testExtraArgs} -DDC_MAXSIZES_PROFILE")
# p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} ${isXFail}
#   "switch_egress_acl" ${switchtest} "${testExtraArgs} -DEGRESS_ACL_PROFILE")
# p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} ${isXFail}
#   "switch_fabric" ${switchtest} "${testExtraArgs} -DFABRIC_PROFILE")
# p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} ${isXFail}
#   "switch_fabric_maxsizes" ${switchtest} "${testExtraArgs} -DFABRIC_MAXSIZES_PROFILE")
# p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} ${isXFail}
#   "switch_ila" ${switchtest} "${testExtraArgs} -DILA_PROFILE")
# p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} ${isXFail}
#   "switch_ila_ipv6" ${switchtest} "${testExtraArgs} -DILA_IPV6_PROFILE")
# p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} ${isXFail}
#   "switch_ent_fin_spine" ${switchtest} "${testExtraArgs} -DENT_FIN_SPINE_PROFILE")
# p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} ${isXFail}
#   "switch_ent_fin_postcard" ${switchtest} "${testExtraArgs} -DENT_FIN_POSTCARD_PROFILE")
# p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} ${isXFail}
#   "switch_l3_ipv4_fib_clpm" ${switchtest} "${testExtraArgs} -DL3_IPV4_FIB_CLPM_PROFILE")
# p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} ${isXFail}
#   "switch_mpls_udp" ${switchtest} "${testExtraArgs} -DMPLS_UDP_PROFILE")
# p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} ${isXFail}
#   "switch_nat" ${switchtest} "${testExtraArgs} -DNAT_PROFILE")
# p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} ${isXFail}
#   "switch_qos" ${switchtest} "${testExtraArgs} -DQOS_PROFILE")
# p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} ${isXFail}
#   "switch_sflow" ${switchtest} "${testExtraArgs} -DSFLOW_PROFILE")
# p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} ${isXFail}
#   "switch_test_int_vxlan_ep" ${switchtest} "${testExtraArgs} -DTEST_INT_VXLAN_EP_PROFILE")
# p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} ${isXFail}
#   "switch_test_int_vxlan_transit" ${switchtest} "${testExtraArgs} -DTEST_INT_VXLAN_TRANSIT_PROFILE")
# p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} ${isXFail}
#   "switch_test_mirror_on_drop" ${switchtest} "${testExtraArgs} -DTEST_MIRROR_ON_DROP_PROFILE")
