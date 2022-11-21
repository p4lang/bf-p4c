set (tofino5_timeout ${default_test_timeout})

packet_test_setup_check("ftr")
simple_test_setup_check("ftr")

set (P16_T5NA_INCLUDE_PATTERNS "include.*(t5na).p4" "main|common_t5na_test")
set (P16_T5NA_FOR_FLATROCK "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/flatrock/*.p4")
set (P16_T5NA_EXCLUDE_FILES
    # Exclude files here
    )
p4c_find_tests("${P16_T5NA_FOR_FLATROCK}" P16_T5NA_TESTS INCLUDE "${P16_T5NA_INCLUDE_PATTERNS}" EXCLUDE "${P16_T5NA_EXCLUDE_PATTERNS}")
bfn_find_tests("${P16_T5NA_TESTS}" p16_t5na_tests EXCLUDE "${P16_T5NA_EXCLUDE_FILES}")
set (flatrock_t5na_tests ${flatrock_t5na_tests} ${p16_t5na_tests})
p4c_add_bf_backend_tests("tofino5" "ftr" "t5na" "base" "${flatrock_t5na_tests}" "-I${CMAKE_CURRENT_SOURCE_DIR}/p4_16/includes")

# TNA tests for ftr
set (P16_TNA_INCLUDE_PATTERNS "include.*(tna).p4" "main|common_t5na_test")
set (P16_TNA_FOR_FLATROCK "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/stf/*.p4")
set (P16_TNA_EXCLUDE_FILES
    # Most likely PortID width mismatch
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/stf/brig-1218\\.p4"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/stf/brig-658\\.p4"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/stf/cast_narrowing_add\\.p4"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/stf/cast_narrowing_set\\.p4"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/stf/cast_widening_add\\.p4"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/stf/cast_widening_set\\.p4"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/stf/container_dependency\\.p4"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/stf/hash-concat\\.p4"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/stf/hash_calculation_constants\\.p4"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/stf/match_key_slices\\.p4"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/stf/meta_overlay_1\\.p4"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/stf/meta_overlay_2\\.p4"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/stf/meta_packing\\.p4"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/stf/multiple_apply1\\.p4"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/stf/p4c-1426\\.p4"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/stf/p4c-1514\\.p4"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/stf/p4c-1515\\.p4"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/stf/p4c-1620\\.p4"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/stf/p4c-2744\\.p4"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/stf/p4c-2985\\.p4"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/stf/p4c-3055-1\\.p4"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/stf/parse_depth_2\\.p4"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/stf/parser_counter_7\\.p4"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/stf/parser_counter_9\\.p4"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/stf/parser_counter_10\\.p4"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/stf/parser_counter_11\\.p4"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/stf/parser_multi_write_2\\.p4"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/stf/parser_multi_write_3\\.p4"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/stf/parser_multi_write_4\\.p4"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/stf/parser_multi_write_6\\.p4"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/stf/parser_multi_write_7\\.p4"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/stf/parser_multi_write_checksum_deposit_1\\.p4"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/stf/parser_multi_write_checksum_deposit_2\\.p4"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/compile_only/parser_multi_write_checksum_deposit_3\\.p4"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/stf/parser_multi_write_checksum_verify_1\\.p4"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/stf/parser_multi_write_checksum_verify_2\\.p4"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/stf/parser_multi_write_checksum_verify_3\\.p4"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/stf/parser_multi_write_checksum_verify_4\\.p4"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/stf/parser_multi_write_checksum_verify_5\\.p4"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/stf/parser_multi_write_checksum_verify_6\\.p4"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/stf/parser_multi_write_checksum_verify_7\\.p4"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/stf/residual_checksum_hdr_end_pos\\.p4"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/stf/subparser_inline\\.p4"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/stf/symmetric_hash\\.p4"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/stf/tcp_option_mss_4_byte_chunks\\.p4"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/stf/varbit_const_length\\.p4"
    # Wrong emits (probably on different headers)
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/stf/byte-rotate-merge\\.p4"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/stf/p4c-2722\\.p4"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/stf/simple_l3_acl\\.p4"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/stf/varbit_noninjective\\.p4"
    # Using field that no longer exists (part of removed/changed
    # metadata)
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/stf/constant_hash\\.p4"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/stf/decaf_11\\.p4"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/stf/drv-5621\\.p4"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/stf/p4c-4138\\.p4"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/stf/simple_hash_16\\.p4"
    # Using header that no longer exists (part of removed/changed
    # metadata)
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/stf/p4c-1745\\.p4"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/stf/p4c-2212\\.p4"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/stf/p4c-2738\\.p4"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/stf/parser_error\\.p4"
    # SetValid/Invalid
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/stf/p4c-2911-2\\.p4"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/stf/p4c-2911\\.p4"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/stf/update_checksum_2b\\.p4"
    # FIXME: These tests cause bf-asm to enter an infinite loop
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/stf/funnel_shift\\.p4"
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/stf/p4c-3470\\.p4"
    )
p4c_find_tests("${P16_TNA_FOR_FLATROCK}" P16_TNA_TESTS INCLUDE "${P16_TNA_INCLUDE_PATTERNS}" EXCLUDE "${P16_TNA_EXCLUDE_PATTERNS}")
bfn_find_tests("${P16_TNA_TESTS}" p16_tna_tests EXCLUDE "${P16_TNA_EXCLUDE_FILES}")
set (flatrock_tna_tests ${flatrock_tna_tests} ${p16_tna_tests})
p4c_add_bf_backend_tests("tofino5" "ftr" "tna" "base" "${flatrock_tna_tests}" "-I${CMAKE_CURRENT_SOURCE_DIR}/p4_16/includes")

include(FlatrockXfail.cmake)
include(FlatrockErrors.cmake)
