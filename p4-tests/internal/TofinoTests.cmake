set (tofino_timeout ${default_test_timeout})

# check for PTF requirements
packet_test_setup_check("tofino")
# check for STF requirements
simple_test_setup_check("tofino")

# experimental -- doesn't quite work yet
# bfn_add_switch("tofino")

include(internal/TofinoErrors.cmake)

set (P16_V1_INCLUDE_PATTERNS "include.*v1model.p4" "main|common_v1_test")
set (P16_V1_EXCLUDE_PATTERNS "tofino\\.h")
set (P16_V1MODEL_FOR_TOFINO
 "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/*.p4"
 "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/ptf/*.p4"
 "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/stf/*.p4"
 "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/customer/*/*.p4")
p4c_find_tests("${P16_V1MODEL_FOR_TOFINO}" p16_v1tests INCLUDE "${P16_V1_INCLUDE_PATTERNS}" EXCLUDE "${P16_V1_EXCLUDE_PATTERNS}")

set (TOFINO_V1_TEST_SUITES_P416
  ${p16_v1tests}
  )
p4c_add_bf_backend_tests("tofino" "tofino" "v1model" "base" "${TOFINO_V1_TEST_SUITES_P416}" "-I${CMAKE_CURRENT_SOURCE_DIR}/p4_16/includes")

set (P16_TNA_INCLUDE_PATTERNS "include.*(tofino|tna|tofino1_arch).p4" "main|common_tna_test")
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
  "obfuscated-nat_static.p4"
  "obfuscated-nat_vxlan.p4"
  "obfuscated-packet_filter.p4"
  "obfuscated-routescale.p4"
  "obfuscated-small_scale_test.p4"
  "obfuscated-stateless_load_balance_v4v6.p4"
  "obfuscated-vxlan_evpn_scale.p4"
)

# digest_tna.p4 is used for another test (digest-std-p4runtime) with different args
set (P16_TNA_EXCLUDE_FILES
    "p4c-1323-b\\.p4"
    "p4c-2143\\.p4"
    "p4c-2191\\.p4"
    "p4c-2398\\.p4"
    "p4c-2032\\.p4"
    "p4c-2030\\.p4"
    "p4c-2992\\.p4"
    "p4c-2410-leaf\\.p4"
    "p4c-2573-leaf\\.p4"
    "p4c-2753\\.p4"
    "p4c-3241\\.p4"
    "p4c-3139\\.p4"
    "p4c-3254\\.p4"
    "p4c-3255\\.p4"
    "p4c-2423\\.p4"
    "p4c-2534\\.p4"
    "p4c-3678-leaf\\.p4"
    "p4c-2722\\.p4"
    "p4c-3920-b\\.p4"
    "p4c_3926\\.p4"
    "p4c_4158\\.p4"
    "p4c-4064\\.p4"
    "forensics\\.p4"
    "mirror_constants\\.p4"
    "p4c_2601\\.p4"
    "p4c-2602\\.p4"
    "p4c-4770\\.p4"
    "p4c-2269\\.p4"
    "p4c-3582\\.p4"
    "p4c-5164\\.p4"
    "p4c-5223-leaf-tof1\\.p4"
    "p4c-5240\\.p4"
    "p4c-3417\\.p4"
)

set (P16_TNA_EXCLUDE_FILES "${P16_TNA_EXCLUDE_FILES}" 
                           "${P16_TNA_ARISTA_FILES}")

set (P16_TNA_FOR_TOFINO
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/*.p4"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/ptf/*.p4"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/stf/*.p4"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/customer/*/*.p4")
p4c_find_tests("${P16_TNA_FOR_TOFINO}" P4_16_TNA_TESTS INCLUDE "${P16_TNA_INCLUDE_PATTERNS}" EXCLUDE "${P16_TNA_EXCLUDE_PATTERNS}")
bfn_find_tests("${P4_16_TNA_TESTS}" p16_tna_tests EXCLUDE "${P16_TNA_EXCLUDE_FILES}")

set (TOFINO_TNA_TEST_SUITES
  ${p16_tna_tests}
  )

p4c_add_bf_backend_tests("tofino" "tofino" "tna" "base" "${TOFINO_TNA_TEST_SUITES}" "-I${CMAKE_CURRENT_SOURCE_DIR}/p4_16/includes")

p4c_add_bf_backend_tests("tofino" "tofino" "tna" "base" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/customer/extreme/p4c-2269.p4" "-I${CMAKE_CURRENT_SOURCE_DIR}/p4_16/includes -Xp4c=--disable-parse-depth-limit")

p4c_add_ptf_test_with_ptfdir (
    "tofino" "p4c_3343" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/customer/arista/p4c-3343.ptf/p4c_3343.p4"
    "${testExtraArgs} -target tofino -arch tna -bfrt"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/customer/arista/p4c-3343.ptf")
bfn_set_p4_build_flag("tofino" "p4c_3343" "-Xp4c=\"--disable-power-check\"")
set_tests_properties("tofino/p4c_3343" PROPERTIES TIMEOUT ${extended_timeout_4times})

p4c_add_ptf_test_with_ptfdir (
    "tofino" "p4c_4341" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/customer/arista/p4c-4341.ptf/p4c_4341.p4"
    "${testExtraArgs} -target tofino -arch tna -bfrt"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/customer/arista/p4c-4341.ptf")
bfn_set_p4_build_flag("tofino" "p4c_4341" "-Xp4c=\"--set-max-power=65.0\"")
set_tests_properties("tofino/p4c_4341" PROPERTIES TIMEOUT ${extended_timeout_2times})

# p4_16/internal/customer/ruijie/p4c-2992.p4
p4c_add_bf_backend_tests("tofino" "tofino" "tna" "base" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/customer/ruijie/p4c-2992.p4" "-Xp4c=--disable-power-check")
set_tests_properties("tofino/extensions/p4_tests/p4_16/internal/customer/ruijie/p4c-2992.p4" PROPERTIES TIMEOUT ${extended_timeout_2times})

# Kaloom leaf profile needs extra flags.
p4c_add_bf_backend_tests("tofino" "tofino" "tna" "base" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/customer/kaloom/p4c-5223-leaf-tof1.p4" "-Xp4c=\"--traffic-limit 94 --disable-power-check --disable-parse-depth-limit\"")

# Sino Telecom profile needs extra flags.
p4c_add_bf_backend_tests("tofino" "tofino" "tna" "base" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/customer/sino-telecom/p4c-5240.p4" "-Xp4c=\"--set-max-power 55.0 --disable-parse-depth-limit\"")

# Disable power check on these Arista profiles
# P4C-3039
set (P16_TNA_ARISTA_SET_MAX_POWER_FILES
  "obfuscated-nat_scale.p4"
  "obfuscated-nat_vxlan.p4"
  "obfuscated-media.p4"
  "obfuscated-routescale.p4"
)

# Add extra flags for nat and nat_static profiles
set (P16_TNA_ARISTA_EXCL_PASS_TF_CHK
  "obfuscated-nat.p4"
  "obfuscated-nat_static.p4"
)

cmake_policy(SET CMP0057 NEW)
# p4_16/internal/customer/arista/obfuscated-*.p4
set(DEFAULT_TIMEOUT_ARISTA ${extended_timeout_4times})
math(EXPR EXTENDED_TIMEOUT_ARISTA "${DEFAULT_TIMEOUT_ARISTA} + ${default_test_timeout}")
foreach (t IN LISTS P16_TNA_ARISTA_FILES)
  if (${t} IN_LIST P16_TNA_ARISTA_SET_MAX_POWER_FILES)
      set (POWER_CHECK_ARG "-Xp4c=\"--set-max-power 65.0\"")
  elseif (${t} IN_LIST P16_TNA_ARISTA_EXCL_PASS_TF_CHK)
      set (POWER_CHECK_ARG "-Xp4c=\"--set-max-power 68.0 --traffic-limit 95.0 --excludeBackendPasses=ResetInvalidatedChecksumHeaders\"")
  else()
      set (POWER_CHECK_ARG "-Xp4c=\"--disable-power-check\"")
  endif()
  p4c_add_bf_backend_tests("tofino" "tofino" "tna" "base" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/customer/arista/${t}" "${POWER_CHECK_ARG}")
  set_tests_properties("tofino/extensions/p4_tests/p4_16/internal/customer/arista/${t}" PROPERTIES TIMEOUT ${DEFAULT_TIMEOUT_ARISTA})
  p4c_add_test_label("tofino" "CUST_MUST_PASS" "extensions/p4_tests/p4_16/internal/customer/arista/${t}")
endforeach()
set_tests_properties("tofino/extensions/p4_tests/p4_16/internal/customer/arista/obfuscated-media.p4" PROPERTIES TIMEOUT ${EXTENDED_TIMEOUT_ARISTA})

# p4_16/internal/customer/extreme/p4c-1323-b.p4 needs a longer timeout.
p4c_add_bf_backend_tests("tofino" "tofino" "tna" "base" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/customer/extreme/p4c-1323-b.p4")
set_tests_properties("tofino/extensions/p4_tests/p4_16/internal/customer/extreme/p4c-1323-b.p4" PROPERTIES TIMEOUT ${extended_timeout_2times})

# p4_16/internal/customer/extreme/p4c-3920-b.p4
p4c_add_bf_backend_tests("tofino" "tofino" "tna" "base"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/customer/extreme/p4c-3920-b.p4"
    "-Xp4c=\"--p4runtime-force-std-externs\"")

# p4_16/internal/customer/kaloom/p4c-2398.p4
p4c_add_bf_backend_tests("tofino" "tofino" "tna" "base"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/customer/kaloom/p4c-2398.p4"
    "-Xp4c=\"--disable-power-check\"")

# p4_16/internal/customer/kaloom/p4c-2410-leaf.p4
p4c_add_bf_backend_tests("tofino" "tofino" "tna" "base"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/customer/kaloom/p4c-2410-leaf.p4"
    "-Xp4c=\"--disable-power-check\"")

# p4_16/internal/customer/kaloom/p4c-2573-leaf.p4
p4c_add_bf_backend_tests("tofino" "tofino" "tna" "base"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/customer/kaloom/p4c-2573-leaf.p4"
    "-Xp4c=\"--disable-power-check\"")

# p4_16/internal/customer/kaloom/p4c-2753.p4
p4c_add_bf_backend_tests("tofino" "tofino" "tna" "base"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/customer/kaloom/p4c-2753.p4"
    "-Xp4c=\"--disable-power-check\"")

# p4_16/internal/customer/kaloom/p4c-3139.p4
p4c_add_bf_backend_tests("tofino" "tofino" "tna" "base"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/customer/kaloom/p4c-3139.p4"
    "-stfbin -Xp4c=\"--disable-power-check\"")

# p4_16/internal/customer/keysight/p4c-2423.p4
p4c_add_bf_backend_tests("tofino" "tofino" "tna" "base"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/customer/keysight/p4c-2423.p4"
    "-Xp4c=\"--disable-power-check\"")

# p4_16/internal/customer/kaloom/p4c-3678-leaf.p4
p4c_add_bf_backend_tests("tofino" "tofino" "tna" "base"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/customer/kaloom/p4c-3678-leaf.p4"
    "-Xp4c=\"--disable-power-check\"")

# p4_16/internal/customer/onf/p4c-3582.p4
p4c_add_bf_backend_tests("tofino" "tofino" "tna" "base"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/customer/onf/p4c-3582.p4"
    "-Xp4c=\"--disable-parse-max-depth-limit\"")

# Add labels for tests to be run as MUST PASS in Jenkins
p4c_add_test_label("tofino" "CUST_MUST_PASS" "extensions/p4_tests/p4_16/internal/customer/extreme/p4c-1562-1.p4")
p4c_add_test_label("tofino" "CUST_MUST_PASS" "extensions/p4_tests/p4_16/internal/customer/extreme/p4c-1572-b1.p4")
p4c_add_test_label("tofino" "CUST_MUST_PASS" "extensions/p4_tests/p4_16/internal/customer/extreme/p4c-1809-1.p4")
p4c_add_test_label("tofino" "CUST_MUST_PASS" "extensions/p4_tests/p4_16/internal/customer/extreme/p4c-1812-1.p4")
p4c_add_test_label("tofino" "CUST_MUST_PASS" "extensions/p4_tests/p4_16/internal/customer/extreme/p4c-2313.p4")
p4c_add_test_label("tofino" "CUST_MUST_PASS" "extensions/p4_tests/p4_16/internal/customer/kaloom/p4c-1832.p4")
p4c_add_test_label("tofino" "CUST_MUST_PASS" "extensions/p4_tests/p4_16/internal/customer/kaloom/p4c-2398.p4")
p4c_add_test_label("tofino" "CUST_MUST_PASS" "extensions/p4_tests/p4_16/internal/customer/kaloom/p4c-2410-leaf.p4")
p4c_add_test_label("tofino" "CUST_MUST_PASS" "extensions/p4_tests/p4_16/internal/customer/kaloom/p4c-2410-spine.p4")
p4c_add_test_label("tofino" "CUST_MUST_PASS" "extensions/p4_tests/p4_16/internal/customer/kaloom/p4c-2573-leaf.p4")
p4c_add_test_label("tofino" "CUST_MUST_PASS" "extensions/p4_tests/p4_16/internal/customer/kaloom/p4c-3678-leaf.p4")
p4c_add_test_label("tofino" "CUST_MUST_PASS" "extensions/p4_tests/p4_16/internal/customer/keysight/keysight-tf1.p4")
p4c_add_test_label("tofino" "CUST_MUST_PASS" "extensions/p4_tests/p4_16/internal/customer/keysight/pktgen9_16.p4")

# need more compile time after we fix the slicing timeout issue because more
# possible slicing are tried and try allocation of them takes more time.
set_tests_properties("tofino/extensions/p4_tests/p4_16/internal/customer/extreme/p4c-1572-b1.p4" PROPERTIES TIMEOUT ${extended_timeout_2times})
set_tests_properties("tofino/extensions/p4_tests/p4_16/internal/customer/extreme/p4c-1812-1.p4" PROPERTIES TIMEOUT ${extended_timeout_2times})
set_tests_properties("tofino/extensions/p4_tests/p4_16/internal/customer/extreme/p4c-1809-1.p4" PROPERTIES TIMEOUT ${extended_timeout_2times})
set_tests_properties("tofino/extensions/p4_tests/p4_16/internal/customer/extreme/p4c-2313.p4" PROPERTIES TIMEOUT ${extended_timeout_2times})
set_tests_properties("tofino/extensions/p4_tests/p4_16/internal/customer/kaloom/p4c-1832.p4" PROPERTIES TIMEOUT ${extended_timeout_2times})

p4c_add_ptf_test_with_ptfdir (
    "tofino" "p4c-1970" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/bfrt/p4c-1970/p4c-1970.p4"
    "${testExtraArgs} -target tofino -arch tna -bfrt" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/bfrt/p4c-1970")
set_tests_properties("tofino/p4c-1970" PROPERTIES TIMEOUT ${extended_timeout_4times})

p4c_add_ptf_test_with_ptfdir (
    "tofino" "p4c_1585_a" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/bfrt/p4c_1585_a/p4c_1585_a.p4"
    "${testExtraArgs} -target tofino -arch tna -bfrt" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/bfrt/p4c_1585_a")

p4c_add_ptf_test_with_ptfdir (
    "tofino" "p4c_1585_b" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/bfrt/p4c_1585_b/p4c_1585_b.p4"
    "${testExtraArgs} -target tofino -arch tna -bfrt" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/bfrt/p4c_1585_b")

p4c_add_ptf_test_with_ptfdir (
    "tofino" "p4c_2249" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/bfrt/p4c_2249/p4c_2249.p4"
    "${testExtraArgs} -target tofino -arch tna -bfrt -Xp4c=\"--disable-parse-max-depth-limit\""
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/bfrt/p4c_2249")
set_tests_properties("tofino/p4c_2249" PROPERTIES TIMEOUT ${extended_timeout_4times})
bfn_needs_scapy("tofino" "p4c_2249")

p4c_add_ptf_test_with_ptfdir (
    "tofino" "p4c_3005" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/bfrt/p4c_3005/p4c3005.p4"
    "${testExtraArgs} -target tofino -arch tna -bfrt" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/bfrt/p4c_3005/p4c3005.ptf")

p4c_add_ptf_test_with_ptfdir (
    "tofino" "p4c_2611" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/bfrt/p4c_2611/p4c2611.p4"
    "${testExtraArgs} -target tofino -arch tna -bfrt" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/bfrt/p4c_2611/p4c2611.ptf")

p4c_add_ptf_test_with_ptfdir (
    "tofino" "p4c_2713" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/bfrt/p4c_2713/p4c2713.p4"
    "${testExtraArgs} -target tofino -arch tna -bfrt" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/bfrt/p4c_2713/p4c2713.ptf")

p4c_add_ptf_test_with_ptfdir (
    "tofino" "t2na_static_entry" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/bfrt/t2na_static_entry/t2na_static_entry.p4"
    "${testExtraArgs} -target tofino -arch tna -bfrt " "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/bfrt/t2na_static_entry")

p4c_add_ptf_test_with_ptfdir (
    "tofino" "parse_srv6_fast_ptf" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/bfrt/parse_srv6_fast_ptf/parse_srv6_fast_ptf.p4"
    "${testExtraArgs} -target tofino -arch tna -bfrt " "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/bfrt/parse_srv6_fast_ptf")
set_tests_properties("tofino/parse_srv6_fast_ptf" PROPERTIES TIMEOUT ${extended_timeout_4times})

p4c_add_ptf_test_with_ptfdir (
    "tofino" "p4c_2785_sizeinbits" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/bfrt/p4c_2785/p4c_2785_sizeinbits.p4"
    "${testExtraArgs} -target tofino -arch tna -bfrt" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/bfrt/p4c_2785/p4c_2785_sizeinbits.ptf")
p4c_add_ptf_test_with_ptfdir (
    "tofino" "p4c_2785_sizeinbytes" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/bfrt/p4c_2785/p4c_2785_sizeinbytes.p4"
    "${testExtraArgs} -target tofino -arch tna -bfrt" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/bfrt/p4c_2785/p4c_2785_sizeinbytes.ptf")

p4c_add_ptf_test_with_ptfdir (
    "tofino" "p4c-3876" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/bfrt/p4c-3876/p4c_3876.p4"
    "${testExtraArgs} -target tofino -arch tna -bfrt -Xp4c=--disable-parse-min-depth-limit" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/bfrt/p4c-3876")
bfn_needs_scapy("tofino" "p4c-3876")

p4c_add_ptf_test_with_ptfdir (
    "tofino" "p4c_4366" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/bfrt/p4c_4366/p4c_4366.p4"
    "${testExtraArgs} -target tofino -arch tna -bfrt -Xp4c=--disable-parse-min-depth-limit" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/bfrt/p4c_4366")

p4c_add_ptf_test_with_ptfdir (
    "tofino" "p4c_5043" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/bfrt/p4c_5043/p4c_5043.p4"
    "${testExtraArgs} -target tofino -arch tna -bfrt -Xp4c=\"--disable-parse-depth-limit --traffic-limit 75\"" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/bfrt/p4c_5043")

p4c_add_ptf_test_with_ptfdir (
    "tofino" "p4c_3926" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/ptf/p4c_3926.p4"
    "${testExtraArgs} -target tofino -arch tna -bfrt --p4runtime-force-std-externs"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/ptf/p4c_3926.ptf")

p4c_add_ptf_test_with_ptfdir(
    "tofino" "p4c-2602" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/ptf/p4c-2602.p4"
    "${testExtraArgs} -target tofino -arch tna -bfrt --p4runtime-force-std-externs"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/ptf/p4c-2602.ptf")

p4c_add_ptf_test_with_ptfdir (
    "tofino" "p4c_4158" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/bfrt/p4c_4158/p4c_4158.p4"
    "${testExtraArgs} -target tofino -arch tna -bfrt -Xp4c=\"--set-max-power 60\""
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/bfrt/p4c_4158")
set_tests_properties("tofino/p4c_4158" PROPERTIES TIMEOUT ${extended_timeout_4times})

p4c_add_ptf_test_with_ptfdir (
 "tofino" "p4c_2549" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/bfrt/p4c_2549/p4c_2549.p4"
 "${testExtraArgs} -target tofino -arch tna -bfrt"
 "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/bfrt/p4c_2549")
set_tests_properties("tofino/p4c_2549" PROPERTIES TIMEOUT ${extended_timeout_4times})
bfn_needs_scapy("tofino" "p4c_2549")

p4c_add_ptf_test_with_ptfdir (
    "tofino" "p4c_2601" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/ptf/p4c_2601.p4"
    "${testExtraArgs} -target tofino -arch tna -bfrt --p4runtime-force-std-externs"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/ptf/p4c_2601.ptf")
bfn_needs_scapy("tofino" "p4c_2601")

p4c_add_ptf_test_with_ptfdir (
    "tofino" "p4c-4878" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/bfrt/p4c-4878/p4c-4878.p4"
    "${testExtraArgs} -target tofino -arch tna -bfrt" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/bfrt/p4c-4878")
bfn_set_ptf_ports_json_file("tofino" "p4c-4878"
                            "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/bfrt/p4c-4878/ports.json")

# 600s is too little for forensics.p4
p4c_add_bf_backend_tests("tofino" "tofino" "tna" "base"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/forensics.p4")
set_tests_properties("tofino/extensions/p4_tests/p4_16/internal/forensics.p4" PROPERTIES TIMEOUT ${extended_timeout_150percent})

# 900s is too little for p4c-3417.p4
p4c_add_bf_backend_tests("tofino" "tofino" "tna" "base"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/p4c-3417.p4")
set_tests_properties("tofino/extensions/p4_tests/p4_16/internal/p4c-3417.p4" PROPERTIES TIMEOUT ${extended_timeout_150percent})


# P4C-2985
# We need to create two tests with different args for one p4 file.
# We utilize the fact that p4c_add_bf_backend_tests and p4c_add_test_with_args use the same name
# of the *.test file if there is more tests for one *.p4 file, so we create test with command line option
# --parser-inline-opt here, and let the other test be created as part of tests created from variable
# TOFINO_TNA_TEST_SUITES.
p4c_find_test_names("${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/stf/p4c-2985.p4" P4C_2985_TESTNAME)
bfn_add_test_with_args("tofino" "tofino" "parser-inline-opt/${P4C_2985_TESTNAME}" ${P4C_2985_TESTNAME} "" "--parser-inline-opt")
p4c_add_test_label("tofino" "base;stf" "parser-inline-opt/${P4C_2985_TESTNAME}")

# p4_16/internal/p4c-4064.p4
p4c_add_bf_backend_tests("tofino" "tofino" "tna" "base" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/p4c-4064.p4" "-Xp4c=--disable-power-check")

# p4_16/internal/p4c-5164.p4
p4c_add_bf_backend_tests("tofino" "tofino" "tna" "base" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/p4c-5164.p4" "-Xp4c=\"--disable-parse-depth-limit --disable-power-check\"")

# p4_16/internal/p4c-3241.p4
p4c_add_bf_backend_tests("tofino" "tofino" "tna" "base"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/p4c-3241.p4"
    "-to 1200 -Xp4c=\"--set-max-power 57.10\"")
set_tests_properties("tofino/extensions/p4_tests/p4_16/internal/p4c-3241.p4" PROPERTIES TIMEOUT 1200)

# p4_16/internal/p4c-3254.p4
p4c_add_bf_backend_tests("tofino" "tofino" "tna" "base"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/p4c-3254.p4"
    "-Xp4c=\"--set-max-power 55.0\"")
set_tests_properties("tofino/extensions/p4_tests/p4_16/internal/p4c-3254.p4" PROPERTIES TIMEOUT ${extended_timeout_4times})

#p4_16/internal/p4c-3255.p4
p4c_add_bf_backend_tests("tofino" "tofino" "tna" "base"
  "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/p4c-3255.p4"
  "-Xp4c=\"--no-dead-code-elimination\"")

#p4_16/internal/p4c-4770.p4
p4c_add_bf_backend_tests("tofino" "tofino" "tna" "base"
  "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/p4c-4770.p4"
  "-Xp4c=\"--disable-power-check --disable-parse-depth-limit\"")

# p4_16/internal/p4c-5109.p4 -- longer timeout needed for alt-phv
set_tests_properties("tofino/extensions/p4_tests/p4_16/internal/p4c-5109.p4" PROPERTIES TIMEOUT ${extended_timeout_2times})
set_tests_properties("tofino/extensions/p4_tests/p4_16/internal/p4c-2035-name.p4" PROPERTIES TIMEOUT ${extended_timeout_150percent})

# need more compile time after we fix the slicing timeout issue because more
# possible slicing are tried and try allocation of them takes more time.
set_tests_properties("tofino/extensions/p4_tests/p4_16/internal/stf/p4c-5288.p4" PROPERTIES TIMEOUT ${extended_timeout_2times})

p4c_add_ptf_test_with_ptfdir (
    "tofino" tor.p4 ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/google-tor/p4/spec/tor.p4
    "${testExtraArgs} -arch v1model" ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/tor.ptf)

set (ONOS_FABRIC_P4 ${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/p4_16_programs/bf-onos/pipelines/fabric/src/main/resources/fabric-tofino.p4)
set (ONOS_FABRIC_PTF ${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/p4_16_programs/onf_fabric/tests/onf)
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

bfn_needs_scapy("tofino" "fabric")
bfn_needs_scapy("tofino" "fabric-DWITH_SPGW")
bfn_needs_scapy("tofino" "fabric-DWITH_INT_TRANSIT")
bfn_needs_scapy("tofino" "fabric-DWITH_SPGW-DWITH_INT_TRANSIT")

set_tests_properties("tofino/fabric" PROPERTIES TIMEOUT ${extended_timeout_2times})
set_tests_properties("tofino/fabric-DWITH_SPGW" PROPERTIES TIMEOUT ${extended_timeout_2times})
set_tests_properties("tofino/fabric-DWITH_INT_TRANSIT" PROPERTIES TIMEOUT ${extended_timeout_2times})
set_tests_properties("tofino/fabric-DWITH_SPGW-DWITH_INT_TRANSIT" PROPERTIES TIMEOUT ${extended_timeout_2times})

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
set (BFN_TESTS "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/programs/*/*.p4")
bfn_find_tests ("${BFN_TESTS}" ALL_BFN_TESTS EXCLUDE "${BFN_EXCLUDE_PATTERNS}")
# make a list of all the tests that we want to run PTF on
set (P4F_PTF_TESTS)
foreach (t IN LISTS P4FACTORY_REGRESSION_TESTS)
  list (APPEND P4F_PTF_TESTS
    "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/programs/${t}/${t}.p4")
endforeach()
bfn_add_p4factory_tests("tofino" "tofino" "${TOFINO_P414_TEST_ARCH}" "smoketest_programs\;p414_nightly" P4F_PTF_TESTS)

set (P4FACTORY_PROGRAMS_PATH "extensions/p4_tests/internal/p4-programs/programs")
# Add extra build flags for PD gen

bfn_set_pd_build_flag("tofino" "${P4FACTORY_PROGRAMS_PATH}/perf_test_alpm/perf_test_alpm.p4"
  "--gen-perf-test-pd")

bfn_set_ptf_ports_json_file("tofino" "extensions/p4_tests/internal/p4-programs/programs/ha/ha.p4" "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/ptf-tests/ha/ports.json")
bfn_set_pd_build_flag("tofino" "extensions/p4_tests/internal/p4-programs/programs/ha/ha.p4" "--gen-hitless-ha-test-pd")

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

p4c_add_ptf_test_with_ptfdir("tofino" "smoketest_programs_alpm_test" "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/programs/alpm_test/alpm_test.p4"
  "${testExtraArgs} -pd -arch ${TOFINO_P414_TEST_ARCH}" "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/ptf-tests/alpm_test")
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
p4c_add_ptf_test_with_ptfdir("tofino" "smoketest_programs_alpm_test_2" "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/programs/alpm_test/alpm_test.p4"
  "${testExtraArgs} -pd -arch ${TOFINO_P414_TEST_ARCH}" "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/ptf-tests/alpm_test")
p4c_add_test_label("tofino" "p414_nightly" "smoketest_programs_alpm_test_2")
bfn_set_ptf_test_spec("tofino" "smoketest_programs_alpm_test_2"
   "test.TestIdleTime
   ^test.TestSnapshot
   test.TestStateRestore
   test.TestTcamMove")

p4c_add_ptf_test_with_ptfdir("tofino" "smoketest_programs_alpm_test_TestRealData" "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/programs/alpm_test/alpm_test.p4"
  "${testExtraArgs} -pd -arch ${TOFINO_P414_TEST_ARCH}" "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/ptf-tests/alpm_test")
p4c_add_test_label("tofino" "p414_nightly" "smoketest_programs_alpm_test_TestRealData")
bfn_set_ptf_test_spec("tofino" "smoketest_programs_alpm_test_TestRealData"
   "test.TestRealData")

set(_smoketestProgramsArgs "${testExtraArgs} -pd -arch ${TOFINO_P414_TEST_ARCH}")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_programs_basic_ipv4" "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/internal_p4_14/basic_ipv4/basic_ipv4.p4"
    "${_smoketestProgramsArgs}" "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/internal_p4_14/basic_ipv4")
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
bfn_set_ptf_ports_json_file("tofino" "smoketest_programs_basic_ipv4" "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/internal_p4_14/basic_ipv4/ports.json")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_programs_basic_ipv4_2" "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/internal_p4_14/basic_ipv4/basic_ipv4.p4"
    "${_smoketestProgramsArgs}" "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/internal_p4_14/basic_ipv4")
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
bfn_set_ptf_ports_json_file("tofino" "smoketest_programs_basic_ipv4_2" "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/internal_p4_14/basic_ipv4/ports.json")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_programs_basic_ipv4_3" "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/internal_p4_14/basic_ipv4/basic_ipv4.p4"
    "${_smoketestProgramsArgs}" "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/internal_p4_14/basic_ipv4")
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
bfn_set_ptf_ports_json_file("tofino" "smoketest_programs_basic_ipv4_3" "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/internal_p4_14/basic_ipv4/ports.json")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_programs_basic_ipv4_4" "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/internal_p4_14/basic_ipv4/basic_ipv4.p4"
    "${_smoketestProgramsArgs}" "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/internal_p4_14/basic_ipv4")
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
bfn_set_ptf_ports_json_file("tofino" "smoketest_programs_basic_ipv4_4" "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/internal_p4_14/basic_ipv4/ports.json")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_programs_basic_ipv4_5" "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/internal_p4_14/basic_ipv4/basic_ipv4.p4"
    "${_smoketestProgramsArgs}" "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/internal_p4_14/basic_ipv4")
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
bfn_set_ptf_ports_json_file("tofino" "smoketest_programs_basic_ipv4_5" "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/internal_p4_14/basic_ipv4/ports.json")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_programs_basic_ipv4_TestLearning" "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/internal_p4_14/basic_ipv4/basic_ipv4.p4"
    "${_smoketestProgramsArgs}" "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/internal_p4_14/basic_ipv4")
p4c_add_test_label("tofino" "p414_nightly" "smoketest_programs_basic_ipv4_TestLearning")
bfn_set_ptf_test_spec("tofino" "smoketest_programs_basic_ipv4_TestLearning"
         "test.TestLearning")
bfn_set_ptf_ports_json_file("tofino" "smoketest_programs_basic_ipv4_TestLearning" "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/internal_p4_14/basic_ipv4/ports.json")

p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_programs_dkm" "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/programs/dkm/dkm.p4"
    "${testExtraArgs} -pd -arch ${TOFINO_P414_TEST_ARCH}" "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/ptf-tests/dkm")
p4c_add_test_label("tofino" "p414_nightly" "smoketest_programs_dkm")

p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_programs_exm_direct" "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/internal_p4_14/exm_direct/exm_direct.p4"
    "${testExtraArgs} -pd -arch ${TOFINO_P414_TEST_ARCH}" "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/internal_p4_14/exm_direct")
p4c_add_test_label("tofino" "p414_nightly" "smoketest_programs_exm_direct")
bfn_set_pd_build_flag("tofino" "smoketest_programs_exm_direct"
    "--gen-exm-test-pd")
bfn_set_ptf_test_spec("tofino" "smoketest_programs_exm_direct"
        "^test.TestIdleTimeTCAM
        test.TestExm4way8Entries")

p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_programs_exm_direct_2" "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/internal_p4_14/exm_direct/exm_direct.p4"
    "${testExtraArgs} -pd -arch ${TOFINO_P414_TEST_ARCH}" "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/internal_p4_14/exm_direct")
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

p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_programs_exm_direct_1" "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/internal_p4_14/exm_direct_1/exm_direct_1.p4"
    "${testExtraArgs} -pd -arch ${TOFINO_P414_TEST_ARCH}" "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/internal_p4_14/exm_direct_1")
p4c_add_test_label("tofino" "p414_nightly" "smoketest_programs_exm_direct_1")
bfn_set_pd_build_flag("tofino" "smoketest_programs_exm_direct_1"
    "--gen-exm-test-pd")
bfn_set_ptf_test_spec("tofino" "smoketest_programs_exm_direct_1"
        "^test.TestExm5way8Entries
        ^test.TestExmdeep64k
        test.TestExm4way2Entries")

p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_programs_exm_direct_1_2" "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/internal_p4_14/exm_direct_1/exm_direct_1.p4"
    "${testExtraArgs} -pd -arch ${TOFINO_P414_TEST_ARCH}" "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/internal_p4_14/exm_direct_1")
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

p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_programs_exm_indirect_1" "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/internal_p4_14/exm_indirect_1/exm_indirect_1.p4"
    "${testExtraArgs} -pd -arch ${TOFINO_P414_TEST_ARCH}" "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/internal_p4_14/exm_indirect_1")
p4c_add_test_label("tofino" "p414_nightly" "smoketest_programs_exm_indirect_1")
bfn_set_pd_build_flag("tofino" "smoketest_programs_exm_indirect_1"
        "--gen-exm-test-pd")
bfn_set_ptf_test_spec("tofino" "smoketest_programs_exm_indirect_1"
        "test.TestActSelIterators
        test.TestDirectStats")

p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_programs_exm_indirect_1_2" "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/internal_p4_14/exm_indirect_1/exm_indirect_1.p4"
    "${testExtraArgs} -pd -arch ${TOFINO_P414_TEST_ARCH}" "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/internal_p4_14/exm_indirect_1")
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

p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_programs_exm_smoke_test" "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/internal_p4_14/exm_smoke_test/exm_smoke_test.p4"
    "${testExtraArgs} -pd -arch ${TOFINO_P414_TEST_ARCH}" "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/internal_p4_14/exm_smoke_test")
p4c_add_test_label("tofino" "p414_nightly" "smoketest_programs_exm_smoke_test")
bfn_set_pd_build_flag("tofino" "smoketest_programs_exm_smoke_test"
        "--gen-exm-test-pd")
bfn_set_ptf_test_spec("tofino" "smoketest_programs_exm_smoke_test"
        "^test.TestExmdeep64k
        test.TestExm4way2Entries")

p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_programs_exm_smoke_test_2" "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/internal_p4_14/exm_smoke_test/exm_smoke_test.p4"
    "${testExtraArgs} -pd -arch ${TOFINO_P414_TEST_ARCH}" "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/internal_p4_14/exm_smoke_test")
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

p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_programs_stful" "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/programs/stful/stful.p4"
    "${testExtraArgs} -pd -arch ${TOFINO_P414_TEST_ARCH}" "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/ptf-tests/stful")
p4c_add_test_label("tofino" "p414_nightly" "smoketest_programs_stful")
bfn_set_ptf_test_spec("tofino" "smoketest_programs_stful"
        "all
         ^test.TestStfulSelTbl
         ^test.TestStfulSelTbl2")

# 500s timeout is too little for compiling and testing the entire test, bumping it up
set_tests_properties("tofino/smoketest_programs_stful" PROPERTIES TIMEOUT ${extended_timeout_6times})

p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_programs_meters" "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/programs/meters/meters.p4"
    "${testExtraArgs} -pd -arch ${TOFINO_P414_TEST_ARCH}" "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/ptf-tests/meters")
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
bfn_set_ptf_ports_json_file("tofino" "smoketest_programs_meters" "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/ptf-tests/meters/ports.json")

# 500s timeout is too little for compiling and testing the entire test, bumping it up
set_tests_properties("tofino/smoketest_programs_meters" PROPERTIES TIMEOUT ${extended_timeout_6times})

p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_programs_hash_driven" "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/programs/hash_driven/hash_driven.p4"
    "${testExtraArgs} -pd -arch ${TOFINO_P414_TEST_ARCH}" "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/ptf-tests/hash_driven")

# 500s timeout is too little for compiling and testing the entire test, bumping it up
set_tests_properties("tofino/smoketest_programs_hash_driven" PROPERTIES TIMEOUT ${extended_timeout_6times})

# 500s timeout is too little for compiling and testing the entire test, bumping it up
set_tests_properties("tofino/smoketest_programs_basic_ipv4" PROPERTIES TIMEOUT ${extended_timeout_6times})
set_tests_properties("tofino/smoketest_programs_basic_ipv4_2" PROPERTIES TIMEOUT ${extended_timeout_6times})
set_tests_properties("tofino/smoketest_programs_basic_ipv4_3" PROPERTIES TIMEOUT ${extended_timeout_6times})
set_tests_properties("tofino/smoketest_programs_basic_ipv4_4" PROPERTIES TIMEOUT ${extended_timeout_6times})
set_tests_properties("tofino/smoketest_programs_basic_ipv4_5" PROPERTIES TIMEOUT ${extended_timeout_6times})
set_tests_properties("tofino/smoketest_programs_basic_ipv4_TestLearning" PROPERTIES TIMEOUT ${extended_timeout_6times})

p4c_add_ptf_test_with_ptfdir ("tofino" "miss_clause" ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/internal/pd/miss_clause.p4
    "${testExtraArgs} -pd" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/internal/pd/miss_clause.ptf")

p4c_add_ptf_test_with_ptfdir ("tofino" "brig_569"
    ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/internal/pd/BRIG-569/brig_569.p4
    "${testExtraArgs} -pd" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/internal/pd/BRIG-569/brig_569.ptf")
bfn_needs_scapy("tofino" "brig_569")

p4c_add_ptf_test_with_ptfdir ("tofino" "case6684" ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/internal/pd/BRIG-847/case6684.p4
    "${testExtraArgs} -pd" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/internal/pd/BRIG-847/case6684.ptf")

p4c_add_ptf_test_with_ptfdir ("tofino" "p4c-2229" ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/internal/pd/p4c-2229/p4src/simple_l3_lag_ecmp.p4
    "${testExtraArgs} -pd -DRESILIENT_SELECTION" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/internal/pd/p4c-2229/ptf")

p4c_add_ptf_test_with_ptfdir ("tofino" "simple_l3_checksum" ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/internal/pd/COMPILER-1008/simple_l3_checksum.p4
    "${testExtraArgs} -pd" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/internal/pd/COMPILER-1008/simple_l3_checksum.ptf")
bfn_needs_scapy("tofino" "simple_l3_checksum")

p4c_add_ptf_test_with_ptfdir ("tofino" "basic_switching" ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/internal/pd/COMPILER-980/basic_switching.p4
     "${testExtraArgs} -pd -Xp4c=\"--disable-parse-min-depth-limit\""
     "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/internal/pd/COMPILER-980/basic_switching.ptf")

p4c_add_ptf_test_with_ptfdir ("tofino" "case6738" ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/internal/pd/BRIG-879/case6738.p4
     "${testExtraArgs} -pd" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/internal/pd/BRIG-879/case6738.ptf")

p4c_add_ptf_test_with_ptfdir ("tofino" "simple_l3_mirror" ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/internal/pd/BRIG-879/simple_l3_mirror.p4
     "${testExtraArgs} -pd" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/internal/pd/BRIG-879/simple_l3_mirror.ptf")
bfn_needs_scapy("tofino" "simple_l3_mirror")

p4c_add_ptf_test_with_ptfdir ("tofino" "p4c_737" ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/internal/pd/p4c-737/oinked_0.p4
     "${testExtraArgs} -pd" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/internal/pd/p4c-737/oinked_0.ptf")

p4c_add_ptf_test_with_ptfdir ("tofino" "decaf_10" ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/internal/pd/decaf_10/decaf_10.p4
     "${testExtraArgs} -pd" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/internal/pd/decaf_10/decaf_10.ptf")

p4c_add_ptf_test_with_ptfdir ("tofino" "P4C-1021-1"
    ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/internal/pd/P4C-1021-1/P4C_1021_1.p4
    "${testExtraArgs} -pd" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/internal/pd/P4C-1021-1/P4C_1021_1.ptf")

p4c_add_ptf_test_with_ptfdir ("tofino" "P4C-1021-2"
    ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/internal/pd/P4C-1021-2/P4C_1021_2.p4
    "${testExtraArgs} -pd" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/internal/pd/P4C-1021-2/P4C_1021_2.ptf")

p4c_add_ptf_test_with_ptfdir ("tofino" "case5577" ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/internal/pd/COMPILER-897/case5577.p4
    "${testExtraArgs} -pd" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/internal/pd/COMPILER-897")

set (BA102_TESTS_FOR_TOFINO "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/ba-102/labs/*/solution/p4src/*.p4")
# l3_rewrite_920 and _930 are not actually tests but helper files for l3_rewrite
p4c_find_tests("${BA102_TESTS_FOR_TOFINO}" ba102_tests INCLUDE "tna.p4")
# message("BA-102 tests: ${ba102_tests}")
set(_ba102_common_opts "-bfrt -arch tna -Xp4c=\"--disable-parse-depth-limit\" -append-pythonpath ${CMAKE_CURRENT_SOURCE_DIR}/internal/p4examples/tools -Xptf=--test-params=student=False")
function(add_ba102_test t suffix extra_opts)
  get_filename_component(p4name ${t} NAME)
  string (REGEX REPLACE ".p4" "" testname ${p4name})
  string (REGEX REPLACE ".*labs/([^/]*)/.*" "\\1" test_group ${t})
  get_filename_component(__td ${t} DIRECTORY)
  set(_full_testname "ba102_${test_group}_${testname}${suffix}")

  # some labs have PTF as part of the assignment and therefore in the solution subdir but some have
  # it one level up, available for the students
  set (ptfdir "${__td}/../ptf-tests")
  if (NOT EXISTS ${ptfdir})
      set (ptfdir "${__td}/../../ptf-tests")
  endif()
  if (EXISTS ${ptfdir})
    p4c_add_ptf_test_with_ptfdir("tofino" ${_full_testname} ${t}
            "${testExtraArgs} ${_ba102_common_opts} ${extra_opts}" ${ptfdir})
  else()
    file(RELATIVE_PATH testfile ${P4C_SOURCE_DIR} ${t})
    bfn_add_test_with_args("tofino" "tofino" ${_full_testname} ${testfile} "${testExtraArgs}"
        "${_ba102_common_opts} ${extra_opts} -force-link")
  endif()
  p4c_add_test_label("tofino" "BA-102" ${_full_testname})
  bfn_needs_scapy("tofino" "${_full_testname}")
endfunction()
foreach(t IN LISTS ba102_tests)
  add_ba102_test(${t} "" "")
endforeach()
add_ba102_test("${CMAKE_CURRENT_SOURCE_DIR}/p4_16/ba-102/labs/13-simple_mpls_decap/solution/p4src/simple_mpls_decap.p4"
               "_p4c-2880" " -DFAST_MPLS_PARSER -DMPLS_STACK_LOOKAHEAD")
p4c_add_test_label("tofino" "UNSTABLE" "ba102_15-simple_lpf_simple_lpf")
p4c_add_test_label("tofino" "UNSTABLE" "ba102_16-simple_wred_simple_wred")

bfn_add_test_with_args ("tofino" "tofino" "tor-archive"
  extensions/p4_tests/p4_16/internal/google-tor/p4/spec/tor.p4 ""
  "-norun --arch v1model --create-graphs --archive --validate-manifest")
p4c_add_test_label("tofino" "cpplint" "tor-archive")

# tor.p4 and tor-archive share output directory
set_tests_properties(
  "tofino/tor-archive"
  PROPERTIES DEPENDS "tofino/tor.p4"
  )

set (P4FACTORY_INTERNAL_PROGRAMS_PATH "extensions/p4_tests/internal/p4-programs/internal_p4_14")

set (P4FACTORY_REGRESSION_TESTS_INTERNAL
  # action_spec_format.p4                     # PTF failure
  atomic_mod
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
set (BFN_TESTS_INTERNAL "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/internal_p4_14/*/*.p4")
bfn_find_tests ("${BFN_TESTS_INTERNAL}" ALL_BFN_TESTS_INTERNAL EXCLUDE "${BFN_EXCLUDE_PATTERNS}")
# make a list of all the tests that we want to run PTF on
set (P4F_PTF_TESTS_INTERNAL)
foreach (t IN LISTS P4FACTORY_REGRESSION_TESTS_INTERNAL)
  list (APPEND P4F_PTF_TESTS_INTERNAL
    "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/internal_p4_14/${t}/${t}.p4")
endforeach()
set (P4FACTORY_INTERNAL_PROGRAMS_PATH "extensions/p4_tests/internal/p4-programs/internal_p4_14")
bfn_add_p4factory_tests("tofino" "tofino" "${TOFINO_P414_TEST_ARCH}" "smoketest_programs_internal\;p414_nightly" P4F_PTF_TESTS_INTERNAL)
bfn_set_p4_build_flag("tofino" "${P4FACTORY_INTERNAL_PROGRAMS_PATH}/power/power.p4" "-Xp4c=\"--no-power-check\"")
bfn_set_pd_build_flag("tofino" "${P4FACTORY_INTERNAL_PROGRAMS_PATH}/ecc/ecc.p4" "--gen-md-pd --load-unavailable-resources ${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/internal_p4_14/ecc/resource_fail.rf")
p4c_add_test_label("tofino" "p414_nightly" "${P4FACTORY_INTERNAL_PROGRAMS_PATH}/ecc/ecc.p4")
p4c_add_test_label("tofino" "p414_nightly" "${P4FACTORY_INTERNAL_PROGRAMS_PATH}/mau_test/mau_test.p4")

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
  selector_resize
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
  bfrt_dev
  bfrt_perf
  bfrt_tm_queue
  cuckoo_rollback
  digest_test
  exm_large
  exm_no_hash
  fr_counter
  ha_multistage
  ipv4_checksum
  mirror
  misc1
  multithread_test
  selector
  snapshot_all_pipes
  snapshot_all_stages
  snapshot_all_stages_egress
  snapshot_phv
  tna_alpmV2
  tna_digest_custom
  tna_hash
  tna_ipv6_alpm
  tna_multi_prsr_programs_multi_pipes
  tna_pvs_multi_states
  tna_dkm_large_table
  )

## Internal P4-16 Programs - compile-only
set (P4FACTORY_P4_16_PROGRAMS_INTERNAL_COMPILE_ONLY
  fr_test
  # basic_lamb
  # basic_t5na
  bfrt_alpm_perf
  bfrt_tm
  bri_drivers_test
  color_aware_meter
  # common
  counter_meter_test
  custom_meter_colors
  digest_test_custom
  # forwarding_pipeline
  ha_1
  # hwlrn
  large_counter_meter
  lrn
  metersv2
  multithread_perf
  # p4program.am
  selector_dist
  tna_ambiguities
  tna_counter_extended
  tna_ipv4_alpm
  tna_stful
  # uni_dim_scale_shared
  )

# TODO: How to enable these tests?
# tna_with_pdfixed_thrift
# tna_ipv4_checksum
# tna_register_bfrt_integration

# No ptf, compile-only
file(RELATIVE_PATH p4_16_programs_path ${P4C_SOURCE_DIR} ${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/p4_16_programs)
bfn_add_test_with_args ("tofino" "tofino" "p4_16_programs_tna_32q_multiprogram_a"
    ${p4_16_programs_path}/tna_32q_multiprogram/program_a/tna_32q_multiprogram_a.p4
    "${testExtraArgs} -arch tna -I${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/p4_16_programs/tna_32q_multiprogram" "")
bfn_add_test_with_args ("tofino" "tofino" "p4_16_programs_tna_32q_multiprogram_b"
    ${p4_16_programs_path}/tna_32q_multiprogram/program_b/tna_32q_multiprogram_b.p4
    "${testExtraArgs} -arch tna -I${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/p4_16_programs/tna_32q_multiprogram" "")

# PTF Fails, Compile only
# tna_snapshot
bfn_add_test_with_args ("tofino" "tofino" "p4_16_programs_tna_snapshot"
    ${p4_16_programs_path}/tna_snapshot/tna_snapshot.p4
    "${testExtraArgs} -arch tna -I${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/p4_16_programs" "")

# P4-16 Programs with PTF tests
foreach(t IN LISTS P4FACTORY_P4_16_PROGRAMS)
  # FIXME: remove disabling of parser min/max depth limits (P4C-4170)
  if (${t} STREQUAL "tna_meter_lpf_wred")
    p4c_add_ptf_test_with_ptfdir ("tofino" "p4_16_programs_${t}" "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/p4_16_programs/${t}/${t}.p4"
      "${testExtraArgs} -target tofino -arch tna -bfrt -Xp4c=\"--disable-parse-depth-limit\" --p4runtime-force-std-externs" "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/p4_16_programs/${t}")
  else()
    p4c_add_ptf_test_with_ptfdir ("tofino" "p4_16_programs_${t}" "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/p4_16_programs/${t}/${t}.p4"
      "${testExtraArgs} -target tofino -arch tna -bfrt --p4runtime-force-std-externs" "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/p4_16_programs/${t}")
  endif()
  bfn_set_p4_build_flag("tofino" "p4_16_programs_${t}" "-I${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/p4_16_programs")
  set (ports_json ${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/p4_16_programs/${t}/ports.json)
  if (EXISTS ${ports_json})
    bfn_set_ptf_ports_json_file("tofino" "p4_16_programs_${t}" ${ports_json})
  endif()
endforeach()

# 500s timeout is too little for compiling and testing the entire switch, bumping it up
set_tests_properties("tofino/p4_16_programs_tna_exact_match" PROPERTIES TIMEOUT ${extended_timeout_2times})
set_tests_properties("tofino/p4_16_programs_tna_ternary_match" PROPERTIES TIMEOUT ${extended_timeout_4times})
set_tests_properties("tofino/p4_16_programs_tna_register" PROPERTIES TIMEOUT ${extended_timeout_2times})
set_tests_properties("tofino/p4_16_programs_selector_resize" PROPERTIES TIMEOUT ${extended_timeout_4times})

# Compile-only P4-16 Programs
foreach(t IN LISTS P4FACTORY_P4_16_PROGRAMS_COMPILE_ONLY)
  file(RELATIVE_PATH testfile ${P4C_SOURCE_DIR} "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/p4_16_programs/${t}/${t}.p4")
  bfn_add_test_with_args("tofino" "tofino" "p4_16_programs_${t}"
    "${testfile}" ""
    "${testExtraArgs} -arch tna -I${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/p4_16_programs")
endforeach()

# Internal P4-16 Programs with PTF tests
set(P4FACTORY_P4_16_PROGRAMS_INTERNAL_FLAGS "-I${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/internal_p4_16")
foreach(t IN LISTS P4FACTORY_P4_16_PROGRAMS_INTERNAL)
  p4c_add_ptf_test_with_ptfdir ("tofino" "p4_16_programs_internal_${t}"
      "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/internal_p4_16/${t}/${t}.p4"
    "${testExtraArgs} -target tofino -arch tna -bfrt"
    "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/internal_p4_16/${t}")
  bfn_set_p4_build_flag("tofino" "p4_16_programs_internal_${t}" "${P4FACTORY_P4_16_PROGRAMS_INTERNAL_FLAGS}")
  set (ports_json ${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/internal_p4_16/${t}/ports.json)
  if (EXISTS ${ports_json})
    bfn_set_ptf_ports_json_file("tofino" "p4_16_programs_internal_${t}" ${ports_json})
  endif()
endforeach()
bfn_set_p4_build_flag("tofino" "p4_16_programs_internal_misc1"
                      "${P4FACTORY_P4_16_PROGRAMS_INTERNAL_FLAGS} -Xp4c=--disable-power-check")
bfn_set_ptf_test_spec("tofino" "p4_16_programs_internal_bfrt_tm_queue"
  "^test.Test_P41__PortBuffer_ModEntry_Positive")
bfn_set_ptf_test_spec("tofino" "p4_16_programs_internal_misc1"
  "^test.TableMaskTest")
bfn_set_ptf_test_spec("tofino" "p4_16_programs_internal_multithread_test"
  "^test.MultiDiffClientId1WContinue1RTest")
bfn_set_ptf_test_spec("tofino" "p4_16_programs_internal_mirror"
  "^test.TestMirrorCoalescing ^test.TestMirrorCoExistWithCoalescing")

set_tests_properties("tofino/p4_16_programs_internal_misc1" PROPERTIES TIMEOUT ${extended_timeout_150percent})
set_tests_properties("tofino/p4_16_programs_internal_tna_pvs_multi_states" PROPERTIES TIMEOUT ${extended_timeout_150percent})
set_property(TEST "tofino/p4_16_programs_internal_multithread_test" APPEND PROPERTY ENVIRONMENT "RERUN_PTF_ON_FAILURE=1")

# Compile-only internal P4-16 Programs
foreach(t IN LISTS P4FACTORY_P4_16_PROGRAMS_INTERNAL_COMPILE_ONLY)
  file(RELATIVE_PATH testfile ${P4C_SOURCE_DIR} "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/internal_p4_16/${t}/${t}.p4")
  bfn_add_test_with_args("tofino" "tofino" "p4_16_programs_internal_${t}"
    "${testfile}" ""
    "${testExtraArgs} -arch tna -I${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/internal_p4_16")
endforeach()

# Disable failing tests
 bfn_set_ptf_test_spec("tofino" "p4_16_programs_tna_checksum"
     "all ^test.Ipv4UdpTranslateSpecialUpdTest")
 bfn_set_ptf_test_spec("tofino" "p4_16_programs_internal_tna_multi_prsr_programs_multi_pipes"
     "test.Phase0TableOpTest")
 bfn_set_ptf_test_spec("tofino" "p4_16_programs_internal_misc1"
     "all ^test.TestNonDflt ^test.IdleTimeoutNotifications")
 bfn_set_ptf_test_spec("tofino" "p4_16_programs_tna_pktgen"
     "all ^test.PortDownAppTF1 ^test.PortDownPktgenTest")

# Add extra flags for p4_16_programs
# Exclude the MirrorHA tests as they have hard coded install path (specific to p4factory)
bfn_set_ptf_test_spec("tofino" "p4_16_programs_tna_mirror"
        "all ^test.TestIngEgrMirrorHA ^test.TestNegativeMirrorHA")

set_tests_properties("tofino/p4_16_programs_internal_tna_alpmV2" PROPERTIES TIMEOUT ${extended_timeout_12times})

# Exclude some p4s with conditional checksum updates that are added separately
set (P4_14_EXCLUDE_FILES
                            "p4c-2250\\.p4"
                            "p4c-2661\\.p4"
                            "rdp/case9757\\.p4"           # not to be in p414_nightly
                            )

set (P4_14_CUSTOMER "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/internal/customer/*/*.p4")
bfn_find_tests("${P4_14_CUSTOMER}" p4_14_customer EXCLUDE "${P4_14_EXCLUDE_FILES}")

set (TOFINO_V1_TEST_SUITES
    ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/internal/*.p4
    ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/internal/stf/*.p4
    ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/internal/ptf/*.p4
    # customer
    ${p4_14_customer}
)

p4c_add_bf_backend_tests("tofino" "tofino" "${TOFINO_P414_TEST_ARCH}" "base\;p414_nightly" "${TOFINO_V1_TEST_SUITES}")

# not in p414_nightly, running in PR
p4c_add_bf_backend_tests("tofino" "tofino" "${TOFINO_P414_TEST_ARCH}" "base" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/internal/customer/rdp/case9757.p4")
p4c_add_bf_backend_tests("tofino" "tofino" "${TOFINO_P414_TEST_ARCH}" "base" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/internal/customer/ruijie/p4c-2250.p4")
set_tests_properties("tofino/extensions/p4_tests/p4_14/internal/customer/ruijie/p4c-2250.p4" PROPERTIES TIMEOUT ${extended_timeout_4times})

# Add labels for tests to be run as MUST PASS in Jenkins
p4c_add_test_label("tofino" "CUST_MUST_PASS" "extensions/p4_tests/p4_14/internal/customer/rdp/case9757.p4")
p4c_add_test_label("tofino" "CUST_MUST_PASS" "extensions/p4_tests/p4_14/internal/customer/ruijie/p4c-2250.p4")

p4c_add_test_label("tofino" "p414_nightly" "extensions/p4_tests/p4_14/internal/ptf/p4c_1962.p4")
p4c_add_test_label("tofino" "p414_nightly" "extensions/p4_tests/p4_14/internal/ptf/p4c2662.p4")

set (NON_PR
  # Extreme tests excluded from PR
  # Customer Tests to run in nightly
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/customer/kaloom/p4c-2218.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/customer/extreme/p4c-1308-a.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/customer/extreme/p4c-1308-b.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/customer/extreme/p4c-1308-c.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/customer/extreme/p4c-1308-d.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/customer/extreme/p4c-1323-a.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/customer/extreme/p4c-1323-c1.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/customer/extreme/p4c-1326.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/customer/extreme/p4c-1492.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/customer/extreme/p4c-1493.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/customer/extreme/p4c-1557.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/customer/extreme/p4c-1559.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/customer/extreme/p4c-1560.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/customer/extreme/p4c-1565-1.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/customer/extreme/p4c-1572-a.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/customer/extreme/p4c-1585-a.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/customer/extreme/p4c-1585-b1.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/customer/extreme/p4c-1586.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/customer/extreme/p4c-1587-a.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/customer/extreme/p4c-1587-b1.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/customer/extreme/p4c-1599.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/customer/extreme/p4c-1672-1.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/customer/extreme/p4c-1680-1.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/customer/extreme/p4c-1797-1.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/customer/extreme/p4c-1815-1.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/customer/extreme/p4c-1824-1.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/customer/extreme/p4c-1852.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/customer/extreme/p4c-1323-b.p4

  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/internal/test_config_101_switch_msdc.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/p4c-1757-neg.p4
)

foreach(t IN LISTS NON_PR)
  file(RELATIVE_PATH test_path ${P4C_SOURCE_DIR} ${t})
  p4c_add_test_label("tofino" "NON_PR_TOFINO" ${test_path})
endforeach()

set(P4TESTS_NON_PR
  # smoketests not run in PR
  smoketest_programs_alpm_test
  smoketest_programs_alpm_test_2
  smoketest_programs_alpm_test_TestRealData
  smoketest_programs_basic_ipv4_2
  smoketest_programs_basic_ipv4_3
  smoketest_programs_basic_ipv4_4
  smoketest_programs_basic_ipv4_5
  smoketest_programs_basic_ipv4_TestLearning
  smoketest_programs_dkm
  smoketest_programs_exm_direct
  smoketest_programs_exm_direct_2
  smoketest_programs_exm_direct_1
  smoketest_programs_exm_direct_1_2
  smoketest_programs_exm_indirect_1
  smoketest_programs_exm_indirect_1_2
  smoketest_programs_exm_smoke_test
  smoketest_programs_exm_smoke_test_2
  smoketest_programs_stful
  # Dev-env update 2022-10-21: runs for almost 3 hours, then fails
  p4_16_programs_internal_tna_alpmV2
  # Dev-env update 2023-02-13: this internal_p4_16 test is moved into p4_16_programs.
  p4_16_programs_selector_resize
)

foreach(t IN LISTS P4TESTS_NON_PR)
  p4c_add_test_label("tofino" "NON_PR_TOFINO" ${t})
endforeach()

include(internal/Switch.cmake)
include(internal/TofinoMustPass.cmake)
include(internal/TofinoXfail.cmake)
