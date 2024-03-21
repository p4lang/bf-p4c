#ifndef _NPB_EGR_PARSER_
#define _NPB_EGR_PARSER_

#include "npb_sub_parsers.p4"

parser NpbEgressParser(
        packet_in pkt,
        out switch_header_t hdr,
        out switch_egress_metadata_t eg_md,
        out egress_intrinsic_metadata_t eg_intr_md) {

    ParserUnderlayL2() parser_underlay_l2;

	bit<16> ether_type;
	bit<16> inner_ether_type;
	bit<8>  protocol;
	bit<8>  inner_protocol;


    state start {
        pkt.extract(eg_intr_md);
        eg_md.pkt_length = eg_intr_md.pkt_length;
#ifdef MIRROR_ENABLE
        switch_port_mirror_metadata_h mirror_md = pkt.lookahead<switch_port_mirror_metadata_h>();
        transition select(mirror_md.src, mirror_md.type) {
            (SWITCH_PKT_SRC_BRIDGE, _) : parse_bridged_metadata;
            (_, SWITCH_MIRROR_TYPE_PORT) : parse_port_mirrored_metadata;
            (SWITCH_PKT_SRC_CLONE_EGRESS, SWITCH_MIRROR_TYPE_CPU) : parse_cpu_mirrored_metadata;
        }
#else
        transition parse_bridged_metadata;
#endif
    }

    state parse_bridged_metadata {
        pkt.extract(hdr.bridged_md);
        eg_md.pkt_src = SWITCH_PKT_SRC_BRIDGE;
        eg_md.ingress_port = hdr.bridged_md.ingress_port;
        eg_md.ingress_ifindex = hdr.bridged_md.ingress_ifindex;
        eg_md.bd = hdr.bridged_md.ingress_bd;
        eg_md.nexthop = hdr.bridged_md.nexthop;
        eg_md.qos.tc = hdr.bridged_md.tc;
        eg_md.cpu_reason = hdr.bridged_md.cpu_reason;
        eg_md.flags.routed = (bool) hdr.bridged_md.routed;
        eg_md.flags.peer_link = (bool) hdr.bridged_md.peer_link;
        eg_md.flags.capture_ts = (bool) hdr.bridged_md.capture_ts;
        eg_md.tunnel.terminate = (bool) hdr.bridged_md.tunnel_terminate;
        eg_md.pkt_type = hdr.bridged_md.pkt_type;
        eg_md.timestamp = hdr.bridged_md.timestamp;
        eg_md.qos.qid = hdr.bridged_md.qid;

#ifdef EGRESS_ACL_ENABLE
        eg_md.l4_port_label = hdr.bridged_md.l4_port_label;
#endif

#ifdef TUNNEL_ENABLE
        pkt.extract(hdr.bridged_tunnel_md);
        eg_md.outer_nexthop = hdr.bridged_tunnel_md.outer_nexthop;
        eg_md.tunnel.index = hdr.bridged_tunnel_md.index;
        eg_md.tunnel.hash = hdr.bridged_tunnel_md.hash;
#endif
        // Set bridged metadata here.

        // -----------------------------
        // ----- EXTREME NETWORKS -----
        // -----------------------------
        eg_md.orig_pkt_had_nsh                       = hdr.bridged_md.orig_pkt_had_nsh;

        eg_md.nsh_extr.valid                         = hdr.bridged_md.nsh_extr_valid;
        eg_md.nsh_extr.end_of_chain                  = hdr.bridged_md.nsh_extr_end_of_chain;

        // base: word 0

        // base: word 1
        eg_md.nsh_extr.spi                           = hdr.bridged_md.nsh_extr_spi;
        eg_md.nsh_extr.si                            = hdr.bridged_md.nsh_extr_si;

        // ext: type 2 - word 0

        // ext: type 2 - word 1+
        eg_md.nsh_extr.extr_srvc_func_bitmask_local  = hdr.bridged_md.nsh_extr_srvc_func_bitmask_local;  //  1 byte
        eg_md.nsh_extr.extr_srvc_func_bitmask_remote = hdr.bridged_md.nsh_extr_srvc_func_bitmask_remote; //  1 byte
        eg_md.nsh_extr.extr_tenant_id                = hdr.bridged_md.nsh_extr_tenant_id;                //  3 bytes
        eg_md.nsh_extr.extr_flow_type                = hdr.bridged_md.nsh_extr_flow_type;                //  1 byte?

        // -----------------------------

        //transition accept;
        //transition snoop_underlay;
        //transition select(eg_md.nsh_extr.valid) {
        transition select(eg_md.orig_pkt_had_nsh) {
            0: parse_underlay_l2_ethernet;
            1: parse_underlay_nsh;
        }
    }

/*
    state parse_mirrored_packet {
        pkt.extract(eg_md.mirror);
        eg_md.pkt_src = eg_md.mirror.src;
        pkt.extract(hdr.ethernet);
        transition accept;
    }
*/

    state parse_port_mirrored_metadata {
        switch_port_mirror_metadata_h md;
        pkt.extract(md);
        pkt.extract(hdr.ethernet);
        eg_md.pkt_src = md.src;
#if __TARGET_TOFINO__ == 1
        eg_md.mirror.session_id = md.session_id[9:0];
#else
        eg_md.mirror.session_id = md.session_id[7:0];
#endif
        // eg_md.mirror.session_id = (switch_mirror_session_t) md.session_id;
        eg_md.timestamp = md.timestamp;
        transition accept;
    }

    state parse_cpu_mirrored_metadata {
        switch_cpu_mirror_metadata_h md;
        pkt.extract(md);
        eg_md.bd = (switch_bd_t) md.bd;
        // eg_md.ingress_port = (switch_port_t) md.port;
        // eg_md.ingress_ifindex = (switch_ifindex_t) md.ifindex;
        eg_md.cpu_reason = (switch_cpu_reason_t) md.reason_code;
        transition accept;
    }


    ///////////////////////////////////////////////////////////////////////////
    // L2 Underlay (L2-U)
    ///////////////////////////////////////////////////////////////////////////

    state parse_underlay_nsh {
        pkt.extract(hdr.nsh_extr_underlay);
        transition parse_underlay_l2_ethernet;
    }


    // Subparsers are broken in v8.7.0:
    // Any data set down in the subparser, except maybe header extractions,
    // will not be visible up here in the main parser.
    // 
    // // shared fanout/branch state to save tcam resource
    // state parse_underlay_l2 {
    //     parser_underlay_l2.apply(pkt, hdr, ether_type);
    //     transition select(ether_type) {
    //         ETHERTYPE_MPLS : parse_mpls;
    //         ETHERTYPE_IPV4 : parse_ipv4;
    //         ETHERTYPE_IPV6 : parse_ipv6;
    //         default : accept;
    //     }
    // }

    ///////////////////////////////////////////////////////////////////////////
    state parse_underlay_l2_ethernet {
        pkt.extract(hdr.ethernet);
        ether_type = hdr.ethernet.ether_type;
        transition select(hdr.ethernet.ether_type) {
            ETHERTYPE_BR : parse_underlay_l2_br;
            ETHERTYPE_VN : parse_underlay_l2_vn;
            ETHERTYPE_VLAN : parse_underlay_l2_vlan;
            ETHERTYPE_QINQ : parse_underlay_l2_vlan;
            default : parse_underlay_l2_ether_type;
        }
    }

    state parse_underlay_l2_br {
	    pkt.extract(hdr.e_tag);
        ether_type = hdr.e_tag.ether_type;
        transition select(hdr.e_tag.ether_type) {
            ETHERTYPE_VLAN : parse_underlay_l2_vlan;
            ETHERTYPE_QINQ : parse_underlay_l2_vlan;
            default : parse_underlay_l2_ether_type;
        }
    }

    state parse_underlay_l2_vn {
	    pkt.extract(hdr.vn_tag);
        ether_type = hdr.vn_tag.ether_type;
        transition select(hdr.vn_tag.ether_type) {
            ETHERTYPE_VLAN : parse_underlay_l2_vlan;
            ETHERTYPE_QINQ : parse_underlay_l2_vlan;
            default : parse_underlay_l2_ether_type;
        }
    }

    state parse_underlay_l2_vlan {
	    pkt.extract(hdr.vlan_tag.next);
        ether_type = hdr.vlan_tag.last.ether_type;
        transition select(hdr.vlan_tag.last.ether_type) {
            ETHERTYPE_VLAN : parse_underlay_l2_vlan;
            ETHERTYPE_QINQ : parse_underlay_l2_vlan;
            default : parse_underlay_l2_ether_type;
        }
    }

    // shared fanout/branch state to save tcam resource
    state parse_underlay_l2_ether_type {
        transition select(ether_type) {
            ETHERTYPE_MPLS : parse_mpls;
            ETHERTYPE_IPV4 : parse_ipv4;
            ETHERTYPE_IPV6 : parse_ipv6;
            default : accept;
        }
    }


    ///////////////////////////////////////////////////////////////////////////
    // Layer 3 (Network)
    ///////////////////////////////////////////////////////////////////////////

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        protocol = hdr.ipv4.protocol;
        // Flag packet (to be sent to host) if it's a frag or has options.
        transition select(hdr.ipv4.ihl, hdr.ipv4.flags, hdr.ipv4.frag_offset) {
            //(5, 0, 0) : parse_l3_protocol;
            //(5, 2, 0) : parse_l3_protocol;
            (5, 3w2 &&& 3w5, 0): parse_l3_protocol;
            default : accept;
        }
    }

    state parse_ipv6 {
#ifdef IPV6_ENABLE
        pkt.extract(hdr.ipv6);
        protocol = hdr.ipv6.next_hdr;
        transition parse_l3_protocol;
#else
        transition reject;
#endif
    }

    // shared fanout/branch state to save tcam resource
    state parse_l3_protocol {
        transition select(protocol) {
//#if defined(IPINIP) && defined(IPV6_TUNNEL_ENABLE)
           IP_PROTOCOLS_IPV4: parse_inner_ipv4;
           IP_PROTOCOLS_IPV6: parse_inner_ipv6;
//#endif
           IP_PROTOCOLS_UDP: parse_udp;
           IP_PROTOCOLS_TCP: parse_tcp;
           IP_PROTOCOLS_SCTP: parse_sctp;
           // todo: encap doc shows no v6 branch for esp.
           // if true, we need to move this up into v4 state.
           IP_PROTOCOLS_ESP: parse_esp;
           IP_PROTOCOLS_GRE: parse_gre;
           default : accept;
       }
    }


    ///////////////////////////////////////////////////////////////////////////
    // Layer 4 (Transport)
    ///////////////////////////////////////////////////////////////////////////

    state parse_udp {
        pkt.extract(hdr.udp);
        transition select(hdr.udp.dst_port) {
            UDP_PORT_VXLAN: parse_vxlan;
            UDP_PORT_GTP_C: parse_gtp;  // todo: src port too?
            UDP_PORT_GTP_U: parse_gtp;  // todo: src port too?
            default : accept;
        }
    }

    state parse_tcp {
        pkt.extract(hdr.tcp);
        transition accept;
    }

    state parse_sctp {
        pkt.extract(hdr.sctp);
        transition accept;
    }


    ///////////////////////////////////////////////////////////////////////////////
    // Layer X
    ///////////////////////////////////////////////////////////////////////////////
        
    state parse_mpls {
#ifdef MPLS_ENABLE
    	pkt.extract(hdr.mpls.next);
        transition select(hdr.mpls.last.bos, pkt.lookahead<bit<4>>()) {
            (0, _): parse_mpls;
            (1, 4): parse_inner_ipv4;
            (1, 6): parse_inner_ipv6;
            default: parse_eompls;
        }
#else
        transition accept;
#endif  /* MPLS_ENABLE */
    }
    
#ifdef MPLS_ENABLE
    state parse_eompls {
        pkt.extract(hdr.mpls_pw_cw); 
        transition  parse_inner_ethernet;
    }
#endif  /* MPLS_ENABLE */




    ///////////////////////////////////////////////////////////////////////////
    // Tunnels
    ///////////////////////////////////////////////////////////////////////////

    state parse_vxlan {
#ifdef VXLAN_ENABLE
        pkt.extract(hdr.vxlan);
        transition parse_inner_ethernet;
#else
        transition reject;
#endif
    }

    state parse_gre {
    	pkt.extract(hdr.gre);
        //todo: verify(hdr.gre.version == 0, error.GreVersionNotZero);
        // todo: eg_md.tunnel.type = SWITCH_TUNNEL_TYPE_GRE;
        transition select(
            hdr.gre.C,
            hdr.gre.R,
            hdr.gre.K,
            hdr.gre.S,
            hdr.gre.s,
            hdr.gre.recurse,
            hdr.gre.version,
            hdr.gre.proto) {
        
            (0,0,1,0,0,0,0,GRE_PROTOCOLS_NVGRE): parse_nvgre;
            (0,0,0,0,0,0,0,ETHERTYPE_MPLS): parse_mpls;
            (0,0,0,0,0,0,0,ETHERTYPE_IPV4): parse_inner_ipv4;
            (0,0,0,0,0,0,0,ETHERTYPE_IPV6): parse_inner_ipv6;
            //(0,0,0,0,0,0,0,GRE_PROTOCOLS_ERSPAN_TYPE_2): parse_erspan_t1;
            //(0,0,0,1,0,0,0,GRE_PROTOCOLS_ERSPAN_TYPE_2): parse_erspan_t2;
            //(0,0,0,1,0,0,0,GRE_PROTOCOLS_ERSPAN_TYPE_3): parse_erspan_t3;
            default: accept;
        }
    }

    state parse_nvgre {
    	pkt.extract(hdr.nvgre);
        // todo: eg_md.tunnel.type = SWITCH_TUNNEL_TYPE_NVGRE;
    	transition parse_inner_ethernet;
    }

    state parse_esp {
        pkt.extract(hdr.esp);
        // todo: eg_md.tunnel.type = SWITCH_TUNNEL_TYPE_ESP;
        transition accept;
    }


    //-------------------------------------------------------------------------
    // GPRS (General Packet Radio Service) Tunneling Protocol (GTP)
    //-------------------------------------------------------------------------
    // Based on pseudo code from Glenn (see email from 02/11/2019):
    // Does not support parsing GTP optional word
    // Does not support parsing (TLV) extension headers

    // todo: create subparser for this
    // use metadata ing_tunnel_type to determine if we need to continue parsing
    // when I tried subparser, the compiler complained w/ the following:
    //   Unimplemented compiler support: Local metadata array hdr_2_vlan_tag not supported

    // state parse_gtp {
    //     //parser_gtp.apply(pkt, eg_md, hdr);
    //     parser_gtp.apply(pkt, eg_md.tunnel.type, hdr);
    // 	transition select(eg_md.tunnel.type, pkt.lookahead<bit<4>>()) {
    //         (SWITCH_TUNNEL_TYPE_GTP_U, 4): parse_inner_ipv4;
    //         (SWITCH_TUNNEL_TYPE_GTP_U, 6): parse_inner_ipv6;
    //         default: accept;
    //     }
    // }

    state parse_gtp {
        // todo: Flag frame (to be trapped) if version > 2
#ifdef GTP_ENABLE
        transition select(pkt.lookahead<bit<4>>()) { //version,PT
            5: parse_gtp_c;
            3: parse_gtp_u;
            //4,1: parse_gtp_prime;
            default: accept;
        }
#else
        transition reject;
#endif  /* GTP_ENABLE */
    }


#ifdef GTP_ENABLE

    state parse_gtp_u {
        pkt.extract(hdr.gtp_v1_base);
        // todo: eg_md.tunnel.type = SWITCH_TUNNEL_TYPE_GTP_U;
    	transition select(
            hdr.gtp_v1_base.E,
            hdr.gtp_v1_base.S,
            hdr.gtp_v1_base.PN,
            pkt.lookahead<bit<4>>()) {
    
            (0,0,0,4): parse_inner_ipv4;
            (0,0,0,6): parse_inner_ipv6;
            default: accept;
        }
    }

    state parse_gtp_c {
        pkt.extract(hdr.gtp_v1_base);
        // todo: eg_md.tunnel.type = SWITCH_TUNNEL_TYPE_GTP_C;
    	transition accept;
    }


    // the only reason i added this was so we wouldn't set the tunnel
    // type until we knew it had no optional word. not sure this is
    // needed since downstream can check hdr bits to determine this.
    // state parse_gtp_u {
    //     pkt.extract(hdr.gtp_v1_base);
    // 	transition select(
    //         hdr.gtp_v1_base.E,
    //         hdr.gtp_v1_base.S,
    //         hdr.gtp_v1_base.PN) {
    // 
    //         (0,0,0): parse_gtp_u_end;
    //         default: accept;
    //     }
    // }
    // state parse_gtp_u_end {
    //     //eg_md.tunnel.type = SWITCH_TUNNEL_TYPE_GTP_U;
    //     transition select(pkt.lookahead<bit<4>>()) {
    //         4: parse_inner_ipv4;
    //         6: parse_inner_ipv6;
    //         default: accept;
    //     }
    // }

#endif  /* GTP_ENABLE */




    ///////////////////////////////////////////////////////////////////////////
    // Inner Layer 2 (ETH-T)
    ///////////////////////////////////////////////////////////////////////////

    state parse_inner_ethernet {
        pkt.extract(hdr.inner_ethernet);
        inner_ether_type = hdr.inner_ethernet.ether_type;
        transition select(hdr.inner_ethernet.ether_type) {
            ETHERTYPE_VLAN : parse_inner_vlan;
            default : parse_inner_ether_type;
        }
    }

    state parse_inner_vlan {
        pkt.extract(hdr.inner_vlan_tag);
        inner_ether_type = hdr.inner_vlan_tag.ether_type;
        transition parse_inner_ether_type;
    }

    // shared fanout/branch state to save tcam resource
    state parse_inner_ether_type {
        transition select(inner_ether_type) {
            ETHERTYPE_IPV4 : parse_inner_ipv4;
            ETHERTYPE_IPV6 : parse_inner_ipv6;
            default : accept;
        }
    }


    ///////////////////////////////////////////////////////////////////////////
    // Inner Layer 3 (Network)
    ///////////////////////////////////////////////////////////////////////////
    // todo: When barefoot fixes case#8406, we should be able to use a common
    //       subparser for L3 parsing across both outer and inner. This will
    //       result in additional (tcam) resource savings. That being said,
    //       a subparser here can be a little tricky: We may need to use
    //       additional metadata or check valid bits to distinguish between
    //       v4 and v6 when exiting the subparser (into the famout branch).
    //       Also, would we need to indicate that we're finished parsing in
    //       the case of icmp/igmp (if these are done in the subparser(s)).

    state parse_inner_ipv4 {
        pkt.extract(hdr.inner_ipv4);
        inner_protocol = hdr.inner_ipv4.protocol;
        // Flag packet (to be sent to host) if it's a frag or has options.
        transition select(
            hdr.inner_ipv4.ihl,
            hdr.inner_ipv4.flags,
            hdr.inner_ipv4.frag_offset) {
            //(5, 0, 0): parse_inner_l3_protocol;
            //(5, 2, 0): parse_inner_l3_protocol;
            (5, 3w2 &&& 3w5, 0): parse_inner_l3_protocol;

            default: accept;
        }
    }

    state parse_inner_ipv6 {
#ifdef IPV6_ENABLE
        pkt.extract(hdr.inner_ipv6);
        inner_protocol = hdr.inner_ipv6.next_hdr;
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
           IP_PROTOCOLS_ESP: parse_inner_esp;
           IP_PROTOCOLS_GRE: parse_inner_gre;
           default : accept;
       }
    }



    ///////////////////////////////////////////////////////////////////////////
    // Inner Layer 4 (Transport)
    ///////////////////////////////////////////////////////////////////////////

    state parse_inner_udp {
        pkt.extract(hdr.inner_udp);
        transition accept;
    }

    state parse_inner_tcp {
        pkt.extract(hdr.inner_tcp);
        transition accept;
    }

    state parse_inner_sctp {
        pkt.extract(hdr.inner_sctp);
        transition accept;
    }    


    ///////////////////////////////////////////////////////////////////////////
    // Inner Tunnels
    ///////////////////////////////////////////////////////////////////////////

    // todo: do we need to parse this? extract?
    state parse_inner_esp {
        pkt.extract(hdr.inner_esp);
        transition accept;
    }

    // todo: do we need to parse this? extract?
    state parse_inner_gre {
        pkt.extract(hdr.inner_gre);
        transition accept;
    }



// 
// ///////////////////////////////////////////////////////////////////////////////
// // Underlay Encaps
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
