include (ExternalProject)

# Switch P4-14 On jbay_master (refpoint must be periodically updated)
set  (SWITCH_P4 ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/switch-jbay/p4src/switch.p4)
set  (SWITCH_PTF_DIR ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/switch-jbay/ptf-tests/base/api-tests)
set  (SWITCH_PTF_DIR_MIRROR ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/switch-jbay/ptf-tests/base/feature-tests)
set  (isXFail TRUE)
file (RELATIVE_PATH switchtest ${P4C_SOURCE_DIR} ${SWITCH_P4})
p4c_add_test_with_args ("tofino2" ${P4C_RUNTEST} FALSE
  "switch_dc_basic" ${switchtest} "${testExtraArgs}" "-DDC_BASIC_PROFILE")
p4c_add_test_label("tofino2" "18Q2Goal" "switch_dc_basic")

p4c_add_test_with_args ("tofino2" ${P4C_RUNTEST} FALSE
  "switch_ent_dc_general" ${switchtest} "${testExtraArgs}" "-DENT_DC_GENERAL_PROFILE")
p4c_add_test_label("tofino2" "18Q2Goal" "switch_ent_dc_general")

p4c_add_test_with_args ("tofino2" ${P4C_RUNTEST} FALSE
  "switch_msdc" ${switchtest} "${testExtraArgs}" "-DMSDC_PROFILE -DP4_WRED_DEBUG")
p4c_add_test_label("tofino2" "18Q2Goal" "switch_msdc")

p4c_add_ptf_test_with_ptfdir ("tofino2" "smoketest_switch_msdc" ${SWITCH_P4}
    "${testExtraArgs} -DMSDC_PROFILE -DP4_WRED_DEBUG -pd -to 12000" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino2" "smoketest_switch_msdc"
        "switch_hostif.HostIfRxTxTest")
p4c_add_ptf_test_with_ptfdir ("tofino2" "smoketest_switch_msdc_set_1" ${SWITCH_P4}
    "${testExtraArgs} -DMSDC_PROFILE -DP4_WRED_DEBUG -pd -to 12000" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino2" "smoketest_switch_msdc_set_1"
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
p4c_add_ptf_test_with_ptfdir ("tofino2" "smoketest_switch_msdc_set_2" ${SWITCH_P4}
    "${testExtraArgs} -DMSDC_PROFILE -DP4_WRED_DEBUG -pd -to 12000" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino2" "smoketest_switch_msdc_set_2"
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
p4c_add_ptf_test_with_ptfdir ("tofino2" "smoketest_switch_msdc_set_3" ${SWITCH_P4}
    "${testExtraArgs} -DMSDC_PROFILE -DP4_WRED_DEBUG -pd -to 12000" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino2" "smoketest_switch_msdc_set_3"
        "switch_tests.L2TrunkToTrunkVlanTest
    switch_tests.L2VlanStatsTest
        switch_tests.L3EcmpLagTest
        switch_tests.L3IPv4EcmpTest
    switch_tests.L3IPv4HostJumboTest
        switch_tests.L3IPv4HostModifyTest
        switch_tests.L3IPv4HostTest
        switch_tests.L3IPv4LagTest
        switch_tests.L3IPv4LookupTest")
p4c_add_ptf_test_with_ptfdir ("tofino2" "smoketest_switch_msdc_set_4" ${SWITCH_P4}
    "${testExtraArgs} -DMSDC_PROFILE -DP4_WRED_DEBUG -pd -to 12000" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino2" "smoketest_switch_msdc_set_4"
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
p4c_add_ptf_test_with_ptfdir ("tofino2" "smoketest_switch_msdc_set_5" ${SWITCH_P4}
    "${testExtraArgs} -DMSDC_PROFILE -DP4_WRED_DEBUG -pd -to 12000" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino2" "smoketest_switch_msdc_set_5"
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
p4c_add_ptf_test_with_ptfdir ("tofino2" "smoketest_switch_msdc_set_6" ${SWITCH_P4}
        "${testExtraArgs} -DMSDC_PROFILE -DP4_WRED_DEBUG -pd -to 12000" "${SWITCH_PTF_DIR_MIRROR}")
bfn_set_ptf_test_spec("tofino2" "smoketest_switch_msdc_set_6"
        "mirror_acl_slice_tests.IPv6MirrorAclSliceTest_i2e
        mirror_acl_slice_tests.MirrorAclSliceTest_i2e")
p4c_add_ptf_test_with_ptfdir ("tofino2" "smoketest_switch_msdc_set_7" ${SWITCH_P4}
        "${testExtraArgs} -DMSDC_PROFILE -DP4_WRED_DEBUG -pd -to 12000" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino2" "smoketest_switch_msdc_set_7"
        "switch_acl.AclLabelTest
        switch_acl.IPAclStatsTest
        switch_acl.IPAclTest
        switch_acl.IPIngressAclRangeTcamTest
        switch_acl.MirrorAclTest_e2e
        switch_acl.MirrorAclTest_i2e
        switch_acl.MirrorSessionTest")
#p4c_add_ptf_test_with_ptfdir ("tofino2" "smoketest_switch_msdc_Acl_i2e_ErspanRewriteTest" ${SWITCH_P4}
#          "${testExtraArgs} -DMSDC_PROFILE -pd" "${SWITCH_PTF_DIR}")
#bfn_set_ptf_test_spec("tofino2" "smoketest_switch_msdc_Acl_i2e_ErspanRewriteTest"
#	  "switch_acl.Acl_i2e_ErspanRewriteTest")
# 500s timeout is too little for compiling and testing the entire switch, bumping it up
set_tests_properties("tofino2/smoketest_switch_msdc" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino2/smoketest_switch_msdc_set_1" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino2/smoketest_switch_msdc_set_2" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino2/smoketest_switch_msdc_set_3" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino2/smoketest_switch_msdc_set_4" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino2/smoketest_switch_msdc_set_5" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino2/smoketest_switch_msdc_set_6" PROPERTIES TIMEOUT 12000)
set_tests_properties("tofino2/smoketest_switch_msdc_set_7" PROPERTIES TIMEOUT 12000)
