# JBayErrors: Tests that are expected to fail
# =============================================
#
# These tests are expected to fail and throw a certain error. They
# should be placed in an 'errors' directory, e.g.,
# p4-tests/p4_16/errors/

# P4C-4689
set_negative_tests("jbay"
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/stf/parser_multi_write_checksum_verify_2.p4
)
