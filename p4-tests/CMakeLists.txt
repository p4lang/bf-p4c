# Copyright 2013-present Barefoot Networks, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

MESSAGE("-- Adding BFN Compiler test suite")
OPTION(ENABLE_STF2PTF "Run STF tests as PTF" OFF)

if (NOT ENABLE_STF2PTF)
  # We run STF tests on the STF framework
  set(STF_SEARCH_PATHS
    ${CMAKE_INSTALL_PREFIX}/bin
    ${BFN_P4C_SOURCE_DIR}/../model/tests/simple_test_harness
    ${BFN_P4C_SOURCE_DIR}/../model/build/tests/simple_test_harness
    ${BFN_P4C_SOURCE_DIR}/../model/debug/tests/simple_test_harness)
  find_program(HARLYN_STF simple_test_harness
    PATHS ${STF_SEARCH_PATHS})
  if (HARLYN_STF)
    MESSAGE (STATUS "STF binary found.")
  else()
    MESSAGE (WARNING "STF tests need Harlyn simple_test_harness.\nLooked in ${STF_SEARCH_PATHS}.")
  endif()
endif()

set (PTF_REQUIREMENTS_MET TRUE)
# check for ptf
find_program(PTF ptf
  PATHS ${CMAKE_INSTALL_PREFIX}/bin)
if (NOT PTF)
  MESSAGE (WARNING "PTF tests need the ptf binary.")
  set (PTF_REQUIREMENTS_MET FALSE)
endif()
# check for bf_switchd
find_program(BF_SWITCHD bf_switchd
  PATHS ${CMAKE_INSTALL_PREFIX}/bin)
if (NOT BF_SWITCHD)
  MESSAGE (WARNING "PTF tests need the bf_switchd binary.")
  set (PTF_REQUIREMENTS_MET FALSE)
endif()
# check for tofino-model
find_program(HARLYN_MODEL tofino-model
  PATHS ${CMAKE_INSTALL_PREFIX}/bin)
if (NOT HARLYN_MODEL)
  MESSAGE (WARNING "PTF tests need the tofino-model binary.")
  set (PTF_REQUIREMENTS_MET FALSE)
endif()

if (PTF_REQUIREMENTS_MET)
  MESSAGE (STATUS "All PTF dependencies were found.")
else()
  MESSAGE (WARNING "PTF tests will not run as at least one requirement is not met.")
endif()

# if we have a reason for failure, then use that regular expression to
# make the test succeed. If that changes, we know the test moved to a
# different failure. Also turn off automatic ignoring of failures (WILL_FAIL).
macro(p4c_add_xfail_reason tag reason)
  set (__tests "${ARGN}")
  foreach (test IN LISTS __tests)
    p4c_test_set_name(__testname ${tag} ${test})
    if ( "${reason}" STREQUAL "")
      set_tests_properties(${__testname} PROPERTIES WILL_FAIL 1)
    else ()
      set_tests_properties(${__testname} PROPERTIES
        PASS_REGULAR_EXPRESSION ${reason}
        WILL_FAIL 0)
    endif()
    p4c_add_test_label(${tag} "XFAIL" ${test})
  endforeach()
endmacro(p4c_add_xfail_reason)

set (P4C_TOFINO_RUNTEST ${CMAKE_CURRENT_SOURCE_DIR}/runtest)

set (V1_SEARCH_PATTERNS "include.*(v1model|psa).p4" "main")
set (P4TESTDATA ${P4C_SOURCE_DIR}/testdata)
set (P4TESTS_FOR_TOFINO "${P4TESTDATA}/p4_16_samples/*.p4")
p4c_find_tests("${P4TESTS_FOR_TOFINO}" v1tests INCLUDE "${V1_SEARCH_PATTERNS}")

set (TOFINO_TEST_SUITES
  ${P4C_SOURCE_DIR}/testdata/p4_14_samples/*.p4
  ${P4TESTDATA}/p4_14_samples/switch_*/switch.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/*.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/google-tor/p4/spec/tor.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/*.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/c1/*/*.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/c2/*/*.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/c3/*/*.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/c4/*/*.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/c5/*/*.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/c6/*/*.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/c7/*/*.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/c8/*/*.p4
  # switch DC_BASIC_PROFILE
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/switch/p4src/switch.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/jenkins/*/*.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/switch_*/switch.p4
  ${v1tests}
  )

set (testExtraArgs)
# if STF is not found, disbale all stf tests
if (NOT HARLYN_STF)
  set (testExtraArgs ${testExtraArgs} -norun)
endif()
set (TOFINO_PTF_TESTS)
if (PTF_REQUIREMENTS_MET)
  set (testExtraArgs ${testExtraArgs} -ptf)
  if (ENABLE_STF2PTF)
    set (testExtraArgs ${testExtraArgs} -stf2ptf)
  endif()
endif()

set (HARLYN_PTF_DRIVER ${CMAKE_CURRENT_SOURCE_DIR}/ptf_runner.py
  CACHE FILEPATH "Path to PTF Harlyn runner")
set (HARLYN_PTF_DRIVER_WRAPPER ${CMAKE_CURRENT_BINARY_DIR}/ptf_runner_wrapper
  CACHE FILEPATH "Path to PTF Harlyn runner wrapper")

configure_file ("src/ptf_runner_wrapper.c.in"
  "${P4C_BINARY_DIR}/ptf_runner_wrapper.c" @ONLY)

p4c_add_tests ("tofino" ${P4C_TOFINO_RUNTEST} "${TOFINO_TEST_SUITES}"
  "${TOFINO_XFAIL_TESTS}" "${TOFINO_PTF_TESTS}" "${testExtraArgs}")

if (PTF_REQUIREMENTS_MET)
  # PTF tests cannot be run in parallel with other tests, so we set the SERIAL
  # property for them
  set (__ptfCounter 0)
  foreach (ts "${TOFINO_TEST_SUITES}")
    file (GLOB __testfiles RELATIVE ${P4C_SOURCE_DIR} ${ts})
    foreach (__p4file ${__testfiles})
      set(__havePTF 0)
      string (REGEX REPLACE ".p4$" ".ptf" __ptffile ${__p4file})
      if (EXISTS ${P4C_SOURCE_DIR}/${__ptffile})
        set(__havePTF 1)
      endif()
      string (REGEX REPLACE ".p4$" ".stf" __stffile ${__p4file})
      if (ENABLE_STF2PTF AND NOT ${__havePTF} AND EXISTS ${P4C_SOURCE_DIR}/${__stffile})
        # Also add as PTF test the STF
        # MESSAGE(STATUS "STF2PTF: Generating ${P4C_BINARY_DIR}/tofino/${__ptffile}/test.py")
        set(__havePTF 1)
      endif()
      if (${__havePTF})
        p4c_test_set_name(__testname "tofino" ${__p4file})
        set_tests_properties(${__testname} PROPERTIES RUN_SERIAL 1)
        p4c_add_test_label("tofino" "ptf" ${__p4file})
        # MESSAGE(STATUS "Added PTF test: ${__testname}")
        math (EXPR __ptfCounter "${__ptfCounter} + 1")
      endif()
    endforeach() # __p4file
  endforeach() # ts
  MESSAGE(STATUS "Added ${__ptfCounter} PTF tests")
endif() # PTF_REQUIREMENTS_MET

set  (SWITCH_P4 ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/switch/p4src/switch.p4)
set  (isXFail TRUE)
file (RELATIVE_PATH switchtest ${P4C_SOURCE_DIR} ${SWITCH_P4})
p4c_add_test_with_args ("tofino" ${P4C_TOFINO_RUNTEST} ${isXFail}
  "switch_acl_ip4v" ${switchtest} "${testExtraArgs} -DACL_IPV4_PROFILE")
p4c_add_test_with_args ("tofino" ${P4C_TOFINO_RUNTEST} ${isXFail}
  "switch_bfd_offload" ${switchtest} "${testExtraArgs} -DBFD_OFFLOAD_PROFILE")
p4c_add_test_with_args ("tofino" ${P4C_TOFINO_RUNTEST} ${isXFail}
  "switch_dc_maxsizes" ${switchtest} "${testExtraArgs} -DDC_MAXSIZES_PROFILE")
p4c_add_test_with_args ("tofino" ${P4C_TOFINO_RUNTEST} ${isXFail}
  "switch_egress_acl" ${switchtest} "${testExtraArgs} -DEGRESS_ACL_PROFILE")
p4c_add_test_with_args ("tofino" ${P4C_TOFINO_RUNTEST} ${isXFail}
  "switch_fabric" ${switchtest} "${testExtraArgs} -DFABRIC_PROFILE")
p4c_add_test_with_args ("tofino" ${P4C_TOFINO_RUNTEST} ${isXFail}
  "switch_fabric_maxsizes" ${switchtest} "${testExtraArgs} -DFABRIC_MAXSIZES_PROFILE")
p4c_add_test_with_args ("tofino" ${P4C_TOFINO_RUNTEST} ${isXFail}
  "switch_ila" ${switchtest} "${testExtraArgs} -DILA_PROFILE")
p4c_add_test_with_args ("tofino" ${P4C_TOFINO_RUNTEST} ${isXFail}
  "switch_ila_ipv6" ${switchtest} "${testExtraArgs} -DILA_IPV6_PROFILE")
p4c_add_test_with_args ("tofino" ${P4C_TOFINO_RUNTEST} ${isXFail}
  "switch_ent_fin_leaf" ${switchtest} "${testExtraArgs} -DENT_FIN_LEAF_PROFILE")
p4c_add_test_with_args ("tofino" ${P4C_TOFINO_RUNTEST} ${isXFail}
  "switch_ent_fin_spine" ${switchtest} "${testExtraArgs} -DENT_FIN_SPINE_PROFILE")
p4c_add_test_with_args ("tofino" ${P4C_TOFINO_RUNTEST} ${isXFail}
  "switch_ent_fin_postcard" ${switchtest} "${testExtraArgs} -DENT_FIN_POSTCARD_PROFILE")
p4c_add_test_with_args ("tofino" ${P4C_TOFINO_RUNTEST} ${isXFail}
  "switch_l2" ${switchtest} "${testExtraArgs} -DL2_PROFILE")
p4c_add_test_with_args ("tofino" ${P4C_TOFINO_RUNTEST} ${isXFail}
  "switch_l3_ipv4_fib_clpm" ${switchtest} "${testExtraArgs} -DL3_IPV4_FIB_CLPM_PROFILE")
p4c_add_test_with_args ("tofino" ${P4C_TOFINO_RUNTEST} ${isXFail}
  "switch_mpls_udp" ${switchtest} "${testExtraArgs} -DMPLS_UDP_PROFILE")
p4c_add_test_with_args ("tofino" ${P4C_TOFINO_RUNTEST} ${isXFail}
  "switch_nat" ${switchtest} "${testExtraArgs} -DNAT_PROFILE")
p4c_add_test_with_args ("tofino" ${P4C_TOFINO_RUNTEST} ${isXFail}
  "switch_qos" ${switchtest} "${testExtraArgs} -DQOS_PROFILE")
p4c_add_test_with_args ("tofino" ${P4C_TOFINO_RUNTEST} ${isXFail}
  "switch_sflow" ${switchtest} "${testExtraArgs} -DSFLOW_PROFILE")
p4c_add_test_with_args ("tofino" ${P4C_TOFINO_RUNTEST} ${isXFail}
  "switch_test_int_vxlan_ep" ${switchtest} "${testExtraArgs} -DTEST_INT_VXLAN_EP_PROFILE")
p4c_add_test_with_args ("tofino" ${P4C_TOFINO_RUNTEST} ${isXFail}
  "switch_test_int_vxlan_transit" ${switchtest} "${testExtraArgs} -DTEST_INT_VXLAN_TRANSIT_PROFILE")
p4c_add_test_with_args ("tofino" ${P4C_TOFINO_RUNTEST} ${isXFail}
  "switch_test_mirror_on_drop" ${switchtest} "${testExtraArgs} -DTEST_MIRROR_ON_DROP_PROFILE")

# add xfails with reasons
include(TofinoXfail.cmake)


# We have additional test inputs that are used to test the other
# (standard) back-ends These test input programs depend on Tofino in
# some way.

# Exercise v12 back-end on Tofino-specific programs
include (P14Xfail.cmake)
set (P14_TEST_SUITES
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/*.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/c1/*/*.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/c2/*/*.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/c3/*/*.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/c4/*/*.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/c5/*/*.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/c6/*/*.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/c7/*/*.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/c8/*/*.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/switch/p4src/switch.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/jenkins/*/*.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/switch_*/switch.p4
  )

set (V12_DRIVER ${CMAKE_CURRENT_SOURCE_DIR}/test-v12-sample.sh)
p4c_add_tests("p14_to_16" ${V12_DRIVER} "${P14_TEST_SUITES}" "${P14_XFAIL_TESTS}")

# P4_16 tests
include (P16Xfail.cmake)
set (P16_TEST_SUITES
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/*.p4
  )
set (P4TEST_DRIVER ${P4C_SOURCE_DIR}/backends/p4test/run-p4-sample.py)
p4c_add_tests("p4" ${P4TEST_DRIVER} "${P16_TEST_SUITES}" "${P4_XFAIL_TESTS}")

# Exercise bmv2 back-end on Tofino-specific programs
include (BMV2Xfail.cmake)
set (exclude_stateful "tofino/stateful_alu_blackbox" "tofino/stateful_alu")
set (BMV2_P4_14_DIRS
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/*.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/switch_*/switch.p4)

p4c_find_tests("${BMV2_P4_14_DIRS}" bmv2_p4_14_tests
  EXCLUDE "${exclude_stateful}")

p4c_find_tests("${CMAKE_CURRENT_SOURCE_DIR}/p4_16/*.p4" bmv2_p4_16_tests
  INCLUDE "${V1_SEARCH_PATTERNS}" EXCLUDE "${exclude_stateful}")
set (BMV2_TEST_SUITES
  ${bmv2_p4_14_tests}
  ${bmv2_p4_16_tests}
  )
set(BMV2_DRIVER ${CMAKE_CURRENT_SOURCE_DIR}/test-bmv2.sh)
p4c_add_tests("bmv2" ${BMV2_DRIVER} "${BMV2_TEST_SUITES}" "${BMV2_XFAIL_TESTS}")

# test STF lexing and parsing by running the stf2ptf_pd generator on
# all existing STF files in the tree
set (STF2PD_CMD "${CMAKE_CURRENT_SOURCE_DIR}/tools/stf/stf2ptf_pd")
file (GLOB_RECURSE __stftestfiles FOLLOW_SYMLINKS
  RELATIVE ${CMAKE_CURRENT_BINARY_DIR}
  "${BFN_P4C_SOURCE_DIR}/*.stf")
foreach (__t ${__stftestfiles})
  set (__testname "stf2pd_${__t}")
  add_test (NAME ${__testname} COMMAND ${STF2PD_CMD} ${__t}
    WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR})
  set_tests_properties (${__testname} PROPERTIES LABELS "TEST_STF2PTF_GEN")
  # and make sure we cleanup the generated files
  string (REGEX REPLACE ".stf$" "_ptf.py" __ptffile ${__testname})
  set_source_files_properties(${__ptffile} PROPERTIES GENERATED TRUE)
endforeach()

add_custom_target(check-stf2ptf-gen
  COMMAND ${CMAKE_CTEST_COMMAND} -L TEST_STF2PTF
  COMMENT "Running tests for STF2PTF generation"
  WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR})
