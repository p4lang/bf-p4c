/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2015-2019 Barefoot Networks, Inc.

 * All Rights Reserved.
 *
 * NOTICE: All information contained herein is, and remains the property of
 * Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
 * technical concepts contained herein are proprietary to Barefoot Networks,
 * Inc.
 * and its suppliers and may be covered by U.S. and Foreign Patents, patents in
 * process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material is
 * strictly forbidden unless prior written permission is obtained from
 * Barefoot Networks, Inc.
 *
 * No warranty, explicit or implicit is provided, unless granted under a
 * written agreement with Barefoot Networks, Inc.
 *
 ******************************************************************************/

#ifndef _SCOPER_
#define _SCOPER_

// ============================================================================

control ScoperIngress(
        in switch_lookup_fields_t    lkp_in,
		in switch_drop_reason_t      drop_reason,

        inout switch_lookup_fields_t lkp
) {

	apply {
		lkp = lkp_in;
	}
}

// ============================================================================

control ScoperOuterEgress(
		in ethernet_h                l2,
		in e_tag_h                   l2_e_tag,
		in vn_tag_h                  l2_vn_tag,
		in vlan_tag_h                l2_tag0,
		in vlan_tag_h                l2_tag1,

		in ipv4_h                    l3_ipv4,
#ifdef IPV6_ENABLE
		in ipv6_h                    l3_ipv6,
#endif  /* IPV6_ENABLE */
		in tcp_h                     l4_tcp,
		in udp_h                     l4_udp,
		in sctp_h                    l4_sctp,

		in switch_tunnel_type_t      tunnel_type,    // only send in actual tunnels here -- do not send in vlan tunnels (use vlan input instead)
		in switch_tunnel_id_t        tunnel_id,      // only send in actual tunnels here -- do not send in vlan tunnels (use vlan input instead)

		in switch_drop_reason_t      drop_reason,

        inout switch_lookup_fields_t lkp
) {

    // -----------------------------
	// L2
    // -----------------------------

    action scope_l2_none() {
        lkp.mac_src_addr = 0;
        lkp.mac_dst_addr = 0;
        lkp.mac_type     = 0;
        lkp.pcp          = 0;
	}

    action scope_l2() {
        lkp.mac_src_addr = l2.src_addr;
        lkp.mac_dst_addr = l2.dst_addr;
        lkp.mac_type     = l2.ether_type;
        lkp.pcp          = 0;
    }

    action scope_l2_e_tag() {
        lkp.mac_src_addr = l2.src_addr;
        lkp.mac_dst_addr = l2.dst_addr;
        lkp.mac_type     = l2_e_tag.ether_type;
        lkp.pcp          = l2_e_tag.pcp;
    }

    action scope_l2_vn_tag() {
        lkp.mac_src_addr = l2.src_addr;
        lkp.mac_dst_addr = l2.dst_addr;
        lkp.mac_type     = l2_vn_tag.ether_type;
        lkp.pcp          = 0;
    }

    action scope_l2_1tag() {
        lkp.mac_src_addr = l2.src_addr;
        lkp.mac_dst_addr = l2.dst_addr;
        lkp.mac_type     = l2_tag0.ether_type;
        lkp.pcp          = l2_tag0.pcp;
    }

    action scope_l2_2tags() {
        lkp.mac_src_addr = l2.src_addr;
        lkp.mac_dst_addr = l2.dst_addr;
#ifdef BUG_INVALID_LONG_BRANCH_WORKAROUND
        lkp.mac_type     = l2_tag0.ether_type;
#else
		// Derek: This is what we want, but it causes the compiler to dump out with:
		//
		//   ./npb/pipe/npb.bfa:6313: error: Invalid long branch tag 8
		//   ./npb/pipe/npb.bfa:6938: error: Invalid long branch tag 9

        lkp.mac_type     = l2_tag1.ether_type;
#endif
        lkp.pcp          = l2_tag1.pcp;
    }

    table scope_l2_ {
        key = {
			l2.isValid(): exact;
			l2_e_tag.isValid(): exact;
			l2_vn_tag.isValid(): exact;
            l2_tag0.isValid(): exact;
            l2_tag1.isValid(): exact;
        }
        actions = {
            scope_l2_none;
            scope_l2;
            scope_l2_e_tag;
            scope_l2_vn_tag;
            scope_l2_1tag;
            scope_l2_2tags;
        }
        const entries = {
            (false, false, false, false, false): scope_l2_none();

            (true,  false, false, false, false): scope_l2();

            (true,  true,  false, false, false): scope_l2_e_tag();
            (true,  false, true,  false, false): scope_l2_vn_tag();

            (true,  false, false, true,  false): scope_l2_1tag();
            (true,  true,  false, true,  false): scope_l2_1tag();
            (true,  false, true,  true,  false): scope_l2_1tag();

            (true,  false, false, true,  true ): scope_l2_2tags();
            (true,  true,  false, true,  true ): scope_l2_2tags();
            (true,  false, true,  true,  true ): scope_l2_2tags();
        }

	}

    // -----------------------------
	// L3
    // -----------------------------

    action scope_l3_none() {
        lkp.ip_type     = 0;
        lkp.ip_tos      = 0;
        lkp.ip_proto    = 0;
#ifdef BUG_10439_WORKAROUND
        lkp.ip_src_addr_3 = 0;
        lkp.ip_src_addr_2 = 0;
        lkp.ip_src_addr_1 = 0;
        lkp.ip_src_addr_0 = 0;
        lkp.ip_dst_addr_3 = 0;
        lkp.ip_dst_addr_2 = 0;
        lkp.ip_dst_addr_1 = 0;
        lkp.ip_dst_addr_0 = 0;        
#else
        lkp.ip_src_addr = 0;
        lkp.ip_dst_addr = 0;
#endif // BUG_10439_WORKAROUND
        lkp.ip_len      = 0; // extreme added
	} 

    action scope_l3_v4() {
        lkp.ip_type     = SWITCH_IP_TYPE_IPV4;
        lkp.ip_tos      = l3_ipv4.tos;
        lkp.ip_proto    = l3_ipv4.protocol;
#ifdef BUG_10439_WORKAROUND
        lkp.ip_src_addr_3 = 0;
        lkp.ip_src_addr_2 = 0;
        lkp.ip_src_addr_1 = 0;
        lkp.ip_src_addr_0 = l3_ipv4.src_addr;
        lkp.ip_dst_addr_3 = 0;
        lkp.ip_dst_addr_2 = 0;
        lkp.ip_dst_addr_1 = 0;
        lkp.ip_dst_addr_0 = l3_ipv4.dst_addr;        
#else
        lkp.ip_src_addr = (bit<128>) l3_ipv4.src_addr;
        lkp.ip_dst_addr = (bit<128>) l3_ipv4.dst_addr;
#endif // BUG_10439_WORKAROUND
        lkp.ip_len      = l3_ipv4.total_len;
    }

#ifdef IPV6_ENABLE
    action scope_l3_v6() {
        lkp.ip_type     = SWITCH_IP_TYPE_IPV6;
        lkp.ip_tos      = l3_ipv6.tos;
        lkp.ip_proto    = l3_ipv6.next_hdr;
#ifdef BUG_10439_WORKAROUND
        lkp.ip_src_addr_3 = l3_ipv6.src_addr_3;
        lkp.ip_src_addr_2 = l3_ipv6.src_addr_2;
        lkp.ip_src_addr_1 = l3_ipv6.src_addr_1;
        lkp.ip_src_addr_0 = l3_ipv6.src_addr_0;
        lkp.ip_dst_addr_3 = l3_ipv6.dst_addr_3;
        lkp.ip_dst_addr_2 = l3_ipv6.dst_addr_2;
        lkp.ip_dst_addr_1 = l3_ipv6.dst_addr_1;
        lkp.ip_dst_addr_0 = l3_ipv6.dst_addr_0;
#else
        lkp.ip_src_addr = l3_ipv6.src_addr;
        lkp.ip_dst_addr = l3_ipv6.dst_addr;
#endif // BUG_10439_WORKAROUND
        lkp.ip_len      = l3_ipv6.payload_len;
    }
#endif  /* IPV6_ENABLE */

    table scope_l3_ {
        key = {
            l3_ipv4.isValid(): exact;
#ifdef IPV6_ENABLE
            l3_ipv6.isValid(): exact;
#endif  /* IPV6_ENABLE */
        }
        actions = {
            scope_l3_none;
            scope_l3_v4;
#ifdef IPV6_ENABLE
            scope_l3_v6;
#endif  /* IPV6_ENABLE */
        }
        const entries = {
#ifdef IPV6_ENABLE
			(false, false): scope_l3_none();
            (true,  false): scope_l3_v4();
            (false, true ): scope_l3_v6();
#else
			(false       ): scope_l3_none();
            (true        ): scope_l3_v4();
#endif  /* IPV6_ENABLE */
        }

	}

    // -----------------------------
	// L4
    // -----------------------------

    action scope_l4_none() {
        lkp.l4_src_port = 0;
        lkp.l4_dst_port = 0;
        lkp.tcp_flags   = 0;
	} 

    action scope_l4_tcp() {
        lkp.l4_src_port = l4_tcp.src_port;
        lkp.l4_dst_port = l4_tcp.dst_port;
        lkp.tcp_flags   = l4_tcp.flags;
    }

    action scope_l4_udp() {
        lkp.l4_src_port = l4_udp.src_port;
        lkp.l4_dst_port = l4_udp.dst_port;
        lkp.tcp_flags   = 0;
    }

    action scope_l4_sctp() {
        lkp.l4_src_port = l4_sctp.src_port;
        lkp.l4_dst_port = l4_sctp.dst_port;
        lkp.tcp_flags   = 0;
    }

    table scope_l4_ {
        key = {
            l4_tcp.isValid():  exact;
            l4_udp.isValid():  exact;
            l4_sctp.isValid(): exact;
        }
        actions = {
            scope_l4_tcp;
            scope_l4_udp;
            scope_l4_sctp;
			scope_l4_none;
        }
        const entries = {
            (false, false, false): scope_l4_none();
            (true,  false, false): scope_l4_tcp();
            (false, true,  false): scope_l4_udp();
            (false, false, true ): scope_l4_sctp();
        }

	}

    // -----------------------------
	// TUNNEL
    // -----------------------------

    action scope_tunnel_none() {
        lkp.tunnel_type = 0;
        lkp.tunnel_id   = 0;
	}
/*
    action scope_tunnel_vlan() {
		lkp.tunnel_type = SWITCH_TUNNEL_TYPE_VLAN;
		lkp.tunnel_id   = (switch_tunnel_id_t)l2_tag0.vid;
    }
*/
    action scope_tunnel_vni() {
		lkp.tunnel_type = tunnel_type;
		lkp.tunnel_id   = tunnel_id;
    }

    table scope_tunnel_ {
        key = {
            tunnel_type: exact;
/*
            tunnel_type: ternary;
            l2_tag0.isValid(): exact;
            l2_tag0.vid: ternary;
*/
        }
        actions = {
            scope_tunnel_vni;
//          scope_tunnel_vlan;
            scope_tunnel_none;
        }
        const entries = {
/*
			// highest -> lowest priority in tcam
            (0, true,  0): scope_tunnel_none(); // tag has priority only
            (0, true,  _): scope_tunnel_vlan(); // tag has priority and vlan
            (_, true,  _): scope_tunnel_vni();
            (_, false, _): scope_tunnel_vni();
            (0, false, _): scope_tunnel_none();
*/
            (SWITCH_TUNNEL_TYPE_NONE): scope_tunnel_none();
        }
        const default_action = scope_tunnel_vni;

	}

    // -----------------------------
	// Apply
    // -----------------------------

	apply {
		scope_l2_.apply();
		scope_l3_.apply();
		scope_l4_.apply();
		scope_tunnel_.apply();

		lkp.drop_reason = drop_reason;
	}

}

// ============================================================================

control ScoperInnerEgress(
		in ethernet_h                l2,
		in vlan_tag_h                l2_tag0,

		in ipv4_h                    l3_ipv4,
#ifdef IPV6_ENABLE
		in ipv6_h                    l3_ipv6,
#endif  /* IPV6_ENABLE */
		in tcp_h                     l4_tcp,
		in udp_h                     l4_udp,
		in sctp_h                    l4_sctp,

		in switch_tunnel_type_t      tunnel_type,    // only send in actual tunnels here -- do not send in vlan tunnels (use vlan input instead)
		in switch_tunnel_id_t        tunnel_id,      // only send in actual tunnels here -- do not send in vlan tunnels (use vlan input instead)

		in switch_drop_reason_t      drop_reason,

        inout switch_lookup_fields_t lkp
) {

    // -----------------------------
	// L2
    // -----------------------------

    action scope_l2_none() {
        lkp.mac_src_addr = 0;
        lkp.mac_dst_addr = 0;
        lkp.mac_type     = 0;
        lkp.pcp          = 0;
	}

    action scope_l2() {
        lkp.mac_src_addr = l2.src_addr;
        lkp.mac_dst_addr = l2.dst_addr;
        lkp.mac_type     = l2.ether_type;
        lkp.pcp          = 0;
    }

    action scope_l2_1tag() {
        lkp.mac_src_addr = l2.src_addr;
        lkp.mac_dst_addr = l2.dst_addr;
        lkp.mac_type     = l2_tag0.ether_type;
        lkp.pcp          = l2_tag0.pcp;
    }

    table scope_l2_ {
        key = {
			l2.isValid(): exact;
            l2_tag0.isValid(): exact;
        }
        actions = {
            scope_l2_none;
            scope_l2;
            scope_l2_1tag;
        }
        const entries = {
            (false, false): scope_l2_none();

            (true,  false): scope_l2();

            (true,  true ): scope_l2_1tag();
        }

	}

    // -----------------------------
	// L3
    // -----------------------------

    action scope_l3_none() {
        lkp.ip_type     = 0;
        lkp.ip_tos      = 0;
        lkp.ip_proto    = 0;
#ifdef BUG_10439_WORKAROUND
        lkp.ip_src_addr_3 = 0;
        lkp.ip_src_addr_2 = 0;
        lkp.ip_src_addr_1 = 0;
        lkp.ip_src_addr_0 = 0;
        lkp.ip_dst_addr_3 = 0;
        lkp.ip_dst_addr_2 = 0;
        lkp.ip_dst_addr_1 = 0;
        lkp.ip_dst_addr_0 = 0;        
#else
        lkp.ip_src_addr = 0;
        lkp.ip_dst_addr = 0;
#endif // BUG_10439_WORKAROUND
        lkp.ip_len      = 0; // extreme added
	} 

    action scope_l3_v4() {
        lkp.ip_type     = SWITCH_IP_TYPE_IPV4;
        lkp.ip_tos      = l3_ipv4.tos;
        lkp.ip_proto    = l3_ipv4.protocol;
#ifdef BUG_10439_WORKAROUND
        lkp.ip_src_addr_3 = 0;
        lkp.ip_src_addr_2 = 0;
        lkp.ip_src_addr_1 = 0;
        lkp.ip_src_addr_0 = l3_ipv4.src_addr;
        lkp.ip_dst_addr_3 = 0;
        lkp.ip_dst_addr_2 = 0;
        lkp.ip_dst_addr_1 = 0;
        lkp.ip_dst_addr_0 = l3_ipv4.dst_addr;        
#else
        lkp.ip_src_addr = (bit<128>) l3_ipv4.src_addr;
        lkp.ip_dst_addr = (bit<128>) l3_ipv4.dst_addr;
#endif // BUG_10439_WORKAROUND
        lkp.ip_len      = l3_ipv4.total_len;
    }

#ifdef IPV6_ENABLE
    action scope_l3_v6() {
        lkp.ip_type     = SWITCH_IP_TYPE_IPV6;
        lkp.ip_tos      = l3_ipv6.tos;
        lkp.ip_proto    = l3_ipv6.next_hdr;
#ifdef BUG_10439_WORKAROUND
        lkp.ip_src_addr_3 = l3_ipv6.src_addr_3;
        lkp.ip_src_addr_2 = l3_ipv6.src_addr_2;
        lkp.ip_src_addr_1 = l3_ipv6.src_addr_1;
        lkp.ip_src_addr_0 = l3_ipv6.src_addr_0;
        lkp.ip_dst_addr_3 = l3_ipv6.dst_addr_3;
        lkp.ip_dst_addr_2 = l3_ipv6.dst_addr_2;
        lkp.ip_dst_addr_1 = l3_ipv6.dst_addr_1;
        lkp.ip_dst_addr_0 = l3_ipv6.dst_addr_0;
#else
        lkp.ip_src_addr = l3_ipv6.src_addr;
        lkp.ip_dst_addr = l3_ipv6.dst_addr;
#endif // BUG_10439_WORKAROUND
        lkp.ip_len      = l3_ipv6.payload_len;
    }
#endif  /* IPV6_ENABLE */

    table scope_l3_ {
        key = {
            l3_ipv4.isValid(): exact;
#ifdef IPV6_ENABLE
            l3_ipv6.isValid(): exact;
#endif  /* IPV6_ENABLE */
        }
        actions = {
            scope_l3_none;
            scope_l3_v4;
#ifdef IPV6_ENABLE
            scope_l3_v6;
#endif  /* IPV6_ENABLE */
        }
        const entries = {
#ifdef IPV6_ENABLE
			(false, false): scope_l3_none();
            (true,  false): scope_l3_v4();
            (false, true ): scope_l3_v6();
#else
			(false       ): scope_l3_none();
            (true        ): scope_l3_v4();
#endif  /* IPV6_ENABLE */
        }

	}

    // -----------------------------
	// L4
    // -----------------------------

    action scope_l4_none() {
        lkp.l4_src_port = 0;
        lkp.l4_dst_port = 0;
        lkp.tcp_flags   = 0;
	} 

    action scope_l4_tcp() {
        lkp.l4_src_port = l4_tcp.src_port;
        lkp.l4_dst_port = l4_tcp.dst_port;
        lkp.tcp_flags   = l4_tcp.flags;
    }

    action scope_l4_udp() {
        lkp.l4_src_port = l4_udp.src_port;
        lkp.l4_dst_port = l4_udp.dst_port;
        lkp.tcp_flags   = 0;
    }

    action scope_l4_sctp() {
        lkp.l4_src_port = l4_sctp.src_port;
        lkp.l4_dst_port = l4_sctp.dst_port;
        lkp.tcp_flags   = 0;
    }

    table scope_l4_ {
        key = {
            l4_tcp.isValid():  exact;
            l4_udp.isValid():  exact;
            l4_sctp.isValid(): exact;
        }
        actions = {
            scope_l4_tcp;
            scope_l4_udp;
            scope_l4_sctp;
			scope_l4_none;
        }
        const entries = {
            (false, false, false): scope_l4_none();
            (true,  false, false): scope_l4_tcp();
            (false, true,  false): scope_l4_udp();
            (false, false, true ): scope_l4_sctp();
        }

	}

    // -----------------------------
	// TUNNEL
    // -----------------------------

    action scope_tunnel_none() {
        lkp.tunnel_type = 0;
        lkp.tunnel_id   = 0;
	}
/*
    action scope_tunnel_vlan() {
		lkp.tunnel_type = SWITCH_TUNNEL_TYPE_VLAN;
		lkp.tunnel_id   = (switch_tunnel_id_t)l2_tag0.vid;
    }
*/
    action scope_tunnel_vni() {
		lkp.tunnel_type = tunnel_type;
		lkp.tunnel_id   = tunnel_id;
    }

    table scope_tunnel_ {
        key = {
            tunnel_type: exact;
/*
            tunnel_type: ternary;
            l2_tag0.isValid(): exact;
            l2_tag0.vid: ternary;
*/
        }
        actions = {
            scope_tunnel_vni;
//          scope_tunnel_vlan;
            scope_tunnel_none;
        }
        const entries = {
/*
			// highest -> lowest priority in tcam
            (0, true,  0): scope_tunnel_none(); // tag has priority only
            (0, true,  _): scope_tunnel_vlan(); // tag has priority and vlan
            (_, true,  _): scope_tunnel_vni();
            (_, false, _): scope_tunnel_vni();
            (0, false, _): scope_tunnel_none();
*/
            (SWITCH_TUNNEL_TYPE_NONE): scope_tunnel_none();
        }
        const default_action = scope_tunnel_vni;

	}

    // -----------------------------
	// Apply
    // -----------------------------

	apply {
		scope_l2_.apply();
		scope_l3_.apply();
		scope_l4_.apply();
		scope_tunnel_.apply();

		lkp.drop_reason = drop_reason;
	}

}

// ============================================================================
/*
control Scoper_l7(
    in udf_h hdr_l7_udf,
    inout switch_lookup_fields_t lkp
) {
    // -----------------------------
        
    action set_udf() {
#ifdef UDF_ENABLE
        lkp.l7_udf = hdr_l7_udf.opaque;
#endif 
    }

    action clear_udf() {
#ifdef UDF_ENABLE
        lkp.l7_udf = 0;
#endif
    }

    table validate_udf {
        key = {
            hdr_l7_udf.isValid() : exact;
        }

        actions = {
            NoAction;
            set_udf;
            clear_udf;
        }

        const default_action = NoAction;
        const entries = {
            (true)  : set_udf();
            (false) : clear_udf();
        }
    }

    // -----------------------------

    apply {
#ifdef UDF_ENABLE
        validate_udf.apply();
#endif // UDF_ENABLE
    }

}
*/
#endif
