include (ExternalProject)

# Switch P4-14 On Master (refpoint must be periodically updated)
set  (SWITCH_P4 ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/switch/p4src/switch.p4)
set  (SWITCH_PTF_BASE ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/switch/ptf-tests/base)
set  (SWITCH_PTF_DIR ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/switch/ptf-tests/base/api-tests)
set  (SWITCH_PTF_DIR_MIRROR ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/switch/ptf-tests/base/feature-tests)
set  (SWITCH_PTF_DIR_EGRESS_ACL ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/switch/ptf-tests/egress-acl/api-tests)
set  (SWITCH_PTF_DIR_WRED ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/switch/ptf-tests/wred/api-tests)
set  (SWITCH_PTF_DIR_SAI ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/switch/ptf-tests/base/sai-ocp-tests)
set  (SWITCH_PTF_DIR_DTEL ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/switch/ptf-tests/dtel/api-tests)
set  (SWITCH_PTF_DIR_QOS ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/switch/ptf-tests/qos/api-tests)
set  (SWITCH_PTF_DIR_PD ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/switch/ptf-tests/base/pd-tests)
set  (SWITCH_PTF_DIR_SAI_DTEL ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/switch/ptf-tests/dtel/sai-tests)
set  (testExtraArgs "${testExtraArgs} -Xp4c=\"--disable-power-check\"")
set  (isXFail TRUE)

file (RELATIVE_PATH switchtest ${P4C_SOURCE_DIR} ${SWITCH_P4})
p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} FALSE
    "switch_dc_basic" ${switchtest} "${testExtraArgs}" "--disable-pragmas=pa_solitary -DDC_BASIC_PROFILE")
p4c_add_test_label("tofino" "METRICS" "switch_dc_basic")

p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} FALSE
    "switch_ent_fin_postcard" ${switchtest} "${testExtraArgs}" "-DENT_FIN_POSTCARD_PROFILE")

p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} FALSE
    "switch_ent_dc_general" ${switchtest} "${testExtraArgs}" "--disable-pragmas=pa_solitary -DENT_DC_GENERAL_PROFILE -to 1200")
p4c_add_test_label("tofino" "METRICS" "switch_ent_dc_general")

p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} FALSE
    "switch_msdc" ${switchtest} "${testExtraArgs}" "--disable-pragmas=pa_solitary -DMSDC_PROFILE -DP4_WRED_DEBUG")
p4c_add_test_label("tofino" "METRICS" "switch_msdc")

p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} FALSE}
    "switch_msdc_ipv4" ${switchtest} "${testExtraArgs}" "--disable-pragmas=pa_solitary -DMSDC_IPV4_PROFILE")
p4c_add_test_label("tofino" "METRICS" "switch_msdc_ipv4")

p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} FALSE
    "switch_msdc_l3" ${switchtest} "${testExtraArgs}" "-DMSDC_L3_PROFILE")

p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} FALSE
    "switch_msdc_spine_int" ${switchtest} "${testExtraArgs}" "--disable-pragmas=pa_solitary -DMSDC_SPINE_DTEL_INT_PROFILE")
p4c_add_test_label("tofino" "METRICS" "switch_msdc_spine_int")

p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} FALSE
    "switch_msdc_leaf_int" ${switchtest} "${testExtraArgs}" "-DMSDC_LEAF_DTEL_INT_PROFILE")

p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} FALSE
    "switch_l3_heavy_int_leaf" ${switchtest} "${testExtraArgs}" "-DL3_HEAVY_INT_LEAF_PROFILE")

p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} FALSE
    "switch_generic_int_leaf" ${switchtest} "${testExtraArgs}"
    "--disable-pragmas=pa_solitary -DGENERIC_INT_LEAF_PROFILE")

# 500s timeout is too little for compiling ent_dc_general profile, bumping it up
set_tests_properties("tofino/switch_ent_dc_general" PROPERTIES TIMEOUT 1200)

# Switch On Release 8.7 (refpoint must be periodically updated)
set  (SWITCH_VERSION 8.7)
set  (SWITCH_${SWITCH_VERSION}_P4 ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/switch-${SWITCH_VERSION}/p4src/switch.p4)
set  (SWITCH_${SWITCH_VERSION}_PTF_DIR ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/switch-${SWITCH_VERSION}/ptf-tests/base/api-tests)
set  (SWITCH_${SWITCH_VERSION}_PTF_DIR_MIRROR ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/switch-${SWITCH_VERSION}/ptf-tests/base/feature-tests)
set  (SWITCH_${SWITCH_VERSION}_PTF_DIR_SAI ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/switch-${SWITCH_VERSION}/ptf-tests/base/sai-ocp-tests)
set  (SWITCH_${SWITCH_VERSION}_PTF_DIR_SAI_DTEL ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/switch-${SWITCH_VERSION}/ptf-tests/dtel/sai-tests)
set  (SWITCH_${SWITCH_VERSION}_PTF_DIR_EGRESS_ACL ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/switch-${SWITCH_VERSION}/ptf-tests/egress-acl/api-tests)
set  (SWITCH_${SWITCH_VERSION}_PTF_DIR_WRED ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/switch-${SWITCH_VERSION}/ptf-tests/wred/api-tests)
set  (SWITCH_${SWITCH_VERSION}_PTF_DIR_DTEL ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/switch-${SWITCH_VERSION}/ptf-tests/dtel/api-tests)
set  (SWITCH_${SWITCH_VERSION}_PTF_DIR_QOS ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/switch-${SWITCH_VERSION}/ptf-tests/qos/api-tests)
set  (isXFail TRUE)
file (RELATIVE_PATH switch_${SWITCH_VERSION}_test ${P4C_SOURCE_DIR} ${SWITCH_${SWITCH_VERSION}_P4})

p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} FALSE
    "switch_${SWITCH_VERSION}_dc_basic" ${switch_${SWITCH_VERSION}_test} "${testExtraArgs}" "-DDC_BASIC_PROFILE")

p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} FALSE
    "switch_${SWITCH_VERSION}_ent_fin_postcard" ${switch_${SWITCH_VERSION}_test} "${testExtraArgs}" "-DENT_FIN_POSTCARD_PROFILE")

p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} FALSE
    "switch_${SWITCH_VERSION}_ent_dc_general" ${switch_${SWITCH_VERSION}_test} "${testExtraArgs}" "-DENT_DC_GENERAL_PROFILE -to 1200")

p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} FALSE
    "switch_${SWITCH_VERSION}_msdc" ${switch_${SWITCH_VERSION}_test} "${testExtraArgs}" "-DMSDC_PROFILE -DP4_WRED_DEBUG")

p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} FALSE
    "switch_${SWITCH_VERSION}_msdc_ipv4" ${switch_${SWITCH_VERSION}_test} "${testExtraArgs}"
    "--disable-pragmas=pa_solitary -DMSDC_IPV4_PROFILE")

p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} FALSE
    "switch_${SWITCH_VERSION}_msdc_l3" ${switch_${SWITCH_VERSION}_test} "${testExtraArgs}" "-DMSDC_L3_PROFILE")

p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} FALSE
    "switch_${SWITCH_VERSION}_msdc_spine_int" ${switch_${SWITCH_VERSION}_test} "${testExtraArgs}" "-DMSDC_SPINE_DTEL_INT_PROFILE")

p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} FALSE
    "switch_${SWITCH_VERSION}_msdc_leaf_int" ${switch_${SWITCH_VERSION}_test} "${testExtraArgs}" "-DMSDC_LEAF_DTEL_INT_PROFILE")

p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} FALSE
    "switch_${SWITCH_VERSION}_l3_heavy_int_leaf" ${switch_${SWITCH_VERSION}_test} "${testExtraArgs}" "-DL3_HEAVY_INT_LEAF_PROFILE")

p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} FALSE
    "switch_${SWITCH_VERSION}_generic_int_leaf" ${switch_${SWITCH_VERSION}_test} "${testExtraArgs}"
    "--disable-pragmas=pa_solitary -DGENERIC_INT_LEAF_PROFILE")

# 500s timeout is too little for compiling ent_dc_general profile, bumping it up
set_tests_properties("tofino/switch_${SWITCH_VERSION}_ent_dc_general" PROPERTIES TIMEOUT 1200)

# Switch P4-16
set (SWITCH_P4_16_ROOT ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/switch_16)
set (SWITCH_P4_16_INC ${SWITCH_P4_16_ROOT}/p4src/shared)
set (SWITCH_P4_16_PTF ${SWITCH_P4_16_ROOT}/ptf/api)

set (SWITCH_P4_16 ${SWITCH_P4_16_ROOT}/p4src/switch-tofino/switch_tofino_x0.p4)
file (RELATIVE_PATH switch_p4_16 ${P4C_SOURCE_DIR} ${SWITCH_P4_16})
p4c_add_test_with_args("tofino" ${P4C_RUNTEST} FALSE
  "smoketest_switch_16_compile" ${switch_p4_16} "${testExtraArgs}" "-I${SWITCH_P4_16_INC} -arch tna")
p4c_add_test_label("tofino" "METRICS" "smoketest_switch_16_compile")

set (SWITCH_P4_16_X1 ${SWITCH_P4_16_ROOT}/p4src/switch-tofino/switch_tofino_x1.p4)
file (RELATIVE_PATH switch_p4_16_x1 ${P4C_SOURCE_DIR} ${SWITCH_P4_16_X1})
p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} FALSE
  "smoketest_switch_16_compile_x1_profile" ${switch_p4_16_x1} "${testExtraArgs}" "-DX1_PROFILE -I${SWITCH_P4_16_INC} -Xp4c=\"--disable-power-check\" -arch tna")
p4c_add_test_label("tofino" "METRICS" "smoketest_switch_16_compile_x1_profile")

set (SWITCH_P4_16_X2 ${SWITCH_P4_16_ROOT}/p4src/switch-tofino/switch_tofino_x2.p4)
file (RELATIVE_PATH switch_p4_16_x2 ${P4C_SOURCE_DIR} ${SWITCH_P4_16_X2})
p4c_add_test_with_args("tofino" ${P4C_RUNTEST} FALSE
  "smoketest_switch_16_compile_x2_profile" ${switch_p4_16_x2} "${testExtraArgs}" "-DX2_PROFILE -I${SWITCH_P4_16_INC} -Xp4c=\"--disable-power-check\" -arch tna")
p4c_add_test_label("tofino" "METRICS" "smoketest_switch_16_compile_x2_profile")

set (SWITCH_P4_16_X3 ${SWITCH_P4_16_ROOT}/p4src/switch-tofino/switch_tofino_x3.p4)
file (RELATIVE_PATH switch_p4_16_x3 ${P4C_SOURCE_DIR} ${SWITCH_P4_16_X3})
p4c_add_test_with_args("tofino" ${P4C_RUNTEST} FALSE
  "smoketest_switch_16_compile_x3_profile" ${switch_p4_16_x3} "${testExtraArgs}" "-DX3_PROFILE -I${SWITCH_P4_16_INC} -arch tna")
p4c_add_test_label("tofino" "METRICS" "smoketest_switch_16_compile_x3_profile")

# We cannot run some tests in our environment as some interfaces referenced in the port
# mapping file specified for bf-switch don't exist.
  p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_16_Tests_x1" ${SWITCH_P4_16_X1}
    "${testExtraArgs} -arch tna -bfrt -profile x1_tofino -to 3600" ${SWITCH_P4_16_PTF})
  bfn_set_ptf_test_spec("tofino" "smoketest_switch_16_Tests_x1"
         "all
         ^switch_l3.L3SVITest
         ^switch_l2.L2LagTest")
  p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_16_Tests_x2" ${SWITCH_P4_16_X2}
    "${testExtraArgs} -arch tna -bfrt -profile x2_tofino -to 3600" ${SWITCH_P4_16_PTF})
  bfn_set_ptf_test_spec("tofino" "smoketest_switch_16_Tests_x2"
         "all
         ^switch_l3.L3SVITest
         ^switch_l2.L2LagTest")
  p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_16_Tests_x0" ${SWITCH_P4_16}
   "${testExtraArgs} -arch tna -bfrt -profile x0_tofino -to 3600" ${SWITCH_P4_16_PTF})
 bfn_set_ptf_test_spec("tofino" "smoketest_switch_16_Tests_x0"
         "all
         ^switch_l3.L3SVITest
         ^switch_l2.L2LagTest")
# All switch_16 tests should depend on the test being compiled, rather than
# relying on the first one to compile the test.
set_tests_properties(
  "tofino/smoketest_switch_16_Tests_x1"
  "tofino/smoketest_switch_16_Tests_x2"
  "tofino/smoketest_switch_16_Tests_x0"
  PROPERTIES DEPENDS "tofino/smoketest_switch_16_compile"
  )

# 500s timeout is too little for compiling and testing the entire switch, bumping it up
set_tests_properties("tofino/smoketest_switch_16_compile_x1_profile" PROPERTIES TIMEOUT 1200)
set_tests_properties("tofino/smoketest_switch_16_compile_x2_profile" PROPERTIES TIMEOUT 1200)
set_tests_properties("tofino/smoketest_switch_16_compile_x3_profile" PROPERTIES TIMEOUT 1200)
set_tests_properties("tofino/smoketest_switch_16_compile" PROPERTIES TIMEOUT 1200)
set_tests_properties("tofino/smoketest_switch_16_Tests_x1" PROPERTIES TIMEOUT 3600)
set_tests_properties("tofino/smoketest_switch_16_Tests_x2" PROPERTIES TIMEOUT 3600)
set_tests_properties("tofino/smoketest_switch_16_Tests_x0" PROPERTIES TIMEOUT 3600)

# Switch master MSDC_PROFILE tests
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_msdc" ${SWITCH_P4}
    "${testExtraArgs} -DMSDC_PROFILE -DP4_WRED_DEBUG -pd -to 3600" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_msdc"
        "l2 l3 acl ^aclfrag ^tunnel mirror ^urpf ^mpls ^mcast ^racl ^warminit ^stp ^dynhash32
        ^switch_tests.MalformedPacketsTest
        ^switch_tests.L2DynamicMacMoveTest
        ^switch_tests.L2LNStatsTest
        ^switch_tests.L2StaticMacMoveBulkTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_msdc_set_1" ${SWITCH_P4}
    "${testExtraArgs} -DMSDC_PROFILE -DP4_WRED_DEBUG -pd -to 3600" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_msdc_set_1"
        "switch_tests.L2DynamicMacMoveTest
        switch_tests.L2LNStatsTest
        switch_tests.L2StaticMacMoveBulkTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_msdc_mirror" ${SWITCH_P4}
        "${testExtraArgs} -DMSDC_PROFILE -DP4_WRED_DEBUG -pd -to 3600" "${SWITCH_PTF_DIR_MIRROR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_msdc_mirror"
        "mirror_acl")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_msdc_wred" ${SWITCH_P4}
        "${testExtraArgs} -DMSDC_PROFILE -DP4_WRED_DEBUG -pd -to 3600" "${SWITCH_PTF_DIR_WRED}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_msdc_wred"
        "wred_drop")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_msdc_MalformedPacketsTest" ${SWITCH_P4}
   "${testExtraArgs} -DMSDC_PROFILE -DP4_WRED_DEBUG -pd -to 3600" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_msdc_MalformedPacketsTest"
        "switch_tests.MalformedPacketsTest")

# 500s timeout is too little for compiling and testing the entire switch, bumping it up
set_tests_properties("tofino/smoketest_switch_msdc" PROPERTIES TIMEOUT 3600)
set_tests_properties("tofino/smoketest_switch_msdc_set_1" PROPERTIES TIMEOUT 3600)
set_tests_properties("tofino/smoketest_switch_msdc_mirror" PROPERTIES TIMEOUT 3600)
set_tests_properties("tofino/smoketest_switch_msdc_wred" PROPERTIES TIMEOUT 3600)
set_tests_properties("tofino/smoketest_switch_msdc_MalformedPacketsTest" PROPERTIES TIMEOUT 3600)

p4c_add_test_label("tofino" "UNSTABLE" "smoketest_switch_msdc_set_1")

# Switch master DC_BASIC_PROFILE tests
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_dc_basic" ${SWITCH_P4}
        "${testExtraArgs} -DDC_BASIC_PROFILE -pd -to 3600" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_dc_basic"
        "all ^aclfrag ^queue-stats ^dynhash32
        ^switch_tests.MalformedPacketsTest
        ^switch_tests.MalformedPacketsTest_ipv6
        ^switch_tests.MalformedPacketsTest_tunnel
        ^switch_tests.L2DynamicMacMoveTest
        ^switch_tests.L2IPv4InIPv6VxlanUnicastBasicTest
        ^switch_tests.L2LNStatsTest
        ^switch_tests.L2StaticMacMoveBulkTest
        ^switch_tests.L2VxlanToGeneveUnicastBasicTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_dc_basic_set_1" ${SWITCH_P4}
    "${testExtraArgs} -DDC_BASIC_PROFILE -pd -to 3600" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_dc_basic_set_1"
        "switch_tests.L2DynamicMacMoveTest
        switch_tests.L2IPv4InIPv6VxlanUnicastBasicTest
        switch_tests.L2LNStatsTest
        switch_tests.L2StaticMacMoveBulkTest
        switch_tests.L2VxlanToGeneveUnicastBasicTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_dc_basic_sai_l2" ${SWITCH_P4}
        "${testExtraArgs} -DDC_BASIC_PROFILE -pd -to 3600" "${SWITCH_PTF_DIR_SAI}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_dc_basic_sai_l2"
        "l2-ocp")
bfn_set_ptf_port_map_file("tofino" "smoketest_switch_dc_basic_sai_l2"
    "${SWITCH_PTF_DIR_SAI}/default_interface_to_front_map.ini")
bfn_set_ptf_ports_json_file("tofino" "smoketest_switch_dc_basic_sai_l2"
    "${SWITCH_PTF_BASE}/ports.json")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_dc_basic_sai_l3" ${SWITCH_P4}
        "${testExtraArgs} -DDC_BASIC_PROFILE -pd -to 3600" "${SWITCH_PTF_DIR_SAI}")
# Excluding some sail3 tests which need more ports than the supported HW ports
bfn_set_ptf_test_spec("tofino" "smoketest_switch_dc_basic_sai_l3"
        "l3-ocp
        ^sail3.L3MultipleEcmpLagTest
        ^sail3.L3IPv4MacRewriteTest
        ^sail3.L3EcmpLagTest
        ^saihash.L3IPv4EcmpHostTest
        ^saihash.L3IPv4LagTest")
bfn_set_ptf_port_map_file("tofino" "smoketest_switch_dc_basic_sai_l3"
    "${SWITCH_PTF_DIR_SAI}/default_interface_to_front_map.ini")
bfn_set_ptf_ports_json_file("tofino" "smoketest_switch_dc_basic_sai_l3"
    "${SWITCH_PTF_BASE}/ports.json")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_dc_basic_sai_acl" ${SWITCH_P4}
        "${testExtraArgs} -DDC_BASIC_PROFILE -pd -to 3600" "${SWITCH_PTF_DIR_SAI}")
# Excluding some saiacl tests which need more ports than the supported HW ports
bfn_set_ptf_test_spec("tofino" "smoketest_switch_dc_basic_sai_acl"
        "acl-ocp
        ^saiacl.BindAclTableInGroupTest")
bfn_set_ptf_port_map_file("tofino" "smoketest_switch_dc_basic_sai_acl"
    "${SWITCH_PTF_DIR_SAI}/default_interface_to_front_map.ini")
bfn_set_ptf_ports_json_file("tofino" "smoketest_switch_dc_basic_sai_acl"
    "${SWITCH_PTF_BASE}/ports.json")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_dc_basic_sai_hostif_ARPTest" ${SWITCH_P4}
        "${testExtraArgs} -DDC_BASIC_PROFILE -pd -to 3600" "${SWITCH_PTF_DIR_SAI}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_dc_basic_sai_hostif_ARPTest"
        "saihostif.ARPTest")
bfn_set_ptf_test_port("tofino" "smoketest_switch_dc_basic_sai_hostif_ARPTest"
    "3")
bfn_set_ptf_port_map_file("tofino" "smoketest_switch_dc_basic_sai_hostif_ARPTest"
    "${SWITCH_PTF_DIR_SAI}/default_interface_to_front_map.ini")
bfn_set_ptf_ports_json_file("tofino" "smoketest_switch_dc_basic_sai_hostif_ARPTest"
    "${SWITCH_PTF_BASE}/ports.json")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_dc_basic_sai_hostif_DHCPTest" ${SWITCH_P4}
    "${testExtraArgs} -DDC_BASIC_PROFILE -pd -to 3600" "${SWITCH_PTF_DIR_SAI}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_dc_basic_sai_hostif_DHCPTest"
        "saihostif.DHCPTest")
bfn_set_ptf_test_port("tofino" "smoketest_switch_dc_basic_sai_hostif_DHCPTest"
    "3")
bfn_set_ptf_port_map_file("tofino" "smoketest_switch_dc_basic_sai_hostif_DHCPTest"
    "${SWITCH_PTF_DIR_SAI}/default_interface_to_front_map.ini")
bfn_set_ptf_ports_json_file("tofino" "smoketest_switch_dc_basic_sai_hostif_DHCPTest"
    "${SWITCH_PTF_BASE}/ports.json")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_dc_basic_sai_hostif_LLDPTest" ${SWITCH_P4}
    "${testExtraArgs} -DDC_BASIC_PROFILE -pd -to 3600" "${SWITCH_PTF_DIR_SAI}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_dc_basic_sai_hostif_LLDPTest"
        "saihostif.LLDPTest")
bfn_set_ptf_test_port("tofino" "smoketest_switch_dc_basic_sai_hostif_LLDPTest"
    "3")
bfn_set_ptf_port_map_file("tofino" "smoketest_switch_dc_basic_sai_hostif_LLDPTest"
    "${SWITCH_PTF_DIR_SAI}/default_interface_to_front_map.ini")
bfn_set_ptf_ports_json_file("tofino" "smoketest_switch_dc_basic_sai_hostif_LLDPTest"
    "${SWITCH_PTF_BASE}/ports.json")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_dc_basic_sai_hostif_LACPTest" ${SWITCH_P4}
    "${testExtraArgs} -DDC_BASIC_PROFILE -pd -to 3600" "${SWITCH_PTF_DIR_SAI}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_dc_basic_sai_hostif_LACPTest"
        "saihostif.LACPTest")
bfn_set_ptf_test_port("tofino" "smoketest_switch_dc_basic_sai_hostif_LACPTest"
    "3")
bfn_set_ptf_port_map_file("tofino" "smoketest_switch_dc_basic_sai_hostif_LACPTest"
    "${SWITCH_PTF_DIR_SAI}/default_interface_to_front_map.ini")
bfn_set_ptf_ports_json_file("tofino" "smoketest_switch_dc_basic_sai_hostif_LACPTest"
    "${SWITCH_PTF_BASE}/ports.json")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_dc_basic_sai_hostif_SNMPTest" ${SWITCH_P4}
    "${testExtraArgs} -DDC_BASIC_PROFILE -pd -to 3600" "${SWITCH_PTF_DIR_SAI}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_dc_basic_sai_hostif_SNMPTest"
        "saihostif.SNMPTest")
bfn_set_ptf_test_port("tofino" "smoketest_switch_dc_basic_sai_hostif_SNMPTest"
    "3")
bfn_set_ptf_port_map_file("tofino" "smoketest_switch_dc_basic_sai_hostif_SNMPTest"
    "${SWITCH_PTF_DIR_SAI}/default_interface_to_front_map.ini")
bfn_set_ptf_ports_json_file("tofino" "smoketest_switch_dc_basic_sai_hostif_SNMPTest"
    "${SWITCH_PTF_BASE}/ports.json")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_dc_basic_sai_hostif_SSHTest" ${SWITCH_P4}
    "${testExtraArgs} -DDC_BASIC_PROFILE -pd -to 3600" "${SWITCH_PTF_DIR_SAI}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_dc_basic_sai_hostif_SSHTest"
        "saihostif.SSHTest")
bfn_set_ptf_test_port("tofino" "smoketest_switch_dc_basic_sai_hostif_SSHTest"
    "3")
bfn_set_ptf_port_map_file("tofino" "smoketest_switch_dc_basic_sai_hostif_SSHTest"
    "${SWITCH_PTF_DIR_SAI}/default_interface_to_front_map.ini")
bfn_set_ptf_ports_json_file("tofino" "smoketest_switch_dc_basic_sai_hostif_SSHTest"
    "${SWITCH_PTF_BASE}/ports.json")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_dc_basic_sai_hostif_IP2METest" ${SWITCH_P4}
    "${testExtraArgs} -DDC_BASIC_PROFILE -pd -to 3600" "${SWITCH_PTF_DIR_SAI}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_dc_basic_sai_hostif_IP2METest"
        "saihostif.IP2METest")
bfn_set_ptf_test_port("tofino" "smoketest_switch_dc_basic_sai_hostif_IP2METest"
    "3")
bfn_set_ptf_port_map_file("tofino" "smoketest_switch_dc_basic_sai_hostif_IP2METest"
    "${SWITCH_PTF_DIR_SAI}/default_interface_to_front_map.ini")
bfn_set_ptf_ports_json_file("tofino" "smoketest_switch_dc_basic_sai_hostif_IP2METest"
    "${SWITCH_PTF_BASE}/ports.json")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_dc_basic_sai_hostif_TTLErrorTest" ${SWITCH_P4}
    "${testExtraArgs} -DDC_BASIC_PROFILE -pd -to 3600" "${SWITCH_PTF_DIR_SAI}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_dc_basic_sai_hostif_TTLErrorTest"
        "saihostif.TTLErrorTest")
bfn_set_ptf_test_port("tofino" "smoketest_switch_dc_basic_sai_hostif_TTLErrorTest"
    "3")
bfn_set_ptf_port_map_file("tofino" "smoketest_switch_dc_basic_sai_hostif_TTLErrorTest"
    "${SWITCH_PTF_DIR_SAI}/default_interface_to_front_map.ini")
bfn_set_ptf_ports_json_file("tofino" "smoketest_switch_dc_basic_sai_hostif_TTLErrorTest"
    "${SWITCH_PTF_BASE}/ports.json")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_dc_basic_sai_hostif_BGPTest" ${SWITCH_P4}
    "${testExtraArgs} -DDC_BASIC_PROFILE -pd -to 3600" "${SWITCH_PTF_DIR_SAI}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_dc_basic_sai_hostif_BGPTest"
        "saihostif.BGPTest")
bfn_set_ptf_test_port("tofino" "smoketest_switch_dc_basic_sai_hostif_BGPTest"
    "3")
bfn_set_ptf_port_map_file("tofino" "smoketest_switch_dc_basic_sai_hostif_BGPTest"
    "${SWITCH_PTF_DIR_SAI}/default_interface_to_front_map.ini")
bfn_set_ptf_ports_json_file("tofino" "smoketest_switch_dc_basic_sai_hostif_BGPTest"
    "${SWITCH_PTF_BASE}/ports.json")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_dc_basic_MalformedPacketsTest" ${SWITCH_P4}
        "${testExtraArgs} -DDC_BASIC_PROFILE -pd -to 3600" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_dc_basic_MalformedPacketsTest"
        "switch_tests.MalformedPacketsTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_dc_basic_MalformedPacketsTest_ipv6" ${SWITCH_P4}
        "${testExtraArgs} -DDC_BASIC_PROFILE -pd -to 3600" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_dc_basic_MalformedPacketsTest_ipv6"
        "switch_tests.MalformedPacketsTest_ipv6")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_dc_basic_MalformedPacketsTest_tunnel" ${SWITCH_P4}
        "${testExtraArgs} -DDC_BASIC_PROFILE -pd -to 3600" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_dc_basic_MalformedPacketsTest_tunnel"
        "switch_tests.MalformedPacketsTest_tunnel")

# 500s timeout is too little for compiling and testing the entire switch, bumping it up
set_tests_properties("tofino/smoketest_switch_dc_basic" PROPERTIES TIMEOUT 3600)
set_tests_properties("tofino/smoketest_switch_dc_basic_set_1" PROPERTIES TIMEOUT 3600)
set_tests_properties("tofino/smoketest_switch_dc_basic_sai_l2" PROPERTIES TIMEOUT 3600)
set_tests_properties("tofino/smoketest_switch_dc_basic_sai_l3" PROPERTIES TIMEOUT 3600)
set_tests_properties("tofino/smoketest_switch_dc_basic_sai_acl" PROPERTIES TIMEOUT 3600)
set_tests_properties("tofino/smoketest_switch_dc_basic_sai_hostif_ARPTest" PROPERTIES TIMEOUT 3600)
set_tests_properties("tofino/smoketest_switch_dc_basic_sai_hostif_DHCPTest" PROPERTIES TIMEOUT 3600)
set_tests_properties("tofino/smoketest_switch_dc_basic_sai_hostif_LLDPTest" PROPERTIES TIMEOUT 3600)
set_tests_properties("tofino/smoketest_switch_dc_basic_sai_hostif_LACPTest" PROPERTIES TIMEOUT 3600)
set_tests_properties("tofino/smoketest_switch_dc_basic_sai_hostif_SNMPTest" PROPERTIES TIMEOUT 3600)
set_tests_properties("tofino/smoketest_switch_dc_basic_sai_hostif_SSHTest" PROPERTIES TIMEOUT 3600)
set_tests_properties("tofino/smoketest_switch_dc_basic_sai_hostif_IP2METest" PROPERTIES TIMEOUT 3600)
set_tests_properties("tofino/smoketest_switch_dc_basic_sai_hostif_TTLErrorTest" PROPERTIES TIMEOUT 3600)
set_tests_properties("tofino/smoketest_switch_dc_basic_sai_hostif_BGPTest" PROPERTIES TIMEOUT 3600)
set_tests_properties("tofino/smoketest_switch_dc_basic_MalformedPacketsTest" PROPERTIES TIMEOUT 3600)
set_tests_properties("tofino/smoketest_switch_dc_basic_MalformedPacketsTest_ipv6" PROPERTIES TIMEOUT 3600)
set_tests_properties("tofino/smoketest_switch_dc_basic_MalformedPacketsTest_tunnel" PROPERTIES TIMEOUT 3600)

p4c_add_test_label("tofino" "UNSTABLE" "smoketest_switch_dc_basic_set_1")

# Switch master ENT_DC_GENERAL_PROFILE tests
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_ent_dc_general" ${SWITCH_P4}
        "${testExtraArgs} -DENT_DC_GENERAL_PROFILE -pd -to 3600" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_ent_dc_general"
        "ent ^aclfrag ^stp ^dynhash32
        ^switch_tests.L3IPv4MtuTest
        ^switch_tests.L2AccessToTrunkPriorityTaggingTest
        ^switch_tests.L2NoLearnTest
        ^switch_tests.L2LNStatsTest
        ^switch_tests.L2DynamicMacMoveTest
        ^switch_tests.L2StaticMacMoveBulkTest
        ^switch_tests.L2VxlanUnicastBasicTest
        ^switch_tests.L3EcmpLagTest
        ^switch_tests.L3VIIPv4HostMacMoveTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_ent_dc_general_set_1" ${SWITCH_P4}
    "${testExtraArgs} -DENT_DC_GENERAL_PROFILE -pd -to 3600" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_ent_dc_general_set_1"
        "switch_tests.L2LNStatsTest
        switch_tests.L2DynamicMacMoveTest
        switch_tests.L2StaticMacMoveBulkTest
        switch_tests.L2VxlanUnicastBasicTest
        switch_tests.L3EcmpLagTest
        switch_tests.L3VIIPv4HostMacMoveTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_ent_dc_general_egress_acl" ${SWITCH_P4}
        "${testExtraArgs} -DENT_DC_GENERAL_PROFILE -pd -to 3600" "${SWITCH_PTF_DIR_EGRESS_ACL}")

# 500s timeout is too little for compiling and testing the entire switch, bumping it up
set_tests_properties("tofino/smoketest_switch_ent_dc_general" PROPERTIES TIMEOUT 3600)
set_tests_properties("tofino/smoketest_switch_ent_dc_general_set_1" PROPERTIES TIMEOUT 3600)
set_tests_properties("tofino/smoketest_switch_ent_dc_general_egress_acl" PROPERTIES TIMEOUT 3600)

p4c_add_test_label("tofino" "UNSTABLE" "smoketest_switch_ent_dc_general_set_1")

# Additional testing (excluded in PRs and CI)
# Switch Master MSDC_IPV4_PROFILE tests
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_ipv4" ${SWITCH_P4}
    "${testExtraArgs} -DMSDC_IPV4_PROFILE -DP4_WRED_DEBUG -pd -to 3600" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_ipv4"
        "l2 l3 acl mirror l3-vxlan ^hostif ^tunnel ^aclfrag ^dynhash ^dynhash32
        ^urpf ^mpls ^mcast ^racl ^warminit ^stp
        ^switch_tests.MalformedPacketsTest
        ^switch_tests.ExceptionPacketsTest
        ^switch_tests.ExceptionPacketsTest_IPV6")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_ipv4_mirror" ${SWITCH_P4}
    "${testExtraArgs} -DMSDC_IPV4_PROFILE -DP4_WRED_DEBUG -pd -to 3600" "${SWITCH_PTF_DIR_MIRROR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_ipv4_mirror"
        "mirror_acl")

# 500s timeout is too little for compiling and testing the entire switch, bumping it up
set_tests_properties("tofino/smoketest_switch_ipv4" PROPERTIES TIMEOUT 3600)
set_tests_properties("tofino/smoketest_switch_ipv4_mirror" PROPERTIES TIMEOUT 3600)

# Switch Master MSDC_SPINE_DTEL_INT_PROFILE tests
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_dtel_int_spine" ${SWITCH_P4}
    "${testExtraArgs} -DMSDC_SPINE_DTEL_INT_PROFILE -pd -to 3600" "${SWITCH_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_dtel_int_spine"
        "all ^tunnel ^mpls ^urpf ^racl ^ipv6 ^mcast ^warminit ^stp ^ptp ^aclfrag ^dynhash32")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_dtel_int_spine_mirror" ${SWITCH_P4}
    "${testExtraArgs} -DMSDC_SPINE_DTEL_INT_PROFILE -pd -to 3600" "${SWITCH_PTF_DIR_MIRROR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_dtel_int_spine_mirror"
        "mirror_acl_slice_tests.MirrorAclSliceTest_i2e")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_dtel_int_spine_dtel" ${SWITCH_P4}
    "${testExtraArgs} -DMSDC_SPINE_DTEL_INT_PROFILE -pd -to 3600" "${SWITCH_PTF_DIR_DTEL}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_dtel_int_spine_dtel"
        "switch_int_l45_common.intl45_route_dtel_reports
        switch_int_l45_transit_digest.intl45_transitTest_hop2_with_digest
        switch_int_l45_transit.intl45_DSCP_TransitTest
        switch_int_l45_transit.INTL45_Marker_TransitTest
        switch_int_l45_transit.intl45_transitTest_Ebit
        switch_int_l45_transit.INTL45_TransitTest_Enable
        switch_int_l45_transit.intl45_transitTest_hop2_latency")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_dtel_int_spine_dtel_part_2" ${SWITCH_P4}
    "${testExtraArgs} -DMSDC_SPINE_DTEL_INT_PROFILE -pd -to 3600" "${SWITCH_PTF_DIR_DTEL}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_dtel_int_spine_dtel_part_2"
        "switch_int_l45_transit.intl45_transitTest_hop2_port_ids
        switch_int_l45_transit.intl45_transitTest_hop2_qdepth
        switch_int_l45_transit.intl45_transitTest_hop2_txutil_yet_supported
        switch_int_l45_transit.intl45_transitTest_latency_shift
        switch_int_l45_transit.intl45_transitTest_Metadata
        switch_int_l45_transit.intl45_transitTest_switchid
        switch_queue_report.QueueReport_Change_Test")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_dtel_int_spine_dtel_INTL45" ${SWITCH_P4}
    "${testExtraArgs} -DMSDC_SPINE_DTEL_INT_PROFILE -pd -to 3600" "${SWITCH_PTF_DIR_DTEL}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_dtel_int_spine_dtel_INTL45"
        "switch_int_l45_transit.INTL45_Transit_EgressMoDTest
         switch_int_l45_transit.INTL45_Transit_IngressMoDTest
         switch_int_l45_transit_stless.intl45_transitTest_hop2_stateless")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_dtel_int_spine_dtel_QueueReport" ${SWITCH_P4}
    "${testExtraArgs} -DMSDC_SPINE_DTEL_INT_PROFILE -pd -to 3600" "${SWITCH_PTF_DIR_DTEL}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_dtel_int_spine_dtel_QueueReport"
        "switch_queue_report.QueueReport_Entropy_Test
         switch_queue_report.QueueReport_Quota_Test
         switch_queue_report_multimirror.QueueReport_Over_ECMP_Test
         switch_queue_report_multimirror.QueueReport_MirrorTest
         switch_queue_report_multimirror.QueueReport_L2_MirrorTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_dtel_int_spine_dtel_MirrorOnDrop" ${SWITCH_P4}
    "${testExtraArgs} -DMSDC_SPINE_DTEL_INT_PROFILE -pd -to 3600" "${SWITCH_PTF_DIR_DTEL}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_dtel_int_spine_dtel_MirrorOnDrop"
        "switch_mirror_on_drop.MirrorOnDropEgrNonDefaultRuleTest
         switch_mirror_on_drop.MirrorOnDropHostifReasonCodeTest
         switch_mirror_on_drop.MirrorOnDropIngressAclTest
         switch_mirror_on_drop.MirrorOnDropNonDefaultRuleTest
         switch_mirror_on_drop.MirrorOnDropEgressAclTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_dtel_int_spine_dtel_INTL45_Transit_DoDTest" ${SWITCH_P4}
    "${testExtraArgs} -DMSDC_SPINE_DTEL_INT_PROFILE -pd -to 3600" "${SWITCH_PTF_DIR_DTEL}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_dtel_int_spine_dtel_INTL45_Transit_DoDTest"
    "switch_int_l45_transit.INTL45_Transit_DoDTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_dtel_int_spine_dtel_QueueReport_DoD_Test" ${SWITCH_P4}
    "${testExtraArgs} -DMSDC_SPINE_DTEL_INT_PROFILE -pd -to 3600" "${SWITCH_PTF_DIR_DTEL}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_dtel_int_spine_dtel_QueueReport_DoD_Test"
    "switch_queue_report.QueueReport_DoD_Test")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_dtel_int_spine_dtel_MirrorOnDropDoDTest" ${SWITCH_P4}
    "${testExtraArgs} -DMSDC_SPINE_DTEL_INT_PROFILE -pd -to 3600" "${SWITCH_PTF_DIR_DTEL}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_dtel_int_spine_dtel_MirrorOnDropDoDTest"
    "switch_mirror_on_drop.MirrorOnDropDoDTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_dtel_int_spine_dtel_sai" ${SWITCH_P4}
    "${testExtraArgs} -DMSDC_SPINE_DTEL_INT_PROFILE -pd -to 3600" "${SWITCH_PTF_DIR_SAI_DTEL}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_dtel_int_spine_dtel_sai"
        "int_transit")
bfn_set_ptf_port_map_file("tofino" "smoketest_switch_dtel_int_spine_dtel_sai"
    "${SWITCH_PTF_DIR_SAI}/port_map.ini")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_dtel_int_spine_sai" ${SWITCH_P4}
    "${testExtraArgs} -DMSDC_SPINE_DTEL_INT_PROFILE -pd -to 3600" "${SWITCH_PTF_DIR_SAI}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_dtel_int_spine_sai"
        "egress-acl mirror-acl")
bfn_set_ptf_port_map_file("tofino" "smoketest_switch_dtel_int_spine_sai"
    "${SWITCH_PTF_DIR_SAI}/port_map.ini")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_dtel_int_spine_sai_hostif" ${SWITCH_P4}
    "${testExtraArgs} -DMSDC_SPINE_DTEL_INT_PROFILE -pd -to 3600" "${SWITCH_PTF_DIR_SAI}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_dtel_int_spine_sai_hostif"
        "saihostif.CoppStatTest")
bfn_set_ptf_port_map_file("tofino" "smoketest_switch_dtel_int_spine_sai_hostif"
    "${SWITCH_PTF_DIR_SAI}/port_map.ini")
bfn_set_ptf_test_port("tofino" "smoketest_switch_dtel_int_spine_sai_hostif"
    "3")

# 500s timeout is too little for compiling and testing the entire switch, bumping it up
set_tests_properties("tofino/smoketest_switch_dtel_int_spine" PROPERTIES TIMEOUT 3600)
set_tests_properties("tofino/smoketest_switch_dtel_int_spine_mirror" PROPERTIES TIMEOUT 3600)
set_tests_properties("tofino/smoketest_switch_dtel_int_spine_dtel" PROPERTIES TIMEOUT 3600)
set_tests_properties("tofino/smoketest_switch_dtel_int_spine_dtel_part_2" PROPERTIES TIMEOUT 3600)
set_tests_properties("tofino/smoketest_switch_dtel_int_spine_dtel_INTL45" PROPERTIES TIMEOUT 3600)
set_tests_properties("tofino/smoketest_switch_dtel_int_spine_dtel_QueueReport" PROPERTIES TIMEOUT 3600)
set_tests_properties("tofino/smoketest_switch_dtel_int_spine_dtel_MirrorOnDrop" PROPERTIES TIMEOUT 3600)
set_tests_properties("tofino/smoketest_switch_dtel_int_spine_dtel_INTL45_Transit_DoDTest" PROPERTIES TIMEOUT 3600)
set_tests_properties("tofino/smoketest_switch_dtel_int_spine_dtel_QueueReport_DoD_Test" PROPERTIES TIMEOUT 3600)
set_tests_properties("tofino/smoketest_switch_dtel_int_spine_dtel_MirrorOnDropDoDTest" PROPERTIES TIMEOUT 3600)
set_tests_properties("tofino/smoketest_switch_dtel_int_spine_dtel_sai" PROPERTIES TIMEOUT 3600)
set_tests_properties("tofino/smoketest_switch_dtel_int_spine_sai" PROPERTIES TIMEOUT 3600)
set_tests_properties("tofino/smoketest_switch_dtel_int_spine_sai_hostif" PROPERTIES TIMEOUT 3600)

# Switch Rel 8.7 MSDC_PROFILE tests
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_${SWITCH_VERSION}_msdc" ${SWITCH_${SWITCH_VERSION}_P4}
    "${testExtraArgs} -DMSDC_PROFILE -DP4_WRED_DEBUG -pd -to 3600" "${SWITCH_${SWITCH_VERSION}_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_${SWITCH_VERSION}_msdc"
        "switch_acl.AclLabelTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_${SWITCH_VERSION}_msdc_set_1" ${SWITCH_${SWITCH_VERSION}_P4}
    "${testExtraArgs} -DMSDC_PROFILE -DP4_WRED_DEBUG -pd -to 3600" "${SWITCH_${SWITCH_VERSION}_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_${SWITCH_VERSION}_msdc_set_1"
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
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_${SWITCH_VERSION}_msdc_set_2" ${SWITCH_${SWITCH_VERSION}_P4}
    "${testExtraArgs} -DMSDC_PROFILE -DP4_WRED_DEBUG -pd -to 3600" "${SWITCH_${SWITCH_VERSION}_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_${SWITCH_VERSION}_msdc_set_2"
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
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_${SWITCH_VERSION}_msdc_set_3" ${SWITCH_${SWITCH_VERSION}_P4}
    "${testExtraArgs} -DMSDC_PROFILE -DP4_WRED_DEBUG -pd -to 3600" "${SWITCH_${SWITCH_VERSION}_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_${SWITCH_VERSION}_msdc_set_3"
        "switch_tests.L2DynamicLearnAgeTest
        switch_tests.L2DynamicMacLearnTest
        switch_tests.L2FloodTest
        switch_tests.L2LagTest
        switch_tests.L2MacLearnTest
        switch_tests.L2StaticMacBulkDeleteTest
        switch_tests.L2StaticMacMoveTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_${SWITCH_VERSION}_msdc_set_4" ${SWITCH_${SWITCH_VERSION}_P4}
    "${testExtraArgs} -DMSDC_PROFILE -DP4_WRED_DEBUG -pd -to 3600" "${SWITCH_${SWITCH_VERSION}_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_${SWITCH_VERSION}_msdc_set_4"
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
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_${SWITCH_VERSION}_msdc_set_5" ${SWITCH_${SWITCH_VERSION}_P4}
    "${testExtraArgs} -DMSDC_PROFILE -DP4_WRED_DEBUG -pd -to 3600" "${SWITCH_${SWITCH_VERSION}_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_${SWITCH_VERSION}_msdc_set_5"
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
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_${SWITCH_VERSION}_msdc_set_6" ${SWITCH_${SWITCH_VERSION}_P4}
    "${testExtraArgs} -DMSDC_PROFILE -DP4_WRED_DEBUG -pd -to 3600" "${SWITCH_${SWITCH_VERSION}_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_${SWITCH_VERSION}_msdc_set_6"
        "switch_tests.L3VIIPv4HostFloodTest
        switch_tests.L3VIIPv4HostMacMoveTest
        switch_tests.L3VIIPv4HostTest
        switch_tests.L3VIIPv4HostVlanTaggingTest
        switch_tests.L3VIIPv4LagTest
        switch_tests.L3VIIPv6HostTest
        switch_tests.L3VINhopGleanTest
        switch_tests.MalformedPacketsTest_ipv6")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_${SWITCH_VERSION}_msdc_set_7" ${SWITCH_${SWITCH_VERSION}_P4}
        "${testExtraArgs} -DMSDC_PROFILE -DP4_WRED_DEBUG -pd -to 3600" "${SWITCH_${SWITCH_VERSION}_PTF_DIR_MIRROR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_${SWITCH_VERSION}_msdc_set_7"
        "mirror_acl_slice_tests.IPv6MirrorAclSliceTest_i2e
        mirror_acl_slice_tests.MirrorAclSliceTest_i2e")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_${SWITCH_VERSION}_msdc_MalformedPacketsTest" ${SWITCH_${SWITCH_VERSION}_P4}
    "${testExtraArgs} -DMSDC_PROFILE -DP4_WRED_DEBUG -pd -to 3600" "${SWITCH_${SWITCH_VERSION}_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_${SWITCH_VERSION}_msdc_MalformedPacketsTest"
        "switch_tests.MalformedPacketsTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_${SWITCH_VERSION}_msdc_set_8" ${SWITCH_${SWITCH_VERSION}_P4}
    "${testExtraArgs} -DMSDC_PROFILE -DP4_WRED_DEBUG -pd -to 3600" "${SWITCH_${SWITCH_VERSION}_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_${SWITCH_VERSION}_msdc_set_8"
        "switch_tests.L2DynamicMacMoveTest
        switch_tests.L2LNStatsTest
        switch_tests.L2StaticMacMoveBulkTest")

# 500s timeout is too little for compiling and testing the entire switch, bumping it up
set_tests_properties("tofino/smoketest_switch_${SWITCH_VERSION}_msdc" PROPERTIES TIMEOUT 3600)
set_tests_properties("tofino/smoketest_switch_${SWITCH_VERSION}_msdc_set_1" PROPERTIES TIMEOUT 3600)
set_tests_properties("tofino/smoketest_switch_${SWITCH_VERSION}_msdc_set_2" PROPERTIES TIMEOUT 3600)
set_tests_properties("tofino/smoketest_switch_${SWITCH_VERSION}_msdc_set_3" PROPERTIES TIMEOUT 3600)
set_tests_properties("tofino/smoketest_switch_${SWITCH_VERSION}_msdc_set_4" PROPERTIES TIMEOUT 3600)
set_tests_properties("tofino/smoketest_switch_${SWITCH_VERSION}_msdc_set_5" PROPERTIES TIMEOUT 3600)
set_tests_properties("tofino/smoketest_switch_${SWITCH_VERSION}_msdc_set_6" PROPERTIES TIMEOUT 3600)
set_tests_properties("tofino/smoketest_switch_${SWITCH_VERSION}_msdc_set_7" PROPERTIES TIMEOUT 3600)
set_tests_properties("tofino/smoketest_switch_${SWITCH_VERSION}_msdc_set_8" PROPERTIES TIMEOUT 3600)
set_tests_properties("tofino/smoketest_switch_${SWITCH_VERSION}_msdc_MalformedPacketsTest" PROPERTIES TIMEOUT 3600)

p4c_add_test_label("tofino" "UNSTABLE" "smoketest_switch_${SWITCH_VERSION}_msdc_set_8")

# Switch Rel 8.7 ENT_DC_GENERAL_PROFILE tests
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_${SWITCH_VERSION}_ent_dc_general" ${SWITCH_${SWITCH_VERSION}_P4}
    "${testExtraArgs} -DENT_DC_GENERAL_PROFILE -pd -to 3600" "${SWITCH_${SWITCH_VERSION}_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_${SWITCH_VERSION}_ent_dc_general"
        "switch_acl.AclLabelTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_${SWITCH_VERSION}_ent_dc_general_set_1" ${SWITCH_${SWITCH_VERSION}_P4}
    "${testExtraArgs} -DENT_DC_GENERAL_PROFILE -pd -to 3600" "${SWITCH_${SWITCH_VERSION}_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_${SWITCH_VERSION}_ent_dc_general_set_1"
        "switch_acl.IPAclStatsTest
        switch_acl.IPAclTest
        switch_acl.IPIngressAclRangeTcamTest
        switch_acl.MirrorAclTest_i2e
        switch_acl.MirrorSessionTest
        switch_mirror.MirrorPortTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_${SWITCH_VERSION}_ent_dc_general_set_2" ${SWITCH_${SWITCH_VERSION}_P4}
    "${testExtraArgs} -DENT_DC_GENERAL_PROFILE -pd -to 3600" "${SWITCH_${SWITCH_VERSION}_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_${SWITCH_VERSION}_ent_dc_general_set_2"
        "switch_tests.CpuTxTest
        switch_tests.L2AccessToAccessVlanTest
        switch_tests.L2AccessToTrunkVlanJumboTest
        switch_tests.L2AccessToTrunkVlanTest
        switch_tests.L2AgingTest
        switch_tests.L2DynamicLearnAgeTest
        switch_tests.L2DynamicMacLearnTest
        switch_tests.L2FloodTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_${SWITCH_VERSION}_ent_dc_general_set_3" ${SWITCH_${SWITCH_VERSION}_P4}
    "${testExtraArgs} -DENT_DC_GENERAL_PROFILE -pd -to 3600" "${SWITCH_${SWITCH_VERSION}_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_${SWITCH_VERSION}_ent_dc_general_set_3"
        "switch_tests.L2LNSubIntfEncapTest
        switch_tests.L2LagFloodTest
        switch_tests.L2LagTest
        switch_tests.L2MacLearnTest
        switch_tests.L2StaticMacBulkDeleteTest
        switch_tests.L2StaticMacMoveTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_${SWITCH_VERSION}_ent_dc_general_set_4" ${SWITCH_${SWITCH_VERSION}_P4}
    "${testExtraArgs} -DENT_DC_GENERAL_PROFILE -pd -to 3600" "${SWITCH_${SWITCH_VERSION}_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_${SWITCH_VERSION}_ent_dc_general_set_4"
        "switch_tests.L2TrunkToAccessVlanTest
        switch_tests.L2TrunkToTrunkVlanTest
        switch_tests.L2VlanStatsTest
        switch_tests.L2VxlanArpUnicastBasicTest
        switch_tests.L2VxlanFloodBasicTest
        switch_tests.L2VxlanLearnBasicTest
        switch_tests.L2VxlanUnicastLagBasicTest
        switch_tests.L3IPv4EcmpTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_${SWITCH_VERSION}_ent_dc_general_set_5" ${SWITCH_${SWITCH_VERSION}_P4}
    "${testExtraArgs} -DENT_DC_GENERAL_PROFILE -pd -to 3600" "${SWITCH_${SWITCH_VERSION}_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_${SWITCH_VERSION}_ent_dc_general_set_5"
        "switch_tests.L3IPv4HostJumboTest
        switch_tests.L3IPv4HostModifyTest
        switch_tests.L3IPv4HostTest
        switch_tests.L3IPv4LagTest
        switch_tests.L3IPv4LookupTest
        switch_tests.L3IPv4LpmTest
        switch_tests.L3IPv4SubIntfHostTest
        switch_tests.L3IPv6EcmpTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_${SWITCH_VERSION}_ent_dc_general_set_6" ${SWITCH_${SWITCH_VERSION}_P4}
    "${testExtraArgs} -DENT_DC_GENERAL_PROFILE -pd -to 3600" "${SWITCH_${SWITCH_VERSION}_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_${SWITCH_VERSION}_ent_dc_general_set_6"
        "switch_tests.L3IPv6HostTest
        switch_tests.L3IPv6LagTest
        switch_tests.L3IPv6LookupTest
        switch_tests.L3IPv6LpmTest
        switch_tests.L3VIFloodTest
        switch_tests.L3VIIPv4HostFloodTest
        switch_tests.L3VIIPv4HostTest
        switch_tests.L3VIIPv4HostVlanTaggingTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_${SWITCH_VERSION}_ent_dc_general_set_7" ${SWITCH_${SWITCH_VERSION}_P4}
    "${testExtraArgs} -DENT_DC_GENERAL_PROFILE -pd -to 3600" "${SWITCH_${SWITCH_VERSION}_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_${SWITCH_VERSION}_ent_dc_general_set_7"
        "switch_tests.L3VIIPv4LagTest
        switch_tests.L3VIIPv6HostTest
        switch_tunnel.L3VxlanUnicastTunnelECMPLagReflectionSMTest
        switch_tunnel.L3VxlanUnicastTunnelSMSVITest
        switch_tests.L3IPv4LpmEcmpTest
        switch_tests.L3IPv6LpmEcmpTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_${SWITCH_VERSION}_ent_dc_general_set_8" ${SWITCH_${SWITCH_VERSION}_P4}
    "${testExtraArgs} -DENT_DC_GENERAL_PROFILE -pd -to 3600" "${SWITCH_${SWITCH_VERSION}_PTF_DIR_EGRESS_ACL}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_${SWITCH_VERSION}_ent_dc_general_set_8"
        "switch_api_tests.IPEgressAclRangeTcamTest
        switch_api_tests.IPEgressAclTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_${SWITCH_VERSION}_ent_dc_general_set_9" ${SWITCH_${SWITCH_VERSION}_P4}
    "${testExtraArgs} -DENT_DC_GENERAL_PROFILE -pd -to 3600" "${SWITCH_${SWITCH_VERSION}_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_${SWITCH_VERSION}_ent_dc_general_set_9"
        "switch_tests.L2LNStatsTest
        switch_tests.L2DynamicMacMoveTest
        switch_tests.L2StaticMacMoveBulkTest
        switch_tests.L2VxlanUnicastBasicTest
        switch_tests.L3EcmpLagTest
        switch_tests.L3VIIPv4HostMacMoveTest")

# 500s timeout is too little for compiling and testing the entire switch, bumping it up
set_tests_properties("tofino/smoketest_switch_${SWITCH_VERSION}_ent_dc_general" PROPERTIES TIMEOUT 3600)
set_tests_properties("tofino/smoketest_switch_${SWITCH_VERSION}_ent_dc_general_set_1" PROPERTIES TIMEOUT 3600)
set_tests_properties("tofino/smoketest_switch_${SWITCH_VERSION}_ent_dc_general_set_2" PROPERTIES TIMEOUT 3600)
set_tests_properties("tofino/smoketest_switch_${SWITCH_VERSION}_ent_dc_general_set_3" PROPERTIES TIMEOUT 3600)
set_tests_properties("tofino/smoketest_switch_${SWITCH_VERSION}_ent_dc_general_set_4" PROPERTIES TIMEOUT 3600)
set_tests_properties("tofino/smoketest_switch_${SWITCH_VERSION}_ent_dc_general_set_5" PROPERTIES TIMEOUT 3600)
set_tests_properties("tofino/smoketest_switch_${SWITCH_VERSION}_ent_dc_general_set_6" PROPERTIES TIMEOUT 3600)
set_tests_properties("tofino/smoketest_switch_${SWITCH_VERSION}_ent_dc_general_set_7" PROPERTIES TIMEOUT 3600)
set_tests_properties("tofino/smoketest_switch_${SWITCH_VERSION}_ent_dc_general_set_8" PROPERTIES TIMEOUT 3600)
set_tests_properties("tofino/smoketest_switch_${SWITCH_VERSION}_ent_dc_general_set_9" PROPERTIES TIMEOUT 3600)

p4c_add_test_label("tofino" "UNSTABLE" "smoketest_switch_${SWITCH_VERSION}_ent_dc_general_set_9")

# Switch Rel 8.7 DC_BASIC_PROFILE_BRIG tests
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_${SWITCH_VERSION}_dc_basic" ${SWITCH_${SWITCH_VERSION}_P4}
    "${testExtraArgs} -DDC_BASIC_PROFILE -pd -to 3600" "${SWITCH_${SWITCH_VERSION}_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_${SWITCH_VERSION}_dc_basic"
        "switch_acl.AclLabelTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_${SWITCH_VERSION}_dc_basic_set_1" ${SWITCH_${SWITCH_VERSION}_P4}
    "${testExtraArgs} -DDC_BASIC_PROFILE -pd -to 3600" "${SWITCH_${SWITCH_VERSION}_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_${SWITCH_VERSION}_dc_basic_set_1"
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
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_${SWITCH_VERSION}_dc_basic_set_2" ${SWITCH_${SWITCH_VERSION}_P4}
    "${testExtraArgs} -DDC_BASIC_PROFILE -pd -to 3600" "${SWITCH_${SWITCH_VERSION}_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_${SWITCH_VERSION}_dc_basic_set_2"
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
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_${SWITCH_VERSION}_dc_basic_set_3" ${SWITCH_${SWITCH_VERSION}_P4}
    "${testExtraArgs} -DDC_BASIC_PROFILE -pd -to 3600" "${SWITCH_${SWITCH_VERSION}_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_${SWITCH_VERSION}_dc_basic_set_3"
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
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_${SWITCH_VERSION}_dc_basic_set_4" ${SWITCH_${SWITCH_VERSION}_P4}
    "${testExtraArgs} -DDC_BASIC_PROFILE -pd -to 3600" "${SWITCH_${SWITCH_VERSION}_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_${SWITCH_VERSION}_dc_basic_set_4"
        "switch_tests.ExceptionPacketsTest
        switch_tests.ExceptionPacketsTest_IPV6
        switch_tests.HostIfTest
        switch_tests.HostIfV6Test
        switch_tests.IPNeighborTest
        switch_tests.IPv4inIPv4Test
        switch_tests.IPv4inIPv6Test
        switch_tests.IPv6inIPv4Test
        switch_tests.IPv6inIPv6Test")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_${SWITCH_VERSION}_dc_basic_set_5" ${SWITCH_${SWITCH_VERSION}_P4}
    "${testExtraArgs} -DDC_BASIC_PROFILE -pd -to 3600" "${SWITCH_${SWITCH_VERSION}_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_${SWITCH_VERSION}_dc_basic_set_5"
        "switch_tests.L2AccessToAccessVlanTest
        switch_tests.L2AccessToTrunkPriorityTaggingTest
        switch_tests.L2AccessToTrunkVlanJumboTest
        switch_tests.L2AccessToTrunkVlanTest
        switch_tests.L2AgingTest
        switch_tests.L2DynamicLearnAgeTest
        switch_tests.L2DynamicMacLearnTest
        switch_tests.L2FloodTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_${SWITCH_VERSION}_dc_basic_set_6" ${SWITCH_${SWITCH_VERSION}_P4}
    "${testExtraArgs} -DDC_BASIC_PROFILE -pd -to 3600" "${SWITCH_${SWITCH_VERSION}_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_${SWITCH_VERSION}_dc_basic_set_6"
        "switch_tests.L2GeneveUnicastBasicTest
        switch_tests.L2GeneveUnicastLagBasicTest
        switch_tests.L2LNSubIntfEncapTest
        switch_tests.L2LagFloodTest
        switch_tests.L2LagTest
        switch_tests.L2MacLearnTest
        switch_tests.L2MplsPopTest
        switch_tests.L2MplsPushJumboTest
        switch_tests.L2MplsPushTest
        switch_tests.L2MplsSwapTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_${SWITCH_VERSION}_dc_basic_set_7" ${SWITCH_${SWITCH_VERSION}_P4}
    "${testExtraArgs} -DDC_BASIC_PROFILE -pd -to 3600" "${SWITCH_${SWITCH_VERSION}_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_${SWITCH_VERSION}_dc_basic_set_7"
        "switch_tests.L2NvgreUnicastLagBasicTest
        switch_tests.L2StaticMacBulkDeleteTest
        switch_tests.L2StaticMacMoveTest
        switch_tests.L2StpEgressBlockingTest
        switch_tests.L2StpTest
        switch_tests.L2TrunkToAccessVlanTest
        switch_tests.L2TrunkToTrunkVlanTest
        switch_tests.L2TunnelFloodEnhancedTest
        switch_tests.L2TunnelSplicingExtreme1Test
        switch_tests.L2TunnelSplicingExtreme2Test")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_${SWITCH_VERSION}_dc_basic_set_8" ${SWITCH_${SWITCH_VERSION}_P4}
    "${testExtraArgs} -DDC_BASIC_PROFILE -pd -to 3600" "${SWITCH_${SWITCH_VERSION}_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_${SWITCH_VERSION}_dc_basic_set_8"
        "switch_tests.L2VlanStatsTest
        switch_tests.L2VxlanArpUnicastBasicTest
        switch_tests.L2VxlanFloodBasicTest
        switch_tests.L2VxlanLearnBasicTest
        switch_tests.L2VxlanToGeneveUnicastEnhancedTest
        switch_tests.L2VxlanToGeneveUnicastLagBasicTest
        switch_tests.L2VxlanToGeneveUnicastLagEnhancedTest
        switch_tests.L2VxlanUnicastBasicTest
        switch_tests.L2VxlanUnicastLagBasicTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_${SWITCH_VERSION}_dc_basic_set_9" ${SWITCH_${SWITCH_VERSION}_P4}
    "${testExtraArgs} -DDC_BASIC_PROFILE -pd -to 3600" "${SWITCH_${SWITCH_VERSION}_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_${SWITCH_VERSION}_dc_basic_set_9"
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
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_${SWITCH_VERSION}_dc_basic_set_10" ${SWITCH_${SWITCH_VERSION}_P4}
    "${testExtraArgs} -DDC_BASIC_PROFILE -pd -to 3600" "${SWITCH_${SWITCH_VERSION}_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_${SWITCH_VERSION}_dc_basic_set_10"
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
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_${SWITCH_VERSION}_dc_basic_set_11" ${SWITCH_${SWITCH_VERSION}_P4}
    "${testExtraArgs} -DDC_BASIC_PROFILE -pd -to 3600" "${SWITCH_${SWITCH_VERSION}_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_${SWITCH_VERSION}_dc_basic_set_11"
        "switch_tests.L3VIIPv4LagTest
        switch_tests.L3VIIPv6HostTest
        switch_tests.L3VINhopGleanBGPTest
        switch_tests.L3VINhopGleanTest
        switch_tunnel.L3VxlanUnicastMultiTunnelSMTest
        switch_tunnel.L3VxlanUnicastTunnelECMPLagReflectionSMTest
        switch_tunnel.L3VxlanUnicastTunnelECMPSMTest
        switch_tunnel.L3VxlanUnicastTunnelSMSVITest
        switch_tunnel.L3VxlanUnicastTunnelSMTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_${SWITCH_VERSION}_dc_basic_MalformedPacketsTest" ${SWITCH_${SWITCH_VERSION}_P4}
    "${testExtraArgs} -DDC_BASIC_PROFILE -pd -to 3600" "${SWITCH_${SWITCH_VERSION}_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_${SWITCH_VERSION}_dc_basic_MalformedPacketsTest"
        "switch_tests.MalformedPacketsTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_${SWITCH_VERSION}_dc_basic_MalformedPacketsTest_ipv6" ${SWITCH_${SWITCH_VERSION}_P4}
    "${testExtraArgs} -DDC_BASIC_PROFILE -pd -to 3600" "${SWITCH_${SWITCH_VERSION}_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_${SWITCH_VERSION}_dc_basic_MalformedPacketsTest_ipv6"
        "switch_tests.MalformedPacketsTest_ipv6")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_${SWITCH_VERSION}_dc_basic_MalformedPacketsTest_tunnel" ${SWITCH_${SWITCH_VERSION}_P4}
    "${testExtraArgs} -DDC_BASIC_PROFILE -pd -to 3600" "${SWITCH_${SWITCH_VERSION}_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_${SWITCH_VERSION}_dc_basic_MalformedPacketsTest_tunnel"
        "switch_tests.MalformedPacketsTest_tunnel")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_${SWITCH_VERSION}_dc_basic_set_12" ${SWITCH_${SWITCH_VERSION}_P4}
    "${testExtraArgs} -DDC_BASIC_PROFILE -pd -to 3600" "${SWITCH_${SWITCH_VERSION}_PTF_DIR}")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_${SWITCH_VERSION}_dc_basic_set_12"
        "switch_tests.L2DynamicMacMoveTest
        switch_tests.L2IPv4InIPv6VxlanUnicastBasicTest
        switch_tests.L2LNStatsTest
        switch_tests.L2StaticMacMoveBulkTest
        switch_tests.L2VxlanToGeneveUnicastBasicTest")

set_tests_properties("tofino/smoketest_switch_${SWITCH_VERSION}_dc_basic" PROPERTIES TIMEOUT 3600)
set_tests_properties("tofino/smoketest_switch_${SWITCH_VERSION}_dc_basic_set_1" PROPERTIES TIMEOUT 3600)
set_tests_properties("tofino/smoketest_switch_${SWITCH_VERSION}_dc_basic_set_2" PROPERTIES TIMEOUT 3600)
set_tests_properties("tofino/smoketest_switch_${SWITCH_VERSION}_dc_basic_set_3" PROPERTIES TIMEOUT 3600)
set_tests_properties("tofino/smoketest_switch_${SWITCH_VERSION}_dc_basic_set_4" PROPERTIES TIMEOUT 3600)
set_tests_properties("tofino/smoketest_switch_${SWITCH_VERSION}_dc_basic_set_5" PROPERTIES TIMEOUT 3600)
set_tests_properties("tofino/smoketest_switch_${SWITCH_VERSION}_dc_basic_set_6" PROPERTIES TIMEOUT 3600)
set_tests_properties("tofino/smoketest_switch_${SWITCH_VERSION}_dc_basic_set_7" PROPERTIES TIMEOUT 3600)
set_tests_properties("tofino/smoketest_switch_${SWITCH_VERSION}_dc_basic_set_8" PROPERTIES TIMEOUT 3600)
set_tests_properties("tofino/smoketest_switch_${SWITCH_VERSION}_dc_basic_set_9" PROPERTIES TIMEOUT 3600)
set_tests_properties("tofino/smoketest_switch_${SWITCH_VERSION}_dc_basic_set_10" PROPERTIES TIMEOUT 3600)
set_tests_properties("tofino/smoketest_switch_${SWITCH_VERSION}_dc_basic_set_11" PROPERTIES TIMEOUT 3600)
set_tests_properties("tofino/smoketest_switch_${SWITCH_VERSION}_dc_basic_set_12" PROPERTIES TIMEOUT 3600)
set_tests_properties("tofino/smoketest_switch_${SWITCH_VERSION}_dc_basic_MalformedPacketsTest" PROPERTIES TIMEOUT 3600)
set_tests_properties("tofino/smoketest_switch_${SWITCH_VERSION}_dc_basic_MalformedPacketsTest_ipv6" PROPERTIES TIMEOUT 3600)
set_tests_properties("tofino/smoketest_switch_${SWITCH_VERSION}_dc_basic_MalformedPacketsTest_tunnel" PROPERTIES TIMEOUT 3600)

p4c_add_test_label("tofino" "UNSTABLE" "smoketest_switch_${SWITCH_VERSION}_dc_basic_set_12")

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
