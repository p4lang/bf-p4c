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

set(STF_SEARCH_PATHS ${CMAKE_INSTALL_PREFIX}/bin ${BFN_P4C_SOURCE_DIR}/../model/build/tests/simple_test_harness)
find_program(HARLYN_STF simple_test_harness
  PATHS ${STF_SEARCH_PATHS})
if (NOT HARLYN_STF)
  MESSAGE ("STF tests need Harlyn simple_test_harness.\nLooked in ${STF_SEARCH_PATHS}.")
endif()


include(TofinoXfail.cmake)

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
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/switch/*/*.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/jenkins/*/*.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/switch_*/switch.p4
  ${v1tests}
  )

p4c_add_tests("tofino" ${P4C_TOFINO_RUNTEST} "${TOFINO_TEST_SUITES}"
  "${TOFINO_XFAIL_TESTS}")

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
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/switch/*/*.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/jenkins/*/*.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/switch_*/switch.p4
  )

set (V12_DRIVER ${CMAKE_CURRENT_SOURCE_DIR}/test-v12-sample.sh)
p4c_add_tests("p14_to_16" ${V12_DRIVER} "${P14_TEST_SUITES}" "${P14_XFAIL_TESTS}")

# P4_16 tests
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
