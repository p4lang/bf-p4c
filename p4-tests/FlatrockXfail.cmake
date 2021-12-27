# XFAILS: tests that *temporarily* fail
# =====================================
#
# Xfails are _temporary_ failures: the tests should work but we haven't fixed
# the compiler yet.
#
# Tests that are _always_ expected to fail should be placed in an 'errors'
# directory, e.g., p4-tests/p4_16/errors/, and added to FlatrockErrors.cmake.

set (FLATROCK_XFAIL_TESTS
  # this is intentionally empty because xfails should be added with a reason.
  # look for the failure message in this file and add to an existing ticket
  # or open a new one.
  )

p4c_add_xfail_reason("tofino5"
  "package Pipeline"
  extensions/p4_tests/p4_16/flatrock/tf5_template.p4
  )