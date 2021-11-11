# run-it will execute this script if it exists, prior to kicking off a regression.

rm -f *.py* # remove all existing/stale links

# Basic MAU Tests
# ---------------

# basic functionality
cp ../../basic/mau/test_mau_1hop_s__.py                                   ../../../../../../tests/test_mau_1hop_s__.py
cp ../../basic/mau/test_mau_1hop_s___nshtype1.py                          ../../../../../../tests/test_mau_1hop_s___nshtype1.py
cp ../../basic/mau/test_mau_1hop__m_.py                                   ../../../../../../tests/test_mau_1hop__m_.py
cp ../../basic/mau/test_mau_1hop__m__nsh_xlate.py                         ../../../../../../tests/test_mau_1hop__m__nsh_xlate.py
cp ../../basic/mau/test_mau_1hop___e.py                                   ../../../../../../tests/test_mau_1hop___e.py
cp ../../basic/mau/test_mau_1hop___e_nshtype1.py                          ../../../../../../tests/test_mau_1hop___e_nshtype1.py
cp ../../basic/mau/test_mau_1hop_s_e.py                                   ../../../../../../tests/test_mau_1hop_s_e.py
cp ../../basic/mau/test_mau_1hop_s_e_sf0_l2_acl_sf2_l2_acl.py             ../../../../../../tests/test_mau_1hop_s_e_sf0_l2_acl_sf2_l2_acl.py
cp ../../basic/mau/test_mau_2hop_s_e.py                                   ../../../../../../tests/test_mau_2hop_s_e.py
cp ../../basic/mau/test_mau_2hop_s_e_recirc.py                            ../../../../../../tests/test_mau_2hop_s_e_recirc.py
cp ../../basic/mau/test_mau_3hop_sme.py                                   ../../../../../../tests/test_mau_3hop_sme.py
cp ../../basic/mau/test_mau_3hop_sme_recirc.py                            ../../../../../../tests/test_mau_3hop_sme_recirc.py
cp ../../basic/mau/test_mau_3hop_sme_serpentine_without_chains.py         ../../../../../../tests/test_mau_3hop_sme_serpentine_without_chains.py
cp ../../basic/mau/test_mau_3hop_sme_serpentine_with_chains.py            ../../../../../../tests/test_mau_3hop_sme_serpentine_with_chains.py

#cp ../../basic/mau/test_mau_1hop_s___dedup.py                             ../../../../../../tests/test_mau_1hop_s___dedup.py

# 1 hop, bridging
cp ../../basic/mau/test_mau_1hop_____bridge.py                            ../../../../../../tests/test_mau_1hop_____bridge.py
cp ../../basic/mau/test_mau_1hop_____bridge_cpu.py                        ../../../../../../tests/test_mau_1hop_____bridge_cpu.py
cp ../../basic/mau/test_mau_1hop_____bridge_cpu_lacp.py                   ../../../../../../tests/test_mau_1hop_____bridge_cpu_lacp.py
#cp ../../basic/mau/test_mau_1hop_____bridge_add_vlan.py                   ../../../../../../tests/test_mau_1hop_____bridge_add_vlan.py # fails, see explanation in test

# 1 hop, sfc
cp ../../basic/mau/test_mau_1hop_s___sfc_transport.py                     ../../../../../../tests/test_mau_1hop_s___sfc_transport.py
cp ../../basic/mau/test_mau_1hop_s___sfc_transport_mpls.py                ../../../../../../tests/test_mau_1hop_s___sfc_transport_mpls.py
cp ../../basic/mau/test_mau_1hop_s___sfc_transport_mirror.py              ../../../../../../tests/test_mau_1hop_s___sfc_transport_mirror.py
cp ../../basic/mau/test_mau_1hop_s_e_sfc_transport_reencap_v4.py          ../../../../../../tests/test_mau_1hop_s_e_sfc_transport_reencap_v4.py
#cp ../../basic/mau/test_mau_1hop_s_e_sfc_transport_reencap_v6.py          ../../../../../../tests/test_mau_1hop_s_e_sfc_transport_reencap_v6.py
#cp ../../basic/mau/test_mau_1hop_s___sfc_outer_decap.py                   ../../../../../../tests/test_mau_1hop_s___sfc_outer_decap.py
#cp ../../basic/mau/test_mau_1hop_s___sfc_outer_decap_inner_decap.py       ../../../../../../tests/test_mau_1hop_s___sfc_outer_decap_inner_decap.py
#cp ../../basic/mau/test_mau_1hop_s___sfc_outer_decap_inner_scope.py       ../../../../../../tests/test_mau_1hop_s___sfc_outer_decap_inner_scope.py
#cp ../../basic/mau/test_mau_1hop_s___sfc_outer_scope.py                   ../../../../../../tests/test_mau_1hop_s___sfc_outer_scope.py
#cp ../../basic/mau/test_mau_1hop_s___sfc_outer_scope_inner_decap.py       ../../../../../../tests/test_mau_1hop_s___sfc_outer_scope_inner_decap.py
#cp ../../basic/mau/test_mau_1hop_s___sfc_outer_scope_sf0_acl_l2_decap.py  ../../../../../../tests/test_mau_1hop_s___sfc_outer_scope_sf0_acl_l2_decap.py
#cp ../../basic/mau/test_mau_1hop_s___sfc_outer_scope_sf2_acl_l2_decap.py  ../../../../../../tests/test_mau_1hop_s___sfc_outer_scope_sf2_acl_l2_decap.py
cp ../../basic/mau/test_mau_1hop_s___sfc_inner_decap.py                   ../../../../../../tests/test_mau_1hop_s___sfc_inner_decap.py
cp ../../basic/mau/test_mau_1hop_s___sfc_inner_scope.py                   ../../../../../../tests/test_mau_1hop_s___sfc_inner_scope.py
cp ../../basic/mau/test_mau_1hop_s___sfc_inner_scope_sf0_acl_l2_decap.py  ../../../../../../tests/test_mau_1hop_s___sfc_inner_scope_sf0_acl_l2_decap.py
cp ../../basic/mau/test_mau_1hop_s___sfc_inner_scope_sf2_acl_l2_decap.py  ../../../../../../tests/test_mau_1hop_s___sfc_inner_scope_sf2_acl_l2_decap.py
cp ../../basic/mau/test_mau_1hop_s_e_sf0_acl_l2_decap_reencap_v4.py       ../../../../../../tests/test_mau_1hop_s_e_sf0_acl_l2_decap_reencap_v4.py
cp ../../basic/mau/test_mau_1hop_s_e_sf2_acl_l2_decap_reencap_v4.py       ../../../../../../tests/test_mau_1hop_s_e_sf2_acl_l2_decap_reencap_v4.py
cp ../../basic/mau/test_mau_1hop_s_e_sf0_acl_l2_scope_sf2_acl_l2_decap_reencap_v4.py ../../../../../../tests/test_mau_1hop_s_e_sf0_acl_l2_scope_sf2_acl_l2_decap_reencap_v4.py

# 1 hop, sf 0 acl
cp ../../basic/mau/test_mau_1hop_s___sf0_acl_l2_decap.py                  ../../../../../../tests/test_mau_1hop_s___sf0_acl_l2_decap.py
cp ../../basic/mau/test_mau_1hop_s___sf0_acl_l2_drop.py                   ../../../../../../tests/test_mau_1hop_s___sf0_acl_l2_drop.py
cp ../../basic/mau/test_mau_1hop_s___sf0_acl_l2_redirect.py               ../../../../../../tests/test_mau_1hop_s___sf0_acl_l2_redirect.py
#cp ../../basic/mau/test_mau_1hop_s___sf0_acl_l2_redirect_selector.py      ../../../../../../tests/test_mau_1hop_s___sf0_acl_l2_redirect_selector.py
cp ../../basic/mau/test_mau_1hop_s___sf0_acl_l2_scope.py                  ../../../../../../tests/test_mau_1hop_s___sf0_acl_l2_scope.py
cp ../../basic/mau/test_mau_1hop_s___sf0_acl_l2_truncate.py               ../../../../../../tests/test_mau_1hop_s___sf0_acl_l2_truncate.py
cp ../../basic/mau/test_mau_1hop_s___sf0_acl_l34_v4_decap.py              ../../../../../../tests/test_mau_1hop_s___sf0_acl_l34_v4_decap.py
cp ../../basic/mau/test_mau_1hop_s___sf0_acl_l34_v4_drop.py               ../../../../../../tests/test_mau_1hop_s___sf0_acl_l34_v4_drop.py
cp ../../basic/mau/test_mau_1hop_s___sf0_acl_l34_v4_drop_range.py         ../../../../../../tests/test_mau_1hop_s___sf0_acl_l34_v4_drop_range.py
cp ../../basic/mau/test_mau_1hop_s___sf0_acl_l34_v4_drop_port_range.py    ../../../../../../tests/test_mau_1hop_s___sf0_acl_l34_v4_drop_port_range.py
cp ../../basic/mau/test_mau_1hop_s___sf0_acl_l34_v4_redirect.py           ../../../../../../tests/test_mau_1hop_s___sf0_acl_l34_v4_redirect.py
cp ../../basic/mau/test_mau_1hop_s___sf0_acl_l34_v4_scope.py              ../../../../../../tests/test_mau_1hop_s___sf0_acl_l34_v4_scope.py
cp ../../basic/mau/test_mau_1hop_s___sf0_acl_l34_v4_truncate.py           ../../../../../../tests/test_mau_1hop_s___sf0_acl_l34_v4_truncate.py
cp ../../basic/mau/test_mau_1hop_s___sf0_acl_l34_v6_decap.py              ../../../../../../tests/test_mau_1hop_s___sf0_acl_l34_v6_decap.py
cp ../../basic/mau/test_mau_1hop_s___sf0_acl_l34_v6_drop.py               ../../../../../../tests/test_mau_1hop_s___sf0_acl_l34_v6_drop.py
cp ../../basic/mau/test_mau_1hop_s___sf0_acl_l34_v6_drop_range.py         ../../../../../../tests/test_mau_1hop_s___sf0_acl_l34_v6_drop_range.py
cp ../../basic/mau/test_mau_1hop_s___sf0_acl_l34_v6_drop_port_range.py    ../../../../../../tests/test_mau_1hop_s___sf0_acl_l34_v6_drop_port_range.py
cp ../../basic/mau/test_mau_1hop_s___sf0_acl_l34_v6_redirect.py           ../../../../../../tests/test_mau_1hop_s___sf0_acl_l34_v6_redirect.py
cp ../../basic/mau/test_mau_1hop_s___sf0_acl_l34_v6_scope.py              ../../../../../../tests/test_mau_1hop_s___sf0_acl_l34_v6_scope.py
#cp ../../basic/mau/test_mau_1hop_s___sf0_acl_l7_decap.py                  ../../../../../../tests/test_mau_1hop_s___sf0_acl_l7_decap.py
#cp ../../basic/mau/test_mau_1hop_s___sf0_acl_l7_drop.py                   ../../../../../../tests/test_mau_1hop_s___sf0_acl_l7_drop.py
#cp ../../basic/mau/test_mau_1hop_s___sf0_acl_l7_redirect.py               ../../../../../../tests/test_mau_1hop_s___sf0_acl_l7_redirect.py
#cp ../../basic/mau/test_mau_1hop_s___sf0_acl_l7_scope.py                  ../../../../../../tests/test_mau_1hop_s___sf0_acl_l7_scope.py
cp ../../basic/mau/test_mau_1hop_s_e_sf0_acl_l2_truncate.py               ../../../../../../tests/test_mau_1hop_s_e_sf0_acl_l2_truncate.py
#cp ../../basic/mau/test_mau_1hop_s___sf0_acl_l2_copy_to_cpu.py            ../../../../../../tests/test_mau_1hop_s___sf0_acl_l2_copy_to_cpu.py
#cp ../../basic/mau/test_mau_1hop_s___sf0_acl_l2_redirect_to_cpu.py        ../../../../../../tests/test_mau_1hop_s___sf0_acl_l2_redirect_to_cpu.py
cp ../../basic/mau/test_mau_1hop_s___sf0_acl_l2_mirror_cpu.py             ../../../../../../tests/test_mau_1hop_s___sf0_acl_l2_mirror_cpu.py

# 1 hop, sf 1 multicast
cp ../../basic/mau/test_mau_1hop_s___sf1_pre_identical.py                 ../../../../../../tests/test_mau_1hop_s___sf1_pre_identical.py
cp ../../basic/mau/test_mau_1hop_s___sf1_pre_unique.py                    ../../../../../../tests/test_mau_1hop_s___sf1_pre_unique.py

# 1 hop, sf 2 acl
cp ../../basic/mau/test_mau_1hop_s___sf2_acl_l2_decap.py                  ../../../../../../tests/test_mau_1hop_s___sf2_acl_l2_decap.py
cp ../../basic/mau/test_mau_1hop_s___sf2_acl_l2_drop.py                   ../../../../../../tests/test_mau_1hop_s___sf2_acl_l2_drop.py
cp ../../basic/mau/test_mau_1hop_s___sf2_acl_l2_strip_e.py                ../../../../../../tests/test_mau_1hop_s___sf2_acl_l2_strip_e.py
cp ../../basic/mau/test_mau_1hop_s___sf2_acl_l2_strip_vlan.py             ../../../../../../tests/test_mau_1hop_s___sf2_acl_l2_strip_vlan.py
cp ../../basic/mau/test_mau_1hop_s___sf2_acl_l2_strip_vn.py               ../../../../../../tests/test_mau_1hop_s___sf2_acl_l2_strip_vn.py
cp ../../basic/mau/test_mau_1hop_s___sf2_acl_l2_add_vlan.py               ../../../../../../tests/test_mau_1hop_s___sf2_acl_l2_add_vlan.py
cp ../../basic/mau/test_mau_1hop_s___sf2_acl_l2_truncate.py               ../../../../../../tests/test_mau_1hop_s___sf2_acl_l2_truncate.py
cp ../../basic/mau/test_mau_1hop_s___sf2_acl_l34_v4_decap.py              ../../../../../../tests/test_mau_1hop_s___sf2_acl_l34_v4_decap.py
cp ../../basic/mau/test_mau_1hop_s___sf2_acl_l34_v4_drop.py               ../../../../../../tests/test_mau_1hop_s___sf2_acl_l34_v4_drop.py
cp ../../basic/mau/test_mau_1hop_s___sf2_acl_l34_v4_drop_range.py         ../../../../../../tests/test_mau_1hop_s___sf2_acl_l34_v4_drop_range.py
cp ../../basic/mau/test_mau_1hop_s___sf2_acl_l34_v4_drop_port_range.py    ../../../../../../tests/test_mau_1hop_s___sf2_acl_l34_v4_drop_port_range.py
cp ../../basic/mau/test_mau_1hop_s___sf2_acl_l34_v4_truncate.py           ../../../../../../tests/test_mau_1hop_s___sf2_acl_l34_v4_truncate.py
cp ../../basic/mau/test_mau_1hop_s___sf2_acl_l34_v6_decap.py              ../../../../../../tests/test_mau_1hop_s___sf2_acl_l34_v6_decap.py
cp ../../basic/mau/test_mau_1hop_s___sf2_acl_l34_v6_drop.py               ../../../../../../tests/test_mau_1hop_s___sf2_acl_l34_v6_drop.py
cp ../../basic/mau/test_mau_1hop_s___sf2_acl_l34_v6_drop_range.py         ../../../../../../tests/test_mau_1hop_s___sf2_acl_l34_v6_drop_range.py
cp ../../basic/mau/test_mau_1hop_s___sf2_acl_l34_v6_drop_port_range.py    ../../../../../../tests/test_mau_1hop_s___sf2_acl_l34_v6_drop_port_range.py
cp ../../basic/mau/test_mau_1hop_s_e_sf2_acl_l2_truncate.py               ../../../../../../tests/test_mau_1hop_s_e_sf2_acl_l2_truncate.py
#cp ../../basic/mau/test_mau_1hop_s___sf2_acl_l2_copy_to_cpu.py            ../../../../../../tests/test_mau_1hop_s___sf2_acl_l2_copy_to_cpu.py
#cp ../../basic/mau/test_mau_1hop_s___sf2_acl_l2_redirect_to_cpu.py        ../../../../../../tests/test_mau_1hop_s___sf2_acl_l2_redirect_to_cpu.py
cp ../../basic/mau/test_mau_1hop_s___sf2_acl_l2_mirror_cpu.py             ../../../../../../tests/test_mau_1hop_s___sf2_acl_l2_mirror_cpu.py

# 1 hop, mirror / copy-to-cpu / redirect-to-cpu
cp ../../basic/mau/test_mau_1hop_s___ing_mirror.py                        ../../../../../../tests/test_mau_1hop_s___ing_mirror.py
cp ../../basic/mau/test_mau_1hop_s___egr_mirror.py                        ../../../../../../tests/test_mau_1hop_s___egr_mirror.py
cp ../../basic/mau/test_mau_1hop_s___ing_mirror_cpu.py                    ../../../../../../tests/test_mau_1hop_s___ing_mirror_cpu.py
cp ../../basic/mau/test_mau_1hop_s___egr_mirror_cpu.py                    ../../../../../../tests/test_mau_1hop_s___egr_mirror_cpu.py

# 2 hops
cp ../../basic/mau/test_mau_2hop_s_e_for_demo.py                          ../../../../../../tests/test_mau_2hop_s_e_for_demo.py
cp ../../basic/mau/test_mau_2hop_s_e_sfc_inner_scope_sf0_acl_l2_decap.py  ../../../../../../tests/test_mau_2hop_s_e_sfc_inner_scope_sf0_acl_l2_decap.py
#cp ../../basic/mau/test_mau_2hop_s_e_sfc_outer_scope_sf0_acl_l2_decap.py  ../../../../../../tests/test_mau_2hop_s_e_sfc_outer_scope_sf0_acl_l2_decap.py

# 3 hops

# misc
cp ../../basic/mau/test_mau_1hop_s___add_vlan.py                          ../../../../../../tests/test_mau_1hop_s___add_vlan.py
cp ../../basic/mau/test_mau_1hop_s___lag_selector.py                      ../../../../../../tests/test_mau_1hop_s___lag_selector.py
cp ../../basic/mau/test_mau_raw_packet.py                                 ../../../../../../tests/test_mau_raw_packet.py
cp ../../basic/mau/test_mau_raw_packet_case_00575704_sip_error.py         ../../../../../../tests/test_mau_raw_packet_case_00575704_sip_error.py
cp ../../basic/mau/test_mau_raw_packet_case_00622608_tm_underflow_error.py ../../../../../../tests/test_mau_raw_packet_case_00622608_tm_underflow_error.py
#cp ../../basic/mau/test_mau_1hop_s___sf0_acl_l2_copy_to_cpu_sf2_acl_add_vlan.py ../../../../../../tests/test_mau_1hop_s___sf0_acl_l2_copy_to_cpu_sf2_acl_add_vlan.py
#cp ../../basic/mau/test_mau_1hop_s___sf2_acl_l2_copy_to_cpu_sf2_acl_add_vlan.py ../../../../../../tests/test_mau_1hop_s___sf2_acl_l2_copy_to_cpu_sf2_acl_add_vlan.py
cp ../../basic/mau/test_mau_1hop_s___sf0_acl_l2_mirror_cpu_sf2_acl_add_vlan.py ../../../../../../tests/test_mau_1hop_s___sf0_acl_l2_mirror_cpu_sf2_acl_add_vlan.py
cp ../../basic/mau/test_mau_1hop_s___sf2_acl_l2_mirror_cpu_sf2_acl_add_vlan.py ../../../../../../tests/test_mau_1hop_s___sf2_acl_l2_mirror_cpu_sf2_acl_add_vlan.py

#cp ../../basic/mau/test_mau_1hop_s_e_sf0_acl_l2_trunc_sf2_acl_l2_trunc_encap.py ../../../../../../tests/test_mau_1hop_s_e_sf0_acl_l2_trunc_sf2_acl_l2_trunc_encap.py

# Advanced
cp ../../basic/mau/test_mau_adv_ks.py                                     ../../../../../../tests/test_mau_adv_ks.py
cp ../../basic/mau/test_mau_adv_negative.py                               ../../../../../../tests/test_mau_adv_negative.py
cp ../../basic/mau/test_mau_adv_sf0_overloading_case2.py                  ../../../../../../tests/test_mau_adv_sf0_overloading_case2.py
cp ../../basic/mau/test_mau_adv_sf0_overloading_case3.py                  ../../../../../../tests/test_mau_adv_sf0_overloading_case3.py
cp ../../basic/mau/test_mau_adv_sf0_overloading_case4.py                  ../../../../../../tests/test_mau_adv_sf0_overloading_case4.py
cp ../../basic/mau/test_mau_adv_sf0_overloading_case5.py                  ../../../../../../tests/test_mau_adv_sf0_overloading_case5.py
cp ../../basic/mau/test_mau_adv_sf0_overloading_case6.py                  ../../../../../../tests/test_mau_adv_sf0_overloading_case6.py
cp ../../basic/mau/test_mau_1hop_s___sf2_acl_all_pkttype_actions.py       ../../../../../../tests/test_mau_1hop_s___sf2_acl_all_pkttype_actions.py              
cp ../../basic/mau/test_mau_1hop_s___sf0_acl_l2_2000entries.py            ../../../../../../tests/test_mau_1hop_s___sf0_acl_l2_2000entries.py                         
cp ../../basic/mau/test_mau_1hop_s___multi_lag.py                         ../../../../../../tests/test_mau_1hop_s___multi_lag.py     
