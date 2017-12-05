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
  # default drop packet instead of writing to port 0
  testdata/p4_16_samples/issue635-bmv2.p4
  testdata/p4_16_samples/issue655-bmv2.p4
  )

  p4c_add_xfail_reason("tofino"
    "mismatch from expected.*at byte 0x"
    extensions/p4_tests/p4_16/stack_valid.p4
    )

endif() # HARLYN_STF

# add the failures with no reason
p4c_add_xfail_reason("tofino" "" ${TOFINO_XFAIL_TESTS})

# BRIG-103
p4c_add_xfail_reason("tofino"
  "instruction slot [0-9]+ used multiple times in action"
  testdata/p4_14_samples/instruct1.p4
  extensions/p4_tests/p4_14/instruct1.p4
  extensions/p4_tests/p4_14/action_conflict_2.p4
  )

# We need a deposit_field instruction, but we fail to select it.
p4c_add_xfail_reason("tofino"
  "instruction slot [0-9]+ used multiple times in action"
  extensions/p4_tests/p4_14/15-SetMetadata.p4
  extensions/p4_tests/p4_14/16-WrongSizeInfiniteLoop.p4
  )

# BRIG-104
p4c_add_xfail_reason("tofino"
  "Unhandled action bitmask constraint"
  extensions/p4_tests/p4_14/13-IngressEgressConflict.p4
  extensions/p4_tests/p4_16/brig-42.p4
  testdata/p4_14_samples/mac_rewrite.p4
  )

# Fails due to complex expressions in the parser that our hardware can't support.
p4c_add_xfail_reason("tofino"
  "error: Assignment cannot be supported in the parser"
  testdata/p4_16_samples/scalarmeta-bmv2.p4
  testdata/p4_16_samples/issue281.p4
  testdata/p4_14_samples/axon.p4
  testdata/p4_16_samples/stack_complex-bmv2.p4
  testdata/p4_16_samples/issue737-bmv2.p4
  )

# BRIG-107
p4c_add_xfail_reason("tofino"
  "No field named counter_addr in format"
  testdata/p4_14_samples/13-Counters1and2.p4
  testdata/p4_14_samples/14-Counter.p4
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
  )

# BRIG-109
p4c_add_xfail_reason("tofino"
  "Couldn't resolve computed value for select"
  # XXX(seth): This code just uses packet_in.lookahead() in a way which isn't supported yet.
  testdata/p4_16_samples/issue355-bmv2.p4
  # this one should be easy to handle, but hits this issue
  testdata/p4_16_samples/issue1000-bmv2.p4
  )

# Too big a select key (96 bits) for tofino to match in one parser state.  Could be split into
# mulitple states?
p4c_add_xfail_reason("tofino"
  "error: Too much data for parse matcher"
  testdata/p4_16_samples/issue995-bmv2.p4
  )

# varbit extracts don't work in parser
p4c_add_xfail_reason("tofino"
  "Wrong number of arguments for method call"
  testdata/p4_16_samples/issue447-bmv2.p4
  testdata/p4_16_samples/issue447-1-bmv2.p4
  testdata/p4_16_samples/issue447-2-bmv2.p4
  testdata/p4_16_samples/issue447-3-bmv2.p4
  testdata/p4_16_samples/issue447-4-bmv2.p4
  testdata/p4_16_samples/issue1025-bmv2.p4
  )
# varbit not handled in backend
p4c_add_xfail_reason("tofino"
  "Unhandled InstanceRef type"
  testdata/p4_16_samples/issue447-5-bmv2.p4
  )

# BRIG-112
p4c_add_xfail_reason("tofino"
  "ALU ops cannot operate on slices"
  extensions/p4_tests/p4_14/c1/COMPILER-228/case1644.p4
  )

p4c_add_xfail_reason("tofino"
  "Too much data for parse matcher"
  testdata/p4_14_samples/source_routing.p4
  )

p4c_add_xfail_reason("tofino"
  "Value too large"
  extensions/p4_tests/p4_14/test_config_88_testing_action_data_allocation_3.p4
  )

# Checksum16 is deprecated
p4c_add_xfail_reason("tofino"
  "Could not find declaration for"
  extensions/p4_tests/p4_16/ipv4_options.p4
  )

# BRIG-141
p4c_add_xfail_reason("tofino"
"No field named parser_counter in"
  extensions/p4_tests/p4_14/c1/COMPILER-384/case2240.p4
  extensions/p4_tests/p4_14/jenkins/pctr/pctr.p4
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
  "IR structure not yet handled by the ActionAnalysis pass"
  extensions/p4_tests/p4_14/test_config_235_funnel_shift.p4
  )

p4c_add_xfail_reason("tofino"
  "error: tofino supports up to 12 stages"
  extensions/p4_tests/p4_14/jenkins/alpm_test/alpm_test.p4
  extensions/p4_tests/p4_14/jenkins/perf_test_alpm/perf_test_alpm_one.p4
  extensions/p4_tests/p4_14/jenkins/clpm/clpm.p4
  extensions/p4_tests/p4_14/jenkins/multi_device/multi_device.p4
  )

# BRIG-113
p4c_add_xfail_reason("tofino"
  "Input xbar hash.*conflict in"
  )

p4c_add_xfail_reason("tofino"
# Fail on purpose due to action profiles not being mutually exclusive
  "Tables .* and .* are not mutually exclusive"
  extensions/p4_tests/p4_14/action_profile_not_shared.p4
  extensions/p4_tests/p4_14/action_profile_next_stage.p4
  testdata/p4_16_samples/action_selector_shared-bmv2.p4
  extensions/p4_tests/p4_14/c1/COMPILER-235/vag1662.p4
  )

p4c_add_xfail_reason("tofino"
  "error: : condition too complex"
  extensions/p4_tests/p4_14/07-MacAddrCheck.p4
  extensions/p4_tests/p4_14/08-MacAddrCheck1.p4
  testdata/p4_14_samples/issue894.p4
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
  extensions/p4_tests/p4_14/test_config_13_first_selection.p4
  extensions/p4_tests/p4_14/test_config_297_big_metadata.p4
  extensions/p4_tests/p4_14/jenkins/smoke_large_tbls/smoke_large_tbls.p4
  )

p4c_add_xfail_reason("tofino"
  "Can't fit the minimum number of table .* entries within the memories"
  extensions/p4_tests/p4_14/dileep8.p4
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

p4c_add_xfail_reason("tofino"
  "Syntax error, expecting list"
  testdata/p4_14_samples/issue1057.p4
  )

# various stateful
# Signed 1-bit field not allowed in P4_16 (and really makes no sense?)
p4c_add_xfail_reason("tofino"
  "error: int<1>: Signed types cannot be 1-bit wide"
  extensions/p4_tests/p4_14/test_config_160_stateful_single_bit_mode.p4
  )

p4c_add_xfail_reason("tofino"
  "Can't combine hash_dist units in 16 bit operation"
  extensions/p4_tests/p4_14/test_config_184_stateful_bug1.p4
  )

p4c_add_xfail_reason("tofino"
  "Unrecognized AttribLocal combined_predicate"
  extensions/p4_tests/p4_14/test_config_195_stateful_predicate_output.p4
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
  "conflicting memory use between .* and .*"
  extensions/p4_tests/p4_14/jenkins/fr_test/fr_test.p4
  # This is an ATCAM failure due to a stage split being in the same stage.  Much more subtle
  # now fails in PHV allocation
  # extensions/p4_tests/p4_14/c1/COMPILER-494/case2560_min.p4
  )

p4c_add_xfail_reason("tofino"
  "Can't fit table .* in input xbar by itself"
  extensions/p4_tests/p4_14/test_config_103_first_phase_0.p4
  )

p4c_add_xfail_reason("tofino"
  "Wrong number of arguments for method call"
  testdata/p4_16_samples/checksum1-bmv2.p4
  )

# Specifically to save the error message
p4c_add_xfail_reason("tofino"
  "(throwing|uncaught exception).*Backtrack::trigger"
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
  "Invalid select case expression"
  testdata/p4_16_samples/issue361-bmv2.p4
  )

# This program tries to assign an error value to a metadata field.
p4c_add_xfail_reason("tofino"
  "Couldn't resolve computed value for extract"
  testdata/p4_16_samples/issue510-bmv2.p4
  )

p4c_add_xfail_reason("tofino"
  "Exiting with SIGSEGV"
  extensions/p4_tests/p4_14/c1/COMPILER-635/case3468.p4
  extensions/p4_tests/p4_14/c1/COMPILER-637/case3478.p4
  testdata/p4_16_samples/issue461-bmv2.p4
  # Same Name Conversion Bug
  extensions/p4_tests/p4_14/shared_names.p4
  )

# new p4lang/p4c tests that fail
p4c_add_xfail_reason("tofino"
    "error: Syntax error, expecting identifier or operation"
    testdata/p4_14_samples/issue1013.p4
    )
p4c_add_xfail_reason("tofino"
    "Failed to transform the program into a P4Runtime-compatible form"
    testdata/p4_16_samples/issue841.p4
    )
p4c_add_xfail_reason("tofino"
    "visitor returned non-MethodCallExpression type"
    testdata/p4_16_samples/issue955.p4
    )
p4c_add_xfail_reason("tofino"
    "TablePlacement::place_table(.*): Assertion"
    testdata/p4_16_samples/issue986-1-bmv2.p4
    )
p4c_add_xfail_reason("tofino"
    "error: : The hash offset must be a power of 2 in a hash calculation hash.get_hash"
    testdata/p4_16_samples/issue1049-bmv2.p4
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

p4c_add_xfail_reason("tofino"
  "Ran out of tcam space in .* parser"
  testdata/p4_14_samples/issue583.p4
  )

p4c_add_xfail_reason("tofino"
  "Tofino does not allow stats to use different address schemes on one table"
  testdata/p4_14_samples/counter.p4
  extensions/p4_tests/p4_14/test_config_313_neg_test_addr_modes.p4
  )

p4c_add_xfail_reason("tofino"
  "Constant lookup does not match the ActionFormat"
  testdata/p4_14_samples/action_inline.p4
  )

p4c_add_xfail_reason("tofino"
  "Expected type T in digest to be a typeName"
  testdata/p4_16_samples/issue430-1-bmv2.p4
  )
# bug in instruction selection
p4c_add_xfail_reason("tofino"
  "visitor returned invalid type MAU::HashDist"
  testdata/p4_16_samples/issue430-bmv2.p4
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
  extensions/p4_tests/p4_14/c1/BRIG-5/case1715.p4
  extensions/p4_tests/p4_14/c1/COMPILER-133/full_tphv.p4
  extensions/p4_tests/p4_14/c1/COMPILER-235/vag1737_1.p4
  extensions/p4_tests/p4_14/c4/COMPILER-590/case3179.p4
  extensions/p4_tests/p4_14/c4/COMPILER-591/case3176.p4
  extensions/p4_tests/p4_14/jenkins/power/power.p4
  extensions/p4_tests/p4_14/test_config_101_switch_msdc.p4
  extensions/p4_tests/p4_14/c4/COMPILER-523/vag2774.p4
  testdata/p4_14_samples/parser_dc_full.p4
  switch_dc_basic
  testdata/p4_14_samples/port_vlan_mapping.p4
  switch_dc_basic
  extensions/p4_tests/p4_14/jenkins/stful/stful.p4
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

# Incorrect P4_14->16 conversion for varbit extract
p4c_add_xfail_reason("tofino"
  "Wrong number of arguments for method call: packet.extract"
  testdata/p4_14_samples/09-IPv4OptionsUnparsed.p4
  testdata/p4_14_samples/issue781.p4
  extensions/p4_tests/p4_14/c2/COMPILER-379/case2210.p4
  )

# Also incorrect P4_14->16 conversion for varbit extract, but a different
# symptom.
p4c_add_xfail_reason("tofino"
  "Cannot find declaration for len"
  testdata/p4_14_samples/TLV_parsing.p4
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
  testdata/p4_16_samples/issue907-bmv2.p4
  )

# BEGIN: XFAILS that match glass XFAILS

# parde physical adjacency constraint violated by mau phv_no_pack constraint
p4c_add_xfail_reason("tofino"
  "Header field .* is required to be allocated contiguously"
  extensions/p4_tests/p4_14/01-FlexCounter.p4
  extensions/p4_tests/p4_14/03-VlanProfile.p4
  extensions/p4_tests/p4_14/19-SimpleTrill.p4
  )

p4c_add_xfail_reason("tofino"
  "Action.* writes fields using the same assignment type but different source operands"
  extensions/p4_tests/p4_14/14-MultipleActionsInAContainer.p4
  )

p4c_add_xfail_reason("tofino"
  "Not all applies of table .* are mutually exclusive"
  extensions/p4_tests/p4_14/c1/COMPILER-100/exclusive_cf_one_action_fail_after.p4
  extensions/p4_tests/p4_14/c1/COMPILER-100/exclusive_cf_one_action_fail_before.p4
  )

p4c_add_xfail_reason("tofino"
  "Table .* is applied multiple times, and the next table information cannot correctly propagate"
  extensions/p4_tests/p4_14/c1/COMPILER-100/exclusive_cf_multiple_actions.p4
  extensions/p4_tests/p4_14/c1/COMPILER-100/exclusive_cf_fail_next_ptr.p4
  extensions/p4_tests/p4_14/c1/COMPILER-100/exclusive_cf_one_action.p4
  testdata/p4_14_samples/16-TwoReferences.p4
  extensions/p4_tests/p4_14/c1/COMPILER-125/16-TwoReferences.p4
  testdata/p4_16_samples/issue986-bmv2.p4
  )

# Brig/Glass do not follow P4_14 spec for 'drop' in the ingress pipeline
p4c_add_xfail_reason("tofino"
  "expected packet on port .* not seen"
  testdata/p4_14_samples/gateway1.p4
  testdata/p4_14_samples/gateway2.p4
  testdata/p4_14_samples/gateway3.p4
  testdata/p4_14_samples/gateway4.p4
  )

#END: XFAILS that match glass XFAILS

p4c_add_xfail_reason("tofino"
  "Table .* is applied multiple times, but the gateway conditionals determining"
  extensions/p4_tests/p4_14/c1/COMPILER-100/eth_addr_cmp.p4
  extensions/p4_tests/p4_14/eth_addr_cmp.p4
  )

# This code contains an implicit cast in an assignment in the parser; we need to
# convert it into a slice instead of just ignoring the cast.
p4c_add_xfail_reason("tofino"
  "Inferred incompatible alignments for field ig_intr_md_for_tm.ucast_egress_port"
  extensions/p4_tests/p4_14/test_config_101_switch_msdc.p4
)

p4c_add_xfail_reason("tofino"
   "Stage pragma provided to table .* has multiple parameters, while Brig currently"
   extensions/p4_tests/p4_14/test_config_131_placement_with_pragma.p4
)

# START: XFAILs with translation
# We fail to translate `resubmit()`.
p4c_add_xfail_reason("tofino"
  "Could not find declaration for standard_metadata"
  testdata/p4_14_samples/resubmit.p4
  )
# We fail to translate `standard_metadata.instance_type`.
p4c_add_xfail_reason("tofino"
  "Could not find declaration for standard_metadata"
  extensions/p4_tests/p4_14/c1/COMPILER-559/case2987.p4
  extensions/p4_tests/p4_14/switch_l2_profile.p4
  testdata/p4_14_samples/copy_to_cpu.p4
  testdata/p4_14_samples/packet_redirect.p4
  testdata/p4_14_samples/simple_nat.p4
  )
# We fail to translate `generate_digest()`.
p4c_add_xfail_reason("tofino"
  "Could not find declaration for standard_metadata"
  testdata/p4_14_samples/issue1058.p4
  )
# invalid tests, eg_intr_md.egress_port is read-only
p4c_add_xfail_reason("tofino"
  "Expression .* cannot be the target of an assignment"
  extensions/p4_tests/p4_14/test_config_249_simple_bridge.p4
  extensions/p4_tests/p4_14/test_config_6_sram_and_tcam_allocation.p4
  )
# invalid tests, issue604.p4 is a v1.1 testcase
# P4-14 program can not define extern
p4c_add_xfail_reason("tofino"
  "P4_14 extern not fully supported"
  testdata/p4_14_samples/issue604.p4
  )
# are we going to retire these switch profiles?
p4c_add_xfail_reason("tofino"
  "Structure header .* does not have a field"
  testdata/p4_14_samples/sai_p4.p4
  )

# BRIG-109
p4c_add_xfail_reason("tofino"
  "resolve computed"
  extensions/p4_tests/p4_14/c1/COMPILER-217/port_parser.p4
  )
p4c_add_xfail_reason("tofino"
  "hash offset must be a power of 2 in a hash calculation hash.get_hash"
  testdata/p4_14_samples/flowlet_switching.p4
  )
# ingress parser need access pkt_length
p4c_add_xfail_reason("tofino"
  "Could not find declaration for eg_intr_md"
  testdata/p4_14_samples/queueing.p4
  )
# resubmit size is 32 bytes which exceeds max size for tofino (8 bytes).
p4c_add_xfail_reason("tofino"
  "Assertion .*failed"
  extensions/p4_tests/p4_14/13-ResubmitMetadataSize.p4
  )

# backend bug
p4c_add_xfail_reason("tofino"
  "Slice is of IR structure not handled by ActionAnalysis"
  )
# need a good way to handle global action
p4c_add_xfail_reason("tofino"
  "Could not find declaration for drop"
  testdata/p4_16_samples/drop-bmv2.p4
  )
# need a good way to handle global action
p4c_add_xfail_reason("tofino"
  "Could not find declaration for send_to_cpu"
  testdata/p4_16_samples/std_meta_inlining.p4
  )
p4c_add_xfail_reason("tofino"
  "Action argument is not found to be allocated in the action format"
  testdata/p4_16_samples/slice-def-use1.p4
  )
# translation bug: smeta
p4c_add_xfail_reason("tofino"
  "Could not find declaration for smeta"
  testdata/p4_16_samples/issue677-bmv2.p4
  )
# missing support in translation: parser counter
p4c_add_xfail_reason("tofino"
  "parser counter translation is not implemented"
  extensions/p4_tests/p4_14/test_config_294_parser_loop.p4
  )
p4c_add_xfail_reason("tofino"
  "does not have a PHV allocation though it is used in an action"
  )
p4c_add_xfail_reason("tofino"
  "expression too complex for stateful alu"
  extensions/p4_tests/p4_14/jenkins/mau_test/mau_test.p4
  )
# missing support for stateful logging
p4c_add_xfail_reason("tofino"
  "Interface register_action does not have a method named execute_log"
  extensions/p4_tests/p4_14/test_config_206_stateful_logging.p4
  )

p4c_add_xfail_reason("tofino"
  "Could not find declaration for x"
  testdata/p4_16_samples/issue1001-bmv2.p4
  )

# END: XFAILs with translation

if (ENABLE_STF2PTF AND PTF_REQUIREMENTS_MET)
  # STF2PTF tests that fail

  p4c_add_xfail_reason("tofino"
    "AssertionError: Expected packet was not received on device"
    extensions/p4_tests/p4_14/action_default_multiple.p4
    extensions/p4_tests/p4_14/adb_shared2.p4
    extensions/p4_tests/p4_14/adjust_instr3.p4
    extensions/p4_tests/p4_16/stack_valid.p4
    testdata/p4_14_samples/07-MultiProtocol.p4
    testdata/p4_14_samples/instruct5.p4
    testdata/p4_14_samples/tmvalid.p4
    testdata/p4_16_samples/issue635-bmv2.p4
    testdata/p4_16_samples/issue655-bmv2.p4
    extensions/p4_tests/p4_14/stateful2.p4
    extensions/p4_tests/p4_16/multiple_apply1.p4
    extensions/p4_tests/p4_16/cast_widening_set.p4
    extensions/p4_tests/p4_16/cast_narrowing_set.p4
    extensions/p4_tests/p4_16/container_dependency.p4
    # Brig/Glass do not follow P4_14 spec for 'drop' in the ingress pipeline
    testdata/p4_14_samples/gateway1.p4
    testdata/p4_14_samples/gateway2.p4
    testdata/p4_14_samples/gateway3.p4
    testdata/p4_14_samples/gateway4.p4
    )

  p4c_add_xfail_reason("tofino"
    "StatusCode.UNKNOWN, Error when adding match entry to target"
    testdata/p4_14_samples/exact_match_valid1.p4
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

# Detailed error  "<_Rendezvous of RPC that terminated with (StatusCode.INVALID_ARGUMENT, Cannot map table entry to handle)>"
  p4c_add_xfail_reason("tofino"
    "StatusCode.INVALID_ARGUMENT, Cannot map table entry to handle"
    testdata/p4_14_samples/counter2.p4
    )

# BRIG-241
  p4c_add_xfail_reason("tofino"
    "AssertionError: Invalid match name .* for table .*"
    testdata/p4_14_samples/exact_match_mask1.p4
    )

endif() # ENABLE_STF2PTF AND PTF_REQUIREMENTS_MET

if (HARLYN_STF AND NOT ENABLE_STF2PTF)
  p4c_add_xfail_reason("tofino"
    ".* expected packet on port .* not seen"
    extensions/p4_tests/p4_16/multiple_apply1.p4
    extensions/p4_tests/p4_16/cast_widening_set.p4
    extensions/p4_tests/p4_16/cast_narrowing_set.p4
    extensions/p4_tests/p4_16/container_dependency.p4
    )
endif()  # STF FAILURE IN TNA

# XXX(cole): Temporarily override previous XFAILs with new failures related to
# PHV allocation.
p4c_add_xfail_reason("tofino"
  "PHV allocation was not successful"
  testdata/p4_14_samples/parser4.p4
  testdata/p4_14_samples/source_routing.p4
  testdata/p4_14_samples/parser1.p4
  testdata/p4_14_samples/parser2.p4
  testdata/p4_14_samples/03-FullPHV2.p4
  testdata/p4_14_samples/02-FullPHV1.p4
  extensions/p4_tests/p4_14/test_config_119_tcam_range_3.p4
  extensions/p4_tests/p4_14/03-VlanProfile.p4
  extensions/p4_tests/p4_14/23-SimpleMPLS.p4
  extensions/p4_tests/p4_14/test_config_237_hash_action_17_bits.p4
  extensions/p4_tests/p4_14/19-SimpleTrill.p4
  extensions/p4_tests/p4_14/01-FlexCounter.p4
  extensions/p4_tests/p4_14/c1/COMPILER-235/case1737_1.p4
  extensions/p4_tests/p4_14/c1/COMPILER-235/case1737.p4
  extensions/p4_tests/p4_14/c1/COMPILER-235/vag1737_1.p4
  extensions/p4_tests/p4_14/c1/COMPILER-242/case1679.p4
  extensions/p4_tests/p4_14/c1/COMPILER-351/case2079.p4
  extensions/p4_tests/p4_14/c1/COMPILER-358/case2110.p4
  extensions/p4_tests/p4_14/c1/COMPILER-353/case2088.p4
  extensions/p4_tests/p4_14/c1/BRIG-5/case1715.p4
  extensions/p4_tests/p4_14/c1/COMPILER-357/case2100.p4
  extensions/p4_tests/p4_14/c1/COMPILER-494/case2560_min.p4
  extensions/p4_tests/p4_14/c4/COMPILER-523/vag2774.p4
  extensions/p4_tests/p4_14/c1/COMPILER-415/case2386.p4
  extensions/p4_tests/p4_14/c1/COMPILER-326/case2035.p4
  extensions/p4_tests/p4_14/c6/COMPILER-603/loop.p4
  extensions/p4_tests/p4_14/c8/COMPILER-616/case3331.p4
  extensions/p4_tests/p4_14/c6/COMPILER-604/new_parser.p4
  testdata/p4_16_samples/issue983-bmv2.p4

  # Lack of cluster splitting:
  extensions/p4_tests/p4_14/c1/COMPILER-364/case2115.p4
  extensions/p4_tests/p4_14/c1/COMPILER-414/case2387.p4
  extensions/p4_tests/p4_14/c1/COMPILER-414/case2387_1.p4
  extensions/p4_tests/p4_14/c1/COMPILER-437/case2387_1.p4

  # Lack of container packing:
  extensions/p4_tests/p4_14/15-SetMetadata.p4
  extensions/p4_tests/p4_14/16-WrongSizeInfiniteLoop.p4
  )

p4c_add_xfail_reason("tofino"
  "error: Invalid slice of"
  testdata/p4_14_samples/instruct6.p4
  )

p4c_add_xfail_reason("tofino"
  "Due to lacking assembler support, cannot currently split hash distribution units"
  extensions/p4_tests/p4_14/hash_calculation_16.p4
  extensions/p4_tests/p4_14/test_config_300_multi_hash.p4
  extensions/p4_tests/p4_14/hash_calculation_two_hash2.p4
  extensions/p4_tests/p4_14/hash_calculation_multiple.p4
  extensions/p4_tests/p4_14/hash_calculation_two_hash1.p4
  extensions/p4_tests/p4_14/test_config_299_write_hash_keyless_table.p4
  extensions/p4_tests/p4_14/test_config_261_mutually_exclusive_src_ops.p4
  extensions/p4_tests/p4_14/test_config_184_stateful_bug1.p4
  )

p4c_add_xfail_reason("tofino"
  "the packing is too complicated due to either hash distribution or attached outputs"
  extensions/p4_tests/p4_14/test_config_96_hash_data.p4
  testdata/p4_16_samples/flowlet_switching-bmv2.p4
  )

p4c_add_xfail_reason("tofino"
  "Cannot find associated meter for the method call"
  extensions/p4_tests/p4_14/test_config_132_meter_pre_color_4.p4
  )

p4c_add_xfail_reason("tofino"
  "Action Data parameter not configured properly in ActionAnalysis pass"
  testdata/p4_14_samples/meter1.p4
  extensions/p4_tests/p4_14/hash_calculation_max_size.p4
  testdata/p4_16_samples/named_meter_bmv2.p4
  )

p4c_add_xfail_reason("tofino"
  "Can't allocate space on .*-bit part of action bus"
  extensions/p4_tests/p4_14/test_config_199_stateful_constant_index.p4
  extensions/p4_tests/p4_14/c1/COMPILER-342/netchain.p4
  extensions/p4_tests/p4_14/stateful3.p4
  extensions/p4_tests/p4_14/stateful2.p4
  )

p4c_add_xfail_reason("tofino"
  "error: set requires 2 operands"
  extensions/p4_tests/p4_14/test_config_157_random_number_generator.p4
  )

# BRIG-219
p4c_add_xfail_reason("tofino"
  "PHV allocation creates a container action impossible within a Tofino ALU"
  extensions/p4_tests/p4_14/14-MultipleActionsInAContainer.p4
  extensions/p4_tests/p4_14/action_conflict_1.p4
  extensions/p4_tests/p4_14/adjust_instr1.p4
  extensions/p4_tests/p4_14/test_config_248_pa_problem.p4
  extensions/p4_tests/p4_14/test_config_252_pa_required_packing.p4
  extensions/p4_tests/p4_14/test_config_256_pa_problem_4.p4
  extensions/p4_tests/p4_14/test_config_257_pa_problem_5.p4
  extensions/p4_tests/p4_14/c4/COMPILER-550/vag2899.p4
  extensions/p4_tests/p4_16/stack_valid.p4
  testdata/p4_14_samples/instruct5.p4
  )

p4c_add_xfail_reason("tofino"
  "error: .* must be at .* or .* on ixbar to be used in stateful table"
  extensions/p4_tests/p4_14/jenkins/multicast_scale/multicast_scale.p4
  )

p4c_add_xfail_reason("tofino"
  "Unhandled action bitmask constraint"
  extensions/p4_tests/p4_14/test_config_151_action_bus_allocation_2.p4
  extensions/p4_tests/p4_14/test_config_90_testing_action_data_allocation_3_with_fields_in_overhead.p4
  extensions/p4_tests/p4_14/test_config_50_action_data_different_size_fields.p4
  extensions/p4_tests/p4_16/cast_widening_set.p4
  switch_l2
  )

p4c_add_xfail_reason("tofino"
  "error: immediate.* is not on the action bus"
  extensions/p4_tests/p4_14/test_config_291_default_action.p4
  )

p4c_add_xfail_reason("tofino"
  "error: No phv record"
  # Instruction adjustment is not splitting an instruction?
  extensions/p4_tests/p4_14/test_config_163_stateful_table_math_unit.p4
  )

# XXX(cole): This will be fixed with SuperCluster splitting.
p4c_add_xfail_reason("tofino"
  "accumulate too many fields in CCGF"
  extensions/p4_tests/p4_14/test_config_236_stateful_read_bit.p4
  extensions/p4_tests/p4_14/test_config_216_phv_aff.p4
  extensions/p4_tests/p4_14/action_conflict_4.p4
  extensions/p4_tests/p4_14/test_config_259_large_non_multiple_8_bit.p4
  extensions/p4_tests/p4_14/action_conflict_3.p4
  extensions/p4_tests/p4_14/brig-11.p4
  )

p4c_add_xfail_reason("tofino"
  "No format in action table"
  extensions/p4_tests/p4_14/c7/COMPILER-623/case3375.p4
  )

p4c_add_xfail_reason("tofino"
  "Operands of arithmetic operations cannot be greater than 32b, but field .* has .*"
  extensions/p4_tests/p4_14/test_config_296_pragma_container.p4
  extensions/p4_tests/p4_14/test_config_258_wide_add.p4
  extensions/p4_tests/p4_14/c1/COMPILER-129/compiler129.p4
  testdata/p4_16_samples/arith-bmv2.p4
  switch_dc_basic
  )

p4c_add_xfail_reason("tofino"
  "Inferred incompatible alignments for field"
  extensions/p4_tests/p4_14/jenkins/parser_intr_md/parser_intr_md.p4
  )

p4c_add_xfail_reason("tofino"
  "invalid exact key expression"
  # This test attempts to match on a field of `error` type.
  testdata/p4_16_samples/issue1062-bmv2.p4
  )

p4c_add_xfail_reason("tofino"
  "header hdr is not byte-aligned"
  testdata/p4_16_samples/issue1062-1-bmv2.p4
  )

# BRIG-348
p4c_add_xfail_reason("tofino" "Compiler Bug" ${ONOS_FABRIC_P4})
