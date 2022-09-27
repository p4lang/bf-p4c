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
  "Assembler BUG"
  extensions/p4_tests/p4_16/flatrock/ternary1.p4
  )

p4c_add_xfail_reason("tofino5"
  "error: invalid ram in way"
  extensions/p4_tests/p4_16/flatrock/direct-stm0.p4
  )

# invalid assembly code
p4c_add_xfail_reason("tofino5"
#  "Invalid slice of 7 bit field immediate"
  "error: Invalid field group"
  extensions/p4_tests/p4_16/flatrock/tf5_template.p4
  )

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

p4c_add_xfail_reason("tofino5"
  "error: No format field or table named immediate"
  extensions/p4_tests/p4_16/flatrock/pac_shallow_branch.p4
  extensions/p4_tests/p4_16/flatrock/pac_unbal_reconverge.p4
  )

p4c_add_xfail_reason("tofino5"
  "The table tbl_pac_wide_branch.* could not fit within .* input crossbar"
  extensions/p4_tests/p4_16/flatrock/pac_wide_branch.p4
  )

p4c_add_xfail_reason("tofino5"
  "error: Syntax error, expecting identifier"
  extensions/p4_tests/p4_16/stf/header_stack_next.p4
  extensions/p4_tests/p4_16/stf/header_stack_strided_alloc1.p4
  )

p4c_add_xfail_reason("tofino5"
  "Compiler Bug: Only 1 16-bit match value is currently supported"
  extensions/p4_tests/p4_16/stf/header_stack_strided_alloc2.p4
  extensions/p4_tests/p4_16/stf/lookahead1.p4
  extensions/p4_tests/p4_16/stf/p4c-3551.p4
  extensions/p4_tests/p4_16/stf/simple_l3_acl_disappearing_options.p4
  )

p4c_add_xfail_reason("tofino5"
  "Compiler Bug: Transition cannot have both loop and non-loop next states"
  # Loops are not supported during parser lowering
  extensions/p4_tests/p4_16/stf/parser_counter_12.p4
  extensions/p4_tests/p4_16/stf/parser_loop_1.p4
  extensions/p4_tests/p4_16/stf/parser_loop_2.p4
  extensions/p4_tests/p4_16/stf/parser_loop_3.p4
  extensions/p4_tests/p4_16/stf/parser_loop_4.p4
  )

p4c_add_xfail_reason("tofino5"
  "Assertion|expected packets? on port . not seen"
  extensions/p4_tests/p4_16/stf/varbit_constant.p4
  )

p4c_add_xfail_reason("tofino5"
  "Compiler Bug: Field not created in PhvInfo"
  extensions/p4_tests/p4_16/flatrock/mirror_simple.p4
  )

# *********************************************************************************************** #
# ** TNA tests that "should" work *************************************************************** #
# *********************************************************************************************** #
p4c_add_xfail_reason("tofino5"
  "Compiler Bug: Invalid container allocation"
  # Header field with offset 0 from current pointer is allocated to the middle of W container
  # which means that we would need negative offset to extract the PHE.
  # We can utilize the possibility to swap the bytes when extracting PHE16 or PHE32,
  # but this is currently not implemented.
  extensions/p4_tests/p4_16/stf/failed_elim_valid_bit.p4
  extensions/p4_tests/p4_16/stf/wide_arith_non_64.p4
  )

p4c_add_xfail_reason("tofino5"
  "Compiler Bug: Offset of extract .* source in input buffer .* is lower than offset of destination field"
  # Implementation of extracts into PHEs currently require that the whole header
  # from which we extract the field needs to be after the pointer even if some
  # fields are not extracted
  extensions/p4_tests/p4_16/stf/p4c-2638.p4
  extensions/p4_tests/p4_16/stf/parse_depth_1.p4
  extensions/p4_tests/p4_16/stf/update_checksum_4.p4
  extensions/p4_tests/p4_16/stf/p4c-3055-2.p4
  )

# Unimplemented - support for wide matches
p4c_add_xfail_reason("tofino5"
  "Compiler Bug: Cannot allocate wide RAMS in Flatrock. Invalid size 2"
  extensions/p4_tests/p4_16/stf/cond_checksum_update_4.p4
  extensions/p4_tests/p4_16/stf/p4c-1513.p4
  extensions/p4_tests/p4_16/stf/p4c-3089.p4
  extensions/p4_tests/p4_16/stf/zeros_as_ones.p4
  extensions/p4_tests/p4_16/stf/p4c-2772.p4
  extensions/p4_tests/p4_16/stf/auto_init_meta2.p4
  extensions/p4_tests/p4_16/stf/parser_extract_upcast.p4
  extensions/p4_tests/p4_16/stf/p4c-4855.p4
  )

p4c_add_xfail_reason("tofino5"
  "Compiler Bug: Emitted field didn't receive a PHV allocation: ig_intr_md_for_tm.icrc_enable"
  #extensions/p4_tests/p4_16/stf/header_stack_next.p4
  #extensions/p4_tests/p4_16/stf/header_stack_strided_alloc1.p4
  #extensions/p4_tests/p4_16/stf/header_stack_strided_alloc2.p4
  #extensions/p4_tests/p4_16/stf/lookahead1.p4
  #extensions/p4_tests/p4_16/stf/p4c-2638.p4
  #extensions/p4_tests/p4_16/stf/p4c-2695.p4
  #extensions/p4_tests/p4_16/stf/parser_counter_12.p4
  #extensions/p4_tests/p4_16/stf/parser_extract_upcast.p4
  #extensions/p4_tests/p4_16/stf/varbit_constant.p4
  #extensions/p4_tests/p4_16/stf/failed_elim_valid_bit.p4
  #extensions/p4_tests/p4_16/stf/wide_arith_non_64.p4
  )

# These may be genuine expected failures due to field packing and extractions
p4c_add_xfail_reason("tofino5"
  "Compiler Bug: Trying to allocate field .* with .* source to container .* with .* source"
  extensions/p4_tests/p4_16/stf/bit_or_in_same_state.p4
  )

p4c_add_xfail_reason("tofino5"
  "error: No format field or table named immediate"
  extensions/p4_tests/p4_16/stf/p4c-4107.p4
  )

p4c_add_xfail_reason("tofino5"
  "error: No phv record ig_md"
  extensions/p4_tests/p4_16/stf/backend_bug1c.p4
  )

#p4c_add_xfail_reason("tofino5"
#  "Flatrock .* not implemented yet"
#  extensions/p4_tests/p4_16/stf/p4c-3470.p4
#  extensions/p4_tests/p4_16/stf/varbit_constant.p4
#  )

p4c_add_xfail_reason("tofino5"
  "Assembler BUG"  # Looping trying to get a valid RANDOM_DYN matrix
  extensions/p4_tests/p4_16/flatrock/dconfig1.p4
  )

p4c_add_xfail_reason("tofino5"
  "Compiler Bug: Could not find hdr_id"
  extensions/p4_tests/p4_16/stf/extract_slice_2.p4
  extensions/p4_tests/p4_16/stf/parser_multi_write_5.p4
  extensions/p4_tests/p4_16/stf/parser_multi_write_8.p4
  )

p4c_add_xfail_reason("tofino5"
  "error: Invalid offset for .* group"
  extensions/p4_tests/p4_16/stf/p4c-1179.p4
  )

p4c_add_xfail_reason("tofino5"
  "expected packets? on port . not seen"
  extensions/p4_tests/p4_16/stf/parser_counter_6.p4
  extensions/p4_tests/p4_16/stf/parser_counter_8.p4
  extensions/p4_tests/p4_16/stf/parser_local_register.p4
  extensions/p4_tests/p4_16/stf/parser_local_register_2.p4
  )

p4c_add_xfail_reason("tofino5"
  "error: Duplicate element"
  # Multiple writes to the same field generate currently multiple extracts
  # which is wrong and assembler reports the error
  extensions/p4_tests/p4_16/stf/parser_multi_write_1.p4
  )

p4c_add_xfail_reason("tofino5"
  "Compiler Bug: Cannot allocate wide RAMS in Flatrock"
  extensions/p4_tests/p4_16/stf/p4c-3659.p4
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

p4c_add_xfail_reason("tofino5"
  "expected packet on port .* not seen"
  # TNA architecture has different size of PORT_METADATA_SIZE than T5NA architecture.
  # Extraction of ingress intrinsic metadata is currently not correctly supported in TNA programs
  # when those metadata are not used anywhere.
  extensions/p4_tests/p4_16/stf/lookahead2.p4
  extensions/p4_tests/p4_16/stf/lookahead3.p4
  extensions/p4_tests/p4_16/stf/update_checksum_3.p4
  extensions/p4_tests/p4_16/stf/p4c-2695.p4
  )

p4c_add_xfail_reason("tofino5"
  "Could not place table .*: The table .* could not fit within the input crossbar"
  extensions/p4_tests/p4_16/stf/metadata_extract.p4
  )

p4c_add_xfail_reason("tofino5"
  "error: Unknown instruction or table add"
  extensions/p4_tests/p4_16/stf/p4c-1504.p4
  )

p4c_add_xfail_reason("tofino5"
  "error: No phv record meta.__IngressP_extra_bridged_metadata.hdr_data_b1"
  extensions/p4_tests/p4_16/stf/p4c-2772-c.p4
  )
  
p4c_add_xfail_reason("tofino5"
  "Assembler BUG"
  extensions/p4_tests/p4_16/stf/update_checksum_6.p4
  )

# *********************************************************************************************** #
# ** \TNA tests that "should" work ************************************************************** #
# *********************************************************************************************** #
