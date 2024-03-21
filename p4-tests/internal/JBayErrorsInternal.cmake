# JBayErrors: Tests that are expected to fail
# =============================================
#
# These tests are expected to fail and throw a certain error. They
# should be placed in an 'errors' directory, e.g.,
# p4-tests/p4_16/errors/

# P4C-5286
set_negative_tests("jbay"
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/errors/p4c-5286.p4
)
