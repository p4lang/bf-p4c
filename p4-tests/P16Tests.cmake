# XFAILS: tests that *temporarily* fail
# =====================================
#
# Xfails are _temporary_ failures: the tests should work but we haven't fixed
# the compiler yet.
#
# Tests that are _always_ expected to fail should be placed in an 'errors'
# directory, e.g., p4-tests/p4_16/errors/

# FIXME -- mostly missing header files -- utils.h, trivial_parser.h, etc
# FIXME -- need to add explicit -I args to the tests?
set (P4_XFAIL_TESTS
  extensions/p4_tests/p4_16/compile_only/clone-bmv2.p4
  extensions/p4_tests/p4_16/compile_only/clone-bmv2-i2e-and-e2e.p4
  extensions/p4_tests/p4_16/compile_only/filters.p4
  extensions/p4_tests/p4_16/compile_only/flex_packing_pvs_switch.p4
  extensions/p4_tests/p4_16/compile_only/flex_packing_switch.p4
  extensions/p4_tests/p4_16/compile_only/idletime.p4
  extensions/p4_tests/p4_16/compile_only/indirect_filters.p4
  extensions/p4_tests/p4_16/compile_only/ipv6_tlv.p4
  extensions/p4_tests/p4_16/compile_only/meters_0.p4
  extensions/p4_tests/p4_16/compile_only/meters_shared.p4
  extensions/p4_tests/p4_16/compile_only/net_flow.p4
  extensions/p4_tests/p4_16/compile_only/serializer-1446.p4
  extensions/p4_tests/p4_16/compile_only/serializer2.p4
  extensions/p4_tests/p4_16/compile_only/serializer3.p4
  extensions/p4_tests/p4_16/compile_only/serializer.p4
  extensions/p4_tests/p4_16/compile_only/serializer-struct.p4
  extensions/p4_tests/p4_16/compile_only/simple_32q.p4
  extensions/p4_tests/p4_16/stf/stateful5-psa.p4
  extensions/p4_tests/p4_16/ptf/hash_concat.p4
  extensions/p4_tests/p4_16/ptf/inner_checksum.p4
  extensions/p4_tests/p4_16/ptf/ipv4_checksum.p4
  extensions/p4_tests/p4_16/ptf/ixbar_expr3.p4
  extensions/p4_tests/p4_16/ptf/math_unit1.p4
  extensions/p4_tests/p4_16/ptf/math_unit2.p4
  extensions/p4_tests/p4_16/stf/hash_concat.p4
  extensions/p4_tests/p4_16/stf/ixbar_expr1.p4
  extensions/p4_tests/p4_16/stf/ixbar_expr2.p4
  extensions/p4_tests/p4_16/stf/ixbar_expr3.p4
  extensions/p4_tests/p4_16/stf/math_unit1.p4
  extensions/p4_tests/p4_16/stf/math_unit2.p4
  extensions/p4_tests/p4_16/stf/math_unit3.p4
  extensions/p4_tests/p4_16/stf/onlab_packet_io.p4
  extensions/p4_tests/p4_16/stf/sful_sel1.p4
  extensions/p4_tests/p4_16/stf/stateful4.p4
  extensions/p4_tests/p4_16/stf/stateful5.p4
  extensions/p4_tests/p4_16/stf/stateful6.p4
  extensions/p4_tests/p4_16/stf/stateful7.p4
  )


set (P16_TEST_SUITES
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/compile_only/*.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/stf/*.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/ptf/*.p4
  )
set (P4TEST_DRIVER ${P4C_SOURCE_DIR}/backends/p4test/run-p4-sample.py)
p4c_add_tests("p4" ${P4TEST_DRIVER} "${P16_TEST_SUITES}" "${P4_XFAIL_TESTS};${P4_XFAIL_TESTS_INTERNAL}"
  "-I${CMAKE_CURRENT_SOURCE_DIR}/p4_16/includes")

# tests created automatically for the "p4" target which doesn't support TNA
p4c_add_xfail_reason("p4"
  "error: #error Target does not support tofino.* native architecture"
  extensions/p4_tests/p4_16/compile_only/tagalong_mdinit_switch.p4
  extensions/p4_tests/p4_16/compile_only/multiple_apply3.p4
  extensions/p4_tests/p4_16/compile_only/varbit_constant_lengths.p4
  extensions/p4_tests/p4_16/compile_only/parser_local_variable.p4
  extensions/p4_tests/p4_16/compile_only/too_many_ternary_match_key_bits.p4
  extensions/p4_tests/p4_16/compile_only/all_dep_edges.p4
  extensions/p4_tests/p4_16/compile_only/parse_srv6_fast.p4
  extensions/p4_tests/p4_16/compile_only/static_entries_const_prop.p4
  extensions/p4_tests/p4_16/compile_only/checksum_neg_test2.p4
  extensions/p4_tests/p4_16/compile_only/multiple_apply2.p4
  extensions/p4_tests/p4_16/compile_only/simple_l3_acl_varbit_middle.p4
  extensions/p4_tests/p4_16/compile_only/direct_register_struct.p4
  extensions/p4_tests/p4_16/compile_only/parser_match_3.p4
  extensions/p4_tests/p4_16/compile_only/next_table_issue1.p4
  extensions/p4_tests/p4_16/compile_only/checksum_neg_test4.p4
  extensions/p4_tests/p4_16/compile_only/checksum_neg_test1.p4
  extensions/p4_tests/p4_16/compile_only/atcam_match3.p4
  extensions/p4_tests/p4_16/compile_only/atcam_match_wide1-neg.p4
  extensions/p4_tests/p4_16/compile_only/hit_miss_gw1.p4
  extensions/p4_tests/p4_16/compile_only/empty_header_stack.p4
  extensions/p4_tests/p4_16/compile_only/tcam_no_versioning.p4
  extensions/p4_tests/p4_16/compile_only/neg_test_1_lpf_constant_param.p4
  extensions/p4_tests/p4_16/compile_only/atcam_match_extern.p4
  extensions/p4_tests/p4_16/compile_only/default_actions.p4
  extensions/p4_tests/p4_16/compile_only/atcam_match5.p4
  extensions/p4_tests/p4_16/compile_only/too_many_pov_bits.p4
  extensions/p4_tests/p4_16/compile_only/atcam_match1.p4
  extensions/p4_tests/p4_16/compile_only/hash_packing_1.p4
  extensions/p4_tests/p4_16/compile_only/parser_match_17.p4
  extensions/p4_tests/p4_16/compile_only/parser_match_16.p4
  extensions/p4_tests/p4_16/compile_only/bare_else_deparser.p4
  extensions/p4_tests/p4_16/compile_only/pvs_tna.p4
  extensions/p4_tests/p4_16/compile_only/tcp_option_mss.p4
  extensions/p4_tests/p4_16/compile_only/backfill1.p4
  extensions/p4_tests/p4_16/compile_only/register.p4
  extensions/p4_tests/p4_16/compile_only/simple_l3_nexthop_ipv6_options.p4
  extensions/p4_tests/p4_16/compile_only/simple_l3_csum_varbit_v2.p4
  extensions/p4_tests/p4_16/compile_only/inline_subparser.p4
  extensions/p4_tests/p4_16/compile_only/match_key_slices.p4
  extensions/p4_tests/p4_16/compile_only/parser_multi_write_11.p4
  extensions/p4_tests/p4_16/compile_only/parser_match_14.p4
  extensions/p4_tests/p4_16/compile_only/ssub_illegal_pack.p4
  extensions/p4_tests/p4_16/compile_only/checksum_neg_test3.p4
  extensions/p4_tests/p4_16/compile_only/parser_match_15.p4
  extensions/p4_tests/p4_16/compile_only/static_entries2.p4
  extensions/p4_tests/p4_16/compile_only/clot-alloc-phv-pack.p4
  extensions/p4_tests/p4_16/compile_only/state_split1.p4
  extensions/p4_tests/p4_16/compile_only/atcam_match2.p4
  extensions/p4_tests/p4_16/compile_only/atcam_match_wide1.p4
  extensions/p4_tests/p4_16/compile_only/direct_register.p4
  extensions/p4_tests/p4_16/compile_only/lrn1.p4
  extensions/p4_tests/p4_16/compile_only/multi-constraint.p4
  extensions/p4_tests/p4_16/compile_only/proxy_hash.p4
  extensions/p4_tests/p4_16/compile_only/simple_l3_mcast.p4
  extensions/p4_tests/p4_16/compile_only/parser_match_12.p4
  extensions/p4_tests/p4_16/compile_only/varbit_in_middle.p4
  extensions/p4_tests/p4_16/compile_only/action_profile.p4
  extensions/p4_tests/p4_16/compile_only/deparse-zero-clustering.p4
  extensions/p4_tests/p4_16/compile_only/all_ctrl_edges.p4
  extensions/p4_tests/p4_16/compile_only/placement_priority.p4
  extensions/p4_tests/p4_16/compile_only/dkm_invalid.p4
  extensions/p4_tests/p4_16/compile_only/mod_cond_variants.p4
  extensions/p4_tests/p4_16/compile_only/atcam_match4.p4
  extensions/p4_tests/p4_16/compile_only/static_entries_over_multiple_stages.p4
  extensions/p4_tests/p4_16/stf/parser_multi_write_2.p4
  extensions/p4_tests/p4_16/stf/parser_extract_upcast.p4
  extensions/p4_tests/p4_16/stf/extract_const.p4
  extensions/p4_tests/p4_16/stf/lookahead1.p4
  extensions/p4_tests/p4_16/stf/multiple_apply1.p4
  extensions/p4_tests/p4_16/stf/subparser_inline.p4
  extensions/p4_tests/p4_16/stf/cast_widening_set.p4
  extensions/p4_tests/p4_16/stf/parser_counter_stack_1.p4
  extensions/p4_tests/p4_16/stf/parser_counter_8.p4
  extensions/p4_tests/p4_16/stf/hdr_len_inc_stop_3.p4
  extensions/p4_tests/p4_16/stf/zeros_as_ones.p4
  extensions/p4_tests/p4_16/stf/update_checksum_6.p4
  extensions/p4_tests/p4_16/stf/clot-multi-state.p4
  extensions/p4_tests/p4_16/stf/byte-rotate-merge.p4
  extensions/p4_tests/p4_16/stf/stateful10.p4
  extensions/p4_tests/p4_16/stf/hdr_len_inc_stop_2.p4
  extensions/p4_tests/p4_16/stf/simple_l3_acl_disappearing_options.p4
  extensions/p4_tests/p4_16/stf/arith_compare.p4
  extensions/p4_tests/p4_16/stf/meta_packing.p4
  extensions/p4_tests/p4_16/stf/update_checksum_3.p4
  extensions/p4_tests/p4_16/stf/simple_l3_acl.p4
  extensions/p4_tests/p4_16/stf/parser_scratch_reg_2.p4
  extensions/p4_tests/p4_16/stf/parser_scratch_reg_3.p4
  extensions/p4_tests/p4_16/stf/parser_scratch_reg_4.p4
  extensions/p4_tests/p4_16/stf/parser_scratch_reg_5.p4
  extensions/p4_tests/p4_16/stf/parser_scratch_reg_6.p4
  extensions/p4_tests/p4_16/stf/parser_scratch_reg_7.p4
  extensions/p4_tests/p4_16/stf/parser_scratch_reg_8.p4
  extensions/p4_tests/p4_16/stf/cond_checksum_update_4.p4
  extensions/p4_tests/p4_16/stf/parser_multi_write_6.p4
  extensions/p4_tests/p4_16/stf/exit2.p4
  extensions/p4_tests/p4_16/stf/parser_multi_write_8.p4
  extensions/p4_tests/p4_16/stf/math_unit4.p4
  extensions/p4_tests/p4_16/stf/parser_multi_write_4.p4
  extensions/p4_tests/p4_16/stf/cast_narrowing_set.p4
  extensions/p4_tests/p4_16/stf/parser_counter_10.p4
  extensions/p4_tests/p4_16/stf/parser_error.p4
  extensions/p4_tests/p4_16/stf/residual_checksum_hdr_end_pos.p4
  extensions/p4_tests/p4_16/stf/update_checksum_5.p4
  extensions/p4_tests/p4_16/stf/parallel_chain0.p4
  extensions/p4_tests/p4_16/stf/container_dependency.p4
  extensions/p4_tests/p4_16/stf/parser_counter_11.p4
  extensions/p4_tests/p4_16/stf/parser_counter_12.p4
  extensions/p4_tests/p4_16/stf/parser_loop_1.p4
  extensions/p4_tests/p4_16/stf/verify_checksum_3.p4
  extensions/p4_tests/p4_16/stf/header_stack_checksum.p4
  extensions/p4_tests/p4_16/stf/update_checksum_1.p4
  extensions/p4_tests/p4_16/stf/stateful8.p4
  extensions/p4_tests/p4_16/stf/extract_slice_2.p4
  extensions/p4_tests/p4_16/stf/lookahead3.p4
  extensions/p4_tests/p4_16/stf/parser_counter_6.p4
  extensions/p4_tests/p4_16/stf/parser_multi_write_3.p4
  extensions/p4_tests/p4_16/stf/parser_loop_4.p4
  extensions/p4_tests/p4_16/stf/sful_enum_out1.p4
  extensions/p4_tests/p4_16/stf/match_key_slices.p4
  extensions/p4_tests/p4_16/stf/parser_scratch_reg_1.p4
  extensions/p4_tests/p4_16/stf/lookahead4.p4
  extensions/p4_tests/p4_16/stf/exit1.p4
  extensions/p4_tests/p4_16/stf/min_max.p4
  extensions/p4_tests/p4_16/stf/parser_multi_write_1.p4
  extensions/p4_tests/p4_16/stf/hdr_len_inc_stop_1.p4
  extensions/p4_tests/p4_16/stf/meta_overlay_2.p4
  extensions/p4_tests/p4_16/stf/parser_loop_3.p4
  extensions/p4_tests/p4_16/stf/update_checksum_2.p4
  extensions/p4_tests/p4_16/stf/test_pragma_stage.p4
  extensions/p4_tests/p4_16/stf/parser_multi_write_5.p4
  extensions/p4_tests/p4_16/stf/lookahead2.p4
  extensions/p4_tests/p4_16/stf/parser_counter_7.p4
  extensions/p4_tests/p4_16/stf/meta_overlay_1.p4
  extensions/p4_tests/p4_16/stf/cast_narrowing_add.p4
  extensions/p4_tests/p4_16/stf/hash_calculation_constants.p4
  extensions/p4_tests/p4_16/stf/parser_loop_2.p4
  extensions/p4_tests/p4_16/stf/parser_counter_9.p4
  extensions/p4_tests/p4_16/stf/metadata_extract.p4
  extensions/p4_tests/p4_16/stf/decaf_11.p4
  extensions/p4_tests/p4_16/stf/symmetric_hash.p4
  extensions/p4_tests/p4_16/stf/parallel_chain1.p4
  extensions/p4_tests/p4_16/stf/update_checksum_4.p4
  extensions/p4_tests/p4_16/stf/tcp_option_mss_4_byte_chunks.p4
  extensions/p4_tests/p4_16/stf/parser_multi_write_10.p4
  extensions/p4_tests/p4_16/stf/misc_1.p4
  extensions/p4_tests/p4_16/stf/backend_bug1c.p4
  extensions/p4_tests/p4_16/stf/wide_arith_non_64.p4
  extensions/p4_tests/p4_16/stf/failed_elim_valid_bit.p4
  extensions/p4_tests/p4_16/stf/funnel_shift.p4
  extensions/p4_tests/p4_16/stf/overwriting_bitwise.p4
  extensions/p4_tests/p4_16/ptf/static_entries.p4
  extensions/p4_tests/p4_16/ptf/checksum_if_else_cond.p4
  extensions/p4_tests/p4_16/ptf/checksum_splitting.p4
  extensions/p4_tests/p4_16/ptf/parse_recursive_ipv4.p4
  extensions/p4_tests/p4_16/ptf/digest_tna.p4
  extensions/p4_tests/p4_16/ptf/varbit_checksum.p4
  extensions/p4_tests/p4_16/ptf/tofino2_a0_header_checksum_workaround.p4
  extensions/p4_tests/p4_16/ptf/test_with_split_csum_state.p4
  extensions/p4_tests/p4_16/ptf/udpv4_and_v6_checksum.p4
  extensions/p4_tests/p4_16/ptf/tna_parser_counter.p4
  extensions/p4_tests/p4_16/ptf/mirror_constants.p4
  extensions/p4_tests/p4_16/ptf/hash_extern_xor.p4
  extensions/p4_tests/p4_16/ptf/hash_field_expression.p4
  extensions/p4_tests/p4_16/ptf/hash_field_expression_sym.p4
  extensions/p4_tests/p4_16/stf/meter_dest_16_32.p4
  extensions/p4_tests/p4_16/stf/meter_dest_16_32_flexible.p4
)


# tests which aren't supported by bf-p4c
# =======================================

p4c_add_xfail_reason("tofino"
  #"error: Wide operations not supported in Stateful ALU, will only operate on bottom 32 bits"
  "error: Non-mutualy exclusive actions .* trying to use "
  testdata/p4_16_samples/psa-register-read-write-bmv2.p4
  testdata/p4_16_samples/psa-example-register2-bmv2.p4
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
