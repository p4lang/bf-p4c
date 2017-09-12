
set (P14_XFAIL_TESTS
  extensions/p4_tests/p4_14/02-FlexCounterActionProfile.p4
  extensions/p4_tests/p4_14/test_config_125_meter_pre_color.p4
  extensions/p4_tests/p4_14/test_config_126_meter_pre_color_2.p4
  extensions/p4_tests/p4_14/test_config_127_meter_pre_color_3.p4
  extensions/p4_tests/p4_14/test_config_132_meter_pre_color_4.p4
  extensions/p4_tests/p4_14/test_config_172_stateful_heavy_hitter.p4
  extensions/p4_tests/p4_14/test_config_160_stateful_single_bit_mode.p4
  extensions/p4_tests/p4_14/test_config_185_first_lpf.p4
  extensions/p4_tests/p4_14/test_config_201_meter_constant_index.p4
  extensions/p4_tests/p4_14/test_config_163_stateful_table_math_unit.p4
  extensions/p4_tests/p4_14/test_config_192_stateful_driven_by_hash.p4
  extensions/p4_tests/p4_14/test_config_166_stateful_generic_counter.p4
  extensions/p4_tests/p4_14/test_config_142_stateful_bfd.p4
  extensions/p4_tests/p4_14/test_config_195_stateful_predicate_output.p4
  extensions/p4_tests/p4_14/test_config_165_stateful_bfd_failure_detection.p4
  extensions/p4_tests/p4_14/test_config_184_stateful_bug1.p4
  extensions/p4_tests/p4_14/test_config_206_stateful_logging.p4
  extensions/p4_tests/p4_14/test_config_205_modify_field_from_hash.p4
  extensions/p4_tests/p4_14/test_config_214_full_stats.p4
  extensions/p4_tests/p4_14/shared_names.p4
  extensions/p4_tests/p4_14/c1/COMPILER-414/case2387.p4
  extensions/p4_tests/p4_14/c1/COMPILER-364/case2115.p4
  extensions/p4_tests/p4_14/c1/COMPILER-351/case2079.p4
  extensions/p4_tests/p4_14/c1/COMPILER-482/case2622.p4
  extensions/p4_tests/p4_14/c2/COMPILER-408/case2364.p4
  extensions/p4_tests/p4_14/c2/COMPILER-514/balancer_one.p4
  extensions/p4_tests/p4_14/c2/COMPILER-537/case2834.p4
  extensions/p4_tests/p4_14/c2/COMPILER-533/case2736.p4
  extensions/p4_tests/p4_14/c1/COMPILER-437/case2387_1.p4
  extensions/p4_tests/p4_14/c3/COMPILER-393/case2277.p4
  extensions/p4_tests/p4_14/jenkins/mau_test/mau_test.p4
  extensions/p4_tests/p4_14/jenkins/multi_device/multi_device.p4.p4
  extensions/p4_tests/p4_14/jenkins/meters/meters_one.p4
  extensions/p4_tests/p4_14/jenkins/drivers_test/drivers_test_one.p4
  extensions/p4_tests/p4_14/jenkins/pvs/pvs.p4
  extensions/p4_tests/p4_14/jenkins/parser_intr_md/parser_intr_md.p4
  extensions/p4_tests/p4_14/jenkins/pctr/pctr.p4
  extensions/p4_tests/p4_14/c1/COMPILER-260/case1799_1.p4
  extensions/p4_tests/p4_14/c1/COMPILER-260/case1799.p4
  extensions/p4_tests/p4_14/c1/COMPILER-262/case1804.p4
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
  extensions/p4_tests/p4_14/c1/COMPILER-414/case2387_1.p4
  extensions/p4_tests/p4_14/c1/COMPILER-415/case2386.p4
  extensions/p4_tests/p4_14/c1/COMPILER-447/case2527.p4
  extensions/p4_tests/p4_14/c1/COMPILER-448/case2526.p4
  extensions/p4_tests/p4_14/c1/COMPILER-451/case2537.p4
  extensions/p4_tests/p4_14/c1/COMPILER-477/case2602.p4
  extensions/p4_tests/p4_14/c1/COMPILER-483/case2619.p4
  extensions/p4_tests/p4_14/c1/COMPILER-499/case2560_min_2.p4
  extensions/p4_tests/p4_14/c1/DRV-543/case2499.p4
  extensions/p4_tests/p4_14/c2/COMPILER-392/case2266.p4
  extensions/p4_tests/p4_14/c2/COMPILER-400/case2314.p4
  extensions/p4_tests/p4_14/c2/COMPILER-401/case2308_bugged.p4
  extensions/p4_tests/p4_14/c2/COMPILER-420/case2433.p4
  extensions/p4_tests/p4_14/c2/COMPILER-421/case2434.p4
  extensions/p4_tests/p4_14/c2/COMPILER-426/case2475.p4
  extensions/p4_tests/p4_14/c2/COMPILER-443/case2514.p4
  extensions/p4_tests/p4_14/c2/COMPILER-466/case2563_with_nop.p4
  extensions/p4_tests/p4_14/c2/COMPILER-466/case2563_without_nop.p4
  extensions/p4_tests/p4_14/c2/COMPILER-475/case2600.p4
  extensions/p4_tests/p4_14/c2/COMPILER-502/case2675.p4
  extensions/p4_tests/p4_14/c2/COMPILER-510/case2682.p4
  extensions/p4_tests/p4_14/test_config_295_polynomial_hash.p4
  extensions/p4_tests/p4_14/test_config_308_hash_96b.p4
  extensions/p4_tests/p4_14/test_config_311_hash_adb.p4
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
  extensions/p4_tests/p4_14/test_config_261_mutually_exclusive_src_ops.p4
  extensions/p4_tests/p4_14/c1/COMPILER-532/case2807.p4
  extensions/p4_tests/p4_14/c1/COMPILER-632/case3459.p4
  extensions/p4_tests/p4_14/c1/COMPILER-608/case3263.p4
  extensions/p4_tests/p4_14/c1/COMPILER-593/case3011.p4
  extensions/p4_tests/p4_14/c1/COMPILER-589/comp589.p4
  extensions/p4_tests/p4_14/c1/COMPILER-588/comp588.p4
  extensions/p4_tests/p4_14/c1/COMPILER-588/comp588dce.p4
  extensions/p4_tests/p4_14/c1/COMPILER-585/comp585.p4
  extensions/p4_tests/p4_14/c1/COMPILER-579/case3085.p4
  extensions/p4_tests/p4_14/c1/COMPILER-577/comp577.p4
  extensions/p4_tests/p4_14/c1/COMPILER-576/case3042.p4
  extensions/p4_tests/p4_14/c1/COMPILER-575/case3041.p4
  extensions/p4_tests/p4_14/c1/COMPILER-568/case3026.p4
  extensions/p4_tests/p4_14/c1/COMPILER-568/case3026dce.p4
  extensions/p4_tests/p4_14/c1/COMPILER-567/case2807.p4
  extensions/p4_tests/p4_14/c1/COMPILER-562/case3005.p4
  extensions/p4_tests/p4_14/c1/COMPILER-559/case2987.p4
  extensions/p4_tests/p4_14/c1/COMPILER-548/case3011.p4
  extensions/p4_tests/p4_14/c1/COMPILER-548/case2895.p4
  extensions/p4_tests/p4_14/c1/COMPILER-637/case3478.p4
  extensions/p4_tests/p4_14/c1/COMPILER-635/case3468.p4
  extensions/p4_tests/p4_14/c2/COMPILER-599/case3230.p4
  extensions/p4_tests/p4_14/c5/COMPILER-594/comp594.p4
  extensions/p4_tests/p4_14/c7/COMPILER-623/case3375.p4
# BRIG-28
  extensions/p4_tests/p4_14/switch/p4src/switch.p4
  )
