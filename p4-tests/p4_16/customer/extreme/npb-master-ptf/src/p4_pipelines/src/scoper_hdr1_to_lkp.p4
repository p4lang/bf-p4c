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

#ifndef _SCOPER_HDR1_TO_LKP_
#define _SCOPER_HDR1_TO_LKP_

// ============================================================================
// Low Level Routines (meant to only be used by functions within this file)
// ============================================================================

control Scoper_Hdr1_To_Lkp(
	in switch_header_outer_t     hdr_curr,
	in switch_header_inner_t     hdr_next,
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
#ifdef INGRESS_MAU_NO_LKP_1
		// do nothing...keep previous layer's values
#else
//		lkp.l2_valid     = false;
		lkp.mac_src_addr = 0;
		lkp.mac_dst_addr = 0;
//		lkp.mac_type     = 0;
		lkp.pcp          = 0;
		lkp.pad          = 0;
		lkp.vid          = 0;
#endif
		lkp.l2_valid     = false;
		lkp.mac_type     = 0;
	}
*/
	action scope_l2_none_v4() {
#ifdef INGRESS_MAU_NO_LKP_1
		// do nothing...keep previous layer's values
#else
//		lkp.l2_valid     = false;
		lkp.mac_src_addr = 0;
		lkp.mac_dst_addr = 0;
//		lkp.mac_type     = ETHERTYPE_IPV4;
		lkp.pcp          = 0;
		lkp.pad          = 0;
		lkp.vid          = 0;
#endif
		lkp.l2_valid     = false;
		lkp.mac_type     = ETHERTYPE_IPV4;
	}

	action scope_l2_none_v6() {
#ifdef INGRESS_MAU_NO_LKP_1
		// do nothing...keep previous layer's values
#else
//		lkp.l2_valid     = false;
		lkp.mac_src_addr = 0;
		lkp.mac_dst_addr = 0;
//		lkp.mac_type     = ETHERTYPE_IPV6;
		lkp.pcp          = 0;
		lkp.pad          = 0;
		lkp.vid          = 0;
#endif
		lkp.l2_valid     = false;
		lkp.mac_type     = ETHERTYPE_IPV6;
	}

	action scope_l2_0tag() {
		lkp.l2_valid     = true;
		lkp.mac_src_addr = hdr_curr.ethernet.src_addr;
		lkp.mac_dst_addr = hdr_curr.ethernet.dst_addr;
		lkp.mac_type     = hdr_curr.ethernet.ether_type;
		lkp.pcp          = 0;
		lkp.pad          = 0;
		lkp.vid          = 0;
	}

	action scope_l2_e_tag() {
		lkp.l2_valid     = true;
		lkp.mac_src_addr = hdr_curr.ethernet.src_addr;
		lkp.mac_dst_addr = hdr_curr.ethernet.dst_addr;
		lkp.mac_type     = hdr_curr.e_tag.ether_type;
		//lkp.pcp          = hdr_curr.e_tag.pcp;
		lkp.pcp          = 0; // do not populate w/ e-tag
		lkp.pad          = 0;
		lkp.vid          = 0;
	}

	action scope_l2_vn_tag() {
		lkp.l2_valid     = true;
		lkp.mac_src_addr = hdr_curr.ethernet.src_addr;
		lkp.mac_dst_addr = hdr_curr.ethernet.dst_addr;
		lkp.mac_type     = hdr_curr.vn_tag.ether_type;
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

	action scope_l2_2tags() {
		lkp.l2_valid     = true;
		lkp.mac_src_addr = hdr_curr.ethernet.src_addr;
		lkp.mac_dst_addr = hdr_curr.ethernet.dst_addr;
		lkp.mac_type     = hdr_curr.vlan_tag[1].ether_type;
		lkp.pcp          = hdr_curr.vlan_tag[1].pcp;
		lkp.pad          = 0;
		lkp.vid          = hdr_curr.vlan_tag[1].vid;
	}

	// -----------------------------

	@name("scope_l2_")
	table scope_l2_ {
		key = {
			hdr_curr.ethernet.isValid(): exact;
			hdr_curr.vlan_tag[0].isValid(): exact;
			hdr_curr.vlan_tag[1].isValid(): exact;

			hdr_curr.ipv4.isValid(): exact;
#ifdef IPV6_ENABLE
			hdr_curr.ipv6.isValid(): exact;
#endif // IPV6_ENABLE
		}
		actions = {
//			scope_l2_none;
			scope_l2_none_v4;
			scope_l2_none_v6;
			scope_l2_0tag;
//			scope_l2_e_tag;
//			scope_l2_vn_tag;
			scope_l2_1tag;
			scope_l2_2tags;
		}
		const entries = {
			// l2                 l3
			// ------------------ ------------
//			(false, false, false, false, false): scope_l2_none();
			(false, false, false, true,  false): scope_l2_none_v4();
			(false, false, false, false, true ): scope_l2_none_v6();

			(true,  false, false, false, false): scope_l2_0tag();
			(true,  false, false, true,  false): scope_l2_0tag();
			(true,  false, false, false, true ): scope_l2_0tag();

			(true,  true,  false, false, false): scope_l2_1tag();
			(true,  true,  false, true,  false): scope_l2_1tag();
			(true,  true,  false, false, true ): scope_l2_1tag();

			(true,  true,  true,  false, false): scope_l2_2tags();
			(true,  true,  true,  true,  false): scope_l2_2tags();
			(true,  true,  true,  false, true ): scope_l2_2tags();
		}
	}

	// -----------------------------

	@name("scope_l2_")
	table scope_l2_etag {
		key = {
			hdr_curr.ethernet.isValid(): exact;
			hdr_curr.e_tag.isValid(): exact;
			hdr_curr.vlan_tag[0].isValid(): exact;
			hdr_curr.vlan_tag[1].isValid(): exact;

			hdr_curr.ipv4.isValid(): exact;
#ifdef IPV6_ENABLE
			hdr_curr.ipv6.isValid(): exact;
#endif // IPV6_ENABLE
		}
		actions = {
//			scope_l2_none;
			scope_l2_none_v4;
			scope_l2_none_v6;
			scope_l2_0tag;
			scope_l2_e_tag;
//			scope_l2_vn_tag;
			scope_l2_1tag;
			scope_l2_2tags;
		}
		const entries = {
			// l2                        l3
			// ------------------------- ------------
//			(false, false, false, false, false, false): scope_l2_none();
			(false, false, false, false, true,  false): scope_l2_none_v4();
			(false, false, false, false, false, true ): scope_l2_none_v6();

			(true,  false, false, false, false, false): scope_l2_0tag();
			(true,  false, false, false, true,  false): scope_l2_0tag();
			(true,  false, false, false, false, true ): scope_l2_0tag();

			(true,  true,  false, false, false, false): scope_l2_e_tag();
			(true,  true,  false, false, true,  false): scope_l2_e_tag();
			(true,  true,  false, false, false, true ): scope_l2_e_tag();

			(true,  false, true,  false, false, false): scope_l2_1tag();
			(true,  false, true,  false, true,  false): scope_l2_1tag();
			(true,  false, true,  false, false, true ): scope_l2_1tag();
			(true,  true,  true,  false, false, false): scope_l2_1tag();
			(true,  true,  true,  false, true,  false): scope_l2_1tag();
			(true,  true,  true,  false, false, true ): scope_l2_1tag();

			(true,  false, true,  true,  false, false): scope_l2_2tags();
			(true,  false, true,  true,  true,  false): scope_l2_2tags();
			(true,  false, true,  true,  false, true ): scope_l2_2tags();
			(true,  true,  true,  true,  false, false): scope_l2_2tags();
			(true,  true,  true,  true,  true,  false): scope_l2_2tags();
			(true,  true,  true,  true,  false, true ): scope_l2_2tags();
		}
	}

	// -----------------------------

	@name("scope_l2_")
	table scope_l2_vntag {
		key = {
			hdr_curr.ethernet.isValid(): exact;
			hdr_curr.vn_tag.isValid(): exact;
			hdr_curr.vlan_tag[0].isValid(): exact;
			hdr_curr.vlan_tag[1].isValid(): exact;

			hdr_curr.ipv4.isValid(): exact;
#ifdef IPV6_ENABLE
			hdr_curr.ipv6.isValid(): exact;
#endif // IPV6_ENABLE
		}
		actions = {
//			scope_l2_none;
			scope_l2_none_v4;
			scope_l2_none_v6;
			scope_l2_0tag;
//			scope_l2_e_tag;
			scope_l2_vn_tag;
			scope_l2_1tag;
			scope_l2_2tags;
		}
		const entries = {
			// l2                        l3
			// ------------------------- ------------
//			(false, false, false, false, false, false): scope_l2_none();
			(false, false, false, false, true,  false): scope_l2_none_v4();
			(false, false, false, false, false, true ): scope_l2_none_v6();

			(true,  false, false, false, false, false): scope_l2_0tag();
			(true,  false, false, false, true,  false): scope_l2_0tag();
			(true,  false, false, false, false, true ): scope_l2_0tag();

			(true,  true,  false, false, false, false): scope_l2_vn_tag();
			(true,  true,  false, false, true,  false): scope_l2_vn_tag();
			(true,  true,  false, false, false, true ): scope_l2_vn_tag();

			(true,  false, true,  false, false, false): scope_l2_1tag();
			(true,  false, true,  false, true,  false): scope_l2_1tag();
			(true,  false, true,  false, false, true ): scope_l2_1tag();
			(true,  true,  true,  false, false, false): scope_l2_1tag();
			(true,  true,  true,  false, true,  false): scope_l2_1tag();
			(true,  true,  true,  false, false, true ): scope_l2_1tag();

			(true,  false, true,  true,  false, false): scope_l2_2tags();
			(true,  false, true,  true,  true,  false): scope_l2_2tags();
			(true,  false, true,  true,  false, true ): scope_l2_2tags();
			(true,  true,  true,  true,  false, false): scope_l2_2tags();
			(true,  true,  true,  true,  true,  false): scope_l2_2tags();
			(true,  true,  true,  true,  false, true ): scope_l2_2tags();
		}
	}

	// -----------------------------

	@name("scope_l2_")
	table scope_l2_etag_vntag {
		key = {
			hdr_curr.ethernet.isValid(): exact;
			hdr_curr.e_tag.isValid(): exact;
			hdr_curr.vn_tag.isValid(): exact;
			hdr_curr.vlan_tag[0].isValid(): exact;
			hdr_curr.vlan_tag[1].isValid(): exact;

			hdr_curr.ipv4.isValid(): exact;
#ifdef IPV6_ENABLE
			hdr_curr.ipv6.isValid(): exact;
#endif // IPV6_ENABLE
		}
		actions = {
//			scope_l2_none;
			scope_l2_none_v4;
			scope_l2_none_v6;
			scope_l2_0tag;
			scope_l2_e_tag;
			scope_l2_vn_tag;
			scope_l2_1tag;
			scope_l2_2tags;
		}
		const entries = {
			// l2                               l3
			// -------------------------------- ------------
//			(false, false, false, false, false, false, false): scope_l2_none();
			(false, false, false, false, false, true,  false): scope_l2_none_v4();
			(false, false, false, false, false, false, true ): scope_l2_none_v6();

			(true,  false, false, false, false, false, false): scope_l2_0tag();
			(true,  false, false, false, false, true,  false): scope_l2_0tag();
			(true,  false, false, false, false, false, true ): scope_l2_0tag();

			(true,  true,  false, false, false, false, false): scope_l2_e_tag();
			(true,  true,  false, false, false, true,  false): scope_l2_e_tag();
			(true,  true,  false, false, false, false, true ): scope_l2_e_tag();
			(true,  false, true,  false, false, false, false): scope_l2_vn_tag();
			(true,  false, true,  false, false, true,  false): scope_l2_vn_tag();
			(true,  false, true,  false, false, false, true ): scope_l2_vn_tag();

			(true,  false, false, true,  false, false, false): scope_l2_1tag();
			(true,  false, false, true,  false, true,  false): scope_l2_1tag();
			(true,  false, false, true,  false, false, true ): scope_l2_1tag();
			(true,  true,  false, true,  false, false, false): scope_l2_1tag();
			(true,  true,  false, true,  false, true,  false): scope_l2_1tag();
			(true,  true,  false, true,  false, false, true ): scope_l2_1tag();
			(true,  false, true,  true,  false, false, false): scope_l2_1tag();
			(true,  false, true,  true,  false, true,  false): scope_l2_1tag();
			(true,  false, true,  true,  false, false, true ): scope_l2_1tag();

			(true,  false, false, true,  true,  false, false): scope_l2_2tags();
			(true,  false, false, true,  true,  true,  false): scope_l2_2tags();
			(true,  false, false, true,  true,  false, true ): scope_l2_2tags();
			(true,  true,  false, true,  true,  false, false): scope_l2_2tags();
			(true,  true,  false, true,  true,  true,  false): scope_l2_2tags();
			(true,  true,  false, true,  true,  false, true ): scope_l2_2tags();
			(true,  false, true,  true,  true,  false, false): scope_l2_2tags();
			(true,  false, true,  true,  true,  true,  false): scope_l2_2tags();
			(true,  false, true,  true,  true,  false, true ): scope_l2_2tags();
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
		lkp.ip_tos        = hdr_curr.ipv4.tos;
		lkp.ip_proto      = hdr_curr.ipv4.protocol;
		lkp.ip_flags      = hdr_curr.ipv4.flags;
		lkp.ip_src_addr_v4= hdr_curr.ipv4.src_addr;
		lkp.ip_dst_addr_v4= hdr_curr.ipv4.dst_addr;
		lkp.ip_len        = hdr_curr.ipv4.total_len;
	}

	action scope_l3_v6() {
#ifdef IPV6_ENABLE
		lkp.ip_type       = SWITCH_IP_TYPE_IPV6;
		lkp.ip_tos        = hdr_curr.ipv6.tos;
		lkp.ip_proto      = hdr_curr.ipv6.next_hdr;
		lkp.ip_flags      = 0;
		lkp.ip_src_addr   = hdr_curr.ipv6.src_addr;
		lkp.ip_dst_addr   = hdr_curr.ipv6.dst_addr;
		lkp.ip_len        = hdr_curr.ipv6.payload_len;
#endif // IPV6_ENABLE
	}

	// -----------------------------

	table scope_l3_ {
		key = {
			hdr_curr.ipv4.isValid(): exact;
#ifdef IPV6_ENABLE
			hdr_curr.ipv6.isValid(): exact;
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
		lkp.l4_src_port = hdr_curr.tcp.src_port;
		lkp.l4_dst_port = hdr_curr.tcp.dst_port;
		lkp.tcp_flags   = hdr_curr.tcp.flags;
	}

	action scope_l4_udp() {
		lkp.l4_src_port = hdr_curr.udp.src_port;
		lkp.l4_dst_port = hdr_curr.udp.dst_port;
		lkp.tcp_flags   = 0;
	}

	action scope_l4_sctp() {
		lkp.l4_src_port = hdr_curr.sctp.src_port;
		lkp.l4_dst_port = hdr_curr.sctp.dst_port;
		lkp.tcp_flags   = 0;
	}

	// -----------------------------

	table scope_l4_ {
		key = {
			hdr_curr.tcp.isValid():  exact;
			hdr_curr.udp.isValid():  exact;
			hdr_curr.sctp.isValid(): exact;
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

	// -----------------------------

	table scope_l34_ {
		key = {
			hdr_curr.ipv4.isValid(): exact;
#ifdef IPV6_ENABLE
			hdr_curr.ipv6.isValid(): exact;
#endif // IPV6_ENABLE

			hdr_curr.tcp.isValid():  exact;
			hdr_curr.udp.isValid():  exact;
			hdr_curr.sctp.isValid(): exact;
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

	// -----------------------------

	table scope_l234_ {
		key = {
			hdr_curr.ethernet.isValid(): exact;
			hdr_curr.e_tag.isValid(): exact;
			hdr_curr.vn_tag.isValid(): exact;
			hdr_curr.vlan_tag[0].isValid(): exact;
			hdr_curr.vlan_tag[1].isValid(): exact;

			hdr_curr.ipv4.isValid(): exact;
#ifdef IPV6_ENABLE
			hdr_curr.ipv6.isValid(): exact;
#endif // IPV6_ENABLE

			hdr_curr.tcp.isValid():  exact;
			hdr_curr.udp.isValid():  exact;
			hdr_curr.sctp.isValid(): exact;
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

	action scope_tunnel_use_parser_values(bool lkp_curr_next_lyr_valid) {
		lkp.tunnel_type    = lkp_curr.tunnel_type;
		lkp.tunnel_id      = lkp_curr.tunnel_id;
		lkp.next_lyr_valid = lkp_curr_next_lyr_valid;
	}

	// -----------------------------
/*
	table scope_tunnel_ {
		key = {
			hdr_curr.gre.isValid():  exact;
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
	// Apply
	// -----------------------------

	apply {
		if(OUTER_ETAG_ENABLE && OUTER_VNTAG_ENABLE) {
			scope_l2_etag_vntag.apply();
		} else if(OUTER_ETAG_ENABLE) {
			scope_l2_etag.apply();
		} else if(OUTER_VNTAG_ENABLE) {
			scope_l2_vntag.apply();
		} else {
			scope_l2_.apply();
		}
//		scope_l3_.apply();
//		scope_l4_.apply();
		scope_l34_.apply();
//		scope_l234_.apply();
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
