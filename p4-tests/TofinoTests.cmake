set (tofino_timeout ${default_test_timeout})

# check for PTF requirements
packet_test_setup_check("tofino")
# check for STF requirements
simple_test_setup_check("tofino")

include(TofinoErrors.cmake)

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
set (P16_V1MODEL_FOR_TOFINO
 "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/compile_only/*.p4"
 "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/stf/*.p4"
 "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/ptf/*.p4")
p4c_find_tests("${P16_V1MODEL_FOR_TOFINO}" p16_v1tests INCLUDE "${P16_V1_INCLUDE_PATTERNS}" EXCLUDE "${P16_V1_EXCLUDE_PATTERNS}")

set (P16_TNA_INCLUDE_PATTERNS "include.*(tofino|tna|tofino1_arch).p4" "main|common_tna_test")
set (P16_TNA_EXCLUDE_PATTERNS "tofino\\.h")

# digest_tna.p4 is used for another test (digest-std-p4runtime) with different args
set (P16_TNA_EXCLUDE_FILES
    "digest_tna\\.p4"
    "forensics\\.p4"
    "mirror_constants\\.p4"
    "hash_extern_xor\\.p4"
    "hash_field_expression\\.p4"
    "hash_field_expression_sym\\.p4"
)

set (P16_TNA_EXCLUDE_FILES "${P16_TNA_EXCLUDE_FILES}" 
                           "${DIAGNOSTIC_TESTS_TOFINO}")

set (P16_TNA_FOR_TOFINO
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/compile_only/*.p4"
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
set (P16_PSA_FOR_TOFINO
  "${P4TESTDATA}/p4_16_samples/*.p4"
  "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/compile_only/*.p4"
  "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/stf/*.p4")

if (CLOSED_SOURCE)
  set (P16_PSA_FOR_TOFINO_INTERNAL
  "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/customer/*/*.p4"
  "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/*.p4"
  "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/stf/*.p4"
  "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/fabric-psa/*.p4"
  )
endif (CLOSED_SOURCE)

set (P16_PSA_FOR_TOFINO
     "${P16_PSA_FOR_TOFINO}"
     "${P16_PSA_FOR_TOFINO_INTERNAL}"
)

p4c_find_tests("${P16_PSA_FOR_TOFINO}" P4_16_PSA_TESTS INCLUDE "${PSA_SEARCH_PATTERNS}" EXCLUDE "${PSA_EXCLUDE_PATTERNS}")
bfn_find_tests("${P4_16_PSA_TESTS}" p16_psa_tests EXCLUDE "${P16_PSA_EXCLUDE_FILES}")

# Exclude some p4s with conditional checksum updates that are added separately
set (P4_14_EXCLUDE_FILES
                            "parser_dc_full\\.p4"
                            "sai_p4\\.p4"
                            "checksum_pragma\\.p4"
                            "port_vlan_mapping\\.p4"
                            "checksum\\.p4"
                            "header-stack-ops-bmv2\\.p4"  # times out in PHV alloc
                            "08-FullTPHV3\\.p4"
                            "action_bus1\\.p4"            # max depth limit
                            "06-FullTPHV1\\.p4"           # max depth limit
                            "07-FullTPHV2\\.p4"           # max depth limit
                            "mau_test_neg_test\\.p4"      # disable power check
                            )

set (P4_14_SAMPLES "${P4TESTDATA}/p4_14_samples/*.p4")
bfn_find_tests("${P4_14_SAMPLES}" p4_14_samples EXCLUDE "${P4_14_EXCLUDE_FILES}")

set (P4_14_COMPILE_ONLY "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/compile_only/*.p4")
bfn_find_tests("${P4_14_COMPILE_ONLY}" p4_14_compile_only EXCLUDE "${P4_14_EXCLUDE_FILES}")

set (TOFINO_V1_TEST_SUITES
  ${p4_14_samples}
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/*.p4
  # p4_14_samples
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/bf_p4c_samples/*.p4
  # compile_only
  ${p4_14_compile_only}
  # p4smith regression tests
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/compile_only/p4smith_regression/*.p4
  # stf
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/stf/*.p4
  # ptf
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/ptf/*.p4
  )

p4c_add_bf_backend_tests("tofino" "tofino" "${TOFINO_P414_TEST_ARCH}" "base\;p414_nightly" "${TOFINO_V1_TEST_SUITES}")

# JIRA-DOC: P4C-2985
# We need to create one more test for each ${P4TESTDATA}/p4_16_samples/parser-inline/*.p4
# file with command line option --parser-inline-opt (which enables parser inlining optimization).
# As tests created by p4c_add_bf_backend_tests and p4c_add_test_with_args macros use the same *.test file
# regardless the name of the test if they have the same *.p4 file, we create first this test providing
# the extra test argument "--parser-inline-opt" and then let the *.test file be rewritten by
# p4c_add_bf_backend_tests macro when tests are creates from variable v1tests.
p4c_find_test_names("${P4TESTDATA}/p4_16_samples/parser-inline/*.p4" P4TESTS_PARSER_INLINE)
foreach (ts ${P4TESTS_PARSER_INLINE})
  bfn_add_test_with_args("tofino" "tofino" "parser-inline-opt/${ts}" ${ts} "" "--parser-inline-opt")
  p4c_add_test_label("tofino" "base" "parser-inline-opt/${ts}")
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
    bfn_add_test_with_args("tofino" "tofino" "testdata/p4_14_samples/${test}" "testdata/p4_14_samples/${test}" "" "-Xp4c=\"--disable-parse-max-depth-limit\"")
endforeach()
foreach (test ${P4TESTS_P4_16_FOR_TOFINO_NO_MIN_DEPTH})
    bfn_add_test_with_args("tofino" "tofino" "testdata/p4_16_samples/${test}" "testdata/p4_16_samples/${test}" "" "-Xp4c=\"--disable-parse-min-depth-limit\"")
endforeach()
foreach (test ${P4TESTS_P4_16_FOR_TOFINO_NO_MAX_DEPTH})
    bfn_add_test_with_args("tofino" "tofino" "testdata/p4_16_samples/${test}" "testdata/p4_16_samples/${test}" "" "-Xp4c=\"--disable-parse-max-depth-limit\"")
endforeach()
foreach (test ${P4TESTS_FOR_TOFINO_NO_DEPTH})
    bfn_add_test_with_args("tofino" "tofino" "testdata/p4_16_samples/${test}" "testdata/p4_16_samples/${test}" "" "-Xp4c=\"--disable-parse-depth-limit\"")
endforeach()

p4c_add_ptf_test_with_ptfdir(
    "tofino" "mirror_constants" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/ptf/mirror_constants.p4"
    "${testExtraArgs} -target tofino -arch tna -bfrt --p4runtime-force-std-externs"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/ptf/mirror_constants.ptf")
bfn_needs_scapy("tofino" "mirror_constants")

p4c_add_ptf_test_with_ptfdir(
    "tofino" "hash_extern_xor" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/ptf/hash_extern_xor.p4"
    "${testExtraArgs} -target tofino -arch tna -bfrt --p4runtime-force-std-externs"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/ptf/hash_extern_xor.ptf")
bfn_needs_scapy("tofino" "hash_extern_xor")

p4c_add_ptf_test_with_ptfdir(
    "tofino" "hash_field_expression" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/ptf/hash_field_expression.p4"
    "${testExtraArgs} -target tofino -arch tna -bfrt --p4runtime-force-std-externs"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/ptf/hash_field_expression.ptf")
bfn_needs_scapy("tofino" "hash_field_expression")

p4c_add_ptf_test_with_ptfdir(
    "tofino" "hash_field_expression_sym" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/ptf/hash_field_expression_sym.p4"
    "${testExtraArgs} -target tofino -arch tna -bfrt --p4runtime-force-std-externs"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/ptf/hash_field_expression_sym.ptf")
bfn_needs_scapy("tofino" "hash_field_expression_sym")

set (TOFINO_TNA_TEST_SUITES
  ${p16_tna_tests}
  )
p4c_add_bf_backend_tests("tofino" "tofino" "tna" "base" "${TOFINO_TNA_TEST_SUITES}" "-I${CMAKE_CURRENT_SOURCE_DIR}/p4_16/includes")
p4c_add_bf_diagnostic_tests("tofino" "tofino" "tna" "base" "${P16_TNA_INCLUDE_PATTERNS}" "${P16_TNA_EXCLUDE_PATTERNS}" "p4_16")
p4c_add_bf_diagnostic_tests("tofino" "tofino" "tna" "base" "" "${P16_TNA_INCLUDE_PATTERNS};${P16_TNA_EXCLUDE_PATTERNS}" "p4_14")
set_tests_properties("tofino/extensions/p4_tests/p4_16/ptf/options_invalid.p4" PROPERTIES TIMEOUT ${extended_timeout_2times})
bfn_needs_scapy("tofino" "extensions/p4_tests/p4_16/ptf/options_invalid.p4")
bfn_needs_scapy("tofino" "extensions/p4_tests/p4_16/ptf/inner_checksum.p4")

p4c_add_bf_backend_tests("tofino" "tofino" "${TOFINO_P414_TEST_ARCH}" "base\;p414_nightly" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/compile_only/mau_test_neg_test.p4" "-Xp4c=--disable-power-check")

set (TOFINO_PSA_TEST_SUITES
  ${p16_psa_tests}
  )
p4c_add_bf_backend_tests("tofino" "tofino" "psa" "base" "${TOFINO_PSA_TEST_SUITES}" "-I${CMAKE_CURRENT_SOURCE_DIR}/p4_16/includes -Xp4c=\"--disable-parse-min-depth-limit\"")

# need to increase timeout for test that fail PHV Allocation since it require a bit more time
# to go over all the possible strategy + optimization
p4c_add_bf_backend_tests("tofino" "tofino" "${TOFINO_P414_TEST_ARCH}" "base\;p414_nightly" "${P4TESTDATA}/p4_14_samples/08-FullTPHV3.p4")
set_tests_properties("tofino/testdata/p4_14_samples/08-FullTPHV3.p4" PROPERTIES TIMEOUT ${extended_timeout_2times})

# this tests conversion from Tofino-specific P4Info to "standard" P4Info
p4c_add_ptf_test_with_ptfdir (
    "tofino" digest-std-p4runtime ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/ptf/digest_tna.p4
    "${testExtraArgs} --p4runtime-force-std-externs -arch tna"
    ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/ptf/digest.ptf)

file(RELATIVE_PATH tofino32q-3pipe_path ${P4C_SOURCE_DIR} ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/tofino32q-3pipe/sfc.p4)
bfn_add_test_with_args ("tofino" "tofino" "tofino32q-3pipe"
    ${tofino32q-3pipe_path} "${testExtraArgs} -arch tna" "")

p4c_add_ptf_test_with_ptfdir ("tofino" "psa_recirculate" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/ptf/psa_recirculate.p4"
    "${testExtraArgs} -ptf -arch psa -Xp4c=\"--disable-parse-min-depth-limit\""
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/ptf/psa_recirculate.ptf")

p4c_add_ptf_test_with_ptfdir ("tofino" "psa_resubmit" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/ptf/psa_resubmit.p4"
    "${testExtraArgs} -ptf -arch psa -Xp4c=\"--disable-parse-min-depth-limit\""
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/ptf/psa_resubmit.ptf")

p4c_add_ptf_test_with_ptfdir ("tofino" "psa_clone_i2e" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/ptf/psa_clone_i2e.p4"
    "${testExtraArgs} -ptf -arch psa -Xp4c=\"--disable-parse-min-depth-limit\""
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/ptf/psa_clone_i2e.ptf")

p4c_add_ptf_test_with_ptfdir ("tofino" "psa_clone_e2e" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/ptf/psa_clone_e2e.p4"
    "${testExtraArgs} -ptf -arch psa -Xp4c=\"--disable-parse-min-depth-limit\""
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/ptf/psa_clone_e2e.ptf")

p4c_add_ptf_test_with_ptfdir ("tofino" "psa_checksum" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/ptf/psa_checksum.p4"
    "${testExtraArgs} -ptf -arch psa -Xp4c=\"--disable-parse-min-depth-limit\""
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/ptf/psa_checksum.ptf")

## Manifest tests
# test the generation of the compiler archive, for a must pass P4_14 and P4_16 program
# will run as part of cpplint
bfn_add_test_with_args ("tofino" "tofino" "easy-ternary-archive"
  extensions/p4_tests/p4_14/ptf/easy_ternary.p4 ""
  "-norun --arch ${TOFINO_P414_TEST_ARCH} --create-graphs --archive --validate-manifest")
p4c_add_test_label("tofino" "cpplint" "easy-ternary-archive")
p4c_add_test_label("tofino" "p414_nightly" "easy-ternary-archive")

set  (PHASE0_PRAGMA_P4 ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/compile_only/phase0_pragma.p4)
file (RELATIVE_PATH phase0test ${P4C_SOURCE_DIR} ${PHASE0_PRAGMA_P4})
bfn_add_test_with_args ("tofino" "tofino" "phase0_pragma_test"
    ${phase0test} "${testExtraArgs} -Tphase0:5 -arch ${TOFINO_P414_TEST_ARCH}" "")
p4c_add_test_label("tofino" "p414_nightly" "phase0_pragma_test")
p4c_add_tofino_success_reason(
  "No phase 0 table found; skipping phase 0 translation"
  phase0_pragma_test
  )

# JIRA-DOC: P4C-4718
set(TOFINO_DETERMINISM_TESTS_14
    ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/stf/decaf_3.p4
    ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/stf/decaf_8.p4
  )
foreach(t IN LISTS TOFINO_DETERMINISM_TESTS_14)
  bfn_add_determinism_test_with_args("tofino" "${P414_TEST_ARCH}" ${t} "--std=p4-14")
endforeach()

set(TOFINO_DETERMINISM_TESTS_16 )
foreach(t IN LISTS TOFINO_DETERMINISM_TESTS_16)
  bfn_add_determinism_test_with_args("tofino" "tna" ${t} "")
endforeach()

set (NON_PR
  # Long running tests that can be run in nightly
  ${P4TESTDATA}/p4_14_samples/03-FullPHV2.p4
  ${P4TESTDATA}/p4_14_samples/05-FullTPHV.p4
  ${P4TESTDATA}/p4_14_samples/06-FullTPHV1.p4
  ${P4TESTDATA}/p4_14_samples/07-FullTPHV2.p4
  
  # Other XFails in compilers repo to run in nightly
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/compile_only/04-FullPHV3.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/compile_only/conditional_constraints_infinite_loop.p4
  # Extreme tests excluded from PR
  # Customer Tests to run in nightly
)

include(TofinoMustPass.cmake)
include(TofinoXfail.cmake)
