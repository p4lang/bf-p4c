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

include(TofinoXfail.cmake)

set (TOFINO_RUNTEST ${CMAKE_CURRENT_SOURCE_DIR}/runtest)

#   $(shell grep -l main $(shell grep -l -E '(v1model|psa)\.p4'
#	   $(srcdir)/testdata/p4_16_samples/*.p4))
set (TOFINO_TEST_SUITES
  ${P4C_SRC_DIR}/testdata/p4_14_samples/*.p4
  ${P4C_SRC_DIR}/testdata/p4_14_samples/switch_*/switch.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/*.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/google-tor/p4/spec/tor.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/*.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/c1/*/*.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/c2/*/*.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/c3/*/*.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/jenkins/*/*.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/switch_*/switch.p4
  )

p4c_add_tests("tofino" ${TOFINO_DRIVER} "${TOFINO_TEST_SUITES}" ${XFAIL_TESTS})

# We have additional test inputs that are used to test the other (standard) back-ends
# These test input programs depend on Tofino in some way.

# Exercise v12 back-end on Tofino-specific programs
set (P14_TEST_SUITES
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/*.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/c1/*/*.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/c2/*/*.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/c3/*/*.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/jenkins/*/*.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/switch_*/switch.p4
  )

set (V12_DRIVER ${CMAKE_CURRENT_SOURCE_DIR}/test-v12-sample.sh)
p4c_add_tests("p14_to_16" ${V12_DRIVER} "${P14_TEST_SUITES}" ${XFAIL_TESTS})

set (P16_TEST_SUITES
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/*.p4
  )
set (P4TEST_DRIVER ${P4C_SOURCE_DIR}/backends/p4test/run-p4-sample.py)
p4c_add_tests("p4" ${P4TEST_DRIVER} "${P16_TEST_SUITES}" ${XFAIL_TESTS})

# $(shell grep -L 'tofino/stateful_alu_blackbox'
#    $(shell grep -L 'tofino/stateful_alu' \
#	$(shell grep -l main $(shell grep -l -E '(v1model|psa)\.p4' \
# Exercise bmv2 back-end on Tofino-specific programs
set (BMV2_TEST_SUITES
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/*.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/switch_*/switch.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/*.p4
  )
set(BMV2_DRIVER ${P4C_SOURCE_DIR}/backends/bmv2/run-bmv2-test.py)
# p4c_add_tests("bmv2" ${BMV2_DRIVER} "${BMV2_TEST_SUITES}" ${XFAIL_TESTS})
