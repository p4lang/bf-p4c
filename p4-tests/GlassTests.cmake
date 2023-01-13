include (ExternalProject)

set (GTS_ARISTA_PR
  # glass arista tests -> to be run in PR regressions
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-1019/case6894.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-1041/comp_1041.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-1066/test_config_414_container_valid_bit_for_tcam.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-1105/case8039.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-1105/test_config_417_disable_xbar_sharing.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-1113/case8138.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-1114/case8156.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-1151/test_config_424_unique_zeros_as_ones.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-1152/case8686.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-673/test_config_350_atcam_with_default_action.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-913/test_config_395_checksum_update_location.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-915/test_config_393_alias_dep.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-964/test_config_401_random_num.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-977/comp_977.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/DRV-543/case2499.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/MODEL-475/case9192.p4
)

p4c_add_bf_backend_tests("tofino" "tofino" "${TOFINO_P414_TEST_ARCH}" "base" "${GTS_ARISTA_PR}")

# Add additional flags to some customer tests
p4c_add_bf_backend_tests("tofino" "tofino" "${TOFINO_P414_TEST_ARCH}" "arista" "${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-868/comp_868.p4"
  "--backward-compatible -Xp4c=\"--no-power-check\" --disable-pragmas=pa_container_size")

p4c_add_bf_backend_tests("tofino" "tofino" "${TOFINO_P414_TEST_ARCH}" "arista" "${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-562/case3005.p4"
  "--backward-compatible -Xp4c=\"--no-power-check\"")

p4c_add_bf_backend_tests("tofino" "tofino" "${TOFINO_P414_TEST_ARCH}" "arista" "${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-576/case3042.p4"
  "--backward-compatible -Xp4c=\"--no-power-check\"")

p4c_add_bf_backend_tests("tofino" "tofino" "${TOFINO_P414_TEST_ARCH}" "arista" "${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-589/comp589.p4"
  "--backward-compatible -Xp4c=\"--no-power-check\"")

p4c_add_bf_backend_tests("tofino" "tofino" "${TOFINO_P414_TEST_ARCH}" "alibaba" "${CMAKE_CURRENT_SOURCE_DIR}/glass/alibaba/COMPILER-869/alpm_ali_cloud.p4"
  "--backward-compatible -Xp4c=\"--no-power-check\"")

set (GTS_ARISTA
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/BRIG-5/case1715.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-100/eth_addr_cmp.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-100/exclusive_cf_fail_next_ptr.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-100/exclusive_cf_multiple_actions.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-100/exclusive_cf_one_action_fail_after.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-100/exclusive_cf_one_action_fail_before.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-100/exclusive_cf_one_action.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-1168/comp_1168.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-1169/case8847.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-1170/case8862.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-1177/case8933.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-1181/case8969.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-1183/case9182.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-1189/case9294.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-1200/case9376.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-125/16-TwoReferences.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-129/compiler129.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-133/full_tphv.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-209/sizing.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-217/port_parser.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-219/test.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-227/case1642_split.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-227/case1642.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-228/case1644.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-233/case1662.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-234/case1803.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-235/case1737_1.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-235/case1737.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-235/vag1662.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-235/vag1737_1.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-242/case1679.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-254/case1744.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-256/case1765.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-257/case1770.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-260/case1799_1.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-260/case1799.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-262/case1804.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-263/case1795.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-264/case1822.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-271/case1834.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-273/case1832.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-275/case1841.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-276/case1844.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-282/case1864.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-295/vag1892.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-326/case2035.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-342/netchain.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-347/switch_bug.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-351/case2079.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-352/netchain_one.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-353/case2088.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-355/netchain_two.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-357/case2100.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-358/case2110.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-364/case2115.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-384/case2240.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-385/case2247.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-386/test_config_286_stat_bugs.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-402/case2318.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-413/mirror_test.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-414/case2387_1.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-414/case2387.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-415/case2386.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-437/case2387_1.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-447/case2527.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-448/case2526.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-451/case2537.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-477/case2602.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-482/case2622.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-483/case2619.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-494/case2560_min.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-499/case2560_min_2.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-503/case2678.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-505/case2690.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-530/vag2784.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-532/case2807.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-548/case2895.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-548/case3011.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-559/case2987.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-567/case2807.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-568/case3026.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-568/case3026dce.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-575/case3041.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-577/comp577.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-579/case3085.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-585/comp585.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-588/comp588.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-588/comp588dce.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-593/case3011.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-608/case3263.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-632/case3459.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-635/case3468.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-637/case3478.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-645/comp_645.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-648/comp648.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-650/case3597.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-666/case3696.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-674/case3730.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-721/case4015.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-725/comp_725.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-744/comp_744.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-751/case4256.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-752/test_config_372_init_issue.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-783/case4552.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-786/comp_786.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-799/case4571.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-818/case4954_new_fail.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-818/case4954.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-823/pipeline2-failing.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-870/vag5425.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-880/test_config_387_max_actions_pragma.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-883/case5521.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-897/case5577.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/arista/COMPILER-897/clone_e2e_no_residual.p4
)

p4c_add_bf_backend_tests("tofino" "tofino" "${TOFINO_P414_TEST_ARCH}" "base" "${GTS_ARISTA}")

foreach(t IN LISTS GTS_ARISTA)
  file(RELATIVE_PATH test_path ${P4C_SOURCE_DIR} ${t})
  p4c_add_test_label("tofino" "GTS_WEEKLY" ${test_path})
endforeach()

set (GTS_RDP
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/rdp/COMPILER-261/case1803.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/rdp/COMPILER-261/vag2241.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/rdp/COMPILER-379/case2210.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/rdp/COMPILER-383/case2241.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/rdp/COMPILER-392/case2266.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/rdp/COMPILER-400/case2314.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/rdp/COMPILER-401/case2308_bugged.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/rdp/COMPILER-408/case2364.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/rdp/COMPILER-420/case2433.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/rdp/COMPILER-421/case2434.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/rdp/COMPILER-426/case2475.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/rdp/COMPILER-443/case2514.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/rdp/COMPILER-466/case2563_with_nop.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/rdp/COMPILER-466/case2563_without_nop.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/rdp/COMPILER-475/case2600.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/rdp/COMPILER-502/case2675.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/rdp/COMPILER-510/case2682.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/rdp/COMPILER-514/balancer_one.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/rdp/COMPILER-533/case2736.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/rdp/COMPILER-537/case2834.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/rdp/COMPILER-599/case3230.p4
)

p4c_add_bf_backend_tests("tofino" "tofino" "${TOFINO_P414_TEST_ARCH}" "base" "${GTS_RDP}")

foreach(t IN LISTS GTS_RDP)
  file(RELATIVE_PATH test_path ${P4C_SOURCE_DIR} ${t})
  p4c_add_test_label("tofino" "GTS_WEEKLY" ${test_path})
endforeach()

set (GTS_NOVIFLOW
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/noviflow/case9296.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/noviflow/COMPILER-1003/case6738.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/noviflow/COMPILER-1006/case6738_2.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/noviflow/COMPILER-1026/case6830.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/noviflow/COMPILER-1028/case6962.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/noviflow/COMPILER-1132/case8417.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/noviflow/COMPILER-1165/case8808.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/noviflow/COMPILER-1175/comp_1175.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/noviflow/COMPILER-1186/case9213.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/noviflow/COMPILER-1186/case9213b.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/noviflow/COMPILER-564/case3825.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/noviflow/COMPILER-687/case3769.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/noviflow/COMPILER-688/06-Phase0.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/noviflow/COMPILER-842/comp_842.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/noviflow/COMPILER-842/mod_field_cond.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/noviflow/COMPILER-854/case5273.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/noviflow/COMPILER-922/case5792.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/noviflow/COMPILER-938/bitscopy_test.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/noviflow/COMPILER-960/case6162.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/noviflow/DRV-1092/drv_1092.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/noviflow/P4C-1984/p4c_1984_1.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/noviflow/P4C-1984/p4c_1984_2.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/noviflow/P4C-1984/p4c_1984_3.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/noviflow/P4C-1984/p4c_1984_4.p4
)

p4c_add_bf_backend_tests("tofino" "tofino" "${TOFINO_P414_TEST_ARCH}" "base" "${GTS_NOVIFLOW}")

foreach(t IN LISTS GTS_NOVIFLOW)
  file(RELATIVE_PATH test_path ${P4C_SOURCE_DIR} ${t})
  p4c_add_test_label("tofino" "GTS_WEEKLY" ${test_path})
endforeach()

# P4C-4718
bfn_add_determinism_test_with_args("tofino" "${TOFINO_P414_TEST_ARCH}"
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/noviflow/COMPILER-1186/case9213b.p4
  "--std=p4-14 -I${BFN_P4C_SOURCE_DIR}/glass/p4c_tofino/target/tofino/p4_lib")

set (GTS_ALIBABA
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/alibaba/COMPILER-1039/comp_1039.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/alibaba/COMPILER-1129/comp_1129.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/alibaba/COMPILER-1129b/comp_1129b.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/alibaba/COMPILER-1130/comp_1130.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/alibaba/COMPILER-1130/comp_1130b.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/alibaba/COMPILER-940/comp_940.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/alibaba/COMPILER-980/comp_980_repaired.p4
)

p4c_add_bf_backend_tests("tofino" "tofino" "${TOFINO_P414_TEST_ARCH}" "base" "${GTS_ALIBABA}")

foreach(t IN LISTS GTS_ALIBABA)
  file(RELATIVE_PATH test_path ${P4C_SOURCE_DIR} ${t})
  p4c_add_test_label("tofino" "GTS_WEEKLY" ${test_path})
endforeach()

set (GTS_KALOOM
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/kaloom/COMPILER-662/case3689.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/kaloom/COMPILER-753/case4263.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/kaloom/COMPILER-773/case4398.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/kaloom/COMPILER-789/big_state.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/kaloom/COMPILER-789/case4569.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/kaloom/COMPILER-839/leaf.p4
)

# since COMPILER-839/leaf.p4 has XFail that checks that it timeouts we need to
# set timeout explictly
p4c_add_bf_backend_tests("tofino" "tofino" "${TOFINO_P414_TEST_ARCH}" "base" "${GTS_KALOOM}" "-to 590")

foreach(t IN LISTS GTS_KALOOM)
  file(RELATIVE_PATH test_path ${P4C_SOURCE_DIR} ${t})
  p4c_add_test_label("tofino" "GTS_WEEKLY" ${test_path})
endforeach()

set (GTS_KEYSIGHT
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/keysight/COMPILER-1049/case7268.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/keysight/COMPILER-924/case5801.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/keysight/COMPILER-996/pktgen8.p4
)

p4c_add_bf_backend_tests("tofino" "tofino" "${TOFINO_P414_TEST_ARCH}" "base" "${GTS_KEYSIGHT}")

foreach(t IN LISTS GTS_KEYSIGHT)
  file(RELATIVE_PATH test_path ${P4C_SOURCE_DIR} ${t})
  p4c_add_test_label("tofino" "GTS_WEEKLY" ${test_path})
endforeach()

set (GTS_OTHER
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/certusnet/COMPILER-888/comp_888.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/cisco/COMPILER-1140/case8399.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/cisco/COMPILER-1140/comp_1140.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/cisco/COMPILER-1143/case8542.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/cisco/COMPILER-1146/case8575.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/cisco/COMPILER-1147/comp_1147.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/cisco/COMPILER-393/case2277.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/embedway/COMPILER-603/loop.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/embedway/COMPILER-604/new_parser.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/embedway/COMPILER-765/parser_tcp_ip_option_mul.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/embedway/COMPILER-765/parser_tcp_option_mul.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/embedway/COMPILER-921/comp_921.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/fox/COMPILER-939/case5942.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/fox/COMPILER-956/case6123_3.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/fox/COMPILER-957/case6123.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/fujitsu/COMPILER-1141/static_acl_tun_tel.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/harveymudd/COMPILER-900/case4813.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/huawei/COMPILER-1090/case7787.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/ixia/COMPILER-522/case2774.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/ixia/COMPILER-523/vag2774.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/ixia/COMPILER-529/dnets_bng_case1.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/ixia/COMPILER-529/dnets_bng_case2.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/ixia/COMPILER-549/case2898.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/ixia/COMPILER-550/vag2899.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/ixia/COMPILER-590/case3179.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/ixia/COMPILER-591/case3176.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/jdcloud/COMPILER-917/comp_917.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/kaust/COMPILER-1077/countmin.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/kaust/COMPILER-1155/test_config_425_salu_ops.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/kaust/COMPILER-800/vag4730.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/kpn/COMPILER-896/case5546.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/medialinks/COMPILER-1000/clone_field_list_bug.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/medialinks/COMPILER-682/case3764.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/microsoft/CASE-6342/case6342.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/microsoft/COMPILER-606/case3259.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/microsoft/COMPILER-623/case3375.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/microsoft/COMPILER-713/case3975.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/microsoft/COMPILER-982/case6409.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/microsoft/COMPILER-983/case6463.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/microsoft/COMPILER-991/vag6589.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/mimetrix/COMPILER-1058/comp_1058.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/mimetrix/COMPILER-1062/case7485.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/mimetrix/COMPILER-1063/case7501.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/netscout/P4C-1605/filter_bf_p414.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/nus/COMPILER-858/comp_858.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/princeton/COMPILER-1005/vag6748.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/princeton/COMPILER-1012/case6782.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/princeton/COMPILER-1025/case6934.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/princeton/COMPILER-1038/case7096_fit.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/princeton/COMPILER-1038/case7096.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/princeton/COMPILER-676/case3736.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/rohde/COMPILER-1164/test_config_427_sel_scramble.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/stordis/COMPILER-1095/case7871.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/surfnet/COMPILER-817/case4947.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/tudarmstadt/COMPILER-1128/case8348.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/tudarmstadt/COMPILER-616/case3331.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/tudarmstadt/COMPILER-743/case4181_fix.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/tudarmstadt/COMPILER-743/case4181.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/tudarmstadt/COMPILER-779/case4343.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/tudarmstadt/COMPILER-805/case4825.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/ucloud/COMPILER-1042/uxr.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/ucloud/COMPILER-1045/case6975.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/ucloud/COMPILER-951/comp_951.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/ucsd/COMPILER-1022/comp_1022.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/usi/COMPILER-669/comp_669.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/usi/COMPILER-875/vag5471.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/yale/COMPILER-988/case6394.p4
  ${CMAKE_CURRENT_SOURCE_DIR}/glass/zte/COMPILER-594/comp594.p4
)

p4c_add_bf_backend_tests("tofino" "tofino" "${TOFINO_P414_TEST_ARCH}" "base" "${GTS_OTHER}")

foreach(t IN LISTS GTS_OTHER)
  file(RELATIVE_PATH test_path ${P4C_SOURCE_DIR} ${t})
  p4c_add_test_label("tofino" "GTS_WEEKLY" ${test_path})
  p4c_add_test_label("tofino" "GTS_OTHER" ${test_path})
endforeach()

# tests which aren't supported by bf-p4c
# =======================================

# P4C-1390 - sample_e2e is not supported by the TNA
p4c_add_xfail_reason("tofino"
  "error: (Primitive sample[34] is not supported by the backend)|(sample_e2e primitive is not currently supported by the TNA architecture)"
  extensions/p4_tests/glass/parde/test_start_coalesced_state.p4
  extensions/p4_tests/glass/mau/test_config_183_sample_e2e.p4
  )

p4c_add_xfail_reason("tofino"
  "error: .*: unsupported 64-bit select"
  extensions/p4_tests/glass/parde/COMPILER-368/out.p4
)
