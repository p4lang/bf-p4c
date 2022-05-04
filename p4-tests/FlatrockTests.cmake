set (tofino5_timeout 600)

packet_test_setup_check("ftr")
# ftr simple harness is not available yet
# simple_test_setup_check("ftr")

set (P16_T5NA_INCLUDE_PATTERNS "include.*(t5na).p4" "main|common_t5na_test")
set (P16_T5NA_FOR_FLATROCK "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/flatrock/*.p4")
set (P16_T5NA_EXCLUDE_FILES
    # Exclude files here
    )
p4c_find_tests("${P16_T5NA_FOR_FLATROCK}" P16_T5NA_TESTS INCLUDE "${P16_T5NA_INCLUDE_PATTERNS}" EXCLUDE "${P16_T5NA_EXCLUDE_PATTERNS}")
bfn_find_tests("${P16_T5NA_TESTS}" p16_t5na_tests EXCLUDE "${P16_T5NA_EXCLUDE_FILES}")
set (flatrock_t5na_tests ${flatrock_t5na_tests} ${p16_t5na_tests})
p4c_add_bf_backend_tests("tofino5" "ftr" "t5na" "base" "${flatrock_t5na_tests}" "-I${CMAKE_CURRENT_SOURCE_DIR}/p4_16/includes")

include(FlatrockXfail.cmake)
include(FlatrockErrors.cmake)
