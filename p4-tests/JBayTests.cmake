set (jbay_timeout 500)

set (V1_SEARCH_PATTERNS "include.*(v1model|psa).p4" "main")
set (P4TESTDATA ${P4C_SOURCE_DIR}/testdata)
set (P4TESTS_FOR_JBAY "${P4TESTDATA}/p4_16_samples/*.p4")
p4c_find_tests("${P4TESTS_FOR_JBAY}" v1tests INCLUDE "${V1_SEARCH_PATTERNS}")

set (P16_INCLUDE_PATTERNS "include.*(v1model|psa|jbay).p4" "main")
set (P16_EXCLUDE_PATTERNS "tofino.h")
set (P16_FOR_TOFINO "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/*.p4")
p4c_find_tests("${P16_FOR_TOFINO}" p16tests INCLUDE "${P16_INCLUDE_PATTERNS}" EXCLUDE "${P16_EXCLUDE_PATTERNS}")

set (p16tests ${p16tests} ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/ipv4_checksum.p4)

# p4-tests has all the includes at the same level with the programs.
set (BFN_EXCLUDE_PATTERNS "tofino.p4")
set (BFN_TESTS "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4-tests/programs/*/*.p4")
bfn_find_tests ("${BFN_TESTS}" BFN_TESTS_LIST EXCLUDE "${BFN_EXCLUDE_PATTERNS}")

file (GLOB STF_TESTS "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/*.stf")
string (REGEX REPLACE "\\.stf;" ".p4;" STF_P4_TESTS "${STF_TESTS};")

file (GLOB PTF_TESTS "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/*.ptf")
string (REGEX REPLACE "\\.ptf;" ".p4;" PTF_P4_TESTS "${PTF_TESTS};")

set (JBAY_TEST_SUITES
  ${P4C_SOURCE_DIR}/testdata/p4_14_samples/*.p4
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
  ${p16tests}
  ${STF_P4_TESTS}
  ${PTF_P4_TESTS}
  )

p4c_add_bf_backend_tests("jbay" "${JBAY_TEST_SUITES}")

set (testExtraArgs "${testExtraArgs} -jbay")

p4c_add_ptf_test_with_ptfdir (
    "jbay" fabric.p4 ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/bf-onos/pipelines/fabric/src/main/resources/fabric.p4
    "${testExtraArgs}" ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/bf-onos-ptf/fabric.ptf)

p4c_add_ptf_test_with_ptfdir (
    "jbay" tor.p4 ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/google-tor/p4/spec/tor.p4
    "${testExtraArgs}" ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/tor.ptf)

include(JBayXfail.cmake)
