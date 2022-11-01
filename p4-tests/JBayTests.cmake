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
set (P16_V1_FOR_JBAY "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/customer/*/*.p4" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/compile_only/*.p4" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/stf/*.p4" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/ptf/*.p4")
p4c_find_tests("${P16_V1_FOR_JBAY}" p16_v1tests INCLUDE "${P16_V1_INCLUDE_PATTERNS}" EXCLUDE "${P16_V1_EXCLUDE_PATTERNS}")

set (P16_JNA_INCLUDE_PATTERNS "include.*(t2?na|tofino2_arch).p4" "main|common_tna_test|common_t2na_test")
set (P16_JNA_EXCLUDE_PATTERNS
  "tofino\\.h" "TOFINO1_ONLY" "<built-in>"
  "p4c-1323-b\\.p4"
  "p4c-1587-a\\.p4"
  "p4c-2537\\.p4"  # this program is excluded because it exceeds 900s timeout
  "p4c-2794\\.p4"
  "p4c-3001\\.p4"
  "p4c-3030-2\\.p4"
  "obfuscated-ddos_tofino2\\.p4"
  "obfuscated-hybrid_default_tofino2\\.p4"
  "obfuscated-l2_dci\\.p4"
  "obfuscated-msee_tofino2\\.p4"
  "obfuscated-msee_tofino2_lkg\\.p4"
  "obfuscated-p416_baremetal_tofino2\\.p4"
  "obfuscated-p416_baremetal_tofino2-2022-09-15\\.p4"
  "p4c-2641\\.p4"
  "p4c-3528\\.p4"
  "npb-GA\\.p4"
  "npb-master-20210108\\.p4"
  "npb-master-20210202\\.p4"
  "npb-master-20210211\\.p4"
  "npb-master-20210225\\.p4"
  "npb-master-20210301\\.p4"
  "npb-97-ga\\.p4"
  "p4c-3455.p4"
  "p4c-3455_2.p4"
  "p4c-3454\\.p4"
  "p4c-3476\\.p4"
  "p4c-2740\\.p4"
  "p4c-2490\\.p4"
  "p4c-4127\\.p4"
  "p4c-3288\\.p4"
  "p4c_2601\\.p4"
  "mirror_constants\\.p4"
  "hash_extern_xor\\.p4"
  "hash_field_expression\\.p4"
  "hash_field_expression_sym\\.p4"
  "keysight-eagle-tf2\\.p4"
  "p4c-4055\\.p4"
  "MODEL-1095\\.p4"
  "p4c-4072\\.p4"
)
set (P16_JNA_FOR_JBAY "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/customer/*/*.p4"
                      "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/compile_only/*.p4"
                      "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/stf/*.p4"
                      "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/ptf/*.p4"
                      "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/jbay/*.p4")
p4c_find_tests("${P16_JNA_FOR_JBAY}" P16_JNA_TESTS INCLUDE "${P16_JNA_INCLUDE_PATTERNS}" EXCLUDE "${P16_JNA_EXCLUDE_PATTERNS}")
bfn_find_tests("${P16_JNA_TESTS}" p16_jna_tests EXCLUDE "${P16_JNA_EXCLUDE_PATTERNS}")

file (GLOB STF_TESTS "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/stf/*.stf")
string (REGEX REPLACE "\\.stf;" ".p4;" STF_P4_TESTS "${STF_TESTS};")

file (GLOB PTF_TESTS "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/ptf/*.ptf")
string (REGEX REPLACE "\\.ptf;" ".p4;" PTF_P4_TESTS "${PTF_TESTS};")

# P4C-2985
# We need to create two tests with different args for one p4 file.
# We utilize the fact that p4c_add_bf_backend_tests and p4c_add_test_with_args use the same name
# of the *.test file if there is more tests for one *.p4 file, so we create test with command line option
# --parser-inline-opt here, and let the other test be created as part of tests created from variable
# JBAY_JNA_TEST_SUITES.
p4c_find_test_names("${CMAKE_CURRENT_SOURCE_DIR}/p4_16/stf/p4c-2985.p4" P4C_2985_TESTNAME)
bfn_add_test_with_args("tofino2" "jbay" "parser-inline-opt/${P4C_2985_TESTNAME}" ${P4C_2985_TESTNAME} "" "--parser-inline-opt")
p4c_add_test_label("tofino2" "base;JENKINS_PART1;stf" "parser-inline-opt/${P4C_2985_TESTNAME}")

set (JBAY_JNA_TEST_SUITES
  ${p16_jna_tests}
  )

p4c_add_bf_backend_tests("tofino2" "jbay" "t2na" "base\;JENKINS_PART1" "${JBAY_JNA_TEST_SUITES}" "-I${CMAKE_CURRENT_SOURCE_DIR}/p4_16/includes")
p4c_add_bf_backend_tests("tofino2" "jbay" "t2na" "base\;JENKINS_PART1" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/jbay/p4c-3288.p4")
set_tests_properties("tofino2/extensions/p4_tests/p4_16/jbay/p4c-3288.p4" PROPERTIES TIMEOUT ${extended_timeout_2times})
bfn_needs_scapy("tofino2" "extensions/p4_tests/p4_16/ptf/inner_checksum_payload_offset.p4")
bfn_needs_scapy("tofino2" "extensions/p4_tests/p4_16/ptf/options_invalid.p4")
bfn_needs_scapy("tofino2" "extensions/p4_tests/p4_16/ptf/inner_checksum.p4")
bfn_needs_scapy("tofino2" "extensions/p4_tests/p4_16/ptf/large_indirect_count.p4")

# longer timeout
p4c_add_bf_backend_tests("tofino2" "jbay" "t2na" "base\;JENKINS_PART1" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/customer/extreme/npb-master-20210108.p4")
set_tests_properties("tofino2/extensions/p4_tests/p4_16/customer/extreme/npb-master-20210108.p4" PROPERTIES TIMEOUT ${extended_timeout_6times})
p4c_add_bf_backend_tests("tofino2" "jbay" "t2na" "base\;JENKINS_PART1" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/customer/extreme/npb-master-20210202.p4")
set_tests_properties("tofino2/extensions/p4_tests/p4_16/customer/extreme/npb-master-20210202.p4" PROPERTIES TIMEOUT ${extended_timeout_6times})
p4c_add_bf_backend_tests("tofino2" "jbay" "t2na" "base\;JENKINS_PART1" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/customer/extreme/npb-master-20210211.p4")
set_tests_properties("tofino2/extensions/p4_tests/p4_16/customer/extreme/npb-master-20210211.p4" PROPERTIES TIMEOUT ${extended_timeout_6times})
p4c_add_bf_backend_tests("tofino2" "jbay" "t2na" "base\;JENKINS_PART1" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/customer/extreme/npb-master-20210225.p4")
set_tests_properties("tofino2/extensions/p4_tests/p4_16/customer/extreme/npb-master-20210225.p4" PROPERTIES TIMEOUT ${extended_timeout_6times})
p4c_add_bf_backend_tests("tofino2" "jbay" "t2na" "base\;JENKINS_PART1" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/customer/extreme/npb-master-20210301.p4")
set_tests_properties("tofino2/extensions/p4_tests/p4_16/customer/extreme/npb-master-20210301.p4" PROPERTIES TIMEOUT ${extended_timeout_8times})
p4c_add_bf_backend_tests("tofino2" "jbay" "t2na" "base\;JENKINS_PART1" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/customer/extreme/npb-97-ga.p4")
set_tests_properties("tofino2/extensions/p4_tests/p4_16/customer/extreme/npb-97-ga.p4" PROPERTIES TIMEOUT ${extended_timeout_2times})
p4c_add_bf_backend_tests("tofino2" "jbay" "t2na" "base\;JENKINS_PART1" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/compile_only/p4c-3528.p4")
set_tests_properties("tofino2/extensions/p4_tests/p4_16/compile_only/p4c-3528.p4" PROPERTIES TIMEOUT ${extended_timeout_4times})
p4c_add_bf_backend_tests("tofino2" "jbay" "t2na" "base\;JENKINS_PART1" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/customer/extreme/p4c-3455.p4")
set_tests_properties("tofino2/extensions/p4_tests/p4_16/customer/extreme/p4c-3455.p4" PROPERTIES TIMEOUT ${extended_timeout_4times})
p4c_add_bf_backend_tests("tofino2" "jbay" "t2na" "base\;JENKINS_PART1" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/customer/extreme/p4c-3455_2.p4")
set_tests_properties("tofino2/extensions/p4_tests/p4_16/customer/extreme/p4c-3455_2.p4" PROPERTIES TIMEOUT ${extended_timeout_4times})
p4c_add_bf_backend_tests("tofino2" "jbay" "t2na" "base\;JENKINS_PART1" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/customer/extreme/p4c-3454.p4")
set_tests_properties("tofino2/extensions/p4_tests/p4_16/customer/extreme/p4c-3454.p4" PROPERTIES TIMEOUT ${extended_timeout_2times})
p4c_add_bf_backend_tests("tofino2" "jbay" "t2na" "base\;JENKINS_PART1" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/customer/extreme/p4c-3476.p4")
set_tests_properties("tofino2/extensions/p4_tests/p4_16/customer/extreme/p4c-3476.p4" PROPERTIES TIMEOUT ${extended_timeout_2times})
p4c_add_bf_backend_tests("tofino2" "jbay" "t2na" "base\;JENKINS_PART1" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/compile_only/p4c-2740.p4")
set_tests_properties("tofino2/extensions/p4_tests/p4_16/compile_only/p4c-2740.p4" PROPERTIES TIMEOUT ${extended_timeout_4times})
p4c_add_bf_backend_tests("tofino2" "jbay" "t2na" "base\;JENKINS_PART1" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/compile_only/p4c-2490.p4")
set_tests_properties("tofino2/extensions/p4_tests/p4_16/compile_only/p4c-2490.p4" PROPERTIES TIMEOUT ${extended_timeout_4times})

# Arista profiles need a longer timeout
p4c_add_bf_backend_tests("tofino2" "jbay" "t2na" "base\;JENKINS_PART1" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/customer/arista/obfuscated-msee_tofino2.p4" "-Xp4c=--disable-power-check")
set_tests_properties("tofino2/extensions/p4_tests/p4_16/customer/arista/obfuscated-msee_tofino2.p4" PROPERTIES TIMEOUT ${extended_timeout_8times})
p4c_add_bf_backend_tests("tofino2" "jbay" "t2na" "base\;JENKINS_PART1" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/customer/arista/obfuscated-l2_dci.p4" "-Xp4c=--disable-power-check")
set_tests_properties("tofino2/extensions/p4_tests/p4_16/customer/arista/obfuscated-l2_dci.p4" PROPERTIES TIMEOUT ${extended_timeout_8times})
p4c_add_bf_backend_tests("tofino2" "jbay" "t2na" "base\;JENKINS_PART1" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/customer/ruijie/p4c-4127.p4")
set_tests_properties("tofino2/extensions/p4_tests/p4_16/customer/ruijie/p4c-4127.p4" PROPERTIES TIMEOUT ${extended_timeout_4times})

p4c_add_bf_backend_tests("tofino2" "jbay" "t2na" "base\;JENKINS_PART1" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/customer/arista/obfuscated-p416_baremetal_tofino2.p4" "-Xp4c=\"--set-max-power 62.0\"")
set_tests_properties("tofino2/extensions/p4_tests/p4_16/customer/arista/obfuscated-p416_baremetal_tofino2.p4" PROPERTIES TIMEOUT ${extended_timeout_8times})
p4c_add_test_label("tofino2" "CUST_MUST_PASS" "extensions/p4_tests/p4_16/customer/arista/obfuscated-p416_baremetal_tofino2.p4")

p4c_add_bf_backend_tests("tofino2" "jbay" "t2na" "base\;JENKINS_PART1" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/customer/arista/obfuscated-p416_baremetal_tofino2-2022-09-15.p4" "-Xp4c=\"--set-max-power 62.0\"")
set_tests_properties("tofino2/extensions/p4_tests/p4_16/customer/arista/obfuscated-p416_baremetal_tofino2-2022-09-15.p4" PROPERTIES TIMEOUT ${extended_timeout_8times})
p4c_add_test_label("tofino2" "CUST_MUST_PASS" "extensions/p4_tests/p4_16/customer/arista/obfuscated-p416_baremetal_tofino2-2022-09-15.p4")

p4c_add_bf_backend_tests("tofino2" "jbay" "t2na" "base\;JENKINS_PART1" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/customer/arista/obfuscated-hybrid_default_tofino2.p4" "-Xp4c=\"--set-max-power 65.0\"")
set_tests_properties("tofino2/extensions/p4_tests/p4_16/customer/arista/obfuscated-hybrid_default_tofino2.p4" PROPERTIES TIMEOUT ${extended_timeout_8times})
p4c_add_test_label("tofino2" "CUST_MUST_PASS" "extensions/p4_tests/p4_16/customer/arista/obfuscated-hybrid_default_tofino2.p4")

p4c_add_bf_backend_tests("tofino2" "jbay" "t2na" "base\;JENKINS_PART1" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/customer/arista/obfuscated-ddos_tofino2.p4" "-Xp4c=--disable-power-check")
set_tests_properties("tofino2/extensions/p4_tests/p4_16/customer/arista/obfuscated-ddos_tofino2.p4" PROPERTIES TIMEOUT ${extended_timeout_6times})

# longer timeout
p4c_add_bf_backend_tests("tofino2" "jbay" "t2na" "base\;JENKINS_PART1" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/customer/extreme/p4c-2641.p4")
set_tests_properties("tofino2/extensions/p4_tests/p4_16/customer/extreme/p4c-2641.p4" PROPERTIES TIMEOUT ${extended_timeout_4times})

# p4_16/customer/extreme/p4c-1323-b.p4 needs a longer timeout.
p4c_add_bf_backend_tests("tofino2" "jbay" "t2na" "base\;JENKINS_PART1" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/customer/extreme/p4c-1323-b.p4")
set_tests_properties("tofino2/extensions/p4_tests/p4_16/customer/extreme/p4c-1323-b.p4" PROPERTIES TIMEOUT ${extended_timeout_2times})

p4c_add_bf_backend_tests("tofino2" "jbay" "t2na" "base\;JENKINS_PART1" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/customer/extreme/p4c-1587-a.p4")
set_tests_properties("tofino2/extensions/p4_tests/p4_16/customer/extreme/p4c-1587-a.p4" PROPERTIES TIMEOUT ${extended_timeout_2times})

p4c_add_bf_backend_tests("tofino2" "jbay" "t2na" "base\;JENKINS_PART1" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/customer/extreme/p4c-2794.p4")
set_tests_properties("tofino2/extensions/p4_tests/p4_16/customer/extreme/p4c-2794.p4" PROPERTIES TIMEOUT ${extended_timeout_6times})

p4c_add_bf_backend_tests("tofino2" "jbay" "t2na" "base\;JENKINS_PART1" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/customer/extreme/p4c-3001.p4")
set_tests_properties("tofino2/extensions/p4_tests/p4_16/customer/extreme/p4c-3001.p4" PROPERTIES TIMEOUT ${extended_timeout_6times})

p4c_add_bf_backend_tests("tofino2" "jbay" "t2na" "base\;JENKINS_PART1" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/customer/extreme/p4c-3030-2.p4")
set_tests_properties("tofino2/extensions/p4_tests/p4_16/customer/extreme/p4c-3030-2.p4" PROPERTIES TIMEOUT ${extended_timeout_2times})

p4c_add_bf_backend_tests("tofino2" "jbay" "t2na" "base" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/customer/extreme/p4c-3473-a2.p4")
set_tests_properties("tofino2/extensions/p4_tests/p4_16/customer/extreme/p4c-3473-a2.p4" PROPERTIES TIMEOUT ${extended_timeout_2times})

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

p4c_add_bf_backend_tests("tofino2" "jbay" "${JBAY_P414_TEST_ARCH}" "base\;JENKINS_PART1" "${JBAY_V1_TEST_SUITES_P414}" "-I${CMAKE_CURRENT_SOURCE_DIR}/p4_16/includes")
bfn_needs_scapy("tofino2" "extensions/p4_tests/p4_14/ptf/inner_checksum_l4.p4")

p4c_add_test_label("tofino2" "JENKINS_PART1" "extensions/p4_tests/p4_16/customer/keysight/keysight-tf2.p4")

p4c_add_test_label("tofino2" "CUST_MUST_PASS" "extensions/p4_tests/p4_16/customer/extreme/npb-master-20210108.p4")
p4c_add_test_label("tofino2" "CUST_MUST_PASS" "extensions/p4_tests/p4_16/customer/extreme/npb-master-20210202.p4")
p4c_add_test_label("tofino2" "CUST_MUST_PASS" "extensions/p4_tests/p4_16/customer/extreme/npb-master-20210211.p4")
p4c_add_test_label("tofino2" "JENKINS_PART1" "extensions/p4_tests/p4_16/customer/extreme/npb-master-20210211.p4")
p4c_add_test_label("tofino2" "CUST_MUST_PASS" "extensions/p4_tests/p4_16/customer/extreme/npb-master-20210225.p4")
p4c_add_test_label("tofino2" "JENKINS_PART1" "extensions/p4_tests/p4_16/customer/extreme/npb-master-20210225.p4")
p4c_add_test_label("tofino2" "CUST_MUST_PASS" "extensions/p4_tests/p4_16/customer/extreme/npb-master-20210301.p4")
p4c_add_test_label("tofino2" "JENKINS_PART1" "extensions/p4_tests/p4_16/customer/extreme/npb-master-20210301.p4")
p4c_add_test_label("tofino2" "CUST_MUST_PASS" "extensions/p4_tests/p4_16/customer/extreme/npb-97-ga.p4")
p4c_add_test_label("tofino2" "JENKINS_PART1" "extensions/p4_tests/p4_16/customer/extreme/npb-97-ga.p4")

# PTF tests with different parameters
p4c_add_ptf_test_with_ptfdir ("tofino2" "mirror_constants"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/ptf/mirror_constants.p4"
    "${testExtraArgs} -target tofino2 -arch t2na -bfrt"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/ptf/mirror_constants.ptf")
bfn_needs_scapy("tofino2" "mirror_constants")

p4c_add_ptf_test_with_ptfdir (
    "tofino2" "p4c_2601" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/ptf/p4c_2601.p4"
    "${testExtraArgs} -target tofino2 -arch t2na -bfrt --p4runtime-force-std-externs"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/ptf/p4c_2601.ptf")
bfn_needs_scapy("tofino2" "p4c_2601")

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

p4c_add_ptf_test_with_ptfdir (
    "tofino2" "p4c_873" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/bfrt/p4c_873/p4c_873.p4"
    "${testExtraArgs} -bfrt -arch v1model" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/bfrt/p4c_873")
p4c_add_test_label("tofino2" "JENKINS_PART1" "p4c_873")

p4c_add_ptf_test_with_ptfdir (
    "tofino2" "p4c_1585" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/bfrt/p4c_1585/p4c_1585.p4"
    "${testExtraArgs} -target tofino2 -arch t2na -bfrt" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/bfrt/p4c_1585")
p4c_add_test_label("tofino2" "JENKINS_PART1" "p4c_1585")

p4c_add_ptf_test_with_ptfdir (
    "tofino2" "p4c_3043" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/bfrt/p4c_3043/p4c_3043.p4"
    "${testExtraArgs} -target tofino2 -arch t2na -bfrt -Xp4c=\"--disable-power-check\"" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/bfrt/p4c_3043")
p4c_add_test_label("tofino2" "JENKINS_PART1" "p4c_3043")
p4c_add_test_label("tofino2" "UNSTABLE" "p4c_3043")
set_tests_properties("tofino2/p4c_3043" PROPERTIES TIMEOUT ${extended_timeout_4times})

p4c_add_ptf_test_with_ptfdir (
    "tofino2" "p4c_1585_a" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/bfrt/p4c_1585_a/p4c_1585_a.p4"
    "${testExtraArgs} -target tofino2 -arch t2na -bfrt" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/bfrt/p4c_1585_a")
p4c_add_test_label("tofino2" "JENKINS_PART1" "p4c_1585_a")

p4c_add_ptf_test_with_ptfdir (
    "tofino2" "p4c_1585_b" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/bfrt/p4c_1585_b/p4c_1585_b.p4"
    "${testExtraArgs} -target tofino2 -arch t2na -bfrt" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/bfrt/p4c_1585_b")
p4c_add_test_label("tofino2" "JENKINS_PART1" "p4c_1585_b")

p4c_add_ptf_test_with_ptfdir (
    "tofino2" "p4c_1587" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/bfrt/p4c_1587/p4c_1587.p4"
    "${testExtraArgs} -target tofino2 -arch t2na -bfrt" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/bfrt/p4c_1587")
set_tests_properties("tofino2/p4c_1587" PROPERTIES TIMEOUT ${extended_timeout_2times})
p4c_add_test_label("tofino2" "JENKINS_PART1" "p4c_1587")

p4c_add_ptf_test_with_ptfdir (
    "tofino2" "p4c_2527" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/bfrt/p4c_2527/npb.p4"
    "${testExtraArgs} -target tofino2 -arch t2na -bfrt" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/bfrt/p4c_2527")
p4c_add_test_label("tofino2" "JENKINS_PART1" "p4c_2527")

p4c_add_ptf_test_with_ptfdir (
 "tofino2" "p4c_2549" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/bfrt/p4c_2549/p4c_2549.p4"
 "${testExtraArgs} -target tofino2 -arch t2na -bfrt"
 "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/bfrt/p4c_2549")
set_tests_properties("tofino2/p4c_2549" PROPERTIES TIMEOUT ${extended_timeout_4times})
bfn_needs_scapy("tofino2" "p4c_2549")

p4c_add_ptf_test_with_ptfdir (
    "tofino2" "p4c-3033" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/bfrt/p4c-3033/npb.p4"
    "${testExtraArgs} -target tofino2 -arch t2na -bfrt " "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/bfrt/p4c-3033")
set_tests_properties("tofino2/p4c-3033" PROPERTIES TIMEOUT ${extended_timeout_4times})
p4c_add_test_label("tofino2" "JENKINS_PART1" "p4c-3033")
bfn_needs_scapy("tofino2" "p4c-3033")
p4c_add_test_label("tofino2" "UNSTABLE" "p4c-3033")

p4c_add_ptf_test_with_ptfdir (
    "tofino2" "p4c-3614" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/bfrt/p4c_3614/npb/npb.p4"
    "${testExtraArgs} -target tofino2 -arch t2na -bfrt " "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/bfrt/p4c_3614")
set_tests_properties("tofino2/p4c-3614" PROPERTIES TIMEOUT ${extended_timeout_4times})
p4c_add_test_label("tofino2" "JENKINS_PART1" "p4c-3614")

p4c_add_ptf_test_with_ptfdir (
    "tofino2" "p4c-3379" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/bfrt/p4c-3379/npb.p4"
    "${testExtraArgs} -target tofino2 -arch t2na -bfrt"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/bfrt/p4c-3379")
set_tests_properties("tofino2/p4c-3379" PROPERTIES TIMEOUT ${extended_timeout_4times})
p4c_add_test_label("tofino2" "JENKINS_PART2" "p4c-3379")

p4c_add_ptf_test_with_ptfdir (
    "tofino2" "p4c-3570" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/bfrt/p4c-3570/npb.p4"
    "${testExtraArgs} -target tofino2 -arch t2na -bfrt"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/bfrt/p4c-3570")
set_tests_properties("tofino2/p4c-3570" PROPERTIES TIMEOUT ${extended_timeout_2times})
p4c_add_test_label("tofino2" "JENKINS_PART2" "p4c-3570")
bfn_needs_scapy("tofino2" "p4c-3570")

p4c_add_ptf_test_with_ptfdir (
    "tofino2" "p4c-3479" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/bfrt/p4c-3479/p4c_3479.p4"
    "${testExtraArgs} -target tofino2 -arch t2na -bfrt"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/bfrt/p4c-3479")
set_tests_properties("tofino2/p4c-3479" PROPERTIES TIMEOUT ${extended_timeout_2times})
p4c_add_test_label("tofino2" "JENKINS_PART2" "p4c-3479")

p4c_add_ptf_test_with_ptfdir (
    "tofino2" "p4c-3876" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/bfrt/p4c-3876/p4c_3876.p4"
    "${testExtraArgs} -target tofino2 -arch t2na -bfrt"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/bfrt/p4c-3876")
set_tests_properties("tofino2/p4c-3876" PROPERTIES TIMEOUT ${extended_timeout_2times})
p4c_add_test_label("tofino2" "JENKINS_PART2" "p4c-3876")
bfn_needs_scapy("tofino2" "p4c-3876")

p4c_add_ptf_test_with_ptfdir (
    "tofino2" "npb-master-ptf"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/customer/extreme/npb-master-ptf/src/pgm_sp_npb_vcpFw_top.p4"
    "${testExtraArgs} -target tofino2 -arch t2na -bfrt"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/customer/extreme/npb-master-ptf/tests")
bfn_set_p4_build_flag("tofino2" "npb-master-ptf" "-I${CMAKE_CURRENT_SOURCE_DIR}/p4_16/customer/extreme/npb-master-ptf/src -I${CMAKE_CURRENT_SOURCE_DIR}/p4_16/customer/extreme/npb-master-ptf/src/pipeline_npb")
bfn_set_ptf_ports_json_file("tofino2" "npb-master-ptf" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/customer/extreme/npb-master-ptf/tests/ports.json")
set_tests_properties("tofino2/npb-master-ptf" PROPERTIES TIMEOUT ${extended_timeout_4times})

p4c_add_ptf_test_with_ptfdir (
    "tofino2" "npb-multi-prog"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/customer/extreme/npb-multi-prog/src/pgm_mp_npb_igOnly_npb_igOnly_npb_igOnly_npb_egOnly_top.p4"
    "${testExtraArgs} -target tofino2 -arch t2na -bfrt"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/customer/extreme/npb-multi-prog/tests")
bfn_set_p4_build_flag("tofino2" "npb-multi-prog" "-I${CMAKE_CURRENT_SOURCE_DIR}/p4_16/customer/extreme/npb-multi-prog/src -I${CMAKE_CURRENT_SOURCE_DIR}/p4_16/customer/extreme/npb-multi-prog/src/pipeline_npb_igOnly_egOnly")
bfn_set_ptf_ports_json_file("tofino2" "npb-multi-prog" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/customer/extreme/npb-multi-prog/tests/ports.json")
set_tests_properties("tofino2/npb-multi-prog" PROPERTIES TIMEOUT ${extended_timeout_8times})

p4c_add_ptf_test_with_ptfdir (
    "tofino2" "npb-folded-pipe"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/customer/extreme/npb-folded-pipe/src/pgm_fp_npb_dedup_dtel_vcpFw_top.p4"
    "${testExtraArgs} -target tofino2 -arch t2na -bfrt"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/customer/extreme/npb-folded-pipe/tests")
bfn_set_p4_build_flag("tofino2" "npb-folded-pipe" "-I${CMAKE_CURRENT_SOURCE_DIR}/p4_16/customer/extreme/npb-folded-pipe/src -I${CMAKE_CURRENT_SOURCE_DIR}/p4_16/customer/extreme/npb-folded-pipe/src/pipeline_npb")
bfn_set_ptf_ports_json_file("tofino2" "npb-folded-pipe" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/customer/extreme/npb-folded-pipe/tests/ports.json")
set_tests_properties("tofino2/npb-folded-pipe" PROPERTIES TIMEOUT ${extended_timeout_8times})

p4c_add_ptf_test_with_ptfdir (
    "tofino2" "p4c-3484" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/bfrt/p4c-3484/npb.p4"
    "${testExtraArgs} -target tofino2 -arch t2na -bfrt"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/bfrt/p4c-3484/tests")
set_tests_properties("tofino2/p4c-3484" PROPERTIES TIMEOUT ${extended_timeout_4times})
bfn_set_ptf_test_spec("tofino2" "p4c-3484" "test_mau_1hop_s___ing_mirror.test")
p4c_add_test_label("tofino2" "JENKINS_PART2" "p4c-3484")

p4c_add_bf_backend_tests("tofino2" "jbay" "v1model" "base\;JENKINS_PART1" "${JBAY_V1_TEST_SUITES_P416}" "-I${CMAKE_CURRENT_SOURCE_DIR}/p4_16/includes")

set (ONOS_FABRIC_P4 ${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/p4_16_programs/bf-onos/pipelines/fabric/src/main/resources/fabric-tofino.p4)
set (ONOS_FABRIC_PTF ${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/p4_16_programs/onf_fabric/tests/onf)
p4c_add_ptf_test_with_ptfdir_and_spec (
    "tofino2" fabric ${ONOS_FABRIC_P4}
    "${testExtraArgs} --auto-init-metadata -DCPU_PORT=0 -arch v1model"
    ${ONOS_FABRIC_PTF} "all ^spgw ^int")

p4c_add_ptf_test_with_ptfdir_and_spec (
    "tofino2" fabric-DWITH_SPGW ${ONOS_FABRIC_P4}
    "${testExtraArgs} --auto-init-metadata -DCPU_PORT=0 -DWITH_SPGW -arch v1model"
    ${ONOS_FABRIC_PTF} "all ^int")

p4c_add_ptf_test_with_ptfdir_and_spec (
    "tofino2" fabric-DWITH_INT_TRANSIT ${ONOS_FABRIC_P4}
    "${testExtraArgs} --auto-init-metadata -DCPU_PORT=0 -DWITH_INT_TRANSIT -arch v1model"
    ${ONOS_FABRIC_PTF} "all ^spgw")

p4c_add_ptf_test_with_ptfdir_and_spec (
    "tofino2" fabric-DWITH_SPGW-DWITH_INT_TRANSIT ${ONOS_FABRIC_P4}
    "${testExtraArgs} --auto-init-metadata -DCPU_PORT=0 -DWITH_SPGW -DWITH_INT_TRANSIT -arch v1model"
    ${ONOS_FABRIC_PTF} "all")

bfn_needs_scapy("tofino2" "fabric")
bfn_needs_scapy("tofino2" "fabric-DWITH_SPGW")
bfn_needs_scapy("tofino2" "fabric-DWITH_INT_TRANSIT")
bfn_needs_scapy("tofino2" "fabric-DWITH_SPGW-DWITH_INT_TRANSIT")

set_tests_properties("tofino2/fabric" PROPERTIES TIMEOUT ${extended_timeout_2times})
set_tests_properties("tofino2/fabric-DWITH_SPGW" PROPERTIES TIMEOUT ${extended_timeout_2times})
set_tests_properties("tofino2/fabric-DWITH_INT_TRANSIT" PROPERTIES TIMEOUT ${extended_timeout_2times})
set_tests_properties("tofino2/fabric-DWITH_SPGW-DWITH_INT_TRANSIT" PROPERTIES TIMEOUT ${extended_timeout_2times})

p4c_add_ptf_test_with_ptfdir (
    "tofino2" tor.p4 ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/google-tor/p4/spec/tor.p4
    "${testExtraArgs} -arch v1model" ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/tor.ptf)
p4c_add_test_label("tofino2" "JENKINS_PART2" tor.p4)

# p4-tests has all the includes at the same level with the programs.
set (BFN_EXCLUDE_PATTERNS "tofino\\.p4")
set (BFN_TESTS "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/internal_p4_14/atomic_mod/*.p4"
               "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/internal_p4_14/dyn_hash/*.p4"
               "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/internal_p4_14/emulation/*.p4"
               "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/internal_p4_14/entry_read_from_hw/*.p4"
               "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/internal_p4_14/hash_test/*.p4"
               "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/internal_p4_14/incremental_checksum/*.p4"
               "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/internal_p4_14/parse480/*.p4"
               "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/internal_p4_14/simple_l3_checksum_branched_end/*.p4"
               "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/internal_p4_14/simple_l3_checksum_single_end/*.p4"
               "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/internal_p4_14/stashes/*.p4"
               "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/internal_p4_14/simple_l3_checksum_taken_default_ingress/*.p4"
               "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/programs/basic_switching/*.p4"
               "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/programs/chksum/*.p4"
               "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/programs/default_entry/*.p4"
               "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/programs/deparse_zero/*.p4"
               # Hitless doesn't work with tofino2 (it timeouts)
               # "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/programs/ha/*.p4"
               "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/programs/mirror_test/*.p4"
               "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/programs/multicast_test/*.p4"
               "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/programs/parse_error/*.p4"
               "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/programs/pcie_pkt_test/*.p4"
               "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/programs/resubmit/*.p4"
               # Might need to move this test to nightly if it times out on Travis
               "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/programs/dkm/*.p4"
               "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/programs/fast_reconfig/*.p4"
               "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/programs/hash_driven/*.p4"
               "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/programs/meters/*.p4"
               "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/programs/pvs/*.p4"
               "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/programs/resubmit/*.p4"
               "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/programs/smoke_large_tbls/*.p4"
               "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/programs/stful/*.p4")
bfn_find_tests ("${BFN_TESTS}" BFN_TESTS_LIST EXCLUDE "${BFN_EXCLUDE_PATTERNS}")
bfn_add_p4factory_tests("tofino2" "tofino2" "${JBAY_P414_TEST_ARCH}" "smoketest_programs\;JENKINS_PART2" BFN_TESTS_LIST "${testExtraArgs}")
p4c_add_test_label("tofino2" "UNSTABLE" "extensions/p4_tests/p4-programs/programs/multicast_test/multicast_test.p4")

bfn_set_ptf_test_spec("tofino2" "extensions/p4_tests/p4-programs/programs/meters/meters.p4"
        "^test.TestMeterOmnet
        test.TestTCAMLpfIndirect
        test.TestExmLpfIndirect
        test.TestExmLpfdirect
        test.TestByteAdj
        test.TestMeterIndirectStateRestore
        test.TestMeterScopes
        test.TestExmMeterIndirect
        test.TestMeterDirectStateRestore
        test.TestExmMeterColorAwareIndirect
        test.TestTCAMLpfdirect
        test.TestExmMeterDirect")

bfn_set_ptf_test_spec("tofino2" "extensions/p4_tests/p4-programs/programs/smoke_large_tbls/smoke_large_tbls.p4"
       "test.TestAtcam
       test.TestAtcamTernaryValid")

bfn_set_ptf_ports_json_file("tofino2" "extensions/p4_tests/p4-programs/programs/multicast_test/multicast_test.p4"
                            "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/ptf-tests/multicast_test/ports.json")
bfn_set_ptf_ports_json_file("tofino2" "extensions/p4_tests/p4-programs/programs/fast_reconfig/fast_reconfig.p4"
                            "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/ptf-tests/fast_reconfig/ports.json")
bfn_set_ptf_ports_json_file("tofino2" "extensions/p4_tests/p4-programs/programs/mirror_test/mirror_test.p4"
                            "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/ptf-tests/mirror_test/ports.json")
# bfn_set_ptf_ports_json_file("tofino2" "extensions/p4_tests/p4-programs/programs/ha/ha.p4"
#                             "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/ptf-tests/ha/ports.json")
bfn_set_ptf_ports_json_file("tofino2" "extensions/p4_tests/p4-programs/programs/pvs/pvs.p4"
                            "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/ptf-tests/pvs/ports.json")

# bfn_set_pd_build_flag("tofino2" "extensions/p4_tests/p4-programs/programs/ha/ha.p4"
#     "--gen-hitless-ha-test-pd")
file(RELATIVE_PATH ha_ha_path ${P4C_SOURCE_DIR} ${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/programs/ha/ha.p4)
bfn_add_test_with_args ("tofino2" "jbay" "extensions/p4_tests/p4-programs/programs/ha/ha.p4"
    ${ha_ha_path} "${testExtraArgs} -arch ${JBAY_P414_TEST_ARCH}" "")
p4c_add_test_label("tofino2" "JENKINS_PART2" "extensions/p4_tests/p4-programs/programs/ha/ha.p4")

# Add some tests as compile only (if they take too long to run or cannot be run
# in compiler docker env due to port issues or lack of pd-16 support)
set (TOF2_V1MODEL_COMPILE_ONLY_TESTS "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/internal_p4_14/action_spec_format/*.p4"
                                     "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/internal_p4_14/basic_ipv4/*.p4"
                                     "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/internal_p4_14/exm_direct_1/*.p4"
                                     "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/internal_p4_14/exm_direct/*.p4"
                                     "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/internal_p4_14/exm_indirect_1/*.p4"
                                     "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/internal_p4_14/exm_smoke_test/*.p4"
                                     "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/internal_p4_14/knet_mgr_test/*.p4"
                                     "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/internal_p4_14/mau_test/*.p4"
                                     "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/internal_p4_14/mod_field_conditionally/*.p4"
                                     "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/internal_p4_14/multi_device/*.p4"
                                     "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/internal_p4_14/multicast_scale/*.p4"
                                     "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/internal_p4_14/opcode_test_saturating/*.p4"
                                     "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/internal_p4_14/opcode_test_signed_and_saturating/*.p4"
                                     "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/internal_p4_14/opcode_test_signed/*.p4"
                                     "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/internal_p4_14/opcode_test/*.p4"
                                     "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/internal_p4_14/parser_error/*.p4"
                                     "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/internal_p4_14/parser_intr_md/*.p4"
                                     "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/internal_p4_14/pgrs_tof2/*.p4"
                                     "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/internal_p4_14/range/*.p4"
                                     "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/programs/alpm_test/*.p4"
                                     "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/programs/iterator/*.p4"
                                     "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/programs/perf_test_alpm/*.p4"
                                     "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/programs/perf_test/*.p4"
                                     "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/programs/pgrs/*.p4")
bfn_find_tests ("${TOF2_V1MODEL_COMPILE_ONLY_TESTS}" TOF2_V1MODEL_COMPILE_ONLY_TESTS_LIST EXCLUDE "${BFN_EXCLUDE_PATTERNS}")
p4c_add_bf_backend_tests("tofino2" "jbay" "${JBAY_P414_TEST_ARCH}" "smoketest_programs\;JENKINS_PART2" "${TOF2_V1MODEL_COMPILE_ONLY_TESTS_LIST}")

file(RELATIVE_PATH tofino32q-3pipe_path ${P4C_SOURCE_DIR} ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/tofino32q-3pipe/sfc.p4)
bfn_add_test_with_args ("tofino2" "jbay" "tofino32q-3pipe" ${tofino32q-3pipe_path} "${testExtraArgs} -arch t2na" "")
p4c_add_test_label("tofino2" "JENKINS_PART2" tofino32q-3pipe)

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
  tna_dyn_hashing
  tna_exact_match
  tna_field_slice
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
file(RELATIVE_PATH p4_16_programs_path ${P4C_SOURCE_DIR} ${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/p4_16_programs)

bfn_add_test_with_args ("tofino2" "jbay" "p4_16_programs_tna_32q_multiprogram_a"
    ${p4_16_programs_path}/tna_32q_multiprogram/program_a/tna_32q_multiprogram_a.p4 "${testExtraArgs} -arch t2na -I${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/p4_16_programs/tna_32q_multiprogram" "")
p4c_add_test_label("tofino2" "JENKINS_PART2" "p4_16_programs_tna_32q_multiprogram_a")

bfn_add_test_with_args ("tofino2" "jbay" "p4_16_programs_tna_32q_multiprogram_b"
    ${p4_16_programs_path}/tna_32q_multiprogram/program_b/tna_32q_multiprogram_b.p4 "${testExtraArgs} -arch t2na -I${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/p4_16_programs/tna_32q_multiprogram" "")
p4c_add_test_label("tofino2" "JENKINS_PART2" "p4_16_programs_tna_32q_multiprogram_b")

bfn_add_test_with_args ("tofino2" "jbay" "p4_16_programs_tna_resubmit"
    ${p4_16_programs_path}/tna_resubmit/tna_resubmit.p4 "${testExtraArgs} -arch t2na -I${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/p4_16_programs/tna_resubmit" "")
p4c_add_test_label("tofino2" "JENKINS_PART2" "p4_16_programs_tna_resubmit")

bfn_add_test_with_args ("tofino2" "jbay" "p4_16_programs_tna_pktgen"
    ${p4_16_programs_path}/tna_pktgen/tna_pktgen.p4 "${testExtraArgs} -arch t2na -I${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/p4_16_programs/tna_pktgen" "")
bfn_set_ptf_test_spec("tofino2" "p4_16_programs_tna_pktgen" "all ^test.PortDownPktgenTest")
p4c_add_test_label("tofino2" "JENKINS_PART2" "p4_16_programs_tna_pktgen")

file(RELATIVE_PATH p4_16_internal_p4_16_path ${P4C_SOURCE_DIR} ${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/internal_p4_16)
bfn_add_test_with_args ("tofino2" "jbay" "p4_16_internal_p4_16_hwlrn"
    ${p4_16_internal_p4_16_path}/hwlrn/hwlrn.p4 "${testExtraArgs} -arch t2na --no-bf-rt-schema -I${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/internal_p4_16" "")
set_property(TEST "tofino2/extensions/p4_tests/p4_16/jbay/hwlearn1.p4"
  APPEND PROPERTY ENVIRONMENT "CTEST_P4C_ARGS=--no-bf-rt-schema")
p4c_add_test_label("tofino2" "JENKINS_PART2" "p4_16_internal_p4_16_hwlrn")

bfn_add_test_with_args ("tofino2" "jbay" "p4_16_internal_p4_16_ipv4_checksum"
    ${p4_16_internal_p4_16_path}/ipv4_checksum/ipv4_checksum.p4 "${testExtraArgs} -arch t2na -I${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/internal_p4_16" "")
p4c_add_test_label("tofino2" "JENKINS_PART2" "p4_16_internal_p4_16_ipv4_checksum")

bfn_add_test_with_args ("tofino2" "jbay" "p4_16_internal_p4_16_lrn"
    ${p4_16_internal_p4_16_path}/lrn/lrn.p4 "${testExtraArgs} -arch t2na -I${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/internal_p4_16" "")
p4c_add_test_label("tofino2" "JENKINS_PART2" "p4_16_internal_p4_16_lrn")

bfn_add_test_with_args ("tofino2" "jbay" "p4_16_internal_p4_16_t2na_emulation"
    ${p4_16_internal_p4_16_path}/t2na_emulation/t2na_emulation.p4 "${testExtraArgs} -arch t2na -I${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/internal_p4_16" "")
p4c_add_test_label("tofino2" "JENKINS_PART2" "p4_16_internal_p4_16_t2na_emulation")

bfn_add_test_with_args ("tofino2" "jbay" "p4_16_internal_p4_16_t2na_fifo"
    ${p4_16_internal_p4_16_path}/t2na_fifo/t2na_fifo.p4 "${testExtraArgs} -arch t2na -I${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/internal_p4_16" "")
p4c_add_test_label("tofino2" "JENKINS_PART2" "p4_16_internal_p4_16_t2na_fifo")

bfn_add_test_with_args ("tofino2" "jbay" "p4_16_internal_p4_16_t2na_pgr"
    ${p4_16_internal_p4_16_path}/t2na_pgr/t2na_pgr.p4 "${testExtraArgs} -arch t2na -I${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/internal_p4_16" "")
p4c_add_test_label("tofino2" "JENKINS_PART2" "p4_16_internal_p4_16_t2na_pgr")

bfn_add_test_with_args ("tofino2" "jbay" "p4_16_internal_p4_16_t2na_static_entry"
    ${p4_16_internal_p4_16_path}/t2na_static_entry/t2na_static_entry.p4 "${testExtraArgs} -arch t2na -I${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/internal_p4_16" "")
p4c_add_test_label("tofino2" "JENKINS_PART2" "p4_16_internal_p4_16_t2na_static_entry")

bfn_add_test_with_args ("tofino2" "jbay" "p4_16_internal_p4_16_tna_pvs_multi_states" ${p4_16_internal_p4_16_path}/tna_pvs_multi_states/tna_pvs_multi_states.p4 "${testExtraArgs} -arch t2na -I${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/internal_p4_16" "")
bfn_set_ptf_test_spec("tofino2" "p4_16_internal_p4_16_tna_pvs_multi_states" "all")
p4c_add_test_label("tofino2" "JENKINS_PART2" "p4_16_internal_p4_16_tna_pvs_multi_states")

bfn_add_test_with_args ("tofino2" "jbay" "p4_16_internal_p4_16_t2na_ghost"
    ${p4_16_internal_p4_16_path}/t2na_ghost/t2na_ghost.p4 "${testExtraArgs} -arch t2na -I${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/internal_p4_16" "")
p4c_add_test_label("tofino2" "JENKINS_PART2" "p4_16_internal_p4_16_t2na_ghost")

bfn_add_test_with_args ("tofino2" "jbay" "p4_16_internal_p4_16_mirror"
    ${p4_16_internal_p4_16_path}/mirror/mirror.p4 "${testExtraArgs} -arch t2na -I${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/internal_p4_16" "")
p4c_add_test_label("tofino2" "JENKINS_PART2" "p4_16_internal_p4_16_mirror")

p4c_add_ptf_test_with_ptfdir ("tofino2" "t2na_ghost_dod" "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/internal_p4_16/t2na_ghost_dod/t2na_ghost_dod.p4" "${testExtraArgs} -target tofino2 -arch t2na -bfrt" "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/internal_p4_16/t2na_ghost_dod")
bfn_set_ptf_test_spec("tofino2" "t2na_ghost_dod" "test.T2naGhostTestDoD")
p4c_add_test_label("tofino2" "JENKINS_PART2" "t2na_ghost_dod")

p4c_add_ptf_test_with_ptfdir ("tofino2" "t2na_ghost_dod_simpl" "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/internal_p4_16/t2na_ghost_dod_simpl/t2na_ghost_dod_simpl.p4" "${testExtraArgs} -target tofino2 -arch t2na -bfrt" "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/internal_p4_16/t2na_ghost_dod_simpl")
bfn_set_ptf_test_spec("tofino2" "t2na_ghost_dod_simpl" "test.T2naGhostSimplTestDoD")
p4c_add_test_label("tofino2" "JENKINS_PART2" "t2na_ghost_dod_simpl")

p4c_add_ptf_test_with_ptfdir ("tofino2" "t2na_ghost_dod_2pipe_simpl" "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/internal_p4_16/t2na_ghost_dod_2pipe_simpl/t2na_ghost_dod_2pipe_simpl.p4" "${testExtraArgs} -target tofino2 -arch t2na -bfrt " "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/internal_p4_16/t2na_ghost_dod_2pipe_simpl")
bfn_set_ptf_test_spec("tofino2" "t2na_ghost_dod_2pipe_simpl" "test.T2naGhost2PipeSimplTestDoD")
p4c_add_test_label("tofino2" "JENKINS_PART2" "t2na_ghost_dod_2pipe_simpl")
# uses multiple pipes so we need to specify ports explicitly
bfn_set_ptf_ports_json_file("tofino2" "t2na_ghost_dod_2pipe_simpl" "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/internal_p4_16/t2na_ghost_dod_2pipe_simpl/ports.json")

p4c_add_ptf_test_with_ptfdir ("tofino2" "large_counter_meter" "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/internal_p4_16/large_counter_meter/large_counter_meter.p4"
  "${testExtraArgs} -target tofino2 -arch t2na -I${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/internal_p4_16 -bfrt -Xp4c=\"--disable_split_attached\" -Xptf=--test-params=pkt_size=100"
  "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/internal_p4_16/large_counter_meter")
bfn_set_ptf_test_spec("tofino2" "large_counter_meter" "all")
p4c_add_test_label("tofino2" "JENKINS_PART2" "large_counter_meter")
set_tests_properties("tofino2/large_counter_meter" PROPERTIES TIMEOUT ${extended_timeout_2times})

# P4-16 Programs with PTF tests
foreach(t IN LISTS P4FACTORY_P4_16_PROGRAMS)
  p4c_add_ptf_test_with_ptfdir ("tofino2" "p4_16_programs_${t}" "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/p4_16_programs/${t}/${t}.p4"
    "${testExtraArgs} -target tofino2 -arch t2na -bfrt" "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/p4_16_programs/${t}")
  bfn_set_p4_build_flag("tofino2" "p4_16_programs_${t}" "-I${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/p4_16_programs")
  set (ports_json ${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/p4_16_programs/${t}/ports_tof2.json)
  if (EXISTS ${ports_json})
    bfn_set_ptf_ports_json_file("tofino2" "p4_16_programs_${t}" ${ports_json})
  endif()
  p4c_add_test_label("tofino2" "JENKINS_PART2" "p4_16_programs_${t}")
endforeach()

# PTF, disable failing tests
bfn_add_test_with_args ("tofino2" "jbay" "p4_16_programs_tna_checksum"
    ${p4_16_programs_path}/tna_checksum/tna_checksum.p4 "${testExtraArgs} -arch t2na -I${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/p4_16_programs/tna_checksum" "")
bfn_set_ptf_test_spec("tofino2" "p4_16_programs_tna_checksum"
    "all ^test.Ipv4UdpTranslateSpecialUpdTest")
bfn_set_ptf_test_spec("tofino2" "p4_16_programs_tna_snapshot"
    "all ^test.SnapshotTest")
p4c_add_test_label("tofino2" "JENKINS_PART2" "p4_16_programs_tna_checksum")

# Set ports.json for tna_idletime test
bfn_set_ptf_ports_json_file("tofino2" "p4_16_programs_tna_dkm" "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/p4_16_programs/tna_dkm/ports.json")
bfn_set_ptf_ports_json_file("tofino2" "p4_16_programs_tna_idletimeout" "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/p4_16_programs/tna_idletimeout/ports.json")

# 500s timeout is too little for compiling and testing the entire switch, bumping it up
set_tests_properties("tofino2/p4_16_programs_tna_exact_match" PROPERTIES TIMEOUT ${extended_timeout_2times})
set_tests_properties("tofino2/p4_16_programs_tna_ternary_match" PROPERTIES TIMEOUT ${extended_timeout_4times})
set_tests_properties("tofino2/p4c_2527" PROPERTIES TIMEOUT ${extended_timeout_2times})

# P4C-4079
# New HeaderMutex pass increases compilation time a bit over 600s default timeout value (usually 660s to 780s).
p4c_add_bf_backend_tests("tofino2" "jbay" "t2na" "base" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/customer/keysight/keysight-eagle-tf2.p4" "-to 1200")
set_tests_properties("tofino2/extensions/p4_tests/p4_16/customer/keysight/keysight-eagle-tf2.p4" PROPERTIES TIMEOUT 1200)
p4c_add_bf_backend_tests("tofino2" "jbay" "t2na" "base" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/stf/p4c-4055.p4" "-to 1200")
set_tests_properties("tofino2/extensions/p4_tests/p4_16/stf/p4c-4055.p4" PROPERTIES TIMEOUT 1200)
p4c_add_bf_backend_tests("tofino2" "jbay" "t2na" "base" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/stf/MODEL-1095.p4" "-to 1200")
set_tests_properties("tofino2/extensions/p4_tests/p4_16/stf/MODEL-1095.p4" PROPERTIES TIMEOUT 1200)
p4c_add_bf_backend_tests("tofino2" "jbay" "t2na" "base" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/jbay/p4c-4072.p4" "-to 1200")
set_tests_properties("tofino2/extensions/p4_tests/p4_16/jbay/p4c-4072.p4" PROPERTIES TIMEOUT 1200)

# P4C-4718
set(TOFINO2_DETERMINISM_TESTS_14
    ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/pd/decaf_10/decaf_10.p4
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

include(SwitchJBay.cmake)
include(JBayXfail.cmake)
include(JBayErrors.cmake)
