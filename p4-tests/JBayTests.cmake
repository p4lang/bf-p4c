set (jbay_timeout 500)

set (V1_SEARCH_PATTERNS "include.*(v1model|psa).p4" "main")
set (P4TESTDATA ${P4C_SOURCE_DIR}/testdata)
set (P4TESTS_FOR_JBAY "${P4TESTDATA}/p4_16_samples/*.p4")
p4c_find_tests("${P4TESTS_FOR_JBAY}" v1tests INCLUDE "${V1_SEARCH_PATTERNS}")

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
#  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/jenkins/*/*.p4
#  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/switch_*/switch.p4
#  ${v1tests}
  )

p4c_add_bf_backend_tests("jbay" "${JBAY_TEST_SUITES}")

#p4c_add_ptf_test_with_ptfdir (
#    "jbay" tor.p4 ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/google-tor/p4/spec/tor.p4
#    "${testExtraArgs}" ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/tor.ptf)

include(JBayXfail.cmake)
