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
  "Flatrock .* not implemented yet"
  extensions/p4_tests/p4_16/flatrock/direct1.p4
  )

p4c_add_xfail_reason("tofino5"
  "Flatrock .* not implemented yet"
  extensions/p4_tests/p4_16/flatrock/exact1.p4
  )

# model fails -- probably many other problems besides this message
p4c_add_xfail_reason("tofino5"
   "WARNING:.*binary.*does not match model version"
  extensions/p4_tests/p4_16/flatrock/passthrough.p4
  )

p4c_add_xfail_reason("tofino5"
  "Flatrock .* not implemented yet"
  extensions/p4_tests/p4_16/flatrock/gateway1.p4
  )

p4c_add_xfail_reason("tofino5"
  "Flatrock .* not implemented yet"
  extensions/p4_tests/p4_16/flatrock/gateway2.p4
  )

# invalid assembly code
p4c_add_xfail_reason("tofino5"
  "Invalid slice of 7 bit field immediate"
  extensions/p4_tests/p4_16/flatrock/tf5_template.p4
  extensions/p4_tests/p4_16/flatrock/t5na_bridged_md.p4
  )

p4c_add_xfail_reason("tofino5"
  "Conditions in an action must be simple comparisons of an action data parameter"
  extensions/p4_tests/p4_16/flatrock/exact2.p4
  )


# PAC test cases
#p4c_add_xfail_reason("tofino5"
#  ""  -- need a real test case here.
#  extensions/p4_tests/p4_16/flatrock/pac_trivial.p4
#  extensions/p4_tests/p4_16/flatrock/pac_single_hdr.p4
#  )

p4c_add_xfail_reason("tofino5"
  "Flatrock .* not implemented yet"
  extensions/p4_tests/p4_16/flatrock/pac_unbal_reconverge.p4
  )

p4c_add_xfail_reason("tofino5"
  "invalid gateway group"
  extensions/p4_tests/p4_16/flatrock/pac_shallow_branch.p4
  extensions/p4_tests/p4_16/flatrock/pac_wide_branch.p4
  )
