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
  "error: No phv record meta.__IngressP_extra_bridged_metadata.hdr_data_b1"
  extensions/p4_tests/p4_16/stf/p4c-2772-c.p4
  )

# invalid assembly code
p4c_add_xfail_reason("tofino5"
#  "Invalid slice of 7 bit field immediate"
  "error: Ghost bit .* does not appear on the hash function for way"
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

p4c_add_xfail_reason("tofino5"
  # "error: The table table .* cannot find a valid packing, and cannot be placed. Possibly the match key is too wide given the hardware constraints"
  "The selected pack format for table .* could not fit given the input xbar allocation"
  extensions/p4_tests/p4_16/stf/p4c-3089.p4
  )

p4c_add_xfail_reason("tofino5"
  " error: Index counter_addr for .* cannot be found"
  extensions/p4_tests/p4_16/flatrock/counter1.p4
  )

#p4c_add_xfail_reason("tofino5"
#  ""  -- need a real test case here.
#  extensions/p4_tests/p4_16/flatrock/pac_single_hdr.p4
#  )

p4c_add_xfail_reason("tofino5"
  "error: No format field or table named immediate"
  extensions/p4_tests/p4_16/flatrock/pac_shallow_branch_egress_const.p4
  extensions/p4_tests/p4_16/flatrock/pac_unbal_reconverge_egress_const.p4
  )

p4c_add_xfail_reason("tofino5"
  "error: Syntax error, expecting identifier"
  extensions/p4_tests/p4_16/stf/header_stack_next.p4
  extensions/p4_tests/p4_16/stf/header_stack_strided_alloc1.p4
  extensions/p4_tests/p4_16/stf/header_stack_strided_alloc2.p4
  )

p4c_add_xfail_reason("tofino5"
  "error: Ran out of parser match registers"
  extensions/p4_tests/p4_16/stf/simple_l3_acl_disappearing_options.p4
  )

p4c_add_xfail_reason("tofino5"
  "error: .* too large for operand"
  extensions/p4_tests/p4_16/flatrock/pac_wide_branch_egress_const.p4
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
  #"expected packet on port .* not seen"
  #"Requested byte is out of bounds"
  "BUG:.*eMac don't correctly handle PGR pkts yet!" # in model
#  extensions/p4_tests/p4_16/flatrock/mirror_simple.p4  # see 2023-01-12 dev-env update
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
  extensions/p4_tests/p4_16/stf/lookahead1.p4
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
  extensions/p4_tests/p4_16/stf/p4c-3551.p4
  )

p4c_add_xfail_reason("tofino5"
  # "Compiler Bug: Cannot process pipelines with 6 arguments on Tofino 5"
  "Compiler Bug: Exiting with SIGSEGV"
  extensions/p4_tests/p4_16/stf/auto_init_meta2.p4
  )

# Unimplemented - support for wide matches
p4c_add_xfail_reason("tofino5"
  # "Compiler Bug: Cannot allocate wide RAMS in Flatrock. Invalid size 2"
  "The selected pack format for table .* could not fit given the input xbar allocation"
  extensions/p4_tests/p4_16/stf/cond_checksum_update_4.p4
  extensions/p4_tests/p4_16/stf/p4c-1513.p4
  extensions/p4_tests/p4_16/stf/zeros_as_ones.p4
  extensions/p4_tests/p4_16/stf/p4c-2772.p4
  extensions/p4_tests/p4_16/stf/parser_extract_upcast.p4
  extensions/p4_tests/p4_16/stf/p4c-4855.p4
  extensions/p4_tests/p4_16/stf/p4c-3659.p4
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
  "Compiler Bug: Trying to allocate field .* with .* source to container .* with .* source|Invalid container allocation"
  extensions/p4_tests/p4_16/stf/bit_or_in_same_state.p4
  )

p4c_add_xfail_reason("tofino5"
  "error: No format field or table named immediate"
  extensions/p4_tests/p4_16/stf/p4c-4107.p4
  )

p4c_add_xfail_reason("tofino5"
  "error: No phv record .*"
  extensions/p4_tests/p4_16/stf/backend_bug1c.p4
  extensions/p4_tests/p4_16/stf/p4c-1179.p4
  )

#p4c_add_xfail_reason("tofino5"
#  "Flatrock .* not implemented yet"
#  extensions/p4_tests/p4_16/stf/p4c-3470.p4
#  extensions/p4_tests/p4_16/stf/varbit_constant.p4
#  )

p4c_add_xfail_reason("tofino5"
  "Could not place table .*: The selected pack format for table .* could not fit given the input xbar allocation"
  extensions/p4_tests/p4_16/flatrock/dconfig1.p4
  )

p4c_add_xfail_reason("tofino5"
 "Compiler Bug: Could not find hdr_id"
  extensions/p4_tests/p4_16/stf/extract_slice_2.p4
  )

p4c_add_xfail_reason("tofino5"
  "Compiler Bug: Allocation of field: .* can not be satisfied as it requires to use extraction from packet and other source to the same container"
  extensions/p4_tests/p4_16/stf/parser_multi_write_5.p4
  extensions/p4_tests/p4_16/stf/parser_multi_write_8.p4
  )

p4c_add_xfail_reason("tofino5"
  "expected packets? on port . not seen"
  extensions/p4_tests/p4_16/stf/parser_counter_6.p4
  extensions/p4_tests/p4_16/stf/parser_counter_8.p4
  extensions/p4_tests/p4_16/stf/parser_multi_write_1.p4
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
  "expected packets? on port .* not seen"
  # TNA architecture has different size of PORT_METADATA_SIZE than T5NA architecture.
  # Extraction of ingress intrinsic metadata is currently not correctly supported in TNA programs
  # when those metadata are not used anywhere.
  extensions/p4_tests/p4_16/stf/lookahead2.p4
  extensions/p4_tests/p4_16/stf/lookahead3.p4
  extensions/p4_tests/p4_16/stf/update_checksum_3.p4
  extensions/p4_tests/p4_16/stf/p4c-2695.p4
  extensions/p4_tests/p4_16/stf/parser_local_register.p4
  extensions/p4_tests/p4_16/stf/parser_local_register_2.p4
  )

p4c_add_xfail_reason("tofino5"
  "Compiler Bug: Byte on search bus .* appears as a match byte when no search bus is provided on match"
  extensions/p4_tests/p4_16/stf/metadata_extract.p4
  )

p4c_add_xfail_reason("tofino5"
  "dest must be action data"
  extensions/p4_tests/p4_16/stf/p4c-1504.p4
  extensions/p4_tests/p4_16/flatrock/ealu0.p4
  )

p4c_add_xfail_reason("tofino5"
  "Assembler BUG"
  extensions/p4_tests/p4_16/stf/update_checksum_6.p4
  )

p4c_add_xfail_reason("tofino5"
  "error: cast: values of type 'bit<8>' cannot be implicitly cast to type 'MeterColor_t'"
  extensions/p4_tests/p4_16/stf/meter_dest_16_32_flexible.p4
  )

# P4C-5084
p4c_add_xfail_reason("tofino5"
  "mismatch from expected"
#  extensions/p4_tests/p4_16/flatrock/parser_swap_headers.p4  # see 2023-01-12 dev-env update
#  extensions/p4_tests/p4_16/flatrock/pac_shallow_branch_parser_const.p4  # see 2023-01-12 dev-env update
  )

# Some conditions in egress are not correctly evaluated
p4c_add_xfail_reason("tofino5"
  "mismatch from expected"
#  extensions/p4_tests/p4_16/flatrock/pac_shallow_branch_egress_hdrs.p4  # see 2023-01-12 dev-env update
#  extensions/p4_tests/p4_16/flatrock/pac_unbal_reconverge_egress_hdrs.p4  # see 2023-01-12 dev-env update
  )


# *********************************************************************************************** #
# ** \TNA tests that "should" work ************************************************************** #
# *********************************************************************************************** #

# 2023-01-12 dev-env update
p4c_add_xfail_reason("tofino5"
  "Deparser-.* bad configuration.  PBO TCAM match but header 0x[0-9a-f]* NOT present in HdrPtrs. Will drop"
  extensions/p4_tests/p4_16/flatrock/cuckoo-lamb-default1.p4
  extensions/p4_tests/p4_16/flatrock/direct0.p4
  extensions/p4_tests/p4_16/flatrock/direct1.p4
  extensions/p4_tests/p4_16/flatrock/direct_actiondata1.p4
  extensions/p4_tests/p4_16/flatrock/exact0.p4
  extensions/p4_tests/p4_16/flatrock/exact1.p4
  extensions/p4_tests/p4_16/flatrock/exact3.p4
  extensions/p4_tests/p4_16/flatrock/gateway1.p4
  extensions/p4_tests/p4_16/flatrock/gateway1i.p4
  extensions/p4_tests/p4_16/flatrock/gateway2.p4
  extensions/p4_tests/p4_16/flatrock/gateway2i.p4
  extensions/p4_tests/p4_16/flatrock/gateway3.p4
  extensions/p4_tests/p4_16/flatrock/gateway4.p4
  extensions/p4_tests/p4_16/flatrock/mcast_simple.p4
  extensions/p4_tests/p4_16/flatrock/mirror_simple.p4
  extensions/p4_tests/p4_16/flatrock/pac_shallow_branch_egress_hdrs.p4
  extensions/p4_tests/p4_16/flatrock/pac_shallow_branch_parser_const.p4
  extensions/p4_tests/p4_16/flatrock/pac_shallow_branch_swap_hdrs.p4
  extensions/p4_tests/p4_16/flatrock/pac_unbal_reconverge_egress_hdrs.p4
  extensions/p4_tests/p4_16/flatrock/pac_unbal_reconverge_swap_hdrs.p4
  extensions/p4_tests/p4_16/flatrock/pac_wide_branch_swap_hdrs.p4
  extensions/p4_tests/p4_16/flatrock/pac_single_hdr.p4
  extensions/p4_tests/p4_16/flatrock/pac_trivial.p4
  extensions/p4_tests/p4_16/flatrock/parser_constant_1.p4
  extensions/p4_tests/p4_16/flatrock/parser_swap_headers.p4
  extensions/p4_tests/p4_16/flatrock/passthrough.p4
  extensions/p4_tests/p4_16/flatrock/ternary1.p4
  extensions/p4_tests/p4_16/flatrock/ternary2.p4
  extensions/p4_tests/p4_16/flatrock/ternary3.p4
)
p4c_add_xfail_reason("tofino5"
  "Dropping packet=0x[0-9a-f]* at iTM. [(]does NOT output anywhere[)]"
  extensions/p4_tests/p4_16/flatrock/exact4.p4
)
