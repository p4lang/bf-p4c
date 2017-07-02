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

# set(BMV2_DRIVER ${CMAKE_CURRENT_SOURCE_DIR}/run-bmv2-test.py)

# set (BMV2_TEST_SUITES
#   "${P4C_SOURCE_DIR}/testdata/p4_16_samples/*-bmv2.p4"
#   "${P4C_SOURCE_DIR}/testdata/p4_16_bmv_errors/*-bmv2.p4"
#   "${P4C_SOURCE_DIR}/testdata/p4_14_samples/*.p4"
#   "${P4C_SOURCE_DIR}/testdata/p4_14_samples/switch_*/switch.p4"
#   )

# # This test defines two lpm keys for a table.
# # Even though the P4 spec allows it, it doesn't really make sense in a switch
# # so we allow it to fail on BMv2.
# set (XFAIL_TESTS
#   testdata/p4_14_samples/issue60.p4
#   )

# p4c_add_tests("bmv2" ${BMV2_DRIVER} "${BMV2_TEST_SUITES}" ${XFAIL_TESTS})
# # store the tags in a global list to enable check-* make rules
# set (TEST_TAGS ${TEST_TAGS} "bmv2" PARENT_SCOPE)
