// Copyright 2020-2021 Extreme Networks, Inc.
// All rights reserved.

#ifndef _NPB_ING_PARSER_
#define _NPB_ING_PARSER_


parser IngressParser(
    packet_in pkt,
    out switch_header_t hdr,
    out switch_ingress_metadata_t ig_md,
    out ingress_intrinsic_metadata_t ig_intr_md
) ( // constructor parameters
    MODULE_DEPLOYMENT_PARAMS
) {

    // Checksum() ipv4_checksum_transport;
    // Checksum() ipv4_checksum_outer;
    // Checksum() ipv4_checksum_inner;

    value_set<switch_cpu_port_value_set_t>(4) cpu_port;
    value_set<bit<32>>(1) my_mac_lo;
    value_set<bit<16>>(1) my_mac_hi;
    
    bit<16> ether_type_transport;
    bit<16> ether_type_outer;
    //bit<16> ether_type_inner;
    bit<8>  protocol_outer;
    bit<8>  protocol_inner;
    //bit<1>  transport_eompls_enable;

    state start {
        pkt.extract(ig_intr_md);
        ig_md.ingress_port           = ig_intr_md.ingress_port;
#if defined(PTP_ENABLE) || defined(INT_V2)
        ig_md.ingress_timestamp = ig_intr_md.ingress_mac_tstamp;
#else
        ig_md.ingress_timestamp = ig_intr_md.ingress_mac_tstamp[31:0];
#endif
        // Check for resubmit flag if packet is resubmitted.
        // transition select(ig_intr_md.resubmit_flag) {
        //     1 : parse_resubmit;
        //     0 : parse_port_metadata;
        // }

        ig_md.flags.transport_valid = false;
        ig_md.flags.outer_enet_in_transport = false;

#ifdef PA_NO_INIT
        ig_md.tunnel_0.terminate = false;
        ig_md.tunnel_1.terminate = false;
        ig_md.tunnel_2.terminate = false;
#endif
        transition parse_port_metadata;
    }

    state parse_resubmit {
        transition reject;
    }
    
    //--------------------------------------------------------------------------
    // Port Metadata
    //--------------------------------------------------------------------------
    
    state parse_port_metadata {
        // Parse port metadata produced by ibuf
#ifdef CPU_HDR_CONTAINS_EG_PORT
        pkt.advance(PORT_METADATA_SIZE);
#else
       switch_port_metadata_t port_md = port_metadata_unpack<switch_port_metadata_t>(pkt);
       ig_md.ingress_port_lag_index = port_md.port_lag_index;
       ig_md.nsh_md.l2_fwd_en = (bool)port_md.l2_fwd_en;
#endif
        // switch_port_metadata_t port_md = port_metadata_unpack<switch_port_metadata_t>(pkt);
	// transport_eompls_enable = port_md.transport_eompls_enable;     
        
        transition select(FOLDED_ENABLE) {
            true: parse_bridged_pkt;
            false: check_from_cpu;
        }
    }
    
    //--------------------------------------------------------------------------
    // Folded Metadata
    //--------------------------------------------------------------------------

    state parse_bridged_pkt {
        pkt.extract(hdr.bridged_md_folded);
//      ig_md.pkt_src = SWITCH_PKT_SRC_BRIDGED;

        // ---- extract base bridged metadata -----
//      ig_md.ingress_port         = hdr.bridged_md_folded.base.ingress_port;
#ifdef CPU_HDR_CONTAINS_EG_PORT
#else
        ig_md.ingress_port_lag_index = hdr.bridged_md_folded.base.ingress_port_lag_index;
#endif
//      ig_md.bd                   = hdr.bridged_md_folded.base.ingress_bd;
        ig_md.nexthop              = hdr.bridged_md_folded.base.nexthop;
//      ig_md.pkt_type             = hdr.bridged_md_folded.base.pkt_type;
//      ig_md.flags.bypass_egress  = hdr.bridged_md_folded.base.bypass_egress;
        ig_md.cpu_reason           = hdr.bridged_md_folded.base.cpu_reason;
        ig_md.ingress_timestamp    = hdr.bridged_md_folded.base.timestamp;
//      ig_md.qos.qid              = hdr.bridged_md_folded.base.qid; // can't do in parser for some reason.

        ig_md.hash                 = hdr.bridged_md_folded.base.hash;
#ifdef TUNNEL_ENABLE
        ig_md.tunnel_nexthop       = hdr.bridged_md_folded.tunnel.tunnel_nexthop;
        ig_md.tunnel_0.dip_index   = hdr.bridged_md_folded.tunnel.dip_index;
//      ig_md.tunnel_0.hash        = hdr.bridged_md_folded.tunnel.hash;

//      ig_md.tunnel_0.terminate   = hdr.bridged_md_folded.tunnel.terminate_0;
//      ig_md.tunnel_1.terminate   = hdr.bridged_md_folded.tunnel.terminate_1;
//      ig_md.tunnel_2.terminate   = hdr.bridged_md_folded.tunnel.terminate_2;
#endif

        // ----- extract nsh bridged metadata -----
        ig_md.flags.transport_valid= hdr.bridged_md_folded.base.transport_valid;
        ig_md.nsh_md.end_of_path   = hdr.bridged_md_folded.base.nsh_md_end_of_path;
        ig_md.nsh_md.l2_fwd_en     = hdr.bridged_md_folded.base.nsh_md_l2_fwd_en;
//      ig_md.nsh_md.dedup_en      = hdr.bridged_md_folded.base.nsh_md_dedup_en; // can't be done in parser, for some reason

//      transition check_from_cpu;
//      transition parse_transport_nsh_internal;

        transition select(
            (bit<1>)hdr.bridged_md_folded.base.nsh_md_l2_fwd_en,
            (bit<1>)hdr.bridged_md_folded.base.transport_valid) {

            (1, 0):  parse_outer_ethernet;         // SFC Optical-Tap / Bridging Path
//          default: parse_transport_ethernet;     // SFC Network-Tap / SFC Bypass Path
            default: parse_transport_nsh_internal; // SFC Network-Tap / SFC Bypass Path
        }
    }

    state parse_transport_nsh_internal {
        pkt.extract(hdr.transport.nsh_type1_internal);

        ig_md.nsh_md.ttl           = hdr.transport.nsh_type1_internal.ttl;
        ig_md.nsh_md.spi           = (bit<SPI_WIDTH>)hdr.transport.nsh_type1_internal.spi;
        ig_md.nsh_md.si            = hdr.transport.nsh_type1_internal.si;
        ig_md.nsh_md.vpn           = (bit<VPN_ID_WIDTH>)hdr.transport.nsh_type1_internal.vpn;
        ig_md.nsh_md.scope         = hdr.transport.nsh_type1_internal.scope;
        ig_md.nsh_md.sap           = (bit<SSAP_ID_WIDTH>)hdr.transport.nsh_type1_internal.sap;

        transition parse_outer_ethernet;
    }

    //--------------------------------------------------------------------------
    // CPU Packet Check
    //--------------------------------------------------------------------------

    state check_from_cpu {
        transition select(
            pkt.lookahead<ethernet_h>().ether_type, ig_intr_md.ingress_port) {
            cpu_port: check_my_mac_lo_cpu;
            default:  check_my_mac_lo;
        }
    }
    
    //--------------------------------------------------------------------------
    // My-MAC Check
    //--------------------------------------------------------------------------
    //  My   L2   MAU                   First   
    //  MAC  Fwd  Path                  Stack
    //  ----------------------------    ------------
    //  0    0    SFC Optical-Tap       Outer       
    //  0    1    Bridging              Outer       
    //  1    x    SFC Network-Tap       Transport   
    //            or SFC Bypass (nsh)   Transport

    state check_my_mac_lo {
        transition select(pkt.lookahead<snoop_enet_my_mac_h>().dst_addr_lo) {
            my_mac_lo: check_my_mac_hi;
            default: construct_transport_special_case_a;
        }
    }
    state check_my_mac_hi {
        transition select(pkt.lookahead<snoop_enet_my_mac_h>().dst_addr_hi) {
            my_mac_hi: parse_transport_ethernet;
            default: construct_transport_special_case_a;
       }
    }

    state check_my_mac_lo_cpu {
        transition select(pkt.lookahead<snoop_enet_my_mac_h>().dst_addr_lo) {
            my_mac_lo: check_my_mac_hi_cpu;
            default: parse_outer_ethernet_cpu;
        }
    }
    state check_my_mac_hi_cpu {
        transition select(pkt.lookahead<snoop_enet_my_mac_h>().dst_addr_hi) {
            my_mac_hi: parse_transport_ethernet_cpu;
            default: parse_outer_ethernet_cpu;
        }
    }

    //--------------------------------------------------------------------------
    // Special-Case Snooping Path
    // 
    // Special-case parsing path to enable deeper parsing on a small set of
    // specific packets on a my-mac miss. Information from these packets will
    // be presented to dest-vtep table (transport) instead of the traditional
    // inner-sap table (outer).
    //
    //    spbm
    //    enet / mpls-sr
    //    enet / ipv4 / udp / vxlan
    //    enet / ipv4 / udp / geneve
    //    todo: add vlan-tag cases to this list?
    //
    // To accomplish this, we need to lookahead and in some cases begin
    // extracting headers prior to knowing where the headers belong (transport
    // versus outer). Unfortunately, all packets that experience a my-mac miss
    // will start down this path and be subjected to additional parsing states.
    //--------------------------------------------------------------------------

    state construct_transport_special_case_a {
        transition select(
            TRANSPORT_INGRESS_ENABLE,
            TRANSPORT_IPV4_VXLAN_INGRESS_ENABLE,
            TRANSPORT_IPV4_GENEVE_INGRESS_ENABLE,
            TRANSPORT_EoMPLS_INGRESS_ENABLE,
            TRANSPORT_IPoMPLS_INGRESS_ENABLE,
            TRANSPORT_SPBM_INGRESS_ENABLE) {
            (false,    _,    _,    _,    _,    _): parse_outer_ethernet;
            ( true,    _,    _, true,    _, true): check_special_case_enet_ipv4_mpls_spbm;
            ( true,    _,    _,    _, true, true): check_special_case_enet_ipv4_mpls_spbm;
            ( true,    _,    _, true,    _,    _): check_special_case_enet_ipv4_mpls_nospbm;
            ( true,    _,    _,    _, true,    _): check_special_case_enet_ipv4_mpls_nospbm;
            ( true,    _,    _,    _,    _, true): check_special_case_enet_ipv4_nompls_spbm;
            ( true,    _, true,    _,    _,    _): check_special_case_enet_ipv4_nompls_nospbm;
            ( true, true,    _,    _,    _,    _): check_special_case_enet_ipv4_nompls_nospbm;
            default: parse_outer_ethernet;
        }
    }

    // state construct_transport_special_case_a {
    //     transition select(
    //         TRANSPORT_INGRESS_ENABLE,
    //         TRANSPORT_IPV4_VXLAN_INGRESS_ENABLE,
    //         TRANSPORT_IPV4_GENEVE_INGRESS_ENABLE,
    //         TRANSPORT_MPLS_INGRESS_ENABLE,
    //         TRANSPORT_SPBM_INGRESS_ENABLE) {
    //         (false,    _,    _,    _,    _): parse_outer_ethernet;
    //         ( true,    _,    _, true, true): check_special_case_enet_ipv4_mpls_spbm;
    //         ( true,    _,    _, true,    _): check_special_case_enet_ipv4_mpls_nospbm;
    //         ( true,    _,    _,    _, true): check_special_case_enet_ipv4_nompls_spbm;
    //         ( true,    _, true,    _,    _): check_special_case_enet_ipv4_nompls_nospbm;
    //         ( true, true,    _,    _,    _): check_special_case_enet_ipv4_nompls_nospbm;
    //         default: parse_outer_ethernet;
    //     }
    // }


    
    // state snoop_head_unsure_tunnel {  // compile errors w/ vlan tag case
    //     transition select(
    //         pkt.lookahead<snoop_head_enet_vlan_ipv4_h>().enet_ether_type,
    //         pkt.lookahead<snoop_head_enet_vlan_ipv4_h>().vlan_ether_type,
    //         pkt.lookahead<snoop_head_enet_vlan_ipv4_h>().ipv4_protocol) {
    // 
    //         (ETHERTYPE_VLAN,
    //          ETHERTYPE_IPV4,
    //          IP_PROTOCOLS_UDP): parse_ethernet_vlan_unsure_vxlan;
    //         default: parse_outer_ethernet;
    //     }
    // }
    
    state check_special_case_enet_ipv4_mpls_spbm {
        transition select(
            pkt.lookahead<snoop_head_enet_ipv4_h>().enet_ether_type,
            pkt.lookahead<snoop_head_enet_ipv4_h>().ipv4_protocol) {    
            (ETHERTYPE_QINQ, _               ): check_special_case_qinq_minm;
            (ETHERTYPE_MPLS, _               ): parse_transport_ethernet;
            (ETHERTYPE_IPV4, IP_PROTOCOLS_UDP): construct_transport_special_case_b;
            default                           : parse_outer_ethernet;
        }
    }

    // Need to look at 2nd tag to differentiate between Q-in-Q and MAC-in-MAC
    // (both start w/ 0x88a8)
    state check_special_case_qinq_minm {
        transition select(
            pkt.lookahead<snoop_head_enet_vlan_h>().vlan_ether_type) {
            ETHERTYPE_MINM: parse_transport_ethernet;
            default: parse_outer_ethernet;
        }
    }

    state check_special_case_enet_ipv4_mpls_nospbm {
        transition select(
            pkt.lookahead<snoop_head_enet_ipv4_h>().enet_ether_type,
            pkt.lookahead<snoop_head_enet_ipv4_h>().ipv4_protocol) {    
            (ETHERTYPE_MPLS, _               ): parse_transport_ethernet;
            (ETHERTYPE_IPV4, IP_PROTOCOLS_UDP): construct_transport_special_case_b;
            default                           : parse_outer_ethernet;
        }
    }

    state check_special_case_enet_ipv4_nompls_spbm {
        transition select(
            pkt.lookahead<snoop_head_enet_ipv4_h>().enet_ether_type,
            pkt.lookahead<snoop_head_enet_ipv4_h>().ipv4_protocol) {    
            (ETHERTYPE_QINQ, _               ): parse_transport_ethernet;
            (ETHERTYPE_IPV4, IP_PROTOCOLS_UDP): construct_transport_special_case_b;
            default                           : parse_outer_ethernet;
        }
    }

    state check_special_case_enet_ipv4_nompls_nospbm {
        transition select(
            pkt.lookahead<snoop_head_enet_ipv4_h>().enet_ether_type,
            pkt.lookahead<snoop_head_enet_ipv4_h>().ipv4_protocol) {
            (ETHERTYPE_IPV4, IP_PROTOCOLS_UDP): construct_transport_special_case_b;
            default                           : parse_outer_ethernet;
        }
    }
    
    // todo: Insert new state check_special_case_enet_vlan_ipv4 here?
    
    state construct_transport_special_case_b {
        transition select(
            TRANSPORT_IPV4_VXLAN_INGRESS_ENABLE,
            TRANSPORT_IPV4_GENEVE_INGRESS_ENABLE) {
            (true, false): parse_ethernet_unsure_special_case_vxlan;
            (false, true): parse_ethernet_unsure_special_case_geneve;
            (true, true): parse_ethernet_unsure_special_case_vxlan_geneve;
        }
    }

    state parse_ethernet_unsure_special_case_vxlan {
        pkt.extract(hdr.transport.ethernet);

        hdr.outer.ethernet.setValid();
        // Compiler problems: parser tests fail - need to move header in MAU
        hdr.outer.ethernet.dst_addr = hdr.transport.ethernet.dst_addr;
        hdr.outer.ethernet.src_addr = hdr.transport.ethernet.src_addr;
        // hdr.outer.ethernet.ether_type = hdr.transport.ethernet.ether_type;

#ifdef INGRESS_PARSER_POPULATES_LKP_0
        ig_md.lkp_0.l2_valid     = true;
        ig_md.lkp_0.mac_src_addr = hdr.transport.ethernet.src_addr;
        ig_md.lkp_0.mac_dst_addr = hdr.transport.ethernet.dst_addr;
        ig_md.lkp_0.mac_type     = hdr.transport.ethernet.ether_type;
#endif // INGRESS_PARSER_POPULATES_LKP_0

#ifdef INGRESS_PARSER_POPULATES_LKP_1
        ig_md.lkp_1.l2_valid     = true;
        ig_md.lkp_1.mac_src_addr = hdr.transport.ethernet.src_addr;
        ig_md.lkp_1.mac_dst_addr = hdr.transport.ethernet.dst_addr;
        ig_md.lkp_1.mac_type     = hdr.transport.ethernet.ether_type;
#endif // INGRESS_PARSER_POPULATES_LKP_1

        // error: Ran out of parser match registers
        // transition select(pkt.lookahead<snoop_ipv4_udp_geneve_h>().udp_dst_port,
        //               pkt.lookahead<snoop_ipv4_udp_geneve_h>().geneve_ver,
        //               pkt.lookahead<snoop_ipv4_udp_geneve_h>().geneve_opt_len,
        //               pkt.lookahead<snoop_ipv4_udp_geneve_h>().geneve_O,
        //               pkt.lookahead<snoop_ipv4_udp_geneve_h>().geneve_C,
        //               pkt.lookahead<snoop_ipv4_udp_geneve_h>().geneve_proto_type) {
        // 
        //   // udp_dst_port   v l O C proto_type 
        //     (UDP_PORT_VXLAN,_,_,_,_,_             ): construct_transport_ipv4;
        //     (UDP_PORT_GENV, 0,0,0,0,ETHERTYPE_ENET): construct_transport_ipv4;
        //     (UDP_PORT_GENV, 0,0,0,0,ETHERTYPE_IPV4): construct_transport_ipv4;
        //     (UDP_PORT_GENV, 0,0,0,0,ETHERTYPE_IPV6): construct_transport_ipv4;
        //     default: not_transport_special_case;
        //     //default: accept;
        // }
        transition select(pkt.lookahead<snoop_ipv4_udp_h>().udp_dst_port) {
            UDP_PORT_VXLAN: construct_transport_ipv4;
            default: not_transport_special_case;
        }
    }

    state parse_ethernet_unsure_special_case_geneve {
        pkt.extract(hdr.transport.ethernet);

        hdr.outer.ethernet.setValid();
        // Compiler problem: parser tests fail - need to move header in MAU
        hdr.outer.ethernet.dst_addr = hdr.transport.ethernet.dst_addr;
        hdr.outer.ethernet.src_addr = hdr.transport.ethernet.src_addr;
        // hdr.outer.ethernet.ether_type = hdr.transport.ethernet.ether_type;

#ifdef INGRESS_PARSER_POPULATES_LKP_0
        ig_md.lkp_0.l2_valid     = true;
        ig_md.lkp_0.mac_src_addr = hdr.transport.ethernet.src_addr;
        ig_md.lkp_0.mac_dst_addr = hdr.transport.ethernet.dst_addr;
        ig_md.lkp_0.mac_type     = hdr.transport.ethernet.ether_type;
#endif // INGRESS_PARSER_POPULATES_LKP_0

#ifdef INGRESS_PARSER_POPULATES_LKP_1
        ig_md.lkp_1.l2_valid     = true;
        ig_md.lkp_1.mac_src_addr = hdr.transport.ethernet.src_addr;
        ig_md.lkp_1.mac_dst_addr = hdr.transport.ethernet.dst_addr;
        ig_md.lkp_1.mac_type     = hdr.transport.ethernet.ether_type;
#endif // INGRESS_PARSER_POPULATES_LKP_1

        transition select(pkt.lookahead<snoop_ipv4_udp_h>().udp_dst_port) {
            UDP_PORT_GENV : construct_transport_ipv4;
            default: not_transport_special_case;
        }
    }

    state parse_ethernet_unsure_special_case_vxlan_geneve {
        pkt.extract(hdr.transport.ethernet);

        hdr.outer.ethernet.setValid();
        // Compiler problem: parser tests fail - need to move header in MAU
        hdr.outer.ethernet.dst_addr = hdr.transport.ethernet.dst_addr;
        hdr.outer.ethernet.src_addr = hdr.transport.ethernet.src_addr;
        // hdr.outer.ethernet.ether_type = hdr.transport.ethernet.ether_type;

#ifdef INGRESS_PARSER_POPULATES_LKP_0
        ig_md.lkp_0.l2_valid     = true;
        ig_md.lkp_0.mac_src_addr = hdr.transport.ethernet.src_addr;
        ig_md.lkp_0.mac_dst_addr = hdr.transport.ethernet.dst_addr;
        ig_md.lkp_0.mac_type     = hdr.transport.ethernet.ether_type;
#endif // INGRESS_PARSER_POPULATES_LKP_0

#ifdef INGRESS_PARSER_POPULATES_LKP_1
        ig_md.lkp_1.l2_valid     = true;
        ig_md.lkp_1.mac_src_addr = hdr.transport.ethernet.src_addr;
        ig_md.lkp_1.mac_dst_addr = hdr.transport.ethernet.dst_addr;
        ig_md.lkp_1.mac_type     = hdr.transport.ethernet.ether_type;
#endif // INGRESS_PARSER_POPULATES_LKP_1

        transition select(pkt.lookahead<snoop_ipv4_udp_h>().udp_dst_port) {
            UDP_PORT_VXLAN: construct_transport_ipv4;
            UDP_PORT_GENV : construct_transport_ipv4;
            default: not_transport_special_case;
        }
    }
    
    state not_transport_special_case {
        // hdr.transport.ethernet.setInvalid();
        ig_md.flags.outer_enet_in_transport = true;

#ifdef INGRESS_PARSER_POPULATES_LKP_0
        ig_md.lkp_0.l2_valid     = false;
        ig_md.lkp_0.mac_src_addr = 0;
        ig_md.lkp_0.mac_dst_addr = 0;
        ig_md.lkp_0.mac_type     = 0;
#endif // INGRESS_PARSER_POPULATES_LKP_0
        
        transition qualify_outer_ipv4;
    }


    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////
    // "Transport" Headers / Stack (L2-U)
    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////

    ////////////////////////////////////////////////////////////////////////////
    // Layer2 - Transport (ETH-T)
    ////////////////////////////////////////////////////////////////////////////

    state parse_transport_ethernet {
        ig_md.flags.transport_valid = true;
        pkt.extract(hdr.transport.ethernet);
        ether_type_transport = hdr.transport.ethernet.ether_type;

#ifdef INGRESS_PARSER_POPULATES_LKP_0
        ig_md.lkp_0.l2_valid     = true;
        ig_md.lkp_0.mac_src_addr = hdr.transport.ethernet.src_addr;
        ig_md.lkp_0.mac_dst_addr = hdr.transport.ethernet.dst_addr;
        ig_md.lkp_0.mac_type     = hdr.transport.ethernet.ether_type;
#endif // INGRESS_PARSER_POPULATES_LKP_0

// populate for L3-tunnel case (where there's no L2 present)
#ifdef INGRESS_PARSER_POPULATES_LKP_1        
        ig_md.lkp_1.l2_valid     = true;
        ig_md.lkp_1.mac_src_addr = hdr.transport.ethernet.src_addr;
        ig_md.lkp_1.mac_dst_addr = hdr.transport.ethernet.dst_addr;
        ig_md.lkp_1.mac_type     = hdr.transport.ethernet.ether_type;
#endif // INGRESS_PARSER_POPULATES_LKP_1

// populate for L3-tunnel case (where there's no L2 present)
#ifdef INGRESS_PARSER_POPULATES_LKP_2
        // ig_md.lkp_2.l2_valid     = true;
        // ig_md.lkp_2.mac_src_addr = hdr.transport.ethernet.src_addr;
        // ig_md.lkp_2.mac_dst_addr = hdr.transport.ethernet.dst_addr;
        // ig_md.lkp_2.mac_type     = hdr.transport.ethernet.ether_type;
#endif // INGRESS_PARSER_POPULATES_LKP_2

        transition select(hdr.transport.ethernet.ether_type) {
            ETHERTYPE_NSH:  parse_transport_nsh;
            ETHERTYPE_VLAN: parse_transport_vlan_0;
            ETHERTYPE_QINQ: construct_transport_spbm;
            default: construct_transport_nsh_only;
        }
    }
    
    // -------------------------------------------------------------------------
    state parse_transport_ethernet_cpu {
        ig_md.flags.transport_valid = true;
        pkt.extract(hdr.transport.ethernet);

#ifdef CPU_FABRIC_HEADER_ENABLE
        pkt.extract(hdr.fabric);
#endif // CPU_FABRIC_HEADER_ENABLE
        pkt.extract(hdr.cpu);

#ifdef CPU_IG_BYPASS_ENABLE
        ig_md.bypass = (bit<8>)hdr.cpu.reason_code;
#endif
        ig_md.ingress_port = (switch_port_t) hdr.cpu.ingress_port;
        //ig_md.egress_port_lag_index = (switch_port_lag_index_t) hdr.cpu.port_lag_index;
        ig_md.flags.bypass_egress = (bool) hdr.cpu.tx_bypass;
        //ig_md.bd = (switch_bd_t)hdr.cpu.ingress_bd;
        hdr.transport.ethernet.ether_type = hdr.cpu.ether_type;
        ether_type_transport = hdr.cpu.ether_type;
// #ifdef PTP_ENABLE
//         ig_md.flags.capture_ts = (bool) hdr.cpu.capture_ts;  // todo
// #endif // PTP_ENABLE
        
#ifdef INGRESS_PARSER_POPULATES_LKP_0
        ig_md.lkp_0.l2_valid     = true;
        ig_md.lkp_0.mac_src_addr = hdr.transport.ethernet.src_addr;
        ig_md.lkp_0.mac_dst_addr = hdr.transport.ethernet.dst_addr;
        ig_md.lkp_0.mac_type     = hdr.cpu.ether_type;
#endif // INGRESS_PARSER_POPULATES_LKP_0        

// populate for L3-tunnel case (where there's no L2 present)
#ifdef INGRESS_PARSER_POPULATES_LKP_1
        ig_md.lkp_1.l2_valid     = true;
        ig_md.lkp_1.mac_src_addr = hdr.transport.ethernet.src_addr;
        ig_md.lkp_1.mac_dst_addr = hdr.transport.ethernet.dst_addr;
        ig_md.lkp_1.mac_type     = hdr.cpu.ether_type;
#endif // INGRESS_PARSER_POPULATES_LKP_1

// populate for L3-tunnel case (where there's no L2 present)        
#ifdef INGRESS_PARSER_POPULATES_LKP_2
        // ig_md.lkp_2.l2_valid     = true;
        // ig_md.lkp_2.mac_src_addr = hdr.transport.ethernet.src_addr;
        // ig_md.lkp_2.mac_dst_addr = hdr.transport.ethernet.dst_addr;
        // ig_md.lkp_2.mac_type     = hdr.cpu.ether_type;
#endif // INGRESS_PARSER_POPULATES_LKP_2
        
        transition select(hdr.cpu.ether_type) {
            ETHERTYPE_NSH:  parse_transport_nsh;
            ETHERTYPE_VLAN: parse_transport_vlan_0;
            default: construct_transport_nsh_only;            
        }
    }
        
    // -------------------------------------------------------------------------
    state parse_transport_vlan_0 {
        pkt.extract(hdr.transport.vlan_tag[0]);
        ether_type_transport = hdr.transport.vlan_tag[0].ether_type;
        
//#ifdef INGRESS_PARSER_POPULATES_LKP_0
  #ifndef SF_0_L2_VLAN_ID_ENABLE
        ig_md.lkp_0.tunnel_type = SWITCH_TUNNEL_TYPE_VLAN;        
  #endif // SF_0_L2_VLAN_ID_ENABLE
//#endif

#ifdef INGRESS_PARSER_POPULATES_LKP_0
        ig_md.lkp_0.pcp = hdr.transport.vlan_tag[0].pcp;
  #ifdef SF_0_L2_VLAN_ID_ENABLE
        ig_md.lkp_0.vid = hdr.transport.vlan_tag[0].vid;
  #endif // SF_0_L2_VLAN_ID_ENABLE
        ig_md.lkp_0.mac_type = hdr.transport.vlan_tag[0].ether_type;
#endif // INGRESS_PARSER_POPULATES_LKP_0

// populate for L3-tunnel case (where there's no L2 present)
#ifdef INGRESS_PARSER_POPULATES_LKP_1
        ig_md.lkp_1.pcp = hdr.transport.vlan_tag[0].pcp;
  #ifdef SF_0_L2_VLAN_ID_ENABLE
        ig_md.lkp_1.vid = hdr.transport.vlan_tag[0].vid;
  #endif // SF_0_L2_VLAN_ID_ENABLE
        ig_md.lkp_1.mac_type = hdr.transport.vlan_tag[0].ether_type;
#endif // INGRESS_PARSER_POPULATES_LKP_1

// populate for L3-tunnel case (where there's no L2 present)
#ifdef INGRESS_PARSER_POPULATES_LKP_2
  //       ig_md.lkp_2.pcp = hdr.transport.vlan_tag[0].pcp;
  // #ifdef SF_0_L2_VLAN_ID_ENABLE
  //       ig_md.lkp_2.vid = hdr.transport.vlan_tag[0].vid;
  // #endif // SF_0_L2_VLAN_ID_ENABLE
  //       ig_md.lkp_2.mac_type = hdr.transport.vlan_tag[0].ether_type;
#endif // INGRESS_PARSER_POPULATES_LKP_2
        
        transition select(hdr.transport.vlan_tag[0].ether_type) {
            ETHERTYPE_NSH:  parse_transport_nsh;
            ETHERTYPE_VLAN: parse_transport_vlan_unsupported;
            default: construct_transport_nsh_only;
        }
    }
    state parse_transport_vlan_unsupported {
        ig_md.lkp_0.tunnel_type = SWITCH_TUNNEL_TYPE_UNSUPPORTED;
        ig_md.lkp_0.tunnel_id = 0;
        transition reject;
    }
    state construct_transport_nsh_only {
        transition select(TRANSPORT_INGRESS_ENABLE) {
            true: parse_transport_etype_additional;
            false: accept;
        }
    }
    state parse_transport_etype_additional {
        transition select(ether_type_transport) {
            ETHERTYPE_MPLS: construct_transport_mpls;
            ETHERTYPE_IPV4: construct_transport_ipv4;
            ETHERTYPE_IPV6: construct_transport_ipv6;
            default: accept;
        }
    }

    ////////////////////////////////////////////////////////////////////////////
    // Layer2 - Transport - SPBM
    ////////////////////////////////////////////////////////////////////////////
    // For the initial crack at this:
    //   - B-DA and B-SA were extracted into transport.hdr.ethernet
    //   - Use hdr.transport.vlan_tag[0] for both btag and itag extraction.
    //       (itag extraction will overwrite btag extraction)
    //   - Populate lkp.vid w/ btag.vid. (for both lkp[0] and lkp[1])
    //   - Populate lkp.tunnel-id w/ i-sid. (for both lkp[0] and lkp[1])
    //       (we're actually populating tunnel-id w/ whole 32bit i-tci)
    //   - All other lkp fields will be populated in MAU as needed:
    //       We want to overload L3 SIP/DIP w/ { B-VID[11:0], B-DA[47:0] }
    //       but we're having trouble trying to get this to work in parser.

    state construct_transport_spbm {
        transition select(TRANSPORT_INGRESS_ENABLE,
                          TRANSPORT_SPBM_INGRESS_ENABLE) {
            (false,     _): reject;
            ( true, false): parse_transport_vlan_unsupported;
            ( true,  true): parse_transport_spbm_btag;
        }
    }
    
    state parse_transport_spbm_btag {
        pkt.extract(hdr.transport.vlan_tag[0]);

        ig_md.lkp_0.tunnel_type = SWITCH_TUNNEL_TYPE_UNSUPPORTED;
        ig_md.lkp_0.tunnel_id = pkt.lookahead<bit<32>>(); // whole i-tci
        ig_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_UNSUPPORTED;
        ig_md.lkp_1.tunnel_id = pkt.lookahead<bit<32>>(); // whole i-tci

        ig_md.lkp_0.vid = hdr.transport.vlan_tag[0].vid; // goes nowhere
        ig_md.lkp_1.vid = hdr.transport.vlan_tag[0].vid;

        // Overload L3 SIP/DIP w/ { B-VID[11:0], B-DA[47:0] }
        // (didn't fit, so vid and da was run to dst-vtep directly in MAU)
        // ig_md.lkp_0.ip_src_addr[31:0] = hdr.transport.ethernet.dst_addr[31:0];
        // ig_md.lkp_0.ip_dst_addr[31:0] = 4w0 \
        //                                 ++ ig_md.lkp_1.vid \
        //                                 ++ hdr.transport.ethernet.dst_addr[47:32];
        
        transition select(hdr.transport.vlan_tag[0].ether_type) {
            ETHERTYPE_MINM: parse_transport_spbm_itag;
            default: parse_transport_vlan_unsupported;
        }
    }

    state parse_transport_spbm_itag {
        // todo: should we simply skip ahead here and not extract/overwrite?
        //       (since we already have i-tci fields captured in tunnel-id)
        pkt.extract(hdr.transport.vlan_tag[0]); // overwrite b-tag extraction
        ig_md.lkp_0.tunnel_type = SWITCH_TUNNEL_TYPE_SPBM;
        //ig_md.lkp_0.tunnel_id = // set via lookahead in previous state
        ig_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_SPBM;
        //ig_md.lkp_1.tunnel_id = // set via lookahead in previous state

        transition parse_outer_ethernet;
    }

    
    ////////////////////////////////////////////////////////////////////////////
    // Layer3 - Transport
    ////////////////////////////////////////////////////////////////////////////

    // todo: currently we're extracting the ip-header, even if it contains
    //       unsupported ip-options (or frag). is this acceptable, or would it
    //       be better to extract the ip-header after being fully qualified?
    //
    // todo: same question applies to setting lookup metadata fields - would
    //       it be better to only set these if ip is fully qualified?
    //
    // todo: we're currently only setting UNSUPPORTED tunnel-type if we detect
    //       ipv4 options or frag. we're not attempting to detect IPv6 options
    //       currently as this would require more tcam resources to qualify
    //       more protocol field values. is this acceptable, or do we need to
    //       detect ipv6 options, and set UNSUPPORTED tunnel type?
    
    state construct_transport_ipv4 {
        transition select(TRANSPORT_IPV4_INGRESS_ENABLE) {
            true: qualify_transport_ipv4;
            false: reject;
        }
    }

    state qualify_transport_ipv4 {
        ig_md.flags.transport_valid = true;
        pkt.extract(hdr.transport.ipv4);
#ifdef INGRESS_PARSER_POPULATES_LKP_0
        //ig_md.lkp_0.ip_type      = SWITCH_IP_TYPE_IPV4;
        ig_md.lkp_0.ip_proto       = hdr.transport.ipv4.protocol;
        ig_md.lkp_0.ip_tos         = hdr.transport.ipv4.tos;
        ig_md.lkp_0.ip_flags       = hdr.transport.ipv4.flags;
        ig_md.lkp_0.ip_src_addr_v4 = hdr.transport.ipv4.src_addr;
        ig_md.lkp_0.ip_dst_addr_v4 = hdr.transport.ipv4.dst_addr;
        ig_md.lkp_0.ip_len         = hdr.transport.ipv4.total_len;
#endif
        transition select(hdr.transport.ipv4.ihl,
                          hdr.transport.ipv4.frag_offset) {
            (5, 0): parse_transport_ipv4;
            default: parse_transport_ip_unsupported;
        }
    }
    
    state parse_transport_ipv4 {    
        transition select(hdr.transport.ipv4.protocol) {
           IP_PROTOCOLS_GRE: construct_transport_gre;
           IP_PROTOCOLS_UDP: construct_transport_udp_tunnel;
           default: accept;
        }
    }


    //--------------------------------------------------------------------------
    state construct_transport_ipv6 {
        transition select(
            TRANSPORT_IPV6_INGRESS_ENABLE,
            TRANSPORT_IPV6_REDUCED_ADDR) {
            (true, false): parse_transport_ipv6;
            (true, true): parse_transport_ipv6_reduced_addr;
            (false, _): reject;
        }
    }

    state parse_transport_ipv6 {
        pkt.extract(hdr.transport.ipv6);
#ifdef INGRESS_PARSER_POPULATES_LKP_0
        //ig_md.lkp_0.ip_type      = SWITCH_IP_TYPE_IPV6;
        ig_md.lkp_0.ip_proto     = hdr.transport.ipv6.next_hdr;
        //ig_md.lkp_0.ip_tos       = hdr.transport.ipv6.tos; // not byte-aligned so set in mau
        ig_md.lkp_0.ip_src_addr  = hdr.transport.ipv6.src_addr;
        ig_md.lkp_0.ip_dst_addr  = hdr.transport.ipv6.dst_addr;
        ig_md.lkp_0.ip_len       = hdr.transport.ipv6.payload_len;
#endif
        transition select(hdr.transport.ipv6.next_hdr) {
            IP_PROTOCOLS_GRE: construct_transport_gre;
            default: accept;
        }
    }

    state parse_transport_ipv6_reduced_addr {
        pkt.extract(hdr.transport.ipv6);
#ifdef INGRESS_PARSER_POPULATES_LKP_0
        //ig_md.lkp_0.ip_type        = SWITCH_IP_TYPE_IPV6;
        ig_md.lkp_0.ip_proto       = hdr.transport.ipv6.next_hdr;
        //ig_md.lkp_0.ip_tos         = hdr.transport.ipv6.tos; // not byte-aligned so set in mau
        ig_md.lkp_0.ip_src_addr_v4 = hdr.transport.ipv6.src_addr[95:64];
        ig_md.lkp_0.ip_dst_addr_v4 = hdr.transport.ipv6.dst_addr[95:64];
        ig_md.lkp_0.ip_len         = hdr.transport.ipv6.payload_len;
#endif        
        transition select(hdr.transport.ipv6.next_hdr) {
            IP_PROTOCOLS_GRE: construct_transport_gre;
            default: accept;
        }
    }

    state parse_transport_ip_unsupported {
        ig_md.lkp_0.tunnel_type = SWITCH_TUNNEL_TYPE_UNSUPPORTED;
        ig_md.lkp_0.tunnel_id = 0;
        transition reject;
    }
    
    
    ////////////////////////////////////////////////////////////////////////////
    // Layer4 - UDP
    ////////////////////////////////////////////////////////////////////////////

    state construct_transport_udp_tunnel {
        transition select(TRANSPORT_IPV4_VXLAN_INGRESS_ENABLE,     
                          TRANSPORT_IPV4_GENEVE_INGRESS_ENABLE) {
            (false, true): parse_transport_udp_geneve;
            (true, false): parse_transport_udp_vxlan;
            (true, true): parse_transport_udp_vxlan_geneve;
            default: reject; // should never get here
        }
    }

    state parse_transport_udp_geneve {
        pkt.extract(hdr.transport.udp);
#ifdef INGRESS_PARSER_POPULATES_LKP_0        
        ig_md.lkp_0.l4_src_port = hdr.transport.udp.src_port;
        ig_md.lkp_0.l4_dst_port = hdr.transport.udp.dst_port;       
#endif
        transition select(hdr.transport.udp.dst_port) {            
            UDP_PORT_GENV: parse_transport_geneve;        
            default: accept;
        }
    }

    state parse_transport_udp_vxlan {
        pkt.extract(hdr.transport.udp);
#ifdef INGRESS_PARSER_POPULATES_LKP_0        
        ig_md.lkp_0.l4_src_port = hdr.transport.udp.src_port;
        ig_md.lkp_0.l4_dst_port = hdr.transport.udp.dst_port;       
#endif    
        transition select(hdr.transport.udp.dst_port) {            
            UDP_PORT_VXLAN: parse_transport_vxlan;
            default: accept;
        }
    }

    state parse_transport_udp_vxlan_geneve {
        pkt.extract(hdr.transport.udp);
#ifdef INGRESS_PARSER_POPULATES_LKP_0        
        ig_md.lkp_0.l4_src_port = hdr.transport.udp.src_port;
        ig_md.lkp_0.l4_dst_port = hdr.transport.udp.dst_port;       
#endif
        transition select(hdr.transport.udp.dst_port) {            
            UDP_PORT_VXLAN: parse_transport_vxlan;
            UDP_PORT_GENV: parse_transport_geneve;        
            default: accept;
        }
    }


    ////////////////////////////////////////////////////////////////////////////
    // Layer X - Transport
    ////////////////////////////////////////////////////////////////////////////

    //--------------------------------------------------------------------------
    // Multi-Protocol Label Switching Segment Routing (MPLS-SR) - Transport
    //--------------------------------------------------------------------------

    // state construct_transport_mpls {
    //     transition select(TRANSPORT_MPLS_INGRESS_ENABLE) {
    //         true: parse_transport_mpls_0;
    //         default: reject;
    //     }
    // }
    state construct_transport_mpls {
        transition select(
            TRANSPORT_EoMPLS_INGRESS_ENABLE,
            TRANSPORT_IPoMPLS_INGRESS_ENABLE) {
            (true,   _): parse_transport_mpls_0;
            (   _,true): parse_transport_mpls_0;
            default: reject;
        }
    }
    state parse_transport_mpls_0 {
        ig_md.lkp_0.tunnel_type = SWITCH_TUNNEL_TYPE_MPLS;
        ig_md.lkp_0.tunnel_id = pkt.lookahead<bit<32>>();
        pkt.extract(hdr.transport.mpls_0);
        transition select(hdr.transport.mpls_0.bos) {
            0: parse_transport_mpls_1;
            1: parse_transport_mpls_fanout;
        }
    }
    state parse_transport_mpls_1 {
        ig_md.lkp_0.tunnel_id = pkt.lookahead<bit<32>>();
        pkt.extract(hdr.transport.mpls_1);
        transition select(hdr.transport.mpls_1.bos) {
            0: construct_transport_mpls_2;
            1: parse_transport_mpls_fanout;
        }
    }
    state construct_transport_mpls_2 {
        transition select(MPLS_DEPTH_TRANSPORT) {
            1: parse_transport_mpls_unsupported; // unsupported param value
            2: parse_transport_mpls_unsupported;
            default: parse_transport_mpls_2;
        }
    }
    state parse_transport_mpls_2 {
        ig_md.lkp_0.tunnel_id = pkt.lookahead<bit<32>>();
        pkt.extract(hdr.transport.mpls_2);
        transition select(hdr.transport.mpls_2.bos) {
            0: parse_transport_mpls_3;
            1: parse_transport_mpls_fanout;
        }
    }
    state parse_transport_mpls_3 {
        ig_md.lkp_0.tunnel_id = pkt.lookahead<bit<32>>();
        pkt.extract(hdr.transport.mpls_3);
        transition select(hdr.transport.mpls_3.bos) {
            0: construct_transport_mpls_4;
            1: parse_transport_mpls_fanout;
        }
    }
    state construct_transport_mpls_4 {
        transition select(MPLS_DEPTH_TRANSPORT) {
            3: parse_transport_mpls_unsupported; // unsupported param value
            4: parse_transport_mpls_unsupported;
            default: parse_transport_mpls_4;
        }
    }
    state parse_transport_mpls_4 {
        ig_md.lkp_0.tunnel_id = pkt.lookahead<bit<32>>();
        pkt.extract(hdr.transport.mpls_4);
        transition select(hdr.transport.mpls_4.bos) {
            0: parse_transport_mpls_5;
            1: parse_transport_mpls_fanout;
        }
    }
    state parse_transport_mpls_5 {
        ig_md.lkp_0.tunnel_id = pkt.lookahead<bit<32>>();
        pkt.extract(hdr.transport.mpls_5);
        transition select(hdr.transport.mpls_5.bos) {
            0: parse_transport_mpls_unsupported;
            1: parse_transport_mpls_fanout;
        }
    }
    state parse_transport_mpls_unsupported {
        ig_md.lkp_0.tunnel_type = SWITCH_TUNNEL_TYPE_UNSUPPORTED;
        ig_md.lkp_0.tunnel_id = 0;
        transition reject;
    }
    // // fanout state that uses port metadata table for branch decision
    // state parse_transport_mpls_fanout {
    //     transition select(
    //         transport_eompls_enable,
    //         pkt.lookahead<bit<4>>()) {
    //         (0, 0x4): qualify_outer_ipv4;
    //         (0, 0x6): construct_outer_ipv6;
    //         (1,   _): parse_outer_ethernet;
    //         default: reject;
    //     }
    // }
    // fanout state that uses feature defines for branch decision
    state parse_transport_mpls_fanout {
        transition select(
            TRANSPORT_EoMPLS_INGRESS_ENABLE,
            TRANSPORT_IPoMPLS_INGRESS_ENABLE) {
            (true, false): parse_transport_mpls_fanout_eompls;
            (false, true): parse_transport_mpls_fanout_ipompls;
            default: reject;
        }
    }
    state parse_transport_mpls_fanout_eompls {
        transition parse_outer_ethernet;
    }
    state parse_transport_mpls_fanout_ipompls {
        transition select(pkt.lookahead<bit<4>>()) {
            4: qualify_outer_ipv4;
            6: construct_outer_ipv6;
            default: reject;
        }
    }

    
    ////////////////////////////////////////////////////////////////////////////
    // Tunnels - Transport
    ////////////////////////////////////////////////////////////////////////////    

    //--------------------------------------------------------------------------
    // Virtual Extensible Local Area Network (VXLAN) - Transport
    //--------------------------------------------------------------------------

    state parse_transport_vxlan {
        pkt.extract(hdr.transport.vxlan);
        ig_md.lkp_0.tunnel_type = SWITCH_TUNNEL_TYPE_VXLAN;
        ig_md.lkp_0.tunnel_id = (bit<switch_tunnel_id_width>)hdr.transport.vxlan.vni;
        transition parse_outer_ethernet;
    }

    //--------------------------------------------------------------------------
    // Generic Network Virtualization Encapsulation (GENEVE) - Transport
    //--------------------------------------------------------------------------

    state parse_transport_geneve {
        geneve_h snoop_geneve = pkt.lookahead<geneve_h>();
        ig_md.lkp_0.tunnel_type = SWITCH_TUNNEL_TYPE_UNSUPPORTED;

        transition select(
            snoop_geneve.ver,
            snoop_geneve.opt_len,
            snoop_geneve.O,
            snoop_geneve.C,
            snoop_geneve.proto_type) {        
            (0,0,0,0,ETHERTYPE_ENET): parse_transport_geneve_qualified;
            (0,0,0,0,ETHERTYPE_IPV4): parse_transport_geneve_qualified;
            (0,0,0,0,ETHERTYPE_IPV6): parse_transport_geneve_qualified;
            default: accept;
        }
    }

    state parse_transport_geneve_qualified {    
        pkt.extract(hdr.transport.geneve);
        ig_md.lkp_0.tunnel_type = SWITCH_TUNNEL_TYPE_GENEVE;
        ig_md.lkp_0.tunnel_id = (bit<switch_tunnel_id_width>)hdr.transport.geneve.vni;

        transition select(hdr.transport.geneve.proto_type) {
            ETHERTYPE_ENET: parse_outer_ethernet;
            ETHERTYPE_IPV4: qualify_outer_ipv4;
            ETHERTYPE_IPV6: construct_outer_ipv6;
            default: accept;
        }
    }

    //--------------------------------------------------------------------------
    // GRE - Transport
    //--------------------------------------------------------------------------

    state construct_transport_gre {
        transition select(TRANSPORT_GRE_INGRESS_ENABLE,
                          TRANSPORT_ERSPAN_INGRESS_ENABLE) {    
            (true, false): parse_transport_gre;
            (   _, true): parse_transport_gre_erspan;
            default: reject;
        }
    }

    state parse_transport_gre {
        gre_h snoop_gre = pkt.lookahead<gre_h>();
        ig_md.lkp_0.tunnel_type = SWITCH_TUNNEL_TYPE_UNSUPPORTED;
        ig_md.lkp_0.tunnel_id = 0;
        transition select(
            snoop_gre.C,
            snoop_gre.R,
            snoop_gre.K,
            snoop_gre.S,
            snoop_gre.s,
            snoop_gre.recurse,
            snoop_gre.flags,
            snoop_gre.version) {
          // C R K S s r f v
            (0,0,0,0,0,0,0,0): parse_transport_gre_qualified;
            default: accept;
        }
    }

    state parse_transport_gre_erspan {
        gre_h snoop_gre = pkt.lookahead<gre_h>();
        ig_md.lkp_0.tunnel_type = SWITCH_TUNNEL_TYPE_UNSUPPORTED;
        ig_md.lkp_0.tunnel_id = 0;
        transition select(
            snoop_gre.C,
            snoop_gre.R,
            snoop_gre.K,
            snoop_gre.S,
            snoop_gre.s,
            snoop_gre.recurse,
            snoop_gre.flags,
            snoop_gre.version) {
          // C R K S s r f v
            (0,0,0,0,0,0,0,0): parse_transport_gre_erspan_qualified;
            (0,0,0,1,0,0,0,0): parse_transport_gre_erspan_qualified;
            default: accept;
        }
    }

    state parse_transport_gre_qualified {
        pkt.extract(hdr.transport.gre);
        ig_md.lkp_0.tunnel_type = SWITCH_TUNNEL_TYPE_GRE;
        ig_md.lkp_0.tunnel_id = 0;
        transition select(hdr.transport.gre.S, hdr.transport.gre.proto) {
            (0,ETHERTYPE_IPV4): qualify_outer_ipv4;
            (0,ETHERTYPE_IPV6): construct_outer_ipv6;
            default: accept;
        }
    }

    state parse_transport_gre_erspan_qualified {
        pkt.extract(hdr.transport.gre);
        ig_md.lkp_0.tunnel_type = SWITCH_TUNNEL_TYPE_GRE;
        ig_md.lkp_0.tunnel_id = 0;
        transition select(hdr.transport.gre.S, hdr.transport.gre.proto) {
            (0,ETHERTYPE_IPV4): qualify_outer_ipv4;
            (0,ETHERTYPE_IPV6): construct_outer_ipv6;
            (1,GRE_PROTOCOLS_ERSPAN_TYPE_2): construct_transport_erspan_t2;
            //(1,GRE_PROTOCOLS_ERSPAN_TYPE_3): parse_transport_erspan_t3;
            default: accept;
        }
    }

    
    //--------------------------------------------------------------------------
    // ERSPAN - Transport
    //--------------------------------------------------------------------------

    state construct_transport_erspan_t2 {
        transition select(TRANSPORT_ERSPAN_INGRESS_SET_TUNNEL_ID) {    
            false: parse_transport_erspan_t2;
            true: parse_transport_erspan_t2_set_tunnel_id;
        }
    }

    state parse_transport_erspan_t2 {
        pkt.extract(hdr.transport.gre_sequence);
        pkt.extract(hdr.transport.erspan_type2);
        ig_md.lkp_0.tunnel_type = SWITCH_TUNNEL_TYPE_ERSPAN;
        ig_md.lkp_0.tunnel_id = 0;
        transition parse_outer_ethernet;
    }

    state parse_transport_erspan_t2_set_tunnel_id {
        pkt.extract(hdr.transport.gre_sequence);
        pkt.extract(hdr.transport.erspan_type2);
        ig_md.lkp_0.tunnel_type = SWITCH_TUNNEL_TYPE_ERSPAN;
        ig_md.lkp_0.tunnel_id = (bit<switch_tunnel_id_width>)hdr.transport.erspan_type2.session_id;
        transition parse_outer_ethernet;
    }

    // state parse_transport_erspan_t3 {
    //     pkt.extract(hdr.transport.gre_sequence);
    //     pkt.extract(hdr.transport.erspan_type3);
    //     ig_md.lkp_0.tunnel_type = SWITCH_TUNNEL_TYPE_ERSPAN;
    //     transition select(hdr.transport.erspan_type3.o) {
    //         1: parse_erspan_type3_platform;
    //         default: parse_inner_ethernet;
    //     }
    // }
    // 
    // state parse_transport_erspan_type3_platform {
    //     pkt.extract(hdr.transport.erspan_platform);
    //     transition parse_outer_ethernet;
    // }
   
    
    //--------------------------------------------------------------------------
    // NSH - Transport
    //--------------------------------------------------------------------------

    state parse_transport_nsh {
        pkt.extract(hdr.transport.nsh_type1);

        ig_md.nsh_md.ttl = hdr.transport.nsh_type1.ttl;
        ig_md.nsh_md.spi = (bit<SPI_WIDTH>)hdr.transport.nsh_type1.spi;
        ig_md.nsh_md.si = hdr.transport.nsh_type1.si;
        ig_md.nsh_md.ver = hdr.transport.nsh_type1.ver;
        ig_md.nsh_md.vpn = (bit<VPN_ID_WIDTH>)hdr.transport.nsh_type1.vpn;
        ig_md.nsh_md.scope = hdr.transport.nsh_type1.scope;
        ig_md.nsh_md.sap = (bit<SSAP_ID_WIDTH>)hdr.transport.nsh_type1.sap;

        transition select(hdr.transport.nsh_type1.next_proto) {
            NSH_PROTOCOLS_ETH: parse_outer_ethernet;
            default: accept;  // todo: support ipv4? ipv6?
        }
    }

    
    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////
    // "Outer" Headers / Stack
    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////
    
    ////////////////////////////////////////////////////////////////////////////
    // Layer2 - Outer (ETH)
    ////////////////////////////////////////////////////////////////////////////

    state parse_outer_ethernet {
        pkt.extract(hdr.outer.ethernet);
        ether_type_outer = hdr.outer.ethernet.ether_type;
#ifdef INGRESS_PARSER_POPULATES_LKP_1
        ig_md.lkp_1.l2_valid     = true;
        ig_md.lkp_1.mac_src_addr = hdr.outer.ethernet.src_addr;
        ig_md.lkp_1.mac_dst_addr = hdr.outer.ethernet.dst_addr;
        ig_md.lkp_1.mac_type     = hdr.outer.ethernet.ether_type;
        ig_md.lkp_1.pcp = 0;
        ig_md.lkp_1.vid = 0;        
#endif // INGRESS_PARSER_POPULATES_LKP_1

// populate for L3-tunnel case (where there's no L2 present)
#ifdef INGRESS_PARSER_POPULATES_LKP_2
        // ig_md.lkp_2.l2_valid     = true;
        // ig_md.lkp_2.mac_src_addr = hdr.outer.ethernet.src_addr;
        // ig_md.lkp_2.mac_dst_addr = hdr.outer.ethernet.dst_addr;
        // ig_md.lkp_2.mac_type     = hdr.outer.ethernet.ether_type;
        // ig_md.lkp_2.pcp = 0;
        // ig_md.lkp_2.vid = 0;
#endif // INGRESS_PARSER_POPULATES_LKP_2
        transition select(hdr.outer.ethernet.ether_type) {
            ETHERTYPE_BR : construct_outer_br;
            ETHERTYPE_VN : construct_outer_vn;
            ETHERTYPE_VLAN : parse_outer_vlan_0;
            ETHERTYPE_QINQ : parse_outer_vlan_0;
            //ETHERTYPE_MPLS : construct_outer_mpls;
            ////ETHERTYPE_ARP  : parse_outer_arp;
            //ETHERTYPE_IPV4 : qualify_outer_ipv4;
            //ETHERTYPE_IPV6 : construct_outer_ipv6;
            //default : accept;
            default: branch_outer_l2_ether_type;
        }
    }

    state parse_outer_ethernet_cpu {
        pkt.extract(hdr.outer.ethernet);
#ifdef CPU_FABRIC_HEADER_ENABLE
        pkt.extract(hdr.fabric);
#endif // CPU_FABRIC_HEADER_ENABLE
        pkt.extract(hdr.cpu);
        ether_type_outer = hdr.cpu.ether_type;
#ifdef CPU_IG_BYPASS_ENABLE
        ig_md.bypass = (bit<8>)hdr.cpu.reason_code;
#endif
        ig_md.ingress_port = (switch_port_t) hdr.cpu.ingress_port;
        // ig_md.egress_port_lag_index = (switch_port_lag_index_t) hdr.cpu.port_lag_index;
        ig_md.flags.bypass_egress = (bool)hdr.cpu.tx_bypass;
        // ig_md.bd = (switch_bd_t)hdr.cpu.ingress_bd;
        hdr.outer.ethernet.ether_type = hdr.cpu.ether_type;
// #ifdef PTP_ENABLE
//         ig_md.flags.capture_ts = (bool) hdr.cpu.capture_ts;  // todo
// #endif // PTP_ENABLE
#ifdef INGRESS_PARSER_POPULATES_LKP_1
        ig_md.lkp_1.l2_valid     = true;
        ig_md.lkp_1.mac_src_addr = hdr.outer.ethernet.src_addr;
        ig_md.lkp_1.mac_dst_addr = hdr.outer.ethernet.dst_addr;
        ig_md.lkp_1.mac_type     = hdr.cpu.ether_type;
        ig_md.lkp_1.pcp = 0;
        ig_md.lkp_1.vid = 0;        
#endif // INGRESS_PARSER_POPULATES_LKP_1

// populate for L3-tunnel case (where there's no L2 present)
#ifdef INGRESS_PARSER_POPULATES_LKP_2
        // ig_md.lkp_2.l2_valid     = true;
        // ig_md.lkp_2.mac_src_addr = hdr.outer.ethernet.src_addr;
        // ig_md.lkp_2.mac_dst_addr = hdr.outer.ethernet.dst_addr;
        // ig_md.lkp_2.mac_type     = hdr.cpu.ether_type;
        // ig_md.lkp_2.pcp = 0;
        // ig_md.lkp_2.vid = 0;
#endif // INGRESS_PARSER_POPULATES_LKP_2
        transition select(hdr.cpu.ether_type) {            
            ETHERTYPE_BR : construct_outer_br;
            ETHERTYPE_VN : construct_outer_vn;
            ETHERTYPE_VLAN : parse_outer_vlan_0;
            ETHERTYPE_QINQ : parse_outer_vlan_0;
            //ETHERTYPE_MPLS : construct_outer_mpls;
            ////ETHERTYPE_ARP  : parse_outer_arp;
            //ETHERTYPE_IPV4 : qualify_outer_ipv4;
            //ETHERTYPE_IPV6 : construct_outer_ipv6;
            //default : accept;
            default: branch_outer_l2_ether_type;
        }
    }

    // -------------------------------------------------------------------------    
    state construct_outer_br {
        transition select(OUTER_ETAG_ENABLE) {
            true: parse_outer_br;
            false: accept;
        }
    }
    state parse_outer_br {
        pkt.extract(hdr.outer.e_tag);
        ether_type_outer = hdr.outer.e_tag.ether_type;
#ifdef INGRESS_PARSER_POPULATES_LKP_1
        ig_md.lkp_1.mac_type = hdr.outer.e_tag.ether_type;
        //ig_md.lkp_1.pcp = hdr.outer.e_tag.pcp;  // do not populate w/ e-tag
#endif // INGRESS_PARSER_POPULATES_LKP_1

// populate for L3-tunnel case (where there's no L2 present)
#ifdef INGRESS_PARSER_POPULATES_LKP_2
/*
        ig_md.lkp_2.mac_type = hdr.outer.e_tag.ether_type;
        //ig_md.lkp_2.pcp = hdr.outer.e_tag.pcp;  // do not populate w/ e-tag
*/
#endif // INGRESS_PARSER_POPULATES_LKP_2
        transition select(hdr.outer.e_tag.ether_type) {
            ETHERTYPE_VLAN : parse_outer_vlan_0;
            ETHERTYPE_QINQ : parse_outer_vlan_0;
            //ETHERTYPE_MPLS : construct_outer_mpls;
            //ETHERTYPE_IPV4 : qualify_outer_ipv4;
            ////ETHERTYPE_ARP  : parse_outer_arp;
            //ETHERTYPE_IPV6 : construct_outer_ipv6;
            //default : accept;
            default: branch_outer_l2_ether_type;
        }
    }

    // -------------------------------------------------------------------------    
    state construct_outer_vn {
        transition select(OUTER_VNTAG_ENABLE) {
            true: parse_outer_vn;
            false: accept;
        }
    }
    state parse_outer_vn {
        pkt.extract(hdr.outer.vn_tag);
        ether_type_outer = hdr.outer.vn_tag.ether_type;
#ifdef INGRESS_PARSER_POPULATES_LKP_1        
        ig_md.lkp_1.mac_type = hdr.outer.vn_tag.ether_type;
#endif // INGRESS_PARSER_POPULATES_LKP_1

// populate for L3-tunnel case (where there's no L2 present)
#ifdef INGRESS_PARSER_POPULATES_LKP_2
/*
        ig_md.lkp_2.mac_type = hdr.outer.vn_tag.ether_type;        
*/
#endif // INGRESS_PARSER_POPULATES_LKP_2
        transition select(hdr.outer.vn_tag.ether_type) {
            ETHERTYPE_VLAN : parse_outer_vlan_0;
            ETHERTYPE_QINQ : parse_outer_vlan_0;
            //ETHERTYPE_MPLS : construct_outer_mpls;
            //ETHERTYPE_IPV4 : qualify_outer_ipv4;
            ////ETHERTYPE_ARP  : parse_outer_arp;
            //ETHERTYPE_IPV6 : construct_outer_ipv6;
            //default : accept;
            default: branch_outer_l2_ether_type;
        }
    }

    // -------------------------------------------------------------------------    
    state parse_outer_vlan_0 {
        pkt.extract(hdr.outer.vlan_tag[0]);
        ether_type_outer = hdr.outer.vlan_tag[0].ether_type;
//#ifdef INGRESS_PARSER_POPULATES_LKP_1
  #ifndef SF_0_L2_VLAN_ID_ENABLE
        ig_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_VLAN;
  #endif // SF_0_L2_VLAN_ID_ENABLE
//#endif // INGRESS_PARSER_POPULATES_LKP_1
        
#ifdef INGRESS_PARSER_POPULATES_LKP_1        
        ig_md.lkp_1.pcp = hdr.outer.vlan_tag[0].pcp;
  #ifdef SF_0_L2_VLAN_ID_ENABLE
        ig_md.lkp_1.vid = hdr.outer.vlan_tag[0].vid;
  #endif // SF_0_L2_VLAN_ID_ENABLE
        ig_md.lkp_1.mac_type = hdr.outer.vlan_tag[0].ether_type;
#endif // INGRESS_PARSER_POPULATES_LKP_1

// populate for L3-tunnel case (where there's no L2 present)
#ifdef INGRESS_PARSER_POPULATES_LKP_2
  //       ig_md.lkp_2.pcp = hdr.outer.vlan_tag[0].pcp;
  // #ifdef SF_0_L2_VLAN_ID_ENABLE
  //       ig_md.lkp_2.vid = hdr.outer.vlan_tag[0].vid;
  // #endif // SF_0_L2_VLAN_ID_ENABLE
  //       ig_md.lkp_2.mac_type = hdr.outer.vlan_tag[0].ether_type;
#endif // INGRESS_PARSER_POPULATES_LKP_2
        transition select(hdr.outer.vlan_tag[0].ether_type) {
            ETHERTYPE_VLAN : parse_outer_vlan_1;
            //ETHERTYPE_MPLS : construct_outer_mpls;
            //ETHERTYPE_IPV4 : qualify_outer_ipv4;
            //ETHERTYPE_IPV6 : construct_outer_ipv6;
            //default : accept;
            default: branch_outer_l2_ether_type;
        }
    }
    
    state parse_outer_vlan_1 {
        pkt.extract(hdr.outer.vlan_tag[1]);
        ether_type_outer = hdr.outer.vlan_tag[1].ether_type;
//#ifdef INGRESS_PARSER_POPULATES_LKP_1
  #ifndef SF_0_L2_VLAN_ID_ENABLE
        ig_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_VLAN;
  #endif // SF_0_L2_VLAN_ID_ENABLE
//#endif // INGRESS_PARSER_POPULATES_LKP_1
        
#ifdef INGRESS_PARSER_POPULATES_LKP_1
        ig_md.lkp_1.pcp = hdr.outer.vlan_tag[1].pcp;
  #ifdef SF_0_L2_VLAN_ID_ENABLE
        ig_md.lkp_1.vid = hdr.outer.vlan_tag[1].vid;
  #endif // SF_0_L2_VLAN_ID_ENABLE
        ig_md.lkp_1.mac_type = hdr.outer.vlan_tag[1].ether_type;
#endif // INGRESS_PARSER_POPULATES_LKP_1

// populate for L3-tunnel case (where there's no L2 present)
#ifdef INGRESS_PARSER_POPULATES_LKP_2
  //       ig_md.lkp_2.pcp = hdr.outer.vlan_tag[1].pcp;
  // #ifdef SF_0_L2_VLAN_ID_ENABLE
  //       ig_md.lkp_2.vid = hdr.outer.vlan_tag[1].vid;
  // #endif // SF_0_L2_VLAN_ID_ENABLE
  //       ig_md.lkp_2.mac_type = hdr.outer.vlan_tag[1].ether_type;
#endif // INGRESS_PARSER_POPULATES_LKP_2
        transition select(hdr.outer.vlan_tag[1].ether_type) {
            ETHERTYPE_VLAN : parse_outer_vlan_unsupported;
            //ETHERTYPE_MPLS : construct_outer_mpls;
            //ETHERTYPE_IPV4 : qualify_outer_ipv4;
            //ETHERTYPE_IPV6 : construct_outer_ipv6;
            //default : accept;
            default: branch_outer_l2_ether_type;
        }
    }
    state parse_outer_vlan_unsupported {
        ig_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_UNSUPPORTED;
        ig_md.lkp_1.tunnel_id = 0;
        transition reject;
    }

    state branch_outer_l2_ether_type {
        transition select(ether_type_outer) {
            ETHERTYPE_MPLS: construct_outer_mpls;
            ETHERTYPE_IPV4: qualify_outer_ipv4;
            ETHERTYPE_IPV6: construct_outer_ipv6;
            default: accept;
        }
    }


    // /////////////////////////////////////////////////////////////////////////
    // // Layer 2.5 - Outer
    // /////////////////////////////////////////////////////////////////////////
    // 
    // state parse_outer_arp {
    //     // pkt.extract(hdr.outer.arp);
    //     // transition accept;
    //     transition accept;
    // 
    // }


    ////////////////////////////////////////////////////////////////////////////
    // Layer 3 - Outer
    ////////////////////////////////////////////////////////////////////////////

    // todo: currently we're extracting the ip-header, even if it contains
    //       unsupported ip-options (or frag). is this acceptable, or would it
    //       be better to extract the ip-header after being fully qualified?
    //
    // todo: same question applies to setting lookup metadata fields - would
    //       it be better to only set these if ip is fully qualified?
    //
    // todo: we're currently only setting UNSUPPORTED tunnel-type if we detect
    //       ipv4 options or frag. we're not attempting to detect IPv6 options
    //       currently as this would require more tcam resources to qualify
    //       more protocol field values. is this acceptable, or do we need to
    //       detect ipv6 options, and set UNSUPPORTED tunnel type?
    
    // -------------------------------------------------------------------------    
    state qualify_outer_ipv4 {
        pkt.extract(hdr.outer.ipv4);
        protocol_outer = hdr.outer.ipv4.protocol;
        
#ifdef INGRESS_PARSER_POPULATES_LKP_1
        //ig_md.lkp_1.ip_type        = SWITCH_IP_TYPE_IPV4;
        ig_md.lkp_1.ip_proto       = hdr.outer.ipv4.protocol;
        ig_md.lkp_1.ip_tos         = hdr.outer.ipv4.tos;
        ig_md.lkp_1.ip_flags       = hdr.outer.ipv4.flags;
        ig_md.lkp_1.ip_src_addr_v4 = hdr.outer.ipv4.src_addr;
        ig_md.lkp_1.ip_dst_addr_v4 = hdr.outer.ipv4.dst_addr;
        ig_md.lkp_1.ip_len         = hdr.outer.ipv4.total_len;
#endif // INGRESS_PARSER_POPULATES_LKP_1
        //ipv4_checksum_outer.add(hdr.outer.ipv4);
        //ig_md.flags.ipv4_checksum_err_1 = ipv4_checksum_outer.verify();
        transition select(hdr.outer.ipv4.ihl, hdr.outer.ipv4.frag_offset) {
            (5, 0): construct_outer_ipv4_udf;
            default: parse_outer_ip_unsupported;
        }
    }

    state construct_outer_ipv4_udf {
        transition select(UDF_ENABLE) {
            true: parse_outer_ipv4_udf;
            false: branch_outer_ip;
        }
    }

    state parse_outer_ipv4_udf {
        transition select(hdr.outer.ipv4.protocol, hdr.outer.ipv4.total_len) {
            (IP_PROTOCOLS_UDP,  IP4_WIDTH_BYTES .. MIN_LEN_IP4_UDP_UDF ): parse_outer_udp_noudf;
            (IP_PROTOCOLS_UDP,  _                                      ): parse_outer_udp_udf;
            (IP_PROTOCOLS_TCP,  IP4_WIDTH_BYTES .. MIN_LEN_IP4_TCP_UDF ): parse_outer_tcp_noudf;
            (IP_PROTOCOLS_TCP,  _                                      ): parse_outer_tcp_udf;
            (IP_PROTOCOLS_SCTP, IP4_WIDTH_BYTES .. MIN_LEN_IP4_SCTP_UDF): parse_outer_sctp_noudf;
            (IP_PROTOCOLS_SCTP, _                                      ): parse_outer_sctp_udf;
            default: branch_outer_ip;
        }
    }

    // -------------------------------------------------------------------------    
    state construct_outer_ipv6 {
        transition select(OUTER_IPV6_ENABLE) {
            true: parse_outer_ipv6;
            default: reject;
        }
    }

    state parse_outer_ipv6 {
        pkt.extract(hdr.outer.ipv6);
        protocol_outer = hdr.outer.ipv6.next_hdr;
        
#ifdef INGRESS_PARSER_POPULATES_LKP_1        
        //ig_md.lkp_1.ip_type       = SWITCH_IP_TYPE_IPV6;
        ig_md.lkp_1.ip_proto      = hdr.outer.ipv6.next_hdr;
        //ig_md.lkp_1.ip_tos        = hdr.outer.ipv6.tos; // not byte-aligned so set in mau
        ig_md.lkp_1.ip_src_addr   = hdr.outer.ipv6.src_addr;
        ig_md.lkp_1.ip_dst_addr   = hdr.outer.ipv6.dst_addr;
        ig_md.lkp_1.ip_len        = hdr.outer.ipv6.payload_len;
#endif // INGRESS_PARSER_POPULATES_LKP_1
        transition construct_outer_ipv6_udf;
    }
    
    state construct_outer_ipv6_udf {
        transition select(UDF_ENABLE) {
            true: parse_outer_ipv6_udf;
            false: branch_outer_ip;
        }
    }

    state parse_outer_ipv6_udf {
        transition select(hdr.outer.ipv6.next_hdr, hdr.outer.ipv6.payload_len) {
            (IP_PROTOCOLS_UDP,  16w0 .. MIN_LEN_IP6_UDP_UDF ): parse_outer_udp_noudf;
            (IP_PROTOCOLS_UDP,  _                           ): parse_outer_udp_udf;
            (IP_PROTOCOLS_TCP,  16w0 .. MIN_LEN_IP6_TCP_UDF ): parse_outer_tcp_noudf;
            (IP_PROTOCOLS_TCP,  _                           ): parse_outer_tcp_udf;
            (IP_PROTOCOLS_SCTP, 16w0 .. MIN_LEN_IP6_SCTP_UDF): parse_outer_sctp_noudf;
            (IP_PROTOCOLS_SCTP, _                           ): parse_outer_sctp_udf;
            default: branch_outer_ip;
        }
    }

    // shared fanout/branch state to save tcam resource
    state branch_outer_ip {
        transition select(protocol_outer) {
            IP_PROTOCOLS_IPV4: construct_outer_ipinip_set_tunnel;
            IP_PROTOCOLS_IPV6: construct_outer_ipv6inip_set_tunnel;
            IP_PROTOCOLS_GRE: construct_outer_gre;
            IP_PROTOCOLS_UDP: parse_outer_udp_noudf;
            IP_PROTOCOLS_TCP: parse_outer_tcp_noudf;
            IP_PROTOCOLS_SCTP: parse_outer_sctp_noudf;
            //IP_PROTOCOLS_ESP: parse_outer_esp_overload;
            default: accept;
       }
    }

    state parse_outer_ip_unsupported {
        ig_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_UNSUPPORTED;
        ig_md.lkp_1.tunnel_id = 0;
        transition reject;
    }
    

    ////////////////////////////////////////////////////////////////////////////
    // Layer 4 - Outer
    ////////////////////////////////////////////////////////////////////////////

    //--------------------------------------------------------------------------
    // User Datagram Protocol (UDP) - Outer
    //--------------------------------------------------------------------------

    state parse_outer_udp_noudf {
        pkt.extract(hdr.outer.udp);
        
#ifdef INGRESS_PARSER_POPULATES_LKP_1        
        ig_md.lkp_1.l4_src_port = hdr.outer.udp.src_port;
        ig_md.lkp_1.l4_dst_port = hdr.outer.udp.dst_port;       
#endif // INGRESS_PARSER_POPULATES_LKP_1
        
        transition select(
            hdr.outer.udp.src_port,
            hdr.outer.udp.dst_port) {
            
            (_, UDP_PORT_GENV): construct_outer_geneve;
            (_, UDP_PORT_VXLAN): construct_outer_vxlan;            
            (_, UDP_PORT_GTP_C): construct_outer_gtp_c;
            (UDP_PORT_GTP_C, _): construct_outer_gtp_c;
            (_, UDP_PORT_GTP_U): construct_outer_gtp_u;
            (UDP_PORT_GTP_U, _): construct_outer_gtp_u;
            default : accept;
        }
    }

    state parse_outer_udp_udf {
        pkt.extract(hdr.outer.udp);
        
#ifdef INGRESS_PARSER_POPULATES_LKP_1        
        ig_md.lkp_1.l4_src_port = hdr.outer.udp.src_port;
        ig_md.lkp_1.l4_dst_port = hdr.outer.udp.dst_port;       
#endif // INGRESS_PARSER_POPULATES_LKP_1
        
        transition select(
            hdr.outer.udp.src_port,
            hdr.outer.udp.dst_port) {

            (_, UDP_PORT_GENV): construct_outer_geneve;
            (_, UDP_PORT_VXLAN): construct_outer_vxlan;            
            (_, UDP_PORT_GTP_C): construct_outer_gtp_c;
            (UDP_PORT_GTP_C, _): construct_outer_gtp_c;
            (_, UDP_PORT_GTP_U): construct_outer_gtp_u;
            (UDP_PORT_GTP_U, _): construct_outer_gtp_u;
            default : parse_udf;
        }
    }


    //--------------------------------------------------------------------------
    // Transmission Control Protocol (TCP) - Outer
    //--------------------------------------------------------------------------

    // todo: do we need to flag tcp w/ options as UNSUPPORTED tunnel?
    
    state parse_outer_tcp_noudf {
        pkt.extract(hdr.outer.tcp);
#ifdef INGRESS_PARSER_POPULATES_LKP_1        
        ig_md.lkp_1.l4_src_port = hdr.outer.tcp.src_port;
        ig_md.lkp_1.l4_dst_port = hdr.outer.tcp.dst_port;
        ig_md.lkp_1.tcp_flags   = hdr.outer.tcp.flags;
#endif // INGRESS_PARSER_POPULATES_LKP_1
        transition select(hdr.outer.tcp.data_offset) {
            5: accept;
            default: parse_outer_tcp_unsupported;
        }
    }
    
    state parse_outer_tcp_udf {
        pkt.extract(hdr.outer.tcp);
#ifdef INGRESS_PARSER_POPULATES_LKP_1        
        ig_md.lkp_1.l4_src_port = hdr.outer.tcp.src_port;
        ig_md.lkp_1.l4_dst_port = hdr.outer.tcp.dst_port;
        ig_md.lkp_1.tcp_flags   = hdr.outer.tcp.flags;
#endif // INGRESS_PARSER_POPULATES_LKP_1
        transition select(hdr.outer.tcp.data_offset) {
            5: parse_udf;
            default: parse_outer_tcp_unsupported;
        }
    }

    state parse_outer_tcp_unsupported {
        ig_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_UNSUPPORTED;
        ig_md.lkp_1.tunnel_id = 0;
        transition reject;
    }
    
    
    //--------------------------------------------------------------------------
    // Stream Control Transmission Protocol (SCTP) - Outer
    //--------------------------------------------------------------------------

    state parse_outer_sctp_noudf {
        pkt.extract(hdr.outer.sctp);
#ifdef INGRESS_PARSER_POPULATES_LKP_1        
        ig_md.lkp_1.l4_src_port = hdr.outer.sctp.src_port;
        ig_md.lkp_1.l4_dst_port = hdr.outer.sctp.dst_port;
#endif // INGRESS_PARSER_POPULATES_LKP_1
        transition accept;
    }

    state parse_outer_sctp_udf {
        pkt.extract(hdr.outer.sctp);
#ifdef INGRESS_PARSER_POPULATES_LKP_1        
        ig_md.lkp_1.l4_src_port = hdr.outer.sctp.src_port;
        ig_md.lkp_1.l4_dst_port = hdr.outer.sctp.dst_port;
#endif // INGRESS_PARSER_POPULATES_LKP_1
        transition parse_udf;
    }

    
    ////////////////////////////////////////////////////////////////////////////
    // Layer X - Outer
    ////////////////////////////////////////////////////////////////////////////

    //--------------------------------------------------------------------------
    // Multi-Protocol Label Switching (MPLS) - Outer
    //--------------------------------------------------------------------------
    // Due to chip resource constraints, we're only supporting certain MPLS
    // modes via heuristic parsing (aka: "first nibble hack").
    //
    // The following three MPLS modes are supported:
    //   EoMPLS       (via OUTER_EoMPLS_ENABLE parameter)
    //   EoMPLS-PWCW  (via OUTER_EoMPLS_PWCW_ENABLE parameter)
    //   IPoMPLS      (via OUTER_IPoMPLS_ENABLE parameter)
    //
    // EoMPLS assumes ethernet follows bos (no pw_cw).
    // EoMPLS-PWCW assumes pw_cw follows bos.
    // IPoMPLS assumes v4 or v6 header follows bos.
    //
    // Valid parameter combinations are as follows:
    //
    //  EoMPLS_ENABLE  EoMPLS_PWCW_ENABLE  IPoMPLS_ENABLE
    //  -----------------------------------------------------
    //  false          false               false
    //  true           false               false
    //  false          false               true
    //  false          true                false
    //  false          true                true
    //
    // For all MPLS enabled combinations above, the user can add MPLS-over-GRE
    // support via parameter OUTER_MPLSoGRE_ENABLE

    state construct_outer_mplsogre {
        transition select(OUTER_MPLSoGRE_ENABLE) {
            true: construct_outer_mpls;
            default: reject;
        }
    }        
    state construct_outer_mpls {
        transition select(OUTER_EoMPLS_ENABLE, OUTER_EoMPLS_PWCW_ENABLE, OUTER_IPoMPLS_ENABLE) {
            //(true,      _,     _): parse_outer_eompls;
            //(false,  true, false): parse_outer_eompls_pwcw;
            //(false, false,  true): parse_outer_ipompls;
            //(false,  true,  true): parse_outer_eompls_pwcw_ipompls;
            (true,      _,     _): parse_outer_eompls_0;
            (false,  true, false): parse_outer_eompls_pwcw_0;
            (false, false,  true): parse_outer_ipompls_0;
            (false,  true,  true): parse_outer_eompls_pwcw_ipompls_0;
            default: reject;
        }
    }

    //--------------------------------------------------------------------------
    // state parse_outer_eompls {
    // 
    //     ig_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_MPLS;
    //     ig_md.lkp_1.tunnel_id = pkt.lookahead<bit<32>>();    
    // 
    //     pkt.extract(hdr.outer.mpls.next);
    //     transition select(hdr.outer.mpls.last.bos) {
    //         0: parse_outer_eompls;
    //         1: parse_inner_ethernet;
    //     }
    // }

    state parse_outer_eompls_0 {
        ig_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_MPLS;
        ig_md.lkp_1.tunnel_id = pkt.lookahead<bit<32>>();    
        pkt.extract(hdr.outer.mpls_0);
        transition select(hdr.outer.mpls_0.bos) {
            0: parse_outer_eompls_1;
            1: parse_inner_ethernet;
        }
    }
    state parse_outer_eompls_1 {
        ig_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_MPLS;
        ig_md.lkp_1.tunnel_id = pkt.lookahead<bit<32>>();    
        pkt.extract(hdr.outer.mpls_1);
        transition select(hdr.outer.mpls_1.bos) {
            0: construct_outer_eompls_2;
            1: parse_inner_ethernet;
        }
    }
    state construct_outer_eompls_2 {
        transition select(MPLS_DEPTH_OUTER) {
            1: parse_outer_mpls_unsupported; // unsupported param value
            2: parse_outer_mpls_unsupported;
            default: parse_outer_eompls_2;
        }
    }
    state parse_outer_eompls_2 {
        ig_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_MPLS;
        ig_md.lkp_1.tunnel_id = pkt.lookahead<bit<32>>();    
        pkt.extract(hdr.outer.mpls_2);
        transition select(hdr.outer.mpls_2.bos) {
            0: parse_outer_eompls_3;
            1: parse_inner_ethernet;
        }
    }
    state parse_outer_eompls_3 {
        ig_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_MPLS;
        ig_md.lkp_1.tunnel_id = pkt.lookahead<bit<32>>();    
        pkt.extract(hdr.outer.mpls_3);
        transition select(hdr.outer.mpls_3.bos) {
            // 0: construct_outer_eompls_4;
            0: parse_outer_mpls_unsupported;
            1: parse_inner_ethernet;
        }
    }
    // state construct_outer_eompls_4 {
    //     transition select(MPLS_DEPTH_OUTER) {
    //         3: parse_outer_mpls_unsupported; // unsupported param value
    //         4: parse_outer_mpls_unsupported;
    //         default: parse_outer_eompls_4;
    //     }
    // }
    // state parse_outer_eompls_4 {
    //     ig_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_MPLS;
    //     ig_md.lkp_1.tunnel_id = pkt.lookahead<bit<32>>();    
    //     pkt.extract(hdr.outer.mpls_4);
    //     transition select(hdr.outer.mpls_4.bos) {
    //         0: parse_outer_eompls_5;
    //         1: parse_inner_ethernet;
    //     }
    // }
    // state parse_outer_eompls_5 {
    //     ig_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_MPLS;
    //     ig_md.lkp_1.tunnel_id = pkt.lookahead<bit<32>>();    
    //     pkt.extract(hdr.outer.mpls_5);
    //     transition select(hdr.outer.mpls_5.bos) {
    //         0: parse_outer_mpls_unsupported;
    //         1: parse_inner_ethernet;
    //     }
    // }

    
    //--------------------------------------------------------------------------
    // state parse_outer_eompls_pwcw {
    // 
    //     ig_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_MPLS;
    //     ig_md.lkp_1.tunnel_id = pkt.lookahead<bit<32>>();    
    // 
    //  pkt.extract(hdr.outer.mpls.next);
    //     transition select(hdr.outer.mpls.last.bos, pkt.lookahead<bit<4>>()) {
    //         (0, _): parse_outer_eompls_pwcw;
    //         (1, 0): parse_outer_eompls_pwcw_extract_pwcw;
    //         //default: parse_inner_ethernet;
    //         default: accept; // todo: unexpected - flag this as error?
    //     }
    // }

    state parse_outer_eompls_pwcw_0 {
        ig_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_MPLS;
        ig_md.lkp_1.tunnel_id = pkt.lookahead<bit<32>>();    
        pkt.extract(hdr.outer.mpls_0);
        transition select(hdr.outer.mpls_0.bos, pkt.lookahead<bit<4>>()) {
            (0, _): parse_outer_eompls_pwcw_1;
            (1, 0): parse_outer_eompls_pwcw_extract_pwcw;
            default: reject; // todo: unexpected - flag this as error?
        }
    }
    state parse_outer_eompls_pwcw_1 {
        ig_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_MPLS;
        ig_md.lkp_1.tunnel_id = pkt.lookahead<bit<32>>();    
        pkt.extract(hdr.outer.mpls_1);
        transition select(hdr.outer.mpls_1.bos, pkt.lookahead<bit<4>>()) {
            (0, _): construct_outer_eompls_pwcw_2;
            (1, 0): parse_outer_eompls_pwcw_extract_pwcw;
            default: reject; // todo: unexpected - flag this as error?
        }
    }
    state construct_outer_eompls_pwcw_2 {
        transition select(MPLS_DEPTH_OUTER) {
            1: parse_outer_mpls_unsupported; // unsupported param value
            2: parse_outer_mpls_unsupported;
            default: parse_outer_eompls_pwcw_2;
        }
    }    
    state parse_outer_eompls_pwcw_2 {
        ig_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_MPLS;
        ig_md.lkp_1.tunnel_id = pkt.lookahead<bit<32>>();    
        pkt.extract(hdr.outer.mpls_2);
        transition select(hdr.outer.mpls_2.bos, pkt.lookahead<bit<4>>()) {
            (0, _): parse_outer_eompls_pwcw_3;
            (1, 0): parse_outer_eompls_pwcw_extract_pwcw;
            default: reject; // todo: unexpected - flag this as error?
        }
    }
    state parse_outer_eompls_pwcw_3 {
        ig_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_MPLS;
        ig_md.lkp_1.tunnel_id = pkt.lookahead<bit<32>>();    
        pkt.extract(hdr.outer.mpls_3);
        transition select(hdr.outer.mpls_3.bos, pkt.lookahead<bit<4>>()) {
            // (0, _): construct_outer_eompls_pwcw_4;
            (0, _): parse_outer_mpls_unsupported;
            (1, 0): parse_outer_eompls_pwcw_extract_pwcw;
            default: reject; // todo: unexpected - flag this as error?
        }
    }
    // state construct_outer_eompls_pwcw_4 {
    //     transition select(MPLS_DEPTH_OUTER) {
    //         3: parse_outer_mpls_unsupported; // unsupported param value
    //         4: parse_outer_mpls_unsupported;
    //         default: parse_outer_eompls_pwcw_4;
    //     }
    // }
    // state parse_outer_eompls_pwcw_4 {
    //     ig_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_MPLS;
    //     ig_md.lkp_1.tunnel_id = pkt.lookahead<bit<32>>();    
    //  pkt.extract(hdr.outer.mpls_4);
    //     transition select(hdr.outer.mpls_4.bos, pkt.lookahead<bit<4>>()) {
    //         (0, _): parse_outer_eompls_pwcw_5;
    //         (1, 0): parse_outer_eompls_pwcw_extract_pwcw;
    //         default: reject; // todo: unexpected - flag this as error?
    //     }
    // }
    // state parse_outer_eompls_pwcw_5 {
    //     ig_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_MPLS;
    //     ig_md.lkp_1.tunnel_id = pkt.lookahead<bit<32>>();    
    //  pkt.extract(hdr.outer.mpls_5);
    //     transition select(hdr.outer.mpls_5.bos, pkt.lookahead<bit<4>>()) {
    //         (0, _): parse_outer_mpls_unsupported;
    //         (1, 0): parse_outer_eompls_pwcw_extract_pwcw;
    //         default: reject; // todo: unexpected - flag this as error?
    //     }
    // }
    state parse_outer_eompls_pwcw_extract_pwcw {
        pkt.extract(hdr.outer.mpls_pw_cw); 
        transition parse_inner_ethernet;
    }


    //--------------------------------------------------------------------------
    // state parse_outer_ipompls {
    // 
    //     ig_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_MPLS;
    //     ig_md.lkp_1.tunnel_id = pkt.lookahead<bit<32>>();    
    // 
    //  pkt.extract(hdr.outer.mpls.next);
    //     transition select(hdr.outer.mpls.last.bos, pkt.lookahead<bit<4>>()) {
    //         (0, _): parse_outer_ipompls;
    //         (1, 4): qualify_inner_ipv4;
    //         (1, 6): construct_inner_ipv6;
    //         default: accept; // todo: unexpected - flag this as error?
    //     }
    // }

    state parse_outer_ipompls_0 {
        ig_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_MPLS;
        ig_md.lkp_1.tunnel_id = pkt.lookahead<bit<32>>();    
        pkt.extract(hdr.outer.mpls_0);
        transition select(hdr.outer.mpls_0.bos, pkt.lookahead<bit<4>>()) {
            (0, _): parse_outer_ipompls_1;
            (1, 4): qualify_inner_ipv4;
            (1, 6): construct_inner_ipv6;
            default: reject; // todo: unexpected - flag this as error?
        }
    }
    state parse_outer_ipompls_1 {
        ig_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_MPLS;
        ig_md.lkp_1.tunnel_id = pkt.lookahead<bit<32>>();    
        pkt.extract(hdr.outer.mpls_1);
        transition select(hdr.outer.mpls_1.bos, pkt.lookahead<bit<4>>()) {
            (0, _): construct_outer_ipompls_2;
            (1, 4): qualify_inner_ipv4;
            (1, 6): construct_inner_ipv6;
            default: reject; // todo: unexpected - flag this as error?
        }
    }
    state construct_outer_ipompls_2 {
        transition select(MPLS_DEPTH_OUTER) {
            1: parse_outer_mpls_unsupported; // unsupported param value
            2: parse_outer_mpls_unsupported;
            default: parse_outer_ipompls_2;
        }
    }
    state parse_outer_ipompls_2 {
        ig_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_MPLS;
        ig_md.lkp_1.tunnel_id = pkt.lookahead<bit<32>>();    
        pkt.extract(hdr.outer.mpls_2);
        transition select(hdr.outer.mpls_2.bos, pkt.lookahead<bit<4>>()) {
            (0, _): parse_outer_ipompls_3;
            (1, 4): qualify_inner_ipv4;
            (1, 6): construct_inner_ipv6;
            default: reject; // todo: unexpected - flag this as error?
        }
    }
    state parse_outer_ipompls_3 {
        ig_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_MPLS;
        ig_md.lkp_1.tunnel_id = pkt.lookahead<bit<32>>();    
        pkt.extract(hdr.outer.mpls_3);
        transition select(hdr.outer.mpls_3.bos, pkt.lookahead<bit<4>>()) {
            // (0, _): construct_outer_ipompls_4;
            (0, _): parse_outer_mpls_unsupported;
            (1, 4): qualify_inner_ipv4;
            (1, 6): construct_inner_ipv6;
            default: reject; // todo: unexpected - flag this as error?
        }
    }
    // state construct_outer_ipompls_4 {
    //     transition select(MPLS_DEPTH_OUTER) {
    //         3: parse_outer_mpls_unsupported; // unsupported param value
    //         4: parse_outer_mpls_unsupported;
    //         default: parse_outer_ipompls_4;
    //     }
    // }
    // state parse_outer_ipompls_4 {
    //     ig_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_MPLS;
    //     ig_md.lkp_1.tunnel_id = pkt.lookahead<bit<32>>();    
    //  pkt.extract(hdr.outer.mpls_4);
    //     transition select(hdr.outer.mpls_4.bos, pkt.lookahead<bit<4>>()) {
    //         (0, _): parse_outer_ipompls_5;
    //         (1, 4): qualify_inner_ipv4;
    //         (1, 6): construct_inner_ipv6;
    //         default: reject; // todo: unexpected - flag this as error?
    //     }
    // }
    // state parse_outer_ipompls_5 {
    //     ig_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_MPLS;
    //     ig_md.lkp_1.tunnel_id = pkt.lookahead<bit<32>>();    
    //  pkt.extract(hdr.outer.mpls_5);
    //     transition select(hdr.outer.mpls_5.bos, pkt.lookahead<bit<4>>()) {
    //         (0, _): parse_outer_mpls_unsupported;
    //         (1, 4): qualify_inner_ipv4;
    //         (1, 6): construct_inner_ipv6;
    //         default: reject; // todo: unexpected - flag this as error?
    //     }
    // }

    
    //--------------------------------------------------------------------------
    // state parse_outer_eompls_pwcw_ipompls {
    // 
    //     ig_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_MPLS;
    //     ig_md.lkp_1.tunnel_id = pkt.lookahead<bit<32>>();    
    // 
    //  pkt.extract(hdr.outer.mpls.next);
    //     transition select(hdr.outer.mpls.last.bos, pkt.lookahead<bit<4>>()) {
    //         (0, _): parse_outer_eompls_pwcw_ipompls;
    //         (1, 4): qualify_inner_ipv4;
    //         (1, 6): construct_inner_ipv6;
    //         (1, 0): parse_outer_eompls_pwcw_ipompls_extract_pwcw;
    //         //default: parse_inner_ethernet;
    //         default: accept; // todo: unexpected - flag this as error?
    //     }
    // }
    
    state parse_outer_eompls_pwcw_ipompls_0 {
        ig_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_MPLS;
        ig_md.lkp_1.tunnel_id = pkt.lookahead<bit<32>>();    
        pkt.extract(hdr.outer.mpls_0);
        transition select(hdr.outer.mpls_0.bos, pkt.lookahead<bit<4>>()) {
            (0, _): parse_outer_eompls_pwcw_ipompls_1;
            (1, 4): qualify_inner_ipv4;
            (1, 6): construct_inner_ipv6;
            (1, 0): parse_outer_eompls_pwcw_ipompls_extract_pwcw;
            default: reject; // todo: unexpected - flag this as error?
        }
    }
    state parse_outer_eompls_pwcw_ipompls_1 {
        ig_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_MPLS;
        ig_md.lkp_1.tunnel_id = pkt.lookahead<bit<32>>();    
        pkt.extract(hdr.outer.mpls_1);
        transition select(hdr.outer.mpls_1.bos, pkt.lookahead<bit<4>>()) {
            (0, _): construct_outer_eompls_pwcw_ipompls_2;
            (1, 4): qualify_inner_ipv4;
            (1, 6): construct_inner_ipv6;
            (1, 0): parse_outer_eompls_pwcw_ipompls_extract_pwcw;
            default: reject; // todo: unexpected - flag this as error?
        }
    }
    state construct_outer_eompls_pwcw_ipompls_2 {
        transition select(MPLS_DEPTH_OUTER) {
            1: parse_outer_mpls_unsupported; // unsupported param value
            2: parse_outer_mpls_unsupported;
            default: parse_outer_eompls_pwcw_ipompls_2;
        }
    }
    state parse_outer_eompls_pwcw_ipompls_2 {
        ig_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_MPLS;
        ig_md.lkp_1.tunnel_id = pkt.lookahead<bit<32>>();    
        pkt.extract(hdr.outer.mpls_2);
        transition select(hdr.outer.mpls_2.bos, pkt.lookahead<bit<4>>()) {
            (0, _): parse_outer_eompls_pwcw_ipompls_3;
            (1, 4): qualify_inner_ipv4;
            (1, 6): construct_inner_ipv6;
            (1, 0): parse_outer_eompls_pwcw_ipompls_extract_pwcw;
            default: reject; // todo: unexpected - flag this as error?
        }
    }
    state parse_outer_eompls_pwcw_ipompls_3 {
        ig_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_MPLS;
        ig_md.lkp_1.tunnel_id = pkt.lookahead<bit<32>>();    
        pkt.extract(hdr.outer.mpls_3);
        transition select(hdr.outer.mpls_3.bos, pkt.lookahead<bit<4>>()) {
            // (0, _): construct_outer_eompls_pwcw_ipompls_4;
            (0, _): parse_outer_mpls_unsupported;
            (1, 4): qualify_inner_ipv4;
            (1, 6): construct_inner_ipv6;
            (1, 0): parse_outer_eompls_pwcw_ipompls_extract_pwcw;
            default: reject; // todo: unexpected - flag this as error?
        }
    }
    // state construct_outer_eompls_pwcw_ipompls_4 {
    //     transition select(MPLS_DEPTH_OUTER) {
    //         3: parse_outer_mpls_unsupported; // unsupported param value
    //         4: parse_outer_mpls_unsupported;
    //         default: parse_outer_eompls_pwcw_ipompls_4;
    //     }
    // }
    // state parse_outer_eompls_pwcw_ipompls_4 {
    //     ig_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_MPLS;
    //     ig_md.lkp_1.tunnel_id = pkt.lookahead<bit<32>>();    
    //  pkt.extract(hdr.outer.mpls_4);
    //     transition select(hdr.outer.mpls_4.bos, pkt.lookahead<bit<4>>()) {
    //         (0, _): parse_outer_eompls_pwcw_ipompls_5;
    //         (1, 4): qualify_inner_ipv4;
    //         (1, 6): construct_inner_ipv6;
    //         (1, 0): parse_outer_eompls_pwcw_ipompls_extract_pwcw;
    //         default: reject; // todo: unexpected - flag this as error?
    //     }
    // }
    // state parse_outer_eompls_pwcw_ipompls_5 {
    //     ig_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_MPLS;
    //     ig_md.lkp_1.tunnel_id = pkt.lookahead<bit<32>>();    
    //  pkt.extract(hdr.outer.mpls_5);
    //     transition select(hdr.outer.mpls_5.bos, pkt.lookahead<bit<4>>()) {
    //         (0, _): parse_outer_mpls_unsupported;
    //         (1, 4): qualify_inner_ipv4;
    //         (1, 6): construct_inner_ipv6;
    //         (1, 0): parse_outer_eompls_pwcw_ipompls_extract_pwcw;
    //         default: reject; // todo: unexpected - flag this as error?
    //     }
    // }
    state parse_outer_eompls_pwcw_ipompls_extract_pwcw {
        pkt.extract(hdr.outer.mpls_pw_cw); 
        transition  parse_inner_ethernet;
    }

    state parse_outer_mpls_unsupported {
        ig_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_UNSUPPORTED;
        ig_md.lkp_1.tunnel_id = 0;
        transition reject;
    }
    
    ////////////////////////////////////////////////////////////////////////////
    // Tunnels - Outer
    ////////////////////////////////////////////////////////////////////////////

    //--------------------------------------------------------------------------
    // Generic Network Virtualization Encapsulation (GENEVE) - Outer
    //--------------------------------------------------------------------------

    state construct_outer_geneve {
        transition select(OUTER_GENEVE_ENABLE) {
            true: qualify_outer_geneve;
            false: reject;
        }
    }

    state qualify_outer_geneve {
        geneve_h snoop_geneve = pkt.lookahead<geneve_h>();
        ig_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_UNSUPPORTED;
        
        transition select(
            snoop_geneve.ver,
            snoop_geneve.opt_len,
            snoop_geneve.O,
            snoop_geneve.C,
            snoop_geneve.proto_type) {

          //     O C 
            (0,0,0,0,ETHERTYPE_ENET): parse_outer_geneve_qualified;
            (0,0,0,0,ETHERTYPE_IPV4): parse_outer_geneve_qualified;
            (0,0,0,0,ETHERTYPE_IPV6): parse_outer_geneve_qualified;
            default: accept;
        }
    }

    state parse_outer_geneve_qualified {    
        pkt.extract(hdr.outer.geneve);
        ig_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_GENEVE;
        ig_md.lkp_1.tunnel_id = (bit<switch_tunnel_id_width>)hdr.outer.geneve.vni;

        transition select(hdr.outer.geneve.proto_type) {
            ETHERTYPE_ENET: parse_inner_ethernet;
            ETHERTYPE_IPV4: qualify_inner_ipv4;
            ETHERTYPE_IPV6: construct_inner_ipv6;
            default: accept;
        }
    }


    //--------------------------------------------------------------------------
    // Virtual Extensible Local Area Network (VXLAN) - Outer
    //--------------------------------------------------------------------------

    state construct_outer_vxlan {
        transition select(OUTER_VXLAN_ENABLE) {
            true: parse_outer_vxlan;
            false: reject;
        }
    }

    state parse_outer_vxlan {
        pkt.extract(hdr.outer.vxlan);
        ig_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_VXLAN;
        ig_md.lkp_1.tunnel_id = (bit<switch_tunnel_id_width>)hdr.outer.vxlan.vni;
        transition parse_inner_ethernet; 
    }


    //--------------------------------------------------------------------------
    // Internet Protocol (IP) - Outer
    //--------------------------------------------------------------------------

    state construct_outer_ipinip_set_tunnel {
        transition select(OUTER_IPINIP_ENABLE) {    
            true: parse_outer_ipinip_set_tunnel;
            default: reject;
        }
    }
    state parse_outer_ipinip_set_tunnel {
        ig_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_IPINIP;
        ig_md.lkp_1.tunnel_id = 0;
        transition qualify_inner_ipv4;
    }

    state construct_outer_ipv6inip_set_tunnel {
        transition select(OUTER_IPINIP_ENABLE) {    
            true: parse_outer_ipv6inip_set_tunnel;
            default: reject;
        }
    }   
    state parse_outer_ipv6inip_set_tunnel {
        ig_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_IPINIP;
        ig_md.lkp_1.tunnel_id = 0;
        transition construct_inner_ipv6;
    }


    //--------------------------------------------------------------------------
    // Generic Routing Encapsulation (GRE) - Outer
    //--------------------------------------------------------------------------

    state construct_outer_gre {
        transition select(OUTER_GRE_ENABLE) {    
            true: parse_outer_gre;
            default: reject;
        }
    }

    state parse_outer_gre {
        gre_h snoop_gre = pkt.lookahead<gre_h>();
        ig_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_UNSUPPORTED;

        transition select(
            snoop_gre.C,
            snoop_gre.R,
            snoop_gre.K,
            snoop_gre.S,
            snoop_gre.s,
            snoop_gre.recurse,
            snoop_gre.flags,
            snoop_gre.version) {

          // C R K S s r f v
            (0,0,0,0,0,0,0,0): parse_outer_gre_qualified;
            (1,0,0,0,0,0,0,0): parse_outer_gre_qualified;
            (0,0,1,0,0,0,0,0): parse_outer_gre_qualified;
            (0,0,0,1,0,0,0,0): parse_outer_gre_qualified;
            default: accept;
        }
    }

    state parse_outer_gre_qualified {    
        pkt.extract(hdr.outer.gre);
        ig_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_GRE;
        ig_md.lkp_1.tunnel_id = 0;

        transition select(
            hdr.outer.gre.C,
            hdr.outer.gre.K,
            hdr.outer.gre.S,
            hdr.outer.gre.proto) {

          // C K S
            (0,1,0,GRE_PROTOCOLS_NVGRE): construct_outer_nvgre;
            (0,0,0,ETHERTYPE_IPV4): qualify_inner_ipv4;
            (0,0,0,ETHERTYPE_IPV6): construct_inner_ipv6;
            (0,0,0,ETHERTYPE_MPLS): construct_outer_mplsogre;
            (1,0,0,_): parse_outer_gre_optional;
            (0,1,0,_): parse_outer_gre_optional;
            (0,0,1,_): parse_outer_gre_optional;
            default: accept;
        }
    }

    state parse_outer_gre_optional {    
        pkt.extract(hdr.outer.gre_optional);
        transition select(hdr.outer.gre.proto) {
            ETHERTYPE_IPV4: qualify_inner_ipv4;
            ETHERTYPE_IPV6: construct_inner_ipv6;
            ETHERTYPE_MPLS: construct_outer_mplsogre;
            default: accept;
        }
    }
    
    
    //--------------------------------------------------------------------------
    // Network Virtualization using GRE (NVGRE) - (aka: L2 GRE) - Outer
    //--------------------------------------------------------------------------

    state construct_outer_nvgre {
        transition select(OUTER_NVGRE_ENABLE) {
            true: parse_outer_nvgre;
            false: reject;
        }
    }

    state parse_outer_nvgre {
        pkt.extract(hdr.outer.nvgre);
        ig_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_NVGRE;
        ig_md.lkp_1.tunnel_id = (bit<switch_tunnel_id_width>)hdr.outer.nvgre.vsid;
        ig_md.tunnel_1.nvgre_flow_id = hdr.outer.nvgre.flow_id; // from switch
        transition parse_inner_ethernet;
    }


    //--------------------------------------------------------------------------
    // Encapsulating Security Payload (ESP) - Outer
    //--------------------------------------------------------------------------

//     state parse_outer_esp_overload {
// #if defined(PARSER_L4_PORT_OVERLOAD) && defined(INGRESS_PARSER_POPULATES_LKP_1)
//         ig_md.lkp_1.l4_src_port = pkt.lookahead<esp_h>().spi_hi;
//         ig_md.lkp_1.l4_dst_port = pkt.lookahead<esp_h>().spi_lo;
// #endif
//         transition accept;
//     }


    //--------------------------------------------------------------------------
    // GPRS (General Packet Radio Service) Tunneling Protocol (GTP) - Outer
    //--------------------------------------------------------------------------
    // Based on pseudo code from Glenn (see email from 03/11/2019):

    // GTP-C
    //--------------------------------------------------------------------------
    // Simply set tunnel type and ID for policy via lookahead (no extraction).

    state construct_outer_gtp_c {
        transition select(OUTER_GTP_ENABLE, UDF_ENABLE) {    
            (true, _): parse_outer_gtp_c;
            (false, true): parse_udf;
            default: reject;
        }
    }
    
    state parse_outer_gtp_c {
        ig_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_UNSUPPORTED;
            
        transition select(
            pkt.lookahead<gtp_v2_base_h>().version,
            pkt.lookahead<gtp_v2_base_h>().T
        ) {
            (2, 1): parse_outer_gtp_c_qualified;
            default: accept;
        }
    }

    state parse_outer_gtp_c_qualified {
        ig_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_GTPC;
        ig_md.lkp_1.tunnel_id = pkt.lookahead<gtp_v2_base_h>().teid;
        transition accept;
    }

    // GTP-U
    //--------------------------------------------------------------------------
    // Only supports optional header for sequence-number
    // Does not support parsing (TLV) extension headers

    state construct_outer_gtp_u {
        transition select(OUTER_GTP_ENABLE, UDF_ENABLE) {    
            (true, _): parse_outer_gtp_u;
            (false, true): parse_udf;
            default: reject;
        }
    }
    
    state parse_outer_gtp_u {
        gtp_v1_base_h snoop_gtp_v1_base = pkt.lookahead<gtp_v1_base_h>();
        ig_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_UNSUPPORTED;
            
        transition select(
            snoop_gtp_v1_base.version,
            snoop_gtp_v1_base.PT,
            snoop_gtp_v1_base.E,
            snoop_gtp_v1_base.S,
            snoop_gtp_v1_base.PN) {

            (1, 1, 0, 0, 0): parse_outer_gtp_u_qualified;
            (1, 1, 0, 1, 0): parse_outer_gtp_u_with_optional;
            default: accept;
        }
    }

    state parse_outer_gtp_u_qualified {
        pkt.extract(hdr.outer.gtp_v1_base);
        ig_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_GTPU;
        ig_md.lkp_1.tunnel_id = hdr.outer.gtp_v1_base.teid;
        
        transition select(pkt.lookahead<bit<4>>()) {
            4: qualify_inner_ipv4;
            6: construct_inner_ipv6;
            default: accept;
        }
    }

    state parse_outer_gtp_u_with_optional {
        pkt.extract(hdr.outer.gtp_v1_base);
        pkt.extract(hdr.outer.gtp_v1_optional);
        ig_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_GTPU;
        ig_md.lkp_1.tunnel_id = hdr.outer.gtp_v1_base.teid;

        transition select(
            hdr.outer.gtp_v1_base.E,
            pkt.lookahead<bit<4>>()) {
            (0, 4): qualify_inner_ipv4;
            (0, 6): construct_inner_ipv6;
            default: accept;
        }
    }    
    

    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////
    // "Inner" Headers / Stack
    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////

    ////////////////////////////////////////////////////////////////////////////
    // Layer 2 (ETH-T) - Inner
    ////////////////////////////////////////////////////////////////////////////

    state parse_inner_ethernet {
        pkt.extract(hdr.inner.ethernet);
#ifdef INGRESS_PARSER_POPULATES_LKP_2
        ig_md.lkp_2.l2_valid     = true;
        ig_md.lkp_2.mac_src_addr = hdr.inner.ethernet.src_addr;
        ig_md.lkp_2.mac_dst_addr = hdr.inner.ethernet.dst_addr;
        ig_md.lkp_2.mac_type     = hdr.inner.ethernet.ether_type;
        ig_md.lkp_2.pcp = 0;
        ig_md.lkp_2.vid = 0;
#endif // INGRESS_PARSER_POPULATES_LKP_2
        transition select(hdr.inner.ethernet.ether_type) {
            //ETHERTYPE_ARP:  parse_inner_arp;
            ETHERTYPE_VLAN: parse_inner_vlan_0;
            ETHERTYPE_IPV4: qualify_inner_ipv4;
            ETHERTYPE_IPV6: construct_inner_ipv6;
            default : accept;
        }
    }

    state parse_inner_vlan_0 {
        pkt.extract(hdr.inner.vlan_tag[0]);
//#ifdef INGRESS_PARSER_POPULATES_LKP_2
  #ifndef SF_0_L2_VLAN_ID_ENABLE
        ig_md.lkp_2.tunnel_type = SWITCH_TUNNEL_TYPE_VLAN;
  #endif // SF_0_L2_VLAN_ID_ENABLE
//#endif // INGRESS_PARSER_POPULATES_LKP_2        
        
#ifdef INGRESS_PARSER_POPULATES_LKP_2
        ig_md.lkp_2.pcp = hdr.inner.vlan_tag[0].pcp;
  #ifdef SF_0_L2_VLAN_ID_ENABLE
        ig_md.lkp_2.vid = hdr.inner.vlan_tag[0].vid;
  #endif // SF_0_L2_VLAN_ID_ENABLE
        ig_md.lkp_2.mac_type = hdr.inner.vlan_tag[0].ether_type;
#endif // INGRESS_PARSER_POPULATES_LKP_2        
        transition select(hdr.inner.vlan_tag[0].ether_type) {
            ETHERTYPE_VLAN: parse_inner_vlan_unsupported;
            //ETHERTYPE_ARP: parse_inner_arp;
            ETHERTYPE_IPV4: qualify_inner_ipv4;
            ETHERTYPE_IPV6: construct_inner_ipv6;
            default : accept;
        }
    }
    state parse_inner_vlan_unsupported {
        ig_md.lkp_2.tunnel_type = SWITCH_TUNNEL_TYPE_UNSUPPORTED;
        ig_md.lkp_2.tunnel_id = 0;
        transition reject;
    }

    
    // /////////////////////////////////////////////////////////////////////////
    // // Layer 2.5 - Inner
    // /////////////////////////////////////////////////////////////////////////
    // 
    // state parse_inner_arp {
    //     // pkt.extract(hdr.inner.arp);
    //     // transition accept;
    //     transition accept;
    // }


    ////////////////////////////////////////////////////////////////////////////
    // Layer 3 - Inner
    ////////////////////////////////////////////////////////////////////////////

    // todo: currently we're extracting the ip-header, even if it contains
    //       unsupported ip-options (or frag). is this acceptable, or would it
    //       be better to extract the ip-header after being fully qualified?
    //
    // todo: same question applies to setting lookup metadata fields - would
    //       it be better to only set these if ip is fully qualified?
    //
    // todo: we're currently only setting UNSUPPORTED tunnel-type if we detect
    //       ipv4 options or frag. we're not attempting to detect IPv6 options
    //       currently as this would require more tcam resources to qualify
    //       more protocol field values. is this acceptable, or do we need to
    //       detect ipv6 options, and set UNSUPPORTED tunnel type?
    
    // -------------------------------------------------------------------------    
    state qualify_inner_ipv4 {
        pkt.extract(hdr.inner.ipv4);
        protocol_inner = hdr.inner.ipv4.protocol;
        
#ifdef INGRESS_PARSER_POPULATES_LKP_2
        // fixup ethertype for ip-n-ip case
        ig_md.lkp_2.mac_type      = ETHERTYPE_IPV4;
        //ig_md.lkp_2.ip_type       = SWITCH_IP_TYPE_IPV4;
        ig_md.lkp_2.ip_proto      = hdr.inner.ipv4.protocol;
        ig_md.lkp_2.ip_tos        = hdr.inner.ipv4.tos;
        ig_md.lkp_2.ip_flags      = hdr.inner.ipv4.flags;
        ig_md.lkp_2.ip_src_addr_v4= hdr.inner.ipv4.src_addr;
        ig_md.lkp_2.ip_dst_addr_v4= hdr.inner.ipv4.dst_addr;
        ig_md.lkp_2.ip_len        = hdr.inner.ipv4.total_len;
#endif // INGRESS_PARSER_POPULATES_LKP_2        
                
        // Flag packet (to be sent to host) if it's a frag or has options.
        //ipv4_checksum_inner.add(hdr.inner.ipv4);
        //ig_md.flags.ipv4_checksum_err_2 = ipv4_checksum_inner.verify();
        transition select(hdr.inner.ipv4.ihl, hdr.inner.ipv4.frag_offset) {
            (5, 0): construct_inner_ipv4_udf;
            default: parse_inner_ip_unsupported;
        }
    }

    state construct_inner_ipv4_udf {
        transition select(UDF_ENABLE) {
            true: parse_inner_ipv4_udf;
            false: branch_inner_ip;
        }
    }

    state parse_inner_ipv4_udf {
        transition select(hdr.inner.ipv4.protocol, hdr.inner.ipv4.total_len) {
            (IP_PROTOCOLS_UDP,  IP4_WIDTH_BYTES .. MIN_LEN_IP4_UDP_UDF ): parse_inner_udp_noudf;
            (IP_PROTOCOLS_UDP,  _                                      ): parse_inner_udp_udf;
            (IP_PROTOCOLS_TCP,  IP4_WIDTH_BYTES .. MIN_LEN_IP4_TCP_UDF ): parse_inner_tcp_noudf;
            (IP_PROTOCOLS_TCP,  _                                      ): parse_inner_tcp_udf;
            (IP_PROTOCOLS_SCTP, IP4_WIDTH_BYTES .. MIN_LEN_IP4_SCTP_UDF): parse_inner_sctp_noudf;
            (IP_PROTOCOLS_SCTP, _                                      ): parse_inner_sctp_udf;
            default: accept;
        }
    }

    // -------------------------------------------------------------------------    
    state construct_inner_ipv6 {
        transition select(INNER_IPV6_ENABLE) {
            true: parse_inner_ipv6;
            default: reject;
        }
    }

    state parse_inner_ipv6 {
        pkt.extract(hdr.inner.ipv6);
        protocol_inner = hdr.inner.ipv6.next_hdr;
        
#ifdef INGRESS_PARSER_POPULATES_LKP_2
        // fixup ethertype for ip-n-ip case
        ig_md.lkp_2.mac_type      = ETHERTYPE_IPV6;
        //ig_md.lkp_2.ip_type       = SWITCH_IP_TYPE_IPV6;
        ig_md.lkp_2.ip_proto      = hdr.inner.ipv6.next_hdr;
        //ig_md.lkp_2.ip_tos        = hdr.inner.ipv6.tos; // not byte-aligned so set in mau
        ig_md.lkp_2.ip_src_addr   = hdr.inner.ipv6.src_addr;
        ig_md.lkp_2.ip_dst_addr   = hdr.inner.ipv6.dst_addr;
        ig_md.lkp_2.ip_len        = hdr.inner.ipv6.payload_len;
#endif // INGRESS_PARSER_POPULATES_LKP_2
        transition construct_inner_ipv6_udf;
    }
    
    state construct_inner_ipv6_udf {
        transition select(UDF_ENABLE) {
            true: parse_inner_ipv6_udf;
            false: branch_inner_ip;
        }
    }

    state parse_inner_ipv6_udf {
        transition select(hdr.inner.ipv6.next_hdr, hdr.inner.ipv6.payload_len) {
            (IP_PROTOCOLS_UDP,  16w0 .. MIN_LEN_IP6_UDP_UDF ): parse_inner_udp_noudf;
            (IP_PROTOCOLS_UDP,  _                           ): parse_inner_udp_udf;
            (IP_PROTOCOLS_TCP,  16w0 .. MIN_LEN_IP6_TCP_UDF ): parse_inner_tcp_noudf;
            (IP_PROTOCOLS_TCP,  _                           ): parse_inner_tcp_udf;
            (IP_PROTOCOLS_SCTP, 16w0 .. MIN_LEN_IP6_SCTP_UDF): parse_inner_sctp_noudf;
            (IP_PROTOCOLS_SCTP, _                           ): parse_inner_sctp_udf;
            default: branch_inner_ip;                       
        }        
    }

    // shared fanout/branch state to save tcam resource
    state branch_inner_ip {
        transition select(protocol_inner) {
            IP_PROTOCOLS_IPV4: construct_inner_ipinip_set_tunnel;
            IP_PROTOCOLS_IPV6: construct_inner_ipv6inip_set_tunnel;
            IP_PROTOCOLS_GRE: construct_inner_gre;
            IP_PROTOCOLS_UDP: parse_inner_udp_noudf;
            IP_PROTOCOLS_TCP: parse_inner_tcp_noudf;
            IP_PROTOCOLS_SCTP: parse_inner_sctp_noudf;
            default: accept;
       }
    }

    state parse_inner_ip_unsupported {
        ig_md.lkp_2.tunnel_type = SWITCH_TUNNEL_TYPE_UNSUPPORTED;
        ig_md.lkp_2.tunnel_id = 0;
        transition reject;
    }

        
    ////////////////////////////////////////////////////////////////////////////
    // Inner Layer 4 - Inner
    ////////////////////////////////////////////////////////////////////////////

    //--------------------------------------------------------------------------
    // User Datagram Protocol (UDP) - Inner
    //--------------------------------------------------------------------------
                                
    state parse_inner_udp_noudf {
        pkt.extract(hdr.inner.udp);
#ifdef INGRESS_PARSER_POPULATES_LKP_2
        ig_md.lkp_2.l4_src_port = hdr.inner.udp.src_port;
        ig_md.lkp_2.l4_dst_port = hdr.inner.udp.dst_port;
#endif // INGRESS_PARSER_POPULATES_LKP_2        
        transition select(
            hdr.inner.udp.src_port,
            hdr.inner.udp.dst_port) {
                    
            (_, UDP_PORT_GTP_C): construct_inner_gtp_c;
            (UDP_PORT_GTP_C, _): construct_inner_gtp_c;
            (_, UDP_PORT_GTP_U): construct_inner_gtp_u;
            (UDP_PORT_GTP_U, _): construct_inner_gtp_u;
            default: accept;
        }
    }

    state parse_inner_udp_udf {
        pkt.extract(hdr.inner.udp);
#ifdef INGRESS_PARSER_POPULATES_LKP_2
        ig_md.lkp_2.l4_src_port = hdr.inner.udp.src_port;
        ig_md.lkp_2.l4_dst_port = hdr.inner.udp.dst_port;
#endif // INGRESS_PARSER_POPULATES_LKP_2        
        transition select(
            hdr.inner.udp.src_port,
            hdr.inner.udp.dst_port) {
                    
            (_, UDP_PORT_GTP_C): construct_inner_gtp_c;
            (UDP_PORT_GTP_C, _): construct_inner_gtp_c;
            (_, UDP_PORT_GTP_U): construct_inner_gtp_u;
            (UDP_PORT_GTP_U, _): construct_inner_gtp_u;
            default: parse_udf;
        }
    }
        
    //--------------------------------------------------------------------------
    // Transmission Control Protocol (TCP) - Inner
    //--------------------------------------------------------------------------

    // todo: do we need to flag tcp w/ options as UNSUPPORTED tunnel?

    state parse_inner_tcp_noudf {
        pkt.extract(hdr.inner.tcp);
#ifdef INGRESS_PARSER_POPULATES_LKP_2
        ig_md.lkp_2.l4_src_port = hdr.inner.tcp.src_port;
        ig_md.lkp_2.l4_dst_port = hdr.inner.tcp.dst_port;
        ig_md.lkp_2.tcp_flags   = hdr.inner.tcp.flags;        
#endif // INGRESS_PARSER_POPULATES_LKP_2
        transition select(hdr.inner.tcp.data_offset) {
            5: accept;
            default: parse_inner_tcp_unsupported;
        }
    }
        
    state parse_inner_tcp_udf {
        pkt.extract(hdr.inner.tcp);
#ifdef INGRESS_PARSER_POPULATES_LKP_2
        ig_md.lkp_2.l4_src_port = hdr.inner.tcp.src_port;
        ig_md.lkp_2.l4_dst_port = hdr.inner.tcp.dst_port;
        ig_md.lkp_2.tcp_flags   = hdr.inner.tcp.flags;        
#endif // INGRESS_PARSER_POPULATES_LKP_2
        transition select(hdr.inner.tcp.data_offset) {
            5: parse_udf;
            default: parse_inner_tcp_unsupported;
        }
    }

    state parse_inner_tcp_unsupported {
        ig_md.lkp_2.tunnel_type = SWITCH_TUNNEL_TYPE_UNSUPPORTED;
        ig_md.lkp_2.tunnel_id = 0;
        transition reject;
    }

    //--------------------------------------------------------------------------
    // Stream Control Transmission Protocol (SCTP) - Inner
    //--------------------------------------------------------------------------
  
    state parse_inner_sctp_noudf {
        pkt.extract(hdr.inner.sctp);
#ifdef INGRESS_PARSER_POPULATES_LKP_2
        ig_md.lkp_2.l4_src_port = hdr.inner.sctp.src_port;
        ig_md.lkp_2.l4_dst_port = hdr.inner.sctp.dst_port;
#endif // INGRESS_PARSER_POPULATES_LKP_2
        transition accept;
    }    

    state parse_inner_sctp_udf {
        pkt.extract(hdr.inner.sctp);
#ifdef INGRESS_PARSER_POPULATES_LKP_2
        ig_md.lkp_2.l4_src_port = hdr.inner.sctp.src_port;
        ig_md.lkp_2.l4_dst_port = hdr.inner.sctp.dst_port;
#endif // INGRESS_PARSER_POPULATES_LKP_2
        transition parse_udf;
    }    
        
                                

    ////////////////////////////////////////////////////////////////////////////
    // Tunnels - Inner
    ////////////////////////////////////////////////////////////////////////////

    //--------------------------------------------------------------------------
    // Internet Protocol (IP) - Inner
    //--------------------------------------------------------------------------

    state construct_inner_ipinip_set_tunnel {
        transition select(INNER_IPINIP_ENABLE) {    
            true: parse_inner_ipinip_set_tunnel;
            default: reject;
        }
    }
    state parse_inner_ipinip_set_tunnel {
        ig_md.lkp_2.tunnel_type = SWITCH_TUNNEL_TYPE_IPINIP;
        ig_md.lkp_2.tunnel_id = 0;
        transition parse_inner_inner_ipv4;
    }

    state construct_inner_ipv6inip_set_tunnel {
        transition select(INNER_IPINIP_ENABLE) {    
            true: parse_inner_ipv6inip_set_tunnel;
            default: reject;
        }
    }           
    state parse_inner_ipv6inip_set_tunnel {
        ig_md.lkp_2.tunnel_type = SWITCH_TUNNEL_TYPE_IPINIP;
        ig_md.lkp_2.tunnel_id = 0;
        transition construct_inner_inner_ipv6;
    }


    //--------------------------------------------------------------------------
    // Encapsulating Security Payload (ESP) - Inner
    //--------------------------------------------------------------------------
    
//     state parse_inner_esp_overload {
// #if defined(PARSER_L4_PORT_OVERLOAD) && defined(INGRESS_PARSER_POPULATES_LKP_2)
//         ig_md.lkp_2.l4_src_port = pkt.lookahead<esp_h>().spi_hi;
//         ig_md.lkp_2.l4_dst_port = pkt.lookahead<esp_h>().spi_lo;
// #endif
//         transition accept;
//     }    


    //--------------------------------------------------------------------------
    // Generic Routing Encapsulation (GRE) - Inner
    //--------------------------------------------------------------------------

    state construct_inner_gre {
        transition select(INNER_GRE_ENABLE) {    
            true: parse_inner_gre;
            default: reject;
        }
    }
    
    state parse_inner_gre {  
        gre_h snoop_gre = pkt.lookahead<gre_h>();
        ig_md.lkp_2.tunnel_type = SWITCH_TUNNEL_TYPE_UNSUPPORTED;

        transition select(
            snoop_gre.C,
            snoop_gre.R,
            snoop_gre.K,
            snoop_gre.S,
            snoop_gre.s,
            snoop_gre.recurse,
            snoop_gre.flags,
            snoop_gre.version) {

          // C R K S s r f v
            (0,0,0,0,0,0,0,0): parse_inner_gre_qualified;
            (1,0,0,0,0,0,0,0): parse_inner_gre_qualified;
            (0,0,1,0,0,0,0,0): parse_inner_gre_qualified;
            (0,0,0,1,0,0,0,0): parse_inner_gre_qualified;
            default: accept;
        }
    }

    state parse_inner_gre_qualified {    
        pkt.extract(hdr.inner.gre);
        ig_md.lkp_2.tunnel_type = SWITCH_TUNNEL_TYPE_GRE;
        ig_md.lkp_2.tunnel_id = 0;

        transition select(
            hdr.inner.gre.C,
            hdr.inner.gre.K,
            hdr.inner.gre.S,
            hdr.inner.gre.proto) {        

            (0,0,0,ETHERTYPE_IPV4): parse_inner_inner_ipv4;
            (0,0,0,ETHERTYPE_IPV6): construct_inner_inner_ipv6;                        
            (1,0,0,_): parse_inner_gre_optional;
            (0,1,0,_): parse_inner_gre_optional;
            (0,0,1,_): parse_inner_gre_optional;
            default: accept;
        }
    }
                
    state parse_inner_gre_optional {    
        pkt.extract(hdr.inner.gre_optional);
        transition select(hdr.inner.gre.proto) {
            ETHERTYPE_IPV4: parse_inner_inner_ipv4;
            ETHERTYPE_IPV6: construct_inner_inner_ipv6;                        
            default: accept;
        }
    }
   

    //--------------------------------------------------------------------------
    // GPRS (General Packet Radio Service) Tunneling Protocol (GTP) - Inner
    //--------------------------------------------------------------------------
    // Based on pseudo code from Glenn (see email from 03/11/2019):

    // GTP-C
    //--------------------------------------------------------------------------
    // Simply set tunnel type and ID for policy via lookahead (no extraction).

    state construct_inner_gtp_c {
        transition select(INNER_GTP_ENABLE, UDF_ENABLE) {    
            (true, _): parse_inner_gtp_c;
            (false, true): parse_udf;
            default: reject;
        }
    }
    
    state parse_inner_gtp_c {
        //gtp_v2_base_h snoop_inner_gtp_v2_base = pkt.lookahead<gtp_v2_base_h>();
        //transition select(
        //    snoop_inner_gtp_v2_base.version,
        //    snoop_inner_gtp_v2_base.T) {
        ig_md.lkp_2.tunnel_type = SWITCH_TUNNEL_TYPE_UNSUPPORTED;
        
        transition select(
            pkt.lookahead<gtp_v2_base_h>().version,
            pkt.lookahead<gtp_v2_base_h>().T
        ) {
            (2, 1): parse_inner_gtp_c_qualified;
            default: accept;
        }
    }

    state parse_inner_gtp_c_qualified {
        //pkt.extract(hdr.inner.gtp_v2_base);
        ig_md.lkp_2.tunnel_type = SWITCH_TUNNEL_TYPE_GTPC;
        ig_md.lkp_2.tunnel_id = pkt.lookahead<gtp_v2_base_h>().teid;
        transition accept;
    }

    // GTP-U
    //--------------------------------------------------------------------------
    // Only supports optional header for sequence-number
    // Does not support parsing (TLV) extension headers
        
    state construct_inner_gtp_u {
        transition select(INNER_GTP_ENABLE, UDF_ENABLE) {    
            (true, _): parse_inner_gtp_u;
            (false, true): parse_udf;
            default: reject;
        }
    }
        
    state parse_inner_gtp_u {
        gtp_v1_base_h snoop_inner_gtp_v1_base = pkt.lookahead<gtp_v1_base_h>();
        ig_md.lkp_2.tunnel_type = SWITCH_TUNNEL_TYPE_UNSUPPORTED;

        transition select(
            snoop_inner_gtp_v1_base.version,
            snoop_inner_gtp_v1_base.PT,
            snoop_inner_gtp_v1_base.E,
            snoop_inner_gtp_v1_base.S,
            snoop_inner_gtp_v1_base.PN) {

            (1, 1, 0, 0, 0): parse_inner_gtp_u_qualified;
            (1, 1, 0, 1, 0): parse_inner_gtp_u_with_optional;
            default: accept;
        }
    }

    state parse_inner_gtp_u_qualified {
        pkt.extract(hdr.inner.gtp_v1_base);
        ig_md.lkp_2.tunnel_type = SWITCH_TUNNEL_TYPE_GTPU;
        ig_md.lkp_2.tunnel_id = hdr.inner.gtp_v1_base.teid;

        transition select(pkt.lookahead<bit<4>>()) {
            4: parse_inner_inner_ipv4;
            6: construct_inner_inner_ipv6;
            default: accept;
        }
    }

    state parse_inner_gtp_u_with_optional {
        pkt.extract(hdr.inner.gtp_v1_base);
        pkt.extract(hdr.inner.gtp_v1_optional);
        ig_md.lkp_2.tunnel_type = SWITCH_TUNNEL_TYPE_GTPU;
        ig_md.lkp_2.tunnel_id = hdr.inner.gtp_v1_base.teid;

        transition select(
            hdr.inner.gtp_v1_base.E,
            pkt.lookahead<bit<4>>()) {
            (0, 4): parse_inner_inner_ipv4;
            (0, 6): construct_inner_inner_ipv6;
            default: accept;
        }
    }    
    
    
    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////
    // "Inner Inner" Headers / Stack
    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////

    state parse_inner_inner_ipv4 {
        hdr.inner_inner.ipv4.setValid();
        transition accept;
    }

    state construct_inner_inner_ipv6 {
        transition select(INNER_INNER_IPV6_ENABLE) {
            true: parse_inner_inner_ipv6;
            default: reject;
        }
    }
    state parse_inner_inner_ipv6 {
        hdr.inner_inner.ipv6.setValid();
        transition accept;
    }
    
    
    ////////////////////////////////////////////////////////////////////////////
    // UDF
    ////////////////////////////////////////////////////////////////////////////

    state parse_udf {
        pkt.extract(hdr.udf);
        transition accept;
    }
}

#endif /* _NPB_ING_PARSER_ */
