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

# P4C-2293
p4c_add_xfail_reason("tofino"
  "error: .* has previous assignment in parser state .*This is an error because the field will"
  extensions/p4_tests/p4_16/compile_only/p4c-2293-simple-rec.p4
  extensions/p4_tests/p4_16/compile_only/p4c-2293-rec.p4
  extensions/p4_tests/p4_16/compile_only/p4c-2293-no-rec-fail.p4
  extensions/p4_tests/p4_16/stf/parser_multi_write_2.p4
  extensions/p4_tests/p4_16/stf/parser_multi_write_7.p4
  extensions/p4_tests/p4_16/stf/parser_multi_write_8.p4
)

p4c_add_xfail_reason("tofino"
  "error: The slice list below contains .* bits, the no_split attribute prevents it from being split any further, and it is too large to fit in the largest PHV containers.|NO_SLICING_FOUND"
  testdata/p4_16_samples/issue1607-bmv2.p4
)

p4c_add_xfail_reason("tofino"
  "Conditions in an action must be simple comparisons of an action data parameter"
  testdata/p4_16_samples/psa-conditional_operator.p4
)
# Fail on purpose due to indirect tables not being mutually exclusive
p4c_add_xfail_reason("tofino"
  "table .* and table .* cannot share .*"
  testdata/p4_16_samples/issue2844-enum.p4
  )

p4c_add_xfail_reason("tofino"
  "error: constant value .* too large for stateful alu"
  extensions/p4_tests/p4_14/compile_only/mau_test_neg_test.p4
)

p4c_add_xfail_reason("tofino"
  "error: RegisterAction do_sth does not match the type of register it uses"
  extensions/p4_tests/p4_16/errors/p4c-4270.p4
)

# P4C-1390 - sample_e2e is not supported by the TNA
p4c_add_xfail_reason("tofino"
  "error: (Primitive sample[34] is not supported by the backend)|(sample_e2e primitive is not currently supported by the TNA architecture)"
  extensions/p4_tests/glass/parde/test_start_coalesced_state.p4
  extensions/p4_tests/glass/mau/test_config_183_sample_e2e.p4
  )

# Headers that are not byte aligned
p4c_add_xfail_reason("tofino"
  "error: Tofino requires byte-aligned headers, but header .* is not byte-aligned"
  testdata/p4_16_samples/custom-type-restricted-fields.p4
  testdata/p4_16_samples/parser-unroll-test3.p4
  testdata/p4_16_samples/parser-unroll-test4.p4
  testdata/p4_16_samples/parser-unroll-test5.p4
  # p4c update 2022-04-25
  testdata/p4_16_samples/issue3225.p4
)

# P4C-2943: Parser value used by select statement is only initialised from constants
p4c_add_xfail_reason("tofino"
  "error: Value used in select statement needs to be set from input packet"
  extensions/p4_tests/p4_16/errors/p4c-2943.p4
)

p4c_add_xfail_reason("tofino"
  "error: .*: unsupported 64-bit select"
  extensions/p4_tests/p4_16/errors/p4c-2156.p4
  testdata/p4_14_samples/simple_nat.p4
  testdata/p4_14_samples/copy_to_cpu.p4
  testdata/p4_14_samples/axon.p4
  testdata/p4_14_samples/source_routing.p4
  extensions/p4_tests/glass/parde/COMPILER-368/out.p4
)

p4c_add_xfail_reason("tofino"
  "error: Unable to slice the following group of fields due to unsatisfiable constraints: .*|NO_SLICING_FOUND"
  extensions/p4_tests/p4_16/stf/cast_widening_add.p4
)

p4c_add_xfail_reason("tofino"
  "error: Unable to slice the following group of fields due to unsatisfiable constraints: .*|NO_SLICING_FOUND"
  extensions/p4_tests/p4_16/errors/p4c-4346.p4
)

p4c_add_xfail_reason("tofino"
  "error: Because you declared the register SwitchIngress.time_feats.pull_flow to store the type bit<8>.*"
  extensions/p4_tests/p4_16/compile_only/p4c-4612.p4
)

p4c_add_xfail_reason("tofino"
  "error: Two or more assignments of .* inside the register action .* are not mutually exclusive"
  extensions/p4_tests/p4_16/errors/p4c-4600.p4
)

p4c_add_xfail_reason("tofino"
  "error: invalid SuperCluster was formed"
  extensions/p4_tests/p4_16/errors/p4c-4720.p4
)

# P4C-4524
p4c_add_xfail_reason("tofino"
  "error: .* uses of all registers within a single action have to use the same addressing.*"
  extensions/p4_tests/p4_16/errors/p4c-4524.p4
)

# P4C-4607
p4c_add_xfail_reason("tofino"
  "error: slice of register value in condition is not supported"
  extensions/p4_tests/p4_16/errors/p4c-4607.p4
)

# P4C-4616
p4c_add_xfail_reason("tofino"
  "error: hash.get: field list cannot be empty"
  extensions/p4_tests/p4_16/errors/externs_hash_empty_list.p4
)

p4c_add_xfail_reason("tofino"
  "error: Only simple assignments are supported for one-bit registers."
  extensions/p4_tests/p4_16/errors/p4c-4522.p4
)

p4c_add_xfail_reason("tofino"
  "error: too complex bitwise operation used in comparison"
  extensions/p4_tests/p4_16/errors/p4c-4705.p4
)