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

set_negative_tests("tofino"
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/stf/parser_multi_write_2.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/stf/parser_multi_write_8.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/stf/parser_multi_write_checksum_deposit_2.p4
)
