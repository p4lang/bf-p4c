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
# FIXME: remove disabling of parser min/max depth limits (P4C-4170)
p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} FALSE
    "switch_dc_basic" ${switchtest} "${testExtraArgs}" "-arch ${TOFINO_P414_TEST_ARCH} --disable-pragmas=pa_solitary -DDC_BASIC_PROFILE -Xp4c=\"--disable-parse-max-depth-limit\"")
p4c_add_test_label("tofino" "METRICS" "switch_dc_basic")
p4c_add_test_label("tofino" "p414_nightly" "switch_dc_basic")

# FIXME: remove disabling of parser min/max depth limits (P4C-4170)
p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} FALSE
    "switch_ent_fin_postcard" ${switchtest} "${testExtraArgs}" "-arch ${TOFINO_P414_TEST_ARCH} -DENT_FIN_POSTCARD_PROFILE -Xp4c=\"--disable-parse-max-depth-limit\"")
p4c_add_test_label("tofino" "p414_nightly" "switch_ent_fin_postcard")

# FIXME: remove disabling of parser min/max depth limits (P4C-4170)
p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} FALSE
    "switch_ent_dc_general" ${switchtest} "${testExtraArgs}" "-arch ${TOFINO_P414_TEST_ARCH} -DENT_DC_GENERAL_PROFILE -to 1200 -Xp4c=\"--disable-parse-max-depth-limit\"")
p4c_add_test_label("tofino" "METRICS" "switch_ent_dc_general")
p4c_add_test_label("tofino" "p414_nightly" "switch_ent_dc_general")

# FIXME: remove disabling of parser min/max depth limits (P4C-4170)
p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} FALSE
    "switch_msdc" ${switchtest} "${testExtraArgs}" "-arch ${TOFINO_P414_TEST_ARCH} --disable-pragmas=pa_solitary -DMSDC_PROFILE -DP4_WRED_DEBUG -Xp4c=\"--disable-parse-max-depth-limit\"")
p4c_add_test_label("tofino" "METRICS" "switch_msdc")
p4c_add_test_label("tofino" "p414_nightly" "switch_msdc")

p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} FALSE}
    "switch_msdc_ipv4" ${switchtest} "${testExtraArgs}" "-arch ${TOFINO_P414_TEST_ARCH} --disable-pragmas=pa_solitary -DMSDC_IPV4_PROFILE")
p4c_add_test_label("tofino" "METRICS" "switch_msdc_ipv4")
p4c_add_test_label("tofino" "p414_nightly" "switch_msdc_ipv4")

# FIXME: remove disabling of parser min/max depth limits (P4C-4170)
p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} FALSE
    "switch_msdc_l3" ${switchtest} "${testExtraArgs}" "-arch ${TOFINO_P414_TEST_ARCH} -DMSDC_L3_PROFILE -Xp4c=\"--disable-parse-depth-limit\"")
p4c_add_test_label("tofino" "p414_nightly" "switch_msdc_l3")

# FIXME: remove disabling of parser min/max depth limits (P4C-4170)
p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} FALSE
    "switch_msdc_spine_int" ${switchtest} "${testExtraArgs}" "-arch ${TOFINO_P414_TEST_ARCH} --disable-pragmas=pa_solitary -DMSDC_SPINE_DTEL_INT_PROFILE -Xp4c=\"--disable-parse-depth-limit\"")
p4c_add_test_label("tofino" "METRICS" "switch_msdc_spine_int")
p4c_add_test_label("tofino" "p414_nightly" "switch_msdc_spine_int")

# FIXME: remove disabling of parser min/max depth limits (P4C-4170)
p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} FALSE
    "switch_msdc_leaf_int" ${switchtest} "${testExtraArgs}" "-arch ${TOFINO_P414_TEST_ARCH} -DMSDC_LEAF_DTEL_INT_PROFILE -Xp4c=\"--disable-parse-max-depth-limit\"")
p4c_add_test_label("tofino" "p414_nightly" "switch_msdc_leaf_int")

# FIXME: remove disabling of parser min/max depth limits (P4C-4170)
p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} FALSE
    "switch_l3_heavy_int_leaf" ${switchtest} "" "-arch ${TOFINO_P414_TEST_ARCH} -DL3_HEAVY_INT_LEAF_PROFILE -Xp4c=\"--disable-power-check --disable-parse-max-depth-limit\"")
p4c_add_test_label("tofino" "p414_nightly" "switch_l3_heavy_int_leaf")

# FIXME: remove disabling of parser min/max depth limits (P4C-4170)
p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} FALSE
    "switch_generic_int_leaf" ${switchtest} "" "-arch ${TOFINO_P414_TEST_ARCH} --disable-pragmas=pa_solitary -DGENERIC_INT_LEAF_PROFILE -to 2400 -Xp4c=\"--disable-power-check --disable-parse-max-depth-limit\"")
p4c_add_test_label("tofino" "p414_nightly" "switch_generic_int_leaf")

# 500s timeout is too little for compiling ent_dc_general profile, bumping it up
set_tests_properties("tofino/switch_ent_dc_general" PROPERTIES TIMEOUT 1200)
set_tests_properties("tofino/switch_generic_int_leaf" PROPERTIES TIMEOUT 2400)

# Switch P4-16
set (SWITCH_P4_16_ROOT ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/switch_16)
set (SWITCH_P4_16_INC ${SWITCH_P4_16_ROOT}/p4src/shared)
set (SWITCH_P4_16_PTF ${SWITCH_P4_16_ROOT}/ptf/api)

set (SWITCH_P4_16_X1 ${SWITCH_P4_16_ROOT}/p4src/switch-tofino/switch_tofino_x1.p4)
file (RELATIVE_PATH switch_p4_16_x1 ${P4C_SOURCE_DIR} ${SWITCH_P4_16_X1})
p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} FALSE
  "smoketest_switch_16_compile_x1_profile" ${switch_p4_16_x1} "" "-DX1_PROFILE -I${SWITCH_P4_16_INC} -Xp4c=\"--auto-init-metadata --disable-power-check\" -arch tna")
p4c_add_test_label("tofino" "METRICS" "smoketest_switch_16_compile_x1_profile")

set (SWITCH_P4_16_X2 ${SWITCH_P4_16_ROOT}/p4src/switch-tofino/switch_tofino_x2.p4)
file (RELATIVE_PATH switch_p4_16_x2 ${P4C_SOURCE_DIR} ${SWITCH_P4_16_X2})
p4c_add_test_with_args("tofino" ${P4C_RUNTEST} FALSE
  "smoketest_switch_16_compile_x2_profile" ${switch_p4_16_x2} "" "-DX2_PROFILE -I${SWITCH_P4_16_INC} -Xp4c=\"--auto-init-metadata --set-max-power 50\" -arch tna")
p4c_add_test_label("tofino" "METRICS" "smoketest_switch_16_compile_x2_profile")

set (SWITCH_P4_16_X3 ${SWITCH_P4_16_ROOT}/p4src/switch-tofino/switch_tofino_x3.p4)
file (RELATIVE_PATH switch_p4_16_x3 ${P4C_SOURCE_DIR} ${SWITCH_P4_16_X3})
p4c_add_test_with_args("tofino" ${P4C_RUNTEST} FALSE
  "smoketest_switch_16_compile_x3_profile" ${switch_p4_16_x3} "" "-DX3_PROFILE -I${SWITCH_P4_16_INC} -Xp4c=\"--auto-init-metadata\" -arch tna")
p4c_add_test_label("tofino" "METRICS" "smoketest_switch_16_compile_x3_profile")

# We cannot run some tests in our environment as some interfaces referenced in the port
# mapping file specified for bf-switch don't exist.
  p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_16_Tests_x1" ${SWITCH_P4_16_X1}
    "${testExtraArgs} -arch tna -bfrt -profile x1_tofino -to 7200" ${SWITCH_P4_16_PTF})
  bfn_set_ptf_test_spec("tofino" "smoketest_switch_16_Tests_x1"
         "all
         ^hash
         ^switch_l3.L3SVITest
         ^switch_l2.L2LagTest")
# FIXME: remove disabling of parser min/max depth limits (P4C-4170)
  p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_16_Tests_x2" ${SWITCH_P4_16_X2}
    "${testExtraArgs} -arch tna -bfrt -profile x2_tofino -to 7200 -Xp4c=\"--set-max-power 50 --disable-parse-depth-limit\"" ${SWITCH_P4_16_PTF})
  bfn_set_p4_build_flag("tofino" "smoketest_switch_16_Tests_x2" "-Xp4c=\"--disable-parse-depth-limit\"")
  bfn_set_ptf_test_spec("tofino" "smoketest_switch_16_Tests_x2"
         "all
         ^hash
         ^switch_l3.L3SVITest
         ^switch_l2.L2LagTest")
# All switch_16 tests should depend on the test being compiled, rather than
# relying on the first one to compile the test.
set_tests_properties(
  "tofino/smoketest_switch_16_Tests_x1"
  PROPERTIES DEPENDS "tofino/smoketest_switch_16_compile_x1_profile"
  )
set_tests_properties(
  "tofino/smoketest_switch_16_Tests_x2"
  PROPERTIES DEPENDS "tofino/smoketest_switch_16_compile_x2_profile"
  )

# 500s timeout is too little for compiling and testing the entire switch, bumping it up
set_tests_properties("tofino/smoketest_switch_16_compile_x1_profile" PROPERTIES TIMEOUT 1200)
set_tests_properties("tofino/smoketest_switch_16_compile_x2_profile" PROPERTIES TIMEOUT 1200)
set_tests_properties("tofino/smoketest_switch_16_compile_x3_profile" PROPERTIES TIMEOUT 1200)
set_tests_properties("tofino/smoketest_switch_16_Tests_x1" PROPERTIES TIMEOUT 7300)
set_tests_properties("tofino/smoketest_switch_16_Tests_x2" PROPERTIES TIMEOUT 7300)

# Switch master MSDC_PROFILE tests
# FIXME: remove disabling of parser min/max depth limits (P4C-4170)
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_msdc" ${SWITCH_P4}
    "${testExtraArgs} -arch ${TOFINO_P414_TEST_ARCH} -DMSDC_PROFILE -DP4_WRED_DEBUG -pd -Xp4c=\"--disable-parse-depth-limit\" -to 3600" "${SWITCH_PTF_DIR}")
bfn_set_p4_build_flag("tofino" "smoketest_switch_msdc" "-Xp4c=\"--disable-parse-depth-limit\"")
p4c_add_test_label("tofino" "p414_nightly" "smoketest_switch_msdc")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_msdc"
        "l2 l3 acl ^aclfrag ^tunnel mirror ^urpf ^mpls ^mcast ^racl ^warminit ^stp ^dynhash32
        ^switch_tests.MalformedPacketsTest
        ^switch_tests.L2DynamicMacMoveTest
        ^switch_tests.L2LNStatsTest
        ^switch_tests.L2StaticMacMoveBulkTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_msdc_set_1" ${SWITCH_P4}
    "${testExtraArgs} -arch ${TOFINO_P414_TEST_ARCH} -DMSDC_PROFILE -DP4_WRED_DEBUG -pd -to 3600" "${SWITCH_PTF_DIR}")
p4c_add_test_label("tofino" "p414_nightly" "smoketest_switch_msdc_set_1")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_msdc_set_1"
        "switch_tests.L2DynamicMacMoveTest
        switch_tests.L2LNStatsTest
        switch_tests.L2StaticMacMoveBulkTest")
# FIXME: remove disabling of parser min/max depth limits (P4C-4170)
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_msdc_mirror" ${SWITCH_P4}
        "${testExtraArgs} -arch ${TOFINO_P414_TEST_ARCH} -DMSDC_PROFILE -DP4_WRED_DEBUG -pd -Xp4c=\"--disable-parse-depth-limit\" -to 3600" "${SWITCH_PTF_DIR_MIRROR}")
p4c_add_test_label("tofino" "p414_nightly" "smoketest_switch_msdc_mirror")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_msdc_mirror"
        "mirror_acl")
# FIXME: remove disabling of parser min/max depth limits (P4C-4170)
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_msdc_wred" ${SWITCH_P4}
        "${testExtraArgs} -arch ${TOFINO_P414_TEST_ARCH} -DMSDC_PROFILE -DP4_WRED_DEBUG -pd -Xp4c=\"--disable-parse-depth-limit\" -to 3600" "${SWITCH_PTF_DIR_WRED}")
p4c_add_test_label("tofino" "p414_nightly" "smoketest_switch_msdc_wred")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_msdc_wred"
        "wred_drop")
# FIXME: remove disabling of parser min/max depth limits (P4C-4170)
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_msdc_MalformedPacketsTest" ${SWITCH_P4}
   "${testExtraArgs} -arch ${TOFINO_P414_TEST_ARCH} -DMSDC_PROFILE -DP4_WRED_DEBUG -pd -Xp4c=\"--disable-parse-depth-limit\" -to 3600" "${SWITCH_PTF_DIR}")
p4c_add_test_label("tofino" "p414_nightly" "smoketest_switch_msdc_MalformedPacketsTest")
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
# FIXME: remove disabling of parser min/max depth limits (P4C-4170)
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_dc_basic" ${SWITCH_P4}
        "${testExtraArgs} -arch ${TOFINO_P414_TEST_ARCH} -DDC_BASIC_PROFILE -pd -Xp4c=\"--disable-parse-depth-limit\" -to 3600" "${SWITCH_PTF_DIR}")
p4c_add_test_label("tofino" "p414_nightly" "smoketest_switch_dc_basic")
bfn_set_p4_build_flag("tofino" "smoketest_switch_dc_basic" "-Xp4c=\"--disable-parse-depth-limit\"")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_dc_basic"
        "all ^aclfrag ^queue-stats ^dynhash32
        ^switch_scale.L2VlanScaleTest
        ^switch_tests.MalformedPacketsTest
        ^switch_tests.MalformedPacketsTest_ipv6
        ^switch_tests.MalformedPacketsTest_tunnel
        ^switch_tests.L2DynamicMacMoveTest
        ^switch_tests.L2IPv4InIPv6VxlanUnicastBasicTest
        ^switch_tests.L2LNStatsTest
        ^switch_tests.L2StaticMacMoveBulkTest
        ^switch_tests.L2VxlanToGeneveUnicastBasicTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_dc_basic_set_1" ${SWITCH_P4}
    "${testExtraArgs} -arch ${TOFINO_P414_TEST_ARCH} -DDC_BASIC_PROFILE -pd -to 3600" "${SWITCH_PTF_DIR}")
p4c_add_test_label("tofino" "p414_nightly" "smoketest_switch_dc_basic_set_1")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_dc_basic_set_1"
        "switch_tests.L2DynamicMacMoveTest
        switch_tests.L2IPv4InIPv6VxlanUnicastBasicTest
        switch_tests.L2LNStatsTest
        switch_tests.L2StaticMacMoveBulkTest
        switch_tests.L2VxlanToGeneveUnicastBasicTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_dc_basic_sai_l2" ${SWITCH_P4}
        "${testExtraArgs} -arch ${TOFINO_P414_TEST_ARCH} -DDC_BASIC_PROFILE -pd -to 3600" "${SWITCH_PTF_DIR_SAI}")
p4c_add_test_label("tofino" "p414_nightly" "smoketest_switch_dc_basic_sai_l2")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_dc_basic_sai_l2"
        "l2-ocp")
bfn_set_ptf_port_map_file("tofino" "smoketest_switch_dc_basic_sai_l2"
    "${SWITCH_PTF_DIR_SAI}/default_interface_to_front_map.ini")
bfn_set_ptf_ports_json_file("tofino" "smoketest_switch_dc_basic_sai_l2"
    "${SWITCH_PTF_BASE}/ports.json")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_dc_basic_sai_l3" ${SWITCH_P4}
        "${testExtraArgs} -arch ${TOFINO_P414_TEST_ARCH} -DDC_BASIC_PROFILE -pd -to 3600" "${SWITCH_PTF_DIR_SAI}")
p4c_add_test_label("tofino" "p414_nightly" "smoketest_switch_dc_basic_sai_l3")
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
        "${testExtraArgs} -arch ${TOFINO_P414_TEST_ARCH} -DDC_BASIC_PROFILE -pd -to 3600" "${SWITCH_PTF_DIR_SAI}")
p4c_add_test_label("tofino" "p414_nightly" "smoketest_switch_dc_basic_sai_acl")
# Excluding some saiacl tests which need more ports than the supported HW ports
bfn_set_ptf_test_spec("tofino" "smoketest_switch_dc_basic_sai_acl"
        "acl-ocp
        ^saiacl.BindAclTableInGroupTest")
bfn_set_ptf_port_map_file("tofino" "smoketest_switch_dc_basic_sai_acl"
    "${SWITCH_PTF_DIR_SAI}/default_interface_to_front_map.ini")
bfn_set_ptf_ports_json_file("tofino" "smoketest_switch_dc_basic_sai_acl"
    "${SWITCH_PTF_BASE}/ports.json")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_dc_basic_sai_hostif_ARPTest" ${SWITCH_P4}
        "${testExtraArgs} -arch ${TOFINO_P414_TEST_ARCH} -DDC_BASIC_PROFILE -pd -to 3600" "${SWITCH_PTF_DIR_SAI}")
p4c_add_test_label("tofino" "p414_nightly" "smoketest_switch_dc_basic_sai_hostif_ARPTest")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_dc_basic_sai_hostif_ARPTest"
        "saihostif.ARPTest")
bfn_set_ptf_test_port("tofino" "smoketest_switch_dc_basic_sai_hostif_ARPTest"
    "3")
bfn_set_ptf_port_map_file("tofino" "smoketest_switch_dc_basic_sai_hostif_ARPTest"
    "${SWITCH_PTF_DIR_SAI}/default_interface_to_front_map.ini")
bfn_set_ptf_ports_json_file("tofino" "smoketest_switch_dc_basic_sai_hostif_ARPTest"
    "${SWITCH_PTF_BASE}/ports.json")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_dc_basic_sai_hostif_DHCPTest" ${SWITCH_P4}
    "${testExtraArgs} -arch ${TOFINO_P414_TEST_ARCH} -DDC_BASIC_PROFILE -pd -to 3600" "${SWITCH_PTF_DIR_SAI}")
p4c_add_test_label("tofino" "p414_nightly" "smoketest_switch_dc_basic_sai_hostif_DHCPTest")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_dc_basic_sai_hostif_DHCPTest"
        "saihostif.DHCPTest")
bfn_set_ptf_test_port("tofino" "smoketest_switch_dc_basic_sai_hostif_DHCPTest"
    "3")
bfn_set_ptf_port_map_file("tofino" "smoketest_switch_dc_basic_sai_hostif_DHCPTest"
    "${SWITCH_PTF_DIR_SAI}/default_interface_to_front_map.ini")
bfn_set_ptf_ports_json_file("tofino" "smoketest_switch_dc_basic_sai_hostif_DHCPTest"
    "${SWITCH_PTF_BASE}/ports.json")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_dc_basic_sai_hostif_LLDPTest" ${SWITCH_P4}
    "${testExtraArgs} -arch ${TOFINO_P414_TEST_ARCH} -DDC_BASIC_PROFILE -pd -to 3600" "${SWITCH_PTF_DIR_SAI}")
p4c_add_test_label("tofino" "p414_nightly" "smoketest_switch_dc_basic_sai_hostif_LLDPTest")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_dc_basic_sai_hostif_LLDPTest"
        "saihostif.LLDPTest")
bfn_set_ptf_test_port("tofino" "smoketest_switch_dc_basic_sai_hostif_LLDPTest"
    "3")
bfn_set_ptf_port_map_file("tofino" "smoketest_switch_dc_basic_sai_hostif_LLDPTest"
    "${SWITCH_PTF_DIR_SAI}/default_interface_to_front_map.ini")
bfn_set_ptf_ports_json_file("tofino" "smoketest_switch_dc_basic_sai_hostif_LLDPTest"
    "${SWITCH_PTF_BASE}/ports.json")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_dc_basic_sai_hostif_LACPTest" ${SWITCH_P4}
    "${testExtraArgs} -arch ${TOFINO_P414_TEST_ARCH} -DDC_BASIC_PROFILE -pd -to 3600" "${SWITCH_PTF_DIR_SAI}")
p4c_add_test_label("tofino" "p414_nightly" "smoketest_switch_dc_basic_sai_hostif_LACPTest")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_dc_basic_sai_hostif_LACPTest"
        "saihostif.LACPTest")
bfn_set_ptf_test_port("tofino" "smoketest_switch_dc_basic_sai_hostif_LACPTest"
    "3")
bfn_set_ptf_port_map_file("tofino" "smoketest_switch_dc_basic_sai_hostif_LACPTest"
    "${SWITCH_PTF_DIR_SAI}/default_interface_to_front_map.ini")
bfn_set_ptf_ports_json_file("tofino" "smoketest_switch_dc_basic_sai_hostif_LACPTest"
    "${SWITCH_PTF_BASE}/ports.json")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_dc_basic_sai_hostif_SNMPTest" ${SWITCH_P4}
    "${testExtraArgs} -arch ${TOFINO_P414_TEST_ARCH} -DDC_BASIC_PROFILE -pd -to 3600" "${SWITCH_PTF_DIR_SAI}")
p4c_add_test_label("tofino" "p414_nightly" "smoketest_switch_dc_basic_sai_hostif_SNMPTest")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_dc_basic_sai_hostif_SNMPTest"
        "saihostif.SNMPTest")
bfn_set_ptf_test_port("tofino" "smoketest_switch_dc_basic_sai_hostif_SNMPTest"
    "3")
bfn_set_ptf_port_map_file("tofino" "smoketest_switch_dc_basic_sai_hostif_SNMPTest"
    "${SWITCH_PTF_DIR_SAI}/default_interface_to_front_map.ini")
bfn_set_ptf_ports_json_file("tofino" "smoketest_switch_dc_basic_sai_hostif_SNMPTest"
    "${SWITCH_PTF_BASE}/ports.json")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_dc_basic_sai_hostif_SSHTest" ${SWITCH_P4}
    "${testExtraArgs} -arch ${TOFINO_P414_TEST_ARCH} -DDC_BASIC_PROFILE -pd -to 3600" "${SWITCH_PTF_DIR_SAI}")
p4c_add_test_label("tofino" "p414_nightly" "smoketest_switch_dc_basic_sai_hostif_SSHTest")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_dc_basic_sai_hostif_SSHTest"
        "saihostif.SSHTest")
bfn_set_ptf_test_port("tofino" "smoketest_switch_dc_basic_sai_hostif_SSHTest"
    "3")
bfn_set_ptf_port_map_file("tofino" "smoketest_switch_dc_basic_sai_hostif_SSHTest"
    "${SWITCH_PTF_DIR_SAI}/default_interface_to_front_map.ini")
bfn_set_ptf_ports_json_file("tofino" "smoketest_switch_dc_basic_sai_hostif_SSHTest"
    "${SWITCH_PTF_BASE}/ports.json")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_dc_basic_sai_hostif_IP2METest" ${SWITCH_P4}
    "${testExtraArgs} -arch ${TOFINO_P414_TEST_ARCH} -DDC_BASIC_PROFILE -pd -to 3600" "${SWITCH_PTF_DIR_SAI}")
p4c_add_test_label("tofino" "p414_nightly" "smoketest_switch_dc_basic_sai_hostif_IP2METest")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_dc_basic_sai_hostif_IP2METest"
        "saihostif.IP2METest")
bfn_set_ptf_test_port("tofino" "smoketest_switch_dc_basic_sai_hostif_IP2METest"
    "3")
bfn_set_ptf_port_map_file("tofino" "smoketest_switch_dc_basic_sai_hostif_IP2METest"
    "${SWITCH_PTF_DIR_SAI}/default_interface_to_front_map.ini")
bfn_set_ptf_ports_json_file("tofino" "smoketest_switch_dc_basic_sai_hostif_IP2METest"
    "${SWITCH_PTF_BASE}/ports.json")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_dc_basic_sai_hostif_TTLErrorTest" ${SWITCH_P4}
    "${testExtraArgs} -arch ${TOFINO_P414_TEST_ARCH} -DDC_BASIC_PROFILE -pd -to 3600" "${SWITCH_PTF_DIR_SAI}")
p4c_add_test_label("tofino" "p414_nightly" "smoketest_switch_dc_basic_sai_hostif_TTLErrorTest")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_dc_basic_sai_hostif_TTLErrorTest"
        "saihostif.TTLErrorTest")
bfn_set_ptf_test_port("tofino" "smoketest_switch_dc_basic_sai_hostif_TTLErrorTest"
    "3")
bfn_set_ptf_port_map_file("tofino" "smoketest_switch_dc_basic_sai_hostif_TTLErrorTest"
    "${SWITCH_PTF_DIR_SAI}/default_interface_to_front_map.ini")
bfn_set_ptf_ports_json_file("tofino" "smoketest_switch_dc_basic_sai_hostif_TTLErrorTest"
    "${SWITCH_PTF_BASE}/ports.json")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_dc_basic_sai_hostif_BGPTest" ${SWITCH_P4}
    "${testExtraArgs} -arch ${TOFINO_P414_TEST_ARCH} -DDC_BASIC_PROFILE -pd -to 3600" "${SWITCH_PTF_DIR_SAI}")
p4c_add_test_label("tofino" "p414_nightly" "smoketest_switch_dc_basic_sai_hostif_BGPTest")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_dc_basic_sai_hostif_BGPTest"
        "saihostif.BGPTest")
bfn_set_ptf_test_port("tofino" "smoketest_switch_dc_basic_sai_hostif_BGPTest"
    "3")
bfn_set_ptf_port_map_file("tofino" "smoketest_switch_dc_basic_sai_hostif_BGPTest"
    "${SWITCH_PTF_DIR_SAI}/default_interface_to_front_map.ini")
bfn_set_ptf_ports_json_file("tofino" "smoketest_switch_dc_basic_sai_hostif_BGPTest"
    "${SWITCH_PTF_BASE}/ports.json")
# FIXME: remove disabling of parser min/max depth limits (P4C-4170)
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_dc_basic_MalformedPacketsTest" ${SWITCH_P4}
        "${testExtraArgs} -arch ${TOFINO_P414_TEST_ARCH} -DDC_BASIC_PROFILE -pd -Xp4c=\"--disable-parse-depth-limit\" -to 3600" "${SWITCH_PTF_DIR}")
p4c_add_test_label("tofino" "p414_nightly" "smoketest_switch_dc_basic_MalformedPacketsTest")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_dc_basic_MalformedPacketsTest"
        "switch_tests.MalformedPacketsTest")
# FIXME: remove disabling of parser min/max depth limits (P4C-4170)
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_dc_basic_MalformedPacketsTest_ipv6" ${SWITCH_P4}
        "${testExtraArgs} -arch ${TOFINO_P414_TEST_ARCH} -DDC_BASIC_PROFILE -pd -Xp4c=\"--disable-parse-depth-limit\" -to 3600" "${SWITCH_PTF_DIR}")
p4c_add_test_label("tofino" "p414_nightly" "smoketest_switch_dc_basic_MalformedPacketsTest_ipv6")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_dc_basic_MalformedPacketsTest_ipv6"
        "switch_tests.MalformedPacketsTest_ipv6")
# FIXME: remove disabling of parser min/max depth limits (P4C-4170)
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_dc_basic_MalformedPacketsTest_tunnel" ${SWITCH_P4}
        "${testExtraArgs} -arch ${TOFINO_P414_TEST_ARCH} -DDC_BASIC_PROFILE -pd -Xp4c=\"--disable-parse-depth-limit\" -to 3600" "${SWITCH_PTF_DIR}")
p4c_add_test_label("tofino" "p414_nightly" "smoketest_switch_dc_basic_MalformedPacketsTest_tunnel")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_dc_basic_MalformedPacketsTest_tunnel"
        "switch_tests.MalformedPacketsTest_tunnel")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_dc_basic_L2VlanScaleTest" ${SWITCH_P4}
        "${testExtraArgs} -arch ${TOFINO_P414_TEST_ARCH} -DDC_BASIC_PROFILE -pd -to 3600" "${SWITCH_PTF_DIR}")
p4c_add_test_label("tofino" "p414_nightly" "smoketest_switch_dc_basic_L2VlanScaleTest")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_dc_basic_L2VlanScaleTest"
        "switch_scale.L2VlanScaleTest")

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
set_tests_properties("tofino/smoketest_switch_dc_basic_L2VlanScaleTest" PROPERTIES TIMEOUT 3600)

p4c_add_test_label("tofino" "UNSTABLE" "smoketest_switch_dc_basic_set_1")
p4c_add_test_label("tofino" "UNSTABLE" "smoketest_switch_dc_basic_sai_l2")
p4c_add_test_label("tofino" "UNSTABLE" "smoketest_switch_dc_basic_sai_l3")
p4c_add_test_label("tofino" "UNSTABLE" "smoketest_switch_dc_basic_sai_acl")
p4c_add_test_label("tofino" "UNSTABLE" "smoketest_switch_dc_basic_sai_hostif_ARPTest")
p4c_add_test_label("tofino" "UNSTABLE" "smoketest_switch_dc_basic_sai_hostif_DHCPTest")
p4c_add_test_label("tofino" "UNSTABLE" "smoketest_switch_dc_basic_sai_hostif_LLDPTest")
p4c_add_test_label("tofino" "UNSTABLE" "smoketest_switch_dc_basic_sai_hostif_LACPTest")
p4c_add_test_label("tofino" "UNSTABLE" "smoketest_switch_dc_basic_sai_hostif_SNMPTest")
p4c_add_test_label("tofino" "UNSTABLE" "smoketest_switch_dc_basic_sai_hostif_SSHTest")
p4c_add_test_label("tofino" "UNSTABLE" "smoketest_switch_dc_basic_sai_hostif_IP2METest")
p4c_add_test_label("tofino" "UNSTABLE" "smoketest_switch_dc_basic_sai_hostif_TTLErrorTest")
p4c_add_test_label("tofino" "UNSTABLE" "smoketest_switch_dc_basic_sai_hostif_BGPTest")
p4c_add_test_label("tofino" "UNSTABLE" "smoketest_switch_dc_basic_L2VlanScaleTest")

# Switch master ENT_DC_GENERAL_PROFILE tests
# FIXME: remove disabling of parser min/max depth limits (P4C-4170)
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_ent_dc_general" ${SWITCH_P4}
        "${testExtraArgs} -arch ${TOFINO_P414_TEST_ARCH} -DENT_DC_GENERAL_PROFILE -pd -to 3600 -Xp4c=\"--disable-parse-max-depth-limit\"" "${SWITCH_PTF_DIR}")
p4c_add_test_label("tofino" "p414_nightly" "smoketest_switch_ent_dc_general")
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
    "${testExtraArgs} -arch ${TOFINO_P414_TEST_ARCH} -DENT_DC_GENERAL_PROFILE -pd -to 3600" "${SWITCH_PTF_DIR}")
p4c_add_test_label("tofino" "p414_nightly" "smoketest_switch_ent_dc_general_set_1")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_ent_dc_general_set_1"
        "switch_tests.L2LNStatsTest
        switch_tests.L2DynamicMacMoveTest
        switch_tests.L2StaticMacMoveBulkTest
        switch_tests.L2VxlanUnicastBasicTest
        switch_tests.L3EcmpLagTest
        switch_tests.L3VIIPv4HostMacMoveTest")
# FIXME: remove disabling of parser min/max depth limits (P4C-4170)
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_ent_dc_general_egress_acl" ${SWITCH_P4}
        "${testExtraArgs} -arch ${TOFINO_P414_TEST_ARCH} -DENT_DC_GENERAL_PROFILE -pd -to 3600 -Xp4c=\"--disable-parse-max-depth-limit\"" "${SWITCH_PTF_DIR_EGRESS_ACL}")
p4c_add_test_label("tofino" "p414_nightly" "smoketest_switch_ent_dc_general_egress_acl")

# 500s timeout is too little for compiling and testing the entire switch, bumping it up
set_tests_properties("tofino/smoketest_switch_ent_dc_general" PROPERTIES TIMEOUT 3600)
set_tests_properties("tofino/smoketest_switch_ent_dc_general_set_1" PROPERTIES TIMEOUT 3600)
set_tests_properties("tofino/smoketest_switch_ent_dc_general_egress_acl" PROPERTIES TIMEOUT 3600)

p4c_add_test_label("tofino" "UNSTABLE" "smoketest_switch_ent_dc_general_set_1")

# Additional testing (excluded in PRs and CI)
# Switch Master MSDC_IPV4_PROFILE tests
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_ipv4" ${SWITCH_P4}
    "${testExtraArgs} -arch ${TOFINO_P414_TEST_ARCH} -DMSDC_IPV4_PROFILE -DP4_WRED_DEBUG -pd -to 3600" "${SWITCH_PTF_DIR}")
p4c_add_test_label("tofino" "p414_nightly" "smoketest_switch_ipv4")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_ipv4"
        "l2 l3 acl mirror l3-vxlan ^hostif ^tunnel ^aclfrag ^dynhash ^dynhash32
        ^urpf ^mpls ^mcast ^racl ^warminit ^stp
        ^switch_tests.MalformedPacketsTest
        ^switch_tests.ExceptionPacketsTest
        ^switch_tests.ExceptionPacketsTest_IPV6")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_ipv4_mirror" ${SWITCH_P4}
    "${testExtraArgs} -arch ${TOFINO_P414_TEST_ARCH} -DMSDC_IPV4_PROFILE -DP4_WRED_DEBUG -pd -to 3600" "${SWITCH_PTF_DIR_MIRROR}")
p4c_add_test_label("tofino" "p414_nightly" "smoketest_switch_ipv4_mirror")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_ipv4_mirror"
        "mirror_acl")

# 500s timeout is too little for compiling and testing the entire switch, bumping it up
set_tests_properties("tofino/smoketest_switch_ipv4" PROPERTIES TIMEOUT 3600)
set_tests_properties("tofino/smoketest_switch_ipv4_mirror" PROPERTIES TIMEOUT 3600)

# Switch Master MSDC_SPINE_DTEL_INT_PROFILE tests
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_dtel_int_spine" ${SWITCH_P4}
    "${testExtraArgs} -arch ${TOFINO_P414_TEST_ARCH} -DMSDC_SPINE_DTEL_INT_PROFILE -pd -to 3600" "${SWITCH_PTF_DIR}")
p4c_add_test_label("tofino" "p414_nightly" "smoketest_switch_dtel_int_spine")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_dtel_int_spine"
        "all ^tunnel ^mpls ^urpf ^racl ^ipv6 ^mcast ^warminit ^stp ^ptp ^aclfrag ^dynhash32")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_dtel_int_spine_mirror" ${SWITCH_P4}
    "${testExtraArgs} -arch ${TOFINO_P414_TEST_ARCH} -DMSDC_SPINE_DTEL_INT_PROFILE -pd -to 3600" "${SWITCH_PTF_DIR_MIRROR}")
p4c_add_test_label("tofino" "p414_nightly" "smoketest_switch_dtel_int_spine_mirror")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_dtel_int_spine_mirror"
        "mirror_acl_slice_tests.MirrorAclSliceTest_i2e")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_dtel_int_spine_dtel" ${SWITCH_P4}
    "${testExtraArgs} -arch ${TOFINO_P414_TEST_ARCH} -DMSDC_SPINE_DTEL_INT_PROFILE -pd -to 3600" "${SWITCH_PTF_DIR_DTEL}")
p4c_add_test_label("tofino" "p414_nightly" "smoketest_switch_dtel_int_spine_dtel")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_dtel_int_spine_dtel"
        "switch_int_l45_common.intl45_route_dtel_reports
        switch_int_l45_transit_digest.intl45_transitTest_hop2_with_digest
        switch_int_l45_transit.intl45_DSCP_TransitTest
        switch_int_l45_transit.INTL45_Marker_TransitTest
        switch_int_l45_transit.intl45_transitTest_Ebit
        switch_int_l45_transit.INTL45_TransitTest_Enable
        switch_int_l45_transit.intl45_transitTest_hop2_latency")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_dtel_int_spine_dtel_part_2" ${SWITCH_P4}
    "${testExtraArgs} -arch ${TOFINO_P414_TEST_ARCH} -DMSDC_SPINE_DTEL_INT_PROFILE -pd -to 3600" "${SWITCH_PTF_DIR_DTEL}")
p4c_add_test_label("tofino" "p414_nightly" "smoketest_switch_dtel_int_spine_dtel_part_2")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_dtel_int_spine_dtel_part_2"
        "switch_int_l45_transit.intl45_transitTest_hop2_port_ids
        switch_int_l45_transit.intl45_transitTest_hop2_qdepth
        switch_int_l45_transit.intl45_transitTest_hop2_txutil_yet_supported
        switch_int_l45_transit.intl45_transitTest_latency_shift
        switch_int_l45_transit.intl45_transitTest_Metadata
        switch_int_l45_transit.intl45_transitTest_switchid
        switch_queue_report.QueueReport_Change_Test")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_dtel_int_spine_dtel_INTL45" ${SWITCH_P4}
    "${testExtraArgs} -arch ${TOFINO_P414_TEST_ARCH} -DMSDC_SPINE_DTEL_INT_PROFILE -pd -to 3600" "${SWITCH_PTF_DIR_DTEL}")
p4c_add_test_label("tofino" "p414_nightly" "smoketest_switch_dtel_int_spine_dtel_INTL45")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_dtel_int_spine_dtel_INTL45"
        "switch_int_l45_transit.INTL45_Transit_EgressMoDTest
         switch_int_l45_transit.INTL45_Transit_IngressMoDTest
         switch_int_l45_transit_stless.intl45_transitTest_hop2_stateless")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_dtel_int_spine_dtel_QueueReport" ${SWITCH_P4}
    "${testExtraArgs} -arch ${TOFINO_P414_TEST_ARCH} -DMSDC_SPINE_DTEL_INT_PROFILE -pd -to 3600" "${SWITCH_PTF_DIR_DTEL}")
p4c_add_test_label("tofino" "p414_nightly" "smoketest_switch_dtel_int_spine_dtel_QueueReport")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_dtel_int_spine_dtel_QueueReport"
        "switch_queue_report.QueueReport_Entropy_Test
         switch_queue_report.QueueReport_Quota_Test
         switch_queue_report_multimirror.QueueReport_Over_ECMP_Test
         switch_queue_report_multimirror.QueueReport_MirrorTest
         switch_queue_report_multimirror.QueueReport_L2_MirrorTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_dtel_int_spine_dtel_MirrorOnDrop" ${SWITCH_P4}
    "${testExtraArgs} -arch ${TOFINO_P414_TEST_ARCH} -DMSDC_SPINE_DTEL_INT_PROFILE -pd -to 3600" "${SWITCH_PTF_DIR_DTEL}")
p4c_add_test_label("tofino" "p414_nightly" "smoketest_switch_dtel_int_spine_dtel_MirrorOnDrop")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_dtel_int_spine_dtel_MirrorOnDrop"
        "switch_mirror_on_drop.MirrorOnDropEgrNonDefaultRuleTest
         switch_mirror_on_drop.MirrorOnDropHostifReasonCodeTest
         switch_mirror_on_drop.MirrorOnDropIngressAclTest
         switch_mirror_on_drop.MirrorOnDropNonDefaultRuleTest
         switch_mirror_on_drop.MirrorOnDropEgressAclTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_dtel_int_spine_dtel_INTL45_Transit_DoDTest" ${SWITCH_P4}
    "${testExtraArgs} -arch ${TOFINO_P414_TEST_ARCH} -DMSDC_SPINE_DTEL_INT_PROFILE -pd -to 3600" "${SWITCH_PTF_DIR_DTEL}")
p4c_add_test_label("tofino" "p414_nightly" "smoketest_switch_dtel_int_spine_dtel_INTL45_Transit_DoDTest")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_dtel_int_spine_dtel_INTL45_Transit_DoDTest"
    "switch_int_l45_transit.INTL45_Transit_DoDTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_dtel_int_spine_dtel_QueueReport_DoD_Test" ${SWITCH_P4}
    "${testExtraArgs} -arch ${TOFINO_P414_TEST_ARCH} -DMSDC_SPINE_DTEL_INT_PROFILE -pd -to 3600" "${SWITCH_PTF_DIR_DTEL}")
p4c_add_test_label("tofino" "p414_nightly" "smoketest_switch_dtel_int_spine_dtel_QueueReport_DoD_Test")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_dtel_int_spine_dtel_QueueReport_DoD_Test"
    "switch_queue_report.QueueReport_DoD_Test")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_dtel_int_spine_dtel_MirrorOnDropDoDTest" ${SWITCH_P4}
    "${testExtraArgs} -arch ${TOFINO_P414_TEST_ARCH} -DMSDC_SPINE_DTEL_INT_PROFILE -pd -to 3600" "${SWITCH_PTF_DIR_DTEL}")
p4c_add_test_label("tofino" "p414_nightly" "smoketest_switch_dtel_int_spine_dtel_MirrorOnDropDoDTest")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_dtel_int_spine_dtel_MirrorOnDropDoDTest"
    "switch_mirror_on_drop.MirrorOnDropDoDTest")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_dtel_int_spine_dtel_sai" ${SWITCH_P4}
    "${testExtraArgs} -arch ${TOFINO_P414_TEST_ARCH} -DMSDC_SPINE_DTEL_INT_PROFILE -pd -to 3600" "${SWITCH_PTF_DIR_SAI_DTEL}")
p4c_add_test_label("tofino" "p414_nightly" "smoketest_switch_dtel_int_spine_dtel_sai")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_dtel_int_spine_dtel_sai"
        "int_transit")
bfn_set_ptf_port_map_file("tofino" "smoketest_switch_dtel_int_spine_dtel_sai"
    "${SWITCH_PTF_DIR_SAI}/port_map.ini")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_dtel_int_spine_sai" ${SWITCH_P4}
    "${testExtraArgs} -arch ${TOFINO_P414_TEST_ARCH} -DMSDC_SPINE_DTEL_INT_PROFILE -pd -to 3600" "${SWITCH_PTF_DIR_SAI}")
p4c_add_test_label("tofino" "p414_nightly" "smoketest_switch_dtel_int_spine_sai")
bfn_set_ptf_test_spec("tofino" "smoketest_switch_dtel_int_spine_sai"
        "egress-acl mirror-acl")
bfn_set_ptf_port_map_file("tofino" "smoketest_switch_dtel_int_spine_sai"
    "${SWITCH_PTF_DIR_SAI}/port_map.ini")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_switch_dtel_int_spine_sai_hostif" ${SWITCH_P4}
    "${testExtraArgs} -arch ${TOFINO_P414_TEST_ARCH} -DMSDC_SPINE_DTEL_INT_PROFILE -pd -to 3600" "${SWITCH_PTF_DIR_SAI}")
p4c_add_test_label("tofino" "p414_nightly" "smoketest_switch_dtel_int_spine_sai_hostif")
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
