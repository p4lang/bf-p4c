# A default timeout for all kinds of tests in bf-p4c
set(default_test_timeout 900)
# A set of extended timeouts that should be used for larger tests
math(EXPR extended_timeout_150percent "(${default_test_timeout} * 15) / 10")
math(EXPR extended_timeout_2times "${default_test_timeout} * 2")
math(EXPR extended_timeout_3times "${default_test_timeout} * 3")
math(EXPR extended_timeout_4times "${default_test_timeout} * 4")
math(EXPR extended_timeout_5times "${default_test_timeout} * 5")
math(EXPR extended_timeout_6times "${default_test_timeout} * 6")
math(EXPR extended_timeout_8times "${default_test_timeout} * 8")
math(EXPR extended_timeout_12times "${default_test_timeout} * 12")

# if we have a reason for failure, then use that regular expression to
# make the test succeed. If that changes, we know the test moved to a
# different failure. Also turn off automatic ignoring of failures (WILL_FAIL).
macro(p4c_add_xfail_reason tag reason)
  set (__tests "${ARGN}")
  string (TOUPPER ${tag} __upperTag)
  foreach (test IN LISTS __tests)
    list (FIND ${__upperTag}_MUST_PASS_TESTS ${test} __isMustPass)
    # not a mandatory pass test
    # FIXME: even mandatory tests can be switched off for ALT-PHV for now
    if (${__isMustPass} EQUAL -1 OR TEST_ALT_PHV_ALLOC)
      p4c_test_set_name(__testname ${tag} ${test})

      # Verify that we haven't already set WILL_FAIL or PASS_REGULAR_EXPRESSION properties
      get_property(__propWillFail TEST ${__testname} PROPERTY WILL_FAIL)
      get_property(__propPassRegex TEST ${__testname} PROPERTY PASS_REGULAR_EXPRESSION)
      if ( NOT ("${__propWillFail}" STREQUAL "") OR NOT ("${__propWillFail}" STREQUAL ""))
        message(SEND_ERROR "Invalid call to p4c_add_xfail_reason for ${__testname}: "
          "WILL_FAIL or PASS_REGULAR_EXPRESSION properties already set")
      endif()

      if ( "${reason}" STREQUAL "")
        set_tests_properties(${__testname} PROPERTIES WILL_FAIL 1)
      else ()
        set_tests_properties(${__testname} PROPERTIES
          PASS_REGULAR_EXPRESSION "${reason}"
          WILL_FAIL 0)
      endif()
      p4c_add_test_label(${tag} "XFAIL" ${test})
    else()
      message(WARNING "${test} can not be listed as an xfail. It must always pass!")
    endif()
  endforeach()
endmacro(p4c_add_xfail_reason)

# tests will succeed when it finds the "reason" regex
macro(p4c_add_tofino_success_reason reason __tests)
  foreach (t ${__tests})
    set (__testname "tofino/${t}")
    set_tests_properties (${__testname} PROPERTIES
      PASS_REGULAR_EXPRESSION "${reason}"
      WILL_FAIL 0)
  endforeach()
endmacro(p4c_add_tofino_success_reason)

# tests will succeed when it finds the "reason" regex
macro(p4c_add_codegen_success_reason reason __tests)
  foreach (t ${__tests})
    set (__testname "codegen/${t}")
    set_tests_properties (${__testname} PROPERTIES
      PASS_REGULAR_EXPRESSION "${reason}"
      WILL_FAIL 0)
  endforeach()
endmacro(p4c_add_codegen_success_reason)

# tests will fail when it finds the "reason" regex
macro(p4c_add_codegen_fail_reason reason __tests)
  foreach (t ${__tests})
    set (__testname "codegen/${t}")
    set_tests_properties (${__testname} PROPERTIES
      FAIL_REGULAR_EXPRESSION "${reason}"
      WILL_FAIL 0)
    p4c_add_test_label("codegen" "XFAIL" ${t})
  endforeach()
endmacro(p4c_add_codegen_fail_reason)

# find all the tests, except the ones matching the names in patterns
function(bfn_find_tests input_files test_list exclude patterns)
  set (inputList "")
  foreach (__t ${input_files})
    file (GLOB __inputTest ${__t})
    list (APPEND inputList ${__inputTest})
  endforeach()
  list (REMOVE_DUPLICATES inputList)

  # remove the tests that match one of the regexes in BFN_EXCLUDE_PATTERNS
  foreach (f IN LISTS inputList)
    foreach (pattern IN LISTS patterns)
      if(NOT "${pattern}" STREQUAL "")
        string (REGEX MATCH ${pattern} __found ${f})
        if (NOT ${__found})
          list (REMOVE_ITEM inputList ${f})
          break()
        endif()
      endif()
    endforeach()
  endforeach()
  set(${test_list} ${inputList} PARENT_SCOPE)
endfunction()

function(bfn_add_p4factory_tests tag device arch label test_list)
  set(ptf_extra_args "${ARGN}")
  # and they have the ptf tests in a separate directory
  foreach(__t IN LISTS ${test_list})
    file (RELATIVE_PATH p4test ${P4C_SOURCE_DIR} ${__t})
    string (REPLACE "p4-programs/programs" "p4-programs/ptf-tests" ptfpath ${__t})
    get_filename_component (ptfdir ${ptfpath} DIRECTORY)
    p4c_add_ptf_test_with_ptfdir (${tag} ${p4test} ${__t} "${testExtraArgs} -pd -${device} -arch ${arch} ${ptf_extra_args}" ${ptfdir})
    set_property(TEST "${tag}/${p4test}" PROPERTY ENVIRONMENT "")
    set_tests_properties("${tag}/${p4test}" PROPERTIES TIMEOUT ${extended_timeout_150percent})
    p4c_add_test_label(${tag} ${label} ${p4test})
  endforeach()
endfunction()

# add additional arguments to building the pd test, after the call to add_test
function(bfn_set_pd_build_flag tag p4test pd_build_flag)
  set_property(TEST "${tag}/${p4test}"
    APPEND PROPERTY ENVIRONMENT "PDFLAGS=${pd_build_flag}")
endfunction()

# add additional arguments to building the pd test, after the call to add_test
function(bfn_set_p4_build_flag tag p4test p4_build_flag)
  set_property(TEST "${tag}/${p4test}"
    APPEND PROPERTY ENVIRONMENT "P4FLAGS=${p4_build_flag}")
endfunction()

# add additional arguments to a test, after the call to add_test
# We currently use this for specifying a set of tests, either by tag,
# a sequence of tags, or a sequence of tests
function(bfn_set_ptf_test_spec tag p4test ptf_test_spec)
  set_property(TEST "${tag}/${p4test}"
    APPEND PROPERTY ENVIRONMENT "PTF_TEST_SPECS=${ptf_test_spec}")
endfunction()

function(bfn_set_ptf_port_map_file tag p4test port_map_file)
  set_property(TEST "${tag}/${p4test}"
    APPEND PROPERTY ENVIRONMENT "PORT_MAP_FILE=${port_map_file}")
endfunction()

function(bfn_set_ptf_ports_json_file tag p4test ports_json_file)
  set_property(TEST "${tag}/${p4test}"
    APPEND PROPERTY ENVIRONMENT "PORTS_JSON_FILE=${ports_json_file}")
endfunction()

function(bfn_set_ptf_test_port tag p4test test_port)
  set_property(TEST "${tag}/${p4test}"
    APPEND PROPERTY ENVIRONMENT "TEST_PORT=${test_port}")
endfunction()

# run the test with scapy instead of bf_pktpy
function(bfn_needs_scapy tag p4test)
  set_property(TEST "${tag}/${p4test}" APPEND PROPERTY ENVIRONMENT "PKTPY=false")
endfunction()

# call this macro to register a PTF test with a custom PTF test directory; by
# default the behavior is to look for a directory with the same name as the P4
# program and a .ptf extension, which may not always be convenient when adding
# tests for third-party P4 programs.
# if you need to mark this test as XFAIL, please edit TofinoXfail.cmake with the
# appropriate call to p4c_add_xfail_reason.
macro(p4c_add_ptf_test_with_ptfdir device alias ts args ptfdir)
  file (RELATIVE_PATH p4test ${P4C_SOURCE_DIR} ${ts})
  p4c_test_set_name(__testname ${device} ${alias})
  if (PTF_REQUIREMENTS_MET)
    p4c_add_test_with_args (${device} ${P4C_RUNTEST} FALSE ${alias}
      ${p4test} "" "${args} -${device} -ptf -ptfdir ${ptfdir}")
    set_ptf_test_locks(${__testname})
    p4c_add_test_label(${device} "ptf" ${alias})
  else()
    p4c_add_test_with_args (${device} ${P4C_RUNTEST} FALSE ${alias}
      ${p4test} "" "${args} -${device}")
  endif()
endmacro(p4c_add_ptf_test_with_ptfdir)

# same as p4c_add_ptf_test_with_ptfdir but takes an extra parameter,
# ptf_test_spec, which can be used to specify the set of tests that will be run
# by ptf.
macro(p4c_add_ptf_test_with_ptfdir_and_spec device alias ts args ptfdir ptf_test_spec)
  p4c_add_ptf_test_with_ptfdir(${device} ${alias} ${ts} ${args} ${ptfdir})
  bfn_set_ptf_test_spec(${device} ${alias} ${ptf_test_spec})
endmacro(p4c_add_ptf_test_with_ptfdir_and_spec)

macro(simple_test_setup_check device)
  if (NOT ENABLE_STF2PTF)
    # We run STF tests on the STF framework
    set(STF_SEARCH_PATHS
      ${P4FACTORY_INSTALL_DIR}/bin
      ${CMAKE_INSTALL_PREFIX}/bin)

    find_program(HARLYN_STF_${device} ${device}_test_harness PATHS ${STF_SEARCH_PATHS})

    if (HARLYN_STF_${device})
      MESSAGE (STATUS "${device}_test_harness for ${device} found at ${HARLYN_STF_${device}}.")
    else()
      MESSAGE (WARNING "STF tests need Harlyn ${device}_test_harness for ${device}.\nLooked in ${STF_SEARCH_PATHS}.")
    endif()

  endif()
endmacro(simple_test_setup_check)

macro(packet_test_setup_check device)
  # check for ptf
  find_program(PTF ptf PATHS ${P4FACTORY_INSTALL_DIR}/bin ${CMAKE_INSTALL_PREFIX}/bin)

  set(BF_SWITCHD_SEARCH_PATHS
    ${P4FACTORY_INSTALL_DIR}/bin
    ${CMAKE_INSTALL_PREFIX}/bin)

  # check for bf_switchd
  find_program(BF_SWITCHD bf_switchd PATHS ${BF_SWITCHD_SEARCH_PATHS} NO_DEFAULT_PATH)

  if (BF_SWITCHD)
    MESSAGE (STATUS "bf-switchd for ${device} found at ${BF_SWITCHD}.")
  else()
    MESSAGE (WARNING "PTF tests need bf-switchd for ${device}.\nLooked in ${BF_SWITCHD_SEARCH_PATHS}.")
  endif()

  # check for tofino-model
  set(HARLYN_MODEL_SEARCH_PATHS
    ${P4FACTORY_INSTALL_DIR}/bin
    ${CMAKE_INSTALL_PREFIX}/bin)

  find_program(HARLYN_MODEL tofino-model PATHS ${HARLYN_MODEL_SEARCH_PATHS} NO_DEFAULT_PATH)

  if (HARLYN_MODEL)
    MESSAGE (STATUS "tofino-model for ${device} found at ${HARLYN_MODEL}.")
  else()
    MESSAGE (WARNING "PTF tests need tofino-model for ${device}.\nLooked in ${HARLYN_MODEL_SEARCH_PATHS}.")
  endif()

  if (PTF AND BF_SWITCHD AND HARLYN_MODEL)
    set (PTF_REQUIREMENTS_MET TRUE)
    MESSAGE (STATUS "All PTF dependencies were found.")
  else()
    set (PTF_REQUIREMENTS_MET FALSE)
    set (__err_str "PTF tests need")
    if (NOT PTF)
      set (__err_str "${__err_str} the ptf binary")
    endif()
    if (NOT BF_SWITCHD)
      set (__err_str "${__err_str} and the bf_switchd binary")
    endif()
    if (NOT HARLYN_MODEL)
      set (__err_str "${__err_str} and the tofino-model binary")
    endif()
    MESSAGE (WARNING "${__err_str}")
  endif()
endmacro(packet_test_setup_check)

function(set_ptf_test_locks testname)
  if (NOT ENABLE_TEST_ISOLATION)
    set_tests_properties(${testname} PROPERTIES RESOURCE_LOCK ptf_test_environment)
  elseif(${testname} MATCHES "p4_14")
    message("Enabling lock for legacy test ${testname}")
    # -pd tests potentially share build directory
    set_tests_properties(${testname} PROPERTIES RESOURCE_LOCK ptf_legacy_test_environment)
  endif()
endfunction()

# extra test args can be passed as unamed arguments
function(bfn_add_test_with_args device toolsdevice alias p4file test_args cmake_args)
  # create the test
  p4c_add_test_with_args (${device} ${P4C_RUNTEST} FALSE ${alias}
      ${p4file} "${test_args}" "-${device} ${cmake_args}")
  if (PTF_REQUIREMENTS_MET)
    set(__havePTF 0)
    # the ptf dir is expected to be in source.ptf directory in the same directory as source.p4
    # use p4c_add_ptf_test_with_ptfdir macro to add ptf test with custom ptf directory
    string (REGEX REPLACE ".p4$" ".ptf" __ptffile ${p4file})
    if (EXISTS ${P4C_SOURCE_DIR}/${__ptffile})
      set(__havePTF 1)
    endif()
    string (REGEX REPLACE ".p4$" ".stf" __stffile ${p4file})
    if (ENABLE_STF2PTF AND NOT ${__havePTF} AND EXISTS ${P4C_SOURCE_DIR}/${__stffile})
      # Also add as PTF test the STF
      # MESSAGE(STATUS "STF2PTF: Generating ${P4C_BINARY_DIR}/${device}/${__ptffile}/test.py")
      set(__havePTF 1)
    endif()
    if (${__havePTF})
      p4c_test_set_name(__testname ${device} ${alias})
      set_ptf_test_locks(${__testname})
      p4c_add_test_label(${device} "ptf" ${alias})
    endif()
  endif() # PTF_REQUIREMENTS_MET
  if (HARLYN_STF_${toolsdevice})
    string (REGEX REPLACE ".p4$" ".stf" __stffile ${p4file})
    if (EXISTS ${P4C_SOURCE_DIR}/${__stffile})
      p4c_add_test_label(${device} "stf" ${alias})
    endif()
  endif(HARLYN_STF_${toolsdevice})
endfunction(bfn_add_test_with_args)

# Test that the compilation is deterministic by comparing PHV and table allocation summaries.
# This function accepts one additional optional argument that is the number of repeats to run.
function(bfn_add_determinism_test_with_args device arch p4file test_args) # + repeats
    # There can be test of the same p4 file for the same device, we need to make sure this gets a
    # distinct .test file. The only way to do that without larger changes to frontend's test macros
    # is to abuse the tag string that usually containes just the device.
    set(tag "${device}/determinism")
    set(_repeats "")
    if (ARGN)
        set(_repeats "--repeats ${ARGN}")
    endif()
    file (RELATIVE_PATH _relpath ${P4C_SOURCE_DIR} ${p4file})
    p4c_add_test_with_args(${tag} ${CMAKE_CURRENT_SOURCE_DIR}/tools/test_compilation_is_deterministic.py
        FALSE ${_relpath} ${_relpath} "-b ${device} -a ${arch} ${test_args}" "${_repeats}")
    p4c_add_test_label(${tag} "determinism" ${_relpath})
    set_tests_properties("${tag}/${_relpath}" PROPERTIES TIMEOUT ${extended_timeout_2times})
endfunction()

macro(add_backend_test_and_label device toolsdevice alias p4file label test_args cmake_args)
  bfn_add_test_with_args(${device} ${toolsdevice} ${alias} ${p4file} "${test_args}" "${cmake_args}")
  p4c_add_test_label(${device} "${label}" ${alias})
endmacro()

# Uses DFS to find all possible combinations of compiler definitions for given test.
function(add_test_with_compiler_definitions device toolsdevice arch alias p4file label definitions len index str)
  if(${index} GREATER_EQUAL ${len})
    add_backend_test_and_label(${device} ${toolsdevice} ${alias} ${p4file} "${label}"
      "-target ${device} -arch ${arch}" "${str}")
    return()
  endif()

  list(GET ${definitions} ${index} definition)
  set(values ${definitions}_${definition})
  math(EXPR next_idx "${index} + 1")

  if(DEFINED ${values})
    foreach(value ${${values}})
      set(next_alias ${alias}_${definition}_${value})
      set(next_str "${str} -D${definition}=${value}")

      add_test_with_compiler_definitions(${device} ${toolsdevice} ${arch} ${next_alias} ${p4file} 
        "${label}" ${definitions} ${len} ${next_idx} "${next_str}")
    endforeach()  # value
  else()
    set(str_undef "${str} -U${definition}")
    add_test_with_compiler_definitions(${device} ${toolsdevice} ${arch} ${alias} ${p4file} 
      "${label}" ${definitions} ${len} ${next_idx} "${str_undef}")
    
    set(str_def "${str} -D${definition}")
    set(next_alias ${alias}_${definition})
    add_test_with_compiler_definitions(${device} ${toolsdevice} ${arch} ${next_alias} ${p4file} 
      "${label}" ${definitions} ${len} ${next_idx} "${str_def}")
  endif()
endfunction(add_test_with_compiler_definitions)

# extra test args can be passed as unamed arguments
macro(p4c_add_bf_backend_tests device toolsdevice arch label tests)
  set (_testExtraArgs "${ARGN}")
  # do not add the device directly to _testExtraArgs
  # this is used later to add other tests for multiple configurations.
  # set (_testExtraArgs "${_testExtraArgs} -${device}")

  # if STF is not found, disable all stf tests
  if (NOT HARLYN_STF_${toolsdevice})
    set (_testExtraArgs "${_testExtraArgs} -norun")
  endif()

  if (PTF_REQUIREMENTS_MET)
    set (_testExtraArgs "${_testExtraArgs} -ptf")
    if (ENABLE_STF2PTF)
      if ( "${device}" STREQUAL "tofino")
        set (_testExtraArgs "${_testExtraArgs} -stf2ptf")
      endif()
    endif()
  endif()

  # If label is not empty, add it to the tests
  foreach (ts "${tests}")
    file (GLOB __testfiles RELATIVE ${P4C_SOURCE_DIR} ${ts})
    foreach (__p4file ${__testfiles})
      set(__definitions ${__p4file}_COMPILER_DEFINITIONS)
      if(DEFINED ${__definitions})
        list(LENGTH ${__definitions} __count)
        add_test_with_compiler_definitions(${device} ${toolsdevice} ${arch} ${__p4file} ${__p4file} "${label}"
          ${__definitions} ${__count} 0 "${_testExtraArgs}")
      else()
        add_backend_test_and_label(${device} ${toolsdevice} ${__p4file} ${__p4file} "${label}"
        "-target ${device} -arch ${arch} ${_testExtraArgs}" "")
      endif()
    endforeach() # __p4file
  endforeach()
endmacro(p4c_add_bf_backend_tests)

function(bfn_add_switch_test tofver flv extra_opts extra_labels run_ptf)
    set(path ${SWITCH_PATH_PREFIX}${flv}.p4)
    set(tofino "tofino${tofver}")
    file(RELATIVE_PATH relpath ${P4C_SOURCE_DIR} ${path})
    string(TOUPPER ${flv} FLV_UPPER)
    p4c_add_test_with_args("${tofino}" ${P4C_RUNTEST} FALSE "switch_16_${flv}" "${relpath}" ""
        "-D${FLV_UPPER}_PROFILE -I${SWITCH_P4_16_INC} -Xp4c=\"--auto-init-metadata ${extra_opts}\" -arch t${tofver}na -${tofino}")
    foreach (extra_label ${extra_labels})
        p4c_add_test_label("${tofino}" "${extra_label}" "switch_16_${flv}")
    endforeach()
    p4c_add_test_label("${tofino}" "SWITCH16" "switch_16_${flv}")
    set_tests_properties("${tofino}/switch_16_${flv}" PROPERTIES TIMEOUT ${extended_timeout_2times})
    if (run_ptf)
        p4c_add_ptf_test_with_ptfdir("${tofino}" "smoketest_switch_16_${flv}" ${path}
          "${testExtraArgs} -arch t${tofver}na -bfrt -profile ${flv}_${tofino} -Xp4c=\"--auto-init-metadata ${extra_opts}\"" ${SWITCH_P4_16_PTF})
        bfn_set_ptf_test_spec("${tofino}" "smoketest_switch_16_${flv}" "${ARGN}")
        # All switch_16 tests should depend on the test being compiled, rather than
        # relying on the first one to compile the test.
        # TODO(vstill): I don't think this actually works, the two compilations are done very
        # differently, I don't think the PTF one can pick results from the non-PTF one.
        set_tests_properties(
          "${tofino}/smoketest_switch_16_${flv}"
          PROPERTIES DEPENDS "${tofino}/switch_16_${flv}"
        )
        set_tests_properties("${tofino}/smoketest_switch_16_${flv}" PROPERTIES TIMEOUT ${extended_timeout_12times})
        p4c_add_test_label("${tofino}" "SWITCH16_PTF" "smoketest_switch_16_${flv}")
    endif()
endfunction()

# Specify tests which verify that the compiler reports correct errors.
# The tests will be marked to be added by the p4c_add_bf_diagnostic_tests macro.
# This will disable compilation/packet tests for the specified programs and only test that the
# error messages reported by the compiler match checks.
#
# "toolsdevice" is "tofino", "jbay", "cb", or "ftr"
# Additional arguments are paths to the p4 programs in the source directory to add as tests.
macro(set_negative_tests toolsdevice)
  set(__files ${ARGN})
  string(TOUPPER ${toolsdevice} __name)
  set(__tests DIAGNOSTIC_TESTS_${__name})

  list(APPEND ${__tests} ${__files})
  list(REMOVE_DUPLICATES ${__tests})
endmacro(set_negative_tests)

# Add tests which verify that the compiler reports correct errors/warnings.
#
# Tests in the following directories are added automatically:
# p4_16/warnings
# p4_16/warnings/${device}
# p4_16/errors
# p4_16/errors/${device}
# where ${device} is any of: tofino, jbay, cb, ftr
#
# Tests from other directories can be added by the set_negative_tests macro.
macro(p4c_add_bf_diagnostic_tests device toolsdevice arch label include_patterns exclude_patterns std)
  set(__opts_errors "-error-test")
  set(__opts_warnings "")
  unset(__glob)

  foreach(__type errors warnings)
    set(__glob "${CMAKE_CURRENT_SOURCE_DIR}/${std}/${__type}/*.p4"
               "${CMAKE_CURRENT_SOURCE_DIR}/${std}/${__type}/${toolsdevice}/*.p4")
    if(${__type} STREQUAL errors)
      string(TOUPPER ${toolsdevice} __name)
      list(APPEND __glob ${DIAGNOSTIC_TESTS_${__name}})
    endif()
    p4c_find_tests("${__glob}" __tests INCLUDE "${include_patterns}" EXCLUDE "${exclude_patterns}")
    bfn_find_tests("${__tests}" __bfn_tests EXCLUDE "")
    if(NOT "${__bfn_tests}" STREQUAL "")
      p4c_add_bf_backend_tests(${device} ${toolsdevice} ${arch} "${label};diagnostic" "${__bfn_tests}" 
        "-I${CMAKE_CURRENT_SOURCE_DIR}/${std}/includes ${__opts_${__type}}")
    endif()
  endforeach()  # __type
endmacro(p4c_add_bf_diagnostic_tests)

# Register a compiler definition to create multiple tests from a single p4 program.
# 
# "test" is path to the test file relative to build directory, eg. "extensions/p4_tests/p4_16/errors/p4c-4771.p4"
# "definition" is the name of the compiler definition
#
# Any other arguments will be treated as possible values for the definition and the tests will 
# declare them with -D${DEFINTION}=${VALUE}.
# If there are no more arguments, the definition will be registered as ON/OFF and the tests will 
# declare/undeclare it with -D${DEFINITION} and -U${DEFINITION}.
#
# If there are multiple definitions registered for a single program, tests will all possible combinations will be created, eg.:
#
# add_test_compiler_definition(${TEST} SWITCH)
# add_test_compiler_definition(${TEST} VARIABLE 1 2 3)
# 
# will create tests with the following definitions:
# - -USWITCH -DVARIABLE=1
# - -USWITCH -DVARIABLE=2
# - -USWITCH -DVARIABLE=3
# - -DSWITCH -DVARIABLE=1
# - -DSWITCH -DVARIABLE=2
# - -DSWITCH -DVARIABLE=3
macro(add_test_compiler_definition test definition)
  set(__values ${ARGN})
  list(LENGTH __values __count)

  set(__definitions ${test}_COMPILER_DEFINITIONS)
  list(APPEND ${__definitions} ${definition})
  list(REMOVE_DUPLICATES ${__definitions})

  if(${__count} GREATER 0)
    set(__definition_values ${__definitions}_${definition})
    list(APPEND ${__definition_values} ${__values})
    list(REMOVE_DUPLICATES ${__definition_values})
  endif()
endmacro()
