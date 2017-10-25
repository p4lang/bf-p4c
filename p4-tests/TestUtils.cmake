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

# call this macro to register a PTF test with a custom PTF test directory; by
# default the behavior is to look for a directory with the same name as the P4
# program and a .ptf extension, which may not always be convenient when adding
# tests for third-party P4 programs.
# if you need to mark this test as XFAIL, please edit TofinoXfail.cmake with the
# appropriate call to p4c_add_xfail_reason.
# FIXME this macro still has "tofino" hardcoded
macro(p4c_add_ptf_test_with_ptfdir alias ts args ptfdir)
  file (RELATIVE_PATH p4test ${P4C_SOURCE_DIR} ${ts})
  p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} FALSE ${alias}
    ${p4test} "${args} -ptfdir ${ptfdir}")
  p4c_test_set_name(__testname "tofino" ${alias})
if (PTF_REQUIREMENTS_MET)
  set_tests_properties(${__testname} PROPERTIES RUN_SERIAL 1)
  p4c_add_test_label("tofino" "ptf" ${alias})
endif()
endmacro(p4c_add_ptf_test_with_ptfdir)

macro(p4c_add_bf_backend_tests tag tests)
set (testExtraArgs)
set (testExtraArgs ${testExtraArgs} "-${tag}")
# if STF is not found, disbale all stf tests
if (NOT HARLYN_STF)
  set (testExtraArgs ${testExtraArgs} -norun)
endif()

if (PTF_REQUIREMENTS_MET)
  set (testExtraArgs ${testExtraArgs} -ptf)
  if (ENABLE_STF2PTF)
    set (testExtraArgs ${testExtraArgs} -stf2ptf)
  endif()
endif()

if (ENABLE_TNA)
  set (testExtraArgs ${testExtraArgs} -Xp4c=--native)
endif()

p4c_add_tests (${tag} ${P4C_RUNTEST} "${tests}"
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
        # MESSAGE(STATUS "STF2PTF: Generating ${P4C_BINARY_DIR}/${tag}/${__ptffile}/test.py")
        set(__havePTF 1)
      endif()
      if (${__havePTF})
        p4c_test_set_name(__testname ${tag} ${__p4file})
        set_tests_properties(${__testname} PROPERTIES RUN_SERIAL 1)
        p4c_add_test_label(${tag} "ptf" ${__p4file})
        # MESSAGE(STATUS "Added PTF test: ${__testname}")
        math (EXPR __ptfCounter "${__ptfCounter} + 1")
      endif()
    endforeach() # __p4file
  endforeach() # ts
  MESSAGE(STATUS "Added ${__ptfCounter} PTF tests")
endif() # PTF_REQUIREMENTS_MET

if (HARLYN_STF)
  foreach (ts "${tests}")
    file (GLOB __testfiles RELATIVE ${P4C_SOURCE_DIR} ${ts})
    foreach (__p4file ${__testfiles})
      string (REGEX REPLACE ".p4$" ".stf" __stffile ${__p4file})
      if (EXISTS ${P4C_SOURCE_DIR}/${__stffile})
        p4c_add_test_label(${tag} "stf" ${__p4file})
      endif()
    endforeach() # __p4file
  endforeach()   # ts
endif(HARLYN_STF)
endmacro(p4c_add_bf_backend_tests)

