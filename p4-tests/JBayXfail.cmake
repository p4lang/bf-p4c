set (JBAY_XFAIL_TESTS
  # this is intentionally empty because xfails should be added with a reason.
  # look for the failure message in this file and add to an existing ticket
  # or open a new one.
  )

# All ptf tests xfail due to lack of jbay driver support...
p4c_add_xfail_reason("tofino2"
  "ERROR:PTF runner:Error when running PTF tests"
  extensions/p4_tests/p4_16/ONLab_packetio.p4
  extensions/p4_tests/p4_16/ingress_checksum.p4
  )

# Mirroring direction BOTH not supported on Tofino2 but is used by the P4Runtime
# implementation
p4c_add_xfail_reason("tofino2"
  "Error when creating clone session in target"
  extensions/p4_tests/p4_16/clone_v1model.p4
  )

# These tests compile successfuly and fail in the model when running the STF test
# the reasons need more characterization
if (HARLYN_STF_jbay AND NOT ENABLE_STF2PTF)

  # ingress_port isn't being setup properly (STF harness bug)
  p4c_add_xfail_reason("tofino2"
    ".* expected packet.* on port .* not seen"
    testdata/p4_14_samples/repeater.p4
    testdata/p4_14_samples/gateway1.p4
    testdata/p4_14_samples/gateway2.p4
    testdata/p4_14_samples/gateway3.p4
    testdata/p4_14_samples/gateway4.p4
    testdata/p4_14_samples/basic_routing.p4
    extensions/p4_tests/p4_14/sful_sel1.p4
    extensions/p4_tests/p4_14/overlay_add_header.p4
    extensions/p4_tests/p4_14/uninit_read_1.p4
  )

  p4c_add_xfail_reason("tofino2"
    "mismatch from expected.* at byte .*"
    # clot-phv interaction bug?
    testdata/p4_14_samples/bridge1.p4
    # conditional checksum: JBay needs different treatment
    extensions/p4_tests/p4_14/cond_checksum_update.p4
    # Needs stateful init regs support in simple test harness, this test passes
    # on stf2ptf
    # decaf: needs to work with CLOT allocation
    extensions/p4_tests/p4_14/stateful_init_regs.p4
    extensions/p4_tests/p4_14/deparser_copy_opt_1.p4
    extensions/p4_tests/p4_14/deparser_copy_opt_2.p4
    extensions/p4_tests/p4_14/deparser_copy_opt_3.p4
    )

endif() # HARLYN_STF

# BEGIN: XFAILS that match glass XFAILS
#END: XFAILS that match glass XFAILS

if (ENABLE_STF2PTF AND PTF_REQUIREMENTS_MET)
endif() # ENABLE_STF2PTF AND PTF_REQUIREMENTS_MET

p4c_add_xfail_reason("tofino2"
  "address too large for table"
  testdata/p4_14_samples/saturated-bmv2.p4
)

p4c_add_xfail_reason("tofino2"
  "Ran out of tcam space in .* parser"
  testdata/p4_14_samples/issue583.p4
)

p4c_add_xfail_reason("tofino2"
  "PHV allocation was not successful"
  testdata/p4_14_samples/05-FullTPHV.p4
  testdata/p4_14_samples/06-FullTPHV1.p4
  testdata/p4_14_samples/07-FullTPHV2.p4
  testdata/p4_14_samples/08-FullTPHV3.p4
  switch_dc_basic
  switch_ent_dc_general
)

p4c_add_xfail_reason("tofino2"
  "Wrong number of arguments for method call: packet.extract"
  testdata/p4_14_samples/09-IPv4OptionsUnparsed.p4
  testdata/p4_14_samples/issue781.p4
)

p4c_add_xfail_reason("tofino2"
  "Table .* is applied multiple times, and the next table information cannot correctly propagate through this multiple application"
  testdata/p4_14_samples/16-TwoReferences.p4
)

p4c_add_xfail_reason("tofino2"
  "error: Assignment cannot be supported in the parser"
  testdata/p4_14_samples/axon.p4
)

p4c_add_xfail_reason("tofino2"
  "This action requires hash, which can only be done through the hit pathway"
  testdata/p4_14_samples/acl1.p4
  testdata/p4_14_samples/hash_action_two_same.p4
)

p4c_add_xfail_reason("tofino2"
# Fail on purpose due to indirect tables not being mutually exclusive
  "Tables .* and .* are not mutually exclusive"
  testdata/p4_14_samples/12-Counters.p4
  testdata/p4_14_samples/13-Counters1and2.p4
)

p4c_add_xfail_reason("tofino2"
  "error: standard_metadata.packet_length is not accessible in the ingress pipe"
  testdata/p4_14_samples/queueing.p4
)

p4c_add_xfail_reason("tofino2"
  "error: Could not find declaration for .*"
  testdata/p4_14_samples/copy_to_cpu.p4
  testdata/p4_14_samples/issue1058.p4
  testdata/p4_14_samples/packet_redirect.p4
  testdata/p4_14_samples/resubmit.p4
  testdata/p4_14_samples/simple_nat.p4
  testdata/p4_14_samples/issue-1426.p4
)

p4c_add_xfail_reason("tofino2"
  "Both .* and .* require the .* address hardware, and cannot be on the same table"
  testdata/p4_14_samples/counter.p4
)

p4c_add_xfail_reason("tofino2"
  "Only compile-time constants are supported for hash base offset and max value"
  testdata/p4_14_samples/flowlet_switching.p4
)

p4c_add_xfail_reason("tofino2"
  ": P4_14 extern type not fully supported"
  testdata/p4_14_samples/issue604.p4
)

p4c_add_xfail_reason("tofino2"
  "Structure header ingress_intrinsic_metadata_t does not have a field ucast_egress_port"
  extensions/p4_tests/p4_14/bf_p4c_samples/sai_p4.p4
)

p4c_add_xfail_reason("tofino2"
  "Action profile .* does not have any action data"
  testdata/p4_14_samples/selector0.p4
  extensions/p4_tests/p4_14/bf_p4c_samples/port_vlan_mapping.p4
  testdata/p4_14_samples/const_default_action.p4
)

p4c_add_xfail_reason("tofino2"
  "The action .* manipulates field .* that requires multiple stages from an action"
  testdata/p4_14_samples/action_inline.p4
)

p4c_add_xfail_reason("tofino2"
  "Compiler Bug.*: .*: Cannot find declaration for"
  testdata/p4_14_samples/TLV_parsing.p4
)

p4c_add_xfail_reason("tofino2"
  "Unimplemented compiler support.*: Currently the compiler only supports allocation of meter color"
  testdata/p4_14_samples/meter.p4
  testdata/p4_14_samples/meter1.p4
)

p4c_add_xfail_reason("tofino2"
  "The method call of read and write on a Register is currently not supported in p4c"
  testdata/p4_14_samples/issue894.p4
  testdata/p4_14_samples/register.p4
)

p4c_add_xfail_reason("tofino2"
  "Ran out of parser match registers"
  testdata/p4_14_samples/source_routing.p4
  testdata/p4_14_samples/parser_value_set2.p4
)

# Checksum16 is deprecated
p4c_add_xfail_reason("tofino2"
  "Could not find declaration for"
  extensions/p4_tests/p4_16/ipv4_options.p4
)

p4c_add_xfail_reason("tofino2"
  "warning: Instruction selection creates an instruction that the rest of the compiler cannot correctly interpret"
  extensions/p4_tests/p4_16/brig-42.p4
)

p4c_add_xfail_reason("tofino2"
  "test.IPv4ChecksumVerifyTest ... FAIL"
  extensions/p4_tests/p4_16/ipv4_checksum.p4
)

p4c_add_xfail_reason("tofino2"
  "Can only output full phv registers, not slices, in deparser"
  extensions/p4_tests/p4_16/int_transit.p4
)


# These tests fail at runtime with the driver
if (PTF_REQUIREMENTS_MET)

p4c_add_xfail_reason("tofino2"
  "AssertionError: A packet was received on device .*, port .*, but we expected no packets"
  extensions/p4_tests/p4_16/verify_checksum.p4
)

p4c_add_xfail_reason("tofino2"
  "AssertionError: Expected packet was not received on device .*, port .*"
  extensions/p4_tests/p4_16/ingress_checksum.p4
  extensions/p4_tests/p4_16/ONLab_packetio.p4
  extensions/p4_tests/p4_14/easy_no_match.p4
  fabric.p4
  tor.p4
)

# P4C-1228
p4c_add_xfail_reason("tofino2"
  "OSError: .* No such file or directory"
  extensions/p4_tests/p4_14/p4-tests/programs/multicast_test/multicast_test.p4
  )

endif() # PTF_REQUIREMENTS_MET

# This test is tailored to fill Tofino's PHV.  It is expected to fail on JBay
# until the compiler can take full advantage of all PHV container types.  (And
# maybe even after that.)
p4c_add_xfail_reason("tofino2"
  "PHV allocation was not successful"
  extensions/p4_tests/p4_14/deparser_group_allocation_1.p4
)

p4c_add_xfail_reason("tofino2"
  "Could not place table .*: The table .* could not fit"
   extensions/p4_tests/p4_14/stateful3.p4
   testdata/p4_14_samples/counter5.p4
)

# BRIG-584
p4c_add_xfail_reason("tofino2"
  "Unimplemented compiler support.*: Cannot extract to a field slice in the parser"
  extensions/p4_tests/p4_16/extract_slice.p4
)

p4c_add_xfail_reason("tofino2"
  "./p4c TIMEOUT|condition expression too complex"
  testdata/p4_14_samples/header-stack-ops-bmv2.p4
)

p4c_add_xfail_reason("tofino2"
  "fatal error:.*switchapi/switch_handle.h:.*No such file or directory"
  smoketest_switch_msdc
  smoketest_switch_msdc_set_1
  smoketest_switch_msdc_set_2
  smoketest_switch_msdc_set_3
  smoketest_switch_msdc_set_4
  smoketest_switch_msdc_set_5
  smoketest_switch_msdc_set_6
  smoketest_switch_msdc_set_7
)

# truncate is not supported in jna
p4c_add_xfail_reason("tofino2"
  "Could not find declaration for truncate"
  testdata/p4_14_samples/truncate.p4
)

p4c_add_xfail_reason("tofino2"
  "failed command assembler"
  extensions/p4_tests/p4_14/cond_checksum_update_2.p4
  extensions/p4_tests/p4_14/cond_checksum_update.p4
)

# P4C-1011
p4c_add_xfail_reason("tofino2"
  "Exiting with SIGSEGV"
  extensions/p4_tests/p4_16/bf_p4c_samples/v1model-special-ops-bmv2.p4
)

# P4C-1300
p4c_add_xfail_reason("tofino2"
  "error: no more that 2 clots per state"
  extensions/p4_tests/p4_14/brig-425.p4
)

p4c_add_xfail_reason("tofino2"
  "Compiler Bug.*Total size of containers used for POV allocation is.*"
  switch_ent_dc_general
)

p4c_add_xfail_reason("tofino2"
  "error.*Ran out of constant output slots"
  extensions/p4_tests/p4_14/metadata_mutex_1.p4
)
