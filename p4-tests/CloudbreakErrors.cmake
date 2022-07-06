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
