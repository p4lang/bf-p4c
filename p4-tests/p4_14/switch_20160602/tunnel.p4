/*
 * Tunnel processing
 */

/*
 * Tunnel metadata
 */
header_type tunnel_metadata_t {
    fields {
        ingress_tunnel_type : 5;               /* tunnel type from parser */
        tunnel_vni : 24;                       /* tunnel id */
        mpls_enabled : 1;                      /* is mpls enabled on BD */
        mpls_label: 20;                        /* Mpls label */
        mpls_exp: 3;                           /* Mpls Traffic Class */
        mpls_ttl: 8;                           /* Mpls Ttl */
        egress_tunnel_type : 5;                /* type of tunnel */
#if defined(L3_IPV4_TUNNEL_PROFILE) || defined(L3_IPV6_TUNNEL_PROFILE)
        tunnel_index: 24;                      /* tunnel index */
        tunnel_dst_index : 24;                 /* index to tunnel dst ip */
#else
        tunnel_index: 14;                      /* tunnel index */
        tunnel_dst_index : 14;                 /* index to tunnel dst ip */
#endif
        tunnel_src_index : 9;                  /* index to tunnel src ip */
        tunnel_smac_index : 9;                 /* index to tunnel src mac */
        tunnel_dmac_index : 14;                /* index to tunnel dst mac */
        vnid : 24;                             /* tunnel vnid */
        tunnel_terminate : 1;                  /* is tunnel being terminated? */
        tunnel_if_check : 1;                   /* tun terminate xor originate */
        egress_header_count: 4;                /* number of mpls header stack */
        inner_ip_proto : 8;                    /* Inner IP protocol */
        skip_encap_inner : 1;                  /* skip encap_process_inner */
#ifdef INT_EP_ENABLE
        erspan_t3_ft_d_other: 16;
#endif
    }
}
metadata tunnel_metadata_t tunnel_metadata;

#ifndef TUNNEL_DISABLE
/*****************************************************************************/
/* Outer router mac lookup                                                   */
/*****************************************************************************/
action outer_rmac_hit() {
    modify_field(l3_metadata.rmac_hit, TRUE);
}

@pragma ternary 1
table outer_rmac {
    reads {
        l3_metadata.rmac_group : exact;
        ethernet.dstAddr : exact;
    }
    actions {
        on_miss;
        outer_rmac_hit;
    }
    size : OUTER_ROUTER_MAC_TABLE_SIZE;
}
#endif /* TUNNEL_DISABLE */

#ifndef TUNNEL_DISABLE
/*****************************************************************************/
/* IPv4 source and destination VTEP lookups                                  */
/*****************************************************************************/
action set_tunnel_termination_flag() {
    modify_field(tunnel_metadata.tunnel_terminate, TRUE);
}

action set_tunnel_vni_and_termination_flag(tunnel_vni) {
    modify_field(tunnel_metadata.tunnel_vni, tunnel_vni);
    modify_field(tunnel_metadata.tunnel_terminate, TRUE);
}
action src_vtep_hit(ifindex) {
    modify_field(ingress_metadata.ifindex, ifindex);
}

#ifndef IPV4_DISABLE
table ipv4_dest_vtep {
    reads {
        l3_metadata.vrf : exact;
        ipv4.dstAddr : exact;
        tunnel_metadata.ingress_tunnel_type : exact;
    }
    actions {
        nop;
        set_tunnel_termination_flag;
        set_tunnel_vni_and_termination_flag;
    }
    size : DEST_TUNNEL_TABLE_SIZE;
}

table ipv4_src_vtep {
    reads {
        l3_metadata.vrf : exact;
        ipv4.srcAddr : exact;
        tunnel_metadata.ingress_tunnel_type : exact;
    }
    actions {
        on_miss;
        src_vtep_hit;
    }
    size : IPV4_SRC_TUNNEL_TABLE_SIZE;
}
#endif /* IPV4_DISABLE */


#ifndef IPV6_DISABLE
/*****************************************************************************/
/* IPv6 source and destination VTEP lookups                                  */
/*****************************************************************************/
table ipv6_dest_vtep {
    reads {
        l3_metadata.vrf : exact;
        ipv6.dstAddr : exact;
        tunnel_metadata.ingress_tunnel_type : exact;
    }
    actions {
        nop;
        set_tunnel_termination_flag;
        set_tunnel_vni_and_termination_flag;
    }
    size : DEST_TUNNEL_TABLE_SIZE;
}

table ipv6_src_vtep {
    reads {
        l3_metadata.vrf : exact;
        ipv6.srcAddr : exact;
        tunnel_metadata.ingress_tunnel_type : exact;
    }
    actions {
        on_miss;
        src_vtep_hit;
    }
    size : IPV6_SRC_TUNNEL_TABLE_SIZE;
}
#endif /* IPV6_DISABLE */
#endif /* TUNNEL_DISABLE */

control process_ipv4_vtep {
#if !defined(TUNNEL_DISABLE) && !defined(IPV4_DISABLE)
    apply(ipv4_src_vtep) {
        src_vtep_hit {
            apply(ipv4_dest_vtep);
        }
    }
#endif /* TUNNEL_DISABLE && IPV4_DISABLE */
}

control process_ipv6_vtep {
#if !defined(TUNNEL_DISABLE) && !defined(IPV6_DISABLE)
    apply(ipv6_src_vtep) {
        src_vtep_hit {
            apply(ipv6_dest_vtep);
        }
    }
#endif /* TUNNEL_DISABLE && IPV6_DISABLE */
}


#ifndef TUNNEL_DISABLE
/*****************************************************************************/
/* Tunnel termination                                                        */
/*****************************************************************************/
action terminate_tunnel_inner_non_ip(bd, bd_label, stats_idx,
                                     exclusion_id, ingress_rid) {
    modify_field(tunnel_metadata.tunnel_terminate, TRUE);
    modify_field(ingress_metadata.bd, bd);
    modify_field(acl_metadata.bd_label, bd_label);
    modify_field(l2_metadata.bd_stats_idx, stats_idx);

    modify_field(l3_metadata.lkp_ip_type, IPTYPE_NONE);
    modify_field(l2_metadata.lkp_mac_type, inner_ethernet.etherType);

    modify_field(ig_intr_md_for_tm.level1_exclusion_id, exclusion_id);
    modify_field(ig_intr_md_for_tm.rid, ingress_rid);
}

#ifndef IPV4_DISABLE
action terminate_tunnel_inner_ethernet_ipv4(bd, vrf,
        rmac_group, bd_label,
        ipv4_unicast_enabled, ipv4_urpf_mode,
        igmp_snooping_enabled, stats_idx,
        ipv4_multicast_enabled, mrpf_group,
        exclusion_id, ingress_rid) {
    modify_field(tunnel_metadata.tunnel_terminate, TRUE);
    modify_field(ingress_metadata.bd, bd);
    modify_field(l3_metadata.vrf, vrf);
    modify_field(qos_metadata.outer_dscp, l3_metadata.lkp_ip_tc);
    modify_field(ipv4_metadata.ipv4_unicast_enabled, ipv4_unicast_enabled);
    modify_field(ipv4_metadata.ipv4_urpf_mode, ipv4_urpf_mode);
    modify_field(l3_metadata.rmac_group, rmac_group);
    modify_field(acl_metadata.bd_label, bd_label);
    modify_field(l2_metadata.bd_stats_idx, stats_idx);

    modify_field(l3_metadata.lkp_ip_type, IPTYPE_IPV4);
    modify_field(l2_metadata.lkp_mac_type, inner_ethernet.etherType);
    modify_field(l3_metadata.lkp_ip_version, inner_ipv4.version);
    modify_field(l3_metadata.lkp_ip_tc, inner_ipv4.diffserv);

    modify_field(multicast_metadata.igmp_snooping_enabled,
                 igmp_snooping_enabled);
    modify_field(multicast_metadata.ipv4_multicast_enabled,
                 ipv4_multicast_enabled);
    modify_field(multicast_metadata.bd_mrpf_group, mrpf_group);

    modify_field(ig_intr_md_for_tm.level1_exclusion_id, exclusion_id);
    modify_field(ig_intr_md_for_tm.rid, ingress_rid);
}

action terminate_tunnel_inner_ipv4(vrf, rmac_group,
        ipv4_urpf_mode, ipv4_unicast_enabled,
        ipv4_multicast_enabled, mrpf_group) {
    modify_field(tunnel_metadata.tunnel_terminate, TRUE);
    modify_field(l3_metadata.vrf, vrf);
    modify_field(qos_metadata.outer_dscp, l3_metadata.lkp_ip_tc);
    modify_field(ipv4_metadata.ipv4_unicast_enabled, ipv4_unicast_enabled);
    modify_field(ipv4_metadata.ipv4_urpf_mode, ipv4_urpf_mode);
    modify_field(l3_metadata.rmac_group, rmac_group);

    modify_field(l2_metadata.lkp_mac_sa, ethernet.srcAddr);
    modify_field(l2_metadata.lkp_mac_da, ethernet.dstAddr);
    modify_field(l3_metadata.lkp_ip_type, IPTYPE_IPV4);
    modify_field(l3_metadata.lkp_ip_version, inner_ipv4.version);
    modify_field(l3_metadata.lkp_ip_tc, inner_ipv4.diffserv);

    modify_field(multicast_metadata.bd_mrpf_group, mrpf_group);
    modify_field(multicast_metadata.ipv4_multicast_enabled,
                 ipv4_multicast_enabled);
}
#endif /* IPV4_DISABLE */

#ifndef IPV6_DISABLE
action terminate_tunnel_inner_ethernet_ipv6(bd, vrf,
        rmac_group, bd_label,
        ipv6_unicast_enabled, ipv6_urpf_mode,
        mld_snooping_enabled, stats_idx,
        ipv6_multicast_enabled, mrpf_group,
        exclusion_id, ingress_rid) {
    modify_field(tunnel_metadata.tunnel_terminate, TRUE);
    modify_field(ingress_metadata.bd, bd);
    modify_field(l3_metadata.vrf, vrf);
    modify_field(qos_metadata.outer_dscp, l3_metadata.lkp_ip_tc);
    modify_field(ipv6_metadata.ipv6_unicast_enabled, ipv6_unicast_enabled);
    modify_field(ipv6_metadata.ipv6_urpf_mode, ipv6_urpf_mode);
    modify_field(l3_metadata.rmac_group, rmac_group);
    modify_field(acl_metadata.bd_label, bd_label);
    modify_field(l2_metadata.bd_stats_idx, stats_idx);

    modify_field(l3_metadata.lkp_ip_type, IPTYPE_IPV6);
    modify_field(l2_metadata.lkp_mac_type, inner_ethernet.etherType);
    modify_field(l3_metadata.lkp_ip_version, inner_ipv6.version);
    modify_field(l3_metadata.lkp_ip_tc, inner_ipv6.trafficClass);

    modify_field(multicast_metadata.bd_mrpf_group, mrpf_group);
    modify_field(multicast_metadata.ipv6_multicast_enabled,
                 ipv6_multicast_enabled);
    modify_field(multicast_metadata.mld_snooping_enabled, mld_snooping_enabled);

    modify_field(ig_intr_md_for_tm.level1_exclusion_id, exclusion_id);
    modify_field(ig_intr_md_for_tm.rid, ingress_rid);
}

action terminate_tunnel_inner_ipv6(vrf, rmac_group,
        ipv6_unicast_enabled, ipv6_urpf_mode,
        ipv6_multicast_enabled, mrpf_group) {
    modify_field(tunnel_metadata.tunnel_terminate, TRUE);
    modify_field(l3_metadata.vrf, vrf);
    modify_field(qos_metadata.outer_dscp, l3_metadata.lkp_ip_tc);
    modify_field(ipv6_metadata.ipv6_unicast_enabled, ipv6_unicast_enabled);
    modify_field(ipv6_metadata.ipv6_urpf_mode, ipv6_urpf_mode);
    modify_field(l3_metadata.rmac_group, rmac_group);

    modify_field(l2_metadata.lkp_mac_sa, ethernet.srcAddr);
    modify_field(l2_metadata.lkp_mac_da, ethernet.dstAddr);
    modify_field(l3_metadata.lkp_ip_type, IPTYPE_IPV6);
    modify_field(l3_metadata.lkp_ip_version, inner_ipv6.version);
    modify_field(l3_metadata.lkp_ip_tc, inner_ipv6.trafficClass);

    modify_field(multicast_metadata.bd_mrpf_group, mrpf_group);
    modify_field(multicast_metadata.ipv6_multicast_enabled,
                 ipv6_multicast_enabled);
}
#endif /* IPV6_DISABLE */

action tunnel_lookup_miss() {
}

table tunnel {
    reads {
        tunnel_metadata.tunnel_vni : exact;
        tunnel_metadata.ingress_tunnel_type : exact;
        inner_ipv4 : valid;
        inner_ipv6 : valid;
    }
    actions {
        nop;
        tunnel_lookup_miss;
        terminate_tunnel_inner_non_ip;
#ifndef IPV4_DISABLE
        terminate_tunnel_inner_ethernet_ipv4;
        terminate_tunnel_inner_ipv4;
#endif /* IPV4_DISABLE */
#ifndef IPV6_DISABLE
        terminate_tunnel_inner_ethernet_ipv6;
        terminate_tunnel_inner_ipv6;
#endif /* IPV6_DISABLE */
    }
    size : VNID_MAPPING_TABLE_SIZE;
}
#endif /* TUNNEL_DISABLE */

action ipv4_lkp() {
    modify_field(l2_metadata.lkp_mac_sa, ethernet.srcAddr);
    modify_field(l2_metadata.lkp_mac_da, ethernet.dstAddr);
    modify_field(ipv4_metadata.lkp_ipv4_sa, ipv4.srcAddr);
    modify_field(ipv4_metadata.lkp_ipv4_da, ipv4.dstAddr);
    modify_field(l3_metadata.lkp_ip_proto, ipv4.protocol);
    modify_field(l3_metadata.lkp_ip_ttl, ipv4.ttl);
    modify_field(l3_metadata.lkp_l4_sport, l3_metadata.lkp_outer_l4_sport);
    modify_field(l3_metadata.lkp_l4_dport, l3_metadata.lkp_outer_l4_dport);

    modify_field(ig_intr_md_for_tm.mcast_grp_a, 0);
}

action ipv6_lkp() {
    modify_field(l2_metadata.lkp_mac_sa, ethernet.srcAddr);
    modify_field(l2_metadata.lkp_mac_da, ethernet.dstAddr);
    modify_field(ipv6_metadata.lkp_ipv6_sa, ipv6.srcAddr);
    modify_field(ipv6_metadata.lkp_ipv6_da, ipv6.dstAddr);
    modify_field(l3_metadata.lkp_ip_proto, ipv6.nextHdr);
    modify_field(l3_metadata.lkp_ip_ttl, ipv6.hopLimit);
    modify_field(l3_metadata.lkp_l4_sport, l3_metadata.lkp_outer_l4_sport);
    modify_field(l3_metadata.lkp_l4_dport, l3_metadata.lkp_outer_l4_dport);

    modify_field(ig_intr_md_for_tm.mcast_grp_a, 0);
}

action non_ip_lkp() {
    modify_field(l2_metadata.lkp_mac_sa, ethernet.srcAddr);
    modify_field(l2_metadata.lkp_mac_da, ethernet.dstAddr);

    modify_field(ig_intr_md_for_tm.mcast_grp_a, 0);
}

table adjust_lkp_fields {
    reads {
        ipv4 : valid;
        ipv6 : valid;
    }
    actions {
        non_ip_lkp;
        ipv4_lkp;
#ifndef IPV6_DISABLE
        ipv6_lkp;
#endif /* IPV6_DISABLE */
    }
}

table tunnel_lookup_miss {
    reads {
        ipv4 : valid;
        ipv6 : valid;
    }
    actions {
        non_ip_lkp;
        ipv4_lkp;
#ifndef IPV6_DISABLE
        ipv6_lkp;
#endif /* IPV6_DISABLE */
    }
}

/*****************************************************************************/
/* Ingress tunnel processing                                                 */
/*****************************************************************************/
control process_tunnel {

    /* ingress fabric processing */
    process_ingress_fabric();

#ifndef TUNNEL_DISABLE
    if (tunnel_metadata.ingress_tunnel_type != INGRESS_TUNNEL_TYPE_NONE) {

        /* outer RMAC lookup for tunnel termination */
        apply(outer_rmac) {
            on_miss {
                process_outer_multicast();
            }
            default {
                if (valid(ipv4)) {
                    process_ipv4_vtep();
                } else {
                    if (valid(ipv6)) {
                        process_ipv6_vtep();
                    } else {
                        /* check for mpls tunnel termination */
#ifndef MPLS_DISABLE
                        if (valid(mpls[0])) {
                            process_mpls();
                        }
#endif
                    }
                }
            }
        }
    }

    /* perform tunnel termination */
    if ((tunnel_metadata.tunnel_terminate == TRUE) or
        ((multicast_metadata.outer_mcast_route_hit == TRUE) and
         (((multicast_metadata.outer_mcast_mode == MCAST_MODE_SM) and
           (multicast_metadata.mcast_rpf_group == 0)) or
          ((multicast_metadata.outer_mcast_mode == MCAST_MODE_BIDIR) and
           (multicast_metadata.mcast_rpf_group != 0))))) {
        apply(tunnel) {
            tunnel_lookup_miss {
                apply(tunnel_lookup_miss);
            }
        }
    } else {
        apply(adjust_lkp_fields);
    }
#endif /* TUNNEL_DISABLE */
}

#if !defined(TUNNEL_DISABLE) && !defined(MPLS_DISABLE)
/*****************************************************************************/
/* Validate MPLS header                                                      */
/*****************************************************************************/
action set_valid_mpls_label1() {
    modify_field(tunnel_metadata.mpls_label, mpls[0].label);
    modify_field(tunnel_metadata.mpls_exp, mpls[0].exp);
}

action set_valid_mpls_label2() {
    modify_field(tunnel_metadata.mpls_label, mpls[1].label);
    modify_field(tunnel_metadata.mpls_exp, mpls[1].exp);
}

action set_valid_mpls_label3() {
    modify_field(tunnel_metadata.mpls_label, mpls[2].label);
    modify_field(tunnel_metadata.mpls_exp, mpls[2].exp);
}

table validate_mpls_packet {
    reads {
        mpls[0].label : ternary;
        mpls[0].bos : ternary;
        mpls[0] : valid;
        mpls[1].label : ternary;
        mpls[1].bos : ternary;
        mpls[1] : valid;
        mpls[2].label : ternary;
        mpls[2].bos : ternary;
        mpls[2] : valid;
    }
    actions {
        set_valid_mpls_label1;
        set_valid_mpls_label2;
        set_valid_mpls_label3;
        //TODO: Redirect to cpu if more than 5 labels
    }
    size : VALIDATE_MPLS_TABLE_SIZE;
}
#endif /* TUNNEL_DISABLE && MPLS_DISABLE */

control validate_mpls_header {
#if !defined(TUNNEL_DISABLE) && !defined(MPLS_DISABLE)
    apply(validate_mpls_packet);
#endif /* TUNNEL_DISABLE && MPLS_DISABLE */
}

#if !defined(TUNNEL_DISABLE) && !defined(MPLS_DISABLE)
/*****************************************************************************/
/* MPLS lookup/forwarding                                                    */
/*****************************************************************************/
action terminate_eompls(bd, tunnel_type) {
    modify_field(tunnel_metadata.tunnel_terminate, TRUE);
    modify_field(tunnel_metadata.ingress_tunnel_type, tunnel_type);
    modify_field(ingress_metadata.bd, bd);

    modify_field(l2_metadata.lkp_mac_type, inner_ethernet.etherType);
}

action terminate_vpls(bd, tunnel_type) {
    modify_field(tunnel_metadata.tunnel_terminate, TRUE);
    modify_field(tunnel_metadata.ingress_tunnel_type, tunnel_type);
    modify_field(ingress_metadata.bd, bd);

    modify_field(l2_metadata.lkp_mac_type, inner_ethernet.etherType);
}

#ifndef IPV4_DISABLE
action terminate_ipv4_over_mpls(vrf, tunnel_type) {
    modify_field(tunnel_metadata.tunnel_terminate, TRUE);
    modify_field(tunnel_metadata.ingress_tunnel_type, tunnel_type);
    modify_field(l3_metadata.vrf, vrf);

    modify_field(l2_metadata.lkp_mac_sa, ethernet.srcAddr);
    modify_field(l2_metadata.lkp_mac_da, ethernet.dstAddr);
    modify_field(l3_metadata.lkp_ip_type, IPTYPE_IPV4);
    modify_field(l2_metadata.lkp_mac_type, inner_ethernet.etherType);
    modify_field(l3_metadata.lkp_ip_version, inner_ipv4.version);
    modify_field(l3_metadata.lkp_ip_tc, inner_ipv4.diffserv);
}
#endif /* IPV4_DISABLE */

#ifndef IPV6_DISABLE
action terminate_ipv6_over_mpls(vrf, tunnel_type) {
    modify_field(tunnel_metadata.tunnel_terminate, TRUE);
    modify_field(tunnel_metadata.ingress_tunnel_type, tunnel_type);
    modify_field(l3_metadata.vrf, vrf);

    modify_field(l2_metadata.lkp_mac_sa, ethernet.srcAddr);
    modify_field(l2_metadata.lkp_mac_da, ethernet.dstAddr);
    modify_field(l3_metadata.lkp_ip_type, IPTYPE_IPV6);
    modify_field(l2_metadata.lkp_mac_type, inner_ethernet.etherType);
    modify_field(l3_metadata.lkp_ip_version, inner_ipv6.version);
    modify_field(l3_metadata.lkp_ip_tc, inner_ipv6.trafficClass);
}
#endif /* IPV6_DISABLE */

action terminate_pw(ifindex) {
    modify_field(ingress_metadata.egress_ifindex, ifindex);

    modify_field(l2_metadata.lkp_mac_sa, ethernet.srcAddr);
    modify_field(l2_metadata.lkp_mac_da, ethernet.dstAddr);
}

action forward_mpls(nexthop_index) {
    modify_field(l3_metadata.fib_nexthop, nexthop_index);
    modify_field(l3_metadata.fib_nexthop_type, NEXTHOP_TYPE_SIMPLE);
    modify_field(l3_metadata.fib_hit, TRUE);

    modify_field(l2_metadata.lkp_mac_sa, ethernet.srcAddr);
    modify_field(l2_metadata.lkp_mac_da, ethernet.dstAddr);
}

@pragma ternary 1
table mpls {
    reads {
        tunnel_metadata.mpls_label: exact;
        inner_ipv4: valid;
        inner_ipv6: valid;
    }
    actions {
        terminate_eompls;
        terminate_vpls;
#ifndef IPV4_DISABLE
        terminate_ipv4_over_mpls;
#endif /* IPV4_DISABLE */
#ifndef IPV6_DISABLE
        terminate_ipv6_over_mpls;
#endif /* IPV6_DISABLE */
        terminate_pw;
        forward_mpls;
    }
    size : MPLS_TABLE_SIZE;
}
#endif /* TUNNEL_DISABLE && MPLS_DISABLE */

control process_mpls {
#if !defined(TUNNEL_DISABLE) && !defined(MPLS_DISABLE)
    apply(mpls);
#endif /* TUNNEL_DISABLE && MPLS_DISABLE */
}


#ifndef TUNNEL_DISABLE
/*****************************************************************************/
/* Tunnel decap (strip tunnel header)                                        */
/*****************************************************************************/
action decap_vxlan_inner_ipv4() {
    copy_header(ethernet, inner_ethernet);
    copy_header(ipv4, inner_ipv4);
    remove_header(vxlan);
    remove_header(ipv6);
    remove_header(inner_ethernet);
    remove_header(inner_ipv4);
}

action decap_vxlan_inner_ipv6() {
    copy_header(ethernet, inner_ethernet);
    copy_header(ipv6, inner_ipv6);
    remove_header(vxlan);
    remove_header(ipv4);
    remove_header(inner_ethernet);
    remove_header(inner_ipv6);
}

action decap_vxlan_inner_non_ip() {
    copy_header(ethernet, inner_ethernet);
    remove_header(vxlan);
    remove_header(ipv4);
    remove_header(ipv6);
}

action decap_genv_inner_ipv4() {
    copy_header(ethernet, inner_ethernet);
    copy_header(ipv4, inner_ipv4);
    remove_header(genv);
    remove_header(ipv6);
    remove_header(inner_ethernet);
    remove_header(inner_ipv4);
}

action decap_genv_inner_ipv6() {
    copy_header(ethernet, inner_ethernet);
    copy_header(ipv6, inner_ipv6);
    remove_header(genv);
    remove_header(ipv4);
    remove_header(inner_ethernet);
    remove_header(inner_ipv6);
}

action decap_genv_inner_non_ip() {
    copy_header(ethernet, inner_ethernet);
    remove_header(genv);
    remove_header(ipv4);
    remove_header(ipv6);
}

#ifndef NVGRE_DISABLE
action decap_nvgre_inner_ipv4() {
    copy_header(ethernet, inner_ethernet);
    copy_header(ipv4, inner_ipv4);
    remove_header(nvgre);
    remove_header(gre);
    remove_header(ipv6);
    remove_header(inner_ethernet);
    remove_header(inner_ipv4);
}

action decap_nvgre_inner_ipv6() {
    copy_header(ethernet, inner_ethernet);
    copy_header(ipv6, inner_ipv6);
    remove_header(nvgre);
    remove_header(gre);
    remove_header(ipv4);
    remove_header(inner_ethernet);
    remove_header(inner_ipv6);
}

action decap_nvgre_inner_non_ip() {
    copy_header(ethernet, inner_ethernet);
    remove_header(nvgre);
    remove_header(gre);
    remove_header(ipv4);
    remove_header(ipv6);
}
#endif

action decap_gre_inner_ipv4() {
    copy_header(ipv4, inner_ipv4);
    remove_header(gre);
    remove_header(ipv6);
    remove_header(inner_ipv4);
    modify_field(ethernet.etherType, ETHERTYPE_IPV4);
}

action decap_gre_inner_ipv6() {
    copy_header(ipv6, inner_ipv6);
    remove_header(gre);
    remove_header(ipv4);
    remove_header(inner_ipv6);
    modify_field(ethernet.etherType, ETHERTYPE_IPV6);
}

action decap_gre_inner_non_ip() {
    modify_field(ethernet.etherType, gre.proto);
    remove_header(gre);
    remove_header(ipv4);
    remove_header(inner_ipv6);
}

action decap_ip_inner_ipv4() {
    copy_header(ipv4, inner_ipv4);
    remove_header(ipv6);
    remove_header(inner_ipv4);
    modify_field(ethernet.etherType, ETHERTYPE_IPV4);
}

action decap_ip_inner_ipv6() {
    copy_header(ipv6, inner_ipv6);
    remove_header(ipv4);
    remove_header(inner_ipv6);
    modify_field(ethernet.etherType, ETHERTYPE_IPV6);
}

#ifndef MPLS_DISABLE
action decap_mpls_inner_ipv4_pop1() {
    remove_header(mpls[0]);
    copy_header(ipv4, inner_ipv4);
    remove_header(inner_ipv4);
    modify_field(ethernet.etherType, ETHERTYPE_IPV4);
}

action decap_mpls_inner_ipv6_pop1() {
    remove_header(mpls[0]);
    copy_header(ipv6, inner_ipv6);
    remove_header(inner_ipv6);
    modify_field(ethernet.etherType, ETHERTYPE_IPV6);
}

action decap_mpls_inner_ethernet_ipv4_pop1() {
    remove_header(mpls[0]);
    copy_header(ethernet, inner_ethernet);
    copy_header(ipv4, inner_ipv4);
    remove_header(inner_ethernet);
    remove_header(inner_ipv4);
}

action decap_mpls_inner_ethernet_ipv6_pop1() {
    remove_header(mpls[0]);
    copy_header(ethernet, inner_ethernet);
    copy_header(ipv6, inner_ipv6);
    remove_header(inner_ethernet);
    remove_header(inner_ipv6);
}

action decap_mpls_inner_ethernet_non_ip_pop1() {
    remove_header(mpls[0]);
    copy_header(ethernet, inner_ethernet);
    remove_header(inner_ethernet);
}

action decap_mpls_inner_ipv4_pop2() {
    remove_header(mpls[0]);
    remove_header(mpls[1]);
    copy_header(ipv4, inner_ipv4);
    remove_header(inner_ipv4);
    modify_field(ethernet.etherType, ETHERTYPE_IPV4);
}

action decap_mpls_inner_ipv6_pop2() {
    remove_header(mpls[0]);
    remove_header(mpls[1]);
    copy_header(ipv6, inner_ipv6);
    remove_header(inner_ipv6);
    modify_field(ethernet.etherType, ETHERTYPE_IPV6);
}

action decap_mpls_inner_ethernet_ipv4_pop2() {
    remove_header(mpls[0]);
    remove_header(mpls[1]);
    copy_header(ethernet, inner_ethernet);
    copy_header(ipv4, inner_ipv4);
    remove_header(inner_ethernet);
    remove_header(inner_ipv4);
}

action decap_mpls_inner_ethernet_ipv6_pop2() {
    remove_header(mpls[0]);
    remove_header(mpls[1]);
    copy_header(ethernet, inner_ethernet);
    copy_header(ipv6, inner_ipv6);
    remove_header(inner_ethernet);
    remove_header(inner_ipv6);
}

action decap_mpls_inner_ethernet_non_ip_pop2() {
    remove_header(mpls[0]);
    remove_header(mpls[1]);
    copy_header(ethernet, inner_ethernet);
    remove_header(inner_ethernet);
}

action decap_mpls_inner_ipv4_pop3() {
    remove_header(mpls[0]);
    remove_header(mpls[1]);
    remove_header(mpls[2]);
    copy_header(ipv4, inner_ipv4);
    remove_header(inner_ipv4);
    modify_field(ethernet.etherType, ETHERTYPE_IPV4);
}

action decap_mpls_inner_ipv6_pop3() {
    remove_header(mpls[0]);
    remove_header(mpls[1]);
    remove_header(mpls[2]);
    copy_header(ipv6, inner_ipv6);
    remove_header(inner_ipv6);
    modify_field(ethernet.etherType, ETHERTYPE_IPV6);
}

action decap_mpls_inner_ethernet_ipv4_pop3() {
    remove_header(mpls[0]);
    remove_header(mpls[1]);
    remove_header(mpls[2]);
    copy_header(ethernet, inner_ethernet);
    copy_header(ipv4, inner_ipv4);
    remove_header(inner_ethernet);
    remove_header(inner_ipv4);
}

action decap_mpls_inner_ethernet_ipv6_pop3() {
    remove_header(mpls[0]);
    remove_header(mpls[1]);
    remove_header(mpls[2]);
    copy_header(ethernet, inner_ethernet);
    copy_header(ipv6, inner_ipv6);
    remove_header(inner_ethernet);
    remove_header(inner_ipv6);
}

action decap_mpls_inner_ethernet_non_ip_pop3() {
    remove_header(mpls[0]);
    remove_header(mpls[1]);
    remove_header(mpls[2]);
    copy_header(ethernet, inner_ethernet);
    remove_header(inner_ethernet);
}
#endif /* MPLS_DISABLE */

table tunnel_decap_process_outer {
    reads {
        tunnel_metadata.ingress_tunnel_type : exact;
        inner_ipv4 : valid;
        inner_ipv6 : valid;
    }
    actions {
        decap_vxlan_inner_ipv4;
        decap_vxlan_inner_ipv6;
        decap_vxlan_inner_non_ip;
        decap_genv_inner_ipv4;
        decap_genv_inner_ipv6;
        decap_genv_inner_non_ip;
#ifndef NVGRE_DISABLE
        decap_nvgre_inner_ipv4;
        decap_nvgre_inner_ipv6;
        decap_nvgre_inner_non_ip;
#endif
        decap_gre_inner_ipv4;
        decap_gre_inner_ipv6;
        decap_gre_inner_non_ip;
        decap_ip_inner_ipv4;
        decap_ip_inner_ipv6;
#ifndef MPLS_DISABLE
        decap_mpls_inner_ipv4_pop1;
        decap_mpls_inner_ipv6_pop1;
        decap_mpls_inner_ethernet_ipv4_pop1;
        decap_mpls_inner_ethernet_ipv6_pop1;
        decap_mpls_inner_ethernet_non_ip_pop1;
        decap_mpls_inner_ipv4_pop2;
        decap_mpls_inner_ipv6_pop2;
        decap_mpls_inner_ethernet_ipv4_pop2;
        decap_mpls_inner_ethernet_ipv6_pop2;
        decap_mpls_inner_ethernet_non_ip_pop2;
        decap_mpls_inner_ipv4_pop3;
        decap_mpls_inner_ipv6_pop3;
        decap_mpls_inner_ethernet_ipv4_pop3;
        decap_mpls_inner_ethernet_ipv6_pop3;
        decap_mpls_inner_ethernet_non_ip_pop3;
#endif /* MPLS_DISABLE */
    }
    size : TUNNEL_DECAP_TABLE_SIZE;
}

/*****************************************************************************/
/* Tunnel decap (move inner header to outer)                                 */
/*****************************************************************************/
action decap_inner_udp() {
    copy_header(udp, inner_udp);
    remove_header(inner_udp);
}

action decap_inner_tcp() {
    copy_tcp_header(tcp, inner_tcp);
    remove_header(inner_tcp);
    remove_header(udp);
}

action decap_inner_icmp() {
    copy_header(icmp, inner_icmp);
    remove_header(inner_icmp);
    remove_header(udp);
}

action decap_inner_unknown() {
    remove_header(udp);
}

table tunnel_decap_process_inner {
    reads {
        inner_tcp : valid;
        inner_udp : valid;
        inner_icmp : valid;
    }
    actions {
        decap_inner_udp;
        decap_inner_tcp;
        decap_inner_icmp;
        decap_inner_unknown;
    }
    size : TUNNEL_DECAP_TABLE_SIZE;
}
#endif /* TUNNEL_DISABLE */


/*****************************************************************************/
/* Tunnel decap processing                                                   */
/*****************************************************************************/
control process_tunnel_decap {
#ifndef TUNNEL_DISABLE
    if (tunnel_metadata.tunnel_terminate == TRUE) {
        if ((multicast_metadata.inner_replica == TRUE) or
            (multicast_metadata.replica == FALSE)) {
            apply(tunnel_decap_process_outer);
            apply(tunnel_decap_process_inner);
        }
    }
#endif /* TUNNEL_DISABLE */
}


#ifndef TUNNEL_DISABLE
/*****************************************************************************/
/* Egress tunnel VNI lookup                                                  */
/*****************************************************************************/
action set_egress_tunnel_vni(vnid) {
    modify_field(tunnel_metadata.vnid, vnid);
}

table egress_vni {
    reads {
        egress_metadata.bd : exact;
        tunnel_metadata.egress_tunnel_type: exact;
    }
    actions {
        nop;
        set_egress_tunnel_vni;
    }
    size: EGRESS_VNID_MAPPING_TABLE_SIZE;
}


/*****************************************************************************/
/* Tunnel encap (inner header rewrite)                                       */
/*****************************************************************************/
action inner_ipv4_udp_rewrite() {
    copy_header(inner_ipv4, ipv4);
    copy_header(inner_udp, udp);
    modify_field(egress_metadata.payload_length, ipv4.totalLen);
    remove_header(udp);
    remove_header(ipv4);
    modify_field(tunnel_metadata.inner_ip_proto, IP_PROTOCOLS_IPV4);
}

action inner_ipv4_tcp_rewrite() {
    copy_header(inner_ipv4, ipv4);
    copy_tcp_header(inner_tcp, tcp);
    modify_field(egress_metadata.payload_length, ipv4.totalLen);
    remove_header(tcp);
    remove_header(ipv4);
    modify_field(tunnel_metadata.inner_ip_proto, IP_PROTOCOLS_IPV4);
}

action inner_ipv4_icmp_rewrite() {
    copy_header(inner_ipv4, ipv4);
    copy_header(inner_icmp, icmp);
    modify_field(egress_metadata.payload_length, ipv4.totalLen);
    remove_header(icmp);
    remove_header(ipv4);
    modify_field(tunnel_metadata.inner_ip_proto, IP_PROTOCOLS_IPV4);
}

action inner_ipv4_unknown_rewrite() {
    copy_header(inner_ipv4, ipv4);
    modify_field(egress_metadata.payload_length, ipv4.totalLen);
    remove_header(ipv4);
    modify_field(tunnel_metadata.inner_ip_proto, IP_PROTOCOLS_IPV4);
}

action inner_ipv6_udp_rewrite() {
    copy_header(inner_ipv6, ipv6);
    copy_header(inner_udp, udp);
    add(egress_metadata.payload_length, ipv6.payloadLen, 40);
    remove_header(ipv6);
    modify_field(tunnel_metadata.inner_ip_proto, IP_PROTOCOLS_IPV6);
}

action inner_ipv6_tcp_rewrite() {
    copy_header(inner_ipv6, ipv6);
    copy_tcp_header(inner_tcp, tcp);
    add(egress_metadata.payload_length, ipv6.payloadLen, 40);
    remove_header(tcp);
    remove_header(ipv6);
    modify_field(tunnel_metadata.inner_ip_proto, IP_PROTOCOLS_IPV6);
}

action inner_ipv6_icmp_rewrite() {
    copy_header(inner_ipv6, ipv6);
    copy_header(inner_icmp, icmp);
    add(egress_metadata.payload_length, ipv6.payloadLen, 40);
    remove_header(icmp);
    remove_header(ipv6);
    modify_field(tunnel_metadata.inner_ip_proto, IP_PROTOCOLS_IPV6);
}

action inner_ipv6_unknown_rewrite() {
    copy_header(inner_ipv6, ipv6);
    add(egress_metadata.payload_length, ipv6.payloadLen, 40);
    remove_header(ipv6);
    modify_field(tunnel_metadata.inner_ip_proto, IP_PROTOCOLS_IPV6);
}

action inner_non_ip_rewrite() {
#ifndef HARLYN
    add(egress_metadata.payload_length, standard_metadata.packet_length, -14);
#endif
}

table tunnel_encap_process_inner {
    reads {
        ipv4 : valid;
        ipv6 : valid;
        tcp : valid;
        udp : valid;
        icmp : valid;
    }
    actions {
        inner_ipv4_udp_rewrite;
        inner_ipv4_tcp_rewrite;
        inner_ipv4_icmp_rewrite;
        inner_ipv4_unknown_rewrite;
        inner_ipv6_udp_rewrite;
        inner_ipv6_tcp_rewrite;
        inner_ipv6_icmp_rewrite;
        inner_ipv6_unknown_rewrite;
        inner_non_ip_rewrite;
    }
    size : TUNNEL_HEADER_TABLE_SIZE;
}


/*****************************************************************************/
/* Tunnel encap (insert tunnel header)                                       */
/*****************************************************************************/
action f_insert_vxlan_header() {
    copy_header(inner_ethernet, ethernet);
    add_header(udp);
    add_header(vxlan);

    modify_field(udp.srcPort, hash_metadata.entropy_hash);
    modify_field(udp.dstPort, UDP_PORT_VXLAN);
    modify_field(udp.checksum, 0);
    add(udp.length_, egress_metadata.payload_length, 30);

    modify_field(vxlan.flags, 0x8);
    modify_field(vxlan.reserved, 0);
    modify_field(vxlan.vni, tunnel_metadata.vnid);
    modify_field(vxlan.reserved2, 0);
}

action f_insert_ipv4_header(proto) {
    add_header(ipv4);
    modify_field(ipv4.protocol, proto);
    modify_field(ipv4.ttl, 64);
    modify_field(ipv4.version, 0x4);
    modify_field(ipv4.ihl, 0x5);
    modify_field(ipv4.identification, 0);
}

action f_insert_ipv6_header(proto) {
    add_header(ipv6);
    modify_field(ipv6.version, 0x6);
    modify_field(ipv6.nextHdr, proto);
    modify_field(ipv6.hopLimit, 64);
    modify_field(ipv6.trafficClass, 0);
    modify_field(ipv6.flowLabel, 0);
}

action ipv4_vxlan_rewrite() {
    f_insert_vxlan_header();
    f_insert_ipv4_header(IP_PROTOCOLS_UDP);
    add(ipv4.totalLen, egress_metadata.payload_length, 50);
    modify_field(ethernet.etherType, ETHERTYPE_IPV4);
}

action ipv6_vxlan_rewrite() {
    f_insert_vxlan_header();
    f_insert_ipv6_header(IP_PROTOCOLS_UDP);
    add(ipv6.payloadLen, egress_metadata.payload_length, 30);
    modify_field(ethernet.etherType, ETHERTYPE_IPV6);
}

action f_insert_genv_header() {
    copy_header(inner_ethernet, ethernet);
    add_header(udp);
    add_header(genv);

    modify_field(udp.srcPort, hash_metadata.entropy_hash);
    modify_field(udp.dstPort, UDP_PORT_GENV);
    modify_field(udp.checksum, 0);
    add(udp.length_, egress_metadata.payload_length, 30);

    modify_field(genv.ver, 0);
    modify_field(genv.oam, 0);
    modify_field(genv.critical, 0);
    modify_field(genv.optLen, 0);
    modify_field(genv.protoType, ETHERTYPE_ETHERNET);
    modify_field(genv.vni, tunnel_metadata.vnid);
    modify_field(genv.reserved, 0);
    modify_field(genv.reserved2, 0);
}

action ipv4_genv_rewrite() {
    f_insert_genv_header();
    f_insert_ipv4_header(IP_PROTOCOLS_UDP);
    add(ipv4.totalLen, egress_metadata.payload_length, 50);
    modify_field(ethernet.etherType, ETHERTYPE_IPV4);
}

action ipv6_genv_rewrite() {
    f_insert_genv_header();
    f_insert_ipv6_header(IP_PROTOCOLS_UDP);
    add(ipv6.payloadLen, egress_metadata.payload_length, 30);
    modify_field(ethernet.etherType, ETHERTYPE_IPV6);
}

#ifndef NVGRE_DISABLE
action f_insert_nvgre_header() {
    copy_header(inner_ethernet, ethernet);
    add_header(gre);
    add_header(nvgre);
    modify_field(gre.proto, ETHERTYPE_ETHERNET);
    modify_field(gre.recurse, 0);
    modify_field(gre.flags, 0);
    modify_field(gre.ver, 0);
    modify_field(gre.R, 0);
    modify_field(gre.K, 1);
    modify_field(gre.C, 0);
    modify_field(gre.S, 0);
    modify_field(gre.s, 0);
    modify_field(nvgre.tni, tunnel_metadata.vnid);
    modify_field(nvgre.flow_id, hash_metadata.entropy_hash, 0xFF);
}

action ipv4_nvgre_rewrite() {
    f_insert_nvgre_header();
    f_insert_ipv4_header(IP_PROTOCOLS_GRE);
    add(ipv4.totalLen, egress_metadata.payload_length, 42);
    modify_field(ethernet.etherType, ETHERTYPE_IPV4);
}

action ipv6_nvgre_rewrite() {
    f_insert_nvgre_header();
    f_insert_ipv6_header(IP_PROTOCOLS_GRE);
    add(ipv6.payloadLen, egress_metadata.payload_length, 22);
    modify_field(ethernet.etherType, ETHERTYPE_IPV6);
}
#endif

action f_insert_gre_header() {
    add_header(gre);
}

action ipv4_gre_rewrite() {
    f_insert_gre_header();
    modify_field(gre.proto, ethernet.etherType);
    f_insert_ipv4_header(IP_PROTOCOLS_GRE);
    add(ipv4.totalLen, egress_metadata.payload_length, 24);
    modify_field(ethernet.etherType, ETHERTYPE_IPV4);
}

action ipv6_gre_rewrite() {
    f_insert_gre_header();
    modify_field(gre.proto, ethernet.etherType);
    f_insert_ipv6_header(IP_PROTOCOLS_GRE);
    add(ipv6.payloadLen, egress_metadata.payload_length, 4);
    modify_field(ethernet.etherType, ETHERTYPE_IPV6);
}

action ipv4_ip_rewrite() {
    f_insert_ipv4_header(tunnel_metadata.inner_ip_proto);
    add(ipv4.totalLen, egress_metadata.payload_length, 20);
    modify_field(ethernet.etherType, ETHERTYPE_IPV4);
}

action ipv6_ip_rewrite() {
    f_insert_ipv6_header(tunnel_metadata.inner_ip_proto);
    modify_field(ipv6.payloadLen, egress_metadata.payload_length);
    modify_field(ethernet.etherType, ETHERTYPE_IPV6);
}

action f_insert_erspan_t3_header() {
    copy_header(inner_ethernet, ethernet);
    add_header(gre);
    add_header(erspan_t3_header);
    modify_field(gre.C, 0);
    modify_field(gre.R, 0);
    modify_field(gre.K, 0);
    modify_field(gre.S, 0);
    modify_field(gre.s, 0);
    modify_field(gre.recurse, 0);
    modify_field(gre.flags, 0);
    modify_field(gre.ver, 0);
    modify_field(gre.proto, GRE_PROTOCOLS_ERSPAN_T3);
    modify_field(erspan_t3_header.timestamp, i2e_metadata.ingress_tstamp);
    modify_field(erspan_t3_header.span_id, i2e_metadata.mirror_session_id);
    modify_field(erspan_t3_header.version, 2);
    modify_field(erspan_t3_header.sgt, 0);

#ifdef INT_EP_ENABLE
    // Take field values from mirror metadata for INT report
    // frame type: ether (0b00000), ip (0b00010), int (0b10000)
    // direction: ingress(0), egress(1)
    modify_field(erspan_t3_header.ft_d_other, tunnel_metadata.erspan_t3_ft_d_other);
#else
    modify_field(erspan_t3_header.pdu_frame, 0);
    modify_field(erspan_t3_header.frame_type, 0);
    modify_field(erspan_t3_header.hw_id, 0);
    modify_field(erspan_t3_header.direction, 0);
    modify_field(erspan_t3_header.granularity, 0);
    modify_field(erspan_t3_header.optional_sub_hdr, 0);
#endif
}

action ipv4_erspan_t3_rewrite() {
    f_insert_erspan_t3_header();
    f_insert_ipv4_header(IP_PROTOCOLS_GRE);
    add(ipv4.totalLen, egress_metadata.payload_length, 50);
}

action ipv6_erspan_t3_rewrite() {
    f_insert_erspan_t3_header();
    f_insert_ipv6_header(IP_PROTOCOLS_GRE);
    add(ipv6.payloadLen, egress_metadata.payload_length, 26);
}

#ifndef MPLS_DISABLE
action mpls_ethernet_push1_rewrite() {
    copy_header(inner_ethernet, ethernet);
    push(mpls, 1);
    modify_field(ethernet.etherType, ETHERTYPE_MPLS);
}

action mpls_ip_push1_rewrite() {
    push(mpls, 1);
    modify_field(ethernet.etherType, ETHERTYPE_MPLS);
}

action mpls_ethernet_push2_rewrite() {
    copy_header(inner_ethernet, ethernet);
    push(mpls, 2);
    modify_field(ethernet.etherType, ETHERTYPE_MPLS);
}

action mpls_ip_push2_rewrite() {
    push(mpls, 2);
    modify_field(ethernet.etherType, ETHERTYPE_MPLS);
}

action mpls_ethernet_push3_rewrite() {
    copy_header(inner_ethernet, ethernet);
    push(mpls, 3);
    modify_field(ethernet.etherType, ETHERTYPE_MPLS);
}

action mpls_ip_push3_rewrite() {
    push(mpls, 3);
    modify_field(ethernet.etherType, ETHERTYPE_MPLS);
}
#endif /* MPLS_DISABLE */
#endif /* TUNNEL_DISABLE */

table tunnel_encap_process_outer {
    reads {
        tunnel_metadata.egress_tunnel_type : exact;
        tunnel_metadata.egress_header_count : exact;
        multicast_metadata.replica : exact;
    }
    actions {
        nop;
        fabric_rewrite;
#ifndef TUNNEL_DISABLE
        ipv4_vxlan_rewrite;
        ipv4_genv_rewrite;
#ifndef NVGRE_DISABLE
        ipv4_nvgre_rewrite;
#endif /* NVGRE_DISABLE */
        ipv4_gre_rewrite;
        ipv4_ip_rewrite;
#ifndef MIRROR_DISABLE
        ipv4_erspan_t3_rewrite;
#endif /* MIRROR_DISABLE */
#ifndef TUNNEL_OVER_IPV6_DISABLE
        ipv6_gre_rewrite;
        ipv6_ip_rewrite;
#ifndef NVGRE_DISABLE
        ipv6_nvgre_rewrite;
#endif /* NVGRE_DISABLE */
        ipv6_vxlan_rewrite;
        ipv6_genv_rewrite;
#ifndef MIRROR_DISABLE
        ipv6_erspan_t3_rewrite;
#endif /* MIRROR_DISABLE */
#endif /* TUNNEL_OVER_IPV6_DISABLE */
#ifndef MPLS_DISABLE
        mpls_ethernet_push1_rewrite;
        mpls_ip_push1_rewrite;
        mpls_ethernet_push2_rewrite;
        mpls_ip_push2_rewrite;
        mpls_ethernet_push3_rewrite;
        mpls_ip_push3_rewrite;
#endif /* MPLS_DISABLE */
#endif /* TUNNEL_DISABLE */
    }
    size : TUNNEL_HEADER_TABLE_SIZE;
}


/*****************************************************************************/
/* Tunnel rewrite                                                            */
/*****************************************************************************/
action set_tunnel_rewrite_details(outer_bd, smac_idx, dmac_idx,
                                  sip_index, dip_index) {
    modify_field(egress_metadata.outer_bd, outer_bd);
    modify_field(tunnel_metadata.tunnel_smac_index, smac_idx);
    modify_field(tunnel_metadata.tunnel_dmac_index, dmac_idx);
    modify_field(tunnel_metadata.tunnel_src_index, sip_index);
    modify_field(tunnel_metadata.tunnel_dst_index, dip_index);
}

#ifndef MPLS_DISABLE
action set_mpls_rewrite_push1(label1, exp1, ttl1, smac_idx, dmac_idx) {
    modify_field(mpls[0].label, label1);
    modify_field(mpls[0].exp, exp1);
    modify_field(mpls[0].bos, 0x1);
    modify_field(mpls[0].ttl, ttl1);
    modify_field(tunnel_metadata.tunnel_smac_index, smac_idx);
    modify_field(tunnel_metadata.tunnel_dmac_index, dmac_idx);
}

action set_mpls_rewrite_push2(label1, exp1, ttl1, label2, exp2, ttl2,
                              smac_idx, dmac_idx) {
    modify_field(mpls[0].label, label1);
    modify_field(mpls[0].exp, exp1);
    modify_field(mpls[0].ttl, ttl1);
    modify_field(mpls[0].bos, 0x0);
    modify_field(mpls[1].label, label2);
    modify_field(mpls[1].exp, exp2);
    modify_field(mpls[1].ttl, ttl2);
    modify_field(mpls[1].bos, 0x1);
    modify_field(tunnel_metadata.tunnel_smac_index, smac_idx);
    modify_field(tunnel_metadata.tunnel_dmac_index, dmac_idx);
}

action set_mpls_rewrite_push3(label1, exp1, ttl1, label2, exp2, ttl2,
                              label3, exp3, ttl3, smac_idx, dmac_idx) {
    modify_field(mpls[0].label, label1);
    modify_field(mpls[0].exp, exp1);
    modify_field(mpls[0].ttl, ttl1);
    modify_field(mpls[0].bos, 0x0);
    modify_field(mpls[1].label, label2);
    modify_field(mpls[1].exp, exp2);
    modify_field(mpls[1].ttl, ttl2);
    modify_field(mpls[1].bos, 0x0);
    modify_field(mpls[2].label, label3);
    modify_field(mpls[2].exp, exp3);
    modify_field(mpls[2].ttl, ttl3);
    modify_field(mpls[2].bos, 0x1);
    modify_field(tunnel_metadata.tunnel_smac_index, smac_idx);
    modify_field(tunnel_metadata.tunnel_dmac_index, dmac_idx);
}
#endif /* MPLS_DISABLE */

#ifdef L3_IPV4_FULL_PROFILE
@pragma ternary 1
#endif
table tunnel_rewrite {
    reads {
        tunnel_metadata.tunnel_index : exact;
    }
    actions {
        nop;
        cpu_rx_rewrite;
#ifndef TUNNEL_DISABLE
        set_tunnel_rewrite_details;
#endif /* TUNNEL_DISABLE */
#ifndef MPLS_DISABLE
        set_mpls_rewrite_push1;
        set_mpls_rewrite_push2;
        set_mpls_rewrite_push3;
#endif /* MPLS_DISABLE */
#ifdef FABRIC_ENABLE
        fabric_unicast_rewrite;
#ifndef MULTICAST_DISABLE
        fabric_multicast_rewrite;
#endif /* MULTICAST_DISABLE */
#endif /* FABRIC_ENABLE */
    }
    size : TUNNEL_REWRITE_TABLE_SIZE;
}


#ifndef TUNNEL_DISABLE
/*****************************************************************************/
/* Tunnel MTU check                                                          */
/*****************************************************************************/
action tunnel_mtu_check(l3_mtu) {
    subtract(l3_metadata.l3_mtu_check, l3_mtu, egress_metadata.payload_length);
}

action tunnel_mtu_miss() {
    modify_field(l3_metadata.l3_mtu_check, 0xFFFF);
}

table tunnel_mtu {
    reads {
        tunnel_metadata.tunnel_index : exact;
    }
    actions {
        tunnel_mtu_check;
        tunnel_mtu_miss;
    }
    size : TUNNEL_REWRITE_TABLE_SIZE;
}


/*****************************************************************************/
/* Tunnel source IP rewrite                                                  */
/*****************************************************************************/
action rewrite_tunnel_ipv4_src(ip) {
    modify_field(ipv4.srcAddr, ip);
}

#ifndef IPV6_DISABLE
action rewrite_tunnel_ipv6_src(ip) {
    modify_field(ipv6.srcAddr, ip);
}
#endif /* IPV6_DISABLE */

table tunnel_src_rewrite {
    reads {
        tunnel_metadata.tunnel_src_index : exact;
    }
    actions {
        nop;
        rewrite_tunnel_ipv4_src;
#ifndef IPV6_DISABLE
        rewrite_tunnel_ipv6_src;
#endif /* IPV6_DISABLE */
    }
    size : TUNNEL_SRC_REWRITE_TABLE_SIZE;
}


/*****************************************************************************/
/* Tunnel destination IP rewrite                                             */
/*****************************************************************************/
action rewrite_tunnel_ipv4_dst(ip) {
    modify_field(ipv4.dstAddr, ip);
}

#ifndef IPV6_DISABLE
action rewrite_tunnel_ipv6_dst(ip) {
    modify_field(ipv6.dstAddr, ip);
}
#endif /* IPV6_DISABLE */

table tunnel_dst_rewrite {
    reads {
        tunnel_metadata.tunnel_dst_index : exact;
    }
    actions {
        nop;
        rewrite_tunnel_ipv4_dst;
#ifndef IPV6_DISABLE
        rewrite_tunnel_ipv6_dst;
#endif /* IPV6_DISABLE */
    }
    size : TUNNEL_DST_REWRITE_TABLE_SIZE;
}

action rewrite_tunnel_smac(smac) {
    modify_field(ethernet.srcAddr, smac);
}


/*****************************************************************************/
/* Tunnel source MAC rewrite                                                 */
/*****************************************************************************/
table tunnel_smac_rewrite {
    reads {
        tunnel_metadata.tunnel_smac_index : exact;
    }
    actions {
        nop;
        rewrite_tunnel_smac;
    }
    size : TUNNEL_SMAC_REWRITE_TABLE_SIZE;
}


/*****************************************************************************/
/* Tunnel destination MAC rewrite                                            */
/*****************************************************************************/
action rewrite_tunnel_dmac(dmac) {
    modify_field(ethernet.dstAddr, dmac);
}

table tunnel_dmac_rewrite {
    reads {
        tunnel_metadata.tunnel_dmac_index : exact;
    }
    actions {
        nop;
        rewrite_tunnel_dmac;
    }
    size : TUNNEL_DMAC_REWRITE_TABLE_SIZE;
}
#endif /* TUNNEL_DISABLE */


/*****************************************************************************/
/* Tunnel encap processing                                                   */
/*****************************************************************************/
control process_tunnel_encap {
    if ((fabric_metadata.fabric_header_present == FALSE) and
        (tunnel_metadata.egress_tunnel_type != EGRESS_TUNNEL_TYPE_NONE)) {

#ifndef TUNNEL_DISABLE
        /* derive egress vni from egress bd */
        apply(egress_vni);

        /* tunnel rewrites */
        if ((tunnel_metadata.egress_tunnel_type != EGRESS_TUNNEL_TYPE_FABRIC) and
            (tunnel_metadata.egress_tunnel_type != EGRESS_TUNNEL_TYPE_CPU) and
            (tunnel_metadata.skip_encap_inner == 0)) {
                apply(tunnel_encap_process_inner);
        }
#endif /* TUNNEL_DISABLE */

        apply(tunnel_encap_process_outer);
        apply(tunnel_rewrite);

#ifndef TUNNEL_DISABLE
        apply(tunnel_mtu);

        /* rewrite tunnel src and dst ip */
        apply(tunnel_src_rewrite);
        apply(tunnel_dst_rewrite);

        /* rewrite tunnel src and dst ip */
        apply(tunnel_smac_rewrite);
        apply(tunnel_dmac_rewrite);
#endif /* TUNNEL_DISABLE */
    }
}
