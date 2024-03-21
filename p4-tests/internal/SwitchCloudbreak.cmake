include (ExternalProject)

# Switch P4-16
set (SWITCH_P4_16_ROOT ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/switch_16)
set (SWITCH_P4_16_INC ${SWITCH_P4_16_ROOT}/p4src/shared)
set (SWITCH_PATH_PREFIX ${SWITCH_P4_16_ROOT}/p4src/switch-tofino2/switch_tofino2_)

bfn_add_switch_test("3" "y2" "" "METRICS" OFF)
