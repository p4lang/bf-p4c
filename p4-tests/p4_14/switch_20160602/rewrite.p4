/*
 * Packet rewrite processing
 */


/*****************************************************************************/
/* Packet rewrite lookup and actions                                         */
/*****************************************************************************/
action set_l2_rewrite_with_tunnel(tunnel_index, tunnel_type) {
    modify_field(egress_metadata.routed, FALSE);
    modify_field(egress_metadata.bd, ingress_metadata.bd);
    modify_field(egress_metadata.outer_bd, ingress_metadata.bd);
    modify_field(tunnel_metadata.tunnel_index, tunnel_index);
    modify_field(tunnel_metadata.egress_tunnel_type, tunnel_type);
}

action set_l2_rewrite() {
    modify_field(egress_metadata.routed, FALSE);
    modify_field(egress_metadata.bd, ingress_metadata.bd);
    modify_field(egress_metadata.outer_bd, ingress_metadata.bd);
}

action set_l3_rewrite_with_tunnel(bd, dmac, tunnel_index, tunnel_type) {
    modify_field(egress_metadata.routed, TRUE);
    modify_field(egress_metadata.mac_da, dmac);
    modify_field(egress_metadata.bd, bd);
    modify_field(egress_metadata.outer_bd, bd);
    modify_field(tunnel_metadata.tunnel_index, tunnel_index);
    modify_field(tunnel_metadata.egress_tunnel_type, tunnel_type);
}

action set_l3_rewrite(bd, mtu_index, dmac) {
    modify_field(egress_metadata.routed, TRUE);
    modify_field(egress_metadata.mac_da, dmac);
    modify_field(egress_metadata.bd, bd);
    modify_field(egress_metadata.outer_bd, bd);
    modify_field(l3_metadata.mtu_index, mtu_index);
}

#ifndef MPLS_DISABLE
action set_mpls_swap_push_rewrite_l2(label, tunnel_index, header_count) {
    modify_field(egress_metadata.routed, l3_metadata.routed);
    modify_field(egress_metadata.bd, ingress_metadata.bd);
    modify_field(mpls[0].label, label);
    modify_field(tunnel_metadata.tunnel_index, tunnel_index);
    modify_field(tunnel_metadata.egress_header_count, header_count);
    modify_field(tunnel_metadata.egress_tunnel_type,
                 EGRESS_TUNNEL_TYPE_MPLS_L2VPN);
}

action set_mpls_push_rewrite_l2(tunnel_index, header_count) {
    modify_field(egress_metadata.routed, l3_metadata.routed);
    modify_field(egress_metadata.bd, ingress_metadata.bd);
    modify_field(tunnel_metadata.tunnel_index, tunnel_index);
    modify_field(tunnel_metadata.egress_header_count, header_count);
    modify_field(tunnel_metadata.egress_tunnel_type,
                 EGRESS_TUNNEL_TYPE_MPLS_L2VPN);
}

action set_mpls_swap_push_rewrite_l3(bd, dmac,
                                     label, tunnel_index, header_count) {
    modify_field(egress_metadata.routed, l3_metadata.routed);
    modify_field(egress_metadata.bd, bd);
    modify_field(mpls[0].label, label);
    modify_field(egress_metadata.mac_da, dmac);
    modify_field(tunnel_metadata.tunnel_index, tunnel_index);
    modify_field(tunnel_metadata.egress_header_count, header_count);
    modify_field(tunnel_metadata.egress_tunnel_type,
                 EGRESS_TUNNEL_TYPE_MPLS_L3VPN);
}

action set_mpls_push_rewrite_l3(bd, dmac,
                                tunnel_index, header_count) {
    modify_field(egress_metadata.routed, l3_metadata.routed);
    modify_field(egress_metadata.bd, bd);
    modify_field(egress_metadata.mac_da, dmac);
    modify_field(tunnel_metadata.tunnel_index, tunnel_index);
    modify_field(tunnel_metadata.egress_header_count, header_count);
    modify_field(tunnel_metadata.egress_tunnel_type,
                 EGRESS_TUNNEL_TYPE_MPLS_L3VPN);
}
#endif /* MPLS_DISABLE */

#ifdef L3_IPV4_FULL_PROFILE
@pragma ternary 1
#endif /* L3_IPV4_FULL_PROFILE */
table rewrite {
    reads {
        l3_metadata.nexthop_index : exact;
    }
    actions {
        nop;
        set_l2_rewrite;
#ifndef TUNNEL_DISABLE
        set_l2_rewrite_with_tunnel;
#endif /* TUNNEL_DISABLE */
#ifndef L3_DISABLE
        set_l3_rewrite;
#ifndef TUNNEL_DISABLE
        set_l3_rewrite_with_tunnel;
#endif /* TUNNEL_DISABLE */
#endif /* L3_DISABLE */
#ifndef MPLS_DISABLE
        set_mpls_swap_push_rewrite_l2;
        set_mpls_push_rewrite_l2;
        set_mpls_swap_push_rewrite_l3;
        set_mpls_push_rewrite_l3;
#endif /* MPLS_DISABLE */
    }
    size : NEXTHOP_TABLE_SIZE;
}

action rewrite_ipv4_multicast() {
    modify_field(ethernet.dstAddr, ipv4.dstAddr, 0x007FFFFF);
}

action rewrite_ipv6_multicast() {
}

table rewrite_multicast {
    reads {
        ipv4 : valid;
        ipv6 : valid;
        ipv4.dstAddr mask 0xF0000000 : ternary;
#ifndef IPV6_DISABLE
        ipv6.dstAddr mask 0xFF000000000000000000000000000000 : ternary;
#endif /* IPV6_DISABLE */
    }
    actions {
        nop;
        rewrite_ipv4_multicast;
#ifndef IPV6_DISABLE
        rewrite_ipv6_multicast;
#endif /* IPV6_DISABLE */
    }
}

control process_rewrite {
    if ((egress_metadata.routed == FALSE) or
        (l3_metadata.nexthop_index != 0)) {
        apply(rewrite);
    } else {
#ifndef MULTICAST_DISABLE
        apply(rewrite_multicast);
#endif /* MULTICAST_DISABLE */
    }
}
