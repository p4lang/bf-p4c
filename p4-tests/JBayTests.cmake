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
  "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/customer/*/*.p4"    # JIRA-DOC:
  "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/compile_only/*.p4"
  "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/*.p4"               # JIRA-DOC:
  "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/ptf/*.p4"           # JIRA-DOC:
  "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/stf/*.p4"           # JIRA-DOC:
  "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/stf/*.p4"
  "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/ptf/*.p4")
p4c_find_tests("${P16_V1_FOR_JBAY}" p16_v1tests INCLUDE "${P16_V1_INCLUDE_PATTERNS}" EXCLUDE "${P16_V1_EXCLUDE_PATTERNS}")

set (P16_JNA_INCLUDE_PATTERNS "include.*(t2?na|tofino2_arch).p4" "main|common_tna_test|common_t2na_test")
set (P16_JNA_EXCLUDE_PATTERNS
  "tofino\\.h" "TOFINO1_ONLY" "<built-in>"
  "hash_extern_xor\\.p4"
  "hash_field_expression\\.p4"
  "hash_field_expression_sym\\.p4"
  "p4c-1323-b\\.p4"                           # JIRA-DOC:
  "p4c-1587-a\\.p4"                           # JIRA-DOC:
  "p4c-2537\\.p4"                             # JIRA-DOC:
  "p4c-2794\\.p4"                             # JIRA-DOC:
  "p4c-3001\\.p4"                             # JIRA-DOC:
  "p4c-3030-2\\.p4"                           # JIRA-DOC:
  "obfuscated-ddos_tofino2\\.p4"              # JIRA-DOC:
  "obfuscated-hybrid_default_tofino2\\.p4"    # JIRA-DOC:
  "obfuscated-l2_dci\\.p4"                    # JIRA-DOC:
  "hash_conflicts\\.p4"                       # JIRA-DOC:
  "obfuscated-msee_tofino2\\.p4"              # JIRA-DOC:
  "obfuscated-nat_tofino2\\.p4"               # JIRA-DOC:
  "obfuscated-p416_baremetal_tofino2\\.p4"    # JIRA-DOC:
  "p4c-2641\\.p4"                             # JIRA-DOC:
  "p4c-3528\\.p4"                             # JIRA-DOC:
  "npb-GA\\.p4"                               # JIRA-DOC:
  "npb-master-20210108\\.p4"                  # JIRA-DOC:
  "npb-master-20210202\\.p4"                  # JIRA-DOC:
  "npb-master-20210211\\.p4"                  # JIRA-DOC:
  "npb-master-20210225\\.p4"                  # JIRA-DOC:
  "npb-master-20210301\\.p4"                  # JIRA-DOC:
  "npb-97-ga\\.p4"                            # JIRA-DOC:
  "p4c-3455.p4"                               # JIRA-DOC:
  "p4c-3455_2.p4"                             # JIRA-DOC:
  "p4c-3454\\.p4"                             # JIRA-DOC:
  "p4c-3476\\.p4"                             # JIRA-DOC:
  "p4c-2740\\.p4"                             # JIRA-DOC:
  "p4c-2490\\.p4"                             # JIRA-DOC:
  "p4c-2649\\.p4"                             # JIRA-DOC:
  "p4c-4535\\.p4"                             # JIRA-DOC:
  "p4c-4127\\.p4"                             # JIRA-DOC:
  "p4c-3288\\.p4"                             # JIRA-DOC:
  "p4c_2601\\.p4"                             # JIRA-DOC:
  "p4c-2602\\.p4"                             # JIRA-DOC:
  "mirror_constants\\.p4"                     # JIRA-DOC:
  "keysight-eagle-tf2\\.p4"                   # JIRA-DOC:
  "p4c-4055\\.p4"                             # JIRA-DOC:
  "MODEL-1095\\.p4"                           # JIRA-DOC:
  "p4c-4072\\.p4"                             # JIRA-DOC:
  "p4c-4943\\.p4"                             # JIRA-DOC:
  "p4c-3582\\.p4"                             # JIRA-DOC:
  "p4c-5223-leaf-tof2\\.p4"                   # JIRA-DOC:
)

include(JBayErrors.cmake)

set (P16_JNA_EXCLUDE_FILES ${DIAGNOSTIC_TESTS_JBAY})
set (P16_JNA_FOR_JBAY 
                      "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/customer/*/*.p4"    # JIRA-DOC:
                      "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/compile_only/*.p4"
                      "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/*.p4"               # JIRA-DOC:
                      "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/jbay/*.p4"          # JIRA-DOC:
                      "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/ptf/*.p4"           # JIRA-DOC:
                      "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/stf/*.p4"           # JIRA-DOC:
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

# JIRA-DOC: P4C-4718
set(TOFINO2_DETERMINISM_TESTS_14
    ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/internal/pd/decaf_10/decaf_10.p4            # JIRA-DOC:
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

if (CLOSED_SOURCE)
# Internal

# We need to create two tests with different args for one p4 file.
# We utilize the fact that p4c_add_bf_backend_tests and p4c_add_test_with_args use the same name
# of the *.test file if there is more tests for one *.p4 file, so we create test with command line option
# --parser-inline-opt here, and let the other test be created as part of tests created from variable
# JBAY_JNA_TEST_SUITES.
bfn_add_test_with_args("tofino2" "jbay" "parser-inline-opt/${P4C_2985_TESTNAME}" ${P4C_2985_TESTNAME} "" "--parser-inline-opt")
p4c_add_test_label("tofino2" "base;stf" "parser-inline-opt/${P4C_2985_TESTNAME}")
p4c_find_test_names("${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/stf/p4c-2985.p4" P4C_2985_TESTNAME)
p4c_add_bf_backend_tests("tofino2" "jbay" "t2na" "base" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/jbay/p4c-3288.p4")

# longer timeout
set_tests_properties("tofino2/extensions/p4_tests/p4_16/internal/jbay/p4c-3288.p4" PROPERTIES TIMEOUT ${extended_timeout_2times})
p4c_add_bf_backend_tests("tofino2" "jbay" "t2na" "base" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/customer/extreme/npb-master-20210108.p4")
set_tests_properties("tofino2/extensions/p4_tests/p4_16/internal/customer/extreme/npb-master-20210108.p4" PROPERTIES TIMEOUT ${extended_timeout_6times})
p4c_add_bf_backend_tests("tofino2" "jbay" "t2na" "base" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/customer/extreme/npb-master-20210202.p4")
set_tests_properties("tofino2/extensions/p4_tests/p4_16/internal/customer/extreme/npb-master-20210202.p4" PROPERTIES TIMEOUT ${extended_timeout_6times})
p4c_add_bf_backend_tests("tofino2" "jbay" "t2na" "base" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/customer/extreme/npb-master-20210211.p4")
set_tests_properties("tofino2/extensions/p4_tests/p4_16/internal/customer/extreme/npb-master-20210211.p4" PROPERTIES TIMEOUT ${extended_timeout_6times})
p4c_add_bf_backend_tests("tofino2" "jbay" "t2na" "base" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/customer/extreme/npb-master-20210225.p4")
set_tests_properties("tofino2/extensions/p4_tests/p4_16/internal/customer/extreme/npb-master-20210225.p4" PROPERTIES TIMEOUT ${extended_timeout_6times})
p4c_add_bf_backend_tests("tofino2" "jbay" "t2na" "base" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/customer/extreme/npb-master-20210301.p4")
set_tests_properties("tofino2/extensions/p4_tests/p4_16/internal/customer/extreme/npb-master-20210301.p4" PROPERTIES TIMEOUT ${extended_timeout_8times})
p4c_add_bf_backend_tests("tofino2" "jbay" "t2na" "base" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/customer/extreme/npb-97-ga.p4" "-to ${extended_timeout_3times}")
set_tests_properties("tofino2/extensions/p4_tests/p4_16/internal/customer/extreme/npb-97-ga.p4" PROPERTIES TIMEOUT ${extended_timeout_4times})  # timeout here must be longer than in `-to`
p4c_add_bf_backend_tests("tofino2" "jbay" "t2na" "base" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/p4c-3528.p4")
set_tests_properties("tofino2/extensions/p4_tests/p4_16/internal/p4c-3528.p4" PROPERTIES TIMEOUT ${extended_timeout_4times})
p4c_add_bf_backend_tests("tofino2" "jbay" "t2na" "base" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/customer/extreme/p4c-3455.p4")
set_tests_properties("tofino2/extensions/p4_tests/p4_16/internal/customer/extreme/p4c-3455.p4" PROPERTIES TIMEOUT ${extended_timeout_4times})
p4c_add_bf_backend_tests("tofino2" "jbay" "t2na" "base" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/customer/extreme/p4c-3455_2.p4")
set_tests_properties("tofino2/extensions/p4_tests/p4_16/internal/customer/extreme/p4c-3455_2.p4" PROPERTIES TIMEOUT ${extended_timeout_4times})
p4c_add_bf_backend_tests("tofino2" "jbay" "t2na" "base" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/customer/extreme/p4c-3454.p4")
set_tests_properties("tofino2/extensions/p4_tests/p4_16/internal/customer/extreme/p4c-3454.p4" PROPERTIES TIMEOUT ${extended_timeout_2times})
p4c_add_bf_backend_tests("tofino2" "jbay" "t2na" "base" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/customer/extreme/p4c-3476.p4")
set_tests_properties("tofino2/extensions/p4_tests/p4_16/internal/customer/extreme/p4c-3476.p4" PROPERTIES TIMEOUT ${extended_timeout_2times})
p4c_add_bf_backend_tests("tofino2" "jbay" "t2na" "base" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/p4c-2740.p4")
set_tests_properties("tofino2/extensions/p4_tests/p4_16/internal/p4c-2740.p4" PROPERTIES TIMEOUT ${extended_timeout_4times})
p4c_add_bf_backend_tests("tofino2" "jbay" "t2na" "base" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/p4c-2490.p4")
set_tests_properties("tofino2/extensions/p4_tests/p4_16/internal/p4c-2490.p4" PROPERTIES TIMEOUT ${extended_timeout_4times})
p4c_add_bf_backend_tests("tofino2" "jbay" "t2na" "base" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/customer/extreme/p4c-2649.p4" "-to ${extended_timeout_3times}")
set_tests_properties("tofino2/extensions/p4_tests/p4_16/internal/customer/extreme/p4c-2649.p4" PROPERTIES TIMEOUT ${extended_timeout_4times})
p4c_add_bf_backend_tests("tofino2" "jbay" "t2na" "base" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/stf/p4c-4535.p4" "-to ${extended_timeout_5times} -I${CMAKE_CURRENT_SOURCE_DIR}/p4_16/includes")
set_tests_properties("tofino2/extensions/p4_tests/p4_16/internal/stf/p4c-4535.p4" PROPERTIES TIMEOUT ${extended_timeout_5times})

# Arista profiles need a longer timeout
#
# First test has a PTF to test table programming on one table
p4c_add_ptf_test_with_ptfdir (
    "tofino2" "extensions/p4_tests/p4_16/internal/customer/arista/hash_conflicts/hash_conflicts.p4" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/customer/arista/hash_conflicts/hash_conflicts.p4"
    "${testExtraArgs} -target tofino2 -arch t2na -bfrt"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/customer/arista/hash_conflicts")
bfn_set_p4_build_flag("tofino2" "extensions/p4_tests/p4_16/internal/customer/arista/hash_conflicts/hash_conflicts.p4" "-Xp4c=\"--disable-power-check\"")
set_tests_properties("tofino2/extensions/p4_tests/p4_16/internal/customer/arista/hash_conflicts/hash_conflicts.p4" PROPERTIES TIMEOUT ${extended_timeout_8times})

p4c_add_bf_backend_tests("tofino2" "jbay" "t2na" "base" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/customer/arista/obfuscated-msee_tofino2.p4" "-Xp4c=\"--set-max-power 65.0\"")
set_tests_properties("tofino2/extensions/p4_tests/p4_16/internal/customer/arista/obfuscated-msee_tofino2.p4" PROPERTIES TIMEOUT ${extended_timeout_8times})
p4c_add_test_label("tofino2" "METRICS" "extensions/p4_tests/p4_16/internal/customer/arista/obfuscated-msee_tofino2.p4")

p4c_add_bf_backend_tests("tofino2" "jbay" "t2na" "base" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/customer/arista/obfuscated-l2_dci.p4" "-Xp4c=--disable-power-check")
set_tests_properties("tofino2/extensions/p4_tests/p4_16/internal/customer/arista/obfuscated-l2_dci.p4" PROPERTIES TIMEOUT ${extended_timeout_8times})
p4c_add_test_label("tofino2" "METRICS" "extensions/p4_tests/p4_16/internal/customer/arista/obfuscated-l2_dci.p4")
p4c_add_bf_backend_tests("tofino2" "jbay" "t2na" "base" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/customer/ruijie/p4c-4127.p4")
set_tests_properties("tofino2/extensions/p4_tests/p4_16/internal/customer/ruijie/p4c-4127.p4" PROPERTIES TIMEOUT ${extended_timeout_4times})

p4c_add_bf_backend_tests("tofino2" "jbay" "t2na" "base" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/customer/arista/obfuscated-p416_baremetal_tofino2.p4" "-Xp4c=\"--set-max-power 62.0\"")
set_tests_properties("tofino2/extensions/p4_tests/p4_16/internal/customer/arista/obfuscated-p416_baremetal_tofino2.p4" PROPERTIES TIMEOUT ${extended_timeout_8times})
p4c_add_test_label("tofino2" "METRICS" "extensions/p4_tests/p4_16/internal/customer/arista/obfuscated-p416_baremetal_tofino2.p4")

p4c_add_bf_backend_tests("tofino2" "jbay" "t2na" "base" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/customer/arista/obfuscated-nat_tofino2.p4" "-Xp4c=\"--set-max-power 62.0\"")
set_tests_properties("tofino2/extensions/p4_tests/p4_16/internal/customer/arista/obfuscated-nat_tofino2.p4" PROPERTIES TIMEOUT ${extended_timeout_8times})
p4c_add_test_label("tofino2" "METRICS" "extensions/p4_tests/p4_16/internal/customer/arista/obfuscated-nat_tofino2.p4")

p4c_add_bf_backend_tests("tofino2" "jbay" "t2na" "base" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/customer/arista/obfuscated-hybrid_default_tofino2.p4" "-Xp4c=\"--set-max-power 65.0\"")
set_tests_properties("tofino2/extensions/p4_tests/p4_16/internal/customer/arista/obfuscated-hybrid_default_tofino2.p4" PROPERTIES TIMEOUT ${extended_timeout_8times})
p4c_add_test_label("tofino2" "METRICS" "extensions/p4_tests/p4_16/internal/customer/arista/obfuscated-hybrid_default_tofino2.p4")

p4c_add_bf_backend_tests("tofino2" "jbay" "t2na" "base" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/customer/arista/obfuscated-ddos_tofino2.p4" "-Xp4c=--disable-power-check")
set_tests_properties("tofino2/extensions/p4_tests/p4_16/internal/customer/arista/obfuscated-ddos_tofino2.p4" PROPERTIES TIMEOUT ${extended_timeout_6times})
p4c_add_test_label("tofino2" "METRICS" "extensions/p4_tests/p4_16/internal/customer/arista/obfuscated-ddos_tofino2.p4")

# longer timeout
p4c_add_bf_backend_tests("tofino2" "jbay" "t2na" "base" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/customer/extreme/p4c-2641.p4")
set_tests_properties("tofino2/extensions/p4_tests/p4_16/internal/customer/extreme/p4c-2641.p4" PROPERTIES TIMEOUT ${extended_timeout_6times})

# p4_16/internal/customer/extreme/p4c-1323-b.p4 needs a longer timeout.
p4c_add_bf_backend_tests("tofino2" "jbay" "t2na" "base" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/customer/extreme/p4c-1323-b.p4")
set_tests_properties("tofino2/extensions/p4_tests/p4_16/internal/customer/extreme/p4c-1323-b.p4" PROPERTIES TIMEOUT ${extended_timeout_2times})

p4c_add_bf_backend_tests("tofino2" "jbay" "t2na" "base" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/customer/extreme/p4c-1587-a.p4")
set_tests_properties("tofino2/extensions/p4_tests/p4_16/internal/customer/extreme/p4c-1587-a.p4" PROPERTIES TIMEOUT ${extended_timeout_2times})

p4c_add_bf_backend_tests("tofino2" "jbay" "t2na" "base" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/customer/extreme/p4c-2794.p4")
set_tests_properties("tofino2/extensions/p4_tests/p4_16/internal/customer/extreme/p4c-2794.p4" PROPERTIES TIMEOUT ${extended_timeout_6times})

p4c_add_bf_backend_tests("tofino2" "jbay" "t2na" "base" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/customer/extreme/p4c-3001.p4")
set_tests_properties("tofino2/extensions/p4_tests/p4_16/internal/customer/extreme/p4c-3001.p4" PROPERTIES TIMEOUT ${extended_timeout_6times})

p4c_add_bf_backend_tests("tofino2" "jbay" "t2na" "base" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/customer/extreme/p4c-3030-2.p4")
set_tests_properties("tofino2/extensions/p4_tests/p4_16/internal/customer/extreme/p4c-3030-2.p4" PROPERTIES TIMEOUT ${extended_timeout_2times})

p4c_add_bf_backend_tests("tofino2" "jbay" "t2na" "base" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/customer/extreme/p4c-3473-a2.p4")
set_tests_properties("tofino2/extensions/p4_tests/p4_16/internal/customer/extreme/p4c-3473-a2.p4" PROPERTIES TIMEOUT ${extended_timeout_2times})

set_tests_properties("tofino2/extensions/p4_tests/p4_16/internal/customer/extreme/p4c-2918-2.p4" PROPERTIES TIMEOUT ${extended_timeout_2times})

# Kaloom leaf profile needs extra flags.
p4c_add_bf_backend_tests("tofino2" "jbay" "t2na" "base" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/customer/kaloom/p4c-5223-leaf-tof2.p4" "-Xp4c=\"--traffic-limit 95 --disable-power-check --disable-parse-depth-limit\"")

p4c_add_test_label("tofino2" "CUST_MUST_PASS" "extensions/p4_tests/p4_16/internal/customer/extreme/npb-master-20210108.p4")
p4c_add_test_label("tofino2" "CUST_MUST_PASS" "extensions/p4_tests/p4_16/internal/customer/extreme/npb-master-20210202.p4")
p4c_add_test_label("tofino2" "CUST_MUST_PASS" "extensions/p4_tests/p4_16/internal/customer/extreme/npb-master-20210211.p4")
p4c_add_test_label("tofino2" "CUST_MUST_PASS" "extensions/p4_tests/p4_16/internal/customer/extreme/npb-master-20210225.p4")
p4c_add_test_label("tofino2" "CUST_MUST_PASS" "extensions/p4_tests/p4_16/internal/customer/extreme/npb-master-20210301.p4")
p4c_add_test_label("tofino2" "CUST_MUST_PASS" "extensions/p4_tests/p4_16/internal/customer/extreme/npb-97-ga.p4")

# PTF tests with different parameters
p4c_add_ptf_test_with_ptfdir (
    "tofino2" "p4c_2601" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/ptf/p4c_2601.p4"
    "${testExtraArgs} -target tofino2 -arch t2na -bfrt --p4runtime-force-std-externs"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/ptf/p4c_2601.ptf")
bfn_needs_scapy("tofino2" "p4c_2601")

p4c_add_ptf_test_with_ptfdir(
    "tofino2" "p4c-2602" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/ptf/p4c-2602.p4"
    "${testExtraArgs} -target tofino2 -arch t2na -bfrt --p4runtime-force-std-externs"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/ptf/p4c-2602.ptf")

p4c_add_ptf_test_with_ptfdir (
    "tofino2" "p4c_873" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/bfrt/p4c_873/p4c_873.p4"
    "${testExtraArgs} -bfrt -arch v1model" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/bfrt/p4c_873")

p4c_add_ptf_test_with_ptfdir (
    "tofino2" "p4c_1585" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/bfrt/p4c_1585/p4c_1585.p4"
    "${testExtraArgs} -target tofino2 -arch t2na -bfrt" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/bfrt/p4c_1585")

p4c_add_ptf_test_with_ptfdir (
    "tofino2" "p4c_3043" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/bfrt/p4c_3043/p4c_3043.p4"
    "${testExtraArgs} -target tofino2 -arch t2na -bfrt -Xp4c=\"--disable-power-check\"" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/bfrt/p4c_3043")
p4c_add_test_label("tofino2" "UNSTABLE" "p4c_3043")
set_tests_properties("tofino2/p4c_3043" PROPERTIES TIMEOUT ${extended_timeout_4times})

p4c_add_ptf_test_with_ptfdir (
    "tofino2" "p4c_1585_a" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/bfrt/p4c_1585_a/p4c_1585_a.p4"
    "${testExtraArgs} -target tofino2 -arch t2na -bfrt" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/bfrt/p4c_1585_a")

p4c_add_ptf_test_with_ptfdir (
    "tofino2" "p4c_1585_b" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/bfrt/p4c_1585_b/p4c_1585_b.p4"
    "${testExtraArgs} -target tofino2 -arch t2na -bfrt" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/bfrt/p4c_1585_b")

p4c_add_ptf_test_with_ptfdir (
    "tofino2" "p4c_1587" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/bfrt/p4c_1587/p4c_1587.p4"
    "${testExtraArgs} -target tofino2 -arch t2na -bfrt" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/bfrt/p4c_1587")
set_tests_properties("tofino2/p4c_1587" PROPERTIES TIMEOUT ${extended_timeout_2times})

p4c_add_ptf_test_with_ptfdir (
    "tofino2" "p4c_2527" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/bfrt/p4c_2527/npb.p4"
    "${testExtraArgs} -target tofino2 -arch t2na -bfrt" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/bfrt/p4c_2527")

p4c_add_ptf_test_with_ptfdir (
 "tofino2" "p4c_2549" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/bfrt/p4c_2549/p4c_2549.p4"
 "${testExtraArgs} -target tofino2 -arch t2na -bfrt"
 "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/bfrt/p4c_2549")
set_tests_properties("tofino2/p4c_2549" PROPERTIES TIMEOUT ${extended_timeout_4times})
bfn_needs_scapy("tofino2" "p4c_2549")

p4c_add_ptf_test_with_ptfdir (
    "tofino2" "p4c-3033" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/bfrt/p4c-3033/npb.p4"
    "${testExtraArgs} -target tofino2 -arch t2na -bfrt " "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/bfrt/p4c-3033")
set_tests_properties("tofino2/p4c-3033" PROPERTIES TIMEOUT ${extended_timeout_4times})
bfn_needs_scapy("tofino2" "p4c-3033")
p4c_add_test_label("tofino2" "UNSTABLE" "p4c-3033")

p4c_add_ptf_test_with_ptfdir (
    "tofino2" "p4c-3614" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/bfrt/p4c_3614/npb/npb.p4"
    "${testExtraArgs} -target tofino2 -arch t2na -bfrt " "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/bfrt/p4c_3614")
set_tests_properties("tofino2/p4c-3614" PROPERTIES TIMEOUT ${extended_timeout_4times})

p4c_add_ptf_test_with_ptfdir (
    "tofino2" "p4c-3379" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/bfrt/p4c-3379/npb.p4"
    "${testExtraArgs} -target tofino2 -arch t2na -bfrt"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/bfrt/p4c-3379")
set_tests_properties("tofino2/p4c-3379" PROPERTIES TIMEOUT ${extended_timeout_4times})

p4c_add_ptf_test_with_ptfdir (
    "tofino2" "p4c-3570" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/bfrt/p4c-3570/npb.p4"
    "${testExtraArgs} -target tofino2 -arch t2na -bfrt"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/bfrt/p4c-3570")
set_tests_properties("tofino2/p4c-3570" PROPERTIES TIMEOUT ${extended_timeout_2times})
bfn_needs_scapy("tofino2" "p4c-3570")

p4c_add_ptf_test_with_ptfdir (
    "tofino2" "p4c-3479" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/bfrt/p4c-3479/p4c_3479.p4"
    "${testExtraArgs} -target tofino2 -arch t2na -bfrt"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/bfrt/p4c-3479")
set_tests_properties("tofino2/p4c-3479" PROPERTIES TIMEOUT ${extended_timeout_2times})

p4c_add_ptf_test_with_ptfdir (
    "tofino2" "p4c-3876" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/bfrt/p4c-3876/p4c_3876.p4"
    "${testExtraArgs} -target tofino2 -arch t2na -bfrt"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/bfrt/p4c-3876")
set_tests_properties("tofino2/p4c-3876" PROPERTIES TIMEOUT ${extended_timeout_2times})
bfn_needs_scapy("tofino2" "p4c-3876")

p4c_add_ptf_test_with_ptfdir (
    "tofino2" "p4c-5236" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/bfrt/p4c-5236/p4/eagle_l47.p4"
    "${testExtraArgs} -target tofino2 -arch t2na -bfrt -I ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/bfrt/p4c-5236/p4"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/bfrt/p4c-5236/ptf")
set_tests_properties("tofino2/p4c-5236" PROPERTIES TIMEOUT ${extended_timeout_2times})

p4c_add_ptf_test_with_ptfdir (
    "tofino2" "npb-master-ptf"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/customer/extreme/npb-master-ptf/src/pgm_sp_npb_vcpFw_top.p4"
    "${testExtraArgs} -target tofino2 -arch t2na -bfrt"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/customer/extreme/npb-master-ptf/tests")
bfn_set_p4_build_flag("tofino2" "npb-master-ptf" "-I${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/customer/extreme/npb-master-ptf/src -I${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/customer/extreme/npb-master-ptf/src/pipeline_npb")
bfn_set_ptf_ports_json_file("tofino2" "npb-master-ptf" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/customer/extreme/npb-master-ptf/tests/ports.json")
set_tests_properties("tofino2/npb-master-ptf" PROPERTIES TIMEOUT ${extended_timeout_4times})

p4c_add_ptf_test_with_ptfdir (
    "tofino2" "p4c-5244"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/customer/extreme/p4c-5244/src/pgm_sp_npb_vcpFw_top.p4"
    "${testExtraArgs} -target tofino2 -arch t2na -bfrt"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/customer/extreme/p4c-5244/tests")
bfn_set_p4_build_flag("tofino2" "p4c-5244" "-I${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/customer/extreme/p4c-5244/src -I${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/customer/extreme/p4c-5244/src/pipeline_npb")
bfn_set_ptf_ports_json_file("tofino2" "p4c-5244" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/customer/extreme/p4c-5244/tests/ports.json")
set_tests_properties("tofino2/p4c-5244" PROPERTIES TIMEOUT ${extended_timeout_4times})

p4c_add_ptf_test_with_ptfdir (
    "tofino2" "npb-multi-prog"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/customer/extreme/npb-multi-prog/src/pgm_mp_npb_top.p4"
    "${testExtraArgs} -target tofino2 -arch t2na -bfrt"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/customer/extreme/npb-multi-prog/tests")
bfn_set_p4_build_flag("tofino2" "npb-multi-prog" "-I${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/customer/extreme/npb-multi-prog/src -I${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/customer/extreme/npb-multi-prog/src/pipeline_npb_igOnly_egOnly")
bfn_set_ptf_ports_json_file("tofino2" "npb-multi-prog" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/customer/extreme/npb-multi-prog/tests/ports.json")
set_tests_properties("tofino2/npb-multi-prog" PROPERTIES TIMEOUT ${extended_timeout_8times})

p4c_add_ptf_test_with_ptfdir (
    "tofino2" "npb-folded-pipe"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/customer/extreme/npb-folded-pipe/src/pgm_fp_npb_dedup_dtel_vcpFw_top.p4"
    "${testExtraArgs} -target tofino2 -arch t2na -bfrt"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/customer/extreme/npb-folded-pipe/tests")
bfn_set_p4_build_flag("tofino2" "npb-folded-pipe" "-I${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/customer/extreme/npb-folded-pipe/src -I${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/customer/extreme/npb-folded-pipe/src/pipeline_npb")
bfn_set_ptf_ports_json_file("tofino2" "npb-folded-pipe" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/customer/extreme/npb-folded-pipe/tests/ports.json")
set_tests_properties("tofino2/npb-folded-pipe" PROPERTIES TIMEOUT ${extended_timeout_8times})

p4c_add_ptf_test_with_ptfdir (
    "tofino2" "p4c-3484" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/bfrt/p4c-3484/npb.p4"
    "${testExtraArgs} -target tofino2 -arch t2na -bfrt"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/bfrt/p4c-3484/tests")
set_tests_properties("tofino2/p4c-3484" PROPERTIES TIMEOUT ${extended_timeout_4times})
bfn_set_ptf_test_spec("tofino2" "p4c-3484" "test_mau_1hop_s___ing_mirror.test")

p4c_add_ptf_test_with_ptfdir (
    "tofino2" tor.p4 ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/google-tor/p4/spec/tor.p4
    "${testExtraArgs} -arch v1model" ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/tor.ptf)

# 500s timeout is too little for compiling and testing the entire switch, bumping it up
set_tests_properties("tofino2/p4c_2527" PROPERTIES TIMEOUT ${extended_timeout_2times})

# JIRA-DOC: P4C-4079
# New HeaderMutex pass increases compilation time a bit over 600s default timeout value (usually 660s to 780s).
p4c_add_bf_backend_tests("tofino2" "jbay" "t2na" "base" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/customer/keysight/keysight-eagle-tf2.p4" "-to 1200")
set_tests_properties("tofino2/extensions/p4_tests/p4_16/internal/customer/keysight/keysight-eagle-tf2.p4" PROPERTIES TIMEOUT 1200)
p4c_add_bf_backend_tests("tofino2" "jbay" "t2na" "base" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/stf/p4c-4055.p4" "-to 1200")
set_tests_properties("tofino2/extensions/p4_tests/p4_16/internal/stf/p4c-4055.p4" PROPERTIES TIMEOUT 1200)
p4c_add_bf_backend_tests("tofino2" "jbay" "t2na" "base" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/stf/MODEL-1095.p4" "-to 1200")
set_tests_properties("tofino2/extensions/p4_tests/p4_16/internal/stf/MODEL-1095.p4" PROPERTIES TIMEOUT 1200)
p4c_add_bf_backend_tests("tofino2" "jbay" "t2na" "base" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/jbay/p4c-4072.p4" "-to 1200")
set_tests_properties("tofino2/extensions/p4_tests/p4_16/internal/jbay/p4c-4072.p4" PROPERTIES TIMEOUT 1200)
endif (CLOSED_SOURCE)

include(JBayXfail.cmake)
include(JBayMustPass.cmake)
