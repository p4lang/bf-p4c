set (tofino2_timeout 600)

# check for PTF requirements
packet_test_setup_check("jbay")

set (V1_SEARCH_PATTERNS "include.*(v1model|psa).p4" "main")
set (P4TESTDATA ${P4C_SOURCE_DIR}/testdata)
set (P4TESTS_FOR_JBAY "${P4TESTDATA}/p4_16_samples/*.p4")
p4c_find_tests("${P4TESTS_FOR_JBAY}" v1tests INCLUDE "${V1_SEARCH_PATTERNS}")

set (P16_V1_INCLUDE_PATTERNS "include.*v1model.p4" "main|common_v1_test")
set (P16_V1_EXCLUDE_PATTERNS "tofino.h")
set (P16_V1_FOR_JBAY "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/*.p4")
p4c_find_tests("${P16_V1_FOR_JBAY}" p16_v1tests INCLUDE "${P16_V1_INCLUDE_PATTERNS}" EXCLUDE "${P16_V1_EXCLUDE_PATTERNS}")

set (P16_JNA_INCLUDE_PATTERNS "include.*(t2na).p4" "main")
set (P16_JNA_EXCLUDE_PATTERNS "tofino.h")
set (P16_JNA_FOR_JBAY "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/*.p4")
p4c_find_tests("${P16_JNA_FOR_JBAY}" p16_jna_tests INCLUDE "${P16_JNA_INCLUDE_PATTERNS}" EXCLUDE "${P16_JNA_EXCLUDE_PATTERNS}")

file (GLOB STF_TESTS "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/*.stf")
string (REGEX REPLACE "\\.stf;" ".p4;" STF_P4_TESTS "${STF_TESTS};")

file (GLOB PTF_TESTS "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/*.ptf")
string (REGEX REPLACE "\\.ptf;" ".p4;" PTF_P4_TESTS "${PTF_TESTS};")

# Exclude some p4s with conditional checksum updates that are added separately
set (P4_14_EXCLUDE_FILES "parser_dc_full.p4" "sai_p4.p4"
                            "checksum_pragma.p4" "port_vlan_mapping.p4"
                            "checksum.p4")
set (P4_14_SAMPLES "${P4TESTDATA}/p4_14_samples/*.p4")
bfn_find_tests("${P4_14_SAMPLES}" p4_14_samples EXCLUDE "${P4_14_EXCLUDE_FILES}")

set (JBAY_V1_TEST_SUITES
  ${p4_14_samples}
#  ${P4TESTDATA}/p4_14_samples/switch_*/switch.p4
#  ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/*.p4
#  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/*.p4
#  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/c1/*/*.p4
#  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/c2/*/*.p4
#  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/c3/*/*.p4
#  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/c4/*/*.p4
#  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/c5/*/*.p4
#  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/c6/*/*.p4
#  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/c7/*/*.p4
#  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/c8/*/*.p4
  # switch DC_BASIC_PROFILE
#  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/switch/p4src/switch.p4
#  ${BFN_TESTS_LIST}
#  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/switch_*/switch.p4
#  ${v1tests}
  ${p16_v1tests}
  ${STF_P4_TESTS}
  ${PTF_P4_TESTS}
# p4_14_samples
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/bf_p4c_samples/*.p4
  )

p4c_add_bf_backend_tests("tofino2" "jbay" "v1model" "base" "${JBAY_V1_TEST_SUITES}")

set (JBAY_JNA_TEST_SUITES
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/jbay/*.p4
  ${p16_jna_tests}
  )
p4c_add_bf_backend_tests("tofino2" "jbay" "t2na" "base" "${JBAY_JNA_TEST_SUITES}")

set (testExtraArgs "${testExtraArgs} -tofino2")

p4c_add_ptf_test_with_ptfdir (
    "tofino2" fabric.p4 ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/bf-onos/pipelines/fabric/src/main/resources/fabric.p4
    "${testExtraArgs}" ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/bf-onos-ptf/fabric.ptf)

p4c_add_ptf_test_with_ptfdir (
    "tofino2" tor.p4 ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/google-tor/p4/spec/tor.p4
    "${testExtraArgs}" ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/tor.ptf)

# p4-tests has all the includes at the same level with the programs.
# For JBay we only add emulation
set (BFN_EXCLUDE_PATTERNS "tofino.p4")
set (BFN_TESTS "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4-tests/programs/emulation/*.p4")
bfn_find_tests ("${BFN_TESTS}" BFN_TESTS_LIST EXCLUDE "${BFN_EXCLUDE_PATTERNS}")
bfn_add_p4factory_tests("tofino2" "smoketest_programs" BFN_TESTS_LIST)

include(SwitchJBay.cmake)
include(JBayXfail.cmake)
