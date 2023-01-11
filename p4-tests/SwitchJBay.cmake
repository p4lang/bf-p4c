include (ExternalProject)

# Switch P4-16
set (SWITCH_P4_16_ROOT ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/switch_16)
set (SWITCH_P4_16_INC ${SWITCH_P4_16_ROOT}/p4src/shared)
set (SWITCH_P4_16_PTF ${SWITCH_P4_16_ROOT}/ptf/api)
set (SWITCH_PATH_PREFIX ${SWITCH_P4_16_ROOT}/p4src/switch-tofino2/switch_tofino2_)

set(SWITCH_T2_PTF_SPEC
    "all
    ^acl2
    ^hash
    ^switch_l3.L3SVITest
    ^switch_l2.L2LagTest
    ^switch_l3.L3ECMPTest
    ^switch_l3.L3MulticastTest")

bfn_add_switch_test("2" "y1" "" "METRICS" ON "${SWITCH_T2_PTF_SPEC}")
bfn_add_switch_test("2" "y2" "" "METRICS" ON "${SWITCH_T2_PTF_SPEC}")
bfn_add_switch_test("2" "y4" "" "METRICS" OFF)
bfn_add_switch_test("2" "y7" "" "METRICS" OFF)
bfn_add_switch_test("2" "y8" "--set-max-power 62" "METRICS" OFF)
