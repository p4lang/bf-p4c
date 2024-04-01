# TofinoErrors: Tests that are expected to fail
# =============================================
#
# These tests are expected to fail and throw a certain error or succeed and report a warning. They
# should be placed in an 'errors' or 'warnings' directory, e.g.,
# p4-tests/p4_16/errors/
# p4-tests/p4_16/warnings/
#
# Tests from these directories are added automatically for all devices. Tests specific to one device 
# can be added to directories with their name, eg. p4-tests/p4_16/errors/tofino. These tests will
# be added only for the specific device.
#
# In this file, compiler definitions should be specified for tests that verify diagnostic messages
# output by the compiler. 
# Additionally, tests from other directories can be set for diagnostic verifiction by calling
# set_negative_tests().

add_test_compiler_definition(
  extensions/p4_tests/p4_16/internal/errors/p4c-4771.p4
  LOOP
)

add_test_compiler_definition(
  extensions/p4_tests/p4_16/internal/errors/p4c-4829.p4
  TEST
  1 2 3
)

# P4C-4226 -- these in fact should pass, but right now the features (varbit assignemnt, etc.) are
# not supported.
add_test_compiler_definition(
  extensions/p4_tests/p4_16/internal/errors/p4c-4226.p4
  TEST
  0 1 2 3 4
)

add_test_compiler_definition(
  extensions/p4_tests/p4_16/errors/register_action_errors.p4
  TEST
  1 2 3 4 5 6 7 8 9 10 11 12
)

set_negative_tests("tofino"
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/p4c-2293-no-rec-fail.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/p4c-2293-rec.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/internal/p4c-2293-simple-rec.p4
)
