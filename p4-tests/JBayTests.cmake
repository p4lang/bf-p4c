set (tofino2_timeout ${default_test_timeout})

# check for PTF requirements
packet_test_setup_check("jbay")
# check for STF requirements
simple_test_setup_check("jbay")

set (V1_SEARCH_PATTERNS "include.*(v1model|psa).p4" "main")
set (P4TESTDATA ${P4C_SOURCE_DIR}/testdata)
set (P4TESTS_FOR_JBAY "${P4TESTDATA}/p4_16_samples/*.p4")
p4c_find_tests("${P4TESTS_FOR_JBAY}" v1tests INCLUDE "${V1_SEARCH_PATTERNS}")

set (P16_V1_INCLUDE_PATTERNS "include.*v1model.p4" "main|common_v1_test")
set (P16_V1_EXCLUDE_PATTERNS "tofino\\.h")
set (P16_V1_FOR_JBAY
  "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/compile_only/*.p4"
  "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/stf/*.p4"
  "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/ptf/*.p4")
p4c_find_tests("${P16_V1_FOR_JBAY}" p16_v1tests INCLUDE "${P16_V1_INCLUDE_PATTERNS}" EXCLUDE "${P16_V1_EXCLUDE_PATTERNS}")

set (P16_JNA_INCLUDE_PATTERNS "include.*(t2?na|tofino2_arch).p4" "main|common_tna_test|common_t2na_test")
set (P16_JNA_EXCLUDE_PATTERNS
  "tofino\\.h" "TOFINO1_ONLY" "<built-in>"
  "hash_extern_xor\\.p4"
  "hash_field_expression\\.p4"
  "hash_field_expression_sym\\.p4"
)

include(JBayErrors.cmake)

set (P16_JNA_EXCLUDE_FILES ${DIAGNOSTIC_TESTS_JBAY})
set (P16_JNA_FOR_JBAY 
                      "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/compile_only/*.p4"
                      "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/stf/*.p4"
                      "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/ptf/*.p4"
                      "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/jbay/*.p4")
p4c_find_tests("${P16_JNA_FOR_JBAY}" P16_JNA_TESTS INCLUDE "${P16_JNA_INCLUDE_PATTERNS}" EXCLUDE "${P16_JNA_EXCLUDE_PATTERNS}")
bfn_find_tests("${P16_JNA_TESTS}" p16_jna_tests EXCLUDE "${P16_JNA_EXCLUDE_PATTERNS};${P16_JNA_EXCLUDE_FILES}")
file (GLOB STF_TESTS "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/stf/*.stf")
string (REGEX REPLACE "\\.stf;" ".p4;" STF_P4_TESTS "${STF_TESTS};")

file (GLOB PTF_TESTS "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/ptf/*.ptf")
string (REGEX REPLACE "\\.ptf;" ".p4;" PTF_P4_TESTS "${PTF_TESTS};")

set (JBAY_JNA_TEST_SUITES
  ${p16_jna_tests}
  )

p4c_add_bf_backend_tests("tofino2" "jbay" "t2na" "base" "${JBAY_JNA_TEST_SUITES}" "-I${CMAKE_CURRENT_SOURCE_DIR}/p4_16/includes")
p4c_add_bf_diagnostic_tests("tofino2" "jbay" "t2na" "base" "${P16_JNA_INCLUDE_PATTERNS}" "${P16_JNA_EXCLUDE_PATTERNS}" "p4_16")
set_tests_properties("tofino2/extensions/p4_tests/p4_16/ptf/options_invalid.p4" PROPERTIES TIMEOUT ${extended_timeout_2times})

bfn_needs_scapy("tofino2" "extensions/p4_tests/p4_16/ptf/inner_checksum_payload_offset.p4")
bfn_needs_scapy("tofino2" "extensions/p4_tests/p4_16/ptf/options_invalid.p4")
bfn_needs_scapy("tofino2" "extensions/p4_tests/p4_16/ptf/inner_checksum.p4")
bfn_needs_scapy("tofino2" "extensions/p4_tests/p4_16/ptf/large_indirect_count.p4")

set(TOFINO2_DETERMINISM_TESTS_14
    ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/stf/decaf_3.p4
    ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/stf/decaf_8.p4
    ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/ptf/inner_checksum_l4.p4
  )
foreach(t IN LISTS TOFINO2_DETERMINISM_TESTS_14)
  bfn_add_determinism_test_with_args("tofino2" "${P414_TEST_ARCH}" ${t} "--std=p4-14")
endforeach()

set(TOFINO2_DETERMINISM_TESTS_16
    ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/jbay/wide_arith.p4
    ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/stf/hdr_len_inc_stop_2.p4
  )
foreach(t IN LISTS TOFINO2_DETERMINISM_TESTS_16)
  get_filename_component(_base_name ${t} NAME_WE)
  bfn_add_determinism_test_with_args("tofino2" "t2na" ${t} "")
endforeach()

# Exclude some p4s with conditional checksum updates that are added separately
set (P4_14_EXCLUDE_FILES "parser_dc_full\\.p4" "sai_p4\\.p4"
                            "checksum_pragma\\.p4" "port_vlan_mapping\\.p4"
                            "checksum\\.p4"
                            "decaf_9\\.p4"
                            "-FullTPHV")
set (P4_14_SAMPLES "${P4TESTDATA}/p4_14_samples/*.p4")
bfn_find_tests("${P4_14_SAMPLES}" p4_14_samples EXCLUDE "${P4_14_EXCLUDE_FILES}")

set (JBAY_V1_TEST_SUITES_P414
  ${p4_14_samples}
#  ${v1tests}
  ${STF_P4_TESTS}
  ${PTF_P4_TESTS}
# p4_14_samples
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/bf_p4c_samples/*.p4
  )
set (JBAY_V1_TEST_SUITES_P416
  ${p16_v1tests}
# p4_16_samples
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/bf_p4c_samples/*.p4
  )

p4c_add_bf_backend_tests("tofino2" "jbay" "${JBAY_P414_TEST_ARCH}" "base" "${JBAY_V1_TEST_SUITES_P414}" "-I${CMAKE_CURRENT_SOURCE_DIR}/p4_16/includes")
bfn_needs_scapy("tofino2" "extensions/p4_tests/p4_14/ptf/inner_checksum_l4.p4")

# PTF tests with different parameters
p4c_add_ptf_test_with_ptfdir ("tofino2" "mirror_constants"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/ptf/mirror_constants.p4"
    "${testExtraArgs} -target tofino2 -arch t2na -bfrt"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/ptf/mirror_constants.ptf")
bfn_needs_scapy("tofino2" "mirror_constants")

p4c_add_ptf_test_with_ptfdir (
    "tofino2" "hash_extern_xor" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/ptf/hash_extern_xor.p4"
    "${testExtraArgs} -target tofino2 -arch t2na -bfrt --p4runtime-force-std-externs"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/ptf/hash_extern_xor.ptf")
bfn_needs_scapy("tofino2" "hash_extern_xor")

p4c_add_ptf_test_with_ptfdir (
    "tofino2" "hash_field_expression" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/ptf/hash_field_expression.p4"
    "${testExtraArgs} -target tofino2 -arch t2na -bfrt --p4runtime-force-std-externs"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/ptf/hash_field_expression.ptf")
bfn_needs_scapy("tofino2" "hash_field_expression")

p4c_add_ptf_test_with_ptfdir (
    "tofino2" "hash_field_expression_sym" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/ptf/hash_field_expression_sym.p4"
    "${testExtraArgs} -target tofino2 -arch t2na -bfrt --p4runtime-force-std-externs"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/ptf/hash_field_expression_sym.ptf")
bfn_needs_scapy("tofino2" "hash_field_expression_sym")

file(RELATIVE_PATH tofino32q-3pipe_path ${P4C_SOURCE_DIR} ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/tofino32q-3pipe/sfc.p4)
bfn_add_test_with_args ("tofino2" "jbay" "tofino32q-3pipe" ${tofino32q-3pipe_path} "${testExtraArgs} -arch t2na" "")

p4c_add_bf_backend_tests("tofino2" "jbay" "v1model" "base" "${JBAY_V1_TEST_SUITES_P416}" "-I${CMAKE_CURRENT_SOURCE_DIR}/p4_16/includes")


include(JBayXfail.cmake)
include(JBayMustPass.cmake)
