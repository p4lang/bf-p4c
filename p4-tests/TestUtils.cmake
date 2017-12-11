# if we have a reason for failure, then use that regular expression to
# make the test succeed. If that changes, we know the test moved to a
# different failure. Also turn off automatic ignoring of failures (WILL_FAIL).
macro(p4c_add_xfail_reason tag reason)
  set (__tests "${ARGN}")
  string (TOUPPER ${tag} __upperTag)
  foreach (test IN LISTS __tests)
    list (FIND ${__upperTag}_MUST_PASS_TESTS ${test} __isMustPass)
    if (${__isMustPass} EQUAL -1) # not a mandatory pass test
      p4c_test_set_name(__testname ${tag} ${test})
      if ( "${reason}" STREQUAL "")
        set_tests_properties(${__testname} PROPERTIES WILL_FAIL 1)
      else ()
        set_tests_properties(${__testname} PROPERTIES
          PASS_REGULAR_EXPRESSION ${reason}
          WILL_FAIL 0)
      endif()
      p4c_add_test_label(${tag} "XFAIL" ${test})
    else()
      message(WARNING "${test} can not be listed as an xfail. It must always pass!")
    endif()
  endforeach()
endmacro(p4c_add_xfail_reason)

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
      ${p4test} "${args} -ptfdir ${ptfdir}")
    set_tests_properties(${__testname} PROPERTIES RUN_SERIAL 1)
    p4c_add_test_label(${device} "ptf" ${alias})
  else()
    p4c_add_test_with_args (${device} ${P4C_RUNTEST} FALSE ${alias}
      ${p4test} "${args}")
  endif()
endmacro(p4c_add_ptf_test_with_ptfdir)

macro(simple_test_setup_check device)
  if (NOT ENABLE_STF2PTF)
    # We run STF tests on the STF framework
    set(STF_SEARCH_PATHS
      ${CMAKE_INSTALL_PREFIX}/bin
      ${BFN_P4C_SOURCE_DIR}/../model/tests/simple_test_harness
      ${BFN_P4C_SOURCE_DIR}/../model/build/tests/simple_test_harness
      ${BFN_P4C_SOURCE_DIR}/../model/debug/tests/simple_test_harness
      ${BFN_P4C_SOURCE_DIR}/bf-asm/simple_test_harness)

    find_program(HARLYN_STF_${device}_GZ ${device}_test_harness.gz PATHS ${STF_SEARCH_PATHS})

    if (HARLYN_STF_${device}_GZ)
      MESSAGE (STATUS "${device}_test_harness.gz found at ${HARLYN_STF_${device}_GZ}, uncompressing file ...")
      execute_process(COMMAND gunzip -kf ${HARLYN_STF_${device}_GZ})
    endif()

    find_program(HARLYN_STF_${device} ${device}_test_harness PATHS ${STF_SEARCH_PATHS})

    if (HARLYN_STF_${device})
      MESSAGE (STATUS "${device}_test_harness found at ${HARLYN_STF_${device}}.")
    else()
      MESSAGE (WARNING "STF tests need Harlyn ${device}_test_harness.\nLooked in ${STF_SEARCH_PATHS}.")
    endif()
  endif()
endmacro(simple_test_setup_check)

macro(packet_test_setup_check device)
  # check for ptf
  find_program(PTF ptf PATHS ${CMAKE_INSTALL_PREFIX}/bin)

  # check for bf_switchd
  find_program(BF_SWITCHD bf_switchd PATHS ${CMAKE_INSTALL_PREFIX}/bin)

  # check for tofino-model
  find_program(HARLYN_MODEL ${device}-model PATHS ${CMAKE_INSTALL_PREFIX}/bin)

  if (PTF AND BF_SWITCHD AND HARLYN_MODEL)
    set (PTF_REQUIREMENTS_MET TRUE)
    MESSAGE (STATUS "All PTF dependencies were found.")
  else()
    set (PTF_REQUIREMENTS_MET FALSE)
    if (NOT PTF)
      MESSAGE (WARNING "PTF tests need the ptf binary.")
    endif()
    if (NOT BF_SWITCHD)
      MESSAGE (WARNING "PTF tests need the bf_switchd binary.")
    endif()
    if (NOT HARLYN_MODEL)
      MESSAGE (WARNING "PTF tests need the ${device}-model binary.")
    endif()
  endif()
endmacro(packet_test_setup_check)

macro(p4c_add_bf_backend_tests device tests)
  set (testExtraArgs)
  set (testExtraArgs "${testExtraArgs} -${device}")

  simple_test_setup_check(${device})

  packet_test_setup_check(${device})

  # if STF is not found, disable all stf tests
  if (NOT HARLYN_STF_${device})
    set (testExtraArgs "${testExtraArgs} -norun")
  endif()

  if (PTF_REQUIREMENTS_MET)
    set (testExtraArgs "${testExtraArgs} -ptf")
    if (ENABLE_STF2PTF)
      set (testExtraArgs "${testExtraArgs} -stf2ptf")
    endif()
  endif()

  p4c_add_tests (${device} ${P4C_RUNTEST} "${tests}"
     "" "${testExtraArgs}")

  if (PTF_REQUIREMENTS_MET)
    # PTF tests cannot be run in parallel with other tests, so we set the SERIAL
    # property for them
    set (__ptfCounter 0)
    foreach (ts "${tests}")
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
          # MESSAGE(STATUS "STF2PTF: Generating ${P4C_BINARY_DIR}/${device}/${__ptffile}/test.py")
          set(__havePTF 1)
        endif()
        if (${__havePTF})
          p4c_test_set_name(__testname ${device} ${__p4file})
          set_tests_properties(${__testname} PROPERTIES RUN_SERIAL 1)
          p4c_add_test_label(${device} "ptf" ${__p4file})
          # MESSAGE(STATUS "Added PTF test: ${__testname}")
          math (EXPR __ptfCounter "${__ptfCounter} + 1")
        endif()
      endforeach() # __p4file
    endforeach() # ts
    MESSAGE(STATUS "Added ${__ptfCounter} PTF tests")
  endif() # PTF_REQUIREMENTS_MET

  if (HARLYN_STF_${device})
    foreach (ts "${tests}")
      file (GLOB __testfiles RELATIVE ${P4C_SOURCE_DIR} ${ts})
      foreach (__p4file ${__testfiles})
        string (REGEX REPLACE ".p4$" ".stf" __stffile ${__p4file})
        if (EXISTS ${P4C_SOURCE_DIR}/${__stffile})
          p4c_add_test_label(${device} "stf" ${__p4file})
        endif()
      endforeach() # __p4file
    endforeach()   # ts
  endif(HARLYN_STF_${device})
endmacro(p4c_add_bf_backend_tests)
