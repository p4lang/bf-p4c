set (tofino_timeout 600)

# check for PTF requirements
packet_test_setup_check("tofino")
# experimental -- doesn't quite work yet
# bfn_add_switch("tofino")

set (V1_SEARCH_PATTERNS "include.*v1model.p4" "main|common_v1_test")
set (V1_EXCLUDE_PATTERNS "package" "extern")
# Exclude some bmv2 p4s with conditional checksum updates that are not needed for backend
set (V1_EXCLUDE_FILES
    "issue461-bmv2\\.p4"
    "issue1079-bmv2\\.p4"
    "issue2291\\.p4"
    "header-stack-ops-bmv2\\.p4"
    "hash-extern-bmv2\\.p4"
    "gauntlet.*-bmv2\\.p4"
    "bvec-hdr-bmv2\\.p4"                # min depth limit
    "table-entries-exact-bmv2\\.p4"     # min depth limit
    "checksum-l4-bmv2\\.p4"             # max depth limit
    "issue1755-1-bmv2\\.p4"             # min+max depth limit
    )
set (P4TESTDATA ${P4C_SOURCE_DIR}/testdata)
set (P4TESTS_FOR_TOFINO "${P4TESTDATA}/p4_16_samples/*.p4" "${P4TESTDATA}/p4_16_samples/parser-inline/*.p4")
p4c_find_tests("${P4TESTS_FOR_TOFINO}" P4_16_V1_TESTS INCLUDE "${V1_SEARCH_PATTERNS}" EXCLUDE "${V1_EXCLUDE_PATTERNS}")
bfn_find_tests("${P4_16_V1_TESTS}" v1tests EXCLUDE "${V1_EXCLUDE_FILES}")

set (P16_V1_INCLUDE_PATTERNS "include.*v1model.p4" "main|common_v1_test")
set (P16_V1_EXCLUDE_PATTERNS "tofino\\.h")
set (P16_V1MODEL_FOR_TOFINO "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/compile_only/*.p4" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/customer/*/*.p4" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/stf/*.p4" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/ptf/*.p4")
p4c_find_tests("${P16_V1MODEL_FOR_TOFINO}" p16_v1tests INCLUDE "${P16_V1_INCLUDE_PATTERNS}" EXCLUDE "${P16_V1_EXCLUDE_PATTERNS}")

set (P16_TNA_INCLUDE_PATTERNS "include.*(tofino|tna).p4" "main|common_tna_test")
set (P16_TNA_EXCLUDE_PATTERNS "tofino\\.h")

# Arista profiles
set (P16_TNA_ARISTA_FILES
  "obfuscated-baremetal.p4"
  "obfuscated-default.p4"
  "obfuscated-greent.p4"
  "obfuscated-firewall.p4"
  "obfuscated-l2subintf.p4"
  "obfuscated-low_latency.p4"
  "obfuscated-map.p4"
  "obfuscated-media.p4"
  "obfuscated-mpls_baremetal.p4"
  "obfuscated-nat.p4"
  "obfuscated-nat_scale.p4"
  "obfuscated-nat_scale-2021-11-16.p4"
  "obfuscated-nat_static.p4"
  "obfuscated-nat_vxlan.p4"
  "obfuscated-packet_filter.p4"
  "obfuscated-small_scale_test.p4"
  "obfuscated-stateless_load_balance_v4v6.p4"
  "obfuscated-vxlan_evpn_scale.p4"
)

# digest_tna.p4 is used for another test (digest-std-p4runtime) with different args
set (P16_TNA_EXCLUDE_FILES "digest_tna\\.p4" "p4c-1323-b\\.p4" "p4c-2143\\.p4"
    "p4c-2191\\.p4" "p4c-2398\\.p4" "p4c-2032\\.p4" "p4c-2030\\.p4"
    "p4c-2992\\.p4" "p4c-2410-leaf\\.p4" "p4c-2573-leaf\\.p4" "p4c-2753\\.p4"
    "p4c-3241\\.p4" "p4c-3139\\.p4" "p4c-3254\\.p4" "p4c-3255\\.p4" "p4c-2423\\.p4"
    "p4c-2534\\.p4" "p4c-3678-leaf\\.p4" "p4c-2722\\.p4" "p4c-3920-b\\.p4" "p4c_3926\\.p4"
    "p4c_4158\\.p4" "p4c-4064\\.p4" "forensics\\.p4")
set (P16_TNA_EXCLUDE_FILES "${P16_TNA_EXCLUDE_FILES}" "${P16_TNA_ARISTA_FILES}")
set (P16_TNA_FOR_TOFINO
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/compile_only/*.p4"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/errors/*.p4"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/customer/*/*.p4"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/stf/*.p4"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/ptf/*.p4")
p4c_find_tests("${P16_TNA_FOR_TOFINO}" P4_16_TNA_TESTS INCLUDE "${P16_TNA_INCLUDE_PATTERNS}" EXCLUDE "${P16_TNA_EXCLUDE_PATTERNS}")
bfn_find_tests("${P4_16_TNA_TESTS}" p16_tna_tests EXCLUDE "${P16_TNA_EXCLUDE_FILES}")

# Checksum clear is not supported
set (P16_PSA_EXCLUDE_FILES
    "psa-example-incremental-checksum\\.p4"
    "hash-extern-bmv2\\.p4")
set (PSA_SEARCH_PATTERNS "include.*psa.p4")
set (PSA_EXCLUDE_PATTERNS "package" "extern")
set (P4TESTDATA ${P4C_SOURCE_DIR}/testdata)
set (P16_PSA_FOR_TOFINO "${P4TESTDATA}/p4_16_samples/*.p4" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/compile_only/*.p4" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/customer/*/*.p4" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/stf/*.p4" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/fabric-psa/*.p4")
p4c_find_tests("${P16_PSA_FOR_TOFINO}" P4_16_PSA_TESTS INCLUDE "${PSA_SEARCH_PATTERNS}" EXCLUDE "${PSA_EXCLUDE_PATTERNS}")
bfn_find_tests("${P4_16_PSA_TESTS}" p16_psa_tests EXCLUDE "${P16_PSA_EXCLUDE_FILES}")

# Exclude some p4s with conditional checksum updates that are added separately
set (P4_14_EXCLUDE_FILES "parser_dc_full\\.p4" "sai_p4\\.p4"
                            "checksum_pragma\\.p4" "port_vlan_mapping\\.p4"
                            "checksum\\.p4"
                            "header-stack-ops-bmv2\\.p4"  # times out in PHV alloc
                            "p4c-2250\\.p4"
                            "08-FullTPHV3\\.p4"
                            "p4c-2661\\.p4"
                            "action_bus1\\.p4"            # max depth limit
                            "06-FullTPHV1\\.p4"           # max depth limit
                            "07-FullTPHV2\\.p4"           # max depth limit
                            )
set (P4_14_SAMPLES "${P4TESTDATA}/p4_14_samples/*.p4")
bfn_find_tests("${P4_14_SAMPLES}" p4_14_samples EXCLUDE "${P4_14_EXCLUDE_FILES}")

set (P4_14_CUSTOMER "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/customer/*/*.p4")
bfn_find_tests("${P4_14_CUSTOMER}" p4_14_customer EXCLUDE "${P4_14_EXCLUDE_FILES}")

set (TOFINO_V1_TEST_SUITES
  ${p4_14_samples}
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/*.p4
  # p4_14_samples
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/bf_p4c_samples/*.p4
  # compile_only
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/compile_only/*.p4
  # p4smith regression tests
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/compile_only/p4smith_regression/*.p4
  # customer
  ${p4_14_customer}
  # stf
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/stf/*.p4
  # ptf
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/ptf/*.p4
  # glass phv tests
  ${BFN_P4C_SOURCE_DIR}/glass/testsuite/p4_tests/phv/*.p4
  ${BFN_P4C_SOURCE_DIR}/glass/testsuite/p4_tests/phv/*/*.p4
  # glass mau tests
  ${BFN_P4C_SOURCE_DIR}/glass/testsuite/p4_tests/mau/*.p4
  ${BFN_P4C_SOURCE_DIR}/glass/testsuite/p4_tests/mau/*/*.p4
  # glass parde tests
  ${BFN_P4C_SOURCE_DIR}/glass/testsuite/p4_tests/parde/*.p4
  ${BFN_P4C_SOURCE_DIR}/glass/testsuite/p4_tests/parde/*/*.p4
  )
p4c_add_bf_backend_tests("tofino" "tofino" "${TOFINO_P414_TEST_ARCH}" "base\;p414_nightly" "${TOFINO_V1_TEST_SUITES}")
p4c_add_test_label("tofino" "p414_nightly_need_python2" "extensions/p4_tests/p4_14/ptf/inner_checksum.p4")
p4c_add_test_label("tofino" "p414_nightly_need_python2" "extensions/p4_tests/p4_14/ptf/p4c_1962.p4")
p4c_add_test_label("tofino" "p414_nightly_need_python2" "extensions/p4_tests/p4_14/ptf/p4c_3029.p4")
p4c_add_test_label("tofino" "p414_nightly_need_python2" "extensions/p4_tests/p4_14/ptf/p4c2662.p4")

p4c_add_bf_backend_tests("tofino" "tofino" "${TOFINO_P414_TEST_ARCH}" "base\;p414_nightly" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/customer/ruijie/p4c-2250.p4" "-to 2400")
set_tests_properties("tofino/extensions/p4_tests/p4_14/customer/ruijie/p4c-2250.p4" PROPERTIES TIMEOUT 2400)

# P4C-2985
# We need to create one more test for each ${P4TESTDATA}/p4_16_samples/parser-inline/*.p4
# file with command line option --parser-inline-opt (which enables parser inlining optimization).
# As tests created by p4c_add_bf_backend_tests and p4c_add_test_with_args macros use the same *.test file
# regardless the name of the test if they have the same *.p4 file, we create first this test providing
# the extra test argument "--parser-inline-opt" and then let the *.test file be rewritten by
# p4c_add_bf_backend_tests macro when tests are creates from variable v1tests.
p4c_find_test_names("${P4TESTDATA}/p4_16_samples/parser-inline/*.p4" P4TESTS_PARSER_INLINE)
foreach (ts ${P4TESTS_PARSER_INLINE})
  p4c_add_test_with_args("tofino" ${P4C_RUNTEST} FALSE "parser-inline-opt/${ts}" ${ts} "" "--parser-inline-opt")
  p4c_add_test_label("tofino" "base;stf" "parser-inline-opt/${ts}")
endforeach()

set (TOFINO_V1_TEST_SUITES_P416
  ${v1tests}
  ${p16_v1tests}
  # p4_16_samples
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/bf_p4c_samples/*.p4
  )
p4c_add_bf_backend_tests("tofino" "tofino" "v1model" "base" "${TOFINO_V1_TEST_SUITES_P416}" "-I${CMAKE_CURRENT_SOURCE_DIR}/p4_16/includes")

# Tests requiring disabling egress parse depth limits which can't easily have command_line pragmas added
set (P4TESTS_P4_16_FOR_TOFINO_NO_MIN_DEPTH
    "bvec-hdr-bmv2.p4"
    "table-entries-exact-bmv2.p4"
    )
set (P4TESTS_P4_16_FOR_TOFINO_NO_MAX_DEPTH
    "checksum-l4-bmv2.p4"
    )
set (P4TESTS_P4_14_FOR_TOFINO_NO_MAX_DEPTH
    "06-FullTPHV1.p4"
    "07-FullTPHV2.p4"
    "action_bus1.p4"
    )
set (P4TESTS_FOR_TOFINO_NO_DEPTH
    "issue1755-1-bmv2.p4"
    )
foreach (test ${P4TESTS_P4_14_FOR_TOFINO_NO_MAX_DEPTH})
    p4c_add_test_with_args("tofino" ${P4C_RUNTEST} FALSE "testdata/p4_14_samples/${test}" "testdata/p4_14_samples/${test}" "" "-Xp4c=\"--disable-parse-max-depth-limit\"")
endforeach()
foreach (test ${P4TESTS_P4_16_FOR_TOFINO_NO_MIN_DEPTH})
    p4c_add_test_with_args("tofino" ${P4C_RUNTEST} FALSE "testdata/p4_16_samples/${test}" "testdata/p4_16_samples/${test}" "" "-Xp4c=\"--disable-parse-min-depth-limit\"")
endforeach()
foreach (test ${P4TESTS_P4_16_FOR_TOFINO_NO_MAX_DEPTH})
    p4c_add_test_with_args("tofino" ${P4C_RUNTEST} FALSE "testdata/p4_16_samples/${test}" "testdata/p4_16_samples/${test}" "" "-Xp4c=\"--disable-parse-max-depth-limit\"")
endforeach()
foreach (test ${P4TESTS_FOR_TOFINO_NO_DEPTH})
    p4c_add_test_with_args("tofino" ${P4C_RUNTEST} FALSE "testdata/p4_16_samples/${test}" "testdata/p4_16_samples/${test}" "" "-Xp4c=\"--disable-parse-depth-limit\"")
endforeach()

# P4C-2985
# We need to create two tests with different args for one p4 file.
# We utilize the fact that p4c_add_bf_backend_tests and p4c_add_test_with_args use the same name
# of the *.test file if there is more tests for one *.p4 file, so we create test with command line option
# --parser-inline-opt here, and let the other test be created as part of tests created from variable
# TOFINO_TNA_TEST_SUITES.
p4c_find_test_names("${CMAKE_CURRENT_SOURCE_DIR}/p4_16/stf/p4c-2985.p4" P4C_2985_TESTNAME)
p4c_add_test_with_args("tofino" ${P4C_RUNTEST} FALSE "parser-inline-opt/${P4C_2985_TESTNAME}" ${P4C_2985_TESTNAME} "" "--parser-inline-opt")
p4c_add_test_label("tofino" "base;stf" "parser-inline-opt/${P4C_2985_TESTNAME}")

set (TOFINO_TNA_TEST_SUITES
  ${p16_tna_tests}
  )
p4c_add_bf_backend_tests("tofino" "tofino" "tna" "base" "${TOFINO_TNA_TEST_SUITES}" "-I${CMAKE_CURRENT_SOURCE_DIR}/p4_16/includes")
p4c_add_test_label("tofino" "need_scapy" "extensions/p4_tests/p4_16/ptf/options_invalid.p4")
p4c_add_test_label("tofino" "need_scapy" "extensions/p4_tests/p4_16/ptf/inner_checksum.p4")

# p4_16/compile_only/p4c-4064.p4
p4c_add_bf_backend_tests("tofino" "tofino" "tna" "base" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/compile_only/p4c-4064.p4" "-Xp4c=--disable-power-check")

# p4_16/customer/arista/p4c-2143.p4
p4c_add_bf_backend_tests("tofino" "tofino" "tna" "base" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/customer/arista/p4c-2143.p4" "-Xp4c=--disable-power-check")

# p4_16/customer/ruijie/p4c-2992.p4
p4c_add_bf_backend_tests("tofino" "tofino" "tna" "base" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/customer/ruijie/p4c-2992.p4" "-Xp4c=--disable-power-check -to 1800")
set_tests_properties("tofino/extensions/p4_tests/p4_16/customer/ruijie/p4c-2992.p4" PROPERTIES TIMEOUT 1800)

# p4_16/customer/arista/p4c-2191.p4
p4c_add_bf_backend_tests("tofino" "tofino" "tna" "base" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/customer/arista/p4c-2191.p4" "-to 1200")
set_tests_properties("tofino/extensions/p4_tests/p4_16/customer/arista/p4c-2191.p4" PROPERTIES TIMEOUT 1200)

# p4_16/customer/arista/p4c-2534.p4
p4c_add_bf_backend_tests("tofino" "tofino" "tna" "base" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/customer/arista/p4c-2534.p4" "-Xp4c=--disable-power-check -to 2400")
set_tests_properties("tofino/extensions/p4_tests/p4_16/customer/arista/p4c-2534.p4" PROPERTIES TIMEOUT 2400)

# Arista profiles
p4c_add_bf_backend_tests("tofino" "tofino" "tna" "base" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/customer/arista/p4c-2032.p4" "-to 2400")
set_tests_properties("tofino/extensions/p4_tests/p4_16/customer/arista/p4c-2032.p4" PROPERTIES TIMEOUT 1200)
p4c_add_bf_backend_tests("tofino" "tofino" "tna" "base" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/customer/arista/p4c-2030.p4" "-to 2400")
set_tests_properties("tofino/extensions/p4_tests/p4_16/customer/arista/p4c-2030.p4" PROPERTIES TIMEOUT 1200)

# Disable power check on these Arista profiles
# P4C-3039
set (P16_TNA_ARISTA_SET_MAX_POWER_FILES
  "obfuscated-nat.p4"
  "obfuscated-nat_scale.p4"
  "obfuscated-nat_static.p4"
  "obfuscated-nat_scale-2021-11-16.p4"
  "obfuscated-nat_vxlan.p4"
)

cmake_policy(SET CMP0057 NEW)
# p4_16/customer/arista/obfuscated-*.p4
foreach (t IN LISTS P16_TNA_ARISTA_FILES)
  if (${t} IN_LIST P16_TNA_ARISTA_SET_MAX_POWER_FILES)
      set (POWER_CHECK_ARG "-Xp4c=\"--set-max-power 62.0\"")
  else()
      set (POWER_CHECK_ARG "-Xp4c=\"--disable-power-check\"")
  endif()
  p4c_add_bf_backend_tests("tofino" "tofino" "tna" "base" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/customer/arista/${t}" "-to 2400 ${POWER_CHECK_ARG}")
  set_tests_properties("tofino/extensions/p4_tests/p4_16/customer/arista/${t}" PROPERTIES TIMEOUT 2400)
  p4c_add_test_label("tofino" "CUST_MUST_PASS" "extensions/p4_tests/p4_16/customer/arista/${t}")
endforeach()
set_tests_properties("tofino/extensions/p4_tests/p4_16/customer/arista/obfuscated-media.p4" PROPERTIES TIMEOUT 3200)

# p4_16/customer/extreme/p4c-1323-b.p4 needs a longer timeout.
p4c_add_bf_backend_tests("tofino" "tofino" "tna" "base" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/customer/extreme/p4c-1323-b.p4" "-to 1200")
set_tests_properties("tofino/extensions/p4_tests/p4_16/customer/extreme/p4c-1323-b.p4" PROPERTIES TIMEOUT 1200)

# p4_16/customer/extreme/p4c-3920-b.p4
p4c_add_bf_backend_tests("tofino" "tofino" "tna" "base"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/customer/extreme/p4c-3920-b.p4"
    "-Xp4c=\"--p4runtime-force-std-externs\"")

# p4_16/customer/kaloom/p4c-2398.p4
p4c_add_bf_backend_tests("tofino" "tofino" "tna" "base"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/customer/kaloom/p4c-2398.p4"
    "-Xp4c=\"--disable-power-check\"")

# p4_16/customer/kaloom/p4c-2410-leaf.p4
p4c_add_bf_backend_tests("tofino" "tofino" "tna" "base"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/customer/kaloom/p4c-2410-leaf.p4"
    "-Xp4c=\"--disable-power-check\"")

# p4_16/customer/kaloom/p4c-2573-leaf.p4
p4c_add_bf_backend_tests("tofino" "tofino" "tna" "base"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/customer/kaloom/p4c-2573-leaf.p4"
    "-Xp4c=\"--disable-power-check\"")

# p4_16/customer/kaloom/p4c-2753.p4
p4c_add_bf_backend_tests("tofino" "tofino" "tna" "base"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/customer/kaloom/p4c-2753.p4"
    "-Xp4c=\"--disable-power-check\"")

# p4_16/compile_only/p4c-3241.p4
p4c_add_bf_backend_tests("tofino" "tofino" "tna" "base"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/compile_only/p4c-3241.p4"
    "-Xp4c=\"--set-max-power 56.98\"")

# p4_16/customer/kaloom/p4c-3139.p4
p4c_add_bf_backend_tests("tofino" "tofino" "tna" "base"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/customer/kaloom/p4c-3139.p4"
    "-stfbin -Xp4c=\"--disable-power-check\"")

# p4_16/customer/keysight/p4c-2423.p4
p4c_add_bf_backend_tests("tofino" "tofino" "tna" "base"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/customer/keysight/p4c-2423.p4"
    "-Xp4c=\"--disable-power-check\"")

# p4_16/compile_only/p4c-3254.p4
p4c_add_bf_backend_tests("tofino" "tofino" "tna" "base"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/compile_only/p4c-3254.p4"
    "-to 2400 -Xp4c=\"--disable-power-check\"")
set_tests_properties("tofino/extensions/p4_tests/p4_16/compile_only/p4c-3254.p4" PROPERTIES TIMEOUT 2400)

#p4_16/compile_only/p4c-3255.p4
p4c_add_bf_backend_tests("tofino" "tofino" "tna" "base"
  "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/compile_only/p4c-3255.p4"
  "-Xp4c=\"--no-dead-code-elimination\"")

# p4_16/customer/kaloom/p4c-3678-leaf.p4
p4c_add_bf_backend_tests("tofino" "tofino" "tna" "base"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/customer/kaloom/p4c-3678-leaf.p4"
    "-Xp4c=\"--disable-power-check\"")

set (TOFINO_PSA_TEST_SUITES
  ${p16_psa_tests}
  )
p4c_add_bf_backend_tests("tofino" "tofino" "psa" "base" "${TOFINO_PSA_TEST_SUITES}" "-I${CMAKE_CURRENT_SOURCE_DIR}/p4_16/includes -Xp4c=\"--disable-parse-min-depth-limit\"")

# Add labels for tests to be run as MUST PASS in Jenkins
p4c_add_test_label("tofino" "CUST_MUST_PASS" "extensions/p4_tests/p4_14/customer/rdp/case9757.p4")
p4c_add_test_label("tofino" "CUST_MUST_PASS" "extensions/p4_tests/p4_14/customer/ruijie/p4c-2250.p4")
p4c_add_test_label("tofino" "CUST_MUST_PASS" "extensions/p4_tests/p4_16/customer/arista/p4c-1214.p4")
p4c_add_test_label("tofino" "CUST_MUST_PASS" "extensions/p4_tests/p4_16/customer/arista/p4c-1813.p4")
p4c_add_test_label("tofino" "CUST_MUST_PASS" "extensions/p4_tests/p4_16/customer/arista/p4c-2030.p4")
p4c_add_test_label("tofino" "CUST_MUST_PASS" "extensions/p4_tests/p4_16/customer/arista/p4c-2032.p4")
# p4c_add_test_label("tofino" "CUST_MUST_PASS" "extensions/p4_tests/p4_16/customer/arista/p4c-2143.p4")
# p4c_add_test_label("tofino" "CUST_MUST_PASS" "extensions/p4_tests/p4_16/customer/arista/p4c-2191.p4")
p4c_add_test_label("tofino" "CUST_MUST_PASS" "extensions/p4_tests/p4_16/customer/extreme/p4c-1562-1.p4")
p4c_add_test_label("tofino" "CUST_MUST_PASS" "extensions/p4_tests/p4_16/customer/extreme/p4c-1572-b1.p4")
p4c_add_test_label("tofino" "CUST_MUST_PASS" "extensions/p4_tests/p4_16/customer/extreme/p4c-1809-1.p4")
p4c_add_test_label("tofino" "CUST_MUST_PASS" "extensions/p4_tests/p4_16/customer/extreme/p4c-1812-1.p4")
p4c_add_test_label("tofino" "CUST_MUST_PASS" "extensions/p4_tests/p4_16/customer/extreme/p4c-2313.p4")
p4c_add_test_label("tofino" "CUST_MUST_PASS" "extensions/p4_tests/p4_16/customer/kaloom/p4c-1832.p4")
p4c_add_test_label("tofino" "CUST_MUST_PASS" "extensions/p4_tests/p4_16/customer/kaloom/p4c-2398.p4")
p4c_add_test_label("tofino" "CUST_MUST_PASS" "extensions/p4_tests/p4_16/customer/kaloom/p4c-2410-leaf.p4")
p4c_add_test_label("tofino" "CUST_MUST_PASS" "extensions/p4_tests/p4_16/customer/kaloom/p4c-2410-spine.p4")
p4c_add_test_label("tofino" "CUST_MUST_PASS" "extensions/p4_tests/p4_16/customer/kaloom/p4c-2573-leaf.p4")
p4c_add_test_label("tofino" "CUST_MUST_PASS" "extensions/p4_tests/p4_16/customer/kaloom/p4c-3678-leaf.p4")
p4c_add_test_label("tofino" "CUST_MUST_PASS" "extensions/p4_tests/p4_16/customer/keysight/keysight-tf1.p4")
p4c_add_test_label("tofino" "CUST_MUST_PASS" "extensions/p4_tests/p4_16/customer/keysight/pktgen9_16.p4")


# need more compile time after we fix the slicing timeout issue because more
# possible slicing are tried and try allocation of them takes more time.
set_tests_properties("tofino/extensions/p4_tests/p4_16/customer/extreme/p4c-1572-b1.p4" PROPERTIES TIMEOUT 1800)
set_tests_properties("tofino/extensions/p4_tests/p4_16/customer/extreme/p4c-1812-1.p4" PROPERTIES TIMEOUT 1800)
set_tests_properties("tofino/extensions/p4_tests/p4_16/customer/extreme/p4c-1809-1.p4" PROPERTIES TIMEOUT 1800)
set_tests_properties("tofino/extensions/p4_tests/p4_16/customer/extreme/p4c-2313.p4" PROPERTIES TIMEOUT 1800)
set_tests_properties("tofino/extensions/p4_tests/p4_16/customer/kaloom/p4c-1832.p4" PROPERTIES TIMEOUT 1800)

# need to increase timeout for test that fail PHV Allocation since it require a bit more time
# to go over all the possible strategy + optimization
p4c_add_bf_backend_tests("tofino" "tofino" "${TOFINO_P414_TEST_ARCH}" "base\;p414_nightly" "${P4TESTDATA}/p4_14_samples/08-FullTPHV3.p4" "-to 1200")
set_tests_properties("tofino/testdata/p4_14_samples/08-FullTPHV3.p4" PROPERTIES TIMEOUT 1200)
p4c_add_bf_backend_tests("tofino" "tofino" "${TOFINO_P414_TEST_ARCH}" "base\;p414_nightly" "extensions/p4_tests/p4_14/customer/arista/p4c-2661.p4" "-to 1200")
set_tests_properties("tofino/extensions/p4_tests/p4_14/customer/arista/p4c-2661.p4" PROPERTIES TIMEOUT 1200)

p4c_add_ptf_test_with_ptfdir (
    "tofino" tor.p4 ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/google-tor/p4/spec/tor.p4
    "${testExtraArgs} -arch v1model" ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/tor.ptf)
# FIXME: tofino/tor.p4 and tor-archive share output directory.
# Instead of acquiring a resource, we could set different output directories
# for these two tests.
set_tests_properties("tofino/tor.p4" PROPERTIES RESOURCE_LOCK tor_output_dir)

# this tests conversion from Tofino-specific P4Info to "standard" P4Info
p4c_add_ptf_test_with_ptfdir (
    "tofino" digest-std-p4runtime ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/ptf/digest_tna.p4
    "${testExtraArgs} --p4runtime-force-std-externs -arch tna"
    ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/ptf/digest.ptf)

set (ONOS_FABRIC_P4 ${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/p4_16_programs/bf-onos/pipelines/fabric/src/main/resources/fabric-tofino.p4)
set (ONOS_FABRIC_PTF ${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/p4_16_programs/onf_fabric/tests/onf)
p4c_add_ptf_test_with_ptfdir_and_spec (
    "tofino" fabric ${ONOS_FABRIC_P4}
    "${testExtraArgs} --auto-init-metadata -DCPU_PORT=320 -arch v1model"
    ${ONOS_FABRIC_PTF} "all ^spgw ^int")
# FIXME: remove disabling of parser min/max depth limits (P4C-4170)
p4c_add_ptf_test_with_ptfdir_and_spec (
    "tofino" fabric-DWITH_SPGW ${ONOS_FABRIC_P4}
    "${testExtraArgs} --auto-init-metadata -DCPU_PORT=320 -DWITH_SPGW -arch v1model -Xp4c=\"--disable-parse-depth-limit\""
    ${ONOS_FABRIC_PTF} "all ^int")
# FIXME: remove disabling of parser min/max depth limits (P4C-4170)
p4c_add_ptf_test_with_ptfdir_and_spec (
    "tofino" fabric-DWITH_INT_TRANSIT ${ONOS_FABRIC_P4}
    "${testExtraArgs} --auto-init-metadata -DCPU_PORT=320 -DWITH_INT_TRANSIT -arch v1model -Xp4c=\"--disable-parse-depth-limit\""
    ${ONOS_FABRIC_PTF} "all ^spgw")
# FIXME: remove disabling of parser min/max depth limits (P4C-4170)
p4c_add_ptf_test_with_ptfdir_and_spec (
    "tofino" fabric-DWITH_SPGW-DWITH_INT_TRANSIT ${ONOS_FABRIC_P4}
    "${testExtraArgs} --auto-init-metadata -DCPU_PORT=320 -DWITH_SPGW -DWITH_INT_TRANSIT -arch v1model -Xp4c=\"--disable-parse-depth-limit\""
    ${ONOS_FABRIC_PTF} "all")
p4c_add_test_label("tofino" "need_scapy" "fabric")
p4c_add_test_label("tofino" "need_scapy" "fabric-DWITH_SPGW")
p4c_add_test_label("tofino" "need_scapy" "fabric-DWITH_INT_TRANSIT")
p4c_add_test_label("tofino" "need_scapy" "fabric-DWITH_SPGW-DWITH_INT_TRANSIT")

file(RELATIVE_PATH tofino32q-3pipe_path ${P4C_SOURCE_DIR} ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/tofino32q-3pipe/sfc.p4)
p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} FALSE
  "tofino32q-3pipe" ${tofino32q-3pipe_path} "${testExtraArgs} -tofino -arch tna" "")

# subset of p4factory tests that we want to run as part of regressions
# One # means it fails badly but should get it to run soon
# Two # means it is not required for switch, but we should still try to compile
# Remove opcode tests to avoid timeout, these are run as part of nightly
# opcode_test_signed
# opcode_test_saturating
# opcode_test_signed_and_saturating
set (P4FACTORY_REGRESSION_TESTS
  basic_switching
  # # # bf-diags
  fast_reconfig
  ha
  mirror_test
  multicast_test
  pcie_pkt_test
  pgrs
  perf_test_alpm   # (a.k.a alpm-pd-perf)
  # # pvs
  resubmit
  smoke_large_tbls
  )

# p4-tests has all the includes at the same level with the programs.
# exclude tofino.p4 which is included in some programs
# exclude fifo_pair.p4 which is jbay specific test
# exclude all netcache p4s and add it as a separate test
# exclude ipv4_checksum.p4 (include it in JBay tests)
set (BFN_EXCLUDE_PATTERNS "tofino\\.p4" "fifo_pair\\.p4" "defines\\.p4"
                          "fast_update\\.p4" "headers\\.p4" "heavy_hitter\\.p4"
                          "ipv4\\.p4" "meter\\.p4" "netcache\\.p4" "parser\\.p4"
                          "slow_update\\.p4" "ipv4_checksum\\.p4" "lookup\\.p4")
set (BFN_TESTS "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/programs/*/*.p4")
bfn_find_tests ("${BFN_TESTS}" ALL_BFN_TESTS EXCLUDE "${BFN_EXCLUDE_PATTERNS}")
# make a list of all the tests that we want to run PTF on
set (P4F_PTF_TESTS)
foreach (t IN LISTS P4FACTORY_REGRESSION_TESTS)
  list (APPEND P4F_PTF_TESTS
    "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/programs/${t}/${t}.p4")
endforeach()
bfn_add_p4factory_tests("tofino" "tofino" "${TOFINO_P414_TEST_ARCH}" "smoketest_programs\;p414_nightly" P4F_PTF_TESTS)

set (P4FACTORY_PROGRAMS_PATH "extensions/p4_tests/p4-programs/programs")
# Add extra build flags for PD gen

bfn_set_pd_build_flag("tofino" "${P4FACTORY_PROGRAMS_PATH}/perf_test_alpm/perf_test_alpm.p4"
  "--gen-perf-test-pd")

bfn_set_ptf_ports_json_file("tofino" "extensions/p4_tests/p4-programs/programs/ha/ha.p4" "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/ptf-tests/ha/ports.json")
bfn_set_pd_build_flag("tofino" "extensions/p4_tests/p4-programs/programs/ha/ha.p4" "--gen-hitless-ha-test-pd")

# Pick a set of tests for the tests that are timing out:
bfn_set_ptf_test_spec("tofino" "${P4FACTORY_PROGRAMS_PATH}/multicast_test/multicast_test.p4"
  "test.TestBasic
   ^test.TestYid
   ^test.TestXid
   test.TestEcmp
   ^test.TestLag
   ^test.TestBackup
   ^test.TestGetEntry
   test.TestRegAccess")
bfn_set_ptf_test_spec("tofino" "${P4FACTORY_PROGRAMS_PATH}/smoke_large_tbls/smoke_large_tbls.p4"
  "test.TestAtcam
   test.TestAtcamTernaryValid")

bfn_set_ptf_test_spec("tofino" "${P4FACTORY_PROGRAMS_PATH}/mirror_test/mirror_test.p4"
   "test.TestBasicForwarding
   test.TestBasicIngMir
   test.TestBasicEgrMir
   test.TestBatching")

bfn_set_ptf_test_spec("tofino" "${P4FACTORY_PROGRAMS_PATH}/pgrs/pgrs.p4"
    "test.TestTxn
     test.TestAddrOverride
     test.TestTimerAllPipe
     test.TestTimerOneShot
     test.TestPattern
     test.TestBatch")
# test.TestRecircAll fails with "AssertionError: Expected packet was not received on device 0, port 0."

# for all other p4factory tests, add them as compile only.
set (P4F_COMPILE_ONLY)
foreach (t IN LISTS ALL_BFN_TESTS)
  list (FIND P4F_PTF_TESTS ${t} found_as_ptf)
  if (${found_as_ptf} EQUAL -1)
    list (APPEND P4F_COMPILE_ONLY ${t})
  endif()
endforeach()
p4c_add_bf_backend_tests("tofino" "tofino" "${TOFINO_P414_TEST_ARCH}" "smoketest_programs\;p414_nightly" "${P4F_COMPILE_ONLY}")

# Other PD tests

p4c_add_ptf_test_with_ptfdir("tofino" "smoketest_programs_alpm_test" "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/programs/alpm_test/alpm_test.p4"
  "${testExtraArgs} -pd -to 2000 -arch ${TOFINO_P414_TEST_ARCH}" "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/ptf-tests/alpm_test")
p4c_add_test_label("tofino" "p414_nightly" "smoketest_programs_alpm_test")
bfn_set_ptf_test_spec("tofino" "smoketest_programs_alpm_test"
  "test.TestAddRoute
   ^test.TestCapacity
   test.TestCoveringPrefix
   test.TestDefaultEntry
   test.TestDrop
   test.TestManyEntries
   test.TestModify")

# test.TestSnapshot fails after the model update (DRV-2626)
p4c_add_ptf_test_with_ptfdir("tofino" "smoketest_programs_alpm_test_2" "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/programs/alpm_test/alpm_test.p4"
  "${testExtraArgs} -pd -to 2000 -arch ${TOFINO_P414_TEST_ARCH}" "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/ptf-tests/alpm_test")
p4c_add_test_label("tofino" "p414_nightly" "smoketest_programs_alpm_test_2")
bfn_set_ptf_test_spec("tofino" "smoketest_programs_alpm_test_2"
   "test.TestIdleTime
   ^test.TestSnapshot
   test.TestStateRestore
   test.TestTcamMove")

p4c_add_ptf_test_with_ptfdir("tofino" "smoketest_programs_alpm_test_TestRealData" "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/programs/alpm_test/alpm_test.p4"
  "${testExtraArgs} -pd -to 2000 -arch ${TOFINO_P414_TEST_ARCH}" "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/ptf-tests/alpm_test")
p4c_add_test_label("tofino" "p414_nightly" "smoketest_programs_alpm_test_TestRealData")
bfn_set_ptf_test_spec("tofino" "smoketest_programs_alpm_test_TestRealData"
   "test.TestRealData")

p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_programs_basic_ipv4" "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/internal_p4_14/basic_ipv4/basic_ipv4.p4"
    "${testExtraArgs} -pd -to 2000 -arch ${TOFINO_P414_TEST_ARCH}" "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/internal_p4_14/basic_ipv4")
p4c_add_test_label("tofino" "p414_nightly" "smoketest_programs_basic_ipv4")
bfn_set_ptf_test_spec("tofino" "smoketest_programs_basic_ipv4"
         "test.TestExm6way4Entries
          test.TestDeepADT
          test.TestExm5way4Entries
          test.TestTcamStateRestoreLarge
          test.TestExm4way3Entries
          test.TestAddRemPort
          test.TestSelectorActions
          test.TestExm4way4Entries
          test.TestRange3
          test.TestMacRW
          test.TestExm3way4Entries
          test.TestTcamScopesMax")
bfn_set_ptf_ports_json_file("tofino" "smoketest_programs_basic_ipv4" "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/internal_p4_14/basic_ipv4/ports.json")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_programs_basic_ipv4_2" "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/internal_p4_14/basic_ipv4/basic_ipv4.p4"
    "${testExtraArgs} -pd -to 2000 -arch ${TOFINO_P414_TEST_ARCH}" "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/internal_p4_14/basic_ipv4")
p4c_add_test_label("tofino" "p414_nightly" "smoketest_programs_basic_ipv4_2")
bfn_set_ptf_test_spec("tofino" "smoketest_programs_basic_ipv4_2"
         "test.TestTblPropSymmetricEntries
          test.TestExm5way3Entries
          test.TestSelectorStateRestore
          test.TestIndirectActionStateRestore
          test.TestTblDbgCountersStage
          test.TestTblPropSymmetric
          test.TestExm4way7Entries
          test.TestExmStateRestore
          test.TestNoKeyNoParamTables
          test.TestAddRoute
          test.TestDefaultEntriesAllStage")
bfn_set_ptf_ports_json_file("tofino" "smoketest_programs_basic_ipv4_2" "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/internal_p4_14/basic_ipv4/ports.json")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_programs_basic_ipv4_3" "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/internal_p4_14/basic_ipv4/basic_ipv4.p4"
    "${testExtraArgs} -pd -to 2000 -arch ${TOFINO_P414_TEST_ARCH}" "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/internal_p4_14/basic_ipv4")
p4c_add_test_label("tofino" "p414_nightly" "smoketest_programs_basic_ipv4_3")
bfn_set_ptf_test_spec("tofino" "smoketest_programs_basic_ipv4_3"
         "test.TestExm4way5Entries
          test.TestTcamEntries
          test.TestTcamScopes
          test.TestHeadPtrMove
          test.TestDrop
          test.TestMatchSpecApi
          test.TestSnapshotWithTimer
          test.TestExm3way5Entries
          test.TestTernaryValidMatch
          test.TestRmHdr
          test.TestTcamScopes1")
bfn_set_ptf_ports_json_file("tofino" "smoketest_programs_basic_ipv4_3" "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/internal_p4_14/basic_ipv4/ports.json")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_programs_basic_ipv4_4" "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/internal_p4_14/basic_ipv4/basic_ipv4.p4"
    "${testExtraArgs} -pd -to 2000 -arch ${TOFINO_P414_TEST_ARCH}" "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/internal_p4_14/basic_ipv4")
p4c_add_test_label("tofino" "p414_nightly" "smoketest_programs_basic_ipv4_4")
bfn_set_ptf_test_spec("tofino" "smoketest_programs_basic_ipv4_4"
         "test.TestSelector
          test.TestAllHit
          test.TestAddHdr
          test.TestTcamSnapshot
          test.TestTcamMove
          test.TestExm6way3Entries
          test.TestRangeTernaryValid
          test.TestTcamDuplicateEntries")
bfn_set_ptf_ports_json_file("tofino" "smoketest_programs_basic_ipv4_4" "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/internal_p4_14/basic_ipv4/ports.json")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_programs_basic_ipv4_5" "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/internal_p4_14/basic_ipv4/basic_ipv4.p4"
    "${testExtraArgs} -pd -to 2000 -arch ${TOFINO_P414_TEST_ARCH}" "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/internal_p4_14/basic_ipv4")
p4c_add_test_label("tofino" "p414_nightly" "smoketest_programs_basic_ipv4_5")
bfn_set_ptf_test_spec("tofino" "smoketest_programs_basic_ipv4_5"
         "test.TestIndirectAction
          test.TestSelectorIterator
          test.TestExmScopes
          test.TestRange
          test.TestRange2
          test.TestExm3way3Entries
          test.TestAllStage
          test.TestTblDbgCounters
          test.TestLogTblCounter
          test.TestExmSnapshot")
bfn_set_ptf_ports_json_file("tofino" "smoketest_programs_basic_ipv4_5" "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/internal_p4_14/basic_ipv4/ports.json")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_programs_basic_ipv4_TestLearning" "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/internal_p4_14/basic_ipv4/basic_ipv4.p4"
    "${testExtraArgs} -pd -to 2000 -arch ${TOFINO_P414_TEST_ARCH}" "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/internal_p4_14/basic_ipv4")
p4c_add_test_label("tofino" "p414_nightly" "smoketest_programs_basic_ipv4_TestLearning")
bfn_set_ptf_test_spec("tofino" "smoketest_programs_basic_ipv4_TestLearning"
         "test.TestLearning")
bfn_set_ptf_ports_json_file("tofino" "smoketest_programs_basic_ipv4_TestLearning" "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/internal_p4_14/basic_ipv4/ports.json")

p4c_add_ptf_test_with_ptfdir ("tofino" "COMPILER-1186" "${BFN_P4C_SOURCE_DIR}/glass/testsuite/p4_tests/noviflow/COMPILER-1186/case9213b.p4"
    "${testExtraArgs} -pd -to 2000" "${BFN_P4C_SOURCE_DIR}/glass/testsuite/p4_tests/noviflow/COMPILER-1186")

p4c_add_ptf_test_with_ptfdir ("tofino" "psa_recirculate" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/ptf/psa_recirculate.p4"
    "${testExtraArgs} -ptf -to 2000 -arch psa -Xp4c=\"--disable-parse-min-depth-limit\""
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/ptf/psa_recirculate.ptf")

p4c_add_ptf_test_with_ptfdir ("tofino" "psa_resubmit" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/ptf/psa_resubmit.p4"
    "${testExtraArgs} -ptf -to 2000 -arch psa -Xp4c=\"--disable-parse-min-depth-limit\""
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/ptf/psa_resubmit.ptf")

p4c_add_ptf_test_with_ptfdir ("tofino" "psa_clone_i2e" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/ptf/psa_clone_i2e.p4"
    "${testExtraArgs} -ptf -to 2000 -arch psa -Xp4c=\"--disable-parse-min-depth-limit\""
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/ptf/psa_clone_i2e.ptf")

p4c_add_ptf_test_with_ptfdir ("tofino" "psa_clone_e2e" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/ptf/psa_clone_e2e.p4"
    "${testExtraArgs} -ptf -to 2000 -arch psa -Xp4c=\"--disable-parse-min-depth-limit\""
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/ptf/psa_clone_e2e.ptf")

p4c_add_ptf_test_with_ptfdir ("tofino" "psa_checksum" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/ptf/psa_checksum.p4"
    "${testExtraArgs} -ptf -to 2000 -arch psa -Xp4c=\"--disable-parse-min-depth-limit\""
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/ptf/psa_checksum.ptf")

# 500s timeout is too little for compiling and testing the entire test, bumping it up
set_tests_properties("tofino/smoketest_programs_basic_ipv4" PROPERTIES TIMEOUT 3600)
set_tests_properties("tofino/smoketest_programs_basic_ipv4_2" PROPERTIES TIMEOUT 3600)
set_tests_properties("tofino/smoketest_programs_basic_ipv4_3" PROPERTIES TIMEOUT 3600)
set_tests_properties("tofino/smoketest_programs_basic_ipv4_4" PROPERTIES TIMEOUT 3600)
set_tests_properties("tofino/smoketest_programs_basic_ipv4_5" PROPERTIES TIMEOUT 3600)
set_tests_properties("tofino/smoketest_programs_basic_ipv4_TestLearning" PROPERTIES TIMEOUT 3600)

p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_programs_dkm" "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/programs/dkm/dkm.p4"
    "${testExtraArgs} -pd -to 2000 -arch ${TOFINO_P414_TEST_ARCH}" "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/ptf-tests/dkm")
p4c_add_test_label("tofino" "p414_nightly" "smoketest_programs_dkm")

p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_programs_exm_direct" "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/internal_p4_14/exm_direct/exm_direct.p4"
    "${testExtraArgs} -pd -to 2000 -arch ${TOFINO_P414_TEST_ARCH}" "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/internal_p4_14/exm_direct")
p4c_add_test_label("tofino" "p414_nightly" "smoketest_programs_exm_direct")
bfn_set_pd_build_flag("tofino" "smoketest_programs_exm_direct"
    "--gen-exm-test-pd")
bfn_set_ptf_test_spec("tofino" "smoketest_programs_exm_direct"
        "^test.TestIdleTimeTCAM
        test.TestExm4way8Entries")

p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_programs_exm_direct_2" "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/internal_p4_14/exm_direct/exm_direct.p4"
    "${testExtraArgs} -pd -to 2000 -arch ${TOFINO_P414_TEST_ARCH}" "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/internal_p4_14/exm_direct")
p4c_add_test_label("tofino" "p414_nightly" "smoketest_programs_exm_direct_2")
bfn_set_pd_build_flag("tofino" "smoketest_programs_exm_direct_2"
    "--gen-exm-test-pd")
bfn_set_ptf_test_spec("tofino" "smoketest_programs_exm_direct_2"
        "^test.TestIdleTimeStateRestore
        test.TestExm5way5Entries
        test.TestExmMoveReg
        test.TestExm4way6Entries
        ^test.TestIdleTimeMovereg
        ^test.TestIdleTimeEXM
        test.TestExm6way5Entries
        test.TestExm6way6Entries
        test.TestExm3way7Entries")

p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_programs_exm_direct_1" "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/internal_p4_14/exm_direct_1/exm_direct_1.p4"
    "${testExtraArgs} -pd -to 2000 -arch ${TOFINO_P414_TEST_ARCH}" "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/internal_p4_14/exm_direct_1")
p4c_add_test_label("tofino" "p414_nightly" "smoketest_programs_exm_direct_1")
bfn_set_pd_build_flag("tofino" "smoketest_programs_exm_direct_1"
    "--gen-exm-test-pd")
bfn_set_ptf_test_spec("tofino" "smoketest_programs_exm_direct_1"
        "^test.TestExm5way8Entries
        ^test.TestExmdeep64k
        test.TestExm4way2Entries")

p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_programs_exm_direct_1_2" "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/internal_p4_14/exm_direct_1/exm_direct_1.p4"
    "${testExtraArgs} -pd -to 2000 -arch ${TOFINO_P414_TEST_ARCH}" "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/internal_p4_14/exm_direct_1")
p4c_add_test_label("tofino" "p414_nightly" "smoketest_programs_exm_direct_1_2")
bfn_set_pd_build_flag("tofino" "smoketest_programs_exm_direct_1_2"
    "--gen-exm-test-pd")
bfn_set_ptf_test_spec("tofino" "smoketest_programs_exm_direct_1_2"
        "test.TestExm6way2Entries
        test.TestExm5way7Entries
        test.TestExm3way2Entries
        ^test.TestExmdeep32k
        ^test.TestExm6way8Entries
        test.TestExm4way1Entries
        test.TestExm6way1Entries
        ^test.TestExmwidekey
        test.TestExm3way1Entries
        test.TestExm5way2Entries
        test.TestExm6way7Entries
        test.TestExm5way1Entries
        test.TestExm5way7EntriesDefaultEntry")

p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_programs_exm_indirect_1" "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/internal_p4_14/exm_indirect_1/exm_indirect_1.p4"
    "${testExtraArgs} -pd -to 2000 -arch ${TOFINO_P414_TEST_ARCH}" "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/internal_p4_14/exm_indirect_1")
p4c_add_test_label("tofino" "p414_nightly" "smoketest_programs_exm_indirect_1")
bfn_set_pd_build_flag("tofino" "smoketest_programs_exm_indirect_1"
        "--gen-exm-test-pd")
bfn_set_ptf_test_spec("tofino" "smoketest_programs_exm_indirect_1"
        "test.TestActSelIterators
        test.TestDirectStats")

p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_programs_exm_indirect_1_2" "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/internal_p4_14/exm_indirect_1/exm_indirect_1.p4"
    "${testExtraArgs} -pd -to 2000 -arch ${TOFINO_P414_TEST_ARCH}" "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/internal_p4_14/exm_indirect_1")
p4c_add_test_label("tofino" "p414_nightly" "smoketest_programs_exm_indirect_1_2")
bfn_set_pd_build_flag("tofino" "smoketest_programs_exm_indirect_1_2"
        "--gen-exm-test-pd")
bfn_set_ptf_test_spec("tofino" "smoketest_programs_exm_indirect_1_2"
        "test.TestDirectStatsPkts28Bytes36
        test.TestDirectStatsPkts32bits
        test.TestExmProxyHash
        test.TestIndirectStatPkt64bits
        test.TestIndirectStatsPkts32bits
        test.TestSelector
        test.TestSelectorScopes
        test.TestExm4way6Entries
        test.TestExmHashAction
        test.TestExmHashAction2")


p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_programs_exm_smoke_test" "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/internal_p4_14/exm_smoke_test/exm_smoke_test.p4"
    "${testExtraArgs} -pd -to 2000 -arch ${TOFINO_P414_TEST_ARCH}" "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/internal_p4_14/exm_smoke_test")
p4c_add_test_label("tofino" "p414_nightly" "smoketest_programs_exm_smoke_test")
bfn_set_pd_build_flag("tofino" "smoketest_programs_exm_smoke_test"
        "--gen-exm-test-pd")
bfn_set_ptf_test_spec("tofino" "smoketest_programs_exm_smoke_test"
        "^test.TestExmdeep64k
        test.TestExm4way2Entries")

p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_programs_exm_smoke_test_2" "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/internal_p4_14/exm_smoke_test/exm_smoke_test.p4"
    "${testExtraArgs} -pd -to 2000 -arch ${TOFINO_P414_TEST_ARCH}" "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/internal_p4_14/exm_smoke_test")
p4c_add_test_label("tofino" "p414_nightly" "smoketest_programs_exm_smoke_test_2")
bfn_set_pd_build_flag("tofino" "smoketest_programs_exm_smoke_test_2"
        "--gen-exm-test-pd")
bfn_set_ptf_test_spec("tofino" "smoketest_programs_exm_smoke_test_2"
        "test.TestExm6way2Entries
        test.TestExm3way2Entries
        ^test.TestExmdeep32k
        test.TestExm6way8Entries
        test.TestExm4way1Entries
        test.TestExm6way1Entries
        ^test.TestExmwidekey
        test.TestExm3way1Entries
        test.TestExm5way2Entries
        test.TestExm6way7Entries
        test.TestExm5way1Entries")

p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_programs_stful" "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/programs/stful/stful.p4"
    "${testExtraArgs} -pd -to 2000 -arch ${TOFINO_P414_TEST_ARCH}" "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/ptf-tests/stful")
p4c_add_test_label("tofino" "p414_nightly" "smoketest_programs_stful")
bfn_set_ptf_test_spec("tofino" "smoketest_programs_stful"
        "all
         ^test.TestStfulSelTbl
         ^test.TestStfulSelTbl2")

# 500s timeout is too little for compiling and testing the entire test, bumping it up
set_tests_properties("tofino/smoketest_programs_stful" PROPERTIES TIMEOUT 3600)

p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_programs_meters" "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/programs/meters/meters.p4"
    "${testExtraArgs} -pd -to 2000 -arch ${TOFINO_P414_TEST_ARCH}" "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/ptf-tests/meters")
p4c_add_test_label("tofino" "p414_nightly" "smoketest_programs_meters")
bfn_set_ptf_test_spec("tofino" "smoketest_programs_meters"
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
bfn_set_ptf_ports_json_file("tofino" "smoketest_programs_meters" "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/ptf-tests/meters/ports.json")

# 500s timeout is too little for compiling and testing the entire test, bumping it up
set_tests_properties("tofino/smoketest_programs_meters" PROPERTIES TIMEOUT 3600)

p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_programs_hash_driven" "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/programs/hash_driven/hash_driven.p4"
    "${testExtraArgs} -pd -to 2000 -arch ${TOFINO_P414_TEST_ARCH}" "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/ptf-tests/hash_driven")
p4c_add_test_label("tofino" "p414_nightly" "smoketest_programs_hash_driven")

# 500s timeout is too little for compiling and testing the entire test, bumping it up
set_tests_properties("tofino/smoketest_programs_hash_driven" PROPERTIES TIMEOUT 3600)

p4c_add_ptf_test_with_ptfdir ("tofino" "miss_clause" ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/pd/miss_clause.p4
    "${testExtraArgs} -pd" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/pd/miss_clause.ptf")

p4c_add_ptf_test_with_ptfdir ("tofino" "brig_569"
    ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/pd/BRIG-569/brig_569.p4
    "${testExtraArgs} -pd" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/pd/BRIG-569/brig_569.ptf")
p4c_add_test_label("tofino" "need_scapy" "brig_569")

p4c_add_ptf_test_with_ptfdir ("tofino" "case6684" ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/pd/BRIG-847/case6684.p4
    "${testExtraArgs} -pd" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/pd/BRIG-847/case6684.ptf")

p4c_add_ptf_test_with_ptfdir ("tofino" "p4c-2229" ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/pd/p4c-2229/p4src/simple_l3_lag_ecmp.p4
    "${testExtraArgs} -pd -DRESILIENT_SELECTION" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/pd/p4c-2229/ptf")

p4c_add_ptf_test_with_ptfdir ("tofino" "simple_l3_checksum" ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/pd/COMPILER-1008/simple_l3_checksum.p4
    "${testExtraArgs} -pd" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/pd/COMPILER-1008/simple_l3_checksum.ptf")
p4c_add_test_label("tofino" "need_scapy" "simple_l3_checksum")

p4c_add_ptf_test_with_ptfdir ("tofino" "basic_switching" ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/pd/COMPILER-980/basic_switching.p4
     "${testExtraArgs} -pd -Xp4c=\"--disable-parse-min-depth-limit\""
     "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/pd/COMPILER-980/basic_switching.ptf")

p4c_add_ptf_test_with_ptfdir ("tofino" "case6738" ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/pd/BRIG-879/case6738.p4
     "${testExtraArgs} -pd" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/pd/BRIG-879/case6738.ptf")

p4c_add_ptf_test_with_ptfdir ("tofino" "simple_l3_mirror" ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/pd/BRIG-879/simple_l3_mirror.p4
     "${testExtraArgs} -pd" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/pd/BRIG-879/simple_l3_mirror.ptf")
p4c_add_test_label("tofino" "need_scapy" "simple_l3_mirror")

p4c_add_ptf_test_with_ptfdir ("tofino" "p4c_737" ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/pd/p4c-737/oinked_0.p4
     "${testExtraArgs} -pd" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/pd/p4c-737/oinked_0.ptf")

p4c_add_ptf_test_with_ptfdir ("tofino" "decaf_10" ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/pd/decaf_10/decaf_10.p4
     "${testExtraArgs} -pd" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/pd/decaf_10/decaf_10.ptf")

p4c_add_ptf_test_with_ptfdir ("tofino" "P4C-1021-1"
    ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/pd/P4C-1021-1/P4C_1021_1.p4
    "${testExtraArgs} -pd" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/pd/P4C-1021-1/P4C_1021_1.ptf")

p4c_add_ptf_test_with_ptfdir ("tofino" "P4C-1021-2"
    ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/pd/P4C-1021-2/P4C_1021_2.p4
    "${testExtraArgs} -pd" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/pd/P4C-1021-2/P4C_1021_2.ptf")

p4c_add_ptf_test_with_ptfdir ("tofino" "case5577" ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/pd/COMPILER-897/case5577.p4
    "${testExtraArgs} -pd" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/pd/COMPILER-897")

# Barefoot academy tests
set (BA101_TESTS_FOR_TOFINO "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/ba-101/labs/*/solution/p4src/*.p4")
p4c_find_tests("${BA101_TESTS_FOR_TOFINO}" ba101_tests INCLUDE "__TARGET_TOFINO__")
# message("BA-101 tests: ${ba101_tests}")
foreach(t IN LISTS ba101_tests)
  get_filename_component(__td ${t} DIRECTORY)
  string (REGEX REPLACE "ba-101/labs/([0-9]+[a-z0-9_-]+)/solution.*" "\\1" __t ${__td})
  if (CMAKE_MATCH_1)
    set (testname ${CMAKE_MATCH_1})
  endif()
  set (ptfdir "${__td}/../ptf-tests")
  if (EXISTS ${ptfdir})
    p4c_add_ptf_test_with_ptfdir ("tofino" ba101_${testname} ${t} "${testExtraArgs} -pd -arch ${TOFINO_P414_TEST_ARCH}" ${ptfdir})
  else()
    file(RELATIVE_PATH testfile ${P4C_SOURCE_DIR} ${t})
    p4c_add_test_with_args("tofino" ${P4C_RUNTEST} FALSE ba101_${testname} ${testfile} "${testExtraArgs} -arch ${TOFINO_P414_TEST_ARCH}" "")
  endif()
  p4c_add_test_label("tofino" "BA-101" ba101_${testname})
  p4c_add_test_label("tofino" "p414_nightly" ba101_${testname})
  p4c_add_test_label("tofino" "p414_nightly_need_python2" ba101_${testname})
endforeach()

set (BA102_TESTS_FOR_TOFINO "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/ba-102/labs/*/solution/p4src/*.p4")
p4c_find_tests("${BA102_TESTS_FOR_TOFINO}" ba102_tests INCLUDE "tna.p4")
# message("BA-102 tests: ${ba102_tests}")
foreach(t IN LISTS ba102_tests)
  get_filename_component(p4name ${t} NAME)
  string (REGEX REPLACE ".p4" "" testname ${p4name})
  get_filename_component(__td ${t} DIRECTORY)
  set (ptfdir "${__td}/../ptf-tests")
  if (EXISTS ${ptfdir})
    p4c_add_ptf_test_with_ptfdir("tofino" ba102_${testname} ${t} "${testExtraArgs} -bfrt -arch tna -Xp4c=\"--disable-parse-depth-limit\"" ${ptfdir})
  else()
    file(RELATIVE_PATH testfile ${P4C_SOURCE_DIR} ${t})
    p4c_add_test_with_args("tofino" ${P4C_RUNTEST} FALSE ba102_${testname} ${testfile} "${testExtraArgs}"
	    "-arch tna -bfrt -force-link -Xp4c=\"--disable-parse-max-depth-limit\"")
  endif()
  p4c_add_test_label("tofino" "BA-102" ba102_${testname})
  set_tests_properties("tofino/ba102_${testname}" PROPERTIES RESOURCE_LOCK ptf_test_environment)
endforeach()
p4c_add_test_label("tofino" "UNSTABLE" "ba102_simple_wred")
p4c_add_test_label("tofino" "UNSTABLE" "ba102_simple_lpf")
p4c_add_test_label("tofino" "need_scapy" "ba102_simple_l3_mirror")
p4c_add_test_label("tofino" "need_scapy" "ba102_simple_l3_mpls")
p4c_add_test_label("tofino" "need_scapy" "ba102_simple_l3_arping")
p4c_add_test_label("tofino" "need_scapy" "ba102_simple_wred")
p4c_add_test_label("tofino" "need_scapy" "ba102_simple_lpf")

# p4testgen ptf tests for p4factory programs
p4c_add_ptf_test_with_ptfdir ("tofino" "p4testgen_emulation" ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/pd/p4testgen_regression/emulation.p4
    "${testExtraArgs} -pd -to 3600" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/pd/p4testgen_regression/emulation.ptf")
set_tests_properties("tofino/p4testgen_emulation" PROPERTIES TIMEOUT 3600)
p4c_add_ptf_test_with_ptfdir ("tofino" "p4testgen_basic_switching" ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/pd/p4testgen_regression/basic_switching.p4
    "${testExtraArgs} -pd" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/pd/p4testgen_regression/basic_switching.ptf")
p4c_add_ptf_test_with_ptfdir ("tofino" "p4testgen_pcie_pkt_test" ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/pd/p4testgen_regression/pcie_pkt_test.p4
    "${testExtraArgs} -pd" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/pd/p4testgen_regression/pcie_pkt_test.ptf")
p4c_add_ptf_test_with_ptfdir ("tofino" "p4testgen_smoke_large_tbls" ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/pd/p4testgen_regression/smoke_large_tbls.p4
    "${testExtraArgs} -pd -to 3600" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/pd/p4testgen_regression/smoke_large_tbls.ptf")
set_tests_properties("tofino/p4testgen_smoke_large_tbls" PROPERTIES TIMEOUT 3600)
p4c_add_ptf_test_with_ptfdir ("tofino" "p4testgen_centipedes_0" ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/pd/p4testgen_regression/centipedes_0.p4
    "${testExtraArgs} -pd" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/pd/p4testgen_regression/centipedes_0.ptf")
p4c_add_ptf_test_with_ptfdir ("tofino" "p4testgen_medal_0" ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/pd/p4testgen_regression/medal_0.p4
    "${testExtraArgs} -pd" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/pd/p4testgen_regression/medal_0.ptf")
p4c_add_ptf_test_with_ptfdir ("tofino" "p4testgen_plasmas_0" ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/pd/p4testgen_regression/plasmas_0.p4
    "${testExtraArgs} -pd" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/pd/p4testgen_regression/plasmas_0.ptf")
p4c_add_ptf_test_with_ptfdir ("tofino" "p4testgen_signets_0" ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/pd/p4testgen_regression/signets_0.p4
    "${testExtraArgs} -pd" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/pd/p4testgen_regression/signets_0.ptf")
p4c_add_ptf_test_with_ptfdir ("tofino" "p4testgen_laymen_0" ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/pd/p4testgen_regression/laymen_0.p4
    "${testExtraArgs} -pd" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/pd/p4testgen_regression/laymen_0.ptf")
p4c_add_ptf_test_with_ptfdir ("tofino" "p4testgen_faecess_0" ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/pd/p4testgen_regression/faecess_0.p4
    "${testExtraArgs} -pd" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/pd/p4testgen_regression/faecess_0.ptf")

## Manifest tests
# test the generation of the compiler archive, for a must pass P4_14 and P4_16 program
# will run as part of cpplint
p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} FALSE "easy-ternary-archive"
  extensions/p4_tests/p4_14/ptf/easy_ternary.p4 ""
  "-norun --arch ${TOFINO_P414_TEST_ARCH} --create-graphs --archive --validate-manifest")
p4c_add_test_label("tofino" "cpplint" "easy-ternary-archive")
p4c_add_test_label("tofino" "p414_nightly" "easy-ternary-archive")

p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} FALSE "tor-archive"
  extensions/p4_tests/p4_16/google-tor/p4/spec/tor.p4 ""
  "-norun --arch v1model --create-graphs --archive --validate-manifest")
p4c_add_test_label("tofino" "cpplint" "tor-archive")
set_tests_properties("tofino/tor-archive" PROPERTIES RESOURCE_LOCK tor_output_dir)

set (P4FACTORY_INTERNAL_PROGRAMS_PATH "extensions/p4_tests/p4-programs/internal_p4_14")

set (P4FACTORY_REGRESSION_TESTS_INTERNAL
  # action_spec_format.p4                     # PTF failure
  atomic_mod
  clpm
  dyn_hash
  ecc
  emulation
  entry_read_from_hw
  # hash_test                                 # PTF failure
  # incremental_checksum                      # PTF failure
  # mau_mem_test                              # PTF failure
  # mau_tcam_test                             # test runs for too long
  mau_test
  mod_field_conditionally
  # multi_thread_test                         # PTF failure
  # multicast_scale                           # test runs for too long
  # netcache                                  # PTF failure (post new dynhash configure BF-RT update)
  opcode_test
  opcode_test_saturating
  opcode_test_signed
  pctr
  power
  range
  simple_l3_checksum_branched_end
  simple_l3_checksum_single_end
  simple_l3_checksum_taken_default_ingress
  simple_l3_mirror
  stashes
  tcam_latch
  tcam_use_valid
  # tofino_diag                                # PTF failure
  )

# p4-tests internal
set (BFN_TESTS_INTERNAL "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/internal_p4_14/*/*.p4")
bfn_find_tests ("${BFN_TESTS_INTERNAL}" ALL_BFN_TESTS_INTERNAL EXCLUDE "${BFN_EXCLUDE_PATTERNS}")
# make a list of all the tests that we want to run PTF on
set (P4F_PTF_TESTS_INTERNAL)
foreach (t IN LISTS P4FACTORY_REGRESSION_TESTS_INTERNAL)
  list (APPEND P4F_PTF_TESTS_INTERNAL
    "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/internal_p4_14/${t}/${t}.p4")
endforeach()
set (P4FACTORY_INTERNAL_PROGRAMS_PATH "extensions/p4_tests/p4-programs/internal_p4_14")
bfn_add_p4factory_tests("tofino" "tofino" "${TOFINO_P414_TEST_ARCH}" "smoketest_programs_internal\;p414_nightly" P4F_PTF_TESTS_INTERNAL)
bfn_set_p4_build_flag("tofino" "${P4FACTORY_INTERNAL_PROGRAMS_PATH}/power/power.p4" "-Xp4c=\"--no-power-check\"")
bfn_set_pd_build_flag("tofino" "${P4FACTORY_INTERNAL_PROGRAMS_PATH}/ecc/ecc.p4" "--gen-md-pd --load-unavailable-resources ${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/internal_p4_14/ecc/resource_fail.rf")
p4c_add_test_label("tofino" "p414_nightly_need_python2" "${P4FACTORY_INTERNAL_PROGRAMS_PATH}/ecc/ecc.p4")
p4c_add_test_label("tofino" "p414_nightly_need_python2" "${P4FACTORY_INTERNAL_PROGRAMS_PATH}/mau_test/mau_test.p4")

# for all other p4factory internal tests, add them as compile only.
set (P4F_INTERNAL_COMPILE_ONLY)
foreach (t IN LISTS ALL_BFN_TESTS_INTERNAL)
  list (FIND P4F_PTF_TESTS_INTERNAL ${t} found_as_ptf)
  if (${found_as_ptf} EQUAL -1)
    list (APPEND P4F_INTERNAL_COMPILE_ONLY ${t})
  endif()
endforeach()
p4c_add_bf_backend_tests("tofino" "tofino" "${TOFINO_P414_TEST_ARCH}" "smoketest_programs_internal\;p414_nightly" "${P4F_INTERNAL_COMPILE_ONLY}")

## P4-16 Programs
set (P4FACTORY_P4_16_PROGRAMS
  tna_32q_2pipe
  tna_action_profile
  tna_action_selector
  tna_bridged_md
  tna_checksum
  tna_counter
  tna_custom_hash
  tna_digest
  tna_dkm
  tna_dyn_hashing
  tna_exact_match
  tna_field_slice
  tna_lpm_match
  tna_meter_bytecount_adjust
  tna_meter_lpf_wred
  tna_mirror
  tna_multicast
  tna_operations
  tna_pktgen
  tna_port_metadata
  tna_port_metadata_extern
  tna_proxy_hash
  tna_pvs
  tna_random
  tna_range_match
  tna_register
  tna_resubmit
  tna_symmetric_hash
  tna_ternary_match
  tna_timestamp
  )
## P4-16 Programs - compile-only
set (P4FACTORY_P4_16_PROGRAMS_COMPILE_ONLY
  tna_idletimeout
  )

## Internal P4-16 Programs
set (P4FACTORY_P4_16_PROGRAMS_INTERNAL
  misc1
  tna_pvs_multi_states
  tna_multi_prsr_programs_multi_pipes
  )

## Internal P4-16 Programs - compile-only
set (P4FACTORY_P4_16_PROGRAMS_INTERNAL_COMPILE_ONLY
  fr_test
  )

# TODO: How to enable these tests?
# tna_with_pdfixed_thrift
# tna_ipv4_checksum
# tna_register_bfrt_integration

# No ptf, compile-only
file(RELATIVE_PATH p4_16_programs_path ${P4C_SOURCE_DIR} ${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/p4_16_programs)
  # FIXME: remove disabling of parser min/max depth limits (P4C-4170)
p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} FALSE
  "p4_16_programs_tna_simple_switch" ${p4_16_programs_path}/tna_simple_switch/tna_simple_switch.p4 "${testExtraArgs} -tofino -arch tna -I${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/p4_16_programs -Xp4c=\"--disable-parse-depth-limit\"" "")
p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} FALSE
  "p4_16_programs_tna_32q_multiprogram_a" ${p4_16_programs_path}/tna_32q_multiprogram/program_a/tna_32q_multiprogram_a.p4 "${testExtraArgs} -tofino -arch tna -I${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/p4_16_programs/tna_32q_multiprogram" "")
p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} FALSE
  "p4_16_programs_tna_32q_multiprogram_b" ${p4_16_programs_path}/tna_32q_multiprogram/program_b/tna_32q_multiprogram_b.p4 "${testExtraArgs} -tofino -arch tna -I${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/p4_16_programs/tna_32q_multiprogram" "")

# PTF Fails, Compile only
# tna_snapshot
p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} FALSE
  "p4_16_programs_tna_snapshot" ${p4_16_programs_path}/tna_snapshot/tna_snapshot.p4 "${testExtraArgs} -tofino -arch tna -I${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/p4_16_programs" "")

# P4-16 Programs with PTF tests
foreach(t IN LISTS P4FACTORY_P4_16_PROGRAMS)
  # FIXME: remove disabling of parser min/max depth limits (P4C-4170)
  if (${t} STREQUAL "tna_meter_lpf_wred")
    p4c_add_ptf_test_with_ptfdir ("tofino" "p4_16_programs_${t}" "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/p4_16_programs/${t}/${t}.p4"
      "${testExtraArgs} -target tofino -arch tna -bfrt -Xp4c=\"--disable-parse-depth-limit\" -to 2000 --p4runtime-force-std-externs" "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/p4_16_programs/${t}")
  else()
    p4c_add_ptf_test_with_ptfdir ("tofino" "p4_16_programs_${t}" "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/p4_16_programs/${t}/${t}.p4"
      "${testExtraArgs} -target tofino -arch tna -bfrt -to 2000 --p4runtime-force-std-externs" "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/p4_16_programs/${t}")
  endif()
  bfn_set_p4_build_flag("tofino" "p4_16_programs_${t}" "-I${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/p4_16_programs")
  set (ports_json ${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/p4_16_programs/${t}/ports.json)
  if (EXISTS ${ports_json})
    bfn_set_ptf_ports_json_file("tofino" "p4_16_programs_${t}" ${ports_json})
  endif()
endforeach()

# Compile-only P4-16 Programs
foreach(t IN LISTS P4FACTORY_P4_16_PROGRAMS_COMPILE_ONLY)
  file(RELATIVE_PATH testfile ${P4C_SOURCE_DIR} "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/p4_16_programs/${t}/${t}.p4")
  p4c_add_test_with_args("tofino" ${P4C_RUNTEST} FALSE
    "p4_16_programs_${t}" "${testfile}" ""
    "${testExtraArgs} -target tofino -arch tna -I${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/p4_16_programs")
endforeach()

# Internal P4-16 Programs with PTF tests
foreach(t IN LISTS P4FACTORY_P4_16_PROGRAMS_INTERNAL)
  p4c_add_ptf_test_with_ptfdir ("tofino" "p4_16_programs_internal_${t}"
      "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/internal_p4_16/${t}/${t}.p4"
    "${testExtraArgs} -target tofino -arch tna -bfrt -to 2000"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/internal_p4_16/${t}")
  bfn_set_p4_build_flag("tofino" "p4_16_programs_internal_${t}"
      "-I${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/internal_p4_16")
  set (ports_json ${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/internal_p4_16/${t}/ports.json)
  if (EXISTS ${ports_json})
    bfn_set_ptf_ports_json_file("tofino" "p4_16_programs_internal_${t}" ${ports_json})
  endif()
endforeach()
p4c_add_test_label("tofino" "need_python2" "p4_16_programs_internal_tna_multi_prsr_programs_multi_pipes")

 set_tests_properties("tofino/p4_16_programs_internal_misc1" PROPERTIES TIMEOUT 900)
 set_tests_properties("tofino/p4_16_programs_internal_tna_pvs_multi_states" PROPERTIES TIMEOUT 900)

# Compile-only internal P4-16 Programs
foreach(t IN LISTS P4FACTORY_P4_16_PROGRAMS_INTERNAL_COMPILE_ONLY)
  file(RELATIVE_PATH testfile ${P4C_SOURCE_DIR} "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/internal_p4_16/${t}/${t}.p4")
  p4c_add_test_with_args("tofino" ${P4C_RUNTEST} FALSE
    "p4_16_programs_internal_${t}" "${testfile}" ""
    "${testExtraArgs} -target tofino -arch tna -I${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/internal_p4_16")
endforeach()

# Disable failing tests
 bfn_set_ptf_test_spec("tofino" "p4_16_programs_tna_pktgen"
     "all ^test.PortDownPktgenTest")
 bfn_set_ptf_test_spec("tofino" "p4_16_programs_tna_checksum"
     "all ^test.Ipv4UdpTranslateSpecialUpdTest")
 bfn_set_ptf_test_spec("tofino" "p4_16_programs_internal_tna_multi_prsr_programs_multi_pipes"
     "test.Phase0TableOpTest")
 bfn_set_ptf_test_spec("tofino" "p4_16_programs_internal_misc1"
     "all ^test.TestNonDflt ^test.IdleTimeoutNotifications")

# Add extra flags for p4_16_programs
# Exclude the MirrorHA tests as they have hard coded install path (specific to p4factory)
bfn_set_ptf_test_spec("tofino" "p4_16_programs_tna_mirror"
        "all ^test.TestIngEgrMirrorHA ^test.TestNegativeMirrorHA")

p4c_add_ptf_test_with_ptfdir (
    "tofino" "p4c_1585_a" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/bfrt/p4c_1585_a/p4c_1585_a.p4"
    "${testExtraArgs} -target tofino -arch tna -bfrt -to 2000" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/bfrt/p4c_1585_a")

p4c_add_ptf_test_with_ptfdir (
    "tofino" "p4c_1585_b" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/bfrt/p4c_1585_b/p4c_1585_b.p4"
    "${testExtraArgs} -target tofino -arch tna -bfrt -to 2000" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/bfrt/p4c_1585_b")

p4c_add_ptf_test_with_ptfdir (
    "tofino" "p4c_2249" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/bfrt/p4c_2249/p4c_2249.p4"
    "${testExtraArgs} -target tofino -arch tna -bfrt -to 2000 -Xp4c=\"--disable-parse-max-depth-limit\""
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/bfrt/p4c_2249")
set_tests_properties("tofino/p4c_2249" PROPERTIES TIMEOUT 2000)
p4c_add_test_label("tofino" "need_scapy" "p4c_2249")

p4c_add_ptf_test_with_ptfdir (
    "tofino" "p4c_3005" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/bfrt/p4c_3005/p4c3005.p4"
    "${testExtraArgs} -target tofino -arch tna -bfrt -to 2000" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/bfrt/p4c_3005/p4c3005.ptf")

p4c_add_ptf_test_with_ptfdir (
    "tofino" "p4c_2611" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/bfrt/p4c_2611/p4c2611.p4"
    "${testExtraArgs} -target tofino -arch tna -bfrt -to 2000" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/bfrt/p4c_2611/p4c2611.ptf")

p4c_add_ptf_test_with_ptfdir (
    "tofino" "p4c_2713" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/bfrt/p4c_2713/p4c2713.p4"
    "${testExtraArgs} -target tofino -arch tna -bfrt -to 2000" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/bfrt/p4c_2713/p4c2713.ptf")

p4c_add_ptf_test_with_ptfdir (
    "tofino" "t2na_static_entry" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/bfrt/t2na_static_entry/t2na_static_entry.p4"
    "${testExtraArgs} -target tofino -arch tna -bfrt -to 2000 " "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/bfrt/t2na_static_entry")

p4c_add_ptf_test_with_ptfdir (
    "tofino" "p4c_2785_sizeinbits" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/bfrt/p4c_2785/p4c_2785_sizeinbits.p4"
    "${testExtraArgs} -target tofino -arch tna -bfrt -to 2000" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/bfrt/p4c_2785/p4c_2785_sizeinbits.ptf")
p4c_add_ptf_test_with_ptfdir (
    "tofino" "p4c_2785_sizeinbytes" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/bfrt/p4c_2785/p4c_2785_sizeinbytes.p4"
    "${testExtraArgs} -target tofino -arch tna -bfrt -to 2000" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/bfrt/p4c_2785/p4c_2785_sizeinbytes.ptf")

p4c_add_ptf_test_with_ptfdir (
    "tofino" "p4c-3876" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/bfrt/p4c-3876/p4c_3876.p4"
    "${testExtraArgs} -target tofino -arch tna -bfrt -to 2000 -Xp4c=--disable-parse-min-depth-limit" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/bfrt/p4c-3876")
p4c_add_test_label("tofino" "need_scapy" "p4c-3876")

p4c_add_ptf_test_with_ptfdir (
    "tofino" "p4c_3343" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/customer/arista/p4c-3343.ptf/p4c_3343.p4"
    "${testExtraArgs} -target tofino -arch tna -bfrt -to 2400"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/customer/arista/p4c-3343.ptf")
bfn_set_p4_build_flag("tofino" "p4c_3343" "-Xp4c=\"--disable-power-check\"")
set_tests_properties("tofino/p4c_3343" PROPERTIES TIMEOUT 2400)

p4c_add_ptf_test_with_ptfdir (
    "tofino" "p4c_3926" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/ptf/p4c_3926.p4"
    "${testExtraArgs} -target tofino -arch tna -bfrt -to 2400 --p4runtime-force-std-externs"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/ptf/p4c_3926.ptf")

p4c_add_ptf_test_with_ptfdir (
    "tofino" "p4c_4158" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/bfrt/p4c_4158/p4c_4158.p4"
    "${testExtraArgs} -target tofino -arch tna -bfrt -to 2400 -Xp4c=\"--set-max-power 60\""
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/bfrt/p4c_4158")
set_tests_properties("tofino/p4c_4158" PROPERTIES TIMEOUT 2400)

# 500s timeout is too little for compiling and testing the entire switch, bumping it up
set_tests_properties("tofino/p4_16_programs_tna_exact_match" PROPERTIES TIMEOUT 1200)
set_tests_properties("tofino/p4_16_programs_tna_ternary_match" PROPERTIES TIMEOUT 2400)

# 600s is too little for forensics.p4
p4c_add_bf_backend_tests("tofino" "tofino" "tna" "base"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/compile_only/forensics.p4"
    "-to 900")
set_tests_properties("tofino/extensions/p4_tests/p4_16/compile_only/forensics.p4" PROPERTIES TIMEOUT 900)

include(Switch.cmake)

# TODO: Move all glass tests to this file
include(GlassTests.cmake)

include(TofinoMustPass.cmake)
include(TofinoXfail.cmake)
include(TofinoErrors.cmake)

set  (PHASE0_PRAGMA_P4 ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/compile_only/phase0_pragma.p4)
file (RELATIVE_PATH phase0test ${P4C_SOURCE_DIR} ${PHASE0_PRAGMA_P4})
p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} FALSE
  "phase0_pragma_test" ${phase0test} "${testExtraArgs} -Tphase0:5 -arch ${TOFINO_P414_TEST_ARCH}" "")
p4c_add_test_label("tofino" "p414_nightly" "phase0_pragma_test")
p4c_add_tofino_success_reason(
  "No phase 0 table found; skipping phase 0 translation"
  phase0_pragma_test
  )

set (NON_PR_ARISTA)
foreach (t IN LISTS P16_TNA_ARISTA_FILES)
  list (APPEND NON_PR_ARISTA
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/customer/arista/${t}")
endforeach()

set (NON_PR
  # Long running tests that can be run in nightly
  ${BFN_P4C_SOURCE_DIR}/glass/testsuite/p4_tests/phv/COMPILER-128/02-FullPHV1.p4
  ${BFN_P4C_SOURCE_DIR}/glass/testsuite/p4_tests/phv/COMPILER-158/comp158.p4
  ${BFN_P4C_SOURCE_DIR}/glass/testsuite/p4_tests/phv/COMPILER-891/comp_891.p4
  # Long running tests that can be run in nightly
  ${P4TESTDATA}/p4_14_samples/03-FullPHV2.p4
  ${P4TESTDATA}/p4_14_samples/05-FullTPHV.p4
  ${P4TESTDATA}/p4_14_samples/06-FullTPHV1.p4
  ${P4TESTDATA}/p4_14_samples/07-FullTPHV2.p4
  # CUST_MUSS_PASS (run on Jenkins)
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/customer/rdp/case9757.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/customer/ruijie/p4c-2250.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/customer/arista/p4c-1214.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/customer/arista/p4c-1813.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/customer/arista/p4c-2012.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/customer/arista/p4c-2030.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/customer/arista/p4c-2032.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/customer/arista/p4c-2143.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/customer/arista/p4c-2178.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/customer/arista/p4c-2189.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/customer/arista/p4c-2191.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/customer/arista/p4c-2370.p4
  # Obfuscated arista p4s
  "${NON_PR_ARISTA}"
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/customer/extreme/p4c-1562-1.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/customer/extreme/p4c-1572-b1.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/customer/extreme/p4c-1809-1.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/customer/extreme/p4c-1812-1.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/customer/extreme/p4c-2269.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/customer/extreme/p4c-2313.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/customer/kaloom/p4c-1832.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/customer/kaloom/p4c-2398.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/customer/kaloom/p4c-2410-leaf.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/customer/kaloom/p4c-2410-spine.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/customer/kaloom/p4c-2573-leaf.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/customer/kaloom/p4c-3678-leaf.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/customer/keysight/keysight-tf1.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/customer/keysight/pktgen9_16.p4
  # Customer Tests to run in nightly
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/customer/kaloom/p4c-2218.p4
  # Other XFails in compilers repo to run in nightly
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/compile_only/04-FullPHV3.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/compile_only/conditional_constraints_infinite_loop.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/compile_only/test_config_101_switch_msdc.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/customer/arista/p4c-1814.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/compile_only/p4c-1757-neg.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/customer/arista/p4c-1494.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/customer/arista/p4c-1652.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/customer/arista/p4c-2058.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/customer/arista/p4c-2076.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/customer/arista/p4c-2077.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/customer/arista/p4c-2257.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/customer/arista/p4c-2378.p4
  # Other XFails in Glass repo to run in nightly
  ${BFN_P4C_SOURCE_DIR}/glass/testsuite/p4_tests/arista/COMPILER-562/case3005.p4
  ${BFN_P4C_SOURCE_DIR}/glass/testsuite/p4_tests/arista/COMPILER-576/case3042.p4
  ${BFN_P4C_SOURCE_DIR}/glass/testsuite/p4_tests/arista/COMPILER-589/comp589.p4
  ${BFN_P4C_SOURCE_DIR}/glass/testsuite/p4_tests/arista/COMPILER-1105/case8039.p4
  ${BFN_P4C_SOURCE_DIR}/glass/testsuite/p4_tests/arista/COMPILER-1113/case8138.p4
  ${BFN_P4C_SOURCE_DIR}/glass/testsuite/p4_tests/arista/COMPILER-1114/case8156.p4
  ${BFN_P4C_SOURCE_DIR}/glass/testsuite/p4_tests/arista/DRV-543/case2499.p4
  ${BFN_P4C_SOURCE_DIR}/glass/testsuite/p4_tests/mau/COMPILER-1068/comp_1068.p4
  ${BFN_P4C_SOURCE_DIR}/glass/testsuite/p4_tests/mau/COMPILER-1160/comp_1160.p4
  ${BFN_P4C_SOURCE_DIR}/glass/testsuite/p4_tests/mau/COMPILER-362/icmp_typecode.p4
  ${BFN_P4C_SOURCE_DIR}/glass/testsuite/p4_tests/mau/COMPILER-464/scrab.p4
  ${BFN_P4C_SOURCE_DIR}/glass/testsuite/p4_tests/mau/COMPILER-465/tridacna-v2.p4
  ${BFN_P4C_SOURCE_DIR}/glass/testsuite/p4_tests/mau/COMPILER-465/tridacna.p4
  ${BFN_P4C_SOURCE_DIR}/glass/testsuite/p4_tests/mau/COMPILER-710/comp_710.p4
  ${BFN_P4C_SOURCE_DIR}/glass/testsuite/p4_tests/mau/COMPILER-726/comp_726.p4
  ${BFN_P4C_SOURCE_DIR}/glass/testsuite/p4_tests/mau/COMPILER-729/ipu.p4
  ${BFN_P4C_SOURCE_DIR}/glass/testsuite/p4_tests/mau/COMPILER-815/int_heavy.p4
  ${BFN_P4C_SOURCE_DIR}/glass/testsuite/p4_tests/mau/COMPILER-702/comp_702.p4
  ${BFN_P4C_SOURCE_DIR}/glass/testsuite/p4_tests/parde/COMPILER-1091/comp_1091.p4
  ${BFN_P4C_SOURCE_DIR}/glass/testsuite/p4_tests/parde/COMPILER-612/leaf.p4
  ${BFN_P4C_SOURCE_DIR}/glass/testsuite/p4_tests/phv/COMPILER-1065/comp_1065.p4
  ${BFN_P4C_SOURCE_DIR}/glass/testsuite/p4_tests/phv/COMPILER-1094/comp_1094.p4
  ${BFN_P4C_SOURCE_DIR}/glass/testsuite/p4_tests/phv/COMPILER-136/06-FullTPHV1.p4
  ${BFN_P4C_SOURCE_DIR}/glass/testsuite/p4_tests/phv/COMPILER-243/comp243.p4
  ${BFN_P4C_SOURCE_DIR}/glass/testsuite/p4_tests/phv/COMPILER-546/switch_comp546.p4
  ${BFN_P4C_SOURCE_DIR}/glass/testsuite/p4_tests/phv/COMPILER-587/l4l.p4
  ${BFN_P4C_SOURCE_DIR}/glass/testsuite/p4_tests/phv/COMPILER-706/terminate_parsing.p4
  ${BFN_P4C_SOURCE_DIR}/glass/testsuite/p4_tests/phv/COMPILER-724/comp_724.p4
  ${BFN_P4C_SOURCE_DIR}/glass/testsuite/p4_tests/phv/COMPILER-733/ipu_ingress.p4
  ${BFN_P4C_SOURCE_DIR}/glass/testsuite/p4_tests/phv/COMPILER-961/jk_msdc.p4
  ${BFN_P4C_SOURCE_DIR}/glass/testsuite/p4_tests/phv/test_config_294_parser_loop.p4
  ${BFN_P4C_SOURCE_DIR}/glass/testsuite/p4_tests/phv/test_config_415_bridge_ing_intr.p4
  ${BFN_P4C_SOURCE_DIR}/glass/testsuite/p4_tests/rdp/COMPILER-466/case2563_with_nop.p4
  ${BFN_P4C_SOURCE_DIR}/glass/testsuite/p4_tests/rdp/COMPILER-466/case2563_without_nop.p4
  ${BFN_P4C_SOURCE_DIR}/glass/testsuite/p4_tests/rdp/COMPILER-502/case2675.p4
  ${BFN_P4C_SOURCE_DIR}/glass/testsuite/p4_tests/rdp/COMPILER-533/case2736.p4
  ${BFN_P4C_SOURCE_DIR}/glass/testsuite/p4_tests/arista/COMPILER-868/comp_868.p4
  ${BFN_P4C_SOURCE_DIR}/glass/testsuite/p4_tests/arista/COMPILER-1152/case8686.p4
  ${BFN_P4C_SOURCE_DIR}/glass/testsuite/p4_tests/arista/MODEL-475/case9192.p4
)

foreach(t IN LISTS NON_PR)
  file(RELATIVE_PATH test_path ${P4C_SOURCE_DIR} ${t})
  p4c_add_test_label("tofino" "NON_PR_TOFINO" ${test_path})
endforeach()
