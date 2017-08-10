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
if (HARLYN_STF)
set (TOFINO_XFAIL_TESTS ${TOFINO_XFAIL_TESTS}
  extensions/p4_tests/p4_16/apply_if.p4
  extensions/p4_tests/p4_14/adb_shared2.p4
  extensions/p4_tests/p4_14/adjust_instr4.p4
  extensions/p4_tests/p4_14/hash_calculation_32.p4
  # Hash Action Bugs within the ASM or Model
  testdata/p4_14_samples/hash_action_gateway.p4
  testdata/p4_14_samples/counter2.p4
  testdata/p4_14_samples/counter3.p4
  testdata/p4_14_samples/counter4.p4
  # Masked table keys ignoring mask in table layout?
  testdata/p4_14_samples/exact_match_mask1.p4
  extensions/p4_tests/p4_14/stateful2.p4
  extensions/p4_tests/p4_14/stateful3.p4
  # default drop packet instead of writing to port 0
  testdata/p4_16_samples/issue635-bmv2.p4
  testdata/p4_16_samples/issue655-bmv2.p4
  # no support for static entries
  testdata/p4_16_samples/table-entries-exact-bmv2.p4
  testdata/p4_16_samples/table-entries-exact-ternary-bmv2.p4
  testdata/p4_16_samples/table-entries-lpm-bmv2.p4
  testdata/p4_16_samples/table-entries-priority-bmv2.p4
  testdata/p4_16_samples/table-entries-range-bmv2.p4
# The STF test fails due to malformed packet data.
# XXX(seth): I haven't had a chance to deeply analyze the problem, but nothing
# looks wrong in the parser or deparser program that we generate. The following
# PHV allocation validation warnings are suggestive:
# warning: Container TW3 contains deparsed header fields, but it has unused bits: ( 22:ingress::h.v<1> I off=0 ref deparsed /t_phv_8,PHV-259;/|t_phv_8,0..0|[0:0]->[TW3](31); )
# warning: Container TW19 contains deparsed header fields, but it has unused bits: ( 44:egress::h.v<1> E off=0 ref deparsed /t_phv_13,PHV-275;/|t_phv_13,0..0|[0:0]->[TW19](31); )
  testdata/p4_16_samples/table-entries-ternary-bmv2.p4
# Assertion failed: (start >= 1 && start < width_i), function taint_ccgf, file phv/cluster_phv_container.cpp, line 282.
# It's suggestive that these all involve header stacks.
# XXX(seth): This problem was diagnosed, and the fix is known. We write to
# `stack.$push`, but expect to read the result from `stack.$stkvalid`, a field
# which is overlayed with `stack.$push`. Since nothing ever reads `stack.$push`,
# we dead code eliminate the write, which breaks stuff. The fix is to totally
# remove `stack.$push` and just write to `stack.$stkvalid` directly. Nobody has
# had time to implement it yet, though.
  testdata/p4_14_samples/instruct5.p4
  extensions/p4_tests/p4_14/test_config_93_push_and_pop.p4
  )

  p4c_add_xfail_reason("tofino"
    "unexpected packet output on port"
    testdata/p4_14_samples/action_inline1.p4
    testdata/p4_14_samples/action_inline2.p4
    testdata/p4_14_samples/action_chain1.p4
    testdata/p4_14_samples/hitmiss.p4
    testdata/p4_14_samples/ternary_match1.p4
    testdata/p4_14_samples/ternary_match3.p4
    testdata/p4_14_samples/ternary_match4.p4
    testdata/p4_14_samples/tmvalid.p4
    testdata/p4_16_samples/ternary2-bmv2.p4
    extensions/p4_tests/p4_16/ternary1.p4
    extensions/p4_tests/p4_16/ternary2.p4
    )

  p4c_add_xfail_reason("tofino"
    "no field nexthop_index related to table ipv4_fib_lpm"
    testdata/p4_14_samples/basic_routing.p4
    )

  p4c_add_xfail_reason("tofino"
    "mismatch from expected.*at byte 0x"
    extensions/p4_tests/p4_16/depgraph1.p4
    extensions/p4_tests/p4_16/stack_valid.p4
    )
endif() # HARLYN_STF

# add the failures with no reason
p4c_add_xfail_reason("tofino" "" ${TOFINO_XFAIL_TESTS})

# Failure for BRIG-44 in JIRA
p4c_add_xfail_reason("tofino"
  "Unhandled expression in BuildGatewayMatch"
  testdata/p4_14_samples/basic_conditionals.p4
  )

# BRIG-136
# was BRIG-134 for extensions/p4_tests/p4_14/jenkins/alpm_test/alpm_test.p4
p4c_add_xfail_reason("tofino"
  "No write within a split instruction"
  extensions/p4_tests/p4_14/dileep.p4
  extensions/p4_tests/p4_14/dileep2.p4
  extensions/p4_tests/p4_14/dileep3.p4
  extensions/p4_tests/p4_14/dileep4.p4
  extensions/p4_tests/p4_14/dileep7-b.p4
  extensions/p4_tests/p4_14/dileep8.p4
  extensions/p4_tests/p4_14/dileep10.p4
  extensions/p4_tests/p4_14/dileep11.p4
  extensions/p4_tests/p4_14/dileep12.p4
  extensions/p4_tests/p4_14/vk_basic_ipv4_20150706.p4
  extensions/p4_tests/p4_14/jenkins/action_spec_format/action_spec_format.p4
  extensions/p4_tests/p4_14/jenkins/alpm_test/alpm_test.p4
  extensions/p4_tests/p4_14/jenkins/basic_ipv4/basic_ipv4.p4
  extensions/p4_tests/p4_14/jenkins/exm_direct/exm_direct_one.p4
  extensions/p4_tests/p4_14/jenkins/exm_direct_1/exm_direct_1_one.p4
  extensions/p4_tests/p4_14/jenkins/exm_indirect_1/exm_indirect_1_one.p4
  extensions/p4_tests/p4_14/jenkins/exm_smoke_test/exm_smoke_test_one.p4
  extensions/p4_tests/p4_14/jenkins/multi_device/multi_device.p4
  )

# BRIG-101
# was BRIG-147 for extensions/p4_tests/p4_14/adjust_instr6.p4
p4c_add_xfail_reason("tofino"
  "src2 must be phv register"
  testdata/p4_14_samples/instruct3.p4
  extensions/p4_tests/p4_14/adjust_instr6.p4
  extensions/p4_tests/p4_14/test_config_45_action_data_immediate_param_and_constant.p4
  extensions/p4_tests/p4_14/test_config_48_action_data_bit_masked_set.p4
  extensions/p4_tests/p4_14/test_config_49_action_data_bit_masked_set_immediate.p4
  )

# BRIG-103
p4c_add_xfail_reason("tofino"
  "instruction slot [0-9]+ used multiple times in action"
  testdata/p4_14_samples/instruct1.p4
  extensions/p4_tests/p4_14/14-MultipleActionsInAContainer.p4
  extensions/p4_tests/p4_14/instruct1.p4
  extensions/p4_tests/p4_14/test_config_256_pa_problem_4.p4
  extensions/p4_tests/p4_14/adjust_instr1.p4
  )

# BRIG-104
p4c_add_xfail_reason("tofino"
  "Unhandled action bitmask constraint"
  testdata/p4_14_samples/mac_rewrite.p4
  testdata/p4_14_samples/switch_20160226/switch.p4
  extensions/p4_tests/p4_14/c1/COMPILER-129/compiler129.p4
  )

# Incorrect P4_14->16 conversion for varbit extract
p4c_add_xfail_reason("tofino"
  "Wrong number of arguments for method call: packet.extract"
  testdata/p4_14_samples/09-IPv4OptionsUnparsed.p4
  testdata/p4_14_samples/issue781.p4
  )

# Fails due to complex expressions in the parser that our hardware can't support.
p4c_add_xfail_reason("tofino"
  "error: Assignment cannot be supported in the parser"
  testdata/p4_14_samples/TLV_parsing.p4
  testdata/p4_14_samples/axon.p4
  testdata/p4_14_samples/simple_nat.p4
  )

# BRIG-107
p4c_add_xfail_reason("tofino"
  "No field named counter_addr in format"
  testdata/p4_14_samples/13-Counters1and2.p4
  testdata/p4_14_samples/14-Counter.p4
  testdata/p4_14_samples/acl1.p4
  testdata/p4_16_samples/action_profile-bmv2.p4
  testdata/p4_16_samples/issue297-bmv2.p4
  )

# BRIG-108
p4c_add_xfail_reason("tofino"
  "No format in action table"
  testdata/p4_14_samples/02-FullPHV1.p4
  testdata/p4_14_samples/03-FullPHV2.p4
  testdata/p4_14_samples/07-FullTPHV2.p4
  testdata/p4_14_samples/selector0.p4
  testdata/p4_16_samples/action_profile-bmv2.p4
  testdata/p4_16_samples/issue297-bmv2.p4
  extensions/p4_tests/p4_14/c1/COMPILER-133/full_tphv.p4
  )

# BRIG-197
p4c_add_xfail_reason("tofino"
  "No register named"
  testdata/p4_14_samples/05-FullTPHV.p4
  testdata/p4_14_samples/06-FullTPHV1.p4
  testdata/p4_14_samples/08-FullTPHV3.p4
  )

# p4c_add_xfail_reason("tofino"
#   "State .* extracts field .* with no PHV allocation"
#   testdata/p4_14_samples/packet_redirect.p4
#   )
# BRIG-109
p4c_add_xfail_reason("tofino"
  "error: Cannot resolve computed select"
  testdata/p4_14_samples/queueing.p4
  # XXX(seth): This code just uses packet_in.lookahead() in a way which isn't supported yet.
  testdata/p4_16_samples/issue355-bmv2.p4
  extensions/p4_tests/p4_14/test_config_294_parser_loop.p4
  )

# varbit extracts don't work in parser
p4c_add_xfail_reason("tofino"
  "Wrong number of arguments for method call"
  extensions/p4_tests/p4_14/c2/COMPILER-379/case2210.p4
  testdata/p4_16_samples/issue447-bmv2.p4
  testdata/p4_16_samples/issue447-1-bmv2.p4
  testdata/p4_16_samples/issue447-2-bmv2.p4
  testdata/p4_16_samples/issue447-3-bmv2.p4
  testdata/p4_16_samples/issue447-4-bmv2.p4
  testdata/p4_16_samples/issue447-5-bmv2.p4
  )

# BRIG-112
p4c_add_xfail_reason("tofino"
  "ALU ops cannot operate on slices"
  extensions/p4_tests/p4_14/01-FlexCounter.p4
  extensions/p4_tests/p4_14/03-VlanProfile.p4
  extensions/p4_tests/p4_14/06-MultiFieldAdd.p4
  extensions/p4_tests/p4_14/19-SimpleTrill.p4
  extensions/p4_tests/p4_14/20-SimpleTrillTwoStep.p4
  extensions/p4_tests/p4_14/21-SimpleTrillThreeStep.p4
  extensions/p4_tests/p4_14/24-SimpleTrillThreeStep2.p4
  extensions/p4_tests/p4_14/test_config_216_phv_aff.p4
  extensions/p4_tests/p4_14/test_config_217_gateway_non_determin.p4
  testdata/p4_16_samples/issue414-bmv2.p4
  testdata/p4_16_samples/parser-locals2.p4
  extensions/p4_tests/p4_14/c1/COMPILER-228/case1644.p4
  )

p4c_add_xfail_reason("tofino"
  "Value too large"
  testdata/p4_14_samples/source_routing.p4
  )

# tofino/parde/extract_parser.cpp:192: Null igParser
# XXX(seth): The extract_maupipe() code is actually passing a null ingress
# parser into extractParser(). I'm not sure what's happening there, but
# presumably it's happening at an earlier layer than the Tofino backend parser
# stuff.
p4c_add_xfail_reason("tofino"
  "Null igParser"
  testdata/p4_14_samples/parser4.p4
  testdata/p4_14_samples/parser2.p4
  testdata/p4_14_samples/parser1.p4
  testdata/p4_14_samples/parser_dc_full.p4
  testdata/p4_14_samples/port_vlan_mapping.p4
  )

p4c_add_xfail_reason("tofino"
  "gen_deparser.cpp:40: Null p"
  testdata/p4_16_samples/issue281.p4
  testdata/p4_16_samples/scalarmeta-bmv2.p4
  testdata/p4_16_samples/stack_complex-bmv2.p4
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

# BRIG-192
# extensions/p4_tests/p4_14/11-AssignChooseDest.p4
p4c_add_xfail_reason("tofino"
  "What happened here.*64"
  extensions/p4_tests/p4_14/11-AssignChooseDest.p4
  extensions/p4_tests/p4_14/c1/COMPILER-326/case2035.p4
  extensions/p4_tests/p4_14/switch_20160602/switch.p4
  )

# used to be: BRIG-129 & BRIG-183
p4c_add_xfail_reason("tofino"
  "No phv record"
  extensions/p4_tests/p4_16/clone-bmv2.p4
  extensions/p4_tests/p4_14/test_checksum.p4
  extensions/p4_tests/p4_14/test_config_102_clone.p4
  extensions/p4_tests/p4_14/test_config_303_static_table.p4
  )

p4c_add_xfail_reason("tofino"
  "warning: Program does not contain a `main' module"
  extensions/p4_tests/p4_16/bloom_filter.p4
  extensions/p4_tests/p4_16/flowlet_switching.p4
  extensions/p4_tests/p4_16/stateful_alu.p4
  )

# BRIG-179
p4c_add_xfail_reason("tofino"
  "Could not find type of"
  extensions/p4_tests/p4_14/c1/COMPILER-386/test_config_286_stat_bugs.p4
  )

p4c_add_xfail_reason("tofino"
  "error: cast: Illegal cast from bit"
  extensions/p4_tests/p4_14/jenkins/stful/stful.p4
  )

p4c_add_xfail_reason("tofino"
  "error: register.*: Type register has .* type parameter"
  extensions/p4_tests/p4_16/stful.p4
  extensions/p4_tests/p4_16/tna-salu.p4
  )

# BRIG-67
# was also BRIG-143
# blackbox type unification failures (JIRA #BRIG-30, #COMPILER-341)
#  extensions/p4_tests/p4_14/test_config_205_modify_field_from_hash.p4
#
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
  extensions/p4_tests/p4_14/test_config_244_gateway_compare.p4
  )

p4c_add_xfail_reason("tofino"
  "error: .*: not defined on bool and int"
  extensions/p4_tests/p4_14/test_config_244_gateway_compare.p4
  extensions/p4_tests/p4_14/test_config_245_alias_test.p4
  extensions/p4_tests/p4_14/test_config_246_fill_stage.p4
  extensions/p4_tests/p4_14/test_config_247_first_clpm.p4
  extensions/p4_tests/p4_14/test_config_261_mutually_exclusive_src_ops.p4
  extensions/p4_tests/p4_14/test_config_262_req_packing.p4
  extensions/p4_tests/p4_14/test_config_277_meta_init.p4
  extensions/p4_tests/p4_14/test_config_278_meta_init2.p4
  extensions/p4_tests/p4_14/c1/COMPILER-386/test_config_286_stat_bugs.p4
  )

# BRIG-102
p4c_add_xfail_reason("tofino"
  "syntax error, unexpected ','"
  extensions/p4_tests/p4_14/test_config_235_funnel_shift.p4
  )

# BRIG-105
p4c_add_xfail_reason("tofino"
  "No register named"
  # Should still fail; see BRIG-198.
  # extensions/p4_tests/p4_14/04-FullPHV3.p4
  extensions/p4_tests/p4_14/switch_l2_profile.p4
  extensions/p4_tests/p4_14/c1/BRIG-5/case1715.p4
  extensions/p4_tests/p4_14/c1/COMPILER-235/case1737.p4
  extensions/p4_tests/p4_14/c1/COMPILER-351/case2079.p4
  extensions/p4_tests/p4_14/c1/COMPILER-353/case2088.p4
  extensions/p4_tests/p4_14/c1/COMPILER-357/case2100.p4
  extensions/p4_tests/p4_14/c1/COMPILER-358/case2110.p4
  extensions/p4_tests/p4_14/c1/COMPILER-364/case2115.p4
  extensions/p4_tests/p4_14/c1/COMPILER-414/case2387.p4
  extensions/p4_tests/p4_14/c1/COMPILER-414/case2387_1.p4
  extensions/p4_tests/p4_14/c1/COMPILER-415/case2386.p4
  extensions/p4_tests/p4_14/c1/COMPILER-437/case2387_1.p4
  extensions/p4_tests/p4_14/c1/COMPILER-494/case2560_min.p4
  )

# BRIG-113
p4c_add_xfail_reason("tofino"
  "Input xbar hash.*conflict in"
  extensions/p4_tests/p4_14/09-MatchNoDep.p4
  extensions/p4_tests/p4_14/10-MatchNoDep1.p4
  extensions/p4_tests/p4_14/test_config_129_various_exact_match_keys.p4
  extensions/p4_tests/p4_14/c1/COMPILER-235/case1737_1.p4
  extensions/p4_tests/p4_14/c1/COMPILER-235/vag1737_1.p4
  extensions/p4_tests/p4_14/test_config_96_hash_data.p4
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

# BRIG_132
p4c_add_xfail_reason("tofino"
  "Unhandled InstanceRef type"
  testdata/p4_16_samples/union-bmv2.p4
  testdata/p4_16_samples/union-valid-bmv2.p4
  testdata/p4_16_samples/union1-bmv2.p4
  testdata/p4_16_samples/union2-bmv2.p4
  testdata/p4_16_samples/union3-bmv2.p4
  testdata/p4_16_samples/union4-bmv2.p4
  testdata/p4_16_samples/verify-bmv2.p4
  )

# The PHV allocator places h.v and h.$valid in the same container, even though
# one is metadata and one is not, and moreover one is deparsed and one is not.
# ValidateAllocation reports this problem:
#     warning: Deparsed container B15 contains some non-deparsed fields: ( 22:ingress::h.v<1> I off=0 ref deparsed /phv_4,PHV-79;/|phv_4,0..0|[0:0]->[B15](6);, 45:ingress::h.$valid<1> I off=0 ref pov /pov_7,PHV-79;/|pov_7,0..0|[0:0]->[B15](7); )
#     warning: Deparsed container B15 contains non-bridged metadata fields: ( 22:ingress::h.v<1> I off=0 ref deparsed /phv_4,PHV-79;/|phv_4,0..0|[0:0]->[B15](6);, 45:ingress::h.$valid<1> I off=0 ref pov /pov_7,PHV-79;/|pov_7,0..0|[0:0]->[B15](7); )
#     warning: Deparsed container B15 contains a mix of metadata and non-metadata fields: ( 22:ingress::h.v<1> I off=0 ref deparsed /phv_4,PHV-79;/|phv_4,0..0|[0:0]->[B15](6);, 45:ingress::h.$valid<1> I off=0 ref pov /pov_7,PHV-79;/|pov_7,0..0|[0:0]->[B15](7); )
#     warning: Container B15 contains deparsed header fields, but it has unused bits: ( 22:ingress::h.v<1> I off=0 ref deparsed /phv_4,PHV-79;/|phv_4,0..0|[0:0]->[B15](6);, 45:ingress::h.$valid<1> I off=0 ref pov /pov_7,PHV-79;/|pov_7,0..0|[0:0]->[B15](7); )
# This causes the parser code to be unable to find a valid extractor allocation.
p4c_add_xfail_reason("tofino"
  "Ran out of phv output slots"
  extensions/p4_tests/p4_14/test_config_236_stateful_read_bit.p4
  extensions/p4_tests/p4_14/test_config_93_push_and_pop.p4
  extensions/p4_tests/p4_14/test_config_95_first_meter_table.p4
  testdata/p4_16_samples/table-entries-valid-bmv2.p4
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
  )

# BRIG-149
p4c_add_xfail_reason("tofino"
  "Syntax error, expecting identifier or operation or integer"
  extensions/p4_tests/p4_14/adjust_instr7.p4
  )

# BRIG-117
p4c_add_xfail_reason("tofino"
  "match bus conflict"
  extensions/p4_tests/p4_14/gateway_and_big_table.p4
  )

# BRIG-119
p4c_add_xfail_reason("tofino"
  "hash expression width mismatch"
  extensions/p4_tests/p4_14/test_config_100_hash_action.p4
  extensions/p4_tests/p4_14/test_config_209_pack_hash_dist.p4
  )

# New failures with action bus working in compiler
p4c_add_xfail_reason("tofino"
  "Two containers in the same action are at the same place?"
  extensions/p4_tests/p4_14/test_config_101_switch_msdc.p4
  )

# Same Name Conversion Bug
p4c_add_xfail_reason("tofino"
  "boost::too_few_args: format-string referred to more arguments than were passed"
  extensions/p4_tests/p4_14/shared_names.p4
  )

p4c_add_xfail_reason("tofino"
  "(throwing|uncaught exception).*std::out_of_range"
  extensions/p4_tests/p4_14/switch_l2_profile_tofino.p4
  )

# BRIG-99
p4c_add_xfail_reason("tofino"
  "Missing color_maprams in meter table"
  extensions/p4_tests/p4_14/test_config_123_meter_2.p4
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
  )

p4c_add_xfail_reason("tofino"
"error: port: expected a field list"
  extensions/p4_tests/p4_14/test_config_144_recirculate.p4
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
  "must be at .* to be used in stateful table"
  extensions/p4_tests/p4_14/test_config_184_stateful_bug1.p4)

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
  extensions/p4_tests/p4_14/switch/p4src/switch.p4
  )

p4c_add_xfail_reason("tofino"
  "hash_dist .* not defined in table"
  extensions/p4_tests/p4_14/test_config_192_stateful_driven_by_hash.p4
  )

# BRIG-119
p4c_add_xfail_reason("tofino"
  "Can't combine hash_dist units"
  extensions/p4_tests/p4_14/test_config_300_multi_hash.p4
  extensions/p4_tests/p4_14/hash_calculation_two_hash2.p4
  extensions/p4_tests/p4_14/hash_calculation_two_hash1.p4
  extensions/p4_tests/p4_14/test_config_13_first_selection.p4
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
  extensions/p4_tests/p4_14/c3/COMPILER-393/case2277.p4
  extensions/p4_tests/p4_14/c4/COMPILER-529/dnets_bng_case1.p4
  extensions/p4_tests/p4_14/c4/COMPILER-529/dnets_bng_case2.p4
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
  extensions/p4_tests/p4_14/jenkins/multicast_scale/multicast_scale.p4
  )

# BRIG-28
# P4_14->16 unhandled primitives
# also BRIG-180
#  extensions/p4_tests/p4_14/test_config_284_swap_primitive.p4
p4c_add_xfail_reason("tofino"
  "Unhandled primitive"
  extensions/p4_tests/p4_14/test_config_182_warp_primitive.p4
  extensions/p4_tests/p4_14/test_config_183_sample_e2e.p4
  extensions/p4_tests/p4_14/test_config_191_invalidate.p4
  extensions/p4_tests/p4_14/test_config_284_swap_primitive.p4
  extensions/p4_tests/p4_14/c1/COMPILER-532/case2807.p4
  )

p4c_add_xfail_reason("tofino"
  "error: : conditional assignment not supported"
  extensions/p4_tests/p4_14/test_config_219_modify_field_conditionally.p4
  testdata/p4_16_samples/issue232-bmv2.p4
  testdata/p4_16_samples/issue242.p4
  testdata/p4_16_samples/issue420.p4
  testdata/p4_16_samples/issue512.p4
  )

# BRIG-181
p4c_add_xfail_reason("tofino"
  "parameter .* must be bound"
  extensions/p4_tests/p4_14/test_config_291_default_action.p4
  extensions/p4_tests/p4_14/c1/COMPILER-235/vag1662.p4
  extensions/p4_tests/p4_14/c1/COMPILER-503/case2678.p4
  extensions/p4_tests/p4_14/c1/COMPILER-505/case2690.p4
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

#BRIG-201
p4c_add_xfail_reason("tofino"
  "payload ... already in use"
  extensions/p4_tests/p4_14/jenkins/mau_tcam_test/mau_tcam_test.p4
  )

#BRIG-142
p4c_add_xfail_reason("tofino"
  "error: .*: expected a field list"
  extensions/p4_tests/p4_14/test_config_313_neg_test_addr_modes.p4
  extensions/p4_tests/p4_14/jenkins/pgrs/pgrs_one.p4
  )

p4c_add_xfail_reason("tofino"
  "cluster.cpp: Operation ..... mixed gress"
  extensions/p4_tests/p4_14/test_config_88_testing_action_data_allocation_3.p4
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

# BRIG-137
p4c_add_xfail_reason("tofino"
  "error: : not enough operands for primitive"
  extensions/p4_tests/p4_14/jenkins/emulation/emulation.p4
  extensions/p4_tests/p4_14/jenkins/mau_test/mau_test.p4
  extensions/p4_tests/p4_14/jenkins/resubmit/resubmit.p4
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
  extensions/p4_tests/p4_14/c1/DRV-543/case2499.p4
  extensions/p4_tests/p4_14/jenkins/iterator/iterator.p4
  )

# BRIG-140
p4c_add_xfail_reason("tofino"
  "syntax error, unexpected IDENTIFIER"
  extensions/p4_tests/p4_14/jenkins/parser_intr_md/parser_intr_md.p4
  extensions/p4_tests/p4_14/jenkins/pvs/pvs.p4
  )

# BRIG-186: per_flow_enable
p4c_add_xfail_reason("tofino"
  "Field .* overlaps with .*"
  extensions/p4_tests/p4_14/jenkins/stats_pi/stats_pi.p4
  )


p4c_add_xfail_reason("tofino"
  "(throwing|uncaught exception).*Backtrack::trigger"
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
  "Null mirror"
  testdata/p4_14_samples/copy_to_cpu.p4
  testdata/p4_14_samples/packet_redirect.p4
  testdata/p4_14_samples/switch_20160512/switch.p4
  )

p4c_add_xfail_reason("tofino"
  "NULL operand 4 for hash"
  testdata/p4_14_samples/flowlet_switching.p4
  testdata/p4_16_samples/flowlet_switching-bmv2.p4
)

# p4c_add_xfail_reason("tofino"
#   "Exiting with SIGSEGV"
#   )

# Tofino expected failures (Glass fails as well)
p4c_add_xfail_reason("tofino"
  "ERROR: Unhandled type of Expression"
  testdata/p4_14_samples/issue583.p4
  )

p4c_add_xfail_reason("tofino"
  "Tofino does not allow meters to use different address schemes on one table"
  testdata/p4_14_samples/counter.p4
  )

p4c_add_xfail_reason("tofino"
  "Constant lookup does not match the ActionFormat"
  testdata/p4_14_samples/action_inline.p4
  )
