#ifndef _NPB_ING_PARSER_
#define _NPB_ING_PARSER_

parser NpbIngressParser(
        packet_in pkt,
        out switch_header_t hdr,
        out switch_ingress_metadata_t ig_md,
        out ingress_intrinsic_metadata_t ig_intr_md) {

    //Checksum<bit<16>>(HashAlgorithm_t.CSUM16) ipv4_checksum;
    //Checksum<bit<16>>(HashAlgorithm_t.CSUM16) inner_ipv4_checksum;
    //Checksum<bit<16>>(ChecksumAlgorithm_t.CSUM16) ipv4_checksum;
    //Checksum<bit<16>>(ChecksumAlgorithm_t.CSUM16) inner_ipv4_checksum;
    Checksum() ipv4_checksum;
    Checksum() inner_ipv4_checksum;

    value_set<bit<16>>(1) udp_port_vxlan;

	bit<16> ether_type;
	bit<16> inner_ether_type;
	bit<8>  protocol;
	bit<8>  inner_protocol;

    state start {
        pkt.extract(ig_intr_md);
        ig_md.port      = ig_intr_md.ingress_port;
        ig_md.timestamp = ig_intr_md.ingress_mac_tstamp;
        // Check for resubmit flag if packet is resubmitted.
        // transition select(ig_intr_md.resubmit_flag) {
        //     1 : parse_resubmit;
        //     0 : parse_port_metadata;
        // }

        // initialize lookup struct to zeros
        ig_md.lkp.mac_src_addr = 0;
        ig_md.lkp.mac_dst_addr = 0;
        ig_md.lkp.mac_type = 0;
        ig_md.lkp.pcp = 0;
        ig_md.lkp.ip_type = SWITCH_IP_TYPE_NONE;
        ig_md.lkp.ip_proto = 0;
        ig_md.lkp.ip_tos = 0;
#ifdef BUG_10439_WORKAROUND
        ig_md.lkp.ip_src_addr_3 = 0;
        ig_md.lkp.ip_src_addr_2 = 0;
        ig_md.lkp.ip_src_addr_1 = 0;
        ig_md.lkp.ip_src_addr_0 = 0;
        ig_md.lkp.ip_dst_addr_3 = 0;
        ig_md.lkp.ip_dst_addr_2 = 0;
        ig_md.lkp.ip_dst_addr_1 = 0;
        ig_md.lkp.ip_dst_addr_0 = 0;
#else
        ig_md.lkp.ip_src_addr = 0;
        ig_md.lkp.ip_dst_addr = 0;
#endif // BUG_10439_WORKAROUND
        ig_md.lkp.ip_len = 0;
        ig_md.lkp.tcp_flags = 0;
        ig_md.lkp.l4_src_port = 0;
        ig_md.lkp.l4_dst_port = 0;
        ig_md.lkp.tunnel_type = 0;
        ig_md.lkp.tunnel_id = 0;
#ifdef UDF_ENABLE
        ig_md.lkp_l7_udf = 0;
#endif        
        ig_md.lkp.drop_reason = 0;

        // initialize lookup struct (2) to zeros
        ig_md.lkp_2.mac_src_addr = 0;
        ig_md.lkp_2.mac_dst_addr = 0;
        ig_md.lkp_2.mac_type = 0;
        ig_md.lkp_2.pcp = 0;
        ig_md.lkp_2.ip_type = SWITCH_IP_TYPE_NONE;
        ig_md.lkp_2.ip_proto = 0;
        ig_md.lkp_2.ip_tos = 0;
#ifdef BUG_10439_WORKAROUND
        ig_md.lkp_2.ip_src_addr_3 = 0;
        ig_md.lkp_2.ip_src_addr_2 = 0;
        ig_md.lkp_2.ip_src_addr_1 = 0;
        ig_md.lkp_2.ip_src_addr_0 = 0;
        ig_md.lkp_2.ip_dst_addr_3 = 0;
        ig_md.lkp_2.ip_dst_addr_2 = 0;
        ig_md.lkp_2.ip_dst_addr_1 = 0;
        ig_md.lkp_2.ip_dst_addr_0 = 0;
#else
        ig_md.lkp_2.ip_src_addr = 0;
        ig_md.lkp_2.ip_dst_addr = 0;
#endif // BUG_10439_WORKAROUND
        ig_md.lkp_2.ip_len = 0;
        ig_md.lkp_2.tcp_flags = 0;
        ig_md.lkp_2.l4_src_port = 0;
        ig_md.lkp_2.l4_dst_port = 0;
        ig_md.lkp_2.tunnel_type = 0;
        ig_md.lkp_2.tunnel_id = 0;
        ig_md.lkp_2.drop_reason = 0;

        transition parse_port_metadata;
    }

    state parse_resubmit {
        // Parse resubmitted packet here.
        transition reject;
    }

    state parse_port_metadata {
        // Parse port metadata produced by ibuf
        switch_port_metadata_t port_md = port_metadata_unpack<switch_port_metadata_t>(pkt);
        ig_md.port_lag_index = port_md.port_lag_index;
//      ig_md.ifindex = port_md.ifindex;
        //transition parse_ethernet;
        transition snoop_head;
    }

    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////
    // "Transport" Headers / Stack (L2-U)
    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////

    // Snoop ahead here to try and determine if there's a transport present
    state snoop_head {
        // transition select(
        //             pkt.lookahead<bit<112>>()[15:0],   // pkt.lookahead<head_snoop_h>().enet_ether_type;
        //             pkt.lookahead<bit<144>>()[15:0],   // pkt.lookahead<head_snoop_h>().vlan_ether_type;
        //             pkt.lookahead<bit<224>>()[7:0]) {  // pkt.lookahead<head_snoop_h>().ipv4_protocol;
        // 
        //     (ETHERTYPE_NSH , _            , _): parse_transport_nsh;
        //     (ETHERTYPE_VLAN, ETHERTYPE_NSH, _): parse_transport_nsh_tagged;
        //     default: parse_outer_ethernet;
        // }

        transition select(pkt.lookahead<bit<112>>()[15:0], pkt.lookahead<bit<144>>()[15:0]) {
            (ETHERTYPE_NSH, _): parse_transport_nsh;
            (ETHERTYPE_VLAN, ETHERTYPE_NSH): parse_transport_nsh_tagged;
            default: parse_outer_ethernet;
        }
    }

    //-------------------------------------------------------------------------
    // NSH - Transport
    //-------------------------------------------------------------------------

    state parse_transport_nsh {
        pkt.extract(hdr.transport.ethernet);
	    pkt.extract(hdr.transport.nsh_type1);
        ig_md.tunnel_0.type = SWITCH_TUNNEL_TYPE_NSH;
        transition parse_outer_ethernet;
    }

    state parse_transport_nsh_tagged {
        pkt.extract(hdr.transport.ethernet);
        pkt.extract(hdr.transport.vlan_tag.next);
	    pkt.extract(hdr.transport.nsh_type1);
        ig_md.tunnel_0.type = SWITCH_TUNNEL_TYPE_NSH;
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
    // more than once in Tofino1. Doing so causes a wire-OR instead of
    // clear-on-write. Because of this limitation, we're unable to use a
    // fanout/branch state at layer2.

    // We can still employ a fanout/branch state for e-tags and vn-tags, since
    // the two headers are mutually exclusive.

    state parse_outer_ethernet {
        pkt.extract(hdr.outer.ethernet);
        ig_md.lkp.mac_src_addr = hdr.outer.ethernet.src_addr;
        ig_md.lkp.mac_dst_addr = hdr.outer.ethernet.dst_addr;
        ig_md.lkp.mac_type     = hdr.outer.ethernet.ether_type;
        transition select(hdr.outer.ethernet.ether_type) {
            ETHERTYPE_BR : parse_outer_br;
            ETHERTYPE_VN : parse_outer_vn;
            ETHERTYPE_VLAN : parse_outer_vlan;
            ETHERTYPE_QINQ : parse_outer_vlan;
#ifdef MPLS_ENABLE
            ETHERTYPE_MPLS : parse_outer_mpls;
#endif
            ETHERTYPE_IPV4 : parse_outer_ipv4;
            ETHERTYPE_ARP  : parse_outer_arp;
            ETHERTYPE_IPV6 : parse_outer_ipv6;
            default : accept;
        }
    }

    state parse_outer_br {
	    pkt.extract(hdr.outer.e_tag);
        ether_type = hdr.outer.e_tag.ether_type;
        ig_md.lkp.mac_type = hdr.outer.e_tag.ether_type;        
        ig_md.lkp.pcp = hdr.outer.e_tag.pcp;        
        transition select(hdr.outer.e_tag.ether_type) {
            ETHERTYPE_VLAN : parse_outer_vlan;
            ETHERTYPE_QINQ : parse_outer_vlan;
            default : branch_outer_ether_type;
        }
    }

    state parse_outer_vn {
	    pkt.extract(hdr.outer.vn_tag);
        ether_type = hdr.outer.vn_tag.ether_type;
        ig_md.lkp.mac_type = hdr.outer.vn_tag.ether_type;
        transition select(hdr.outer.vn_tag.ether_type) {
            ETHERTYPE_VLAN : parse_outer_vlan;
            ETHERTYPE_QINQ : parse_outer_vlan;
            default : branch_outer_ether_type;
        }
    }

    state parse_outer_vlan {
	    pkt.extract(hdr.outer.vlan_tag.next);
        ig_md.lkp.mac_type = hdr.outer.vlan_tag.last.ether_type;
        ig_md.lkp.pcp      = hdr.outer.vlan_tag.last.pcp;
        transition select(hdr.outer.vlan_tag.last.ether_type) {
            ETHERTYPE_VLAN : parse_outer_vlan;
            ETHERTYPE_QINQ : parse_outer_vlan;
#ifdef MPLS_ENABLE
            ETHERTYPE_MPLS : parse_outer_mpls;
#endif
            ETHERTYPE_IPV4 : parse_outer_ipv4;
            ETHERTYPE_ARP  : parse_outer_arp;
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
            ETHERTYPE_ARP  : parse_outer_arp;
            ETHERTYPE_IPV6 : parse_outer_ipv6;
            default : accept;
        }
    }


    ///////////////////////////////////////////////////////////////////////////
    // Layer 2.5 - Outer
    ///////////////////////////////////////////////////////////////////////////

    state parse_outer_arp {
        pkt.extract(hdr.outer.arp);
        transition accept;
    }


    ///////////////////////////////////////////////////////////////////////////
    // Layer 3 - Outer
    ///////////////////////////////////////////////////////////////////////////

    state parse_outer_ipv4 {
        pkt.extract(hdr.outer.ipv4);
        protocol = hdr.outer.ipv4.protocol;
        // todo: should the lkp struct be set in state parse_outer_ipv4_no_options_frags instead?
        ig_md.lkp.ip_type       = SWITCH_IP_TYPE_IPV4;
        ig_md.lkp.ip_proto      = hdr.outer.ipv4.protocol;
        ig_md.lkp.ip_tos        = hdr.outer.ipv4.tos;
#ifdef BUG_10439_WORKAROUND
        ig_md.lkp.ip_src_addr_0 = hdr.outer.ipv4.src_addr;
        ig_md.lkp.ip_dst_addr_0 = hdr.outer.ipv4.dst_addr;
#else
        ig_md.lkp.ip_src_addr   = (bit<128>)hdr.outer.ipv4.src_addr;
        ig_md.lkp.ip_dst_addr   = (bit<128>)hdr.outer.ipv4.dst_addr;
#endif // BUG_10439_WORKAROUND
        ig_md.lkp.ip_len        = hdr.outer.ipv4.total_len;
        // Flag packet (to be sent to host) if it's a frag or has options.
        ipv4_checksum.add(hdr.outer.ipv4);
        transition select(hdr.outer.ipv4.ihl, hdr.outer.ipv4.flags, hdr.outer.ipv4.frag_offset) {
            (5, 3w2 &&& 3w5, 0): parse_outer_ipv4_no_options_frags;
            default : accept;
        }
    }

    state parse_outer_ipv4_no_options_frags {
        ig_md.flags.ipv4_checksum_err_1 = ipv4_checksum.verify();
        transition select(hdr.outer.ipv4.protocol) {
            IP_PROTOCOLS_ICMP: parse_outer_icmp;
            IP_PROTOCOLS_IGMP: parse_outer_igmp;
            default: branch_outer_l3_protocol;
        }
    }

    state parse_outer_ipv6 {
#ifdef IPV6_ENABLE
        pkt.extract(hdr.outer.ipv6);
        protocol = hdr.outer.ipv6.next_hdr;
        ig_md.lkp.ip_type       = SWITCH_IP_TYPE_IPV6;
        ig_md.lkp.ip_proto      = hdr.outer.ipv6.next_hdr;
        //ig_md.lkp.ip_tos        = hdr.outer.ipv6.tos; // not byte-aligned so set in mau
#ifdef BUG_10439_WORKAROUND
        ig_md.lkp.ip_src_addr_3 = hdr.outer.ipv6.src_addr_3;
        ig_md.lkp.ip_src_addr_2 = hdr.outer.ipv6.src_addr_2;
        ig_md.lkp.ip_src_addr_1 = hdr.outer.ipv6.src_addr_1;
        ig_md.lkp.ip_src_addr_0 = hdr.outer.ipv6.src_addr_0;
        ig_md.lkp.ip_dst_addr_3 = hdr.outer.ipv6.dst_addr_3;
        ig_md.lkp.ip_dst_addr_2 = hdr.outer.ipv6.dst_addr_2;
        ig_md.lkp.ip_dst_addr_1 = hdr.outer.ipv6.dst_addr_1;
        ig_md.lkp.ip_dst_addr_0 = hdr.outer.ipv6.dst_addr_0;
#else
        ig_md.lkp.ip_src_addr   = hdr.outer.ipv6.src_addr;
        ig_md.lkp.ip_dst_addr   = hdr.outer.ipv6.dst_addr;
#endif // BUG_10439_WORKAROUND
        ig_md.lkp.ip_len        = hdr.outer.ipv6.payload_len;
        transition select(hdr.outer.ipv6.next_hdr) {
            IP_PROTOCOLS_ICMPV6: parse_outer_icmp;
            default: branch_outer_l3_protocol;
        }
#else
        transition reject;
#endif
    }

    // shared fanout/branch state to save tcam resource
    state branch_outer_l3_protocol {
        transition select(protocol) {
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

    state parse_outer_icmp {
        pkt.extract(hdr.outer.icmp);
        transition accept;
    }

    state parse_outer_igmp {
        pkt.extract(hdr.outer.igmp);
        transition accept;
    }



    ///////////////////////////////////////////////////////////////////////////
    // Layer 4 - Outer
    ///////////////////////////////////////////////////////////////////////////

    //-------------------------------------------------------------------------
    // User Datagram Protocol (UDP) - Outer
    //-------------------------------------------------------------------------

    state parse_outer_udp {
        pkt.extract(hdr.outer.udp);
        ig_md.lkp.l4_src_port = hdr.outer.udp.src_port;
        ig_md.lkp.l4_dst_port = hdr.outer.udp.dst_port;       
        transition select(hdr.outer.udp.src_port, hdr.outer.udp.dst_port) {
            (_, UDP_PORT_VXLAN): parse_outer_vxlan;
#ifdef GTP_ENABLE
            (_, UDP_PORT_GTP_C): parse_outer_gtp_c;
            (UDP_PORT_GTP_C, _): parse_outer_gtp_c;
            (_, UDP_PORT_GTP_U): parse_outer_gtp_u;
            (UDP_PORT_GTP_U, _): parse_outer_gtp_u;
#endif  /* GTP_ENABLE */
            default : parse_layer7_udf;
        }
    }

    //-------------------------------------------------------------------------
    // Transmission Control Protocol (TCP) - Outer
    //-------------------------------------------------------------------------

    state parse_outer_tcp {
        pkt.extract(hdr.outer.tcp);
        ig_md.lkp.l4_src_port = hdr.outer.tcp.src_port;
        ig_md.lkp.l4_dst_port = hdr.outer.tcp.dst_port;
        ig_md.lkp.tcp_flags   = hdr.outer.tcp.flags;
        transition parse_layer7_udf;
    }

    //-------------------------------------------------------------------------
    // Stream Control Transmission Protocol (SCTP) - Outer
    //-------------------------------------------------------------------------

    state parse_outer_sctp {
        pkt.extract(hdr.outer.sctp);
        ig_md.lkp.l4_src_port = hdr.outer.sctp.src_port;
        ig_md.lkp.l4_dst_port = hdr.outer.sctp.dst_port;
        transition parse_layer7_udf;
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
        ig_md.tunnel_1.type = SWITCH_TUNNEL_TYPE_VXLAN;
        ig_md.tunnel_1.id = hdr.outer.vxlan.vni;
        ig_md.lkp.tunnel_type = SWITCH_TUNNEL_TYPE_VXLAN;
        ig_md.lkp.tunnel_id = hdr.outer.vxlan.vni;
        transition parse_inner_ethernet; 
#else
        transition accept;
#endif
    }


    //-------------------------------------------------------------------------
    // Internet Protocol (IP) - Outer
    //-------------------------------------------------------------------------

    state parse_outer_ipinip_set_tunnel_type {
#ifdef IPINIP
        ig_md.tunnel_1.type = SWITCH_TUNNEL_TYPE_IPINIP;
        ig_md.lkp.tunnel_type = SWITCH_TUNNEL_TYPE_IPINIP;
        transition parse_inner_ipv4;
#else
        transition accept;
#endif /* IPINIP */
    }

    state parse_outer_ipv6inip_set_tunnel_type {
#ifdef IPINIP
        ig_md.tunnel_1.type = SWITCH_TUNNEL_TYPE_IPINIP;
        ig_md.lkp.tunnel_type = SWITCH_TUNNEL_TYPE_IPINIP;
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
        ig_md.tunnel_1.type = SWITCH_TUNNEL_TYPE_GRE;
        ig_md.lkp.tunnel_type = SWITCH_TUNNEL_TYPE_GRE;
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
// #ifdef ERSPAN_TRANSPORT_ENABLE
//             (0,0,0,0,GRE_PROTOCOLS_ERSPAN_TYPE_2): parse_erspan_t1_transport;
//             (0,0,1,0,GRE_PROTOCOLS_ERSPAN_TYPE_2): parse_erspan_t2_transport;
//             //(0,0,1,0,GRE_PROTOCOLS_ERSPAN_TYPE_3): parse_erspan_t3_transport;
// #endif /* ERSPAN_TRANSPORT_ENABLE */            
            default: accept;
        }
    }

    
    //-------------------------------------------------------------------------
    // Network Virtualization using GRE (NVGRE) - Outer
    //-------------------------------------------------------------------------

    state parse_outer_nvgre {
    	pkt.extract(hdr.outer.nvgre);
        ig_md.tunnel_1.type = SWITCH_TUNNEL_TYPE_NVGRE;
		ig_md.tunnel_1.id = hdr.outer.nvgre.vsid;
        ig_md.lkp.tunnel_type = SWITCH_TUNNEL_TYPE_NVGRE;
        ig_md.lkp.tunnel_id = hdr.outer.nvgre.vsid;
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

    // state parse_outer_gtp_c {
    //     pkt.extract(hdr.outer.gtp_v2_base);
    //     transition select(hdr.outer.gtp_v2_base.version, hdr.outer.gtp_v2_base.T) {
    //         (2, 1): parse_outer_gtp_c_tied;
    //         default: accept;
    //     }
    // }
    // 
    // state parse_outer_gtp_c_teid {
    //     pkt.extract(hdr.outer.teid);
    // 	transition accept;
    // }

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
        ig_md.tunnel_1.type = SWITCH_TUNNEL_TYPE_GTPC;
//      ig_md.tunnel_1.id = hdr.outer.gtp_v2_teid.teid;
        ig_md.lkp.tunnel_type = SWITCH_TUNNEL_TYPE_GTPC;
//      ig_md.lkp.tunnel_id = hdr.outer.gtp_v2_teid.teid;
    	transition accept;
    }

    // GTP-U
    //-------------------------------------------------------------------------
    // Does not support parsing GTP v1 optional word
    // Does not support parsing (TLV) extension headers

    // state parse_outer_gtp_u {
    //     pkt.extract(hdr.outer.gtp_v1_base);
    //     transition select(
    //         hdr.outer.gtp_v1_base.version,
    //         hdr.outer.gtp_v1_base.PT,
    //         hdr.outer.gtp_v1_base.E,
    //         hdr.outer.gtp_v1_base.S,
    //         hdr.outer.gtp_v1_base.PN
    //         pkt.lookahead<bit<4>>()) {
    // 
    //         (1, 1, 0, 0, 0, 4): parse_inner_ipv4;
    //         (1, 1, 0, 0, 0, 6): parse_inner_ipv6;
    //         default: accept;
    //     }
    // }

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
        ig_md.tunnel_1.type = SWITCH_TUNNEL_TYPE_GTPU;
//      ig_md.tunnel_1.id = hdr.outer.gtp_v1_teid.teid;
        ig_md.lkp.tunnel_type = SWITCH_TUNNEL_TYPE_GTPU;
//      ig_md.lkp.tunnel_id = hdr.outer.gtp_v1_teid.teid;
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
        ig_md.lkp_2.mac_src_addr = hdr.inner.ethernet.src_addr;
        ig_md.lkp_2.mac_dst_addr = hdr.inner.ethernet.dst_addr;
        ig_md.lkp_2.mac_type     = hdr.inner.ethernet.ether_type;

        transition select(hdr.inner.ethernet.ether_type) {
#ifdef PARDE_INNER_CONTROL_ENABLE
            ETHERTYPE_ARP : parse_inner_arp;
#endif
            ETHERTYPE_VLAN : parse_inner_vlan;
            ETHERTYPE_IPV4 : parse_inner_ipv4;
            ETHERTYPE_IPV6 : parse_inner_ipv6;
            default : accept;
        }
    }

    state parse_inner_vlan {
        pkt.extract(hdr.inner.vlan_tag[0]);
        ig_md.lkp_2.mac_type = hdr.inner.vlan_tag[0].ether_type;
        ig_md.lkp_2.pcp      = hdr.inner.vlan_tag[0].pcp;
        
        transition select(hdr.inner.vlan_tag[0].ether_type) {
#ifdef PARDE_INNER_CONTROL_ENABLE
            ETHERTYPE_ARP : parse_inner_arp;
#endif
            ETHERTYPE_IPV4 : parse_inner_ipv4;
            ETHERTYPE_IPV6 : parse_inner_ipv6;
            default : accept;
        }
    }


    ///////////////////////////////////////////////////////////////////////////
    // Layer 2.5 - Inner
    ///////////////////////////////////////////////////////////////////////////

#ifdef PARDE_INNER_CONTROL_ENABLE
    state parse_inner_arp {
        pkt.extract(hdr.inner.arp);
        transition accept;
    }
#endif


    ///////////////////////////////////////////////////////////////////////////
    // Layer 3 - Inner
    ///////////////////////////////////////////////////////////////////////////

    state parse_inner_ipv4 {
        pkt.extract(hdr.inner.ipv4);
        inner_protocol = hdr.inner.ipv4.protocol;

        // todo: should the lkp struct be set in state parse_outer_ipv4_no_options_frags instead?
        ig_md.lkp_2.ip_type       = SWITCH_IP_TYPE_IPV4;
        ig_md.lkp_2.ip_proto      = hdr.inner.ipv4.protocol;
        ig_md.lkp_2.ip_tos        = hdr.inner.ipv4.tos;
#ifdef BUG_10439_WORKAROUND
        ig_md.lkp_2.ip_src_addr_0 = hdr.inner.ipv4.src_addr;
        ig_md.lkp_2.ip_dst_addr_0 = hdr.inner.ipv4.dst_addr;
#else
        ig_md.lkp_2.ip_src_addr   = (bit<128>)hdr.inner.ipv4.src_addr;
        ig_md.lkp_2.ip_dst_addr   = (bit<128>)hdr.inner.ipv4.dst_addr;
#endif // BUG_10439_WORKAROUND
        ig_md.lkp_2.ip_len        = hdr.inner.ipv4.total_len;
        
        // Flag packet (to be sent to host) if it's a frag or has options.
        inner_ipv4_checksum.add(hdr.inner.ipv4);
        transition select(
            hdr.inner.ipv4.ihl,
            hdr.inner.ipv4.flags,
            hdr.inner.ipv4.frag_offset) {
            //(5, 0, 0): parse_inner_ipv4_no_options_frags;
            //(5, 2, 0): parse_inner_ipv4_no_options_frags;
            (5, 3w2 &&& 3w5, 0): parse_inner_ipv4_no_options_frags;
            default: accept;
        }
    }

    state parse_inner_ipv4_no_options_frags {
        ig_md.flags.ipv4_checksum_err_2 = inner_ipv4_checksum.verify();
        transition select(hdr.inner.ipv4.protocol) {
#ifdef PARDE_INNER_CONTROL_ENABLE
            IP_PROTOCOLS_ICMP: parse_inner_icmp;
            IP_PROTOCOLS_IGMP: parse_inner_igmp;
#endif
            default: branch_inner_l3_protocol;
        }
    }

    
    state parse_inner_ipv6 {
#ifdef IPV6_ENABLE
        pkt.extract(hdr.inner.ipv6);
        inner_protocol = hdr.inner.ipv6.next_hdr;

        ig_md.lkp_2.ip_type       = SWITCH_IP_TYPE_IPV6;
        ig_md.lkp_2.ip_proto      = hdr.inner.ipv6.next_hdr;
        //ig_md.lkp_2.ip_tos        = hdr.inner.ipv6.tos; // not byte-aligned so set in mau
#ifdef BUG_10439_WORKAROUND
        ig_md.lkp_2.ip_src_addr_3 = hdr.inner.ipv6.src_addr_3;
        ig_md.lkp_2.ip_src_addr_2 = hdr.inner.ipv6.src_addr_2;
        ig_md.lkp_2.ip_src_addr_1 = hdr.inner.ipv6.src_addr_1;
        ig_md.lkp_2.ip_src_addr_0 = hdr.inner.ipv6.src_addr_0;
        ig_md.lkp_2.ip_dst_addr_3 = hdr.inner.ipv6.dst_addr_3;
        ig_md.lkp_2.ip_dst_addr_2 = hdr.inner.ipv6.dst_addr_2;
        ig_md.lkp_2.ip_dst_addr_1 = hdr.inner.ipv6.dst_addr_1;
        ig_md.lkp_2.ip_dst_addr_0 = hdr.inner.ipv6.dst_addr_0;
#else
        ig_md.lkp_2.ip_src_addr   = hdr.inner.ipv6.src_addr;
        ig_md.lkp_2.ip_dst_addr   = hdr.inner.ipv6.dst_addr;
#endif // BUG_10439_WORKAROUND
        ig_md.lkp_2.ip_len        = hdr.inner.ipv6.payload_len;

        transition select(hdr.inner.ipv6.next_hdr) {
#ifdef PARDE_INNER_CONTROL_ENABLE
            IP_PROTOCOLS_ICMPV6: parse_inner_icmp;
#endif
            default: branch_inner_l3_protocol;
        }
#else
        transition reject;
#endif
    }

    // shared fanout/branch state to save tcam resource
    state branch_inner_l3_protocol {
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

#ifdef PARDE_INNER_CONTROL_ENABLE
    state parse_inner_icmp {
        pkt.extract(hdr.inner.icmp);
        transition accept;
    }

    state parse_inner_igmp {
        pkt.extract(hdr.inner.igmp);
        transition accept;
    }
#endif


    ///////////////////////////////////////////////////////////////////////////
    // Inner Layer 4 - Inner
    ///////////////////////////////////////////////////////////////////////////

    state parse_inner_udp {
        pkt.extract(hdr.inner.udp);
        ig_md.lkp_2.l4_src_port = hdr.inner.udp.src_port;
        ig_md.lkp_2.l4_dst_port = hdr.inner.udp.dst_port; 
        transition parse_layer7_udf;
    }

    state parse_inner_tcp {
        pkt.extract(hdr.inner.tcp);
        ig_md.lkp_2.l4_src_port = hdr.inner.tcp.src_port;
        ig_md.lkp_2.l4_dst_port = hdr.inner.tcp.dst_port;
        ig_md.lkp_2.tcp_flags   = hdr.inner.tcp.flags;        
        transition parse_layer7_udf;
    }

    state parse_inner_sctp {
        pkt.extract(hdr.inner.sctp);
        ig_md.lkp_2.l4_src_port = hdr.inner.sctp.src_port;
        ig_md.lkp_2.l4_dst_port = hdr.inner.sctp.dst_port;
        transition parse_layer7_udf;
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
        ig_md.tunnel_2.type = SWITCH_TUNNEL_TYPE_GRE;
        ig_md.lkp_2.tunnel_type = SWITCH_TUNNEL_TYPE_GRE;
        transition accept;
    }
#endif


    ///////////////////////////////////////////////////////////////////////////
    // Layer 7 - UDF
    ///////////////////////////////////////////////////////////////////////////

    state parse_layer7_udf {
#ifdef UDF_ENABLE
        ig_md.parse_udf_reached = 1;
        ig_md.lkp_l7_udf = hdr.l7_udf.opaque;
        //ig_md.lkp_2.l7_udf = hdr.l7_udf.opaque;  // only populate the lkp version of this (not lkp2)
        pkt.extract(hdr.l7_udf);
#endif  /* UDF_ENABLE */
        transition accept;
    }
}

#endif /* _NPB_ING_PARSER_ */

