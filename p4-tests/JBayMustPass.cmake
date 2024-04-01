# These tests must pass, even when specified as XFAIL in JBayXfail.cmake.

set (JBAY_MUST_PASS_TESTS
  extensions/p4_tests/p4_14/ptf/easy_exact.p4
  extensions/p4_tests/p4_14/ptf/easy_no_match_with_gateway.p4
  extensions/p4_tests/p4_14/ptf/easy_ternary.p4
  )
