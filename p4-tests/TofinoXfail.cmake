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
    testdata/p4_14_samples/basic_routing.p4
    "unexpected packet output on port 10")

  p4c_add_xfail_reason("tofino"
    extensions/p4_tests/p4_16/stack_valid.p4
    "mismatch from expected.*at byte 0x2")
endif() # HARLYN_STF

# add the failures with no reason
foreach (t ${TOFINO_XFAIL_TESTS})
  p4c_add_xfail_reason("tofino" ${t} "")
endforeach()

# Failure for BRIG-44 in JIRA
p4c_add_xfail_reason("tofino"
  testdata/p4_14_samples/basic_conditionals.p4
  "Unhandled expression in BuildGatewayMatch")

# BRIG-136
# was BRIG-134 for extensions/p4_tests/p4_14/jenkins/alpm_test/alpm_test.p4
set (reason "No write within a split instruction")
set (brig_136
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
foreach (t ${brig_136})
  p4c_add_xfail_reason("tofino" ${t} ${reason})
endforeach()

# BRIG-101
# was BRIG-147 for extensions/p4_tests/p4_14/adjust_instr6.p4
set (reason "src2 must be phv register")
set (brig_101
  testdata/p4_14_samples/instruct3.p4
  extensions/p4_tests/p4_14/adjust_instr6.p4
  extensions/p4_tests/p4_14/test_config_45_action_data_immediate_param_and_constant.p4
  extensions/p4_tests/p4_14/test_config_48_action_data_bit_masked_set.p4
  extensions/p4_tests/p4_14/test_config_49_action_data_bit_masked_set_immediate.p4
  )
foreach (t ${brig_101})
  p4c_add_xfail_reason("tofino" ${t} ${reason})
endforeach()

# BRIG-103
set (reason "instruction slot [0-9]+ used multiple times in action")
set (brig_103
  testdata/p4_14_samples/instruct1.p4
  extensions/p4_tests/p4_14/14-MultipleActionsInAContainer.p4
  extensions/p4_tests/p4_14/instruct1.p4
  extensions/p4_tests/p4_14/test_config_256_pa_problem_4.p4
  extensions/p4_tests/p4_14/adjust_instr1.p4
  )
foreach (t ${brig_103})
  p4c_add_xfail_reason("tofino" ${t} ${reason})
endforeach()

# BRIG-104
set (reason  "Unhandled action bitmask constraint")
set (brig_104
  testdata/p4_14_samples/mac_rewrite.p4
  testdata/p4_14_samples/switch_20160226/switch.p4
  testdata/p4_14_samples/switch_20160512/switch.p4
  extensions/p4_tests/p4_14/c1/COMPILER-129/compiler129.p4
  )
foreach (t ${brig_104})
  p4c_add_xfail_reason("tofino" ${t} ${reason})
endforeach()

# Incorrect P4_14->16 conversion for varbit extract
p4c_add_xfail_reason("tofino"
  testdata/p4_14_samples/09-IPv4OptionsUnparsed.p4
  "Wrong number of arguments for method call: packet.extract")

# Fails due to complex expressions in the parser that our hardware can't support.
set (reason "error: Assignment cannot be supported in the parser")
set (complex_parser
  testdata/p4_14_samples/TLV_parsing.p4
  testdata/p4_14_samples/axon.p4
  testdata/p4_14_samples/simple_nat.p4
  )
foreach (t ${complex_parser})
  p4c_add_xfail_reason("tofino" ${t} ${reason})
endforeach()

# BRIG-107
set (reason "No field named counter_addr in format")
set (brig_107
  testdata/p4_14_samples/13-Counters1and2.p4
  testdata/p4_14_samples/14-Counter.p4
  testdata/p4_14_samples/acl1.p4
  testdata/p4_16_samples/action_profile-bmv2.p4
  testdata/p4_16_samples/issue297-bmv2.p4
  )
foreach (t ${brig_107})
  p4c_add_xfail_reason("tofino" ${t} ${reason})
endforeach()

# BRIG-108
set (reason  "No format in action table")
set (brig_108
  testdata/p4_14_samples/02-FullPHV1.p4
  testdata/p4_14_samples/03-FullPHV2.p4
  testdata/p4_14_samples/05-FullTPHV.p4
  testdata/p4_14_samples/07-FullTPHV2.p4
  testdata/p4_14_samples/08-FullTPHV3.p4
  testdata/p4_14_samples/selector0.p4
  testdata/p4_16_samples/action_profile-bmv2.p4
  testdata/p4_16_samples/issue297-bmv2.p4
  extensions/p4_tests/p4_14/c1/COMPILER-133/full_tphv.p4
  )
foreach (t ${brig_108})
  p4c_add_xfail_reason("tofino" ${t} ${reason})
endforeach()

p4c_add_xfail_reason("tofino"
  testdata/p4_14_samples/packet_redirect.p4
  "State .* extracts field .* with no PHV allocation")

# BRIG-109
set (reason "error: Cannot resolve computed select")
set (computed_select_tests
  testdata/p4_14_samples/queueing.p4
  # XXX(seth): This code just uses packet_in.lookahead() in a way which isn't supported yet.
  testdata/p4_16_samples/issue355-bmv2.p4
  extensions/p4_tests/p4_14/test_config_294_parser_loop.p4
  )
foreach (t ${computed_select_tests})
  p4c_add_xfail_reason("tofino" ${t} ${reason})
endforeach()

# varbit extracts don't work in parser
set (reason "Wrong number of arguments for method call")
set (parser_varbit
  extensions/p4_tests/p4_14/c2/COMPILER-379/case2210.p4
  testdata/p4_16_samples/issue447-bmv2.p4
  testdata/p4_16_samples/issue447-1-bmv2.p4
  testdata/p4_16_samples/issue447-2-bmv2.p4
  testdata/p4_16_samples/issue447-3-bmv2.p4
  testdata/p4_16_samples/issue447-4-bmv2.p4
  testdata/p4_16_samples/issue447-5-bmv2.p4
  )
foreach (t ${parser_varbit})
  p4c_add_xfail_reason("tofino" ${t} ${reason})
endforeach()

# BRIG-112
set (reason "ALU ops cannot operate on slices")
set (brig_112
  extensions/p4_tests/p4_14/01-FlexCounter.p4
  extensions/p4_tests/p4_14/03-VlanProfile.p4
  extensions/p4_tests/p4_14/06-MultiFieldAdd.p4
  extensions/p4_tests/p4_14/19-SimpleTrill.p4
  extensions/p4_tests/p4_14/20-SimpleTrillTwoStep.p4
  extensions/p4_tests/p4_14/21-SimpleTrillThreeStep.p4
  extensions/p4_tests/p4_14/24-SimpleTrillThreeStep2.p4
  extensions/p4_tests/p4_14/test_config_216_phv_aff.p4
  extensions/p4_tests/p4_14/test_config_217_gateway_non_determin.p4
  extensions/p4_tests/p4_14/test_config_92_bit_xor_10_bits.p4
  testdata/p4_16_samples/issue414-bmv2.p4
  testdata/p4_16_samples/parser-locals2.p4
  extensions/p4_tests/p4_14/c1/COMPILER-228/case1644.p4
  )
foreach (t ${brig_112})
  p4c_add_xfail_reason("tofino" ${t} ${reason})
endforeach()

set (reason "Value too large")
p4c_add_xfail_reason("tofino" testdata/p4_14_samples/source_routing.p4 ${reason})

# tofino/parde/extract_parser.cpp:192: Null igParser
# XXX(seth): The extract_maupipe() code is actually passing a null ingress
# parser into extractParser(). I'm not sure what's happening there, but
# presumably it's happening at an earlier layer than the Tofino backend parser
# stuff.
set (reason "Null igParser")
set (parser_tests
  testdata/p4_14_samples/parser4.p4
  testdata/p4_14_samples/parser2.p4
  testdata/p4_14_samples/parser1.p4
  testdata/p4_14_samples/parser_dc_full.p4
  testdata/p4_14_samples/port_vlan_mapping.p4
  )
foreach (t ${parser_tests})
  p4c_add_xfail_reason("tofino" ${t} ${reason})
endforeach()

set (reason "gen_deparser.cpp:40: Null p")
set (deparser_tests
  testdata/p4_16_samples/issue281.p4
  testdata/p4_16_samples/scalarmeta-bmv2.p4
  testdata/p4_16_samples/stack_complex-bmv2.p4
  )
foreach (t ${deparser_tests})
  p4c_add_xfail_reason("tofino" ${t} ${reason})
endforeach()

# parser verify not supported
p4c_add_xfail_reason("tofino" extensions/p4_tests/p4_16/ipv4_options.p4
  "Invalid method call: verify")

# BRIG-141
set (reason "No field named parser_counter in")
set (brig_141
  extensions/p4_tests/p4_14/c1/COMPILER-384/case2240.p4
  extensions/p4_tests/p4_14/jenkins/pctr/pctr.p4
  )
foreach (t ${brig_141})
  p4c_add_xfail_reason("tofino" ${t} ${reason})
endforeach()

# BRIG-192
# extensions/p4_tests/p4_14/11-AssignChooseDest.p4
set (reason "What happened here? 64")
set (action_format
  extensions/p4_tests/p4_14/11-AssignChooseDest.p4
  extensions/p4_tests/p4_14/c1/COMPILER-326/case2035.p4
  extensions/p4_tests/p4_14/switch_20160602/switch.p4
  )
foreach (t ${action_format})
  p4c_add_xfail_reason("tofino" ${t} ${reason})
endforeach()

# used to be: BRIG-129 & BRIG-183
set (reason "No phv record")
set (no_phv_record
  extensions/p4_tests/p4_16/clone-bmv2.p4
  extensions/p4_tests/p4_14/test_checksum.p4
  extensions/p4_tests/p4_14/test_config_102_clone.p4
  extensions/p4_tests/p4_14/test_config_303_static_table.p4
  extensions/p4_tests/p4_14/c1/COMPILER-413/mirror_test.p4
  )
foreach (t ${no_phv_record})
  p4c_add_xfail_reason("tofino" ${t} ${reason})
endforeach()

set (reason "warning: Program does not contain a `main' module")
set (no_main
  extensions/p4_tests/p4_16/bloom_filter.p4
  extensions/p4_tests/p4_16/flowlet_switching.p4
  extensions/p4_tests/p4_16/stateful_alu.p4
  )
foreach (t ${no_main})
  p4c_add_xfail_reason("tofino" ${t} ${reason})
endforeach()

# BRIG-179
set (reason "Could not find type of")
set (brig_179
  extensions/p4_tests/p4_16/stful.p4
  extensions/p4_tests/p4_16/tna-salu.p4
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
foreach (t ${brig_179})
  p4c_add_xfail_reason("tofino" ${t} ${reason})
endforeach()

# BRIG-67
# was also BRIG-143
# blackbox type unification failures (JIRA #BRIG-30, #COMPILER-341)
#  extensions/p4_tests/p4_14/test_config_205_modify_field_from_hash.p4
#
set (reason "Cannot unify Type")
set (brig_67
  extensions/p4_tests/p4_14/02-FlexCounterActionProfile.p4
  extensions/p4_tests/p4_14/test_config_172_stateful_heavy_hitter.p4
  extensions/p4_tests/p4_14/test_config_205_modify_field_from_hash.p4
  extensions/p4_tests/p4_14/test_config_214_full_stats.p4
  extensions/p4_tests/p4_14/test_config_295_polynomial_hash.p4
  extensions/p4_tests/p4_14/test_config_308_hash_96b.p4
  extensions/p4_tests/p4_14/test_config_311_hash_adb.p4
  extensions/p4_tests/p4_14/jenkins/stful/stful.p4
  )
foreach (t ${brig_67})
  p4c_add_xfail_reason("tofino" ${t} ${reason})
endforeach()

# BRIG-102
p4c_add_xfail_reason("tofino"
  extensions/p4_tests/p4_14/test_config_235_funnel_shift.p4
  "syntax error, unexpected ','")

# BRIG-105
set (reason "No register named")
set (brig_105
  extensions/p4_tests/p4_14/04-FullPHV3.p4
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
foreach (t ${brig_105})
  p4c_add_xfail_reason("tofino" ${t} ${reason})
endforeach()

# BRIG-113
set (reason "Input xbar hash.*conflict in")
set (brig_113
  extensions/p4_tests/p4_14/09-MatchNoDep.p4
  extensions/p4_tests/p4_14/10-MatchNoDep1.p4
  extensions/p4_tests/p4_14/hash_calculation_max_size.p4
  extensions/p4_tests/p4_14/hash_calculation_multiple.p4
  extensions/p4_tests/p4_14/test_config_129_various_exact_match_keys.p4
  extensions/p4_tests/p4_14/test_config_96_hash_data.p4
  extensions/p4_tests/p4_14/c1/COMPILER-235/case1737_1.p4
  extensions/p4_tests/p4_14/c1/COMPILER-235/vag1737_1.p4
  )
foreach (t ${brig_113})
  p4c_add_xfail_reason("tofino" ${t} ${reason})
endforeach()

# Fail on purpose due to action profiles not being mutually exclusive
set (reason "Tables .* and .* are not mutually exclusive")
set (shared_action_profile
  extensions/p4_tests/p4_14/action_profile_not_shared.p4
  extensions/p4_tests/p4_14/action_profile_next_stage.p4
  testdata/p4_16_samples/action_selector_shared-bmv2.p4
  )
foreach (t ${shared_action_profile})
  p4c_add_xfail_reason("tofino" ${t} ${reason})
endforeach()

set (reason "error: : condition too complex")
set (gateway_cond
  extensions/p4_tests/p4_14/07-MacAddrCheck.p4
  extensions/p4_tests/p4_14/08-MacAddrCheck1.p4
  )
foreach (t ${gateway_cond})
  p4c_add_xfail_reason("tofino" ${t} ${reason})
endforeach()

# BRIG_132
set (reason "Unhandled InstanceRef type")
set (instanceref
  testdata/p4_16_samples/union-bmv2.p4
  testdata/p4_16_samples/union-valid-bmv2.p4
  testdata/p4_16_samples/union1-bmv2.p4
  testdata/p4_16_samples/union2-bmv2.p4
  testdata/p4_16_samples/union3-bmv2.p4
  testdata/p4_16_samples/union4-bmv2.p4
  testdata/p4_16_samples/verify-bmv2.p4
  )
foreach (t ${instanceref})
  p4c_add_xfail_reason("tofino" ${t} ${reason})
endforeach()

# The PHV allocator places h.v and h.$valid in the same container, even though
# one is metadata and one is not, and moreover one is deparsed and one is not.
# ValidateAllocation reports this problem:
#     warning: Deparsed container B15 contains some non-deparsed fields: ( 22:ingress::h.v<1> I off=0 ref deparsed /phv_4,PHV-79;/|phv_4,0..0|[0:0]->[B15](6);, 45:ingress::h.$valid<1> I off=0 ref pov /pov_7,PHV-79;/|pov_7,0..0|[0:0]->[B15](7); )
#     warning: Deparsed container B15 contains non-bridged metadata fields: ( 22:ingress::h.v<1> I off=0 ref deparsed /phv_4,PHV-79;/|phv_4,0..0|[0:0]->[B15](6);, 45:ingress::h.$valid<1> I off=0 ref pov /pov_7,PHV-79;/|pov_7,0..0|[0:0]->[B15](7); )
#     warning: Deparsed container B15 contains a mix of metadata and non-metadata fields: ( 22:ingress::h.v<1> I off=0 ref deparsed /phv_4,PHV-79;/|phv_4,0..0|[0:0]->[B15](6);, 45:ingress::h.$valid<1> I off=0 ref pov /pov_7,PHV-79;/|pov_7,0..0|[0:0]->[B15](7); )
#     warning: Container B15 contains deparsed header fields, but it has unused bits: ( 22:ingress::h.v<1> I off=0 ref deparsed /phv_4,PHV-79;/|phv_4,0..0|[0:0]->[B15](6);, 45:ingress::h.$valid<1> I off=0 ref pov /pov_7,PHV-79;/|pov_7,0..0|[0:0]->[B15](7); )
# This causes the parser code to be unable to find a valid extractor allocation.
set (reason "Ran out of phv output slots")
set (phv_slots
  extensions/p4_tests/p4_14/test_config_236_stateful_read_bit.p4
  extensions/p4_tests/p4_14/test_config_93_push_and_pop.p4
  extensions/p4_tests/p4_14/test_config_95_first_meter_table.p4
  testdata/p4_16_samples/table-entries-valid-bmv2.p4
  )
foreach (t ${phv_slots})
  p4c_add_xfail_reason("tofino" ${t} ${reason})
endforeach()

# failure due to too restrictive constraint of full words in action data bus allocation
# also: BRIG-56, BRIG-182
set (reason "Can't fit table .* in .* by itself")
set (brig_182
  extensions/p4_tests/p4_14/adb_shared3.p4
  extensions/p4_tests/p4_14/test_config_297_big_metadata.p4
  extensions/p4_tests/p4_14/jenkins/smoke_large_tbls/smoke_large_tbls.p4
  )
foreach (t ${brig_182})
  p4c_add_xfail_reason("tofino" ${t} ${reason})
endforeach()

# BRIG-146 (also was BRIG-133)
set (reason "alias for .* has out of range index from allowed")
set (brig_146
  extensions/p4_tests/p4_14/adjust_instr5.p4
  extensions/p4_tests/p4_14/test_config_112_no_phase_0_case_action_width_too_big.p4
  )
foreach (t ${brig_146})
  p4c_add_xfail_reason("tofino" ${t} ${reason})
endforeach()

# BRIG-149
set (reason "Syntax error, expecting identifier or operation or integer")
p4c_add_xfail_reason("tofino"
  extensions/p4_tests/p4_14/adjust_instr7.p4
  ${reason})

# BRIG-117
set (reason "match bus conflict")
p4c_add_xfail_reason("tofino"
  extensions/p4_tests/p4_14/gateway_and_big_table.p4
  ${reason})

# BRIG-119
set (reason "Can't combine hash_dist units in")
set (brig_119
  extensions/p4_tests/p4_14/hash_calculation_two_hash1.p4
  extensions/p4_tests/p4_14/hash_calculation_two_hash2.p4
  extensions/p4_tests/p4_14/test_config_13_first_selection.p4
  extensions/p4_tests/p4_14/test_config_300_multi_hash.p4
  )
foreach (t ${brig_119})
  p4c_add_xfail_reason("tofino" ${t} ${reason})
endforeach()
set (reason "hash expression width mismatch")
set (brig_119
  extensions/p4_tests/p4_14/test_config_100_hash_action.p4
  extensions/p4_tests/p4_14/test_config_209_pack_hash_dist.p4
  )
foreach (t ${brig_119})
  p4c_add_xfail_reason("tofino" ${t} ${reason})
endforeach()

# New failures with action bus working in compiler
set (reason "Two containers in the same action are at the same place?")
p4c_add_xfail_reason("tofino"
  extensions/p4_tests/p4_14/test_config_101_switch_msdc.p4
  ${reason})

# Same Name Conversion Bug
set (reason "boost::too_few_args: format-string referred to more arguments than were passed")
p4c_add_xfail_reason("tofino"
  extensions/p4_tests/p4_14/shared_names.p4
  ${reason})

set (reason "(throwing|uncaught exception).*std::out_of_range")
p4c_add_xfail_reason("tofino"
  extensions/p4_tests/p4_14/switch_l2_profile_tofino.p4
  ${reason})

# BRIG-99
set (reason "Missing color_maprams in meter table")
p4c_add_xfail_reason("tofino"
  extensions/p4_tests/p4_14/test_config_123_meter_2.p4
  ${reason})

set (reason "Assertion failed: (rv < 0 || rv == off)")
p4c_add_xfail_reason("tofino"
  extensions/p4_tests/p4_14/test_config_86_multiple_action_widths_for_indirect_action.p4
  ${reason})

set (reason "Expected 3 operands for execute_meter")
set (meter_pre_color
  extensions/p4_tests/p4_14/test_config_125_meter_pre_color.p4
  extensions/p4_tests/p4_14/test_config_126_meter_pre_color_2.p4
  extensions/p4_tests/p4_14/test_config_127_meter_pre_color_3.p4
  extensions/p4_tests/p4_14/test_config_132_meter_pre_color_4.p4
  )
foreach (t ${meter_pre_color})
  p4c_add_xfail_reason("tofino" ${t} ${reason})
endforeach()

set (reason "error: port: expected a field list")
p4c_add_xfail_reason("tofino"
  extensions/p4_tests/p4_14/test_config_144_recirculate.p4
  ${reason})

# various stateful
# Signed 1-bit field not allowed in P4_16 (and really makes no sense?)
p4c_add_xfail_reason("tofino"
  extensions/p4_tests/p4_14/test_config_160_stateful_single_bit_mode.p4
  "error: int<1>: Signed types cannot be 1-bit wide")

p4c_add_xfail_reason("tofino"
  extensions/p4_tests/p4_14/test_config_163_stateful_table_math_unit.p4
  "Changing type of")

p4c_add_xfail_reason("tofino"
  extensions/p4_tests/p4_14/test_config_169_stateful_sflow_sequence.p4
  "Can't reference memory in")

p4c_add_xfail_reason("tofino"
  extensions/p4_tests/p4_14/test_config_184_stateful_bug1.p4
  "must be at .* to be used in stateful table")

p4c_add_xfail_reason("tofino"
  extensions/p4_tests/p4_14/test_config_195_stateful_predicate_output.p4
  "Unrecognized AttribLocal combined_predicate")

p4c_add_xfail_reason("tofino"
  extensions/p4_tests/p4_14/test_config_199_stateful_constant_index.p4
  "recursion failure")

p4c_add_xfail_reason("tofino"
  extensions/p4_tests/p4_14/test_config_206_stateful_logging.p4
  "Unknown method .* in stateful_alu")

# conflict between blackbox meter and builtin meter
set (reason "P4_14 extern type not fully supported")
set (p4_14_externs
  extensions/p4_tests/p4_14/test_config_185_first_lpf.p4
  extensions/p4_tests/p4_14/test_config_201_meter_constant_index.p4
  extensions/p4_tests/p4_14/switch/p4src/switch.p4
  )
foreach (t ${p4_14_externs})
  p4c_add_xfail_reason("tofino" ${t} ${reason})
endforeach()

p4c_add_xfail_reason("tofino"
  extensions/p4_tests/p4_14/test_config_192_stateful_driven_by_hash.p4
  "hash_dist .* not defined in table")

# COMPILER-329
set (reason "error: : Width cannot be negative or zero")
set (compiler_329
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
  extensions/p4_tests/p4_14/c2/COMPILER-475/case2600.p4
  extensions/p4_tests/p4_14/c2/COMPILER-502/case2675.p4
  extensions/p4_tests/p4_14/c2/COMPILER-510/case2682.p4
  extensions/p4_tests/p4_14/c2/COMPILER-514/balancer_one.p4
  extensions/p4_tests/p4_14/c2/COMPILER-533/case2736.p4
  extensions/p4_tests/p4_14/c2/COMPILER-537/case2834.p4
  extensions/p4_tests/p4_14/c3/COMPILER-393/case2277.p4
  extensions/p4_tests/p4_14/jenkins/drivers_test/drivers_test_one.p4
  extensions/p4_tests/p4_14/jenkins/meters/meters_one.p4
  )
foreach (t ${compiler_329})
  p4c_add_xfail_reason("tofino" ${t} ${reason})
endforeach()

# COMPILER-540
set (reason "error: : direct access to indirect register")
set (compiler_540
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
foreach (t ${compiler_540})
  p4c_add_xfail_reason("tofino" ${t} ${reason})
endforeach()

# BRIG-28
# P4_14->16 unhandled primitives
# also BRIG-180
#  extensions/p4_tests/p4_14/test_config_284_swap_primitive.p4
set (reason "Unhandled primitive")
set (brig_28
  extensions/p4_tests/p4_14/test_config_182_warp_primitive.p4
  extensions/p4_tests/p4_14/test_config_183_sample_e2e.p4
  extensions/p4_tests/p4_14/test_config_191_invalidate.p4
  extensions/p4_tests/p4_14/test_config_284_swap_primitive.p4
  extensions/p4_tests/p4_14/c1/COMPILER-532/case2807.p4
  )
foreach (t ${brig_28})
  p4c_add_xfail_reason("tofino" ${t} ${reason})
endforeach()

set (reason "error: : conditional assignment not supported")
set (cond_assign
  extensions/p4_tests/p4_14/test_config_219_modify_field_conditionally.p4
  testdata/p4_16_samples/issue232-bmv2.p4
  testdata/p4_16_samples/issue242.p4
  testdata/p4_16_samples/issue420.p4
  testdata/p4_16_samples/issue512.p4
  )
foreach (t ${cond_assign})
  p4c_add_xfail_reason("tofino" ${t} ${reason})
endforeach()

# BRIG-181
set (reason "parameter .* must be bound")
set (brig_181
  extensions/p4_tests/p4_14/test_config_291_default_action.p4
  extensions/p4_tests/p4_14/c1/COMPILER-503/case2678.p4
  extensions/p4_tests/p4_14/c1/COMPILER-505/case2690.p4
  )
foreach (t ${brig_181})
  p4c_add_xfail_reason("tofino" ${t} ${reason})
endforeach()

#BRIG-139
set (reason "syntax error, unexpected")
set (brig_139
  extensions/p4_tests/p4_14/test_config_307_dyn_selection.p4
  extensions/p4_tests/p4_14/test_config_309_wide_dyn_selection.p4
  extensions/p4_tests/p4_14/test_config_314_sym_hash.p4
  extensions/p4_tests/p4_14/test_config_315_sym_hash_neg_test_1.p4
  extensions/p4_tests/p4_14/test_config_316_sym_hash_neg_test_2.p4
  extensions/p4_tests/p4_14/test_config_317_sym_hash_neg_test_3.p4
  extensions/p4_tests/p4_14/test_config_318_sym_hash_neg_test_4.p4
  extensions/p4_tests/p4_14/test_config_319_sym_hash_neg_test_5.p4
  extensions/p4_tests/p4_14/c4/COMPILER-529/dnets_bng_case1.p4
  extensions/p4_tests/p4_14/c4/COMPILER-529/dnets_bng_case2.p4
  extensions/p4_tests/p4_14/jenkins/mau_mem_test/mau_mem_test.p4
  extensions/p4_tests/p4_14/jenkins/mau_tcam_test/mau_tcam_test.p4
  )
foreach (t ${brig_139})
  p4c_add_xfail_reason("tofino" ${t} ${reason})
endforeach()

#BRIG-142
set (reason "error: .*: expected a field list")
set (brig_142
  extensions/p4_tests/p4_14/test_config_313_neg_test_addr_modes.p4
  extensions/p4_tests/p4_14/jenkins/pgrs/pgrs_one.p4
  )
foreach (t ${brig_142})
  p4c_add_xfail_reason("tofino" ${t} ${reason})
endforeach()

p4c_add_xfail_reason("tofino"
  extensions/p4_tests/p4_14/test_config_88_testing_action_data_allocation_3.p4
  "cluster.cpp: Operation ..... mixed gress")

p4c_add_xfail_reason("tofino"
  extensions/p4_tests/p4_14/c1/COMPILER-402/case2318.p4
  "constant value .* out of range for immediate")

#
set (reason "Table .* invoked from two different controls")
set (double_invoke
  extensions/p4_tests/p4_14/c1/COMPILER-263/case1795.p4
  extensions/p4_tests/p4_14/c1/COMPILER-264/case1822.p4
  extensions/p4_tests/p4_14/c1/COMPILER-271/case1834.p4
  extensions/p4_tests/p4_14/c1/COMPILER-273/case1832.p4
  extensions/p4_tests/p4_14/c1/COMPILER-275/case1841.p4
  extensions/p4_tests/p4_14/c1/COMPILER-276/case1844.p4
  extensions/p4_tests/p4_14/c1/COMPILER-282/case1864.p4
  extensions/p4_tests/p4_14/c1/COMPILER-347/switch_bug.p4
  extensions/p4_tests/p4_14/c1/COMPILER-352/netchain_one.p4
  extensions/p4_tests/p4_14/c1/COMPILER-353/case2088.p4
  extensions/p4_tests/p4_14/c1/COMPILER-355/netchain_two.p4
  extensions/p4_tests/p4_14/c1/COMPILER-357/case2100.p4
  extensions/p4_tests/p4_14/c1/COMPILER-358/case2110.p4
  extensions/p4_tests/p4_14/c1/COMPILER-384/case2240.p4
  extensions/p4_tests/p4_14/c1/COMPILER-385/case2247.p4
  extensions/p4_tests/p4_14/c1/COMPILER-386/test_config_286_stat_bugs.p4
  extensions/p4_tests/p4_14/c1/COMPILER-402/case2318.p4
#  extensions/p4_tests/p4_14/c1/COMPILER-413/mirror_test.p4
  extensions/p4_tests/p4_14/c1/COMPILER-414/case2387_1.p4
  extensions/p4_tests/p4_14/c1/COMPILER-415/case2386.p4
  extensions/p4_tests/p4_14/c1/COMPILER-499/case2560_min_2.p4
  )
foreach (t ${double_invoke})
  p4c_add_xfail_reason("tofino" ${t} ${reason})
endforeach()

# BRIG-137
set (reason "error: : not enough operands for primitive")
set (brig_137
  extensions/p4_tests/p4_14/jenkins/emulation/emulation.p4
  extensions/p4_tests/p4_14/jenkins/mau_test/mau_test.p4
  extensions/p4_tests/p4_14/jenkins/resubmit/resubmit.p4
  )
foreach (t ${brig_137})
  p4c_add_xfail_reason("tofino" ${t} ${reason})
endforeach()

# BRIG-138
set (reason "error: : action .* appears multiple times in table")
set (brig_138
  extensions/p4_tests/p4_14/c1/COMPILER-447/case2527.p4
  extensions/p4_tests/p4_14/c1/COMPILER-448/case2526.p4
  extensions/p4_tests/p4_14/c1/COMPILER-451/case2537.p4
  extensions/p4_tests/p4_14/c1/COMPILER-477/case2602.p4
  extensions/p4_tests/p4_14/c1/COMPILER-482/case2622.p4
  extensions/p4_tests/p4_14/c1/COMPILER-483/case2619.p4
  extensions/p4_tests/p4_14/c1/DRV-543/case2499.p4
  extensions/p4_tests/p4_14/jenkins/iterator/iterator.p4
  )
foreach (t ${brig_138})
  p4c_add_xfail_reason("tofino" ${t} ${reason})
endforeach()

# BRIG-140
set (reason "syntax error, unexpected IDENTIFIER")
set (brig_140
  extensions/p4_tests/p4_14/jenkins/parser_intr_md/parser_intr_md.p4
  extensions/p4_tests/p4_14/jenkins/pvs/pvs.p4
  )
foreach (t ${brig_140})
  p4c_add_xfail_reason("tofino" ${t} ${reason})
endforeach()

# BRIG-186: per_flow_enable
p4c_add_xfail_reason("tofino"
  extensions/p4_tests/p4_14/jenkins/stats_pi/stats_pi.p4
  "Field .* overlaps with .*")

p4c_add_xfail_reason("tofino"
  testdata/p4_16_samples/arith-bmv2.p4
  "(throwing|uncaught exception).*Backtrack::trigger")

#
set (reason "error: : source of modify_field invalid")
set (src_invalid
  testdata/p4_16_samples/arith1-bmv2.p4
  testdata/p4_16_samples/arith2-bmv2.p4
  testdata/p4_16_samples/concat-bmv2.p4
  )
foreach (t ${src_invalid})
  p4c_add_xfail_reason("tofino" ${t} ${reason})
endforeach()

set (reason "error: : shift count must be a constant in")
set (shift_count
  testdata/p4_16_samples/arith3-bmv2.p4
  testdata/p4_16_samples/arith4-bmv2.p4
  testdata/p4_16_samples/arith5-bmv2.p4
  )
foreach (t ${shift_count})
  p4c_add_xfail_reason("tofino" ${t} ${reason})
endforeach()


p4c_add_xfail_reason("tofino"
  testdata/p4_16_samples/inline-stack-bmv2.p4
  "metadata arrays not handled in")

p4c_add_xfail_reason("tofino"
  testdata/p4_16_samples/issue361-bmv2.p4
  "Invalid select case expression")

p4c_add_xfail_reason("tofino"
  testdata/p4_16_samples/issue510-bmv2.p4
  "Couldn't resolve computed extract in state start")

set (reason "package .*: unexpected type")
set (package_decl
  testdata/p4_16_samples/issue584-1.p4
  testdata/p4_16_samples/noMatch.p4
  testdata/p4_16_samples/pred.p4
  testdata/p4_16_samples/pred1.p4
  testdata/p4_16_samples/pred2.p4
  )
foreach (t ${package_decl})
  p4c_add_xfail_reason("tofino" ${t} ${reason})
endforeach()

set (reason "Exiting with SIGSEGV")
set (crash_tests
  testdata/p4_14_samples/flowlet_switching.p4
  testdata/p4_16_samples/flowlet_switching-bmv2.p4
  testdata/p4_16_samples/inline-bmv2.p4
  testdata/p4_16_samples/inline1-bmv2.p4
  )
foreach (t ${crash_tests})
  p4c_add_xfail_reason("tofino" ${t} ${reason})
endforeach()

# Tofino expected failures (Glass fails as well)
p4c_add_xfail_reason("tofino"
  testdata/p4_14_samples/issue583.p4
  "ERROR: Unhandled type of Expression")
p4c_add_xfail_reason("tofino"
  testdata/p4_14_samples/counter.p4
  "Tofino does not allow meters to use different address schemes on one table")
p4c_add_xfail_reason("tofino"
  testdata/p4_14_samples/copy_to_cpu.p4
  "Too much data for parse matcher")
p4c_add_xfail_reason("tofino"
  testdata/p4_14_samples/action_inline.p4
  "Constant lookup does not match the ActionFormat")
