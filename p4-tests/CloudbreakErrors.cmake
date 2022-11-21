# CloudbreakErrors: Tests that are expected to fail
# =============================================
#
# These tests are expected to fail and throw a certain error. They
# should be placed in an 'errors' directory, e.g.,
# p4-tests/p4_16/errors/

p4c_add_xfail_reason("tofino3"
  "error: Because you declared the register SwitchIngress.time_feats.pull_flow to store the type bit<8>.*"
  extensions/p4_tests/p4_16/compile_only/p4c-4612.p4
)

p4c_add_xfail_reason("tofino3"
  "error: Slices assigned to outputs of register actions cannot cross the 32-bit boundary"
  extensions/p4_tests/p4_16/jbay/p4c-4535-invalid-slice.p4
)

p4c_add_xfail_reason("tofino3"
  "error: .* is assigned in state .* but has also previous assignment"
  extensions/p4_tests/p4_16/stf/parser_multi_write_7.p4
)

# P4C-4689
p4c_add_xfail_reason("tofino3"
  "error: Using checksum verify in direct assignment to set ingress::hdr.c.b; is not supported when the left-hand side of the assignment can be written multiple times for one packet."
  extensions/p4_tests/p4_16/stf/parser_multi_write_checksum_verify_2.p4
  extensions/p4_tests/p4_16/stf/parser_multi_write_checksum_verify_3.p4
  extensions/p4_tests/p4_16/stf/parser_multi_write_checksum_verify_4.p4
)
p4c_add_xfail_reason("tofino3"
    "error: It is not possible to deposit multiple checksum residuals into field"
    extensions/p4_tests/p4_16/compile_only/parser_multi_write_checksum_deposit_3.p4
)
