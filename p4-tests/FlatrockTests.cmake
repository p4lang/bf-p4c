set (tofino5_timeout 600)

packet_test_setup_check("fr")

set (P16_T5NA_INCLUDE_PATTERNS "include.*(t5na).p4" "main|common_tna_test")
set (P16_T5NA_FOR_FLATROCK "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/flatrock/*.p4")
p4c_find_tests("${P16_T5NA_FOR_FLATROCK}" P16_T5NA_TESTS INCLUDE "${P16_T5NA_INCLUDE_PATTERNS}" EXCLUDE "${P16_T5NA_EXCLUDE_PATTERNS}")
bfn_find_tests("${P16_T5NA_TESTS}" p16_t5na_tests EXCLUDE "${P16_T5NA_EXCLUDE_PATTERNS}")

include(FlatrockXfail.cmake)
include(FlatrockErrors.cmake)
