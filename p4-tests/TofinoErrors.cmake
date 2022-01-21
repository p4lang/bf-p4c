# TofinoErrors: Tests that are expected to fail
# =============================================
#
# These tests are expected to fail and throw a certain error. They
# should be placed in an 'errors' directory, e.g.,
# p4-tests/p4_16/errors/

p4c_add_xfail_reason("tofino"
  "There are issues with the following indirect externs"
  testdata/p4_14_samples/counter.p4
  extensions/p4_tests/p4_16/errors/counter1.p4
  extensions/p4_tests/p4_16/errors/counter2.p4
)

p4c_add_xfail_reason("tofino"
  "error: Wrong port metadata field packing size, should be exactly 64 bits, is .* bits"
  extensions/p4_tests/p4_16/errors/p4c-3664.p4
)

p4c_add_xfail_reason("tofino"
  "error: Adjust byte count operand on primitive .* does not resolve to a constant value"
  extensions/p4_tests/p4_16/errors/meters_adjust_byte_count_neg.p4
)

p4c_add_xfail_reason("tofino"
  "error: Wide operations not supported in stateful alu, will only operate on bottom 32 bits"
  extensions/p4_tests/p4_16/errors/p4c-2338.p4
  testdata/p4_16_samples/psa-register-read-write-bmv2.p4
  testdata/p4_16_samples/psa-example-register2-bmv2.p4
)

p4c_add_xfail_reason("tofino"
  "Parser counter increment argument is not a constant integer"
  extensions/p4_tests/p4_16/errors/p4c-3804-inc.p4
)

p4c_add_xfail_reason("tofino"
  "Parser counter decrement argument is not a constant integer"
  extensions/p4_tests/p4_16/errors/p4c-3804-dec.p4
)

p4c_add_xfail_reason("tofino"
  "Name 'pipe.abc' is used for multiple table objects in the P4Info message"
  extensions/p4_tests/p4_16/errors/p4c-3967.p4
)

p4c_add_xfail_reason("tofino"
  "Can't enforce minimum parse depth for parser EgressParser because parser counter is already used"
  extensions/p4_tests/p4_16/errors/parse_depth_counter.p4
)

p4c_add_xfail_reason("tofino"
  "Parser EgressParser: longest path through parser .* exceeds maximum parse depth"
  extensions/p4_tests/p4_16/errors/parse_depth_length.p4
)

p4c_add_xfail_reason("tofino"
   "error: .*: too many actions try to access the register"
   extensions/p4_tests/p4_16/errors/stateful_read_write_5actions.p4
)
