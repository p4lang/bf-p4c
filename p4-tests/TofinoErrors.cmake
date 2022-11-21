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
   "error: .*: too many actions access the Register"
   extensions/p4_tests/p4_16/errors/stateful_read_write_5actions.p4
)

p4c_add_xfail_reason("tofino"
   "error: .*: too many RegisterActions attached to the Register"
   extensions/p4_tests/p4_16/errors/stateful_read_write_5registeractions.p4
)

# P4C-2293
p4c_add_xfail_reason("tofino"
  "error: .* is assigned in state .* but has also previous assignment"
  extensions/p4_tests/p4_16/compile_only/p4c-2293-simple-rec.p4
  extensions/p4_tests/p4_16/compile_only/p4c-2293-rec.p4
  extensions/p4_tests/p4_16/compile_only/p4c-2293-no-rec-fail.p4
  extensions/p4_tests/p4_16/stf/parser_multi_write_2.p4
  extensions/p4_tests/p4_16/stf/parser_multi_write_8.p4
)
p4c_add_xfail_reason("tofino"
  "error: Inconsistent parser write semantic for field ingress::meta.m.f in parser state ingress::parse_c."
  extensions/p4_tests/p4_16/stf/parser_multi_write_7.p4
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

p4c_add_xfail_reason("tofino"
  "error: Before instruction .* in state .*, checksum .* operates on either an \
odd or an even number of bytes, depending on path through the parser. This makes it \
impossible to implement on Tofino. Consider adding a subtract instruction with a constant \
argument 8w0 in a preceding state to make the checksum always operate on either an odd or an \
even number of bytes."
  extensions/p4_tests/p4_16/errors/p4c-4771-error.p4
)

p4c_add_xfail_reason("tofino"
  "error: Checksum .* operates on an odd number of bytes inside a loop consisting of states .* \
which makes it impossible to implement on Tofino. Consider adding an add / subtract instruction \
with a constant argument 8w0 in one of the states in the loop to make the checksum operate on an \
even number of bytes."
  extensions/p4_tests/p4_16/errors/p4c-4771-error-loop.p4
)

p4c_add_xfail_reason("tofino"
  "error: .*: Invalid local variable entry in checksum calculation .*"
  extensions/p4_tests/p4_16/errors/p4c-3477.p4
)

p4c_add_xfail_reason("tofino"
  "error: Register actions associated with .* do not fit on the device. \
Actions use 9 large constants but the device has only 4 register action parameter slots. \
To make the actions fit, reduce the number of large constants."
  extensions/p4_tests/p4_16/errors/p4c-4829-constants.p4
)

p4c_add_xfail_reason("tofino"
  "error: Register actions associated with .* do not fit on the device. \
Actions use 6 large constants and 3 register parameters for a total of 9 register \
action parameter slots but the device has only 4 register action parameter slots. \
To make the actions fit, reduce the number of large constants or register parameters."
  extensions/p4_tests/p4_16/errors/p4c-4829-mixed.p4
)

p4c_add_xfail_reason("tofino"
  "error: Register actions associated with .* do not fit on the device. \
Actions use 5 register parameters but the device has only 4 register action parameter slots. \
To make the actions fit, reduce the number of register parameters."
  extensions/p4_tests/p4_16/errors/p4c-4829-params.p4
)

p4c_add_xfail_reason("tofino"
  "error: Unary negation .* in Stateful ALU is only possible if it is the only operation in an \
expression. Try simplifying your expression."
  extensions/p4_tests/p4_16/errors/p4c-4976-unary-negation.p4
)

p4c_add_xfail_reason("tofino"
  "error: constant value .* is out of range .* for stateful ALU"
  extensions/p4_tests/p4_16/errors/p4c-4110.p4
)

# P4C-4689
# TODO: add tofino 2 version (that passes)
# all these cases are demoted to warnings
#p4c_add_xfail_reason("tofino"
#    "error: (in|e)gress::.* is assigned in state (in|e)gress::.* but has also previous assignment"
#    testdata/p4_16_samples/parser-inline/parser-inline-test7.p4
#    parser-inline-opt/testdata/p4_16_samples/parser-inline/parser-inline-test7.p4
#    testdata/p4_16_samples/parser-inline/parser-inline-test10.p4
#    testdata/p4_16_samples/parser-inline/parser-inline-test8.p4
#    testdata/p4_16_samples/parser-inline/parser-inline-test9.p4
#    testdata/p4_16_samples/issue2314.p4
#    psa_checksum
#)

# P4C-4689 tests that should fail on Tofino 1
p4c_add_xfail_reason("tofino"
    "error: (in|e)gress::.* is assigned in state (in|e)gress::.* but has also previous assignment"
    extensions/p4_tests/p4_16/stf/parser_multi_write_checksum_deposit_2.p4
    extensions/p4_tests/p4_16/stf/parser_multi_write_checksum_verify_3.p4
    extensions/p4_tests/p4_16/stf/parser_multi_write_checksum_verify_4.p4
)
# error demoted to warning :-/
# Check that there is a warning. However, PASS_REGULAR_EXPRESSION disables exitcode checking so
# also set FAIL_REGULAR_EXPRESSION to (hopefully) catch cases when the compilation fails.
set_tests_properties("tofino/extensions/p4_tests/p4_16/stf/parser_multi_write_checksum_verify_2.p4"
  PROPERTIES
  PASS_REGULAR_EXPRESSION "warning: (in|e)gress::.* is assigned in state (in|e)gress::.* but has also previous assignment"
  FAIL_REGULAR_EXPRESSION "p4c FAILED;error:"
)
# P4C-4689 tests that should fail on all Tofino versions
p4c_add_xfail_reason("tofino"
    "error: It is not possible to deposit multiple checksum residuals into field"
    extensions/p4_tests/p4_16/compile_only/parser_multi_write_checksum_deposit_3.p4
)
