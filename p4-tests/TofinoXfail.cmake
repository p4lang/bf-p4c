# Some of these failures are still P4 v1.0 front-end bugs.
# 02-FlexCounter fails with Cannot unify Type(HashAlgorithm) to HashAlgorithm
# Others are due to non-standard extensions to P4:
# The *meter* tests use direct meters and execute_meter calls with 4 arguments (not in spec)
# The *recircualte* tests use a different (non standard?) reciculate primitive
# The *stateful* tests use extensions to P4 not in spec
# FlexCounter, action_profile use a non-standard Algorithm
# TwoReferences invokes a table twice - maybe it should become a negative test?
# *range* match type is not supported by BMv2 (used also in error_detection*.p4)
set (TOFINO_XFAIL_TESTS
  # this is intentionally empty because xfails should be added with a reason.
  # look for the failure message in this file and add to an existing ticket
  # or open a new one.
  )

# These tests compile successfuly and fail in the model when running the STF test
# the reasons need more characterization
if (HARLYN_STF AND NOT ENABLE_STF2PTF)
set (TOFINO_XFAIL_TESTS ${TOFINO_XFAIL_TESTS}
  extensions/p4_tests/p4_14/hash_calculation_32.p4
  testdata/p4_14_samples/counter4.p4
  # Masked table keys ignoring mask in table layout?
  extensions/p4_tests/p4_14/stateful2.p4
  extensions/p4_tests/p4_14/stateful3.p4
  # default drop packet instead of writing to port 0
  testdata/p4_16_samples/issue635-bmv2.p4
  testdata/p4_16_samples/issue655-bmv2.p4
# The STF test fails due to malformed packet data.
# XXX(seth): I haven't had a chance to deeply analyze the problem, but nothing
# looks wrong in the parser or deparser program that we generate. The following
# PHV allocation validation warnings are suggestive:
# warning: Container TW3 contains deparsed header fields, but it has unused bits: ( 22:ingress::h.v<1> I off=0 ref deparsed /t_phv_8,PHV-259;/|t_phv_8,0..0|[0:0]->[TW3](31); )
# warning: Container TW19 contains deparsed header fields, but it has unused bits: ( 44:egress::h.v<1> E off=0 ref deparsed /t_phv_13,PHV-275;/|t_phv_13,0..0|[0:0]->[TW19](31); )

  #Assertion failed: ((bit + field.bit_width - 1)/128U < data.size()), function get_sram_field, file table.cpp, line 60
  testdata/p4_14_samples/exact_match4.p4
  testdata/p4_14_samples/exact_match5.p4
  )

  p4c_add_xfail_reason("tofino"
    "expected packet([s])* on port .* not seen"
    testdata/p4_14_samples/07-MultiProtocol.p4
    testdata/p4_14_samples/gateway4.p4
    testdata/p4_14_samples/hitmiss.p4
    )

  p4c_add_xfail_reason("tofino"
    "mismatch from expected.*at byte 0x"
    extensions/p4_tests/p4_16/stack_valid.p4
    extensions/p4_tests/p4_14/adjust_instr4.p4
    extensions/p4_tests/p4_14/adb_shared2.p4
    testdata/p4_14_samples/ternary_match4.p4
    )

p4c_add_xfail_reason("tofino"
  "corrupt table config json"
  extensions/p4_tests/p4_14/adjust_instr6.p4
  )

endif() # HARLYN_STF

# add the failures with no reason
p4c_add_xfail_reason("tofino" "" ${TOFINO_XFAIL_TESTS})

# tests that no longer fail when enable TNA translation
# possibly due to different PHV allocation
if (NOT ENABLE_TNA)
  # BRIG-136
  # was BRIG-134 for extensions/p4_tests/p4_14/jenkins/alpm_test/alpm_test.p4
  p4c_add_xfail_reason("tofino"
    "No write within a split instruction"
    extensions/p4_tests/p4_14/jenkins/alpm_test/alpm_test.p4
    extensions/p4_tests/p4_14/jenkins/basic_ipv4/basic_ipv4.p4
    extensions/p4_tests/p4_14/jenkins/exm_direct/exm_direct_one.p4
    extensions/p4_tests/p4_14/jenkins/exm_direct_1/exm_direct_1_one.p4
    )
  #BRIG-201
  p4c_add_xfail_reason("tofino"
    "payload ... already in use"
    extensions/p4_tests/p4_14/jenkins/mau_tcam_test/mau_tcam_test.p4
    extensions/p4_tests/p4_14/c1/COMPILER-242/case1679.p4
    )

  p4c_add_xfail_reason("tofino"
    "Too much data for parse matcher"
    testdata/p4_14_samples/copy_to_cpu.p4
    )

  # BRIG-109
  p4c_add_xfail_reason("tofino"
    "error: Cannot resolve computed select"
    testdata/p4_14_samples/queueing.p4
    )

  p4c_add_xfail_reason("tofino"
    "Encountered invalid code in computed checksum control"
    extensions/p4_tests/p4_14/test_checksum.p4
    )

  p4c_add_xfail_reason("tofino"
    "NULL operand 4 for hash"
    testdata/p4_14_samples/flowlet_switching.p4
  )

  p4c_add_xfail_reason("tofino"
    "error: Field is extracted in the parser, but its first container slice has an incompatible alignment"
    )

  p4c_add_xfail_reason("tofino"
    "Input xbar hash.*conflict in"
    extensions/p4_tests/p4_14/test_config_96_hash_data.p4
    )

  p4c_add_xfail_reason("tofino"
    "No PHV allocation for field extracted by the parser"
    testdata/p4_14_samples/packet_redirect.p4
    )

  p4c_add_xfail_reason("tofino"
    "error: Assignment cannot be supported in the parser"
    testdata/p4_14_samples/simple_nat.p4
    testdata/p4_14_samples/TLV_parsing.p4
    )

  # BRIG-109
  p4c_add_xfail_reason("tofino"
    "error: Cannot resolve computed select"
    extensions/p4_tests/p4_14/test_config_294_parser_loop.p4
    )

  p4c_add_xfail_reason("tofino"
    "error: : condition too complex"
    testdata/p4_14_samples/issue894.p4
    )

  # Incorrect P4_14->16 conversion for varbit extract
  p4c_add_xfail_reason("tofino"
    "Wrong number of arguments for method call: packet.extract"
    testdata/p4_14_samples/09-IPv4OptionsUnparsed.p4
    testdata/p4_14_samples/issue781.p4
    )

  p4c_add_xfail_reason("tofino"
    "Wrong number of arguments for method call"
    extensions/p4_tests/p4_14/c2/COMPILER-379/case2210.p4
    )

  p4c_add_xfail_reason("tofino"
    "Header present in IR not under Member"
    testdata/p4_14_samples/resubmit.p4
    )

  p4c_add_xfail_reason("tofino"
    "Wrong number of arguments for method call"
    testdata/p4_16_samples/checksum1-bmv2.p4
  )

endif() # NOT ENABLE_TNA

# Failure for BRIG-44 in JIRA
p4c_add_xfail_reason("tofino"
  "Unhandled expression in BuildGatewayMatch"
  testdata/p4_14_samples/basic_conditionals.p4
  )

# BRIG-136
# was BRIG-134 for extensions/p4_tests/p4_14/jenkins/alpm_test/alpm_test.p4
p4c_add_xfail_reason("tofino"
  "No write within a split instruction"
  extensions/p4_tests/p4_14/jenkins/alpm_test/alpm_test.p4
  extensions/p4_tests/p4_14/jenkins/basic_ipv4/basic_ipv4.p4
  extensions/p4_tests/p4_14/jenkins/exm_direct/exm_direct_one.p4
  extensions/p4_tests/p4_14/jenkins/exm_direct_1/exm_direct_1_one.p4
  )

p4c_add_xfail_reason("tofino"
  "Unrecognized mode of the action selector"
  extensions/p4_tests/p4_14/jenkins/exm_direct/exm_direct_one.p4
  )

# BRIG-101
# was BRIG-147 for extensions/p4_tests/p4_14/adjust_instr6.p4
p4c_add_xfail_reason("tofino"
  "src2 must be phv register"
  extensions/p4_tests/p4_14/c4/COMPILER-549/case2898.p4
  )


# BRIG-103
p4c_add_xfail_reason("tofino"
  "instruction slot [0-9]+ used multiple times in action"
  testdata/p4_14_samples/instruct1.p4
  extensions/p4_tests/p4_14/16-WrongSizeInfiniteLoop.p4
  extensions/p4_tests/p4_14/15-SetMetadata.p4
  extensions/p4_tests/p4_14/instruct1.p4
  extensions/p4_tests/p4_14/action_conflict_2.p4
  )

# BRIG-104
p4c_add_xfail_reason("tofino"
  "Unhandled action bitmask constraint"
  extensions/p4_tests/p4_14/13-IngressEgressConflict.p4
  testdata/p4_14_samples/mac_rewrite.p4
  extensions/p4_tests/p4_14/c1/COMPILER-129/compiler129.p4
  )

# Fails due to invalid action specification
# BRIG-219
p4c_add_xfail_reason("tofino"
  "error: Only part of the container"
  extensions/p4_tests/p4_14/test_config_256_pa_problem_4.p4
  extensions/p4_tests/p4_14/adjust_instr1.p4
  )

# Fails due to complex expressions in the parser that our hardware can't support.
p4c_add_xfail_reason("tofino"
  "error: Assignment cannot be supported in the parser"
  testdata/p4_16_samples/scalarmeta-bmv2.p4
  testdata/p4_16_samples/issue281.p4
  testdata/p4_16_samples/stack_complex-bmv2.p4
  testdata/p4_14_samples/axon.p4
  testdata/p4_16_samples/stack_complex-bmv2.p4
  )

# BRIG-107
p4c_add_xfail_reason("tofino"
  "No field named counter_addr in format"
  testdata/p4_14_samples/13-Counters1and2.p4
  testdata/p4_14_samples/14-Counter.p4
  testdata/p4_16_samples/action_profile-bmv2.p4
  testdata/p4_16_samples/issue297-bmv2.p4
  extensions/p4_tests/p4_14/c1/COMPILER-386/test_config_286_stat_bugs.p4
  )

# BRIG-108
p4c_add_xfail_reason("tofino"
  "No format in action table"
  testdata/p4_14_samples/02-FullPHV1.p4
  testdata/p4_14_samples/03-FullPHV2.p4
  testdata/p4_14_samples/selector0.p4
  testdata/p4_16_samples/action_profile-bmv2.p4
  testdata/p4_16_samples/issue297-bmv2.p4
  )

# BRIG-240
p4c_add_xfail_reason("tofino"
  "Input xbar group.* conflict in stage"
  extensions/p4_tests/p4_14/test_config_197_default_next_table.p4
  extensions/p4_tests/p4_14/test_config_196_hit_miss.p4
  )

# BRIG-109
p4c_add_xfail_reason("tofino"
  "error: Cannot resolve computed select"
  # XXX(seth): This code just uses packet_in.lookahead() in a way which isn't supported yet.
  testdata/p4_16_samples/issue355-bmv2.p4
  )

# varbit extracts don't work in parser
p4c_add_xfail_reason("tofino"
  "Wrong number of arguments for method call"
  testdata/p4_16_samples/issue447-bmv2.p4
  testdata/p4_16_samples/issue447-1-bmv2.p4
  testdata/p4_16_samples/issue447-2-bmv2.p4
  testdata/p4_16_samples/issue447-3-bmv2.p4
  testdata/p4_16_samples/issue447-4-bmv2.p4
  testdata/p4_16_samples/issue447-5-bmv2.p4
  )

# parde physical adjacency constraint violated by mau phv_no_pack constraint
p4c_add_xfail_reason("tofino"
  "CCGF member .* not physically contiguous"
  extensions/p4_tests/p4_14/01-FlexCounter.p4
  extensions/p4_tests/p4_14/03-VlanProfile.p4
  extensions/p4_tests/p4_14/19-SimpleTrill.p4
  extensions/p4_tests/p4_14/c1/COMPILER-129/compiler129.p4
  extensions/p4_tests/p4_14/switch_20160602/switch.p4
  extensions/p4_tests/p4_14/switch/p4src/switch.p4
  )

# BRIG-112
p4c_add_xfail_reason("tofino"
  "ALU ops cannot operate on slices"
  extensions/p4_tests/p4_14/c1/COMPILER-228/case1644.p4
  )

p4c_add_xfail_reason("tofino"
  "Value too large"
  testdata/p4_14_samples/source_routing.p4
  extensions/p4_tests/p4_14/test_config_88_testing_action_data_allocation_3.p4
  )

# parser verify not supported
p4c_add_xfail_reason("tofino"
  "Invalid method call: verify"
  extensions/p4_tests/p4_16/ipv4_options.p4
  )

# BRIG-141
p4c_add_xfail_reason("tofino"
"No field named parser_counter in"
  extensions/p4_tests/p4_14/c1/COMPILER-384/case2240.p4
  extensions/p4_tests/p4_14/jenkins/pctr/pctr.p4
  )

# WARNING: Currently, when this message is sent, the compiler does not stop.  Thus, it may not
# be the right stop message for a particular message
p4c_add_xfail_reason("tofino"
  "No input xbar for salu instruction operand for phv"
  extensions/p4_tests/p4_14/jenkins/multicast_scale/multicast_scale.p4
  )

p4c_add_xfail_reason("tofino"
  "warning: Program does not contain a `main' module"
  extensions/p4_tests/p4_16/bloom_filter.p4
  extensions/p4_tests/p4_16/flowlet_switching.p4
  extensions/p4_tests/p4_16/stateful_alu.p4
  )

p4c_add_xfail_reason("tofino"
  "Could not find declaration for"
  extensions/p4_tests/p4_16/stful.p4
  )

p4c_add_xfail_reason("tofino"
  "Type register has 1 type parameter.*, but it is specialized with 2"
  extensions/p4_tests/p4_16/tna-salu.p4
  )

p4c_add_xfail_reason("tofino"
  "Cannot unify Type"
  extensions/p4_tests/p4_14/02-FlexCounterActionProfile.p4
  extensions/p4_tests/p4_14/test_config_172_stateful_heavy_hitter.p4
  extensions/p4_tests/p4_14/test_config_205_modify_field_from_hash.p4
  extensions/p4_tests/p4_14/test_config_295_polynomial_hash.p4
  extensions/p4_tests/p4_14/test_config_308_hash_96b.p4
  extensions/p4_tests/p4_14/test_config_311_hash_adb.p4
  )

p4c_add_xfail_reason("tofino"
  "error: .*: Cannot unify bit"
  extensions/p4_tests/p4_14/test_config_214_full_stats.p4
  )

# BRIG-102
p4c_add_xfail_reason("tofino"
  "syntax error, unexpected ','"
  extensions/p4_tests/p4_14/test_config_235_funnel_shift.p4
  )

p4c_add_xfail_reason("tofino"
  "tofino only supports 12 stages"
  extensions/p4_tests/p4_14/jenkins/alpm_test/alpm_test.p4
  extensions/p4_tests/p4_14/jenkins/basic_ipv4/basic_ipv4.p4
  extensions/p4_tests/p4_14/jenkins/exm_direct_1/exm_direct_1_one.p4
  extensions/p4_tests/p4_14/jenkins/basic_ipv4/basic_ipv4.p4
  extensions/p4_tests/p4_14/c1/COMPILER-357/case2100.p4
  )

# BRIG-113
p4c_add_xfail_reason("tofino"
  "Input xbar hash.*conflict in"
  extensions/p4_tests/p4_14/hash_calculation_max_size.p4
  extensions/p4_tests/p4_14/hash_calculation_multiple.p4
  )

p4c_add_xfail_reason("tofino"
# Fail on purpose due to action profiles not being mutually exclusive
  "Tables .* and .* are not mutually exclusive"
  extensions/p4_tests/p4_14/action_profile_not_shared.p4
  extensions/p4_tests/p4_14/action_profile_next_stage.p4
  testdata/p4_16_samples/action_selector_shared-bmv2.p4
  )

p4c_add_xfail_reason("tofino"
  "error: : condition too complex"
  extensions/p4_tests/p4_14/07-MacAddrCheck.p4
  extensions/p4_tests/p4_14/08-MacAddrCheck1.p4
  )


p4c_add_xfail_reason("tofino"
  "Unhandled InstanceRef type header_union"
  testdata/p4_16_samples/union-valid-bmv2.p4
  )
# BRIG_132
p4c_add_xfail_reason("tofino"
  "Unhandled InstanceRef type"
  testdata/p4_16_samples/union-bmv2.p4
  testdata/p4_16_samples/union1-bmv2.p4
  testdata/p4_16_samples/union2-bmv2.p4
  testdata/p4_16_samples/union3-bmv2.p4
  testdata/p4_16_samples/union4-bmv2.p4
  testdata/p4_16_samples/verify-bmv2.p4
  )


# failure due to too restrictive constraint of full words in action data bus allocation
# also: BRIG-56, BRIG-182
p4c_add_xfail_reason("tofino"
  "Can't fit table .* in .* by itself"
  extensions/p4_tests/p4_14/adb_shared3.p4
  extensions/p4_tests/p4_14/test_config_297_big_metadata.p4
  extensions/p4_tests/p4_14/jenkins/smoke_large_tbls/smoke_large_tbls.p4
  )

# BRIG-146 (also was BRIG-133)
p4c_add_xfail_reason("tofino"
  "alias for .* has out of range index from allowed"
  extensions/p4_tests/p4_14/adjust_instr5.p4
  extensions/p4_tests/p4_14/test_config_112_no_phase_0_case_action_width_too_big.p4
  extensions/p4_tests/p4_14/test_config_45_action_data_immediate_param_and_constant.p4
  )

# BRIG-149
p4c_add_xfail_reason("tofino"
  "Syntax error, expecting identifier or operation or integer"
  extensions/p4_tests/p4_14/adjust_instr7.p4
  )

# Same Name Conversion Bug
p4c_add_xfail_reason("tofino"
  "boost::too_few_args: format-string referred to more arguments than were passed"
  extensions/p4_tests/p4_14/shared_names.p4
  )

p4c_add_xfail_reason("tofino"
  "rv < 0 || rv == off"
  extensions/p4_tests/p4_14/test_config_86_multiple_action_widths_for_indirect_action.p4
  )

p4c_add_xfail_reason("tofino"
  "Expected 3 operands for execute_meter"
  extensions/p4_tests/p4_14/test_config_125_meter_pre_color.p4
  extensions/p4_tests/p4_14/test_config_126_meter_pre_color_2.p4
  extensions/p4_tests/p4_14/test_config_127_meter_pre_color_3.p4
  extensions/p4_tests/p4_14/test_config_132_meter_pre_color_4.p4
  extensions/p4_tests/p4_14/jenkins/mau_test/mau_test.p4
  )

# various stateful
# Signed 1-bit field not allowed in P4_16 (and really makes no sense?)
p4c_add_xfail_reason("tofino"
  "error: int<1>: Signed types cannot be 1-bit wide"
  extensions/p4_tests/p4_14/test_config_160_stateful_single_bit_mode.p4
  )

p4c_add_xfail_reason("tofino"
  "Changing type of"
  extensions/p4_tests/p4_14/test_config_163_stateful_table_math_unit.p4
  )

p4c_add_xfail_reason("tofino"
  "Can't reference memory in"
  extensions/p4_tests/p4_14/test_config_169_stateful_sflow_sequence.p4
  )

p4c_add_xfail_reason("tofino"
  "must be at 64 or 96 on ixbar to be used in stateful"
  extensions/p4_tests/p4_14/test_config_169_stateful_sflow_sequence.p4
  extensions/p4_tests/p4_14/test_config_184_stateful_bug1.p4
  )

p4c_add_xfail_reason("tofino"
  "Unrecognized AttribLocal combined_predicate"
  extensions/p4_tests/p4_14/test_config_195_stateful_predicate_output.p4
  )

p4c_add_xfail_reason("tofino"
  "recursion failure"
  extensions/p4_tests/p4_14/test_config_199_stateful_constant_index.p4
  )

p4c_add_xfail_reason("tofino"
  "Unknown method .* in stateful_alu"
  extensions/p4_tests/p4_14/test_config_206_stateful_logging.p4
  )

# conflict between blackbox meter and builtin meter
p4c_add_xfail_reason("tofino"
  "P4_14 extern type not fully supported"
  extensions/p4_tests/p4_14/test_config_185_first_lpf.p4
  extensions/p4_tests/p4_14/test_config_201_meter_constant_index.p4
  )

p4c_add_xfail_reason("tofino"
  "hash_dist .* not defined in table"
  extensions/p4_tests/p4_14/test_config_192_stateful_driven_by_hash.p4
  extensions/p4_tests/p4_14/test_config_209_pack_hash_dist.p4
  )


# COMPILER-329
p4c_add_xfail_reason("tofino"
  "error: : Width cannot be negative or zero"
  extensions/p4_tests/p4_14/c1/COMPILER-347/switch_bug.p4
  extensions/p4_tests/p4_14/c1/COMPILER-352/netchain_one.p4
  extensions/p4_tests/p4_14/c1/COMPILER-355/netchain_two.p4
  extensions/p4_tests/p4_14/c1/COMPILER-385/case2247.p4
  extensions/p4_tests/p4_14/c2/COMPILER-392/case2266.p4
  extensions/p4_tests/p4_14/c2/COMPILER-400/case2314.p4
  extensions/p4_tests/p4_14/c2/COMPILER-401/case2308_bugged.p4
  extensions/p4_tests/p4_14/c2/COMPILER-408/case2364.p4
  extensions/p4_tests/p4_14/c2/COMPILER-420/case2433.p4
  extensions/p4_tests/p4_14/c2/COMPILER-421/case2434.p4
  extensions/p4_tests/p4_14/c2/COMPILER-426/case2475.p4
  extensions/p4_tests/p4_14/c2/COMPILER-443/case2514.p4
  extensions/p4_tests/p4_14/c2/COMPILER-466/case2563_with_nop.p4
  extensions/p4_tests/p4_14/c2/COMPILER-466/case2563_without_nop.p4
  extensions/p4_tests/p4_14/c2/COMPILER-475/case2600.p4
  extensions/p4_tests/p4_14/c2/COMPILER-502/case2675.p4
  extensions/p4_tests/p4_14/c2/COMPILER-510/case2682.p4
  extensions/p4_tests/p4_14/c2/COMPILER-514/balancer_one.p4
  extensions/p4_tests/p4_14/c2/COMPILER-533/case2736.p4
  extensions/p4_tests/p4_14/c2/COMPILER-537/case2834.p4
  extensions/p4_tests/p4_14/c2/COMPILER-599/case3230.p4
  extensions/p4_tests/p4_14/c3/COMPILER-393/case2277.p4
  extensions/p4_tests/p4_14/c4/COMPILER-529/dnets_bng_case1.p4
  extensions/p4_tests/p4_14/c4/COMPILER-529/dnets_bng_case2.p4
  extensions/p4_tests/p4_14/c5/COMPILER-594/comp594.p4
  extensions/p4_tests/p4_14/jenkins/drivers_test/drivers_test_one.p4
  extensions/p4_tests/p4_14/jenkins/meters/meters_one.p4
  )

# COMPILER-540
p4c_add_xfail_reason("tofino"
  "error: : direct access to indirect register"
  extensions/p4_tests/p4_14/test_config_170_stateful_selection_table_update.p4
  extensions/p4_tests/p4_14/test_config_171_stateful_conga.p4
  extensions/p4_tests/p4_14/test_config_173_stateful_bloom_filter.p4
  extensions/p4_tests/p4_14/test_config_174_stateful_flow_learning.p4
  extensions/p4_tests/p4_14/c1/COMPILER-254/case1744.p4
  extensions/p4_tests/p4_14/c1/COMPILER-260/case1799.p4
  extensions/p4_tests/p4_14/c1/COMPILER-260/case1799_1.p4
  extensions/p4_tests/p4_14/c1/COMPILER-262/case1804.p4
  )

# BRIG-271
p4c_add_xfail_reason("tofino"
  "error: : conditional assignment not supported"
  extensions/p4_tests/p4_14/test_config_219_modify_field_conditionally.p4
  testdata/p4_16_samples/issue232-bmv2.p4
  testdata/p4_16_samples/issue420.p4
  testdata/p4_16_samples/issue512.p4
  )


#BRIG-139
p4c_add_xfail_reason("tofino"
  "syntax error, unexpected"
  extensions/p4_tests/p4_14/test_config_307_dyn_selection.p4
  extensions/p4_tests/p4_14/test_config_309_wide_dyn_selection.p4
  extensions/p4_tests/p4_14/test_config_314_sym_hash.p4
  extensions/p4_tests/p4_14/test_config_315_sym_hash_neg_test_1.p4
  extensions/p4_tests/p4_14/test_config_316_sym_hash_neg_test_2.p4
  extensions/p4_tests/p4_14/test_config_317_sym_hash_neg_test_3.p4
  extensions/p4_tests/p4_14/test_config_318_sym_hash_neg_test_4.p4
  extensions/p4_tests/p4_14/test_config_319_sym_hash_neg_test_5.p4
  )

p4c_add_xfail_reason("tofino"
  "constant value .* out of range for immediate"
  extensions/p4_tests/p4_14/c1/COMPILER-402/case2318.p4
  )
#
p4c_add_xfail_reason("tofino"
  "Table .* invoked from two different controls"
  extensions/p4_tests/p4_14/c1/COMPILER-263/case1795.p4
  extensions/p4_tests/p4_14/c1/COMPILER-264/case1822.p4
  extensions/p4_tests/p4_14/c1/COMPILER-271/case1834.p4
  extensions/p4_tests/p4_14/c1/COMPILER-273/case1832.p4
  extensions/p4_tests/p4_14/c1/COMPILER-275/case1841.p4
  extensions/p4_tests/p4_14/c1/COMPILER-276/case1844.p4
  extensions/p4_tests/p4_14/c1/COMPILER-282/case1864.p4
  extensions/p4_tests/p4_14/c1/COMPILER-499/case2560_min_2.p4
  )

# BRIG-138
p4c_add_xfail_reason("tofino"
  "error: : action .* appears multiple times in table"
  extensions/p4_tests/p4_14/c1/COMPILER-447/case2527.p4
  extensions/p4_tests/p4_14/c1/COMPILER-448/case2526.p4
  extensions/p4_tests/p4_14/c1/COMPILER-451/case2537.p4
  extensions/p4_tests/p4_14/c1/COMPILER-477/case2602.p4
  extensions/p4_tests/p4_14/c1/COMPILER-482/case2622.p4
  extensions/p4_tests/p4_14/c1/COMPILER-483/case2619.p4
  extensions/p4_tests/p4_14/c1/COMPILER-503/case2678.p4
  extensions/p4_tests/p4_14/c1/COMPILER-505/case2690.p4
  extensions/p4_tests/p4_14/c1/COMPILER-532/case2807.p4
  extensions/p4_tests/p4_14/c1/COMPILER-548/case3011.p4
  extensions/p4_tests/p4_14/c1/COMPILER-559/case2987.p4
  extensions/p4_tests/p4_14/c1/COMPILER-562/case3005.p4
  extensions/p4_tests/p4_14/c1/COMPILER-567/case2807.p4
  extensions/p4_tests/p4_14/c1/COMPILER-568/case3026.p4
  extensions/p4_tests/p4_14/c1/COMPILER-568/case3026dce.p4
  extensions/p4_tests/p4_14/c1/COMPILER-575/case3041.p4
  extensions/p4_tests/p4_14/c1/COMPILER-576/case3042.p4
  extensions/p4_tests/p4_14/c1/COMPILER-577/comp577.p4
  extensions/p4_tests/p4_14/c1/COMPILER-579/case3085.p4
  extensions/p4_tests/p4_14/c1/COMPILER-585/comp585.p4
  extensions/p4_tests/p4_14/c1/COMPILER-588/comp588.p4
  extensions/p4_tests/p4_14/c1/COMPILER-588/comp588dce.p4
  extensions/p4_tests/p4_14/c1/COMPILER-589/comp589.p4
  extensions/p4_tests/p4_14/c1/COMPILER-593/case3011.p4
  extensions/p4_tests/p4_14/c1/COMPILER-608/case3263.p4
  extensions/p4_tests/p4_14/c1/COMPILER-632/case3459.p4
  extensions/p4_tests/p4_14/c1/DRV-543/case2499.p4
  extensions/p4_tests/p4_14/jenkins/iterator/iterator.p4
  )

# BRIG-186: per_flow_enable
p4c_add_xfail_reason("tofino"
  "Field .* overlaps with .*"
  extensions/p4_tests/p4_14/c8/COMPILER-616/case3331.p4
  extensions/p4_tests/p4_14/jenkins/action_spec_format/action_spec_format.p4
  extensions/p4_tests/p4_14/jenkins/stats_pi/stats_pi.p4
  )

p4c_add_xfail_reason("tofino"
  "Action for .* has some unbound arguments"
  # requires pragma action_default_only
  extensions/p4_tests/p4_14/c1/COMPILER-548/case2895.p4
  )

# BRIG-243
p4c_add_xfail_reason("tofino"
  "Multiple synth2port require overflow"
  extensions/p4_tests/p4_14/jenkins/fr_test/fr_test.p4
  )

p4c_add_xfail_reason("tofino"
  "Can't fit table .* in input xbar by itself"
  extensions/p4_tests/p4_14/test_config_103_first_phase_0.p4
  )



# Specifically to save the error message
p4c_add_xfail_reason("tofino"
  "(throwing|uncaught exception).*Backtrack::trigger"
)

p4c_add_xfail_reason("tofino"
  "PHV read has no allocation"
  testdata/p4_16_samples/arith-bmv2.p4
  )

#
p4c_add_xfail_reason("tofino"
  "error: : source of modify_field invalid"
  testdata/p4_16_samples/arith1-bmv2.p4
  testdata/p4_16_samples/arith2-bmv2.p4
  testdata/p4_16_samples/concat-bmv2.p4
  )

p4c_add_xfail_reason("tofino"
  "error: : shift count must be a constant in"
  testdata/p4_16_samples/arith3-bmv2.p4
  testdata/p4_16_samples/arith4-bmv2.p4
  testdata/p4_16_samples/arith5-bmv2.p4
  )

p4c_add_xfail_reason("tofino"
  "metadata arrays not handled in"
  testdata/p4_16_samples/inline-stack-bmv2.p4
  )

p4c_add_xfail_reason("tofino"
  "Invalid select case expression"
  testdata/p4_16_samples/issue361-bmv2.p4
  )

p4c_add_xfail_reason("tofino"
  "Couldn't resolve computed extract in state start"
  testdata/p4_16_samples/issue510-bmv2.p4
  )

p4c_add_xfail_reason("tofino"
  "package .*: unexpected type"
  testdata/p4_16_samples/issue584-1.p4
  testdata/p4_16_samples/noMatch.p4
  testdata/p4_16_samples/pred.p4
  testdata/p4_16_samples/pred1.p4
  testdata/p4_16_samples/pred2.p4
  )

p4c_add_xfail_reason("tofino"
  "NULL operand 4 for hash"
  testdata/p4_16_samples/flowlet_switching-bmv2.p4
)

p4c_add_xfail_reason("tofino"
  "Exiting with SIGSEGV"
  extensions/p4_tests/p4_14/c1/COMPILER-635/case3468.p4
  extensions/p4_tests/p4_14/c1/COMPILER-637/case3478.p4
  )


# BRIG-181
# These are invalid programs, simply because P4_14 is too lax
# The solution is to fix the test cases and pass parameters
# to the default actions.
p4c_add_xfail_reason("tofino"
  "parameter .* must be bound"
#  extensions/p4_tests/p4_14/test_config_291_default_action.p4
#  extensions/p4_tests/p4_14/c1/COMPILER-235/vag1662.p4
  )

# Tofino expected failures (Glass fails as well)
p4c_add_xfail_reason("tofino"
  "ERROR: Unhandled type of Expression"
  testdata/p4_14_samples/issue583.p4
  # Glass succeeds on the next test, so it is here temporarily
  extensions/p4_tests/p4_14/c1/COMPILER-235/vag1737_1.p4
  )

p4c_add_xfail_reason("tofino"
  "Tofino does not allow meters to use different address schemes on one table"
  testdata/p4_14_samples/counter.p4
  extensions/p4_tests/p4_14/test_config_313_neg_test_addr_modes.p4
  )

p4c_add_xfail_reason("tofino"
  "Constant lookup does not match the ActionFormat"
  testdata/p4_14_samples/action_inline.p4
  )

p4c_add_xfail_reason("tofino"
  "Field is marked as deparsed, but the deparser doesn't emit it"
  testdata/p4_16_samples/issue430-1-bmv2.p4
  extensions/p4_tests/p4_16/cast_narrowing_set.p4
  extensions/p4_tests/p4_16/cast_widening_set.p4
  )

p4c_add_xfail_reason("tofino"
  "warning: : Currently the Barefoot HW compiler cannot handle any non direct assignment instruction that has missized rvalues"
  extensions/p4_tests/p4_16/cast_narrowing_add.p4
  extensions/p4_tests/p4_16/cast_widening_add.p4
  )

p4c_add_xfail_reason("tofino"
  "PHV allocation was not successful"
  testdata/p4_14_samples/05-FullTPHV.p4
  testdata/p4_14_samples/06-FullTPHV1.p4
  testdata/p4_14_samples/07-FullTPHV2.p4
  testdata/p4_14_samples/08-FullTPHV3.p4
  testdata/p4_14_samples/01-BigMatch.p4
  extensions/p4_tests/p4_14/04-FullPHV3.p4
  extensions/p4_tests/p4_14/test_config_101_switch_msdc.p4
  extensions/p4_tests/p4_14/c1/COMPILER-133/full_tphv.p4
  extensions/p4_tests/p4_14/c4/COMPILER-590/case3179.p4
  extensions/p4_tests/p4_14/c4/COMPILER-591/case3176.p4
  extensions/p4_tests/p4_14/jenkins/power/power.p4
  testdata/p4_14_samples/parser_dc_full.p4
  testdata/p4_14_samples/port_vlan_mapping.p4
  extensions/p4_tests/p4_14/test_config_101_switch_msdc.p4
  )

# Likely still has a bug; emits the following warning:
p4c_add_xfail_reason("tofino"
   "Action argument is not found to be allocated in the action format"
   testdata/p4_16_samples/slice-def-use.p4
   testdata/p4_16_samples/slice-def-use1.p4
  )

# We can't (without some complex acrobatics) support conditional computed
# checksums on Tofino. In P4-14, these are operations of the form:
#   update ipv4_checksum if(ipv4.ihl == 5);
# Glass's Tofino backend rejects these programs as well; they're really designed
# for BMV2.
p4c_add_xfail_reason("tofino"
  "Encountered invalid code in computed checksum control"
  testdata/p4_16_samples/issue134-bmv2.p4
)

# BRIG-226
# immediates are placed on disallowed bytes on the action bus
p4c_add_xfail_reason("tofino"
  "immediate is not on the action bus"
  extensions/p4_tests/p4_14/test_tp_1_one_table_spill.p4
  extensions/p4_tests/p4_14/test_config_21_tcam_vpns.p4
)

# no support for static entries
p4c_add_xfail_reason("tofino"
  "Table entries are not yet implemented in this backend"
  testdata/p4_16_samples/table-entries-exact-bmv2.p4
  testdata/p4_16_samples/table-entries-exact-ternary-bmv2.p4
  testdata/p4_16_samples/table-entries-priority-bmv2.p4
  testdata/p4_16_samples/table-entries-ternary-bmv2.p4
  testdata/p4_16_samples/table-entries-valid-bmv2.p4
  )

# These programs include non-byte-aligned headers, which are not supported on
# Tofino.
# XXX(seth): We're obviously losing some test coverage here; perhaps we should
# adjust some of these tests to not trigger this error?
p4c_add_xfail_reason("tofino"
  "header .* is not byte-aligned"
  testdata/p4_14_samples/14-SplitEthernetVlan.p4
  testdata/p4_14_samples/02-BadSizeField.p4
  testdata/p4_14_samples/14-GatewayGreaterThan.p4
  testdata/p4_16_samples/table-entries-priority-bmv2.p4
  testdata/p4_16_samples/table-entries-valid-bmv2.p4
  testdata/p4_16_samples/inline-stack-bmv2.p4
  testdata/p4_16_samples/table-entries-range-bmv2.p4
  testdata/p4_16_samples/table-entries-lpm-bmv2.p4
  testdata/p4_16_samples/table-entries-exact-bmv2.p4
  testdata/p4_16_samples/table-entries-ternary-bmv2.p4
  testdata/p4_16_samples/table-entries-exact-ternary-bmv2.p4
  testdata/p4_16_samples/issue134-bmv2.p4
)


p4c_add_xfail_reason("tofino"
  "visitor returned non-Statement type"
  testdata/p4_16_samples/issue887.p4
)

# Extracting '_' - i.e., `p.extract<Header>(_)`.
p4c_add_xfail_reason("tofino"
  "Extracting something other than a header"
  testdata/p4_16_samples/issue774-4-bmv2.p4
)

p4c_add_xfail_reason("tofino"
  "Header present in IR not under Member"
  # was "No PHV allocation for field extracted by the parser"
  testdata/p4_14_samples/packet_redirect.p4
  # was "too much data for parser match"
  testdata/p4_14_samples/copy_to_cpu.p4
  testdata/p4_16_samples/issue907-bmv2.p4
  )

# Hash distribution errors.  Zhao is looking at the following 2 errors currently
p4c_add_xfail_reason("tofino"
  "Hash column out of range"
  # was "Conflicting hash distribution bit allocation .*"
  extensions/p4_tests/p4_14/jenkins/stful/stful.p4
  extensions/p4_tests/p4_14/c1/COMPILER-364/case2115.p4
  )

p4c_add_xfail_reason("tofino"
  "Conflicting hash distribution bit allocation .*"
  extensions/p4_tests/p4_14/c1/COMPILER-326/case2035.p4
  )

p4c_add_xfail_reason("tofino"
  "Hash table .* column .* duplicated"
  extensions/p4_tests/p4_14/c1/COMPILER-357/case2100.p4
  )

p4c_add_xfail_reason("tofino"
  "Inferred incompatible alignments for field"
  extensions/p4_tests/p4_14/switch_l2_profile.p4
  testdata/p4_14_samples/switch_20160226/switch.p4
  testdata/p4_14_samples/switch_20160512/switch.p4
  )

# Tests where a field is placed into a container that's too big, causing us to
# generate an extract that reads past the beginning of the input buffer.
p4c_add_xfail_reason("tofino"
  "Container .* contains deparsed header fields, but it has unused bits.*"
  extensions/p4_tests/p4_14/22-BigToSmallFieldWithMask8.p4
  extensions/p4_tests/p4_14/test_config_262_req_packing.p4
  extensions/p4_tests/p4_14/c1/COMPILER-242/case1679.p4
  extensions/p4_tests/p4_14/c4/COMPILER-549/case2898.p4
  extensions/p4_tests/p4_14/jenkins/range/range.p4
  testdata/p4_14_samples/parser2.p4
  extensions/p4_tests/p4_14/c1/COMPILER-364/case2115.p4
  extensions/p4_tests/p4_14/c1/COMPILER-358/case2110.p4
  extensions/p4_tests/p4_14/c1/BRIG-5/case1715.p4
  extensions/p4_tests/p4_14/c1/COMPILER-494/case2560_min.p4
  )

# Tests where a field is placed correctly, but we still can't extract it without
# reading past the beginning of the input buffer. Multiple fixes are needed
# here; we need to be able to convey this constraint to PHV allocation, but in a
# subset of cases we can handle this by adjusting the parser program and we
# should do so if we can.
# BRIG-270
p4c_add_xfail_reason("tofino"
  "Extract field slice .* with a negative offset."
  extensions/p4_tests/p4_14/c1/COMPILER-217/port_parser.p4
  extensions/p4_tests/p4_14/c1/COMPILER-295/vag1892.p4
  extensions/p4_tests/p4_14/c1/COMPILER-351/case2079.p4
  extensions/p4_tests/p4_14/c1/COMPILER-353/case2088.p4
  extensions/p4_tests/p4_14/jenkins/pcie_pkt_test/pcie_pkt_test_one.p4
  extensions/p4_tests/p4_14/test_config_100_hash_action.p4
  extensions/p4_tests/p4_14/test_config_273_bridged_and_phase0.p4
  )

# BRIG-225?
p4c_add_xfail_reason("tofino"
  "Unexpected mirror id"
  testdata/p4_16_samples/clone-bmv2.p4
  extensions/p4_tests/p4_14/jenkins/mirror_test/mirror_test.p4
  )

p4c_add_xfail_reason("tofino"
  "Could not find declaration"
  extensions/p4_tests/p4_16/stful.p4
  )

# BEGIN: XFAILS that match glass XFAILS

p4c_add_xfail_reason("tofino"
  "Action writes fields using the same assignment type but different source operands"
  extensions/p4_tests/p4_14/14-MultipleActionsInAContainer.p4
  )

# BRIG-219
p4c_add_xfail_reason("tofino"
  "error: Only part of the container"
  extensions/p4_tests/p4_14/action_conflict_1.p4
  extensions/p4_tests/p4_14/action_conflict_3.p4
  extensions/p4_tests/p4_14/c1/COMPILER-235/case1737.p4
  extensions/p4_tests/p4_14/c1/COMPILER-235/case1737_1.p4
  extensions/p4_tests/p4_14/c1/COMPILER-357/case2100.p4
  extensions/p4_tests/p4_14/c1/COMPILER-414/case2387.p4
  extensions/p4_tests/p4_14/c1/COMPILER-415/case2386.p4
  extensions/p4_tests/p4_14/c7/COMPILER-623/case3375.p4
  )

# Fails due to use of more than two source containers
# BRIG-219
p4c_add_xfail_reason("tofino"
  "uses more than two source containers."
  extensions/p4_tests/p4_14/c1/COMPILER-414/case2387_1.p4
  extensions/p4_tests/p4_14/c1/COMPILER-437/case2387_1.p4
  )

#END: XFAILS that match glass XFAILS

if (ENABLE_STF2PTF AND PTF_REQUIREMENTS_MET)
  # STF2PTF tests that fail

  p4c_add_xfail_reason("tofino"
    "AssertionError: Expected packet was not received on device"
    extensions/p4_tests/p4_14/action_default_multiple.p4
    extensions/p4_tests/p4_14/adb_shared2.p4
    extensions/p4_tests/p4_14/adjust_instr3.p4
    extensions/p4_tests/p4_14/adjust_instr4.p4
    extensions/p4_tests/p4_14/counter_test1.p4
    extensions/p4_tests/p4_16/depgraph1.p4
    extensions/p4_tests/p4_16/parser_metadata_init.p4
    extensions/p4_tests/p4_16/stack_valid.p4
    testdata/p4_14_samples/07-MultiProtocol.p4
    testdata/p4_14_samples/basic_routing.p4
    testdata/p4_14_samples/exact_match3.p4
    testdata/p4_14_samples/exact_match_valid1.p4
    testdata/p4_14_samples/instruct5.p4
    testdata/p4_14_samples/ternary_match2.p4
    testdata/p4_14_samples/tmvalid.p4
    testdata/p4_16_samples/issue635-bmv2.p4
    testdata/p4_16_samples/issue655-bmv2.p4
    )

  p4c_add_xfail_reason("tofino"
    "AssertionError: .*: wrong (packets|bytes) count: expected 8 not 64"
    # counter3 fails because it receives 64 bytes: for PTF the test should be adjusted to send more than 8 bytes
    testdata/p4_14_samples/counter3.p4
    )

  p4c_add_xfail_reason("tofino"
    "AssertionError: .*: wrong (packets|bytes) count: expected 1 not 0"
    testdata/p4_14_samples/counter4.p4
    )

  # P4runtime p4info.proto gen
  p4c_add_xfail_reason("tofino"
    "Match field .* is too complicated to represent in P4Runtime"
    testdata/p4_14_samples/exact_match_mask1.p4
    )

  p4c_add_xfail_reason("tofino"
    "error: Encountered invalid code in computed checksum control"
    testdata/p4_14_samples/sai_p4.p4
    )

# Detailed error  "<_Rendezvous of RPC that terminated with (StatusCode.INVALID_ARGUMENT, Cannot map table entry to handle)>"
  p4c_add_xfail_reason("tofino"
    "StatusCode.INVALID_ARGUMENT, Cannot map table entry to handle"
    testdata/p4_14_samples/counter2.p4
    )

# Detailed error "<_Rendezvous of RPC that terminated with (StatusCode.UNAVAILABLE, Connect Failed)>"
  p4c_add_xfail_reason("tofino"
    "StatusCode.UNAVAILABLE, Connect Failed"
    testdata/p4_14_samples/exact_match5.p4
    testdata/p4_14_samples/exact_match4.p4
    extensions/p4_tests/p4_14/meter_test1.p4
    )

# BRIG-241
  p4c_add_xfail_reason("tofino"
    "AssertionError: Invalid match name .* for table .*"
    testdata/p4_14_samples/exact_match_mask1.p4
    )

  p4c_add_xfail_reason("tofino"
    "Error when trying to push config to bf_switchd"
    extensions/p4_tests/p4_14/hash_calculation_32.p4
    extensions/p4_tests/p4_14/stateful0.p4
    extensions/p4_tests/p4_14/stateful1.p4
    extensions/p4_tests/p4_14/stateful2.p4
    extensions/p4_tests/p4_14/stateful3.p4
    extensions/p4_tests/p4_16/stateful1.p4
    extensions/p4_tests/p4_16/stateful2.p4
    )

endif() # ENABLE_STF2PTF AND PTF_REQUIREMENTS_MET

if (ENABLE_TNA)
  # clone/resubmit the entire standard_metadata struct in ingress
  # fail reason: not all fields in standard metadata are defined in ingress
  p4c_add_xfail_reason("tofino"
    "Could not find declaration for"
    testdata/p4_14_samples/packet_redirect.p4
    testdata/p4_14_samples/simple_nat.p4
    # access stdmeta.egress_spec in egress pipeline
    extensions/p4_tests/p4_14/test_config_6_sram_and_tcam_allocation.p4
    # writes to egress_port which is a read-only field in ingress
    # A better error message should be
    # "Unable to write to read-only field standard_metadata.egress_port"
    testdata/p4_14_samples/simple_router.p4
    testdata/p4_14_samples/issue767.p4
    # A better error message should be
    # "Attempt to access undefined metadata field egress_port in ingress"
    testdata/p4_14_samples/copy_to_cpu.p4
    testdata/p4_14_samples/resubmit.p4
    testdata/p4_14_samples/queueing.p4
    extensions/p4_tests/p4_14/c1/BRIG-5/case1715.p4
    extensions/p4_tests/p4_16/stful.p4
    )

  p4c_add_xfail_reason("tofino"
    "meta already resolved to"
    extensions/p4_tests/p4_14/test_config_102_clone.p4
    extensions/p4_tests/p4_14/test_config_303_static_table.p4
    )

  p4c_add_xfail_reason("tofino"
    "Duplicate element meter"
    extensions/p4_tests/p4_14/test_config_168_meter_bug.p4
    extensions/p4_tests/p4_14/test_config_177_meter_test.p4
    )

  # accessing ingress_intrinsic_metadata in egress
  # failed because there is no implicit bridged metadata in tofino.p4
  p4c_add_xfail_reason("tofino"
    "Could not find declaration for ig_intr_md"
    extensions/p4_tests/p4_14/test_config_301_bridge_intrinsic.p4
    extensions/p4_tests/p4_14/c2/COMPILER-261/vag2241.p4
    extensions/p4_tests/p4_14/c4/COMPILER-590/case3179.p4
    extensions/p4_tests/p4_14/c4/COMPILER-591/case3176.p4
    extensions/p4_tests/p4_14/jenkins/parser_intr_md/parser_intr_md.p4
    )

  #
  p4c_add_xfail_reason("tofino"
    "Unrecognized mode of the action selector"
    extensions/p4_tests/p4_14/jenkins/exm_direct/exm_direct_one.p4
    )

  # hash function that return a data width that is different from 'base'
  p4c_add_xfail_reason("tofino"
    "Cannot unify bit"
    testdata/p4_14_samples/flowlet_switching.p4
    extensions/p4_tests/p4_14/test_config_96_hash_data.p4
    extensions/p4_tests/p4_14/test_config_13_first_selection.p4
    extensions/p4_tests/p4_14/test_config_294_parser_loop.p4
    )

  p4c_add_xfail_reason("tofino"
    "Cannot resolve computed select: BFN::SelectComputed"
    extensions/p4_tests/p4_14/c1/COMPILER-217/port_parser.p4
    )

  p4c_add_xfail_reason("tofino"
    "does not have a PHV allocation though it is used in an action"
    extensions/p4_tests/p4_14/test_config_157_random_number_generator.p4
    )

  p4c_add_xfail_reason("tofino"
    "Could not find declaration for ig_intr_md_for_tm"
    extensions/p4_tests/p4_14/test_config_306_no_mirror_share.p4
    extensions/p4_tests/p4_14/c8/COMPILER-616/case3331.p4
    )

  p4c_add_xfail_reason("tofino"
    "Field counter_pfe overlaps with meter_pfe"
    extensions/p4_tests/p4_14/jenkins/action_spec_format/action_spec_format.p4
    )

  p4c_add_xfail_reason("tofino"
    "Could not find declaration for ig_prsr_ctrl"
    extensions/p4_tests/p4_14/switch/p4src/switch.p4
    )

  p4c_add_xfail_reason("tofino"
    "Duplicates declaration struct .*"
    extensions/p4_tests/p4_14/switch_l2_profile.p4
    testdata/p4_14_samples/switch_20160226/switch.p4
    testdata/p4_14_samples/switch_20160512/switch.p4
    testdata/p4_14_samples/sai_p4.p4
    extensions/p4_tests/p4_14/switch_20160602/switch.p4
    )

  p4c_add_xfail_reason("tofino"
    "Cannot unify Type"
    testdata/p4_14_samples/issue894.p4
    )

  p4c_add_xfail_reason("tofino"
    "payload 0.0 already in use by table simple_table_0 gateway"
    extensions/p4_tests/p4_14/jenkins/mau_tcam_test/mau_tcam_test.p4
    )

  p4c_add_xfail_reason("tofino"
    "Expression .* cannot be the target of an assignment"
    extensions/p4_tests/p4_14/test_config_249_simple_bridge.p4
    )

  p4c_add_xfail_reason("tofino"
    "Could not find declaration for tmp_hdr.*"
    testdata/p4_14_samples/issue781.p4
    extensions/p4_tests/p4_14/c2/COMPILER-379/case2210.p4
    testdata/p4_14_samples/09-IPv4OptionsUnparsed.p4
    testdata/p4_14_samples/TLV_parsing.p4
    )

  p4c_add_xfail_reason("tofino"
    "Unexpected method call in parser"
    extensions/p4_tests/p4_14/packet_priority_exact_match.p4
    )

  p4c_add_xfail_reason("tofino"
    "Interface register does not have a method named execute with 2 argument"
    testdata/p4_14_samples/register.p4
    )

  p4c_add_xfail_reason("tofino"
    "src2 must be phv register"
    extensions/p4_tests/p4_14/jenkins/pgrs/pgrs_one.p4
    )

  p4c_add_xfail_reason("tofino"
    "Wrong number of arguments for method call"
    testdata/p4_16_samples/checksum1-bmv2.p4
    )

  p4c_add_xfail_reason("tofino"
    "NULL operand 4 for hash"
    testdata/p4_16_samples/flowlet_switching-bmv2.p4
    )

  p4c_add_xfail_reason("tofino"
    "Extract field slice .* resulted in buffer"
    extensions/p4_tests/p4_14/jenkins/multi_thread_test/multi_thread_test.p4
    extensions/p4_tests/p4_14/jenkins/perf_test/perf_test_one.p4
    )

  p4c_add_xfail_reason("tofino"
    "meta already resolved to"
    extensions/p4_tests/p4_14/c1/COMPILER-548/case3011.p4
    extensions/p4_tests/p4_14/c1/COMPILER-593/case3011.p4
    extensions/p4_tests/p4_14/switch/p4src/switch.p4
    extensions/p4_tests/p4_14/test_checksum.p4
    )

endif()  # ENABLE_TNA
