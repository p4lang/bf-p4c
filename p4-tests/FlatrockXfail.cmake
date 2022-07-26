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
  "WARNING:.*binary.*does not match model version|packet output on port 3"
  extensions/p4_tests/p4_16/flatrock/direct0.p4
  )

p4c_add_xfail_reason("tofino5"
  #"WARNING:.*binary.*does not match model version|unexpected packet output on port 0"
  "error: match entries don't match input_xbar ordering"
  extensions/p4_tests/p4_16/flatrock/exact0.p4
  extensions/p4_tests/p4_16/flatrock/exact1.p4
  )

p4c_add_xfail_reason("tofino5"
  "WARNING:.*binary.*does not match model version|unexpected packet output on port 0"
  extensions/p4_tests/p4_16/flatrock/direct1.p4
  )

# model fails -- probably many other problems besides this message
p4c_add_xfail_reason("tofino5"
  "WARNING:.*binary.*does not match model version|packet output on port 2"
  extensions/p4_tests/p4_16/flatrock/passthrough.p4
  )

p4c_add_xfail_reason("tofino5"
  #"WARNING:.*binary.*does not match model version|mismatch from expected"
  "error: match entries don't match input_xbar ordering"
  extensions/p4_tests/p4_16/flatrock/gateway1.p4
  )

p4c_add_xfail_reason("tofino5"
  #"WARNING:.*binary.*does not match model version|mismatch from expected"
  "error: match entries don't match input_xbar ordering"
  extensions/p4_tests/p4_16/flatrock/gateway2.p4
  )

p4c_add_xfail_reason("tofino5"
  "Assembler BUG"
  extensions/p4_tests/p4_16/flatrock/ternary1.p4
  )

# invalid assembly code
#p4c_add_xfail_reason("tofino5"
#  "Invalid slice of 7 bit field immediate"
#  extensions/p4_tests/p4_16/flatrock/tf5_template.p4
#  )

p4c_add_xfail_reason("tofino5"
  "Compiler Bug.* not an always hit hash_action table"
  extensions/p4_tests/p4_16/flatrock/t5na_bridged_md.p4
  )

p4c_add_xfail_reason("tofino5"
  "Conditions in an action must be simple comparisons of an action data parameter"
  extensions/p4_tests/p4_16/flatrock/exact2.p4
  )

#p4c_add_xfail_reason("tofino5"
#  ""  -- need a real test case here.
#  extensions/p4_tests/p4_16/flatrock/pac_trivial.p4
#  extensions/p4_tests/p4_16/flatrock/pac_single_hdr.p4
#  )

#p4c_add_xfail_reason("tofino5"
#  #"Flatrock .* not implemented yet"
#  "No format field or table named immediate"
#  extensions/p4_tests/p4_16/flatrock/pac_unbal_reconverge.p4
#  )

p4c_add_xfail_reason("tofino5"
  "invalid gateway group"
  extensions/p4_tests/p4_16/flatrock/pac_shallow_branch.p4
  extensions/p4_tests/p4_16/flatrock/pac_wide_branch.p4
  )

p4c_add_xfail_reason("tofino5"
  "Only one parser state transition supported"
  extensions/p4_tests/p4_16/flatrock/pac_unbal_reconverge.p4
  extensions/p4_tests/p4_16/flatrock/tf5_template.p4
  extensions/p4_tests/p4_16/stf/header_stack_next.p4
  extensions/p4_tests/p4_16/stf/header_stack_strided_alloc1.p4
  extensions/p4_tests/p4_16/stf/header_stack_strided_alloc2.p4
  extensions/p4_tests/p4_16/stf/lookahead1.p4
  extensions/p4_tests/p4_16/stf/parser_counter_12.p4
  extensions/p4_tests/p4_16/stf/parser_extract_upcast.p4
  extensions/p4_tests/p4_16/stf/parser_loop_1.p4
  extensions/p4_tests/p4_16/stf/parser_loop_2.p4
  extensions/p4_tests/p4_16/stf/parser_loop_3.p4
  extensions/p4_tests/p4_16/stf/parser_loop_4.p4
  extensions/p4_tests/p4_16/stf/varbit_constant.p4
  )

# *********************************************************************************************** #
# ** TNA tests that "should" work *************************************************************** #
# *********************************************************************************************** #
p4c_add_xfail_reason("tofino5"
  "Compiler Bug: .* Null member"
  extensions/p4_tests/p4_16/stf/failed_elim_valid_bit.p4
  extensions/p4_tests/p4_16/stf/p4c-2638.p4
  extensions/p4_tests/p4_16/stf/p4c-2695.p4
  extensions/p4_tests/p4_16/stf/wide_arith_non_64.p4
  )

# Unimplemented - support for wide matches
p4c_add_xfail_reason("tofino5"
  "Compiler Bug: Cannot allocate wide RAMS in Flatrock. Invalid size 2"
  extensions/p4_tests/p4_16/stf/cond_checksum_update_4.p4
  extensions/p4_tests/p4_16/stf/p4c-1513.p4
  extensions/p4_tests/p4_16/stf/p4c-3089.p4
  extensions/p4_tests/p4_16/stf/zeros_as_ones.p4
  )

p4c_add_xfail_reason("tofino5"
  "Compiler Bug: Emitted field didn't receive a PHV allocation: ig_intr_md_for_tm.icrc_enable"
  extensions/p4_tests/p4_16/stf/backend_bug1c.p4
  extensions/p4_tests/p4_16/stf/funnel_shift.p4
  #extensions/p4_tests/p4_16/stf/header_stack_next.p4
  #extensions/p4_tests/p4_16/stf/header_stack_strided_alloc1.p4
  #extensions/p4_tests/p4_16/stf/header_stack_strided_alloc2.p4
  #extensions/p4_tests/p4_16/stf/lookahead1.p4
  extensions/p4_tests/p4_16/stf/lookahead2.p4
  extensions/p4_tests/p4_16/stf/lookahead3.p4
  #extensions/p4_tests/p4_16/stf/p4c-2638.p4
  #extensions/p4_tests/p4_16/stf/p4c-2695.p4
  extensions/p4_tests/p4_16/stf/p4c-3470.p4
  #extensions/p4_tests/p4_16/stf/parser_counter_12.p4
  #extensions/p4_tests/p4_16/stf/parser_extract_upcast.p4
  extensions/p4_tests/p4_16/stf/update_checksum_3.p4
  extensions/p4_tests/p4_16/stf/update_checksum_4.p4
  extensions/p4_tests/p4_16/stf/update_checksum_6.p4
  #extensions/p4_tests/p4_16/stf/varbit_constant.p4
  #extensions/p4_tests/p4_16/stf/failed_elim_valid_bit.p4
  extensions/p4_tests/p4_16/stf/p4c-1504.p4
  extensions/p4_tests/p4_16/stf/p4c-2772.p4
  extensions/p4_tests/p4_16/stf/p4c-2772-c.p4
  #extensions/p4_tests/p4_16/stf/wide_arith_non_64.p4
  )

# These may be genuine expected failures due to field packing and extractions
p4c_add_xfail_reason("tofino5"
  "Compiler Bug: Trying to allocate field .* with .* source to container .* with .* source"
  extensions/p4_tests/p4_16/stf/bit_or_in_same_state.p4
  )

p4c_add_xfail_reason("tofino5"
  "Compiler Bug: Cannot allocate wide RAMS in Flatrock. Invalid size 2"
  extensions/p4_tests/p4_16/stf/auto_init_meta2.p4
  )

p4c_add_xfail_reason("tofino5"
  "Compiler Bug: Conflicting alloc on the action data bus"
  extensions/p4_tests/p4_16/stf/p4c-4107.p4
  )

#p4c_add_xfail_reason("tofino5"
#  "error: Constant literals only useable on 8-bit PHEs"
#  extensions/p4_tests/p4_16/stf/backend_bug1c.p4
#  extensions/p4_tests/p4_16/stf/bit_or_in_same_state.p4
#  extensions/p4_tests/p4_16/stf/p4c-2695.p4
#  extensions/p4_tests/p4_16/stf/p4c-2638.p4
#  )

#p4c_add_xfail_reason("tofino5"
#  "Flatrock .* not implemented yet"
#  extensions/p4_tests/p4_16/stf/p4c-3470.p4
#  extensions/p4_tests/p4_16/stf/varbit_constant.p4
#  )

p4c_add_xfail_reason("tofino5"
  "invalid gateway group"
  extensions/p4_tests/p4_16/flatrock/dconfig1.p4
  extensions/p4_tests/p4_16/stf/extract_slice_2.p4
  extensions/p4_tests/p4_16/stf/metadata_extract.p4
  extensions/p4_tests/p4_16/stf/p4c-3055-2.p4
  extensions/p4_tests/p4_16/stf/p4c-3551.p4
  extensions/p4_tests/p4_16/stf/p4c-3659.p4
  extensions/p4_tests/p4_16/stf/parse_depth_1.p4
  extensions/p4_tests/p4_16/stf/parser_counter_6.p4
  extensions/p4_tests/p4_16/stf/parser_counter_8.p4
  extensions/p4_tests/p4_16/stf/parser_local_register.p4
  extensions/p4_tests/p4_16/stf/parser_local_register_2.p4
  extensions/p4_tests/p4_16/stf/parser_multi_write_1.p4
  extensions/p4_tests/p4_16/stf/parser_multi_write_5.p4
  extensions/p4_tests/p4_16/stf/parser_multi_write_8.p4
  extensions/p4_tests/p4_16/stf/simple_l3_acl_disappearing_options.p4
  extensions/p4_tests/p4_16/stf/p4c-1179.p4
  )

p4c_add_xfail_reason("tofino5"
  "Compiler Bug: Unknown device"
  extensions/p4_tests/p4_16/stf/header_stack_checksum.p4
  extensions/p4_tests/p4_16/stf/update_checksum_1.p4
  extensions/p4_tests/p4_16/stf/verify_checksum_3.p4
  extensions/p4_tests/p4_16/stf/narrow_to_wide_w_csum_1.p4
  extensions/p4_tests/p4_16/stf/narrow_to_wide_w_csum_2.p4
  extensions/p4_tests/p4_16/stf/narrow_to_wide_w_csum_3.p4
  extensions/p4_tests/p4_16/stf/narrow_to_wide_w_csum_4.p4
  extensions/p4_tests/p4_16/stf/narrow_to_wide_w_csum_5.p4
  )

#p4c_add_xfail_reason("tofino5"
#  "Assembler BUG"
#  extensions/p4_tests/p4_16/stf/header_stack_next.p4
#  extensions/p4_tests/p4_16/stf/header_stack_strided_alloc1.p4
#  extensions/p4_tests/p4_16/stf/update_checksum_6.p4
#  )

#p4c_add_xfail_reason("tofino5"
#  "error: Syntax error, expecting identifier"
#  extensions/p4_tests/p4_16/stf/header_stack_strided_alloc2.p4
#  )

#p4c_add_xfail_reason("tofino5"
#  "CRASH with signal .*"
#  extensions/p4_tests/p4_16/stf/lookahead2.p4
#  extensions/p4_tests/p4_16/stf/lookahead3.p4
#  extensions/p4_tests/p4_16/stf/parser_counter_12.p4
#  extensions/p4_tests/p4_16/stf/update_checksum_3.p4
#  extensions/p4_tests/p4_16/stf/update_checksum_4.p4
#  extensions/p4_tests/p4_16/stf/cond_checksum_update_4.p4
#  extensions/p4_tests/p4_16/stf/funnel_shift.p4
#  extensions/p4_tests/p4_16/stf/lookahead1.p4
#  extensions/p4_tests/p4_16/stf/p4c-1513.p4
#  )

p4c_add_xfail_reason("tofino5"
  "operand not a phv ref"
  extensions/p4_tests/p4_16/stf/p4c-2772-b.p4
  )

#p4c_add_xfail_reason("tofino5"
#  "error: Invalid slice"
#  extensions/p4_tests/p4_16/stf/p4c-2772.p4
#  extensions/p4_tests/p4_16/stf/parser_extract_upcast.p4
#  )

p4c_add_xfail_reason("tofino5"
  "Compiler Bug: Emitted field didn't receive a PHV allocation"
  #extensions/p4_tests/p4_16/stf/parser_loop_1.p4
  #extensions/p4_tests/p4_16/stf/parser_loop_2.p4
  #extensions/p4_tests/p4_16/stf/parser_loop_3.p4
  #extensions/p4_tests/p4_16/stf/parser_loop_4.p4

  )

p4c_add_xfail_reason("tofino5"
  "error: PHV allocation creates an invalid container action within a Tofino ALU"
  extensions/p4_tests/p4_16/stf/update_checksum_2.p4
  )

# p4c_add_xfail_reason("tofino5"
#   #"Compiler Bug: Bytes on same search bus are not contained within the same ixbar group"
#   "IXBar::Use::bits_per_search_bus.. const: Assertion|Internal compiler error"
#   extensions/p4_tests/p4_16/stf/zeros_as_ones.p4
#   )

# *********************************************************************************************** #
# ** \TNA tests that "should" work ************************************************************** #
# *********************************************************************************************** #
