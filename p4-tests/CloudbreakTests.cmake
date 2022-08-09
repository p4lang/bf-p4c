set (tofino3_timeout ${default_test_timeout})

# check for PTF requirements
packet_test_setup_check("cb")
# check for STF requirements
simple_test_setup_check("cb")

set (V1_SEARCH_PATTERNS "include.*(v1model|psa).p4" "main")
set (P4TESTDATA ${P4C_SOURCE_DIR}/testdata)
set (P4TESTS_FOR_CLOUDBREAK "${P4TESTDATA}/p4_16_samples/*.p4")
p4c_find_tests("${P4TESTS_FOR_CLOUDBREAK}" v1tests INCLUDE "${V1_SEARCH_PATTERNS}")

set (P16_V1_INCLUDE_PATTERNS "include.*v1model.p4" "main|common_v1_test")
set (P16_V1_EXCLUDE_PATTERNS "tofino\\.h")
set (P16_V1_FOR_CLOUDBREAK "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/compile_only/*.p4" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/customer/*/*.p4" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/stf/*.p4" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/ptf/*.p4")
p4c_find_tests("${P16_V1_FOR_CLOUDBREAK}" p16_v1tests INCLUDE "${P16_V1_INCLUDE_PATTERNS}" EXCLUDE "${P16_V1_EXCLUDE_PATTERNS}")

set (P16_JNA_INCLUDE_PATTERNS "include.*(t[23]?na).p4" "main|common_tna_test")
set (P16_JNA_EXCLUDE_PATTERNS "tofino\\.h" "TOFINO1_ONLY" "TOFINO2_ONLY" "<built-in>"
                              "mirror_constants\\.p4"
                              "p4c-2740\\.p4"
                              "p4c_2601\\.p4"
                              "hash_extern_xor\\.p4"
                              "hash_field_expression\\.p4"
                              "hash_field_expression_sym\\.p4"
                              "keysight-eagle-tf2\\.p4"
                              "p4c-4055\\.p4"
)
set (P16_JNA_FOR_CLOUDBREAK "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/compile_only/*.p4" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/customer/*/*.p4" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/stf/*.p4" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/ptf/*.p4")
p4c_find_tests("${P16_JNA_FOR_CLOUDBREAK}" P16_JNA_TESTS INCLUDE "${P16_JNA_INCLUDE_PATTERNS}" EXCLUDE "${P16_JNA_EXCLUDE_PATTERNS}")
bfn_find_tests("${P16_JNA_TESTS}" p16_jna_tests EXCLUDE "${P16_JNA_EXCLUDE_PATTERNS}")

file (GLOB STF_TESTS "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/stf/*.stf")
string (REGEX REPLACE "\\.stf;" ".p4;" STF_P4_TESTS "${STF_TESTS};")

file (GLOB PTF_TESTS "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/ptf/*.ptf")
string (REGEX REPLACE "\\.ptf;" ".p4;" PTF_P4_TESTS "${PTF_TESTS};")

# Exclude some p4s with conditional checksum updates that are added separately
set (P4_14_EXCLUDE_FILES "parser_dc_full\\.p4" "sai_p4\\.p4"
                            "checksum_pragma\\.p4" "port_vlan_mapping\\.p4"
                            "checksum\\.p4"
                            "decaf_9\\.p4"
                            "-FullTPHV")
set (P4_14_SAMPLES "${P4TESTDATA}/p4_14_samples/*.p4")
bfn_find_tests("${P4_14_SAMPLES}" p4_14_samples EXCLUDE "${P4_14_EXCLUDE_FILES}")

set (CLOUDBREAK_V1_TEST_SUITES_P414
# ${p4_14_samples}   -- don't run p4c tests on cloudbreak as they need
#  ${v1tests}        -- port rewriting
  ${STF_P4_TESTS}
  ${PTF_P4_TESTS}
# p4_14_samples
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/bf_p4c_samples/*.p4
  )
set (CLOUDBREAK_V1_TEST_SUITES_P416
  ${p16_v1tests}
# p4_16_samples
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/bf_p4c_samples/*.p4
  )
p4c_add_bf_backend_tests("tofino3" "cb" "${CLOUDBREAK_P414_TEST_ARCH}" "base" "${CLOUDBREAK_V1_TEST_SUITES_P414}" "-I${CMAKE_CURRENT_SOURCE_DIR}/p4_16/includes")
p4c_add_bf_backend_tests("tofino3" "cb" "v1model" "base" "${CLOUDBREAK_V1_TEST_SUITES_P416}" "-I${CMAKE_CURRENT_SOURCE_DIR}/p4_16/includes")
bfn_needs_scapy("tofino3" "extensions/p4_tests/p4_14/ptf/inner_checksum_l4.p4")

# P4C-2985
# We need to create two tests with different args for one p4 file.
# We utilize the fact that p4c_add_bf_backend_tests and p4c_add_test_with_args use the same name
# of the *.test file if there is more tests for one *.p4 file, so we create test with command line option
# --parser-inline-opt here, and let the other test be created as part of tests created from variable
# CLOUDBREAK_JNA_TEST_SUITES.
p4c_find_test_names("${CMAKE_CURRENT_SOURCE_DIR}/p4_16/stf/p4c-2985.p4" P4C_2985_TESTNAME)
bfn_add_test_with_args("tofino3" "cb" "parser-inline-opt/${P4C_2985_TESTNAME}" ${P4C_2985_TESTNAME} "" "--parser-inline-opt")
p4c_add_test_label("tofino3" "base;stf" "parser-inline-opt/${P4C_2985_TESTNAME}")

p4c_add_ptf_test_with_ptfdir ("tofino3" "mirror_constants"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/ptf/mirror_constants.p4"
    "${testExtraArgs} -target tofino3 -arch t3na -bfrt"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/ptf/mirror_constants.ptf")
bfn_needs_scapy("tofino3" "mirror_constants")

p4c_add_ptf_test_with_ptfdir (
    "tofino3" "p4c_2601" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/ptf/p4c_2601.p4"
    "${testExtraArgs} -target tofino3 -arch t3na -bfrt --p4runtime-force-std-externs"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/ptf/p4c_2601.ptf")
bfn_needs_scapy("tofino3" "p4c_2601")

p4c_add_ptf_test_with_ptfdir (
    "tofino3" "hash_extern_xor" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/ptf/hash_extern_xor.p4"
    "${testExtraArgs} -target tofino3 -arch t3na -bfrt --p4runtime-force-std-externs"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/ptf/hash_extern_xor.ptf")
bfn_needs_scapy("tofino3" "hash_extern_xor")

p4c_add_ptf_test_with_ptfdir (
    "tofino3" "hash_field_expression" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/ptf/hash_field_expression.p4"
    "${testExtraArgs} -target tofino3 -arch t3na -bfrt --p4runtime-force-std-externs"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/ptf/hash_field_expression.ptf")
bfn_needs_scapy("tofino3" "hash_field_expression")

p4c_add_ptf_test_with_ptfdir (
    "tofino3" "hash_field_expression_sym" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/ptf/hash_field_expression_sym.p4"
    "${testExtraArgs} -target tofino3 -arch t3na -bfrt --p4runtime-force-std-externs"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/ptf/hash_field_expression_sym.ptf")
bfn_needs_scapy("tofino3" "hash_field_expression_sym")

set (CLOUDBREAK_JNA_TEST_SUITES
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/jbay/*.p4)
p4c_find_tests("${CLOUDBREAK_JNA_TEST_SUITES}" cloudbreak_jna_tests INCLUDE "${P16_JNA_INCLUDE_PATTERNS}" EXCLUDE "${P16_JNA_EXCLUDE_PATTERNS}")
set (cloudbreak_jna_tests ${cloudbreak_jna_tests} ${p16_jna_tests})
p4c_add_bf_backend_tests("tofino3" "cb" "t3na" "base" "${cloudbreak_jna_tests}" "-I${CMAKE_CURRENT_SOURCE_DIR}/p4_16/includes")
bfn_needs_scapy("tofino3" "extensions/p4_tests/p4_16/ptf/inner_checksum.p4")
bfn_needs_scapy("tofino3" "extensions/p4_tests/p4_16/ptf/inner_checksum_payload_offset.p4")
bfn_needs_scapy("tofino3" "extensions/p4_tests/p4_16/ptf/large_indirect_count.p4")
bfn_needs_scapy("tofino3" "extensions/p4_tests/p4_16/ptf/options_invalid.p4")

p4c_add_bf_backend_tests("tofino3" "cb" "t3na" "base" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/compile_only/p4c-2740.p4")
set_tests_properties("tofino3/extensions/p4_tests/p4_16/compile_only/p4c-2740.p4" PROPERTIES TIMEOUT ${extended_timeout_4times})

# P4C-4079
# New HeaderMutex pass increases compilation time.
p4c_add_bf_backend_tests("tofino3" "cb" "t3na" "base" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/customer/keysight/keysight-eagle-tf2.p4" "-to 1200")
set_tests_properties("tofino3/extensions/p4_tests/p4_16/customer/keysight/keysight-eagle-tf2.p4" PROPERTIES TIMEOUT 1200)
p4c_add_bf_backend_tests("tofino3" "cb" "t3na" "base" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/stf/p4c-4055.p4" "-to 1200")
set_tests_properties("tofino3/extensions/p4_tests/p4_16/stf/p4c-4055.p4" PROPERTIES TIMEOUT 1200)

## P4-16 Programs
set (P4FACTORY_P4_16_PROGRAMS
  tna_32q_2pipe
  tna_action_profile
  tna_action_selector
  tna_bridged_md
  tna_counter
  tna_custom_hash
  tna_digest
  tna_dkm
  tna_exact_match
  tna_idletimeout
  tna_lpm_match
  tna_meter_bytecount_adjust
  tna_meter_lpf_wred
  tna_mirror
  tna_multicast
  tna_operations
  tna_port_metadata
  tna_port_metadata_extern
  tna_proxy_hash
  tna_pvs
  tna_random
  tna_range_match
  tna_register
  tna_snapshot
  tna_symmetric_hash
  tna_ternary_match
  tna_timestamp
  t2na_counter_true_egress_accounting
)

# No ptf, compile-only
#file(RELATIVE_PATH p4_16_programs_path ${P4C_SOURCE_DIR} ${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/p4_16_programs)

bfn_add_test_with_args ("tofino3" "cb" "p4_16_programs_tna_32q_multiprogram_a"
    ${p4_16_programs_path}/tna_32q_multiprogram/program_a/tna_32q_multiprogram_a.p4 "${testExtraArgs} -arch t3na -I${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/p4_16_programs/tna_32q_multiprogram" "")

bfn_add_test_with_args ("tofino3" "cb" "p4_16_programs_tna_32q_multiprogram_b"
    ${p4_16_programs_path}/tna_32q_multiprogram/program_b/tna_32q_multiprogram_b.p4 "${testExtraArgs} -arch t3na -I${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/p4_16_programs/tna_32q_multiprogram" "")

bfn_add_test_with_args ("tofino3" "cb" "p4_16_programs_tna_resubmit"
    ${p4_16_programs_path}/tna_resubmit/tna_resubmit.p4 "${testExtraArgs} -arch t3na -I${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/p4_16_programs/tna_resubmit" "")

bfn_add_test_with_args ("tofino3" "cb" "p4_16_programs_tna_pktgen"
    ${p4_16_programs_path}/tna_pktgen/tna_pktgen.p4 "${testExtraArgs} -arch t3na -I${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/p4_16_programs/tna_pktgen" "")
bfn_set_ptf_test_spec("tofino3" "p4_16_programs_tna_pktgen" "all ^test.PortDownPktgenTest")

bfn_add_test_with_args ("tofino3" "cb" "p4_16_internal_p4_16_ipv4_checksum"
    ${p4_16_internal_p4_16_path}/ipv4_checksum/ipv4_checksum.p4 "${testExtraArgs} -arch t3na -I${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/internal_p4_16" "")
bfn_add_test_with_args ("tofino3" "cb" "p4_16_internal_p4_16_mirror"
    ${p4_16_internal_p4_16_path}/mirror/mirror.p4 "${testExtraArgs} -arch t3na -I${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/internal_p4_16" "")


# P4-16 Programs with PTF tests
foreach(t IN LISTS P4FACTORY_P4_16_PROGRAMS)
  p4c_add_ptf_test_with_ptfdir ("tofino3" "p4_16_programs_${t}" "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/p4_16_programs/${t}/${t}.p4"
    "${testExtraArgs} -target tofino3 -arch t3na -bfrt" "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/p4_16_programs/${t}")
  bfn_set_p4_build_flag("tofino3" "p4_16_programs_${t}" "-I${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/p4_16_programs")
  set (ports_json ${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/p4_16_programs/${t}/ports_tof3.json)
  if (EXISTS ${ports_json})
    bfn_set_ptf_ports_json_file("tofino3" "p4_16_programs_${t}" ${ports_json})
  endif()
endforeach()

# Set ports.json for tna_idletime test
bfn_set_ptf_ports_json_file("tofino3" "p4_16_programs_tna_dkm" "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/p4_16_programs/tna_dkm/ports.json")
bfn_set_ptf_ports_json_file("tofino3" "p4_16_programs_tna_idletimeout" "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/p4_16_programs/tna_idletimeout/ports.json")

# 500s timeout is too little for compiling and testing the entire switch, bumping it up
set_tests_properties("tofino3/p4_16_programs_tna_exact_match" PROPERTIES TIMEOUT ${extended_timeout_2times})
set_tests_properties("tofino3/p4_16_programs_tna_ternary_match" PROPERTIES TIMEOUT ${extended_timeout_4times})


# P4C-4718
set(TOFINO3_DETERMINISM_TESTS_14
    ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/pd/decaf_10/decaf_10.p4
    ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/stf/decaf_3.p4
    ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/stf/decaf_8.p4
    ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/ptf/inner_checksum_l4.p4
  )
foreach(t IN LISTS TOFINO3_DETERMINISM_TESTS_14)
  get_filename_component(_base_name ${t} NAME_WE)
  bfn_add_determinism_test_with_args("tofino3" "${P414_TEST_ARCH}" ${t} "--std=p4-14")
endforeach()

set(TOFINO3_DETERMINISM_TESTS_16
    ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/jbay/wide_arith.p4
    ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/stf/hdr_len_inc_stop_2.p4
  )
foreach(t IN LISTS TOFINO3_DETERMINISM_TESTS_16)
  get_filename_component(_base_name ${t} NAME_WE)
  bfn_add_determinism_test_with_args("tofino3" "t3na" ${t} "")
endforeach()

include(SwitchCloudbreak.cmake)
include(CloudbreakXfail.cmake)
include(CloudbreakErrors.cmake)
