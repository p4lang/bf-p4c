set (tofino2_timeout 600)

# check for PTF requirements
packet_test_setup_check("jbay")

set (V1_SEARCH_PATTERNS "include.*(v1model|psa).p4" "main")
set (P4TESTDATA ${P4C_SOURCE_DIR}/testdata)
set (P4TESTS_FOR_JBAY "${P4TESTDATA}/p4_16_samples/*.p4")
p4c_find_tests("${P4TESTS_FOR_JBAY}" v1tests INCLUDE "${V1_SEARCH_PATTERNS}")

set (P16_V1_INCLUDE_PATTERNS "include.*v1model.p4" "main|common_v1_test")
set (P16_V1_EXCLUDE_PATTERNS "tofino\\.h")
set (P16_V1_FOR_JBAY "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/compile_only/*.p4" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/customer/*/*.p4" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/stf/*.p4" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/ptf/*.p4")
p4c_find_tests("${P16_V1_FOR_JBAY}" p16_v1tests INCLUDE "${P16_V1_INCLUDE_PATTERNS}" EXCLUDE "${P16_V1_EXCLUDE_PATTERNS}")

set (P16_JNA_INCLUDE_PATTERNS "include.*(t2na).p4" "main|common_tna_test")
set (P16_JNA_EXCLUDE_PATTERNS "tofino\\.h")
set (P16_JNA_FOR_JBAY "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/compile_only/*.p4" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/customer/*/*.p4" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/stf/*.p4" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/ptf/*.p4")
p4c_find_tests("${P16_JNA_FOR_JBAY}" p16_jna_tests INCLUDE "${P16_JNA_INCLUDE_PATTERNS}" EXCLUDE "${P16_JNA_EXCLUDE_PATTERNS}")

file (GLOB STF_TESTS "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/stf/*.stf")
string (REGEX REPLACE "\\.stf;" ".p4;" STF_P4_TESTS "${STF_TESTS};")

file (GLOB PTF_TESTS "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/ptf/*.ptf")
string (REGEX REPLACE "\\.ptf;" ".p4;" PTF_P4_TESTS "${PTF_TESTS};")

# Exclude some p4s with conditional checksum updates that are added separately
set (P4_14_EXCLUDE_FILES "parser_dc_full\\.p4" "sai_p4\\.p4"
                            "checksum_pragma\\.p4" "port_vlan_mapping\\.p4"
                            "checksum\\.p4")
set (P4_14_SAMPLES "${P4TESTDATA}/p4_14_samples/*.p4")
bfn_find_tests("${P4_14_SAMPLES}" p4_14_samples EXCLUDE "${P4_14_EXCLUDE_FILES}")

set (JBAY_V1_TEST_SUITES
  ${p4_14_samples}
#  ${v1tests}
  ${p16_v1tests}
  ${STF_P4_TESTS}
  ${PTF_P4_TESTS}
# p4_14_samples
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/bf_p4c_samples/*.p4
# p4_16_samples
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/bf_p4c_samples/*.p4
  )

p4c_add_bf_backend_tests("tofino2" "jbay" "v1model" "base" "${JBAY_V1_TEST_SUITES}" "-I${CMAKE_CURRENT_SOURCE_DIR}/p4_16/includes")

set (JBAY_JNA_TEST_SUITES
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/jbay/*.p4
  ${p16_jna_tests}
  )
p4c_add_bf_backend_tests("tofino2" "jbay" "t2na" "base" "${JBAY_JNA_TEST_SUITES}" "-I${CMAKE_CURRENT_SOURCE_DIR}/p4_16/includes")

set (testExtraArgs "${testExtraArgs} -tofino2")

p4c_add_ptf_test_with_ptfdir (
    "tofino2" "p4c_1585" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/bfrt/p4c_1585/p4c_1585.p4"
    "${testExtraArgs} -target tofino2 -arch t2na -bfrt -to 2000" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/bfrt/p4c_1585")

set (ONOS_FABRIC_NEW_P4 ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/bf-onos-new/pipelines/fabric/src/main/resources/fabric-tofino.p4)
p4c_add_ptf_test_with_ptfdir_and_spec (
    "tofino2" fabric-new ${ONOS_FABRIC_NEW_P4}
    "${testExtraArgs} -tofino2"
    ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/bf-onos-ptf/fabric-new.ptf "all ^spgw ^int")
p4c_add_ptf_test_with_ptfdir_and_spec (
    "tofino2" fabric-new-DWITH_SPGW ${ONOS_FABRIC_NEW_P4}
    "${testExtraArgs} -tofino2 -DWITH_SPGW"
    ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/bf-onos-ptf/fabric-new.ptf "all ^int")
p4c_add_ptf_test_with_ptfdir_and_spec (
    "tofino2" fabric-new-DWITH_INT_TRANSIT ${ONOS_FABRIC_NEW_P4}
    "${testExtraArgs} -tofino2 -DWITH_INT_TRANSIT"
    ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/bf-onos-ptf/fabric-new.ptf "all ^spgw")
p4c_add_ptf_test_with_ptfdir_and_spec (
    "tofino2" fabric-new-DWITH_SPGW-DWITH_INT_TRANSIT ${ONOS_FABRIC_NEW_P4}
    "${testExtraArgs} -tofino2 -DWITH_SPGW -DWITH_INT_TRANSIT"
    ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/bf-onos-ptf/fabric-new.ptf "all")

p4c_add_ptf_test_with_ptfdir (
    "tofino2" tor.p4 ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/google-tor/p4/spec/tor.p4
    "${testExtraArgs}" ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/tor.ptf)

# p4-tests has all the includes at the same level with the programs.
set (BFN_EXCLUDE_PATTERNS "tofino\\.p4")
set (BFN_TESTS "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/internal_p4_14/emulation/*.p4"
               "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/internal_p4_14/atomic_mod/*.p4"
               "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/programs/basic_switching/*.p4"
               "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/programs/chksum/*.p4"
               "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/programs/deparse_zero/*.p4"
               "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/programs/ha/*.p4"
               "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/programs/parse_error/*.p4"
               "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/programs/pcie_pkt_test/*.p4"
               "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/programs/resubmit/*.p4"
               "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/programs/multicast_test/*.p4"
               "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/programs/mirror_test/*.p4"
               "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/programs/fast_reconfig/*.p4")
bfn_find_tests ("${BFN_TESTS}" BFN_TESTS_LIST EXCLUDE "${BFN_EXCLUDE_PATTERNS}")
bfn_add_p4factory_tests("tofino2" "smoketest_programs" BFN_TESTS_LIST)

bfn_set_ptf_ports_json_file("tofino2" "extensions/p4_tests/p4-programs/programs/multicast_test/multicast_test.p4"
                            "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/ptf-tests/multicast_test/ports.json")
bfn_set_ptf_ports_json_file("tofino2" "extensions/p4_tests/p4-programs/programs/fast_reconfig/fast_reconfig.p4"
                            "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/ptf-tests/fast_reconfig/ports.json")
bfn_set_ptf_ports_json_file("tofino2" "extensions/p4_tests/p4-programs/programs/mirror_test/mirror_test.p4"
                            "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/ptf-tests/mirror_test/ports.json")
bfn_set_ptf_ports_json_file("tofino2" "extensions/p4_tests/p4-programs/programs/ha/ha.p4"
                            "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/ptf-tests/ha/ports.json")

bfn_set_pd_build_flag("tofino2" "extensions/p4_tests/p4-programs/programs/ha/ha.p4"
    "\"--gen-hitless-ha-test-pd\"")

file(RELATIVE_PATH tofino32q-3pipe_path ${P4C_SOURCE_DIR} ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/tofino32q-3pipe/sfc.p4)
p4c_add_test_with_args ("tofino2" ${P4C_RUNTEST} FALSE
  "tofino32q-3pipe" ${tofino32q-3pipe_path} "${testExtraArgs} -tofino2 -arch t2na" "")

## P4-16 Programs
set (P4FACTORY_P4_16_PROGRAMS
  tna_32q_2pipe
  tna_action_profile
  tna_action_selector
  tna_counter
  tna_digest
  tna_dyn_hashing
  tna_exact_match
  tna_idletimeout
  tna_lpm_match
  tna_meter_bytecount_adjust
  tna_meter_lpf_wred
  tna_operations
  tna_port_metadata
  tna_port_metadata_extern
  tna_pvs
  tna_range_match
  tna_register
  tna_ternary_match
  )

# No ptf, compile-only
file(RELATIVE_PATH p4_16_programs_path ${P4C_SOURCE_DIR} ${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/p4_16_programs)
p4c_add_test_with_args ("tofino2" ${P4C_RUNTEST} FALSE
  "p4_16_programs_simple_switch" ${p4_16_programs_path}/simple_switch/simple_switch.p4 "${testExtraArgs} -tofino2 -arch t2na -I${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/p4_16_programs" "")
p4c_add_test_with_args ("tofino2" ${P4C_RUNTEST} FALSE
  "p4_16_programs_tna_32q_multiprogram_a" ${p4_16_programs_path}/tna_32q_multiprogram/program_a/tna_32q_multiprogram_a.p4 "${testExtraArgs} -tofino2 -arch t2na -I${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/p4_16_programs/tna_32q_multiprogram" "")
p4c_add_test_with_args ("tofino2" ${P4C_RUNTEST} FALSE
  "p4_16_programs_tna_32q_multiprogram_b" ${p4_16_programs_path}/tna_32q_multiprogram/program_b/tna_32q_multiprogram_b.p4 "${testExtraArgs} -tofino2 -arch t2na -I${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/p4_16_programs/tna_32q_multiprogram" "")

# P4-16 Programs with PTF tests
foreach(t IN LISTS P4FACTORY_P4_16_PROGRAMS)
  p4c_add_ptf_test_with_ptfdir ("tofino2" "p4_16_programs_${t}" "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/p4_16_programs/${t}/${t}.p4"
    "${testExtraArgs} -target tofino2 -arch t2na -bfrt -to 2000" "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/p4_16_programs/${t}")
  bfn_set_p4_build_flag("tofino2" "p4_16_programs_${t}" "-I${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/p4_16_programs")
  set (ports_json ${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/p4_16_programs/${t}/ports_tof2.json)
  if (EXISTS ${ports_json})
    bfn_set_ptf_ports_json_file("tofino2" "p4_16_programs_${t}" ${ports_json})
  endif()
endforeach()

# 500s timeout is too little for compiling and testing the entire switch, bumping it up
set_tests_properties("tofino2/p4_16_programs_tna_exact_match" PROPERTIES TIMEOUT 1200)
set_tests_properties("tofino2/p4_16_programs_tna_ternary_match" PROPERTIES TIMEOUT 2400)

include(SwitchJBay.cmake)
include(JBayXfail.cmake)
