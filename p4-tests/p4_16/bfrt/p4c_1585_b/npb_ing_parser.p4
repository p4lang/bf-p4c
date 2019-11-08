#ifndef _NPB_ING_PARSER_
#define _NPB_ING_PARSER_

#include "npb_sub_parsers.p4"

parser NpbIngressParser(
        packet_in pkt,
        out switch_header_t hdr,
        out switch_ingress_metadata_t ig_md,
        out ingress_intrinsic_metadata_t ig_intr_md) {

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
        ig_md.port_lag_label = port_md.port_lag_label;
        ig_md.ifindex = port_md.ifindex;
        //transition parse_ethernet;
        transition snoop_underlay;
    }

    // todo: need to understand interaction w/ cpu better.
    // todo: can we assume no vlan-tags after cpu header?
    state parse_cpu {
        pkt.extract(hdr.fabric);
        pkt.extract(hdr.cpu);
        ig_md.bypass = hdr.cpu.reason_code;
        ig_md.flags.capture_ts = (bool) hdr.cpu.capture_ts;
        transition select(hdr.cpu.ether_type) {
            ETHERTYPE_IPV4 : parse_ipv4;
            ETHERTYPE_IPV6 : parse_ipv6;
            //ETHERTYPE_VLAN : parse_vlan;
            //ETHERTYPE_QINQ : parse_vlan;
            //ETHERTYPE_MPLS : parse_mpls;
            default : accept;
        }
    }


    ///////////////////////////////////////////////////////////////////////////
    // Layer 2
    ///////////////////////////////////////////////////////////////////////////

    // Subparsers are broken in v8.7.0:
    // Any data set down in the subparser, except maybe header extractions,
    // will not be visible up here in the main parser.
    // 
    // // shared fanout/branch state to save tcam resource
    // state parse_ethernet {
    //     parser_underlay_l2_md_backup.apply(pkt, hdr, ig_md);
    //     transition select(ig_md.scratch_ether_type) {
    //         ETHERTYPE_NSH : parse_nsh_underlay;
    //         ETHERTYPE_ARP : parse_arp;
    //         ETHERTYPE_MPLS : parse_mpls;
    //         ETHERTYPE_IPV4 : parse_ipv4;
    //         ETHERTYPE_IPV6 : parse_ipv6;
    //         ETHERTYPE_BFN : parse_cpu;
    //         default : accept;
    //     }
    // }


#ifdef SPBM_ENABLE

    // Snoop ahead here to determine type of underlay
    state snoop_underlay {
        // todo: can we make the assumption that all spbm will have nsh?
        //       if not, then snooping won't work here due to 32B limit.
        ethernet_tagged_h snoop = pkt.lookahead<ethernet_tagged_h>();
        transition select(snoop.ether_type, snoop.ether_type_tag) {
            //If we use QINQ (Dot1AD) before SPBM, the linux kernel
            //actually changes the 0x88a8 etype to 0x8100?!
            //[ Ether() / Dot1AD() / SPBM() / Ether() / Dot1Q() ]
            //(ETHERTYPE_QINQ, ETHERTYPE_MINM): parse_underlay;
            (ETHERTYPE_VLAN, ETHERTYPE_MINM): parse_underlay;
            default: parse_underlay_l2_ethernet;
        }
    }

    state parse_underlay {
        // todo: for now, let's just drop everything prior to NSH.
        //       this will make it compatible w/ orig nsh stuff.
        //       (in that nsh will be first hdr sent from ing->egr)
        pkt.extract<ethernet_h>(_); // drop it
        pkt.extract<vlan_tag_h>(_); // drop it
        pkt.extract<spbm_h>(_); // drop it
        pkt.extract<ethernet_h>(_); // drop it
        pkt.extract<vlan_tag_h>(_); // drop it
	    pkt.extract(hdr.nsh_extr_underlay);
        ig_md.orig_pkt_had_nsh = 1;
        transition parse_underlay_l2_ethernet;
    }

#else  /* SPBM_ENABLE (not) */

    // Snoop ahead here to determine type of underlay
    state snoop_underlay {
        ethernet_tagged_h snoop = pkt.lookahead<ethernet_tagged_h>();
        transition select(snoop.ether_type, snoop.ether_type_tag) {
            (ETHERTYPE_NSH, _): parse_underlay_nsh;
            (ETHERTYPE_VLAN, ETHERTYPE_NSH): parse_underlay_nsh_tagged;
            default: parse_underlay_l2_ethernet;
        }
    }

    state parse_underlay_nsh {
        // todo: is this enet used  - can we advance past it? not emit?
        // pkt.extract(hdr.ethernet_underlay);
        pkt.extract<ethernet_h>(_); // drop it
	    pkt.extract(hdr.nsh_extr_underlay);
        ig_md.orig_pkt_had_nsh = 1;
        transition parse_underlay_l2_ethernet;
    }

    state parse_underlay_nsh_tagged {
        // todo: is this enet used  - can we advance past it? not emit?
        // pkt.extract(hdr.ethernet_underlay);
        // pkt.extract(hdr.vlan_tag_underlay);
        pkt.extract<ethernet_h>(_); // drop it
        pkt.extract<vlan_tag_h>(_); // drop it
	    pkt.extract(hdr.nsh_extr_underlay);
        ig_md.orig_pkt_had_nsh = 1;
        transition parse_underlay_l2_ethernet;
    }

#endif /* SPBM_ENABLE */




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
            ETHERTYPE_ARP  : parse_arp;
            ETHERTYPE_IPV6 : parse_ipv6;
            ETHERTYPE_BFN  : parse_cpu;
            default : accept;
        }
    }



    ///////////////////////////////////////////////////////////////////////////
    // Layer 2.5
    ///////////////////////////////////////////////////////////////////////////

    state parse_arp {
        pkt.extract(hdr.arp);
        transition accept;
    }


    ///////////////////////////////////////////////////////////////////////////
    // Layer 3 (Network)
    ///////////////////////////////////////////////////////////////////////////

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        protocol = hdr.ipv4.protocol;
        // Flag packet (to be sent to host) if it's a frag or has options.
        ipv4_checksum.add(hdr.ipv4);
        transition select(hdr.ipv4.ihl, hdr.ipv4.flags, hdr.ipv4.frag_offset) {
            (5, 3w2 &&& 3w5, 0): parse_ipv4_no_options_frags;
            default : accept;
        }
    }

    state parse_ipv4_no_options_frags {
        ig_md.flags.ipv4_checksum_err = ipv4_checksum.verify();
        transition select(hdr.ipv4.protocol) {
            IP_PROTOCOLS_ICMP: parse_icmp;
            IP_PROTOCOLS_IGMP: parse_igmp;
            default: parse_l3_protocol;
        }
    }

    state parse_ipv6 {
#ifdef IPV6_ENABLE
        pkt.extract(hdr.ipv6);
        protocol = hdr.ipv6.next_hdr;
        transition select(hdr.ipv6.next_hdr) {
            IP_PROTOCOLS_ICMPV6: parse_icmp;
            default: parse_l3_protocol;
        }
#else
        transition reject;
#endif
    }

    // shared fanout/branch state to save tcam resource
    state parse_l3_protocol {
        transition select(protocol) {
           IP_PROTOCOLS_IPV4: parse_ipinip;
           IP_PROTOCOLS_IPV6: parse_ipv6inip;
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

    state parse_icmp {
        pkt.extract(hdr.icmp);
        transition accept;
    }

    state parse_igmp {
        pkt.extract(hdr.igmp);
        transition accept;
    }



    ///////////////////////////////////////////////////////////////////////////
    // Layer 4 (Transport)
    ///////////////////////////////////////////////////////////////////////////

    state parse_udp {
        pkt.extract(hdr.udp);
        transition select(hdr.udp.src_port, hdr.udp.dst_port) {
            (_, UDP_PORT_VXLAN): parse_vxlan;
            //(_, udp_port_vxlan): parse_vxlan;
#ifdef GTP_ENABLE
            (_, UDP_PORT_GTP_C): parse_gtp_c;
            (UDP_PORT_GTP_C, _): parse_gtp_c;
            (_, UDP_PORT_GTP_U): parse_gtp_u;
            (UDP_PORT_GTP_U, _): parse_gtp_u;
#endif  /* GTP_ENABLE */
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
        ig_md.tunnel.type = SWITCH_TUNNEL_TYPE_VXLAN;
        ig_md.tunnel.id = hdr.vxlan.vni;
        transition parse_inner_ethernet; 
#else
        transition accept;
#endif
    }

    state parse_ipinip {
#ifdef IPINIP
        ig_md.tunnel.type = SWITCH_TUNNEL_TYPE_IPINIP;
        transition parse_inner_ipv4;
#else
        transition accept;
#endif /* IPINIP */
    }

    state parse_ipv6inip {
//#if defined(IPINIP) && defined(IPV6_TUNNEL_ENABLE)
#ifdef IPINIP
        ig_md.tunnel.type = SWITCH_TUNNEL_TYPE_IPINIP;
        transition parse_inner_ipv6;
#else
        transition accept;
#endif /* IPINIP */
    }

    state parse_gre {
    	pkt.extract(hdr.gre);
        // todo: verify(hdr.gre.version == 0, error.GreVersionNotZero);
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
// #ifdef ERSPAN_UNDERLAY_ENABLE
//             (0,0,0,0,0,0,0,GRE_PROTOCOLS_ERSPAN_TYPE_2): parse_erspan_t1_underlay;
//             (0,0,0,1,0,0,0,GRE_PROTOCOLS_ERSPAN_TYPE_2): parse_erspan_t2_underlay;
//             //(0,0,0,1,0,0,0,GRE_PROTOCOLS_ERSPAN_TYPE_3): parse_erspan_t3_underlay;
// #endif /* ERSPAN_UNDERLAY_ENABLE */
            default: accept;
        }
    }

    state parse_nvgre {
    	pkt.extract(hdr.nvgre);
    	transition parse_inner_ethernet;
    }

    state parse_esp {
        pkt.extract(hdr.esp);
        transition accept;
    }



    //-------------------------------------------------------------------------
    // GPRS (General Packet Radio Service) Tunneling Protocol (GTP)
    //-------------------------------------------------------------------------
    // Based on pseudo code from Glenn (see email from 03/11/2019):

#ifdef GTP_ENABLE

    ///////////////////////////////////////////////////////////////////////////
    // GTP-C
    ///////////////////////////////////////////////////////////////////////////

    // state parse_gtp_c {
    //     pkt.extract(hdr.gtp_v2_base);
    //     transition select(hdr.gtp_v2_base.version, hdr.gtp_v2_base.T) {
    //         (2, 1): parse_gtp_c_tied;
    //         default: accept;
    //     }
    // }
    // 
    // state parse_gtp_c_teid {
    //     pkt.extract(hdr.gtp_v2_optional_teid);
    // 	transition accept;
    // }

    state parse_gtp_c {
        gtp_v2_base_h snoop_gtp_v2_base = pkt.lookahead<gtp_v2_base_h>();
        transition select(snoop_gtp_v2_base.version, snoop_gtp_v2_base.T) {
            (2, 1): extract_gtp_c;
            default: accept;
        }
    }

    state extract_gtp_c {
        pkt.extract(hdr.gtp_v2_base);
        pkt.extract(hdr.gtp_v2_optional_teid);
    	transition accept;
    }


    ///////////////////////////////////////////////////////////////////////////
    // GTP-U
    ///////////////////////////////////////////////////////////////////////////
    // Does not support parsing GTP v1 optional word
    // Does not support parsing (TLV) extension headers

    // state parse_gtp_u {
    //     pkt.extract(hdr.gtp_v1_base);
    //     transition select(
    //         hdr.gtp_v1_base.version,
    //         hdr.gtp_v1_base.PT,
    //         hdr.gtp_v1_base.E,
    //         hdr.gtp_v1_base.S,
    //         hdr.gtp_v1_base.PN
    //         pkt.lookahead<bit<4>>()) {
    // 
    //         (1, 1, 0, 0, 0, 4): parse_inner_ipv4;
    //         (1, 1, 0, 0, 0, 6): parse_inner_ipv6;
    //         default: accept;
    //     }
    // }

    state parse_gtp_u {
        gtp_v1_base_h snoop_gtp_v1_base = pkt.lookahead<gtp_v1_base_h>();
        transition select(
            snoop_gtp_v1_base.version,
            snoop_gtp_v1_base.PT,
            snoop_gtp_v1_base.E,
            snoop_gtp_v1_base.S,
            snoop_gtp_v1_base.PN) {

            (1, 1, 0, 0, 0): extract_gtp_u;
            default: accept;
        }
    }

    state extract_gtp_u {
        pkt.extract(hdr.gtp_v1_base);
        transition select(pkt.lookahead<bit<4>>()) {
            4: parse_inner_ipv4;
            6: parse_inner_ipv6;
            default: accept;
        }
    }

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
            ETHERTYPE_ARP : parse_inner_arp;
            ETHERTYPE_IPV4 : parse_inner_ipv4;
            ETHERTYPE_IPV6 : parse_inner_ipv6;
            default : accept;
        }
    }


    ///////////////////////////////////////////////////////////////////////////
    // Inner - Layer 2.5
    ///////////////////////////////////////////////////////////////////////////

    state parse_inner_arp {
        pkt.extract(hdr.inner_arp);
        transition accept;
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
        inner_ipv4_checksum.add(hdr.inner_ipv4);
        transition select(
            hdr.inner_ipv4.ihl,
            hdr.inner_ipv4.flags,
            hdr.inner_ipv4.frag_offset) {
            //(5, 0, 0): parse_inner_ipv4_no_options_frags;
            //(5, 2, 0): parse_inner_ipv4_no_options_frags;
            (5, 3w2 &&& 3w5, 0): parse_inner_ipv4_no_options_frags;
            default: accept;
        }
    }

    state parse_inner_ipv4_no_options_frags {
        ig_md.flags.inner_ipv4_checksum_err = inner_ipv4_checksum.verify();
        transition select(hdr.inner_ipv4.protocol) {
            IP_PROTOCOLS_ICMP: parse_inner_icmp;
            IP_PROTOCOLS_IGMP: parse_inner_igmp;
            default: parse_inner_l3_protocol;
        }
    }

    state parse_inner_ipv6 {
#ifdef IPV6_ENABLE
        pkt.extract(hdr.inner_ipv6);
        inner_protocol = hdr.inner_ipv6.next_hdr;
        transition select(hdr.inner_ipv6.next_hdr) {
            IP_PROTOCOLS_ICMPV6: parse_inner_icmp;
            default: parse_inner_l3_protocol;
        }
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

    state parse_inner_icmp {
        pkt.extract(hdr.inner_icmp);
        transition accept;
    }

    state parse_inner_igmp {
        pkt.extract(hdr.inner_igmp);
        transition accept;
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



}

#endif /* _NPB_ING_PARSER_ */
