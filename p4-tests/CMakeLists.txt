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

set (P4C_RUNTEST ${CMAKE_CURRENT_SOURCE_DIR}/runtest)

set (HARLYN_PTF_DRIVER ${CMAKE_CURRENT_SOURCE_DIR}/ptf_runner.py
  CACHE FILEPATH "Path to PTF Harlyn runner")
set (HARLYN_PTF_DRIVER_WRAPPER ${CMAKE_CURRENT_BINARY_DIR}/ptf_runner_wrapper
  CACHE FILEPATH "Path to PTF Harlyn runner wrapper")

configure_file ("src/ptf_runner_wrapper.c.in"
  "${P4C_BINARY_DIR}/ptf_runner_wrapper.c" @ONLY)


# common test utils
include(TestUtils.cmake)

#include(Switch.cmake)
if (ENABLE_TESTING)
  # add tofino tests and xfails with reasons
  include(TofinoTests.cmake)

  if (ENABLE_JBAY)
    # tofino2 variants -- to be enabled when support is added in the model and p4-build
    # include(Tofino2Tests.cmake)
    # add jbay tests and xfails with reasons
    include(JBayTests.cmake)
  endif()

  # We have additional test inputs that are used to test the other
  # (standard) back-ends These test input programs depend on Tofino in
  # some way.

  # Exercise v12 back-end on Tofino-specific programs
  include (P14Tests.cmake)

  # P4_16 tests
  include (P16Tests.cmake)

  # Exercise bmv2 back-end on Tofino-specific programs
  include (BMV2Tests.cmake)

  # Test code generation (check assembler output)
  include (CodeGenTests.cmake)

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
endif(ENABLE_TESTING)
