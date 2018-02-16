set (tofino_timeout 500)

set (V1_SEARCH_PATTERNS "include.*(v1model|psa).p4" "main")
set (V1_EXCLUDE_PATTERNS "package" "extern")
set (P4TESTDATA ${P4C_SOURCE_DIR}/testdata)
set (P4TESTS_FOR_TOFINO "${P4TESTDATA}/p4_16_samples/*.p4")
p4c_find_tests("${P4TESTS_FOR_TOFINO}" v1tests INCLUDE "${V1_SEARCH_PATTERNS}" EXCLUDE "${V1_EXCLUDE_PATTERNS}")

set (P16_INCLUDE_PATTERNS "include.*(v1model|psa|tofino).p4" "main")
set (P16_EXCLUDE_PATTERNS "tofino.h")
set (P16_FOR_TOFINO "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/*.p4")
p4c_find_tests("${P16_FOR_TOFINO}" p16tests INCLUDE "${P16_INCLUDE_PATTERNS}" EXCLUDE "${P16_EXCLUDE_PATTERNS}")

# p4-tests has all the includes at the same level with the programs.
set (BFN_EXCLUDE_PATTERNS "tofino.p4")
set (BFN_TESTS "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4-tests/programs/*/*.p4")
bfn_find_tests ("${BFN_TESTS}" BFN_TESTS_LIST EXCLUDE "${BFN_EXCLUDE_PATTERNS}")

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
  ${BFN_TESTS_LIST}
  ${v1tests}
  )

p4c_add_bf_backend_tests("tofino" "${TOFINO_TEST_SUITES}")

p4c_add_ptf_test_with_ptfdir (
    "tofino" tor.p4 ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/google-tor/p4/spec/tor.p4
    "${testExtraArgs}" ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/tor.ptf)

set (ONOS_FABRIC_P4 ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/bf-onos/pipelines/fabric/src/main/resources/fabric.p4)
p4c_add_ptf_test_with_ptfdir (
    "tofino" fabric.p4 ${ONOS_FABRIC_P4}
    "${testExtraArgs} -DWITH_SPGW"
    ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/bf-onos-ptf/fabric.ptf)

set  (SWITCH_P4 ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/switch/p4src/switch.p4)
set  (isXFail TRUE)
file (RELATIVE_PATH switchtest ${P4C_SOURCE_DIR} ${SWITCH_P4})
p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} ${isXFail}
  "switch_ent_fin_leaf" ${switchtest} "${testExtraArgs} -DENT_FIN_LEAF_PROFILE")
p4c_add_test_label("tofino" "17Q4Goal" "switch_ent_fin_leaf")

p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} FALSE 
  "switch_dc_basic" ${switchtest} "${testExtraArgs} -DDC_BASIC_PROFILE")
p4c_add_test_label("tofino" "17Q4Goal" "switch_dc_basic")

p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} ${isXFail}
  "switch_ent_dc_general" ${switchtest} "${testExtraArgs} -DENT_DC_GENERAL_PROFILE")
p4c_add_test_label("tofino" "17Q4Goal" "switch_ent_dc_general")

p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} ${isXFail}
  "switch_msdc" ${switchtest} "${testExtraArgs} -DMSDC_PROFILE")
p4c_add_test_label("tofino" "17Q4Goal" "switch_msdc")

p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} FALSE
  "switch_l2" ${switchtest} "${testExtraArgs} -DL2_PROFILE")

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
