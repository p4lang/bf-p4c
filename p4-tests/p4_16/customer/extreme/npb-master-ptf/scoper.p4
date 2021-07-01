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
// Low Level Routines (meant to only be used by functions within this file)
// ============================================================================

control Scoper_DataMux_LkpToLkp(
		in    switch_lookup_fields_t lkp_in,

		inout switch_lookup_fields_t lkp
) {

//	action scoper() {
	apply {
#if 0
		// Derek: Can't use this code, as we need to alias the 128-bit ip addresses with a 32-bit version.  Need to use the code below instead.
		lkp = lkp_in;
#else
		// l2
		if(lkp_in.l2_valid != false) {
			// only update if next layer has l2
			lkp.mac_src_addr        = lkp_in.mac_src_addr;
			lkp.mac_dst_addr        = lkp_in.mac_dst_addr;
//			lkp.mac_type            = lkp_in.mac_type;
			lkp.pcp                 = lkp_in.pcp;
			lkp.pad                 = lkp_in.pad;
			lkp.vid                 = lkp_in.vid;
		}
		lkp.mac_type            = lkp_in.mac_type;

		// l3
		lkp.ip_type             = lkp_in.ip_type;
		lkp.ip_proto            = lkp_in.ip_proto;
		lkp.ip_tos              = lkp_in.ip_tos;
		lkp.ip_flags            = lkp_in.ip_flags;
		lkp.ip_src_addr         = lkp_in.ip_src_addr;
		lkp.ip_dst_addr         = lkp_in.ip_dst_addr;
		// Comment the two below as they are alias fields and do not need to be written again.
		//lkp.ip_src_addr_v4    = lkp_in.ip_src_addr_v4;
		//lkp.ip_dst_addr_v4    = lkp_in.ip_dst_addr_v4;
		lkp.ip_len              = lkp_in.ip_len;

		// l4
		lkp.tcp_flags           = lkp_in.tcp_flags;
		lkp.l4_src_port         = lkp_in.l4_src_port;
		lkp.l4_dst_port         = lkp_in.l4_dst_port;

		// tunnel
  #ifdef INGRESS_PARSER_INNER_TUNNEL_INFO_OVERLOAD
		if(lkp_in.tunnel_type != SWITCH_TUNNEL_TYPE_NONE) {
			// only update if next layer has tunnel
			lkp.tunnel_type         = lkp_in.tunnel_type;
			lkp.tunnel_id           = lkp_in.tunnel_id;
		}
  #else
		lkp.tunnel_type         = lkp_in.tunnel_type;
		lkp.tunnel_id           = lkp_in.tunnel_id;
  #endif

  #ifdef SF_2_ACL_INNER_OUTER_TUNNEL_KEY_ENABLE
		// outer means two back from current scope (scope-2), inner means one back from current scope (scope-1)
		lkp.tunnel_outer_type   = lkp_in.tunnel_outer_type; // egress only
		lkp.tunnel_inner_type   = lkp_in.tunnel_inner_type; // egress only
  #endif

		// misc
		lkp.next_lyr_valid      = lkp_in.next_lyr_valid;
#endif
	}
/*
	apply {
		scoper();
	}
*/
}

// ============================================================================

control Scoper_DataMux_Hdr0ToLkp(
		in switch_header_transport_t hdr_0,
		in switch_header_outer_t     hdr_1,
		in    switch_lookup_fields_t lkp_in,

		inout switch_lookup_fields_t lkp
) {

	// -----------------------------
	// L2
	// -----------------------------

	action scope_l2_none() {
		lkp.l2_valid     = false;
		lkp.mac_src_addr = 0;
		lkp.mac_dst_addr = 0;
		lkp.mac_type     = 0;
		lkp.pcp          = 0;
		lkp.pad          = 0;
		lkp.vid          = 0;
	}

	action scope_l2_0tag() {
		lkp.l2_valid     = true;
		lkp.mac_src_addr = hdr_0.ethernet.src_addr;
		lkp.mac_dst_addr = hdr_0.ethernet.dst_addr;
		lkp.mac_type     = hdr_0.ethernet.ether_type;
		lkp.pcp          = 0;
		lkp.pad          = 0;
		lkp.vid          = 0;
	}

	action scope_l2_1tag() {
		lkp.l2_valid     = true;
		lkp.mac_src_addr = hdr_0.ethernet.src_addr;
		lkp.mac_dst_addr = hdr_0.ethernet.dst_addr;
		lkp.mac_type     = hdr_0.vlan_tag[0].ether_type;
		lkp.pcp          = hdr_0.vlan_tag[0].pcp;
		lkp.pad          = 0;
		lkp.vid          = hdr_0.vlan_tag[0].vid;
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
		lkp.ip_type       = SWITCH_IP_TYPE_IPV4;
		lkp.ip_proto      = hdr_0.ipv4.protocol;
		lkp.ip_tos        = hdr_0.ipv4.tos;
		lkp.ip_flags      = hdr_0.ipv4.flags;
		lkp.ip_src_addr_v4= hdr_0.ipv4.src_addr;
		lkp.ip_dst_addr_v4= hdr_0.ipv4.dst_addr;
		lkp.ip_len        = hdr_0.ipv4.total_len;
	}

	action scope_l3_v6() {
#if defined(GRE_TRANSPORT_INGRESS_ENABLE_V6) || defined(ERSPAN_TRANSPORT_INGRESS_ENABLE_V6) || defined(GRE_TRANSPORT_EGRESS_ENABLE_V6)
		lkp.ip_type       = SWITCH_IP_TYPE_IPV6;
		lkp.ip_proto      = hdr_0.ipv6.next_hdr;
		lkp.ip_tos        = hdr_0.ipv6.tos;
		lkp.ip_flags      = 0;
		lkp.ip_src_addr   = hdr_0.ipv6.src_addr;
		lkp.ip_dst_addr   = hdr_0.ipv6.dst_addr;
		lkp.ip_len        = hdr_0.ipv6.payload_len;
#endif // IPV6_ENABLE
	}

	// -----------------------------
	// L4
	// -----------------------------

	action scope_l4_none() {
		lkp.l4_src_port = 0;
		lkp.l4_dst_port = 0;
		lkp.tcp_flags   = 0;
	}

#ifdef VXLAN_TRANSPORT_INGRESS_ENABLE_V4
	action scope_l4_udp() {
		lkp.l4_src_port = hdr_0.udp.src_port;
		lkp.l4_dst_port = hdr_0.udp.dst_port;
		lkp.tcp_flags   = 0;
	}
#endif // VXLAN_TRANSPORT_INGRESS_ENABLE_V4

	// -----------------------------
	// TUNNEL
	// -----------------------------

	action scope_tunnel_none() {
		lkp.tunnel_type    = SWITCH_TUNNEL_TYPE_NONE;
		lkp.tunnel_id      = 0;
		lkp.next_lyr_valid = false;
	}

	action scope_tunnel_ipinip() {
		lkp.tunnel_type    = SWITCH_TUNNEL_TYPE_IPINIP;
		lkp.tunnel_id      = 0;
		lkp.next_lyr_valid = true;
	}

	action scope_tunnel_gre() {
		lkp.tunnel_type    = SWITCH_TUNNEL_TYPE_GRE;
		lkp.tunnel_id      = 0;
		lkp.next_lyr_valid = true;
	}

	action scope_tunnel_vxlan() {
#ifdef VXLAN_TRANSPORT_INGRESS_ENABLE_V4
		lkp.tunnel_type    = SWITCH_TUNNEL_TYPE_VXLAN;
		lkp.tunnel_id      = (bit<32>)hdr_0.vxlan.vni;
		lkp.next_lyr_valid = true;
#endif // VXLAN_TRANSPORT_INGRESS_ENABLE_V4
	}

	action scope_tunnel_mpls() {
#ifdef MPLS_SR_TRANSPORT_INGRESS_ENABLE_V4
		lkp.tunnel_type    = SWITCH_TUNNEL_TYPE_MPLS;
		lkp.tunnel_id      = (bit<32>)hdr_0.mpls[0].label;
		lkp.next_lyr_valid = true;
#endif // MPLS_SR_TRANSPORT_INGRESS_ENABLE_V4 
	}

	action scope_tunnel_unsupported() {
		lkp.tunnel_type    = SWITCH_TUNNEL_TYPE_UNSUPPORTED;
		lkp.tunnel_id      = 0;
		lkp.next_lyr_valid = false; // unsupported has no next layer
	}

	action scope_tunnel_use_parser_values(bool lkp_in_next_lyr_valid) {
		lkp.tunnel_type    = lkp_in.tunnel_type;
		lkp.tunnel_id      = lkp_in.tunnel_id;
		lkp.next_lyr_valid = lkp_in_next_lyr_valid;
	}
/*
	table scope_tunnel_ {
		key = {
			hdr_0.gre.isValid(): exact;
#ifdef VXLAN_TRANSPORT_INGRESS_ENABLE_V4
			hdr_0.vxlan.isValid(): exact;
#endif // VXLAN_TRANSPORT_INGRESS_ENABLE_V4
#ifdef MPLS_SR_TRANSPORT_INGRESS_ENABLE_V4
			hdr_0.mpls[0].isValid(): exact;
#endif // MPLS_SR_TRANSPORT_INGRESS_ENABLE_V4
			hdr_1.ipv4.isValid(): exact;
			hdr_1.ipv6.isValid(): exact;
		}
		actions = {
			scope_tunnel_gre;
			scope_tunnel_vxlan;
			scope_tunnel_mpls;
			scope_tunnel_ipinip;
			scope_tunnel_none;
			scope_tunnel_unsupported;
		}
		const entries = {
#if !defined(VXLAN_TRANSPORT_INGRESS_ENABLE_V4) && !defined(MPLS_SR_TRANSPORT_INGRESS_ENABLE_V4)
		const entries = {
			// hdr0               hdr1
			// ------------------ ------------
			(true,                false, false): scope_tunnel_gre(); // hdr1 is a don't care
			(true,                true,  false): scope_tunnel_gre(); // hdr1 is a don't care
			(true,                false, true ): scope_tunnel_gre(); // hdr1 is a don't care

			{false,               true,  false}: scope_tunnel_ipinip(); // no tunnels valid, but next layer is...so must be ip-in-ip
			{false,               false, true }: scope_tunnel_ipinip(); // no tunnels valid, but next layer is...so must be ip-in-ip
		}
#endif // !VXLAN_TRANSPORT_INGRESS_ENABLE_V4 && !MPLS_SR_TRANSPORT_INGRESS_ENABLE_V4
#if  defined(VXLAN_TRANSPORT_INGRESS_ENABLE_V4) && !defined(MPLS_SR_TRANSPORT_INGRESS_ENABLE_V4)
			// hdr0               hdr1
			// ------------------ ------------
			(true,  false,        false, false): scope_tunnel_gre(); // hdr1 is a don't care
			(true,  false,        true,  false): scope_tunnel_gre(); // hdr1 is a don't care
			(true,  false,        false, true ): scope_tunnel_gre(); // hdr1 is a don't care

			(false, true,         false, false): scope_tunnel_vxlan(); // hdr1 is a don't care
			(false, true,         true,  false): scope_tunnel_vxlan(); // hdr1 is a don't care
			(false, true,         false, true ): scope_tunnel_vxlan(); // hdr1 is a don't care

			{false, false,        true,  false}: scope_tunnel_ipinip(); // no tunnels valid, but next layer is...so must be ip-in-ip
			{false, false,        false, true }: scope_tunnel_ipinip(); // no tunnels valid, but next layer is...so must be ip-in-ip
		}
#endif //  VXLAN_TRANSPORT_INGRESS_ENABLE_V4 && !MPLS_SR_TRANSPORT_INGRESS_ENABLE_V4
#if !defined(VXLAN_TRANSPORT_INGRESS_ENABLE_V4) &&  defined(MPLS_SR_TRANSPORT_INGRESS_ENABLE_V4)
			// hdr0               hdr1
			// ------------------ ------------
			(true,         false, false, false): scope_tunnel_gre(); // hdr1 is a don't care
			(true,         false, true,  false): scope_tunnel_gre(); // hdr1 is a don't care
			(true,         false, false, true ): scope_tunnel_gre(); // hdr1 is a don't care

			(false,        true,  false, false): scope_tunnel_mpls(); // hdr1 is a don't care
			(false,        true,  true,  false): scope_tunnel_mpls(); // hdr1 is a don't care
			(false,        true,  false, true ): scope_tunnel_mpls(); // hdr1 is a don't care

			{false,        false, true,  false}: scope_tunnel_ipinip(); // no tunnels valid, but next layer is...so must be ip-in-ip
			{false,        false, false, true }: scope_tunnel_ipinip(); // no tunnels valid, but next layer is...so must be ip-in-ip
		}
#endif // !VXLAN_TRANSPORT_INGRESS_ENABLE_V4 &&  MPLS_SR_TRANSPORT_INGRESS_ENABLE_V4
#if  defined(VXLAN_TRANSPORT_INGRESS_ENABLE_V4) &&  defined(MPLS_SR_TRANSPORT_INGRESS_ENABLE_V4)
			// hdr0               hdr1
			// ------------------ ------------
			(true,  false, false, false, false): scope_tunnel_gre(); // hdr1 is a don't care
			(true,  false, false, true,  false): scope_tunnel_gre(); // hdr1 is a don't care
			(true,  false, false, false, true ): scope_tunnel_gre(); // hdr1 is a don't care

			(false, true,  false, false, false): scope_tunnel_vxlan(); // hdr1 is a don't care
			(false, true,  false, true,  false): scope_tunnel_vxlan(); // hdr1 is a don't care
			(false, true,  false, false, true ): scope_tunnel_vxlan(); // hdr1 is a don't care

			(false, false, true,  false, false): scope_tunnel_mpls(); // hdr1 is a don't care
			(false, false, true,  true,  false): scope_tunnel_mpls(); // hdr1 is a don't care
			(false, false, true,  false, true ): scope_tunnel_mpls(); // hdr1 is a don't care

			{false, false, false, true,  false}: scope_tunnel_ipinip(); // no tunnels valid, but next layer is...so must be ip-in-ip
			{false, false, false, false, true }: scope_tunnel_ipinip(); // no tunnels valid, but next layer is...so must be ip-in-ip
		}
#endif //  VXLAN_TRANSPORT_INGRESS_ENABLE_V4 &&  MPLS_SR_TRANSPORT_INGRESS_ENABLE_V4
		const default_action = scope_tunnel_none;
	}
*/
	table scope_tunnel_ {
		key = {
			lkp_in.tunnel_type: exact;
		}
		actions = {
			scope_tunnel_none;
			scope_tunnel_use_parser_values;
		}
		const entries = {
			(SWITCH_TUNNEL_TYPE_GTPC):        scope_tunnel_use_parser_values(false);
			(SWITCH_TUNNEL_TYPE_NONE):        scope_tunnel_none();
			(SWITCH_TUNNEL_TYPE_UNSUPPORTED): scope_tunnel_use_parser_values(false);
//			(SWITCH_TUNNEL_TYPE_VXLAN):       scope_tunnel_use_parser_values(true); // filler entries to get rid of compiler bug when less than 4 constant entries
//			(SWITCH_TUNNEL_TYPE_IPINIP):      scope_tunnel_use_parser_values(true); // filler entries to get rid of compiler bug when less than 4 constant entries
		}
		const default_action = scope_tunnel_use_parser_values(true);
	}

	// -----------------------------
	// L2 / L3 / L4
	// -----------------------------

	action scope_l2_none_l3_none_l4_none() { scope_l2_none(); scope_l3_none(); scope_l4_none(); }

	action scope_l2_0tag_l3_none_l4_none() { scope_l2_0tag(); scope_l3_none(); scope_l4_none(); }
	action scope_l2_1tag_l3_none_l4_none() { scope_l2_1tag(); scope_l3_none(); scope_l4_none(); }

	action scope_l2_0tag_l3_v4_l4_none()   { scope_l2_0tag(); scope_l3_v4();   scope_l4_none(); }
	action scope_l2_1tag_l3_v4_l4_none()   { scope_l2_1tag(); scope_l3_v4();   scope_l4_none(); }
	action scope_l2_0tag_l3_v4_l4_udp()    { scope_l2_0tag(); scope_l3_v4();   scope_l4_udp();  }
	action scope_l2_1tag_l3_v4_l4_udp()    { scope_l2_1tag(); scope_l3_v4();   scope_l4_udp();  }

	action scope_l2_0tag_l3_v6_l4_none()   { scope_l2_0tag(); scope_l3_v6();   scope_l4_none(); }
	action scope_l2_1tag_l3_v6_l4_none()   { scope_l2_1tag(); scope_l3_v6();   scope_l4_none(); }
	action scope_l2_0tag_l3_v6_l4_udp()    { scope_l2_0tag(); scope_l3_v6();   scope_l4_udp();  }
	action scope_l2_1tag_l3_v6_l4_udp()    { scope_l2_1tag(); scope_l3_v6();   scope_l4_udp();  }

	table scope_l234_ {
		key = {
			hdr_0.ethernet.isValid(): exact;
			hdr_0.vlan_tag[0].isValid(): exact;
			hdr_0.ipv4.isValid(): exact;
#if defined(GRE_TRANSPORT_INGRESS_ENABLE_V6) || defined(ERSPAN_TRANSPORT_INGRESS_ENABLE_V6) || defined(GRE_TRANSPORT_EGRESS_ENABLE_V6)
			hdr_0.ipv6.isValid(): exact;
#endif // IPV6_ENABLE
#ifdef VXLAN_TRANSPORT_INGRESS_ENABLE_V4
			hdr_0.udp.isValid(): exact;
#endif // VXLAN_TRANSPORT_INGRESS_ENABLE_V4
		}
		actions = {
			scope_l2_none_l3_none_l4_none;

			scope_l2_0tag_l3_none_l4_none;
			scope_l2_1tag_l3_none_l4_none;

			scope_l2_0tag_l3_v4_l4_none;
			scope_l2_1tag_l3_v4_l4_none;
#ifdef VXLAN_TRANSPORT_INGRESS_ENABLE_V4
			scope_l2_0tag_l3_v4_l4_udp;
			scope_l2_1tag_l3_v4_l4_udp;
#endif // VXLAN_TRANSPORT_INGRESS_ENABLE_V4

			scope_l2_0tag_l3_v6_l4_none;
			scope_l2_1tag_l3_v6_l4_none;
#ifdef VXLAN_TRANSPORT_INGRESS_ENABLE_V4
			scope_l2_0tag_l3_v6_l4_udp;
			scope_l2_1tag_l3_v6_l4_udp;
#endif // VXLAN_TRANSPORT_INGRESS_ENABLE_V4
		}
		const entries = {
#if defined(GRE_TRANSPORT_INGRESS_ENABLE_V6) || defined(ERSPAN_TRANSPORT_INGRESS_ENABLE_V6) || defined(GRE_TRANSPORT_EGRESS_ENABLE_V6)
#ifdef VXLAN_TRANSPORT_INGRESS_ENABLE_V4
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
#else // #ifdef VXLAN_TRANSPORT_INGRESS_ENABLE_V4
			(true, false,     false, false           ): scope_l2_0tag_l3_none_l4_none;
			(true, true,      false, false           ): scope_l2_1tag_l3_none_l4_none;

			(true, false,     true,  false           ): scope_l2_0tag_l3_v4_l4_none;
			(true, true,      true,  false           ): scope_l2_1tag_l3_v4_l4_none;

			(true, false,     false, true            ): scope_l2_0tag_l3_v6_l4_none;
			(true, true,      false, true            ): scope_l2_1tag_l3_v6_l4_none;
#endif // VXLAN_TRANSPORT_INGRESS_ENABLE_V4
#else
#ifdef VXLAN_TRANSPORT_INGRESS_ENABLE_V4
			(true, false,     false,            false): scope_l2_0tag_l3_none_l4_none;
			(true, true,      false,            false): scope_l2_1tag_l3_none_l4_none;

			(true, false,     true,             false): scope_l2_0tag_l3_v4_l4_none;
			(true, true,      true,             false): scope_l2_1tag_l3_v4_l4_none;
			(true, false,     true,             true ): scope_l2_0tag_l3_v4_l4_udp;
			(true, true,      true,             true ): scope_l2_1tag_l3_v4_l4_udp;
#else // #ifdef VXLAN_TRANSPORT_INGRESS_ENABLE_V4
			(true, false,     false                  ): scope_l2_0tag_l3_none_l4_none;
			(true, true,      false                  ): scope_l2_1tag_l3_none_l4_none;

			(true, false,     true                   ): scope_l2_0tag_l3_v4_l4_none;
			(true, true,      true                   ): scope_l2_1tag_l3_v4_l4_none;
#endif // VXLAN_TRANSPORT_INGRESS_ENABLE_V4
#endif
		}
		const default_action = scope_l2_none_l3_none_l4_none;
	}

	apply {
		scope_l234_.apply();
		// Note: we can't use our tunnel table, because we don't know about the parser's unsupported tunnel type
/*
		lkp.tunnel_type    = lkp_in.tunnel_type;
		scope_tunnel_.apply();
*/
/*
		if(lkp_in.tunnel_type == SWITCH_TUNNEL_TYPE_NONE) {
			// for handling overload case
			scope_tunnel_none();
		} else {
			scope_tunnel_use_parser_values(lkp_in.next_lyr_valid);
		}
*/
		scope_tunnel_.apply();
	}
}


// ============================================================================

control Scoper_DataMux_Hdr1ToLkp(
		in switch_header_outer_t     hdr_1,
		in switch_header_inner_t     hdr_2,
		in    switch_lookup_fields_t lkp_in,

		inout switch_lookup_fields_t lkp
) {

	// -----------------------------
	// L2
	// -----------------------------

	action scope_l2_none() {
#ifdef INGRESS_MAU_NO_LKP_1
		lkp.l2_valid     = false;
		// do nothing...keep previous layer's values
#else
		lkp.l2_valid     = false;
		lkp.mac_src_addr = 0;
		lkp.mac_dst_addr = 0;
		lkp.mac_type     = 0;
		lkp.pcp          = 0;
#endif
	}

	action scope_l2_0tag() {
		lkp.l2_valid     = true;
		lkp.mac_src_addr = hdr_1.ethernet.src_addr;
		lkp.mac_dst_addr = hdr_1.ethernet.dst_addr;
		lkp.mac_type     = hdr_1.ethernet.ether_type;
		lkp.pcp          = 0;
	}

#ifdef ETAG_ENABLE
	action scope_l2_e_tag() {
		lkp.l2_valid     = true;
		lkp.mac_src_addr = hdr_1.ethernet.src_addr;
		lkp.mac_dst_addr = hdr_1.ethernet.dst_addr;
		lkp.mac_type     = hdr_1.e_tag.ether_type;
		//lkp.pcp          = hdr_1.e_tag.pcp;
		lkp.pcp          = 0; // do not populate w/ e-tag
	}
#endif // ETAG_ENABLE

#ifdef VNTAG_ENABLE
	action scope_l2_vn_tag() {
		lkp.l2_valid     = true;
		lkp.mac_src_addr = hdr_1.ethernet.src_addr;
		lkp.mac_dst_addr = hdr_1.ethernet.dst_addr;
		lkp.mac_type     = hdr_1.vn_tag.ether_type;
		lkp.pcp          = 0;
	}
#endif // VNTAG_ENABLE

	action scope_l2_1tag() {
		lkp.l2_valid     = true;
		lkp.mac_src_addr = hdr_1.ethernet.src_addr;
		lkp.mac_dst_addr = hdr_1.ethernet.dst_addr;
		lkp.mac_type     = hdr_1.vlan_tag[0].ether_type;
		lkp.pcp          = hdr_1.vlan_tag[0].pcp;
	}

	action scope_l2_2tags() {
		lkp.l2_valid     = true;
		lkp.mac_src_addr = hdr_1.ethernet.src_addr;
		lkp.mac_dst_addr = hdr_1.ethernet.dst_addr;
		lkp.mac_type     = hdr_1.vlan_tag[1].ether_type;
		lkp.pcp          = hdr_1.vlan_tag[0].pcp;
	}

	table scope_l2_ {
		key = {
			hdr_1.ethernet.isValid(): exact;

#ifdef ETAG_ENABLE
			hdr_1.e_tag.isValid(): exact;
#endif // ETAG_ENABLE

#ifdef VNTAG_ENABLE
			hdr_1.vn_tag.isValid(): exact;
#endif // VNTAG_ENABLE

			hdr_1.vlan_tag[0].isValid(): exact;
			hdr_1.vlan_tag[1].isValid(): exact;
		}
		actions = {
			scope_l2_none;
			scope_l2_0tag;

#ifdef ETAG_ENABLE
			scope_l2_e_tag;
#endif // ETAG_ENABLE

#ifdef VNTAG_ENABLE
			scope_l2_vn_tag;
#endif // VNTAG_ENABLE

			scope_l2_1tag;
			scope_l2_2tags;
		}
		const entries = {

#if defined(ETAG_ENABLE) && defined(VNTAG_ENABLE)

			(false, false, false, false, false): scope_l2_none();

			(true,  false, false, false, false): scope_l2_0tag();

			(true,  true,  false, false, false): scope_l2_e_tag();
			(true,  false, true,  false, false): scope_l2_vn_tag();

			(true,  false, false, true,  false): scope_l2_1tag();
			(true,  true,  false, true,  false): scope_l2_1tag();
			(true,  false, true,  true,  false): scope_l2_1tag();

			(true,  false, false, true,  true ): scope_l2_2tags();
			(true,  true,  false, true,  true ): scope_l2_2tags();
			(true,  false, true,  true,  true ): scope_l2_2tags();

#elif defined(ETAG_ENABLE) && !defined(VNTAG_ENABLE)

			(false, false, false, false): scope_l2_none();

			(true,  false, false, false): scope_l2_0tag();

			(true,  true,  false, false): scope_l2_e_tag();

			(true,  false, true,  false): scope_l2_1tag();
			(true,  true,  true,  false): scope_l2_1tag();

			(true,  false, true,  true ): scope_l2_2tags();
			(true,  true,  true,  true ): scope_l2_2tags();

#elif !defined(ETAG_ENABLE) && defined(VNTAG_ENABLE)

			(false, false, false, false): scope_l2_none();

			(true,  false, false, false): scope_l2_0tag();

			(true,  true,  false, false): scope_l2_vn_tag();

			(true,  false, true,  false): scope_l2_1tag();
			(true,  true,  true,  false): scope_l2_1tag();

			(true,  false, true,  true ): scope_l2_2tags();
			(true,  true,  true,  true ): scope_l2_2tags();

#else // !defined(ETAG_ENABLE) && !defined(VNTAG_ENABLE)

			(false, false, false): scope_l2_none();

			(true,  false, false): scope_l2_0tag();

			(true,  true,  false): scope_l2_1tag();

			(true,  true,  true ): scope_l2_2tags();

#endif
		}
	}

	// -----------------------------
	// L3
	// -----------------------------

	action scope_l3_none() {
		lkp.ip_type       = SWITCH_IP_TYPE_NONE;
		lkp.ip_tos        = 0;
		lkp.ip_proto      = 0;
		lkp.ip_flags      = 0;
		lkp.ip_src_addr   = 0;
		lkp.ip_dst_addr   = 0;
		lkp.ip_len        = 0; // extreme added
	}

	action scope_l3_v4() {
		lkp.ip_type       = SWITCH_IP_TYPE_IPV4;
		lkp.ip_tos        = hdr_1.ipv4.tos;
		lkp.ip_proto      = hdr_1.ipv4.protocol;
		lkp.ip_flags      = hdr_1.ipv4.flags;
		lkp.ip_src_addr   = (bit<128>) hdr_1.ipv4.src_addr;
		lkp.ip_dst_addr   = (bit<128>) hdr_1.ipv4.dst_addr;
		lkp.ip_len        = hdr_1.ipv4.total_len;
	}

	action scope_l3_v6() {
#ifdef IPV6_ENABLE
		lkp.ip_type       = SWITCH_IP_TYPE_IPV6;
		lkp.ip_tos        = hdr_1.ipv6.tos;
		lkp.ip_proto      = hdr_1.ipv6.next_hdr;
		lkp.ip_flags      = 0;
		lkp.ip_src_addr   = hdr_1.ipv6.src_addr;
		lkp.ip_dst_addr   = hdr_1.ipv6.dst_addr;
		lkp.ip_len        = hdr_1.ipv6.payload_len;
#endif // IPV6_ENABLE
	}

	table scope_l3_ {
		key = {
			hdr_1.ipv4.isValid(): exact;
#ifdef IPV6_ENABLE
			hdr_1.ipv6.isValid(): exact;
#endif // IPV6_ENABLE
		}
		actions = {
			scope_l3_none;
			scope_l3_v4;
			scope_l3_v6;
		}
		const entries = {
#ifdef IPV6_ENABLE
			(false, false): scope_l3_none();
			(true,  false): scope_l3_v4();
			(false, true ): scope_l3_v6();
#else
			(false       ): scope_l3_none();
			(true        ): scope_l3_v4();
#endif // IPV6_ENABLE
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
		lkp.l4_src_port = hdr_1.tcp.src_port;
		lkp.l4_dst_port = hdr_1.tcp.dst_port;
		lkp.tcp_flags   = hdr_1.tcp.flags;
	}

	action scope_l4_udp() {
		lkp.l4_src_port = hdr_1.udp.src_port;
		lkp.l4_dst_port = hdr_1.udp.dst_port;
		lkp.tcp_flags   = 0;
	}

	action scope_l4_sctp() {
		lkp.l4_src_port = hdr_1.sctp.src_port;
		lkp.l4_dst_port = hdr_1.sctp.dst_port;
		lkp.tcp_flags   = 0;
	}

	table scope_l4_ {
		key = {
			hdr_1.tcp.isValid():  exact;
			hdr_1.udp.isValid():  exact;
			hdr_1.sctp.isValid(): exact;
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
	// L3 / L4
	// -----------------------------

	action scope_l3_none_l4_none() { scope_l3_none(); scope_l4_none(); }
	action scope_l3_v4_l4_none()   { scope_l3_v4();   scope_l4_none(); }
	action scope_l3_v6_l4_none()   { scope_l3_v6();   scope_l4_none(); }
	action scope_l3_v4_l4_tcp()    { scope_l3_v4();   scope_l4_tcp();  }
	action scope_l3_v6_l4_tcp()    { scope_l3_v6();   scope_l4_tcp();  }
	action scope_l3_v4_l4_udp()    { scope_l3_v4();   scope_l4_udp();  }
	action scope_l3_v6_l4_udp()    { scope_l3_v6();   scope_l4_udp();  }
	action scope_l3_v4_l4_sctp()   { scope_l3_v4();   scope_l4_sctp(); }
	action scope_l3_v6_l4_sctp()   { scope_l3_v6();   scope_l4_sctp(); }

	table scope_l34_ {
		key = {
			hdr_1.ipv4.isValid(): exact;
#ifdef IPV6_ENABLE
			hdr_1.ipv6.isValid(): exact;
#endif // IPV6_ENABLE

			hdr_1.tcp.isValid():  exact;
			hdr_1.udp.isValid():  exact;
			hdr_1.sctp.isValid(): exact;
		}
		actions = {
			scope_l3_v4_l4_tcp;
			scope_l3_v6_l4_tcp;
			scope_l3_v4_l4_udp;
			scope_l3_v6_l4_udp;
			scope_l3_v4_l4_sctp;
			scope_l3_v6_l4_sctp;
			scope_l3_v4_l4_none;
			scope_l3_v6_l4_none;
			scope_l3_none_l4_none;
		}
		const entries = {
#ifdef IPV6_ENABLE
			(false, false,     false, false, false): scope_l3_none_l4_none();

			(true,  false,     false, false, false): scope_l3_v4_l4_none();
			(false, true,      false, false, false): scope_l3_v6_l4_none();
			(true,  false,     true,  false, false): scope_l3_v4_l4_tcp();
			(false, true,      true,  false, false): scope_l3_v6_l4_tcp();
			(true,  false,     false, true,  false): scope_l3_v4_l4_udp();
			(false, true,      false, true,  false): scope_l3_v6_l4_udp();
			(true,  false,     false, false, true ): scope_l3_v4_l4_sctp();
			(false, true,      false, false, true ): scope_l3_v6_l4_sctp();
#else
			(false,            false, false, false): scope_l3_none_l4_none();

			(true,             false, false, false): scope_l3_v4_l4_none();
			(true,             true,  false, false): scope_l3_v4_l4_tcp();
			(true,             false, true,  false): scope_l3_v4_l4_udp();
			(true,             false, false, true ): scope_l3_v4_l4_sctp();
#endif
		}
	}

	// -----------------------------
	// L2 / L3 / L4
	// -----------------------------
// Derek: Not using this, because it chews up too much vliw resources in tofino....
/*
	action scope_l2_none_l3_none_l4_none()  { scope_l2_none();   scope_l3_none(); scope_l4_none(); }

	action scope_l2_0tag_l3_none_l4_none()  { scope_l2_0tag();   scope_l3_none(); scope_l4_none(); }
	action scope_l2_etag_l3_none_l4_none()  { scope_l2_e_tag();  scope_l3_none(); scope_l4_none(); }
	action scope_l2_vntag_l3_none_l4_none() { scope_l2_vn_tag(); scope_l3_none(); scope_l4_none(); }
	action scope_l2_1tag_l3_none_l4_none()  { scope_l2_1tag();   scope_l3_none(); scope_l4_none(); }
	action scope_l2_2tag_l3_none_l4_none()  { scope_l2_2tags();  scope_l3_none(); scope_l4_none(); }

	action scope_l2_0tag_l3_v4_l4_none()    { scope_l2_0tag();   scope_l3_v4();   scope_l4_none(); }
	action scope_l2_etag_l3_v4_l4_none()    { scope_l2_e_tag();  scope_l3_v4();   scope_l4_none(); }
	action scope_l2_vntag_l3_v4_l4_none()   { scope_l2_vn_tag(); scope_l3_v4();   scope_l4_none(); }
	action scope_l2_1tag_l3_v4_l4_none()    { scope_l2_1tag();   scope_l3_v4();   scope_l4_none(); }
	action scope_l2_2tag_l3_v4_l4_none()    { scope_l2_2tags();  scope_l3_v4();   scope_l4_none(); }

	action scope_l2_0tag_l3_v6_l4_none()    { scope_l2_0tag();   scope_l3_v6();   scope_l4_none(); }
	action scope_l2_etag_l3_v6_l4_none()    { scope_l2_e_tag();  scope_l3_v6();   scope_l4_none(); }
	action scope_l2_vntag_l3_v6_l4_none()   { scope_l2_vn_tag(); scope_l3_v6();   scope_l4_none(); }
	action scope_l2_1tag_l3_v6_l4_none()    { scope_l2_1tag();   scope_l3_v6();   scope_l4_none(); }
	action scope_l2_2tag_l3_v6_l4_none()    { scope_l2_2tags();  scope_l3_v6();   scope_l4_none(); }

	action scope_l2_0tag_l3_v4_l4_tcp()     { scope_l2_0tag();   scope_l3_v4();   scope_l4_tcp();  }
	action scope_l2_etag_l3_v4_l4_tcp()     { scope_l2_e_tag();  scope_l3_v4();   scope_l4_tcp();  }
	action scope_l2_vntag_l3_v4_l4_tcp()    { scope_l2_vn_tag(); scope_l3_v4();   scope_l4_tcp();  }
	action scope_l2_1tag_l3_v4_l4_tcp()     { scope_l2_1tag();   scope_l3_v4();   scope_l4_tcp();  }
	action scope_l2_2tag_l3_v4_l4_tcp()     { scope_l2_2tags();  scope_l3_v4();   scope_l4_tcp();  }

	action scope_l2_0tag_l3_v6_l4_tcp()     { scope_l2_0tag();   scope_l3_v6();   scope_l4_tcp();  }
	action scope_l2_etag_l3_v6_l4_tcp()     { scope_l2_e_tag();  scope_l3_v6();   scope_l4_tcp();  }
	action scope_l2_vntag_l3_v6_l4_tcp()    { scope_l2_vn_tag(); scope_l3_v6();   scope_l4_tcp();  }
	action scope_l2_1tag_l3_v6_l4_tcp()     { scope_l2_1tag();   scope_l3_v6();   scope_l4_tcp();  }
	action scope_l2_2tag_l3_v6_l4_tcp()     { scope_l2_2tags();  scope_l3_v6();   scope_l4_tcp();  }

	action scope_l2_0tag_l3_v4_l4_udp()     { scope_l2_0tag();   scope_l3_v4();   scope_l4_udp();  }
	action scope_l2_etag_l3_v4_l4_udp()     { scope_l2_e_tag();  scope_l3_v4();   scope_l4_udp();  }
	action scope_l2_vntag_l3_v4_l4_udp()    { scope_l2_vn_tag(); scope_l3_v4();   scope_l4_udp();  }
	action scope_l2_1tag_l3_v4_l4_udp()     { scope_l2_1tag();   scope_l3_v4();   scope_l4_udp();  }
	action scope_l2_2tag_l3_v4_l4_udp()     { scope_l2_2tags();  scope_l3_v4();   scope_l4_udp();  }

	action scope_l2_0tag_l3_v6_l4_udp()     { scope_l2_0tag();   scope_l3_v6();   scope_l4_udp();  }
	action scope_l2_etag_l3_v6_l4_udp()     { scope_l2_e_tag();  scope_l3_v6();   scope_l4_udp();  }
	action scope_l2_vntag_l3_v6_l4_udp()    { scope_l2_vn_tag(); scope_l3_v6();   scope_l4_udp();  }
	action scope_l2_1tag_l3_v6_l4_udp()     { scope_l2_1tag();   scope_l3_v6();   scope_l4_udp();  }
	action scope_l2_2tag_l3_v6_l4_udp()     { scope_l2_2tags();  scope_l3_v6();   scope_l4_udp();  }

	action scope_l2_0tag_l3_v4_l4_sctp()    { scope_l2_0tag();   scope_l3_v4();   scope_l4_sctp(); }
	action scope_l2_etag_l3_v4_l4_sctp()    { scope_l2_e_tag();  scope_l3_v4();   scope_l4_sctp(); }
	action scope_l2_vntag_l3_v4_l4_sctp()   { scope_l2_vn_tag(); scope_l3_v4();   scope_l4_sctp(); }
	action scope_l2_1tag_l3_v4_l4_sctp()    { scope_l2_1tag();   scope_l3_v4();   scope_l4_sctp(); }
	action scope_l2_2tag_l3_v4_l4_sctp()    { scope_l2_2tags();  scope_l3_v4();   scope_l4_sctp(); }

	action scope_l2_0tag_l3_v6_l4_sctp()    { scope_l2_0tag();   scope_l3_v6();   scope_l4_sctp(); }
	action scope_l2_etag_l3_v6_l4_sctp()    { scope_l2_e_tag();  scope_l3_v6();   scope_l4_sctp(); }
	action scope_l2_vntag_l3_v6_l4_sctp()   { scope_l2_vn_tag(); scope_l3_v6();   scope_l4_sctp(); }
	action scope_l2_1tag_l3_v6_l4_sctp()    { scope_l2_1tag();   scope_l3_v6();   scope_l4_sctp(); }
	action scope_l2_2tag_l3_v6_l4_sctp()    { scope_l2_2tags();  scope_l3_v6();   scope_l4_sctp(); }

	table scope_l234_ {
		key = {
			hdr_1.ethernet.isValid(): exact;
			hdr_1.e_tag.isValid(): exact;
			hdr_1.vn_tag.isValid(): exact;
			hdr_1.vlan_tag[0].isValid(): exact;
			hdr_1.vlan_tag[1].isValid(): exact;

			hdr_1.ipv4.isValid(): exact;
#ifdef IPV6_ENABLE
			hdr_1.ipv6.isValid(): exact;
#endif // IPV6_ENABLE

			hdr_1.tcp.isValid():  exact;
			hdr_1.udp.isValid():  exact;
			hdr_1.sctp.isValid(): exact;
		}
		actions = {
			scope_l2_0tag_l3_v4_l4_tcp;
			scope_l2_etag_l3_v4_l4_tcp;
			scope_l2_vntag_l3_v4_l4_tcp;
			scope_l2_1tag_l3_v4_l4_tcp;
			scope_l2_2tag_l3_v4_l4_tcp;

			scope_l2_0tag_l3_v6_l4_tcp;
			scope_l2_etag_l3_v6_l4_tcp;
			scope_l2_vntag_l3_v6_l4_tcp;
			scope_l2_1tag_l3_v6_l4_tcp;
			scope_l2_2tag_l3_v6_l4_tcp;

			scope_l2_0tag_l3_v4_l4_udp;
			scope_l2_etag_l3_v4_l4_udp;
			scope_l2_vntag_l3_v4_l4_udp;
			scope_l2_1tag_l3_v4_l4_udp;
			scope_l2_2tag_l3_v4_l4_udp;

			scope_l2_0tag_l3_v6_l4_udp;
			scope_l2_etag_l3_v6_l4_udp;
			scope_l2_vntag_l3_v6_l4_udp;
			scope_l2_1tag_l3_v6_l4_udp;
			scope_l2_2tag_l3_v6_l4_udp;

			scope_l2_0tag_l3_v4_l4_sctp;
			scope_l2_etag_l3_v4_l4_sctp;
			scope_l2_vntag_l3_v4_l4_sctp;
			scope_l2_1tag_l3_v4_l4_sctp;
			scope_l2_2tag_l3_v4_l4_sctp;

			scope_l2_0tag_l3_v6_l4_sctp;
			scope_l2_etag_l3_v6_l4_sctp;
			scope_l2_vntag_l3_v6_l4_sctp;
			scope_l2_1tag_l3_v6_l4_sctp;
			scope_l2_2tag_l3_v6_l4_sctp;

			scope_l2_0tag_l3_v4_l4_none;
			scope_l2_etag_l3_v4_l4_none;
			scope_l2_vntag_l3_v4_l4_none;
			scope_l2_1tag_l3_v4_l4_none;
			scope_l2_2tag_l3_v4_l4_none;

			scope_l2_0tag_l3_v6_l4_none;
			scope_l2_etag_l3_v6_l4_none;
			scope_l2_vntag_l3_v6_l4_none;
			scope_l2_1tag_l3_v6_l4_none;
			scope_l2_2tag_l3_v6_l4_none;

			scope_l2_0tag_l3_none_l4_none;
			scope_l2_etag_l3_none_l4_none;
			scope_l2_vntag_l3_none_l4_none;
			scope_l2_1tag_l3_none_l4_none;
			scope_l2_2tag_l3_none_l4_none;

			scope_l2_none_l3_none_l4_none;
		}
		const entries = {
			(false, false, false, false, false,     false, false,     false, false, false): scope_l2_none_l3_none_l4_none();

			(true,  false, false, false, false,     false, false,     false, false, false): scope_l2_0tag_l3_none_l4_none();
			(true,  true,  false, false, false,     false, false,     false, false, false): scope_l2_etag_l3_none_l4_none();
			(true,  false, true,  false, false,     false, false,     false, false, false): scope_l2_vntag_l3_none_l4_none();
			(true,  false, false, true,  false,     false, false,     false, false, false): scope_l2_1tag_l3_none_l4_none();
			(true,  true,  false, true,  false,     false, false,     false, false, false): scope_l2_1tag_l3_none_l4_none();
			(true,  false, true,  true,  false,     false, false,     false, false, false): scope_l2_1tag_l3_none_l4_none();
			(true,  false, false, true,  true,      false, false,     false, false, false): scope_l2_2tag_l3_none_l4_none();
			(true,  true,  false, true,  true,      false, false,     false, false, false): scope_l2_2tag_l3_none_l4_none();
			(true,  false, true,  true,  true,      false, false,     false, false, false): scope_l2_2tag_l3_none_l4_none();

			(true,  false, false, false, false,     true,  false,     false, false, false): scope_l2_0tag_l3_v4_l4_none();
			(true,  true,  false, false, false,     true,  false,     false, false, false): scope_l2_etag_l3_v4_l4_none();
			(true,  false, true,  false, false,     true,  false,     false, false, false): scope_l2_vntag_l3_v4_l4_none();
			(true,  false, false, true,  false,     true,  false,     false, false, false): scope_l2_1tag_l3_v4_l4_none();
			(true,  true,  false, true,  false,     true,  false,     false, false, false): scope_l2_1tag_l3_v4_l4_none();
			(true,  false, true,  true,  false,     true,  false,     false, false, false): scope_l2_1tag_l3_v4_l4_none();
			(true,  false, false, true,  true,      true,  false,     false, false, false): scope_l2_2tag_l3_v4_l4_none();
			(true,  true,  false, true,  true,      true,  false,     false, false, false): scope_l2_2tag_l3_v4_l4_none();
			(true,  false, true,  true,  true,      true,  false,     false, false, false): scope_l2_2tag_l3_v4_l4_none();

			(true,  false, false, false, false,     false, true,      false, false, false): scope_l2_0tag_l3_v6_l4_none();
			(true,  true,  false, false, false,     false, true,      false, false, false): scope_l2_etag_l3_v6_l4_none();
			(true,  false, true,  false, false,     false, true,      false, false, false): scope_l2_vntag_l3_v6_l4_none();
			(true,  false, false, true,  false,     false, true,      false, false, false): scope_l2_1tag_l3_v6_l4_none();
			(true,  true,  false, true,  false,     false, true,      false, false, false): scope_l2_1tag_l3_v6_l4_none();
			(true,  false, true,  true,  false,     false, true,      false, false, false): scope_l2_1tag_l3_v6_l4_none();
			(true,  false, false, true,  true,      false, true,      false, false, false): scope_l2_2tag_l3_v6_l4_none();
			(true,  true,  false, true,  true,      false, true,      false, false, false): scope_l2_2tag_l3_v6_l4_none();
			(true,  false, true,  true,  true,      false, true,      false, false, false): scope_l2_2tag_l3_v6_l4_none();

			(true,  false, false, false, false,     true,  false,     true,  false, false): scope_l2_0tag_l3_v4_l4_tcp();
			(true,  true,  false, false, false,     true,  false,     true,  false, false): scope_l2_etag_l3_v4_l4_tcp();
			(true,  false, true,  false, false,     true,  false,     true,  false, false): scope_l2_vntag_l3_v4_l4_tcp();
			(true,  false, false, true,  false,     true,  false,     true,  false, false): scope_l2_1tag_l3_v4_l4_tcp();
			(true,  true,  false, true,  false,     true,  false,     true,  false, false): scope_l2_1tag_l3_v4_l4_tcp();
			(true,  false, true,  true,  false,     true,  false,     true,  false, false): scope_l2_1tag_l3_v4_l4_tcp();
			(true,  false, false, true,  true,      true,  false,     true,  false, false): scope_l2_2tag_l3_v4_l4_tcp();
			(true,  true,  false, true,  true,      true,  false,     true,  false, false): scope_l2_2tag_l3_v4_l4_tcp();
			(true,  false, true,  true,  true,      true,  false,     true,  false, false): scope_l2_2tag_l3_v4_l4_tcp();

			(true,  false, false, false, false,     false, true,      true,  false, false): scope_l2_0tag_l3_v6_l4_tcp();
			(true,  true,  false, false, false,     false, true,      true,  false, false): scope_l2_etag_l3_v6_l4_tcp();
			(true,  false, true,  false, false,     false, true,      true,  false, false): scope_l2_vntag_l3_v6_l4_tcp();
			(true,  false, false, true,  false,     false, true,      true,  false, false): scope_l2_1tag_l3_v6_l4_tcp();
			(true,  true,  false, true,  false,     false, true,      true,  false, false): scope_l2_1tag_l3_v6_l4_tcp();
			(true,  false, true,  true,  false,     false, true,      true,  false, false): scope_l2_1tag_l3_v6_l4_tcp();
			(true,  false, false, true,  true,      false, true,      true,  false, false): scope_l2_2tag_l3_v6_l4_tcp();
			(true,  true,  false, true,  true,      false, true,      true,  false, false): scope_l2_2tag_l3_v6_l4_tcp();
			(true,  false, true,  true,  true,      false, true,      true,  false, false): scope_l2_2tag_l3_v6_l4_tcp();

			(true,  false, false, false, false,     true,  false,     false, true,  false): scope_l2_0tag_l3_v4_l4_udp();
			(true,  true,  false, false, false,     true,  false,     false, true,  false): scope_l2_etag_l3_v4_l4_udp();
			(true,  false, true,  false, false,     true,  false,     false, true,  false): scope_l2_vntag_l3_v4_l4_udp();
			(true,  false, false, true,  false,     true,  false,     false, true,  false): scope_l2_1tag_l3_v4_l4_udp();
			(true,  true,  false, true,  false,     true,  false,     false, true,  false): scope_l2_1tag_l3_v4_l4_udp();
			(true,  false, true,  true,  false,     true,  false,     false, true,  false): scope_l2_1tag_l3_v4_l4_udp();
			(true,  false, false, true,  true,      true,  false,     false, true,  false): scope_l2_2tag_l3_v4_l4_udp();
			(true,  true,  false, true,  true,      true,  false,     false, true,  false): scope_l2_2tag_l3_v4_l4_udp();
			(true,  false, true,  true,  true,      true,  false,     false, true,  false): scope_l2_2tag_l3_v4_l4_udp();

			(true,  false, false, false, false,     false, true,      false, true,  false): scope_l2_0tag_l3_v6_l4_udp();
			(true,  true,  false, false, false,     false, true,      false, true,  false): scope_l2_etag_l3_v6_l4_udp();
			(true,  false, true,  false, false,     false, true,      false, true,  false): scope_l2_vntag_l3_v6_l4_udp();
			(true,  false, false, true,  false,     false, true,      false, true,  false): scope_l2_1tag_l3_v6_l4_udp();
			(true,  true,  false, true,  false,     false, true,      false, true,  false): scope_l2_1tag_l3_v6_l4_udp();
			(true,  false, true,  true,  false,     false, true,      false, true,  false): scope_l2_1tag_l3_v6_l4_udp();
			(true,  false, false, true,  true,      false, true,      false, true,  false): scope_l2_2tag_l3_v6_l4_udp();
			(true,  true,  false, true,  true,      false, true,      false, true,  false): scope_l2_2tag_l3_v6_l4_udp();
			(true,  false, true,  true,  true,      false, true,      false, true,  false): scope_l2_2tag_l3_v6_l4_udp();

			(true,  false, false, false, false,     true,  false,     false, false, true ): scope_l2_0tag_l3_v4_l4_sctp();
			(true,  true,  false, false, false,     true,  false,     false, false, true ): scope_l2_etag_l3_v4_l4_sctp();
			(true,  false, true,  false, false,     true,  false,     false, false, true ): scope_l2_vntag_l3_v4_l4_sctp();
			(true,  false, false, true,  false,     true,  false,     false, false, true ): scope_l2_1tag_l3_v4_l4_sctp();
			(true,  true,  false, true,  false,     true,  false,     false, false, true ): scope_l2_1tag_l3_v4_l4_sctp();
			(true,  false, true,  true,  false,     true,  false,     false, false, true ): scope_l2_1tag_l3_v4_l4_sctp();
			(true,  false, false, true,  true,      true,  false,     false, false, true ): scope_l2_2tag_l3_v4_l4_sctp();
			(true,  true,  false, true,  true,      true,  false,     false, false, true ): scope_l2_2tag_l3_v4_l4_sctp();
			(true,  false, true,  true,  true,      true,  false,     false, false, true ): scope_l2_2tag_l3_v4_l4_sctp();

			(true,  false, false, false, false,     false, true,      false, false, true ): scope_l2_0tag_l3_v6_l4_sctp();
			(true,  true,  false, false, false,     false, true,      false, false, true ): scope_l2_etag_l3_v6_l4_sctp();
			(true,  false, true,  false, false,     false, true,      false, false, true ): scope_l2_vntag_l3_v6_l4_sctp();
			(true,  false, false, true,  false,     false, true,      false, false, true ): scope_l2_1tag_l3_v6_l4_sctp();
			(true,  true,  false, true,  false,     false, true,      false, false, true ): scope_l2_1tag_l3_v6_l4_sctp();
			(true,  false, true,  true,  false,     false, true,      false, false, true ): scope_l2_1tag_l3_v6_l4_sctp();
			(true,  false, false, true,  true,      false, true,      false, false, true ): scope_l2_2tag_l3_v6_l4_sctp();
			(true,  true,  false, true,  true,      false, true,      false, false, true ): scope_l2_2tag_l3_v6_l4_sctp();
			(true,  false, true,  true,  true,      false, true,      false, false, true ): scope_l2_2tag_l3_v6_l4_sctp();
		}
	}
*/
	// -----------------------------
	// TUNNEL
	// -----------------------------

	action scope_tunnel_none() {
/*
		lkp.tunnel_type    = SWITCH_TUNNEL_TYPE_NONE;
		lkp.tunnel_id      = 0;
		lkp.next_lyr_valid = false;
*/
#ifdef INGRESS_MAU_NO_LKP_1
  #ifdef INGRESS_PARSER_INNER_TUNNEL_INFO_OVERLOAD
		// do nothing...keep previous layer's values
		lkp.next_lyr_valid = false;
  #else
		lkp.tunnel_type    = SWITCH_TUNNEL_TYPE_NONE;
		lkp.tunnel_id      = 0;
		lkp.next_lyr_valid = false;
  #endif
#else
		lkp.tunnel_type    = SWITCH_TUNNEL_TYPE_NONE;
		lkp.tunnel_id      = 0;
		lkp.next_lyr_valid = false;
#endif
	}

	action scope_tunnel_gre() {
		lkp.tunnel_type    = SWITCH_TUNNEL_TYPE_GRE;
		lkp.tunnel_id      = 0;
		lkp.next_lyr_valid = true;
	}

























	action scope_tunnel_unsupported() {
		lkp.tunnel_type    = SWITCH_TUNNEL_TYPE_UNSUPPORTED;
		lkp.tunnel_id      = 0;
		lkp.next_lyr_valid = false; // unsupported has no next layer
	}

	action scope_tunnel_use_parser_values(bool lkp_in_next_lyr_valid) {
		lkp.tunnel_type    = lkp_in.tunnel_type;
		lkp.tunnel_id      = lkp_in.tunnel_id;
		lkp.next_lyr_valid = lkp_in_next_lyr_valid;
	}
/*
	table scope_tunnel_ {
		key = {
			hdr_1.gre.isValid():  exact;
		}
		actions = {
			scope_tunnel_gre;
			scope_tunnel_none;
			scope_tunnel_unsupported;
		}
		const entries = {
			(true ): scope_tunnel_gre();
			(false): scope_tunnel_none();
		}
		const default_action = scope_tunnel_none;
	}
*/
	table scope_tunnel_ {
		key = {
			lkp_in.tunnel_type: exact;
		}
		actions = {
			scope_tunnel_none;
			scope_tunnel_use_parser_values;
		}
		const entries = {
			(SWITCH_TUNNEL_TYPE_GTPC):        scope_tunnel_use_parser_values(false);
			(SWITCH_TUNNEL_TYPE_NONE):        scope_tunnel_none();
			(SWITCH_TUNNEL_TYPE_UNSUPPORTED): scope_tunnel_use_parser_values(false);
//			(SWITCH_TUNNEL_TYPE_VXLAN):       scope_tunnel_use_parser_values(true); // filler entries to get rid of compiler bug when less than 4 constant entries
//			(SWITCH_TUNNEL_TYPE_IPINIP):      scope_tunnel_use_parser_values(true); // filler entries to get rid of compiler bug when less than 4 constant entries
		}
		const default_action = scope_tunnel_use_parser_values(true);
	}

	// -----------------------------
	// Apply
	// -----------------------------

	apply {
		scope_l2_.apply();
//		scope_l3_.apply();
//		scope_l4_.apply();
		scope_l34_.apply();
//		scope_l234_.apply();
		// Note: we can't use our tunnel table, because we don't know about the parser's unsupported tunnel type
/*
		lkp.tunnel_type    = lkp_in.tunnel_type;
		scope_tunnel_.apply();
*/
/*
		if(lkp_in.tunnel_type == SWITCH_TUNNEL_TYPE_NONE) {
			// for handling overload case
			scope_tunnel_none();
		} else {
			scope_tunnel_use_parser_values(lkp_in.next_lyr_valid);
		}
*/
		scope_tunnel_.apply();
	}
}

// ============================================================================

control Scoper_DataMux_Hdr2ToLkp(
		in switch_header_inner_t       hdr_2,
		in switch_header_inner_inner_t hdr_3,
		in switch_lookup_fields_t      lkp_in,

		inout switch_lookup_fields_t   lkp
) {

	// -----------------------------
	// L2
	// -----------------------------

	action scope_l2_none() {
#ifdef INGRESS_MAU_NO_LKP_2
		lkp.l2_valid     = false;
		// do nothing...keep previous layer's values
#else
		lkp.l2_valid     = false;
		lkp.mac_src_addr = 0;
		lkp.mac_dst_addr = 0;
		lkp.mac_type     = 0;
		lkp.pcp          = 0;
		lkp.pad          = 0;
		lkp.vid          = 0;
#endif
	}

	action scope_l2_none_v4() {
#ifdef INGRESS_MAU_NO_LKP_2
		lkp.l2_valid     = false;
		// do nothing...keep previous layer's values
		lkp.mac_type     = ETHERTYPE_IPV4;
#else
		lkp.l2_valid     = false;
		lkp.mac_src_addr = 0;
		lkp.mac_dst_addr = 0;
		lkp.mac_type     = 0;
		lkp.pcp          = 0;
		lkp.pad          = 0;
		lkp.vid          = 0;
#endif
	}

	action scope_l2_none_v6() {
#ifdef INGRESS_MAU_NO_LKP_2
		lkp.l2_valid     = false;
		// do nothing...keep previous layer's values
		lkp.mac_type     = ETHERTYPE_IPV6;
#else
		lkp.l2_valid     = false;
		lkp.mac_src_addr = 0;
		lkp.mac_dst_addr = 0;
		lkp.mac_type     = 0;
		lkp.pcp          = 0;
		lkp.pad          = 0;
		lkp.vid          = 0;
#endif
	}

	action scope_l2_0tag() {
		lkp.l2_valid     = true;
		lkp.mac_src_addr = hdr_2.ethernet.src_addr;
		lkp.mac_dst_addr = hdr_2.ethernet.dst_addr;
		lkp.mac_type     = hdr_2.ethernet.ether_type;
		lkp.pcp          = 0;
		lkp.pad          = 0;
		lkp.vid          = 0;
	}

	action scope_l2_1tag() {
		lkp.l2_valid     = true;
		lkp.mac_src_addr = hdr_2.ethernet.src_addr;
		lkp.mac_dst_addr = hdr_2.ethernet.dst_addr;
		lkp.mac_type     = hdr_2.vlan_tag[0].ether_type;
		lkp.pcp          = hdr_2.vlan_tag[0].pcp;
		lkp.pad          = 0;
		lkp.vid          = hdr_2.vlan_tag[0].vid;
	}

	table scope_l2_ {
		key = {
			hdr_2.ethernet.isValid(): exact;
			hdr_2.vlan_tag[0].isValid(): exact;
		}
		actions = {
			scope_l2_none;
			scope_l2_0tag;
			scope_l2_1tag;
		}
		const entries = {
			(false, false): scope_l2_none();

			(true,  false): scope_l2_0tag();

			(true,  true ): scope_l2_1tag();
		}
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
		lkp.ip_type       = SWITCH_IP_TYPE_IPV4;
		lkp.ip_proto      = hdr_2.ipv4.protocol;
		lkp.ip_tos        = hdr_2.ipv4.tos;
		lkp.ip_flags      = hdr_2.ipv4.flags;
		lkp.ip_src_addr_v4= hdr_2.ipv4.src_addr;
		lkp.ip_dst_addr_v4= hdr_2.ipv4.dst_addr;
		lkp.ip_len        = hdr_2.ipv4.total_len;
	}

	action scope_l3_v6() {
#ifdef IPV6_ENABLE
		lkp.ip_type       = SWITCH_IP_TYPE_IPV6;
		lkp.ip_proto      = hdr_2.ipv6.next_hdr;
		lkp.ip_tos        = hdr_2.ipv6.tos;
		lkp.ip_flags      = 0;
		lkp.ip_src_addr   = hdr_2.ipv6.src_addr;
		lkp.ip_dst_addr   = hdr_2.ipv6.dst_addr;
		lkp.ip_len        = hdr_2.ipv6.payload_len;
#endif // IPV6_ENABLE
	}

	table scope_l3_ {
		key = {
			hdr_2.ipv4.isValid(): exact;
#ifdef IPV6_ENABLE
			hdr_2.ipv6.isValid(): exact;
#endif // IPV6_ENABLE
		}
		actions = {
			scope_l3_none;
			scope_l3_v4;
			scope_l3_v6;
		}
		const entries = {
#ifdef IPV6_ENABLE
			(false, false): scope_l3_none();
			(true,  false): scope_l3_v4();
			(false, true ): scope_l3_v6();
#else
			(false       ): scope_l3_none();
			(true        ): scope_l3_v4();
#endif // IPV6_ENABLE
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
		lkp.l4_src_port = hdr_2.tcp.src_port;
		lkp.l4_dst_port = hdr_2.tcp.dst_port;
		lkp.tcp_flags   = hdr_2.tcp.flags;
	}

	action scope_l4_udp() {
		lkp.l4_src_port = hdr_2.udp.src_port;
		lkp.l4_dst_port = hdr_2.udp.dst_port;
		lkp.tcp_flags   = 0;
	}

	action scope_l4_sctp() {
		lkp.l4_src_port = hdr_2.sctp.src_port;
		lkp.l4_dst_port = hdr_2.sctp.dst_port;
		lkp.tcp_flags   = 0;
	}

	table scope_l4_ {
		key = {
			hdr_2.tcp.isValid():  exact;
			hdr_2.udp.isValid():  exact;
			hdr_2.sctp.isValid(): exact;
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

	// scenario 1: we're the only  step (no_lkp2     defined)
	//  - overload     defined: keep (do nothing)
	//  - overload not defined: replace
	// secnario 2: we're the first step (no_lkp2 not defined)
	//  - overload     defined: replace (scoper handles)
	//  - overload not defined: replace (scoper handles)

#ifdef INGRESS_MAU_NO_LKP_2
  #ifdef INGRESS_PARSER_INNER_TUNNEL_INFO_OVERLOAD
		// do nothing...keep previous layer's values
		lkp.next_lyr_valid = false;
  #else
		lkp.tunnel_type    = SWITCH_TUNNEL_TYPE_NONE;
		lkp.tunnel_id      = 0;
		lkp.next_lyr_valid = false;
  #endif
#else
		lkp.tunnel_type    = SWITCH_TUNNEL_TYPE_NONE;
		lkp.tunnel_id      = 0;
		lkp.next_lyr_valid = false;
#endif
	}

	action scope_tunnel_ipinip() {
		lkp.tunnel_type    = SWITCH_TUNNEL_TYPE_IPINIP;
		lkp.tunnel_id      = 0;
		lkp.next_lyr_valid = true;
	}

	action scope_tunnel_gre() {
		lkp.tunnel_type    = SWITCH_TUNNEL_TYPE_GRE;
		lkp.tunnel_id      = 0;
		lkp.next_lyr_valid = true;
	}

	action scope_tunnel_gtpu() {
		lkp.tunnel_type    = SWITCH_TUNNEL_TYPE_GTPU;
		lkp.tunnel_id      = hdr_2.gtp_v1_base.teid;
		lkp.next_lyr_valid = true;
	}

	action scope_tunnel_gtpc() {
		lkp.tunnel_type    = SWITCH_TUNNEL_TYPE_GTPC;
		lkp.tunnel_id      = hdr_2.gtp_v2_base.teid;
		lkp.next_lyr_valid = false; // gtp-c has no next layer
	}

	action scope_tunnel_unsupported() {
		lkp.tunnel_type    = SWITCH_TUNNEL_TYPE_UNSUPPORTED;
		lkp.tunnel_id      = 0;
		lkp.next_lyr_valid = false; // unsupported has no next layer
	}

	action scope_tunnel_use_parser_values(bool lkp_in_next_lyr_valid) {
		lkp.tunnel_type    = lkp_in.tunnel_type;
		lkp.tunnel_id      = lkp_in.tunnel_id;
		lkp.next_lyr_valid = lkp_in_next_lyr_valid;
	}
/*
	table scope_tunnel_ {
		key = {
			hdr_2.gre.isValid():  exact;
			hdr_2.gtp_v1_base.isValid():  exact;
			hdr_2.gtp_v2_base.isValid():  exact;

			hdr_3.ipv4.isValid(): exact;
			hdr_3.ipv6.isValid(): exact;
		}
		actions = {
			scope_tunnel_ipinip;
			scope_tunnel_gre;
			scope_tunnel_gtpu;
			scope_tunnel_gtpc;
			scope_tunnel_none;
		}
		const entries = {
			// hdr2               hdr3
			// ------------------ ------------
			(true,  false, false, false, false): scope_tunnel_gre(); // hdr3 is a don't care
			(true,  false, false, true,  false): scope_tunnel_gre(); // hdr3 is a don't care
			(true,  false, false, false, true ): scope_tunnel_gre(); // hdr3 is a don't care

			(false, true,  false, false, false): scope_tunnel_gtpu(); // hdr3 is a don't care
			(false, true,  false, true,  false): scope_tunnel_gtpu(); // hdr3 is a don't care
			(false, true,  false, false, true ): scope_tunnel_gtpu(); // hdr3 is a don't care

			(false, false, true,  false, false): scope_tunnel_gtpc(); // hdr3 is a don't care
			(false, false, true,  true,  false): scope_tunnel_gtpc(); // hdr3 is a don't care
			(false, false, true,  false, true ): scope_tunnel_gtpc(); // hdr3 is a don't care

			(false, false, false, true,  false): scope_tunnel_ipinip(); // no tunnels valid, but next layer is...so must be ip-in-ip
			(false, false, false, false, true ): scope_tunnel_ipinip(); // no tunnels valid, but next layer is...so must be ip-in-ip
		}
		const default_action = scope_tunnel_none;
	}
*/
	table scope_tunnel_ {
		key = {
			lkp_in.tunnel_type: exact;
		}
		actions = {
			scope_tunnel_none;
			scope_tunnel_use_parser_values;
		}
		const entries = {
			(SWITCH_TUNNEL_TYPE_GTPC):        scope_tunnel_use_parser_values(false);
			(SWITCH_TUNNEL_TYPE_NONE):        scope_tunnel_none();
			(SWITCH_TUNNEL_TYPE_UNSUPPORTED): scope_tunnel_use_parser_values(false);
//			(SWITCH_TUNNEL_TYPE_VXLAN):       scope_tunnel_use_parser_values(true); // filler entries to get rid of compiler bug when less than 4 constant entries
//			(SWITCH_TUNNEL_TYPE_IPINIP):      scope_tunnel_use_parser_values(true); // filler entries to get rid of compiler bug when less than 4 constant entries
		}
		const default_action = scope_tunnel_use_parser_values(true);
	}

	// -----------------------------
	// L2 / L3 / L4
	// -----------------------------

	action scope_l2_none_l3_none_l4_none() { scope_l2_none_v4(); scope_l3_none(); scope_l4_none(); }
	// l2 only
	action scope_l2_0tag_l3_none_l4_none() { scope_l2_0tag();    scope_l3_none(); scope_l4_none(); }
	action scope_l2_1tag_l3_none_l4_none() { scope_l2_1tag();    scope_l3_none(); scope_l4_none(); }
	// l2, l3, l4
	action scope_l2_0tag_l3_v4_l4_none()   { scope_l2_0tag();    scope_l3_v4();   scope_l4_none(); }
	action scope_l2_1tag_l3_v4_l4_none()   { scope_l2_1tag();    scope_l3_v4();   scope_l4_none(); }
	action scope_l2_0tag_l3_v6_l4_none()   { scope_l2_0tag();    scope_l3_v6();   scope_l4_none(); }
	action scope_l2_1tag_l3_v6_l4_none()   { scope_l2_1tag();    scope_l3_v6();   scope_l4_none(); }
	action scope_l2_0tag_l3_v4_l4_tcp()    { scope_l2_0tag();    scope_l3_v4();   scope_l4_tcp();  }
	action scope_l2_1tag_l3_v4_l4_tcp()    { scope_l2_1tag();    scope_l3_v4();   scope_l4_tcp();  }
	action scope_l2_0tag_l3_v6_l4_tcp()    { scope_l2_0tag();    scope_l3_v6();   scope_l4_tcp();  }
	action scope_l2_1tag_l3_v6_l4_tcp()    { scope_l2_1tag();    scope_l3_v6();   scope_l4_tcp();  }
	action scope_l2_0tag_l3_v4_l4_udp()    { scope_l2_0tag();    scope_l3_v4();   scope_l4_udp();  }
	action scope_l2_1tag_l3_v4_l4_udp()    { scope_l2_1tag();    scope_l3_v4();   scope_l4_udp();  }
	action scope_l2_0tag_l3_v6_l4_udp()    { scope_l2_0tag();    scope_l3_v6();   scope_l4_udp();  }
	action scope_l2_1tag_l3_v6_l4_udp()    { scope_l2_1tag();    scope_l3_v6();   scope_l4_udp();  }
	action scope_l2_0tag_l3_v4_l4_sctp()   { scope_l2_0tag();    scope_l3_v4();   scope_l4_sctp(); }
	action scope_l2_1tag_l3_v4_l4_sctp()   { scope_l2_1tag();    scope_l3_v4();   scope_l4_sctp(); }
	action scope_l2_0tag_l3_v6_l4_sctp()   { scope_l2_0tag();    scope_l3_v6();   scope_l4_sctp(); }
	action scope_l2_1tag_l3_v6_l4_sctp()   { scope_l2_1tag();    scope_l3_v6();   scope_l4_sctp(); }
	// l3, l4 only (no l2)
	action scope_l2_none_l3_v4_l4_none()   { scope_l2_none_v4(); scope_l3_v4();   scope_l4_none(); }
	action scope_l2_none_l3_v6_l4_none()   { scope_l2_none_v6(); scope_l3_v6();   scope_l4_none(); }
	action scope_l2_none_l3_v4_l4_tcp()    { scope_l2_none_v4(); scope_l3_v4();   scope_l4_tcp();  }
	action scope_l2_none_l3_v6_l4_tcp()    { scope_l2_none_v6(); scope_l3_v6();   scope_l4_tcp();  }
	action scope_l2_none_l3_v4_l4_udp()    { scope_l2_none_v4(); scope_l3_v4();   scope_l4_udp();  }
	action scope_l2_none_l3_v6_l4_udp()    { scope_l2_none_v6(); scope_l3_v6();   scope_l4_udp();  }
	action scope_l2_none_l3_v4_l4_sctp()   { scope_l2_none_v4(); scope_l3_v4();   scope_l4_sctp(); }
	action scope_l2_none_l3_v6_l4_sctp()   { scope_l2_none_v6(); scope_l3_v6();   scope_l4_sctp(); }

	table scope_l234_ {
		key = {
			hdr_2.ethernet.isValid(): exact;
			hdr_2.vlan_tag[0].isValid(): exact;

			hdr_2.ipv4.isValid(): exact;
#ifdef IPV6_ENABLE
			hdr_2.ipv6.isValid(): exact;
#endif // IPV6_ENABLE

			hdr_2.tcp.isValid():  exact;
			hdr_2.udp.isValid():  exact;
			hdr_2.sctp.isValid(): exact;
		}
		actions = {
			scope_l2_none_l3_none_l4_none;
			// l2 only
			scope_l2_0tag_l3_none_l4_none;
			scope_l2_1tag_l3_none_l4_none;
			// l2, l3, l4
			scope_l2_0tag_l3_v4_l4_tcp;
			scope_l2_1tag_l3_v4_l4_tcp;
			scope_l2_0tag_l3_v6_l4_tcp;
			scope_l2_1tag_l3_v6_l4_tcp;
			scope_l2_0tag_l3_v4_l4_udp;
			scope_l2_1tag_l3_v4_l4_udp;
			scope_l2_0tag_l3_v6_l4_udp;
			scope_l2_1tag_l3_v6_l4_udp;
			scope_l2_0tag_l3_v4_l4_sctp;
			scope_l2_1tag_l3_v4_l4_sctp;
			scope_l2_0tag_l3_v6_l4_sctp;
			scope_l2_1tag_l3_v6_l4_sctp;
			scope_l2_0tag_l3_v4_l4_none;
			scope_l2_1tag_l3_v4_l4_none;
			scope_l2_0tag_l3_v6_l4_none;
			scope_l2_1tag_l3_v6_l4_none;
			// l3, l4 only (no l2)
			scope_l2_none_l3_v4_l4_tcp;
			scope_l2_none_l3_v6_l4_tcp;
			scope_l2_none_l3_v4_l4_udp;
			scope_l2_none_l3_v6_l4_udp;
			scope_l2_none_l3_v4_l4_sctp;
			scope_l2_none_l3_v6_l4_sctp;
			scope_l2_none_l3_v4_l4_none;
			scope_l2_none_l3_v6_l4_none;
		}
		const entries = {
#ifdef IPV6_ENABLE
			// l2              l3                l4
			// -----------     -------------     -------------------
			// v4
			(true,  false,     false, false,     false, false, false): scope_l2_0tag_l3_none_l4_none();
			(true,  true,      false, false,     false, false, false): scope_l2_1tag_l3_none_l4_none();

			(true,  false,     true,  false,     false, false, false): scope_l2_0tag_l3_v4_l4_none();
			(true,  true,      true,  false,     false, false, false): scope_l2_1tag_l3_v4_l4_none();

			(true,  false,     true,  false,     true,  false, false): scope_l2_0tag_l3_v4_l4_tcp();
			(true,  true,      true,  false,     true,  false, false): scope_l2_1tag_l3_v4_l4_tcp();

			(true,  false,     true,  false,     false, true,  false): scope_l2_0tag_l3_v4_l4_udp();
			(true,  true,      true,  false,     false, true,  false): scope_l2_1tag_l3_v4_l4_udp();

			(true,  false,     true,  false,     false, false, true ): scope_l2_0tag_l3_v4_l4_sctp();
			(true,  true,      true,  false,     false, false, true ): scope_l2_1tag_l3_v4_l4_sctp();

			// v4, l3 tunnel cases (no l2)
			(false, false,     true,  false,     false, false, false): scope_l2_none_l3_v4_l4_none();

			(false, false,     true,  false,     true,  false, false): scope_l2_none_l3_v4_l4_tcp();

			(false, false,     true,  false,     false, true,  false): scope_l2_none_l3_v4_l4_udp();

			(false, false,     true,  false,     false, false, true ): scope_l2_none_l3_v4_l4_sctp();

			// v6
			(true,  false,     false, true,      false, false, false): scope_l2_0tag_l3_v6_l4_none();
			(true,  true,      false, true,      false, false, false): scope_l2_1tag_l3_v6_l4_none();

			(true,  false,     false, true,      true,  false, false): scope_l2_0tag_l3_v6_l4_tcp();
			(true,  true,      false, true,      true,  false, false): scope_l2_1tag_l3_v6_l4_tcp();

			(true,  false,     false, true,      false, true,  false): scope_l2_0tag_l3_v6_l4_udp();
			(true,  true,      false, true,      false, true,  false): scope_l2_1tag_l3_v6_l4_udp();

			(true,  false,     false, true,      false, false, true ): scope_l2_0tag_l3_v6_l4_sctp();
			(true,  true,      false, true,      false, false, true ): scope_l2_1tag_l3_v6_l4_sctp();

			// v6, l3 tunnel cases (no l2)
			(false, false,     false, true,      false, false, false): scope_l2_none_l3_v6_l4_none();

			(false, false,     false, true,      true,  false, false): scope_l2_none_l3_v6_l4_tcp();

			(false, false,     false, true,      false, true,  false): scope_l2_none_l3_v6_l4_udp();

			(false, false,     false, true,      false, false, true ): scope_l2_none_l3_v6_l4_sctp();
#else
			// v4
			(true,  false,     false,            false, false, false): scope_l2_0tag_l3_none_l4_none();
			(true,  true,      false,            false, false, false): scope_l2_1tag_l3_none_l4_none();

			(true,  false,     true,             false, false, false): scope_l2_0tag_l3_v4_l4_none();
			(true,  true,      true,             false, false, false): scope_l2_1tag_l3_v4_l4_none();

			(true,  false,     true,             true,  false, false): scope_l2_0tag_l3_v4_l4_tcp();
			(true,  true,      true,             true,  false, false): scope_l2_1tag_l3_v4_l4_tcp();

			(true,  false,     true,             false, true,  false): scope_l2_0tag_l3_v4_l4_udp();
			(true,  true,      true,             false, true,  false): scope_l2_1tag_l3_v4_l4_udp();

			(true,  false,     true,             false, false, true ): scope_l2_0tag_l3_v4_l4_sctp();
			(true,  true,      true,             false, false, true ): scope_l2_1tag_l3_v4_l4_sctp();

			// v4, l3 tunnel cases (no l2)
			(false, false,     true,             false, false, false): scope_l2_none_l3_v4_l4_none();

			(false, false,     true,             true,  false, false): scope_l2_none_l3_v4_l4_tcp();

			(false, false,     true,             false, true,  false): scope_l2_none_l3_v4_l4_udp();

			(false, false,     true,             false, false, true ): scope_l2_none_l3_v4_l4_sctp();
#endif
		}
		const default_action = scope_l2_none_l3_none_l4_none;
	}

	// -----------------------------
	// Apply
	// -----------------------------

	apply {
//		scope_l2_.apply();
//		scope_l3_.apply();
//		scope_l4_.apply();
		scope_l234_.apply();
		// Note: we can't use our tunnel table, because we don't know about the parser's unsupported tunnel type
/*
		lkp.tunnel_type    = lkp_in.tunnel_type;
		scope_tunnel_.apply();
*/
/*
		if(lkp_in.tunnel_type == SWITCH_TUNNEL_TYPE_NONE) {
			// for handling overload case
			scope_tunnel_none();
		} else {
			scope_tunnel_use_parser_values(lkp_in.next_lyr_valid);
		}
*/
		scope_tunnel_.apply();
	}
}

// ============================================================================
// High Level Routines (meant to only be used by functions outside this file)
// ============================================================================

// NO  Set Terminates / Scope
// YES Set Lkp Data

control Scoper_DataOnly(
		in    switch_lookup_fields_t lkp0_in,
//		in    switch_lookup_fields_t lkp1_in,
		in    switch_lookup_fields_t lkp2_in,

		in    switch_header_outer_t       hdr_1,
		in    switch_header_inner_t       hdr_2,
		in    switch_header_inner_inner_t hdr_3,

		in    bit<8> scope,
		inout switch_lookup_fields_t lkp
) {
	apply {
		if(scope == 0) {
#ifdef INGRESS_MAU_NO_LKP_0
//			Scoper_DataMux_Hdr0ToLkp.apply(hdr_0, hdr_1, lkp0_in, lkp);
#else
//			Scoper_DataMux_LkpToLkp.apply(lkp0_in, lkp);
#endif
		} else if(scope == 1) {
#ifdef INGRESS_MAU_NO_LKP_1
//			Scoper_DataMux_Hdr1ToLkp.apply(hdr_1, hdr_2, lkp1_in, lkp);
#else
//			Scoper_DataMux_LkpToLkp.apply(lkp1_in, lkp);
#endif
		} else {
#ifdef INGRESS_MAU_NO_LKP_2
			Scoper_DataMux_Hdr2ToLkp.apply(hdr_2, hdr_3, lkp2_in, lkp);
#else
			Scoper_DataMux_LkpToLkp.apply(lkp2_in, lkp);
#endif
		}
	}
}

// ============================================================================

// YES Set Terminates / Scope
// NO  Set Lkp Data

control Scoper_ScopeAndTermOnly(
		inout switch_lookup_fields_t lkp,

		in    bool terminate_flag,
		in    bool scope_flag,
		inout bit<8> scope,
		inout bool terminate_0,
		inout bool terminate_1,
		inout bool terminate_2
) {
	action scope_0() {
//		scoper();
		scope = 1;
	}

	action scope_1() {
//		scoper();
		scope = 2;
	}

	action scope_2() {
		// we can't scope any deeper here
		scope = 3;
	}

	action term_0() {
//		terminate_0           = true;
//		scoper();
		scope = 1;
	}

	action term_1() {
		terminate_1           = true;
//		scoper();
		scope = 2;
	}

	action term_2() {
		terminate_1           = true;
		terminate_2           = true;
		// we can't scope any deeper here
		scope = 3;
	}

	table scope_inc {
		key = {
			lkp.next_lyr_valid : exact;
			terminate_flag : exact;
			scope_flag : exact;
			scope : exact;
		}
		actions = {
			NoAction;
			scope_0;
			scope_1;
			scope_2;
			term_0;
			term_1;
			term_2;
		}
		const entries = {
			(true, false, true,  0) : scope_0();
			(true, false, true,  1) : scope_1();
			(true, false, true,  2) : scope_2();

			(true, true,  true,  0) : term_0(); // scope_flag is a don't care when terminating
			(true, true,  false, 0) : term_0(); // scope_flag is a don't care when terminating
			(true, true,  true,  1) : term_1(); // scope_flag is a don't care when terminating
			(true, true,  false, 1) : term_1(); // scope_flag is a don't care when terminating
			(true, true,  true,  2) : term_2(); // scope_flag is a don't care when terminating
			(true, true,  false, 2) : term_2(); // scope_flag is a don't care when terminating
		}
		const default_action = NoAction;
	}

	apply {
		scope_inc.apply();
	}
}

// ============================================================================

// YES Set Terminates / Scope
// YES Set Lkp Data

control Scoper_ScopeAndTermAndData(
		inout switch_lookup_fields_t lkp0_in,
//		inout switch_lookup_fields_t lkp1_in,
		inout switch_lookup_fields_t lkp2_in,

		in    switch_header_outer_t       hdr_1,
		in    switch_header_inner_t       hdr_2,
		in    switch_header_inner_inner_t hdr_3,

		inout switch_lookup_fields_t lkp,

		in    bool terminate_flag,
		in    bool scope_flag,
		inout bit<8> scope,
		inout bool terminate_0,
		inout bool terminate_1,
		inout bool terminate_2
) {
	action scope_0() {
//		scoper();
		scope = 1;
	}

	action scope_1() {
//		scoper();
		scope = 2;
	}

	action scope_2() {
		// we can't scope any deeper here
		scope = 3;
	}

	action term_0() {
//		terminate_0           = true;
//		scoper();
		scope = 1;
	}

	action term_1() {
		terminate_1           = true;
//		scoper();
		scope = 2;
	}

	action term_2() {
		terminate_1           = true;
		terminate_2           = true;
		// we can't scope any deeper here
		scope = 3;
	}

	table scope_inc {
		key = {
			lkp.next_lyr_valid : exact;
			terminate_flag : exact;
			scope_flag : exact;
			scope : exact;
		}
		actions = {
			NoAction;
			scope_0;
			scope_1;
			scope_2;
			term_0;
			term_1;
			term_2;
		}
		const entries = {
			(true, false, true,  0) : scope_0();
			(true, false, true,  1) : scope_1();
			(true, false, true,  2) : scope_2();

			(true, true,  true,  0) : term_0(); // scope_flag is a don't care when terminating
			(true, true,  false, 0) : term_0(); // scope_flag is a don't care when terminating
			(true, true,  true,  1) : term_1(); // scope_flag is a don't care when terminating
			(true, true,  false, 1) : term_1(); // scope_flag is a don't care when terminating
			(true, true,  true,  2) : term_2(); // scope_flag is a don't care when terminating
			(true, true,  false, 2) : term_2(); // scope_flag is a don't care when terminating
		}
		const default_action = NoAction;
	}

	apply {
/*
		scope_inc.apply();
		if(scope == 0) {
			Scoper_DataMux_LkpToLkp.apply(lkp0_in, lkp);
		} else if(scope == 1) {
//			Scoper_DataMux_LkpToLkp.apply(lkp1_in, lkp);
		} else {
			Scoper_DataMux_LkpToLkp.apply(lkp2_in, lkp);
		}
*/
		if(scope_inc.apply().hit) {
#ifdef INGRESS_MAU_NO_LKP_2
			Scoper_DataMux_Hdr2ToLkp.apply(hdr_2, hdr_3, lkp2_in, lkp);
#else
			Scoper_DataMux_LkpToLkp.apply(lkp2_in, lkp);
#endif
		}
	}

}

#endif
