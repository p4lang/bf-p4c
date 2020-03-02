#ifndef _NPB_EGR_PARSER_
#define _NPB_EGR_PARSER_

parser NpbEgressParser(
        packet_in pkt,
        out switch_header_t hdr,
        out switch_egress_metadata_t eg_md,
        out egress_intrinsic_metadata_t eg_intr_md) {

	bit<16> ether_type;
	bit<16> inner_ether_type;
	bit<8>  protocol;
	bit<8>  inner_protocol;

    value_set<bit<16>>(1) udp_port_vxlan;

    state start {
        pkt.extract(eg_intr_md);
        eg_md.pkt_length = eg_intr_md.pkt_length;
        eg_md.port = eg_intr_md.egress_port;

        // initialize lookup struct to zeros
        eg_md.lkp.mac_src_addr = 0;
        eg_md.lkp.mac_dst_addr = 0;
        eg_md.lkp.mac_type = 0;
        eg_md.lkp.pcp = 0;

        eg_md.lkp.ip_type = SWITCH_IP_TYPE_NONE;
        eg_md.lkp.ip_proto = 0;
        eg_md.lkp.ip_tos = 0;
#ifdef BUG_10439_WORKAROUND
        eg_md.lkp.ip_src_addr_3 = 0;
        eg_md.lkp.ip_src_addr_2 = 0;
        eg_md.lkp.ip_src_addr_1 = 0;
        eg_md.lkp.ip_src_addr_0 = 0;
        eg_md.lkp.ip_dst_addr_3 = 0;
        eg_md.lkp.ip_dst_addr_2 = 0;
        eg_md.lkp.ip_dst_addr_1 = 0;
        eg_md.lkp.ip_dst_addr_0 = 0;
#else
        eg_md.lkp.ip_src_addr = 0;
        eg_md.lkp.ip_dst_addr = 0;
#endif // BUG_10439_WORKAROUND
        eg_md.lkp.ip_len = 0;

        eg_md.lkp.tcp_flags = 0;
        eg_md.lkp.l4_src_port = 0;
        eg_md.lkp.l4_dst_port = 0;

        eg_md.lkp.tunnel_type = 0;
        eg_md.lkp.tunnel_id = 0;
        
#ifdef MIRROR_ENABLE
        switch_port_mirror_metadata_h mirror_md = pkt.lookahead<switch_port_mirror_metadata_h>();
        transition select(eg_intr_md.deflection_flag, mirror_md.src, mirror_md.type) {
            (_, SWITCH_PKT_SRC_BRIDGED, _) : parse_bridged_pkt;
        }
#else
        transition parse_bridged_pkt;
#endif
    }

    state parse_bridged_pkt {
		pkt.extract(hdr.bridged_md);
        eg_md.pkt_src = SWITCH_PKT_SRC_BRIDGED;
        eg_md.ingress_port = hdr.bridged_md.base.ingress_port;
        eg_md.port_lag_index = hdr.bridged_md.base.ingress_port_lag_index;
        eg_md.bd = hdr.bridged_md.base.ingress_bd;
        eg_md.nexthop = hdr.bridged_md.base.nexthop;
//      eg_md.pkt_type = hdr.bridged_md.base.pkt_type;
//      eg_md.ingress_timestamp = hdr.bridged_md.base.timestamp;
        eg_md.flags.rmac_hit = hdr.bridged_md.base.rmac_hit;
#ifdef TUNNEL_ENABLE
        eg_md.outer_nexthop = hdr.bridged_md.tunnel.outer_nexthop;
        eg_md.tunnel_0.index = hdr.bridged_md.tunnel.index;
        eg_md.tunnel_0.hash = hdr.bridged_md.tunnel.hash;

        eg_md.tunnel_0.terminate = hdr.bridged_md.tunnel.terminate_0;
        eg_md.tunnel_1.terminate = hdr.bridged_md.tunnel.terminate_1;
        eg_md.tunnel_2.terminate = hdr.bridged_md.tunnel.terminate_2;
		eg_md.nsh_terminate      = hdr.bridged_md.tunnel.nsh_terminate;
#endif

		// ---------------
		// nsh meta data
		// ---------------
        eg_md.nsh_type1.hdr_is_new = hdr.bridged_md.base.nsh_type1_hdr_is_new;
        eg_md.nsh_type1.sf_bitmask = hdr.bridged_md.base.nsh_type1_sf_bitmask;        //  1 byte

		// ---------------
		// dedup stuff
		// ---------------
#ifdef SF_2_DEDUP_ENABLE        
		eg_md.lkp.ipv4_src_addr = hdr.bridged_md.base.ipv4_src_addr;
		eg_md.lkp.ipv4_dst_addr = hdr.bridged_md.base.ipv4_dst_addr;
		eg_md.lkp.ip_proto      = hdr.bridged_md.base.ip_proto;
#endif

        // -----------------------------

        transition parse_transport_ethernet;  // packet will always have NSH present
        // transition snoop_head;
        // transition select(eg_md.orig_pkt_had_nsh) {
        //     0: parse_outer_ethernet;
        //     1: parse_transport_ethernet;
        // }
    }

    // // Snoop ahead here to try and determine if there's a transport present
    // state snoop_head {
    //     transition select(pkt.lookahead<bit<112>>()[15:0], pkt.lookahead<bit<144>>()[15:0]) {
    //         (ETHERTYPE_NSH, _): parse_transport_ethernet;
    //         (ETHERTYPE_VLAN, ETHERTYPE_NSH): parse_transport_ethernet;
    //         default: parse_outer_ethernet;
    //     }
    // }


    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////
    // Transport Layer 2 (L2-U)
    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////

    ///////////////////////////////////////////////////////////////////////////
    // NSH
    ///////////////////////////////////////////////////////////////////////////

    state parse_transport_ethernet {
        pkt.extract(hdr.transport.ethernet);
        transition select(hdr.transport.ethernet.ether_type) {
            ETHERTYPE_VLAN: parse_transport_vlan;
            default: parse_transport_nsh;
        }
    }
    state parse_transport_vlan {
        pkt.extract(hdr.transport.vlan_tag[0]);
        transition parse_transport_nsh;
    }

    state parse_transport_nsh {
	    pkt.extract(hdr.transport.nsh_type1);
        transition parse_outer_ethernet;
    }


    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////
    // "Outer" Headers / Stack
    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////

    ///////////////////////////////////////////////////////////////////////////
    // Layer2 - Outer (ETH)
    ///////////////////////////////////////////////////////////////////////////

    // Barefoot compiler doesn't allow us to set the same variable (or header)
    // more than once. Doing so causes a wire-OR instead of clear-on-write.
    // Because of this limitation, we're unable to use a fanout/branch state
    // at layer2. Barefoot hinted that a fix in the works for Tofino2.

    // We can still emply a fanout/brach state for e-tags and vn-tags, since
    // the two headers are mutually exclusive.

    state parse_outer_ethernet {
        pkt.extract(hdr.outer.ethernet);
        eg_md.lkp.mac_src_addr = hdr.outer.ethernet.src_addr;
        eg_md.lkp.mac_dst_addr = hdr.outer.ethernet.dst_addr;
        eg_md.lkp.mac_type     = hdr.outer.ethernet.ether_type;
        transition select(hdr.outer.ethernet.ether_type) {
            ETHERTYPE_BR : parse_outer_br;
            ETHERTYPE_VN : parse_outer_vn;
            ETHERTYPE_VLAN : parse_outer_vlan;
            ETHERTYPE_QINQ : parse_outer_vlan;
#ifdef MPLS_ENABLE
            ETHERTYPE_MPLS : parse_outer_mpls;
#endif
            ETHERTYPE_IPV4 : parse_outer_ipv4;
            ETHERTYPE_IPV6 : parse_outer_ipv6;
            default : accept;
        }
    }

    state parse_outer_br {
	    pkt.extract(hdr.outer.e_tag);
        ether_type = hdr.outer.e_tag.ether_type;
        eg_md.lkp.mac_type = hdr.outer.e_tag.ether_type;        
        eg_md.lkp.pcp = hdr.outer.e_tag.pcp;        
        transition select(hdr.outer.e_tag.ether_type) {
            ETHERTYPE_VLAN : parse_outer_vlan;
            ETHERTYPE_QINQ : parse_outer_vlan;
            default : branch_outer_ether_type;
        }
    }

    state parse_outer_vn {
	    pkt.extract(hdr.outer.vn_tag);
        ether_type = hdr.outer.vn_tag.ether_type;
        eg_md.lkp.mac_type = hdr.outer.vn_tag.ether_type;
        transition select(hdr.outer.vn_tag.ether_type) {
            ETHERTYPE_VLAN : parse_outer_vlan;
            ETHERTYPE_QINQ : parse_outer_vlan;
            default : branch_outer_ether_type;
        }
    }

    state parse_outer_vlan {
	    pkt.extract(hdr.outer.vlan_tag.next);
        eg_md.lkp.mac_type = hdr.outer.vlan_tag.last.ether_type;
        eg_md.lkp.pcp = hdr.outer.vlan_tag.last.pcp;
        transition select(hdr.outer.vlan_tag.last.ether_type) {
            ETHERTYPE_VLAN : parse_outer_vlan;
            ETHERTYPE_QINQ : parse_outer_vlan;
#ifdef MPLS_ENABLE
            ETHERTYPE_MPLS : parse_outer_mpls;
#endif
            ETHERTYPE_IPV4 : parse_outer_ipv4;
            ETHERTYPE_IPV6 : parse_outer_ipv6;
            default : accept;
        }
    }

    // shared fanout/branch state to save tcam resource
    state branch_outer_ether_type {
        transition select(ether_type) {
#ifdef MPLS_ENABLE
            ETHERTYPE_MPLS : parse_outer_mpls;
#endif
            ETHERTYPE_IPV4 : parse_outer_ipv4;
            ETHERTYPE_IPV6 : parse_outer_ipv6;
            default : accept;
        }
    }


    ///////////////////////////////////////////////////////////////////////////
    // Layer 3 - Outer
    ///////////////////////////////////////////////////////////////////////////

    state parse_outer_ipv4 {
        pkt.extract(hdr.outer.ipv4);
        protocol = hdr.outer.ipv4.protocol;
        // todo: should the lkp struct be set only if no frag and options?
        eg_md.lkp.ip_type       = SWITCH_IP_TYPE_IPV4;
        eg_md.lkp.ip_proto      = hdr.outer.ipv4.protocol;
        eg_md.lkp.ip_tos        = hdr.outer.ipv4.tos;
#ifdef BUG_10439_WORKAROUND
        eg_md.lkp.ip_src_addr_0 = hdr.outer.ipv4.src_addr;
        eg_md.lkp.ip_dst_addr_0 = hdr.outer.ipv4.dst_addr;
#else
        eg_md.lkp.ip_src_addr   = (bit<128>)hdr.outer.ipv4.src_addr;
        eg_md.lkp.ip_dst_addr   = (bit<128>)hdr.outer.ipv4.dst_addr;
#endif // BUG_10439_WORKAROUND
        eg_md.lkp.ip_len        = hdr.outer.ipv4.total_len;
        // Flag packet (to be sent to host) if it's a frag or has options.
        transition select(hdr.outer.ipv4.ihl, hdr.outer.ipv4.flags, hdr.outer.ipv4.frag_offset) {
            //(5, 0, 0) : branch_outer_l3_protocol;
            //(5, 2, 0) : branch_outer_l3_protocol;
            (5, 3w2 &&& 3w5, 0): branch_outer_l3_protocol;
            default : accept;
        }
    }

    state parse_outer_ipv6 {
#ifdef IPV6_ENABLE
        pkt.extract(hdr.outer.ipv6);
        protocol = hdr.outer.ipv6.next_hdr;
        eg_md.lkp.ip_type       = SWITCH_IP_TYPE_IPV6;
        eg_md.lkp.ip_proto      = hdr.outer.ipv6.next_hdr;
        //eg_md.lkp.ip_tos        = hdr.outer.ipv6.tos; // not byte-aligned so set in mau
#ifdef BUG_10439_WORKAROUND
        eg_md.lkp.ip_src_addr_3 = hdr.outer.ipv6.src_addr_3;
        eg_md.lkp.ip_src_addr_2 = hdr.outer.ipv6.src_addr_2;
        eg_md.lkp.ip_src_addr_1 = hdr.outer.ipv6.src_addr_1;
        eg_md.lkp.ip_src_addr_0 = hdr.outer.ipv6.src_addr_0;
        eg_md.lkp.ip_dst_addr_3 = hdr.outer.ipv6.dst_addr_3;
        eg_md.lkp.ip_dst_addr_2 = hdr.outer.ipv6.dst_addr_2;
        eg_md.lkp.ip_dst_addr_1 = hdr.outer.ipv6.dst_addr_1;
        eg_md.lkp.ip_dst_addr_0 = hdr.outer.ipv6.dst_addr_0;
#else
        eg_md.lkp.ip_src_addr   = hdr.outer.ipv6.src_addr;
        eg_md.lkp.ip_dst_addr   = hdr.outer.ipv6.dst_addr;
#endif // BUG_10439_WORKAROUND
        eg_md.lkp.ip_len        = hdr.outer.ipv6.payload_len;
        transition branch_outer_l3_protocol;
#else
        transition reject;
#endif
    }

    // shared fanout/branch state to save tcam resource
    state branch_outer_l3_protocol {
        transition select(protocol) {
           //IP_PROTOCOLS_IPV4: parse_inner_ipv4;
           //IP_PROTOCOLS_IPV6: parse_inner_ipv6;
           IP_PROTOCOLS_IPV4: parse_outer_ipinip_set_tunnel_type;
           IP_PROTOCOLS_IPV6: parse_outer_ipv6inip_set_tunnel_type;
           IP_PROTOCOLS_UDP: parse_outer_udp;
           IP_PROTOCOLS_TCP: parse_outer_tcp;
           IP_PROTOCOLS_SCTP: parse_outer_sctp;
           // todo: encap doc shows no v6 branch for esp.
           // if true, we need to move this up into v4 state.
           IP_PROTOCOLS_ESP: parse_outer_esp;
           IP_PROTOCOLS_GRE: parse_outer_gre;
           default : accept;
       }
    }


    ///////////////////////////////////////////////////////////////////////////
    // Layer 4 - Outer
    ///////////////////////////////////////////////////////////////////////////

    //-------------------------------------------------------------------------
    // User Datagram Protocol (UDP) - Outer
    //-------------------------------------------------------------------------

    state parse_outer_udp {
        pkt.extract(hdr.outer.udp);
        eg_md.lkp.l4_src_port = hdr.outer.udp.src_port;
        eg_md.lkp.l4_dst_port = hdr.outer.udp.dst_port;  
        transition select(hdr.outer.udp.src_port, hdr.outer.udp.dst_port) {
            (_, UDP_PORT_VXLAN): parse_outer_vxlan;
#ifdef GTP_ENABLE
            (_, UDP_PORT_GTP_C): parse_outer_gtp_c;
            (UDP_PORT_GTP_C, _): parse_outer_gtp_c;
            (_, UDP_PORT_GTP_U): parse_outer_gtp_u;
            (UDP_PORT_GTP_U, _): parse_outer_gtp_u;
#endif  /* GTP_ENABLE */
            default : accept;
        }
    }

    //-------------------------------------------------------------------------
    // Transmission Control Protocol (TCP) - Outer
    //-------------------------------------------------------------------------

    state parse_outer_tcp {
        pkt.extract(hdr.outer.tcp);
        eg_md.lkp.l4_src_port = hdr.outer.tcp.src_port;
        eg_md.lkp.l4_dst_port = hdr.outer.tcp.dst_port;
        eg_md.lkp.tcp_flags   = hdr.outer.tcp.flags;
        transition accept;
    }

    //-------------------------------------------------------------------------
    // Stream Control Transmission Protocol (SCTP) - Outer
    //-------------------------------------------------------------------------

    state parse_outer_sctp {
        pkt.extract(hdr.outer.sctp);
        eg_md.lkp.l4_src_port = hdr.outer.sctp.src_port;
        eg_md.lkp.l4_dst_port = hdr.outer.sctp.dst_port;
        transition accept;
    }


    ///////////////////////////////////////////////////////////////////////////////
    // Layer X - Outer
    ///////////////////////////////////////////////////////////////////////////////

    //-------------------------------------------------------------------------
    // Multi-Protocol Label Switching (MPLS) - Outer
    //-------------------------------------------------------------------------
        
#ifdef MPLS_ENABLE

    state parse_outer_mpls {
    	pkt.extract(hdr.outer.mpls.next);
        transition select(hdr.outer.mpls.last.bos, pkt.lookahead<bit<4>>()) {
            (0, _): parse_outer_mpls;
            (1, 4): parse_inner_ipv4;
            (1, 6): parse_inner_ipv6;
            default: parse_outer_eompls;
        }
    }
    
    state parse_outer_eompls {
        pkt.extract(hdr.outer.mpls_pw_cw); 
        transition  parse_inner_ethernet;
    }

#endif  /* MPLS_ENABLE */



    ///////////////////////////////////////////////////////////////////////////
    // Tunnels - Outer
    ///////////////////////////////////////////////////////////////////////////

    //-------------------------------------------------------------------------
    // Virtual Extensible Local Area Network (VXLAN) - Outer
    //-------------------------------------------------------------------------

    state parse_outer_vxlan {
#ifdef VXLAN_ENABLE
        pkt.extract(hdr.outer.vxlan);
        eg_md.tunnel_1.type = SWITCH_TUNNEL_TYPE_VXLAN;
        eg_md.tunnel_1.id = hdr.outer.vxlan.vni;
        eg_md.lkp.tunnel_type = SWITCH_TUNNEL_TYPE_VXLAN;
        eg_md.lkp.tunnel_id = hdr.outer.vxlan.vni;
        transition parse_inner_ethernet;
#else
        transition reject;
#endif
    }


    //-------------------------------------------------------------------------
    // Internet Protocol (IP) - Outer
    //-------------------------------------------------------------------------

    state parse_outer_ipinip_set_tunnel_type {
#ifdef IPINIP
        eg_md.tunnel_1.type = SWITCH_TUNNEL_TYPE_IPINIP;
        eg_md.lkp.tunnel_type = SWITCH_TUNNEL_TYPE_IPINIP;
        transition parse_inner_ipv4;
#else
        transition accept;
#endif /* IPINIP */
    }

    state parse_outer_ipv6inip_set_tunnel_type {
#ifdef IPINIP
        eg_md.tunnel_1.type = SWITCH_TUNNEL_TYPE_IPINIP;
        eg_md.lkp.tunnel_type = SWITCH_TUNNEL_TYPE_IPINIP;
        transition parse_inner_ipv6;
#else
        transition accept;
#endif /* IPINIP */
    }


    //-------------------------------------------------------------------------
    // Generic Routing Encapsulation (GRE) - Outer
    //-------------------------------------------------------------------------

    // todo: validation - make sure R, s, recurse and flags are zero.
    //       see rfc 2784, and 2890
    state parse_outer_gre {
    	pkt.extract(hdr.outer.gre);
        transition select(
            hdr.outer.gre.C,
            hdr.outer.gre.K,
            hdr.outer.gre.S,
            hdr.outer.gre.version,
            hdr.outer.gre.proto) {
        
            (0,1,0,0,GRE_PROTOCOLS_NVGRE): parse_outer_nvgre;
            default: parse_outer_gre_set_tunnel_type;
        }
    }

    state parse_outer_gre_set_tunnel_type {
        eg_md.tunnel_1.type = SWITCH_TUNNEL_TYPE_GRE;
        eg_md.lkp.tunnel_type = SWITCH_TUNNEL_TYPE_GRE;
        transition select(
            hdr.outer.gre.C,
            hdr.outer.gre.K,
            hdr.outer.gre.S,
            hdr.outer.gre.version,
            hdr.outer.gre.proto) {
        
#ifdef MPLS_ENABLE
            (0,0,0,0,ETHERTYPE_MPLS): parse_outer_mpls;
#endif
            (0,0,0,0,ETHERTYPE_IPV4): parse_inner_ipv4;
            (0,0,0,0,ETHERTYPE_IPV6): parse_inner_ipv6;
            default: accept;
        }
    }

    
    //-------------------------------------------------------------------------
    // Network Virtualization using GRE (NVGRE) - Outer
    //-------------------------------------------------------------------------

    state parse_outer_nvgre {
    	pkt.extract(hdr.outer.nvgre);
        eg_md.tunnel_1.type = SWITCH_TUNNEL_TYPE_NVGRE;
        eg_md.tunnel_1.id = hdr.outer.nvgre.vsid;
        eg_md.lkp.tunnel_type = SWITCH_TUNNEL_TYPE_NVGRE;
        eg_md.lkp.tunnel_id = hdr.outer.nvgre.vsid;
    	transition parse_inner_ethernet;
    }


    //-------------------------------------------------------------------------
    // Encapsulating Security Payload (ESP) - Outer
    //-------------------------------------------------------------------------

    state parse_outer_esp {
        pkt.extract(hdr.outer.esp);
        transition accept;
    }


    //-------------------------------------------------------------------------
    // GPRS (General Packet Radio Service) Tunneling Protocol (GTP) - Outer
    //-------------------------------------------------------------------------
    // Based on pseudo code from Glenn (see email from 03/11/2019):

#ifdef GTP_ENABLE

    // GTP-C
    //-------------------------------------------------------------------------

    state parse_outer_gtp_c {
        gtp_v2_base_h snoop_gtp_v2_base = pkt.lookahead<gtp_v2_base_h>();
        transition select(snoop_gtp_v2_base.version, snoop_gtp_v2_base.T) {
            (2, 1): extract_outer_gtp_c;
            default: accept;
        }
    }

    state extract_outer_gtp_c {
        pkt.extract(hdr.outer.gtp_v2_base);
//      pkt.extract(hdr.outer.gtp_v2_teid);
        eg_md.tunnel_1.type = SWITCH_TUNNEL_TYPE_GTPC;
//      eg_md.tunnel_1.id = hdr.outer.gtp_v2_teid.teid;
        eg_md.lkp.tunnel_type = SWITCH_TUNNEL_TYPE_GTPC;
//      eg_md.lkp.tunnel_id = hdr.outer.gtp_v2_teid.teid;
    	transition accept;
    }


    // GTP-U
    //-------------------------------------------------------------------------
    // Does not support parsing GTP v1 optional word
    // Does not support parsing (TLV) extension headers

    state parse_outer_gtp_u {
        gtp_v1_base_h snoop_gtp_v1_base = pkt.lookahead<gtp_v1_base_h>();
        transition select(
            snoop_gtp_v1_base.version,
            snoop_gtp_v1_base.PT,
            snoop_gtp_v1_base.E,
            snoop_gtp_v1_base.S,
            snoop_gtp_v1_base.PN) {

            (1, 1, 0, 0, 0): extract_outer_gtp_u;
            default: accept;
        }
    }

    state extract_outer_gtp_u {
        pkt.extract(hdr.outer.gtp_v1_base);
//      pkt.extract(hdr.outer.gtp_v1_teid);
        eg_md.tunnel_1.type = SWITCH_TUNNEL_TYPE_GTPU;
//      eg_md.tunnel_1.id = hdr.outer.gtp_v1_teid.teid;
        eg_md.lkp.tunnel_type = SWITCH_TUNNEL_TYPE_GTPU;
//      eg_md.lkp.tunnel_id = hdr.outer.gtp_v1_teid.teid;
        transition select(pkt.lookahead<bit<4>>()) {
            4: parse_inner_ipv4;
            6: parse_inner_ipv6;
            default: accept;
        }
    }

#endif  /* GTP_ENABLE */



    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////
    // "Inner" Headers / Stack
    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////

    ///////////////////////////////////////////////////////////////////////////
    // Layer 2 (ETH-T) - Inner
    ///////////////////////////////////////////////////////////////////////////

    state parse_inner_ethernet {
        pkt.extract(hdr.inner.ethernet);
        transition select(hdr.inner.ethernet.ether_type) {
            ETHERTYPE_VLAN : parse_inner_vlan;
            ETHERTYPE_IPV4 : parse_inner_ipv4;
            ETHERTYPE_IPV6 : parse_inner_ipv6;
            default : accept;
        }
    }

    state parse_inner_vlan {
        pkt.extract(hdr.inner.vlan_tag[0]);
        transition select(hdr.inner.vlan_tag[0].ether_type) {
            ETHERTYPE_IPV4 : parse_inner_ipv4;
            ETHERTYPE_IPV6 : parse_inner_ipv6;
            default : accept;
        }
    }


    ///////////////////////////////////////////////////////////////////////////
    // Layer 3 - Inner
    ///////////////////////////////////////////////////////////////////////////

    state parse_inner_ipv4 {
        pkt.extract(hdr.inner.ipv4);
        inner_protocol = hdr.inner.ipv4.protocol;
        // Flag packet (to be sent to host) if it's a frag or has options.
        transition select(
            hdr.inner.ipv4.ihl,
            hdr.inner.ipv4.flags,
            hdr.inner.ipv4.frag_offset) {
            //(5, 0, 0): parse_inner_l3_protocol;
            //(5, 2, 0): parse_inner_l3_protocol;
            (5, 3w2 &&& 3w5, 0): parse_inner_l3_protocol;
            default: accept;
        }
    }

    state parse_inner_ipv6 {
#ifdef IPV6_ENABLE
        pkt.extract(hdr.inner.ipv6);
        inner_protocol = hdr.inner.ipv6.next_hdr;
        transition parse_inner_l3_protocol;
#else
        transition reject;
#endif
    }

    // shared fanout/branch state to save tcam resource
    state parse_inner_l3_protocol {
        transition select(inner_protocol) {
           IP_PROTOCOLS_UDP: parse_inner_udp;
           IP_PROTOCOLS_TCP: parse_inner_tcp;
           IP_PROTOCOLS_SCTP: parse_inner_sctp;
           // todo: encap doc shows no v6 branch for esp.
           // if true, we need to move this up into v4 state.
#ifdef PARDE_INNER_ESP_ENABLE
           IP_PROTOCOLS_ESP: parse_inner_esp;
#endif
#ifdef PARDE_INNER_GRE_ENABLE
           IP_PROTOCOLS_GRE: parse_inner_gre;
#endif

           default : accept;
       }
    }

    ///////////////////////////////////////////////////////////////////////////
    // Inner Layer 4 - Inner
    ///////////////////////////////////////////////////////////////////////////

    state parse_inner_udp {
        pkt.extract(hdr.inner.udp);
        transition accept;
    }

    state parse_inner_tcp {
        pkt.extract(hdr.inner.tcp);
        transition accept;
    }

    state parse_inner_sctp {
        pkt.extract(hdr.inner.sctp);
        transition accept;
    }    

    ///////////////////////////////////////////////////////////////////////////
    // Tunnels - Inner
    ///////////////////////////////////////////////////////////////////////////

#ifdef PARDE_INNER_ESP_ENABLE
    // todo: do we need to parse this? extract?
    state parse_inner_esp {
        pkt.extract(hdr.inner.esp);
        transition accept;
    }
#endif

#ifdef PARDE_INNER_GRE_ENABLE
    // todo: do we need to parse this? extract?
    state parse_inner_gre {
        pkt.extract(hdr.inner.gre);
        eg_md.tunnel_2.type = SWITCH_TUNNEL_TYPE_GRE;
        transition accept;
    }
#endif



// 
// ///////////////////////////////////////////////////////////////////////////////
// // Transport Encaps
// ///////////////////////////////////////////////////////////////////////////////
// 
// //-----------------------------------------------------------------------------
// // Encapsulated Remote Switch Port Analyzer (ERSPAN)
// //-----------------------------------------------------------------------------
// 
// state parse_erspan_t1 {
//     pkt.extract(hdr.erspan_type1);
//     //metadata.ingress_tunnel_type, INGRESS_TUNNEL_TYPE_ERSPAN_T1
//     transition parse_inner_ethernet;
// }
// 
// state parse_erspan_t2 {
//     pkt.extract(hdr.erspan_type2);
//     //verify(hdr.erspan_typeII.version == 1, error.Erspan2VersionNotOne);
//     //metadata.ingress_tunnel_type, INGRESS_TUNNEL_TYPE_ERSPAN_T2
//     transition parse_inner_ethernet;
// }
// 
// // state parse_erspan_t3 {
// //     pkt.extract(hdr.erspan_type3);
// //     //verify(hdr.erspan_typeIII.version == 2, error.Erspan3VersionNotTwo);
// //     //metadata.ingress_tunnel_type, INGRESS_TUNNEL_TYPE_ERSPAN_T3
// //     transition select(hdr.erspan_type3.o) {
// //         1: parse_erspan_type3_platform;
// //         default: parse_inner_ethernet;
// //     }
// // }
// // 
// // state parse_erspan_type3_platform {
// //     pkt.extract(hdr.erspan_platform);
// //     transition parse_inner_ethernet;
// // }
// 
// 


}

#endif /* _NPB_ENG_PARSER_ */
