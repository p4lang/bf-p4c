# XFAILS: tests that *temporarily* fail
# =====================================
#
# Xfails are _temporary_ failures: the tests should work but we haven't fixed
# the compiler yet.
#
# Tests that are _always_ expected to fail should be placed in an 'errors'
# directory, e.g., p4-tests/p4_16/errors/, and added to TofinoErrors.cmake
#
#
# Some of these failures are still P4 v1.0 front-end bugs.
# Others are due to non-standard extensions to P4:
# The *meter* tests use direct meters and execute_meter calls with 4 arguments (not in spec)
# The *recircualte* tests use a different (non standard?) reciculate primitive
# The *stateful* tests use extensions to P4 not in spec
# FlexCounter, action_profile use a non-standard Algorithm
# TwoReferences invokes a table twice - maybe it should become a negative test?
# *range* match type is not supported by BMv2 (used also in error_detection*.p4)
set (TOFINO_XFAIL_TESTS # this is intentionally empty because xfails should be added with a reason.
  # look for the failure message in this file and add to an existing ticket
  # or open a new one.
  )

# Tests that run packets:
# Better to have these at the beginning of the file so that we
# do not overwrite any of the compilation errors.

if (PTF_REQUIREMENTS_MET)

# DRV-2380
  p4c_add_xfail_reason("tofino"
    "TTransportException"
    extensions/p4_tests/internal/p4-programs/programs/perf_test_alpm/perf_test_alpm.p4
    )

endif() # PTF_REQUIREMENTS_MET


# add the failures with no reason
p4c_add_xfail_reason("tofino" "" ${TOFINO_XFAIL_TESTS})

p4c_add_xfail_reason("tofino"
  "the following .* not written in .* will be overwritten illegally|slice list is not byte-sized"
  switch_msdc_l3
  )

p4c_add_xfail_reason("tofino"
  "error.*tofino supports up to 12 stages|error.*table allocation.*failed"
  extensions/p4_tests/p4_16/internal/p4c-3417.p4
)

p4c_add_xfail_reason("tofino"
  "error.*tofino supports up to 12 stages"
  extensions/p4_tests/p4_16/internal/customer/extreme/p4c-1797-1.p4
)

# P4C-1400, P4C-1123
p4c_add_xfail_reason("tofino"
  "NameError: name 'step' is not defined"
  extensions/p4_tests/internal/p4-programs/internal_p4_14/mau_test/mau_test.p4
)

p4c_add_xfail_reason("tofino"
  "Did not receive pkt on 2"
  smoketest_switch_dtel_int_spine_dtel_INTL45_Transit_DoDTest
  smoketest_switch_dtel_int_spine_dtel_MirrorOnDropDoDTest
  smoketest_switch_dtel_int_spine_dtel_QueueReport_DoD_Test
  )

p4c_add_xfail_reason("tofino"
  "A packet was received on device"
  smoketest_switch_ent_dc_general_egress_acl
  )

p4c_add_xfail_reason("tofino"
  "Conditions in an action must be simple comparisons of an action data parameter"
  extensions/p4_tests/p4_16/internal/customer/extreme/p4c-1672-1.p4
)

p4c_add_xfail_reason("tofino"
  "This action requires hash, which can only be done through the hit pathway"
  extensions/p4_tests/p4_14/internal/test_config_101_switch_msdc.p4
)

p4c_add_xfail_reason("tofino"
  "Cannot unify type"
  extensions/p4_tests/p4_16/internal/fabric-psa/fabric.p4
)

# END: XFAILs with translation

p4c_add_xfail_reason("tofino"
  "error: .*: action spanning multiple stages."
  extensions/p4_tests/p4_16/internal/p4c-2336.p4
  )

# P4C-1067
# Expected failure, negative test.
p4c_add_xfail_reason("tofino"
  "Operands of arithmetic operations cannot be greater than 64 bits"
  extensions/p4_tests/p4_16/internal/customer/jeju/p4c-1067-neg.p4
)

# P4C-1067
# Expected failure, negative test.
p4c_add_xfail_reason("tofino"
  "Operand field bit .* of wide arithmetic operation cannot have even and odd container placement constraints"
  extensions/p4_tests/p4_16/internal/customer/jeju/p4c-1067-neg2.p4
)

# Negative test
p4c_add_xfail_reason("tofino"
  "Unsupported unconditional .*.emit"
  extensions/p4_tests/p4_16/internal/brig-neg-1259.p4
)

# Negative test. Directly attached resources (other than action data)
# are not allowed for ATCAM tables.
p4c_add_xfail_reason("tofino"
  "error.*The ability to split directly addressed counters/meters/stateful resources across multiple logical tables of an algorithmic tcam match table is not currently supported.*"
  extensions/p4_tests/p4_16/internal/p4c-1601-neg.p4
)

p4c_add_xfail_reason("tofino"
  "error.*This program violates action constraints imposed by Tofino.|ACTION_CANNOT_BE_SYNTHESIZED"
  # Negative tests for violation of action constraints.
  extensions/p4_tests/p4_16/internal/customer/kaloom/p4c-1299.p4
)

p4c_add_xfail_reason("tofino"
  "error.*This program violates action constraints imposed by Tofino."
# Negative tests for violation of action constraints.
  extensions/p4_tests/p4_16/internal/customer/noviflow/p4c-1288.p4
)

# P4C-1451 -- requires action splitting to avoid the error
p4c_add_xfail_reason("tofino"
  "Action Data Argument .* cannot be used in a hash generation expression"
  extensions/p4_tests/p4_14/internal/customer/barefoot_academy/p4c-1451.p4
)

p4c_add_xfail_reason("tofino"
  "Cannot cast implicitly type"
  P4C-1021-1
)

p4c_add_xfail_reason("tofino"
  "Varbit field size expression evaluates to non byte-aligned value"
  # unbounded varbit expr
  extensions/p4_tests/p4_16/internal/p4c-1478-neg.p4
)

p4c_add_xfail_reason("tofino"
  "Unsupported unconditional .*.emit"
  extensions/p4_tests/p4_16/internal/customer/noviflow/p4c-1588-neg.p4
  )

p4c_add_xfail_reason("tofino"
  "error: Use of uninitialized parser value"
  extensions/p4_tests/p4_16/internal/p4c-1561-neg.p4
)

# P4C-1445, DRV-2667
# Requires Pipe prefix support to avoid duplicate names
p4c_add_xfail_reason("tofino"
  "error: Found .* duplicate name.* in the P4Info"
  extensions/p4_tests/p4_16/internal/brig-814-2.p4
)

# no support for runtime-variable indexing
p4c_add_xfail_reason("tofino"
  "For Tofino, Index of the header stack.*has to be a const value and can't be a variable.*"
  extensions/p4_tests/p4_16/internal/p4c-2056.p4
)
p4c_add_xfail_reason("tofino"
  "error: Exceeded hardware limit for deparser field dictionary entries"
  extensions/p4_tests/p4_16/internal/p4c-1757-neg.p4
)

p4c_add_xfail_reason("tofino"
  "Cannot cast implicitly type"
  extensions/p4_tests/p4_16/internal/brig-305.p4
)

# Expected failures due to program error
p4c_add_xfail_reason("tofino"
  "Dynamic hashes must have the same field list and sets of algorithm for each get call"
  extensions/p4_tests/p4_16/internal/customer/extreme/p4c-1492.p4
  extensions/p4_tests/p4_16/internal/customer/extreme/p4c-1587-a.p4
)

# P4C-1862
p4c_add_xfail_reason("tofino"
  "InvalidTableOperation"
  extensions/p4_tests/internal/p4-programs/internal_p4_14/ecc/ecc.p4
)

# P4C-2091
# Expected failure (negative test)
p4c_add_xfail_reason("tofino"
  "error.*PHV allocation was not successful|ACTION_CANNOT_BE_SYNTHESIZED|NO_SLICING_FOUND"
  extensions/p4_tests/p4_16/internal/p4c-2091.p4
)

# Negative tests to test slice list creation
p4c_add_xfail_reason("tofino"
  "you can introduce padding fields"
  extensions/p4_tests/p4_16/internal/p4c-2025.p4
  extensions/p4_tests/p4_16/internal/p4c-1892.p4
  # parde physical adjacency constraint violated by mau phv_no_pack constraint
)

p4c_add_xfail_reason("tofino"
  "Checksum destination field .* is not byte-aligned in the header. Checksum engine is unable to update a field if it is not byte-aligned"
  extensions/p4_tests/p4_14/internal/p4c-1162.p4
)

# P4 program error
p4c_add_xfail_reason("tofino"
  "Dynamic hashes must have the same field list and sets of algorithm for each get call, as these must change simultaneously at runtime"
  p4c_1585_a
)

# power.p4 PTF failure
# hw team uses it to do some manual testing
# to measure the SRAM and TCAM power draw
# keeping it in regression for compile_only
p4c_add_xfail_reason("tofino"
  "TypeError: %d format: a number is required, not NoneType"
  extensions/p4_tests/internal/p4-programs/internal_p4_14/power/power.p4
)

p4c_add_xfail_reason("tofino"
  "Assignment to a header field in the deparser is only allowed when the source is checksum update, mirror, resubmit or learning digest"
  extensions/p4_tests/p4_16/internal/p4c-1858_neg.p4
  extensions/p4_tests/p4_16/internal/p4c-1867.p4
)

# P4C-2694 - saturating arithmetic exceeding container width
p4c_add_xfail_reason("tofino"
  "Saturating arithmetic operators may not exceed maximum PHV container width"
  extensions/p4_tests/p4_16/internal/p4c-2694.p4
)

p4c_add_xfail_reason("tofino"
  "table.*is applied in multiple places"
  extensions/p4_tests/p4_16/internal/customer/ruijie/p4c-2350-1.p4
)

# Negative test, expected xfail
p4c_add_xfail_reason("tofino"
  "error: table .*: Number of partitions are specified for table .* but the partition index .* is not found"
  extensions/p4_tests/p4_16/internal/p4c-2035-name-neg.p4
)

# P4C-3036
p4c_add_xfail_reason("tofino"
  "AssertionError: Expected packet was not received on device 0, port 0"
  p4c_2249
)

p4c_add_xfail_reason("tofino"
  "Flexible packing bug found"
  # P4C-3042
  extensions/p4_tests/p4_16/internal/p4c-3042.p4
)

p4c_add_xfail_reason("tofino"
  "warning: .*: Padding fields do not need to be explicitly set.* Tofino does not support action data/constant with rotated PHV source at the same time|ACTION_CANNOT_BE_SYNTHESIZED|PHV allocation creates an invalid container action within a Tofino ALU"
  extensions/p4_tests/p4_16/internal/p4c-3453.p4
)

# P4C-3722 - BA102 PTF tests to be fixed and removed from Xfails
p4c_add_xfail_reason("tofino"
  "ERROR:PTF runner:Error when running PTF tests"
   ba102_04-simple_l3_nexthop_simple_l3_nexthop_hash_action
   ba102_17-simple_l3_action_profile_simple_l3_nexthop_hash_action
   ba102_10-simple_l3_mcast_simple_l3_mcast_checksum_full_headers
   ba102_10-simple_l3_mcast_simple_l3_mcast_checksum_split_headers
   ba102_03-simple_l3_rewrite_simple_l3_rewrite_920  # old version
)

p4c_add_xfail_reason("tofino"
    "KeyError: 'SUDO_USER'"
    ba102_02-simple_l3_acl_simple_l3_acl
    ba102_03-simple_l3_rewrite_simple_l3_rewrite_930
)

p4c_add_xfail_reason("tofino"
    "NOT READY YET"
    ba102_17-simple_l3_action_profile_simple_l3_action_profile
    ba102_17-simple_l3_action_profile_simple_l3_no_action_profile
)

# P4C-3402
p4c_add_xfail_reason("tofino"
  "error: Two or more assignments of .* inside the register action .* are not mutually exclusive and thus cannot be implemented in Tofino Stateful ALU."
  extensions/p4_tests/p4_16/internal/p4c-3402.p4
)

p4c_add_xfail_reason("tofino"
  "error: You can only have more than one binary operator in a statement"
  extensions/p4_tests/p4_16/internal/p4c-3402-err.p4
)

# P4C-3765
p4c_add_xfail_reason("tofino"
  "error: Value used in select statement needs to be set from input packet"
  extensions/p4_tests/p4_16/internal/p4c-3765-fail.p4
)
p4c_add_xfail_reason("tofino"
  "error: Unable to resolve extraction source. This is likely due to the source having no absolute offset from the state"
  extensions/p4_tests/p4_16/internal/p4c-2752.p4
)


if (NOT TEST_ALT_PHV_ALLOC)
    # P4C-3914
    p4c_add_xfail_reason("tofino"
      "error: Size of learning quanta is [0-9]+ bytes, greater than the maximum allowed 48 bytes.
Compiler will improve allocation of learning fields in future releases.
Temporary fix: try to apply @pa_container_size pragma to small fields allocated to large container in. Here are possible useful progmas you can try: .*"
      extensions/p4_tests/p4_16/internal/p4c-3914.p4
    )
endif()

p4c_add_xfail_reason("tofino"
  "Compiler Bug: Overwriting definitions"
  extensions/p4_tests/p4_14/internal/customer/surfnet/p4c-1429.p4
)

# P4C-4158 - Expected program output not communicated to us by customer (Arista)
p4c_add_xfail_reason("tofino"
  "AssertionError: Expected packet was not received on device"
  p4c_4158
)

p4c_add_xfail_reason("tofino"
  "not enough operands for .* instruction"
  extensions/p4_tests/p4_14/internal/p4c-4090.p4
)

# P4C-3220
p4c_add_xfail_reason("tofino"
  "error: Incompatible outputs in RegisterAction: mem_lo and mem_hi"
  extensions/p4_tests/p4_16/internal/p4c-3220_1.p4
)

# p4c-4366 test currently does not work due to a model issue
# MODEL-1156
p4c_add_xfail_reason("tofino"
  "AssertionError: Expected packet was not received on"
  p4c_4366
)

# ALT-PHV: tests that do not work yet with the alternative allocator.
# If you make an ALT-PHV test pass (or get close to it but if fails on later
# error), please update the xfails accordingly.
if (TEST_ALT_PHV_ALLOC)
    # PHV fitting
    p4c_add_xfail_reason("tofino"
      "error: PHV fitting failed, [0-9]* clusters cannot be allocated."
      extensions/p4_tests/p4_14/internal/customer/ruijie/p4c-2250.p4
      switch_ent_dc_general # To be removed when switch-14 profiles are removed
    )

    p4c_add_xfail_reason("tofino"
      "ActionAnalysis did not split up container by container"
      extensions/p4_tests/p4_16/internal/customer/arista/obfuscated-nat_vxlan.p4
    )
endif (TEST_ALT_PHV_ALLOC)

# New failures after model/driver update - need to investigate the reason.
p4c_add_xfail_reason("tofino"
  "Invalid arguments"
  p4c_3005
)

# Failure due to old version of p4runtime installed in jarvis docker images -- fixed by
# updating p4runtime.  Can use PYTHONPATH=/mnt/build/_deps/p4runtime-src/py:$PYTHONPATH
p4c_add_xfail_reason("tofino"
  "google.protobuf.text_format.ParseError: .*:3 : Message type \"p4.config.v1.Table\" has no field named \"has_initial_entries\""
  extensions/p4_tests/p4_16/internal/ptf/p4c-5298.p4
)

p4c_add_xfail_reason("tofino"
  "Tofino does not support nested checksum updates in the same deparser"
  basic_switching
)

# JIRA-DOC: P4C-3922 - Fail with both python3 + bf-pktpy and python2 + scapy environments
p4c_add_xfail_reason("tofino"
  "AssertionError: Expected packet was not received"
  tor.p4
)

p4c_add_xfail_reason("tofino"
  "assigned in state"
  extensions/p4_tests/p4_16/internal/p4c-2293-rec.p4
  extensions/p4_tests/p4_16/internal/p4c-2293-no-rec-fail.p4
  extensions/p4_tests/p4_16/internal/p4c-2293-simple-rec.p4
)

p4c_add_xfail_reason("tofino"
  "syntax error"
  extensions/p4_tests/p4_16/errors/register_action_errors.p4
)

# P4C-5334: need to update dev env to incorporating corresponding driver change, wait on Prathima's update.
p4c_add_xfail_reason("tofino"
  "SetValue failed for field:65566 table:pipe.SwitchIngress.example_action_selector Invalid arguments"
  p4_16_programs_tna_action_selector
)
