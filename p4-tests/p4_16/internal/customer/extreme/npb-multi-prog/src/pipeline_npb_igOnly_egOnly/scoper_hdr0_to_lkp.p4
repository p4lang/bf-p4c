#ifndef _SCOPER_HDR0_TO_LKP_
#define _SCOPER_HDR0_TO_LKP_

// ============================================================================
// Low Level Routines (meant to only be used by functions within this file)
// ============================================================================

control Scoper_Hdr0_To_Lkp(
	in switch_header_transport_t hdr_curr,
	in switch_header_outer_t     hdr_next,
	in switch_lookup_fields_t    lkp_curr,
	in bool                      flags_unsupported_tunnel,

	inout switch_lookup_fields_t lkp
) (
	MODULE_DEPLOYMENT_PARAMS
) {

	// -----------------------------
	// L2
	// -----------------------------
/*
	action scope_l2_none() {
		lkp.l2_valid     = false;
		lkp.mac_src_addr = 0;
		lkp.mac_dst_addr = 0;
		lkp.mac_type     = 0;
		lkp.pcp          = 0;
		lkp.pad          = 0;
		lkp.vid          = 0;
	}
*/
	action scope_l2_0tag() {
		lkp.l2_valid     = true;
		lkp.mac_src_addr = hdr_curr.ethernet.src_addr;
		lkp.mac_dst_addr = hdr_curr.ethernet.dst_addr;
		lkp.mac_type     = hdr_curr.ethernet.ether_type;
		lkp.pcp          = 0;
		lkp.pad          = 0;
		lkp.vid          = 0;
	}

	action scope_l2_1tag() {
		lkp.l2_valid     = true;
		lkp.mac_src_addr = hdr_curr.ethernet.src_addr;
		lkp.mac_dst_addr = hdr_curr.ethernet.dst_addr;
		lkp.mac_type     = hdr_curr.vlan_tag[0].ether_type;
		lkp.pcp          = hdr_curr.vlan_tag[0].pcp;
		lkp.pad          = 0;
		lkp.vid          = hdr_curr.vlan_tag[0].vid;
	}

	// -----------------------------
	// L3
	// -----------------------------

	action scope_l3_none() {
		lkp.ip_type       = SWITCH_IP_TYPE_NONE;
		lkp.ip_proto      = 0;
		lkp.ip_tos        = 0;
		lkp.ip_flags      = 0;
		lkp.ip_src_addr   = 0;
		lkp.ip_dst_addr   = 0;
		lkp.ip_len        = 0; // extreme added
	}

	action scope_l3_v4() {
		if(TRANSPORT_IPV4_INGRESS_ENABLE) {
			lkp.ip_type       = SWITCH_IP_TYPE_IPV4;
			lkp.ip_proto      = hdr_curr.ipv4.protocol;
			lkp.ip_tos        = hdr_curr.ipv4.tos;
			lkp.ip_flags      = hdr_curr.ipv4.flags;
			lkp.ip_src_addr_v4= hdr_curr.ipv4.src_addr;
			lkp.ip_dst_addr_v4= hdr_curr.ipv4.dst_addr;
			lkp.ip_len        = hdr_curr.ipv4.total_len;
		}
	}

	action scope_l3_v6() {
		if(TRANSPORT_IPV6_INGRESS_ENABLE) {
			lkp.ip_type       = SWITCH_IP_TYPE_IPV6;
			lkp.ip_proto      = hdr_curr.ipv6.next_hdr;
			lkp.ip_tos        = hdr_curr.ipv6.tos;
			lkp.ip_flags      = 0;
			lkp.ip_src_addr   = hdr_curr.ipv6.src_addr;
			lkp.ip_dst_addr   = hdr_curr.ipv6.dst_addr;
			lkp.ip_len        = hdr_curr.ipv6.payload_len;
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
//		lkp.l4_src_port = hdr_curr.tcp.src_port;
//		lkp.l4_dst_port = hdr_curr.tcp.dst_port;
//		lkp.tcp_flags   = hdr_curr.tcp.flags;
	}

	action scope_l4_udp() {
		if((TRANSPORT_IPV4_INGRESS_ENABLE || TRANSPORT_IPV6_INGRESS_ENABLE) && (TRANSPORT_IPV4_VXLAN_INGRESS_ENABLE || TRANSPORT_IPV4_GENEVE_INGRESS_ENABLE)) {
			lkp.l4_src_port = hdr_curr.udp.src_port;
			lkp.l4_dst_port = hdr_curr.udp.dst_port;
			lkp.tcp_flags   = 0;
		}
	}


	action scope_l4_sctp() {
//		lkp.l4_src_port = hdr_curr.sctp.src_port;
//		lkp.l4_dst_port = hdr_curr.sctp.dst_port;
//		lkp.tcp_flags   = 0;
	}

	// -----------------------------
	// TUNNEL
	// -----------------------------

	action scope_tunnel_none() {
		lkp.tunnel_type    = SWITCH_TUNNEL_TYPE_NONE;
		lkp.tunnel_id      = 0;
		lkp.next_lyr_valid = false;
	}

	action scope_tunnel_use_parser_values(bool lkp_curr_next_lyr_valid) {
		lkp.tunnel_type    = lkp_curr.tunnel_type;
		lkp.tunnel_id      = lkp_curr.tunnel_id;
		lkp.next_lyr_valid = lkp_curr_next_lyr_valid;
	}

	// -----------------------------

	table scope_tunnel_ {
		key = {
			lkp_curr.tunnel_type: exact;
		}
		actions = {
			scope_tunnel_none;
			scope_tunnel_use_parser_values;
		}
		const entries = {
			(SWITCH_TUNNEL_TYPE_GTPC):        scope_tunnel_use_parser_values(false);
			(SWITCH_TUNNEL_TYPE_NONE):        scope_tunnel_none();
			(SWITCH_TUNNEL_TYPE_UNSUPPORTED): scope_tunnel_use_parser_values(false);
			(SWITCH_TUNNEL_TYPE_VXLAN):       scope_tunnel_use_parser_values(true); // filler entries to get rid of compiler bug when less than 4 constant entries
			(SWITCH_TUNNEL_TYPE_IPINIP):      scope_tunnel_use_parser_values(true); // filler entries to get rid of compiler bug when less than 4 constant entries
		}
		const default_action = scope_tunnel_use_parser_values(true);
	}

	// -----------------------------
	// L2 / L3 / L4
	// -----------------------------

//	action scope_l2_none_l3_none_l4_none() { scope_l2_none(); scope_l3_none(); scope_l4_none(); }
	// l2 only
	action scope_l2_0tag_l3_none_l4_none() { scope_l2_0tag(); scope_l3_none(); scope_l4_none(); }
	action scope_l2_1tag_l3_none_l4_none() { scope_l2_1tag(); scope_l3_none(); scope_l4_none(); }
	// l2, l3, l4
	action scope_l2_0tag_l3_v4_l4_none()   { scope_l2_0tag(); scope_l3_v4();   scope_l4_none(); }
	action scope_l2_1tag_l3_v4_l4_none()   { scope_l2_1tag(); scope_l3_v4();   scope_l4_none(); }
	action scope_l2_0tag_l3_v4_l4_udp()    { scope_l2_0tag(); scope_l3_v4();   scope_l4_udp();  }
	action scope_l2_1tag_l3_v4_l4_udp()    { scope_l2_1tag(); scope_l3_v4();   scope_l4_udp();  }

	action scope_l2_0tag_l3_v6_l4_none()   { scope_l2_0tag(); scope_l3_v6();   scope_l4_none(); }
	action scope_l2_1tag_l3_v6_l4_none()   { scope_l2_1tag(); scope_l3_v6();   scope_l4_none(); }
	action scope_l2_0tag_l3_v6_l4_udp()    { scope_l2_0tag(); scope_l3_v6();   scope_l4_udp();  }
	action scope_l2_1tag_l3_v6_l4_udp()    { scope_l2_1tag(); scope_l3_v6();   scope_l4_udp();  }

	// -----------------------------

	bool hdr_curr_ipv4_isValid;
	bool hdr_curr_ipv6_isValid;
	bool hdr_curr_udp_isValid;

	table scope_l234_ {
		key = {
			hdr_curr.ethernet.isValid(): exact;
			hdr_curr.vlan_tag[0].isValid(): exact;
			hdr_curr_ipv4_isValid: exact;
			hdr_curr_ipv6_isValid: exact;
			hdr_curr_udp_isValid: exact;
		}
		actions = {
//			scope_l2_none_l3_none_l4_none;
			// l2 only
			scope_l2_0tag_l3_none_l4_none;
			scope_l2_1tag_l3_none_l4_none;
			// l2, l3, l4
			scope_l2_0tag_l3_v4_l4_none;
			scope_l2_1tag_l3_v4_l4_none;
			scope_l2_0tag_l3_v4_l4_udp;
			scope_l2_1tag_l3_v4_l4_udp;

			scope_l2_0tag_l3_v6_l4_none;
			scope_l2_1tag_l3_v6_l4_none;
			scope_l2_0tag_l3_v6_l4_udp;
			scope_l2_1tag_l3_v6_l4_udp;
		}
		const entries = {
			// l2             l3                l4
			// ----------     -------------     ------
			(true, false,     false, false,     false): scope_l2_0tag_l3_none_l4_none;
			(true, true,      false, false,     false): scope_l2_1tag_l3_none_l4_none;

			(true, false,     true,  false,     false): scope_l2_0tag_l3_v4_l4_none;
			(true, true,      true,  false,     false): scope_l2_1tag_l3_v4_l4_none;
			(true, false,     true,  false,     true ): scope_l2_0tag_l3_v4_l4_udp;
			(true, true,      true,  false,     true ): scope_l2_1tag_l3_v4_l4_udp;

			(true, false,     false, true,      false): scope_l2_0tag_l3_v6_l4_none;
			(true, true,      false, true,      false): scope_l2_1tag_l3_v6_l4_none;
			(true, false,     false, true,      true ): scope_l2_0tag_l3_v6_l4_udp;
			(true, true,      false, true,      true ): scope_l2_1tag_l3_v6_l4_udp;
		}
//		const default_action = scope_l2_none_l3_none_l4_none;
	}

	// -----------------------------
	// Apply
	// -----------------------------

	apply {
		if((TRANSPORT_IPV4_INGRESS_ENABLE))        hdr_curr_ipv4_isValid         = hdr_curr.ipv4.isValid();
		if((TRANSPORT_IPV6_INGRESS_ENABLE))        hdr_curr_ipv6_isValid         = hdr_curr.ipv6.isValid();
		if((TRANSPORT_IPV4_VXLAN_INGRESS_ENABLE) || \
		   (TRANSPORT_IPV4_GENEVE_INGRESS_ENABLE)) hdr_curr_udp_isValid          = hdr_curr.udp.isValid();

		scope_l234_.apply();

		// ------------------------

		// Note: we can't use our tunnel table, because we don't know about the parser's unsupported tunnel type
/*
		lkp.tunnel_type    = lkp_curr.tunnel_type;
		scope_tunnel_.apply();
*/
/*
		if(lkp_curr.tunnel_type == SWITCH_TUNNEL_TYPE_NONE) {
			// for handling overload case
			scope_tunnel_none();
		} else {
			scope_tunnel_use_parser_values(lkp_curr.next_lyr_valid);
		}
*/
		scope_tunnel_.apply();
	}
}

#endif
