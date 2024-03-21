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

control Scoper(
		in    switch_lookup_fields_t    lkp_in,
		in    switch_drop_reason_t      drop_reason,

		inout switch_lookup_fields_t lkp
) {

	apply {
#if 0
		// Derek: Can't use this code, as we need to alias the 128-bit ip addresses with a 32-bit version.  Need to use the code below instead.
		lkp = lkp_in;
#else
		// l2
		lkp.mac_src_addr       = lkp_in.mac_src_addr;
		lkp.mac_dst_addr       = lkp_in.mac_dst_addr;
		lkp.mac_type           = lkp_in.mac_type;
		lkp.pcp                = lkp_in.pcp;
		lkp.pad                = lkp_in.pad;
		lkp.vid                = lkp_in.vid;

		// l3
		lkp.ip_type            = lkp_in.ip_type;
		lkp.ip_proto           = lkp_in.ip_proto;
		lkp.ip_tos             = lkp_in.ip_tos;
		lkp.ip_flags           = lkp_in.ip_flags;
		lkp.ip_src_addr        = lkp_in.ip_src_addr;
		lkp.ip_dst_addr        = lkp_in.ip_dst_addr;
		// Comment the two below as they are alias fields and do not need to be written again.
		//lkp.ip_src_addr_v4   = lkp_in.ip_src_addr_v4;
		//lkp.ip_dst_addr_v4   = lkp_in.ip_dst_addr_v4;
		lkp.ip_len             = lkp_in.ip_len;

		// l4
		lkp.tcp_flags          = lkp_in.tcp_flags;
		lkp.l4_src_port        = lkp_in.l4_src_port;
		lkp.l4_dst_port        = lkp_in.l4_dst_port;

		// tunnel
		lkp.tunnel_type        = lkp_in.tunnel_type;
		lkp.tunnel_id          = lkp_in.tunnel_id;
		lkp.tunnel_outer_type  = lkp_in.tunnel_outer_type;
		lkp.tunnel_inner_type  = lkp_in.tunnel_inner_type;

		lkp.drop_reason        = lkp_in.drop_reason;
#endif
	}
}

// ============================================================================

control ScoperOuter(
		in switch_header_outer_t     hdr_1,
		in switch_tunnel_metadata_t  tunnel,
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
		lkp.mac_src_addr = hdr_1.ethernet.src_addr;
		lkp.mac_dst_addr = hdr_1.ethernet.dst_addr;
		lkp.mac_type     = hdr_1.ethernet.ether_type;
		lkp.pcp          = 0;
	}

#ifdef ETAG_ENABLE
	action scope_l2_e_tag() {
		lkp.mac_src_addr = hdr_1.ethernet.src_addr;
		lkp.mac_dst_addr = hdr_1.ethernet.dst_addr;
		lkp.mac_type     = hdr_1.e_tag.ether_type;
		//lkp.pcp          = hdr_1.e_tag.pcp;
		lkp.pcp          = 0; // do not populate w/ e-tag
	}
#endif // ETAG_ENABLE
    
#ifdef VNTAG_ENABLE    
	action scope_l2_vn_tag() {
		lkp.mac_src_addr = hdr_1.ethernet.src_addr;
		lkp.mac_dst_addr = hdr_1.ethernet.dst_addr;
		lkp.mac_type     = hdr_1.vn_tag.ether_type;
		lkp.pcp          = 0;
	}
#endif // VNTAG_ENABLE

	action scope_l2_1tag() {
		lkp.mac_src_addr = hdr_1.ethernet.src_addr;
		lkp.mac_dst_addr = hdr_1.ethernet.dst_addr;
		lkp.mac_type     = hdr_1.vlan_tag[0].ether_type;
		lkp.pcp          = hdr_1.vlan_tag[0].pcp;
	}

	action scope_l2_2tags() {
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
			scope_l2;
            
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

			(true,  false, false, false, false): scope_l2();

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

			(true,  false, false, false): scope_l2();

			(true,  true,  false, false): scope_l2_e_tag();

			(true,  false, true,  false): scope_l2_1tag();
			(true,  true,  true,  false): scope_l2_1tag();

			(true,  false, true,  true ): scope_l2_2tags();
			(true,  true,  true,  true ): scope_l2_2tags();
            
#elif !defined(ETAG_ENABLE) && defined(VNTAG_ENABLE)

			(false, false, false, false): scope_l2_none();

			(true,  false, false, false): scope_l2();

			(true,  true,  false, false): scope_l2_vn_tag();

			(true,  false, true,  false): scope_l2_1tag();
			(true,  true,  true,  false): scope_l2_1tag();

			(true,  false, true,  true ): scope_l2_2tags();
			(true,  true,  true,  true ): scope_l2_2tags();            

#else // !defined(ETAG_ENABLE) && !defined(VNTAG_ENABLE)

			(false, false, false): scope_l2_none();

			(true,  false, false): scope_l2();

			(true,  true,  false): scope_l2_1tag();

			(true,  true,  true ): scope_l2_2tags();

#endif
        }
	}

	// -----------------------------
	// L3
	// -----------------------------

	action scope_l3_none() {
		lkp.ip_type       = 0;
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

	action scope_l2_0tag_l3_none_l4_none()  { scope_l2();        scope_l3_none(); scope_l4_none(); }
	action scope_l2_etag_l3_none_l4_none()  { scope_l2_e_tag();  scope_l3_none(); scope_l4_none(); }
	action scope_l2_vntag_l3_none_l4_none() { scope_l2_vn_tag(); scope_l3_none(); scope_l4_none(); }
	action scope_l2_1tag_l3_none_l4_none()  { scope_l2_1tag();   scope_l3_none(); scope_l4_none(); }
	action scope_l2_2tag_l3_none_l4_none()  { scope_l2_2tags();  scope_l3_none(); scope_l4_none(); }

	action scope_l2_0tag_l3_v4_l4_none()    { scope_l2();        scope_l3_v4();   scope_l4_none(); }
	action scope_l2_etag_l3_v4_l4_none()    { scope_l2_e_tag();  scope_l3_v4();   scope_l4_none(); }
	action scope_l2_vntag_l3_v4_l4_none()   { scope_l2_vn_tag(); scope_l3_v4();   scope_l4_none(); }
	action scope_l2_1tag_l3_v4_l4_none()    { scope_l2_1tag();   scope_l3_v4();   scope_l4_none(); }
	action scope_l2_2tag_l3_v4_l4_none()    { scope_l2_2tags();  scope_l3_v4();   scope_l4_none(); }

	action scope_l2_0tag_l3_v6_l4_none()    { scope_l2();        scope_l3_v6();   scope_l4_none(); }
	action scope_l2_etag_l3_v6_l4_none()    { scope_l2_e_tag();  scope_l3_v6();   scope_l4_none(); }
	action scope_l2_vntag_l3_v6_l4_none()   { scope_l2_vn_tag(); scope_l3_v6();   scope_l4_none(); }
	action scope_l2_1tag_l3_v6_l4_none()    { scope_l2_1tag();   scope_l3_v6();   scope_l4_none(); }
	action scope_l2_2tag_l3_v6_l4_none()    { scope_l2_2tags();  scope_l3_v6();   scope_l4_none(); }

	action scope_l2_0tag_l3_v4_l4_tcp()     { scope_l2();        scope_l3_v4();   scope_l4_tcp();  }
	action scope_l2_etag_l3_v4_l4_tcp()     { scope_l2_e_tag();  scope_l3_v4();   scope_l4_tcp();  }
	action scope_l2_vntag_l3_v4_l4_tcp()    { scope_l2_vn_tag(); scope_l3_v4();   scope_l4_tcp();  }
	action scope_l2_1tag_l3_v4_l4_tcp()     { scope_l2_1tag();   scope_l3_v4();   scope_l4_tcp();  }
	action scope_l2_2tag_l3_v4_l4_tcp()     { scope_l2_2tags();  scope_l3_v4();   scope_l4_tcp();  }

	action scope_l2_0tag_l3_v6_l4_tcp()     { scope_l2();        scope_l3_v6();   scope_l4_tcp();  }
	action scope_l2_etag_l3_v6_l4_tcp()     { scope_l2_e_tag();  scope_l3_v6();   scope_l4_tcp();  }
	action scope_l2_vntag_l3_v6_l4_tcp()    { scope_l2_vn_tag(); scope_l3_v6();   scope_l4_tcp();  }
	action scope_l2_1tag_l3_v6_l4_tcp()     { scope_l2_1tag();   scope_l3_v6();   scope_l4_tcp();  }
	action scope_l2_2tag_l3_v6_l4_tcp()     { scope_l2_2tags();  scope_l3_v6();   scope_l4_tcp();  }

	action scope_l2_0tag_l3_v4_l4_udp()     { scope_l2();        scope_l3_v4();   scope_l4_udp();  }
	action scope_l2_etag_l3_v4_l4_udp()     { scope_l2_e_tag();  scope_l3_v4();   scope_l4_udp();  }
	action scope_l2_vntag_l3_v4_l4_udp()    { scope_l2_vn_tag(); scope_l3_v4();   scope_l4_udp();  }
	action scope_l2_1tag_l3_v4_l4_udp()     { scope_l2_1tag();   scope_l3_v4();   scope_l4_udp();  }
	action scope_l2_2tag_l3_v4_l4_udp()     { scope_l2_2tags();  scope_l3_v4();   scope_l4_udp();  }

	action scope_l2_0tag_l3_v6_l4_udp()     { scope_l2();        scope_l3_v6();   scope_l4_udp();  }
	action scope_l2_etag_l3_v6_l4_udp()     { scope_l2_e_tag();  scope_l3_v6();   scope_l4_udp();  }
	action scope_l2_vntag_l3_v6_l4_udp()    { scope_l2_vn_tag(); scope_l3_v6();   scope_l4_udp();  }
	action scope_l2_1tag_l3_v6_l4_udp()     { scope_l2_1tag();   scope_l3_v6();   scope_l4_udp();  }
	action scope_l2_2tag_l3_v6_l4_udp()     { scope_l2_2tags();  scope_l3_v6();   scope_l4_udp();  }

	action scope_l2_0tag_l3_v4_l4_sctp()    { scope_l2();        scope_l3_v4();   scope_l4_sctp(); }
	action scope_l2_etag_l3_v4_l4_sctp()    { scope_l2_e_tag();  scope_l3_v4();   scope_l4_sctp(); }
	action scope_l2_vntag_l3_v4_l4_sctp()   { scope_l2_vn_tag(); scope_l3_v4();   scope_l4_sctp(); }
	action scope_l2_1tag_l3_v4_l4_sctp()    { scope_l2_1tag();   scope_l3_v4();   scope_l4_sctp(); }
	action scope_l2_2tag_l3_v4_l4_sctp()    { scope_l2_2tags();  scope_l3_v4();   scope_l4_sctp(); }

	action scope_l2_0tag_l3_v6_l4_sctp()    { scope_l2();        scope_l3_v6();   scope_l4_sctp(); }
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
		lkp.tunnel_type = 0;
		lkp.tunnel_id   = 0;
	}
/*
	action scope_tunnel_vlan() {
		lkp.tunnel_type = SWITCH_TUNNEL_TYPE_VLAN;
		lkp.tunnel_id   = (switch_tunnel_id_t)hdr_1.vlan_tag[0].vid;
	}
*/
	action scope_tunnel_vni() {
		lkp.tunnel_type = lkp.tunnel_type;
		lkp.tunnel_id   = lkp.tunnel_id;
	}

	table scope_tunnel_ {
		key = {
			lkp.tunnel_type: exact;
/*
			tunnel.type: ternary;
			hdr_1.vlan_tag[0].isValid(): exact;
			hdr_1.vlan_tag[0].vid: ternary;
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
//		scope_l3_.apply();
//		scope_l4_.apply();
		scope_l34_.apply();
//		scope_tunnel_.apply();
		scope_tunnel_vni();

		lkp.drop_reason = drop_reason;
	}
}

// ============================================================================

control ScoperInner(
		in switch_header_inner_t     hdr_2,
		in switch_lookup_fields_t    lkp_2,
		in switch_tunnel_metadata_t  tunnel,
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
		lkp.mac_src_addr = hdr_2.ethernet.src_addr;
		lkp.mac_dst_addr = hdr_2.ethernet.dst_addr;
		lkp.mac_type     = hdr_2.ethernet.ether_type;
		lkp.pcp          = 0;
	}

	action scope_l2_1tag() {
		lkp.mac_src_addr = hdr_2.ethernet.src_addr;
		lkp.mac_dst_addr = hdr_2.ethernet.dst_addr;
		lkp.mac_type     = hdr_2.vlan_tag[0].ether_type;
		lkp.pcp          = hdr_2.vlan_tag[0].pcp;
	}

	table scope_l2_ {
		key = {
			hdr_2.ethernet.isValid(): exact;
			hdr_2.vlan_tag[0].isValid(): exact;
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
		lkp.ip_type       = 0;
		lkp.ip_tos        = 0;
		lkp.ip_proto      = 0;
		lkp.ip_flags      = 0;
		lkp.ip_src_addr   = 0;
		lkp.ip_dst_addr   = 0;
		lkp.ip_len        = 0; // extreme added
	} 

	action scope_l3_v4() {
		lkp.ip_type       = SWITCH_IP_TYPE_IPV4;
		lkp.ip_tos        = hdr_2.ipv4.tos;
		lkp.ip_proto      = hdr_2.ipv4.protocol;
		lkp.ip_flags      = hdr_2.ipv4.flags;
		lkp.ip_src_addr   = (bit<128>) hdr_2.ipv4.src_addr;
		lkp.ip_dst_addr   = (bit<128>) hdr_2.ipv4.dst_addr;
		lkp.ip_len        = hdr_2.ipv4.total_len;
	}

	action scope_l3_v6() {
#ifdef IPV6_ENABLE
		lkp.ip_type       = SWITCH_IP_TYPE_IPV6;
		lkp.ip_tos        = hdr_2.ipv6.tos;
		lkp.ip_proto      = hdr_2.ipv6.next_hdr;
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
	// L2 / L3 / L4
	// -----------------------------

	action scope_l2_none_l3_none_l4_none() { scope_l2_none(); scope_l3_none(); scope_l4_none(); }
	action scope_l2_0tag_l3_none_l4_none() { scope_l2();      scope_l3_none(); scope_l4_none(); }
	action scope_l2_1tag_l3_none_l4_none() { scope_l2_1tag(); scope_l3_none(); scope_l4_none(); }
	action scope_l2_0tag_l3_v4_l4_none()   { scope_l2();      scope_l3_v4();   scope_l4_none(); }
	action scope_l2_1tag_l3_v4_l4_none()   { scope_l2_1tag(); scope_l3_v4();   scope_l4_none(); }
	action scope_l2_0tag_l3_v6_l4_none()   { scope_l2();      scope_l3_v6();   scope_l4_none(); }
	action scope_l2_1tag_l3_v6_l4_none()   { scope_l2_1tag(); scope_l3_v6();   scope_l4_none(); }
	action scope_l2_0tag_l3_v4_l4_tcp()    { scope_l2();      scope_l3_v4();   scope_l4_tcp();  }
	action scope_l2_1tag_l3_v4_l4_tcp()    { scope_l2_1tag(); scope_l3_v4();   scope_l4_tcp();  }
	action scope_l2_0tag_l3_v6_l4_tcp()    { scope_l2();      scope_l3_v6();   scope_l4_tcp();  }
	action scope_l2_1tag_l3_v6_l4_tcp()    { scope_l2_1tag(); scope_l3_v6();   scope_l4_tcp();  }
	action scope_l2_0tag_l3_v4_l4_udp()    { scope_l2();      scope_l3_v4();   scope_l4_udp();  }
	action scope_l2_1tag_l3_v4_l4_udp()    { scope_l2_1tag(); scope_l3_v4();   scope_l4_udp();  }
	action scope_l2_0tag_l3_v6_l4_udp()    { scope_l2();      scope_l3_v6();   scope_l4_udp();  }
	action scope_l2_1tag_l3_v6_l4_udp()    { scope_l2_1tag(); scope_l3_v6();   scope_l4_udp();  }
	action scope_l2_0tag_l3_v4_l4_sctp()   { scope_l2();      scope_l3_v4();   scope_l4_sctp(); }
	action scope_l2_1tag_l3_v4_l4_sctp()   { scope_l2_1tag(); scope_l3_v4();   scope_l4_sctp(); }
	action scope_l2_0tag_l3_v6_l4_sctp()   { scope_l2();      scope_l3_v6();   scope_l4_sctp(); }
	action scope_l2_1tag_l3_v6_l4_sctp()   { scope_l2_1tag(); scope_l3_v6();   scope_l4_sctp(); }

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
			scope_l2_0tag_l3_none_l4_none;
			scope_l2_1tag_l3_none_l4_none;
			scope_l2_none_l3_none_l4_none;
		}
		const entries = {
#ifdef IPV6_ENABLE
			(false, false,     false, false,     false, false, false): scope_l2_none_l3_none_l4_none();

			(true,  false,     false, false,     false, false, false): scope_l2_0tag_l3_none_l4_none();
			(true,  true,      false, false,     false, false, false): scope_l2_1tag_l3_none_l4_none();

			(true,  false,     true,  false,     false, false, false): scope_l2_0tag_l3_v4_l4_none();
			(true,  true,      true,  false,     false, false, false): scope_l2_1tag_l3_v4_l4_none();

			(true,  false,     false, true,      false, false, false): scope_l2_0tag_l3_v6_l4_none();
			(true,  true,      false, true,      false, false, false): scope_l2_1tag_l3_v6_l4_none();

			(true,  false,     true,  false,     true,  false, false): scope_l2_0tag_l3_v4_l4_tcp();
			(true,  true,      true,  false,     true,  false, false): scope_l2_1tag_l3_v4_l4_tcp();

			(true,  false,     false, true,      true,  false, false): scope_l2_0tag_l3_v6_l4_tcp();
			(true,  true,      false, true,      true,  false, false): scope_l2_1tag_l3_v6_l4_tcp();

			(true,  false,     true,  false,     false, true,  false): scope_l2_0tag_l3_v4_l4_udp();
			(true,  true,      true,  false,     false, true,  false): scope_l2_1tag_l3_v4_l4_udp();

			(true,  false,     false, true,      false, true,  false): scope_l2_0tag_l3_v6_l4_udp();
			(true,  true,      false, true,      false, true,  false): scope_l2_1tag_l3_v6_l4_udp();

			(true,  false,     true,  false,     false, false, true ): scope_l2_0tag_l3_v4_l4_sctp();
			(true,  true,      true,  false,     false, false, true ): scope_l2_1tag_l3_v4_l4_sctp();

			(true,  false,     false, true,      false, false, true ): scope_l2_0tag_l3_v6_l4_sctp();
			(true,  true,      false, true,      false, false, true ): scope_l2_1tag_l3_v6_l4_sctp();
#else
			(false, false,     false,            false, false, false): scope_l2_none_l3_none_l4_none();

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
#endif
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
		lkp.tunnel_id   = (switch_tunnel_id_t)hdr_2.vlan_tag[0].vid;
	}
*/
	action scope_tunnel_vni() {
		lkp.tunnel_type = lkp_2.tunnel_type;
		lkp.tunnel_id   = lkp_2.tunnel_id;
	}

	table scope_tunnel_ {
		key = {
			lkp_2.tunnel_type: exact;
/*
			tunnel_type: ternary;
			hdr_2.vlan_tag[0].isValid(): exact;
			hdr_2.vlan_tag[0].vid: ternary;
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
//		scope_l2_.apply();
//		scope_l3_.apply();
//		scope_l4_.apply();
		scope_l234_.apply();
//		scope_tunnel_.apply();
		scope_tunnel_vni();

//		lkp.drop_reason = drop_reason;
	}

}

// ============================================================================
/*
control Scoper_l7(
	in udf_h hdr_udf,
	inout switch_lookup_fields_t lkp
) {
	// -----------------------------
		
	action set_udf() {
#ifdef UDF_ENABLE
		lkp.udf = hdr_udf.opaque;
#endif 
	}

	action clear_udf() {
#ifdef UDF_ENABLE
		lkp.udf = 0;
#endif
	}

	table validate_udf {
		key = {
			hdr_udf.isValid() : exact;
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
