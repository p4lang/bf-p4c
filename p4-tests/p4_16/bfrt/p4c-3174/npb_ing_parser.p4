#ifndef _NPB_ING_PARSER_
#define _NPB_ING_PARSER_

parser NpbIngressParser(
        packet_in pkt,
        out switch_header_t hdr,
        out switch_ingress_metadata_t ig_md,
        out ingress_intrinsic_metadata_t ig_intr_md) {

    Checksum() ipv4_checksum_transport;
    Checksum() ipv4_checksum_outer;
    Checksum() ipv4_checksum_inner;

    value_set<switch_cpu_port_value_set_t>(4) cpu_port;

    //value_set<bit<32>>(20) my_mac_lo;
    //value_set<bit<16>>(20) my_mac_hi;
    value_set<bit<32>>(8) my_mac_lo;
    value_set<bit<16>>(8) my_mac_hi;
    
	//bit<8>  protocol_outer;
	//bit<8>  protocol_inner;

    state start {
        pkt.extract(ig_intr_md);
        ig_md.port           = ig_intr_md.ingress_port;
//      ig_md.timestamp      = ig_intr_md.ingress_mac_tstamp;
#ifdef SFC_TIMESTAMP_ENABLE
        hdr.transport.nsh_type1.timestamp = ig_intr_md.ingress_mac_tstamp[31:0];
#else
        hdr.transport.nsh_type1.timestamp = 0;
#endif
        ig_md.flags.rmac_hit = false;
#ifdef UDF_ENABLE
        ig_md.flags.parse_udf_reached = false;
#endif

        // Check for resubmit flag if packet is resubmitted.
        // transition select(ig_intr_md.resubmit_flag) {
        //     1 : parse_resubmit;
        //     0 : parse_port_metadata;
        // }

        ig_md.lkp_0.tunnel_type = SWITCH_TUNNEL_TYPE_NONE;
        ig_md.lkp_0.tunnel_id = 0;
        ig_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_NONE;
        ig_md.lkp_1.tunnel_id = 0;
        ig_md.lkp_2.tunnel_type = SWITCH_TUNNEL_TYPE_NONE;
        ig_md.lkp_2.tunnel_id = 0;

#ifdef INGRESS_PARSER_POPULATES_LKP_0
        // initialize lookup struct to zeros
        ig_md.lkp_0.mac_src_addr = 0;
        ig_md.lkp_0.mac_dst_addr = 0;
        ig_md.lkp_0.mac_type = 0;
        ig_md.lkp_0.pcp = 0;
        ig_md.lkp_0.pad = 0;
        ig_md.lkp_0.vid = 0;
        ig_md.lkp_0.ip_type = SWITCH_IP_TYPE_NONE;
        ig_md.lkp_0.ip_proto = 0;
        ig_md.lkp_0.ip_tos = 0; // not byte-aligned so set in mau
        ig_md.lkp_0.ip_flags = 0;
        ig_md.lkp_0.ip_src_addr = 0;
        ig_md.lkp_0.ip_dst_addr = 0;
        ig_md.lkp_0.ip_len = 0;
        ig_md.lkp_0.tcp_flags = 0;
        ig_md.lkp_0.l4_src_port = 0;
        ig_md.lkp_0.l4_dst_port = 0;
        //ig_md.lkp_0.tunnel_type = SWITCH_TUNNEL_TYPE_NONE; // do this always (above)
        //ig_md.lkp_0.tunnel_id = 0;                         // do this always (above)
        ig_md.lkp_0.drop_reason = 0;
#endif // INGRESS_PARSER_POPULATES_LKP_0

        
#ifdef INGRESS_PARSER_POPULATES_LKP_1
        // initialize lookup struct to zeros
        ig_md.lkp_1.mac_src_addr = 0;
        ig_md.lkp_1.mac_dst_addr = 0;
        ig_md.lkp_1.mac_type = 0;
        ig_md.lkp_1.pcp = 0;
        ig_md.lkp_1.pad = 0;
        ig_md.lkp_1.vid = 0;
        ig_md.lkp_1.ip_type = SWITCH_IP_TYPE_NONE;
        ig_md.lkp_1.ip_proto = 0;
        ig_md.lkp_1.ip_tos = 0; // not byte-aligned so set in mau
        ig_md.lkp_1.ip_flags = 0;
        ig_md.lkp_1.ip_src_addr = 0;
        ig_md.lkp_1.ip_dst_addr = 0;
        ig_md.lkp_1.ip_len = 0;
        ig_md.lkp_1.tcp_flags = 0;
        ig_md.lkp_1.l4_src_port = 0;
        ig_md.lkp_1.l4_dst_port = 0;
        //ig_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_NONE; // do this always (above)
        //ig_md.lkp_1.tunnel_id = 0;                         // do this always (above)
        ig_md.lkp_1.drop_reason = 0;
#endif // INGRESS_PARSER_POPULATES_LKP_1

        
#ifdef INGRESS_PARSER_POPULATES_LKP_2
        // initialize lookup struct (2) to zeros
        ig_md.lkp_2.mac_src_addr = 0;
        ig_md.lkp_2.mac_dst_addr = 0;
        ig_md.lkp_2.mac_type = 0;
        ig_md.lkp_2.pcp = 0;
        ig_md.lkp_2.pad = 0;
        ig_md.lkp_2.vid = 0;
        ig_md.lkp_2.ip_type = SWITCH_IP_TYPE_NONE;
        ig_md.lkp_2.ip_proto = 0;
        ig_md.lkp_2.ip_tos = 0; // not byte-aligned so set in mau
        ig_md.lkp_2.ip_flags = 0;
        ig_md.lkp_2.ip_src_addr = 0;
        ig_md.lkp_2.ip_dst_addr = 0;
        ig_md.lkp_2.ip_len = 0;
        ig_md.lkp_2.tcp_flags = 0;
        ig_md.lkp_2.l4_src_port = 0;
        ig_md.lkp_2.l4_dst_port = 0;
        //ig_md.lkp_2.tunnel_type = SWITCH_TUNNEL_TYPE_NONE; // do this always (above)
        //ig_md.lkp_2.tunnel_id = 0;                         // do this always (above)
        ig_md.lkp_2.drop_reason = 0;
#endif // INGRESS_PARSER_POPULATES_LKP_2

//      ig_md.inner_inner.ethernet_isValid = false;
//      ig_md.inner_inner.ipv4_isValid = false;
//      ig_md.inner_inner.ipv6_isValid = false;

        transition parse_port_metadata;
    }

    state parse_resubmit {
        // Parse resubmitted packet here.
        transition reject;
    }

    
    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////
    // Port Metadata
    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////
    
    state parse_port_metadata {
        // Parse port metadata produced by ibuf
        switch_port_metadata_t port_md = port_metadata_unpack<switch_port_metadata_t>(pkt);
        ig_md.port_lag_index = port_md.port_lag_index;
		ig_md.nsh_md.l2_fwd_en = (bool)port_md.l2_fwd_en;
        transition check_from_cpu;
    }
    
    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////
    // CPU Packet Check
    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////

#ifdef CPU_ENABLE
    
    state check_from_cpu {
        transition select(
            pkt.lookahead<ethernet_h>().ether_type,
            ig_intr_md.ingress_port) {

            cpu_port: check_my_mac_lo_cpu;
            default:  check_my_mac_lo;
        }
    }    
#else
    
    state check_from_cpu {
        transition check_my_mac_lo;
    }
#endif // CPU_ENABLE

    
    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////
    // My-MAC Check
    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////

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
            default:   parse_outer_ethernet; // Bridging path
        }
    }

    state check_my_mac_lo_cpu {
        transition select(pkt.lookahead<snoop_enet_my_mac_h>().dst_addr_lo) {
            my_mac_lo: check_my_mac_hi_cpu;
            default:   parse_outer_ethernet_cpu; // Bridging path
        }
    }

    state check_my_mac_hi {
        transition select(pkt.lookahead<snoop_enet_my_mac_h>().dst_addr_hi) {
            my_mac_hi: parse_transport_ethernet; // SFC Network-Tap / SFC Bypass Path
            default:   parse_outer_ethernet;     // Bridging path
        }
    }

    state check_my_mac_hi_cpu {
        transition select(pkt.lookahead<snoop_enet_my_mac_h>().dst_addr_hi) {
            my_mac_hi: parse_transport_ethernet_cpu; // SFC Network-Tap / SFC Bypass Path
            default:   parse_outer_ethernet_cpu;     // Bridging path
        }
    }

    
    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////
    // "Transport" Headers / Stack (L2-U)
    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////

    ///////////////////////////////////////////////////////////////////////////
    // Layer2 - Transport (ETH-T)
    ///////////////////////////////////////////////////////////////////////////
    // todo: explore implementing a fanout state here to save tcam
    
    state parse_transport_ethernet {
        ig_md.flags.rmac_hit = true;
        pkt.extract(hdr.transport.ethernet);

#ifdef INGRESS_PARSER_POPULATES_LKP_0
        ig_md.lkp_0.mac_src_addr = hdr.transport.ethernet.src_addr;
        ig_md.lkp_0.mac_dst_addr = hdr.transport.ethernet.dst_addr;
        ig_md.lkp_0.mac_type     = hdr.transport.ethernet.ether_type;
#endif // INGRESS_PARSER_POPULATES_LKP_0

#ifdef INGRESS_PARSER_POPULATES_LKP_1
        // populate for L3-tunnel case (where there's no L2 present)
        ig_md.lkp_1.mac_src_addr = hdr.transport.ethernet.src_addr;
        ig_md.lkp_1.mac_dst_addr = hdr.transport.ethernet.dst_addr;
        ig_md.lkp_1.mac_type     = hdr.transport.ethernet.ether_type;
#endif // INGRESS_PARSER_POPULATES_LKP_1

#ifdef INGRESS_PARSER_POPULATES_LKP_2
        // populate for L3-tunnel case (where there's no L2 present)
        ig_md.lkp_2.mac_src_addr = hdr.transport.ethernet.src_addr;
        ig_md.lkp_2.mac_dst_addr = hdr.transport.ethernet.dst_addr;
        ig_md.lkp_2.mac_type     = hdr.transport.ethernet.ether_type;
#endif // INGRESS_PARSER_POPULATES_LKP_2

        transition select(hdr.transport.ethernet.ether_type) {
            ETHERTYPE_NSH:  parse_transport_nsh;
            ETHERTYPE_VLAN: parse_transport_vlan;
            ETHERTYPE_QINQ: parse_transport_vlan;
#if defined(GRE_TRANSPORT_INGRESS_ENABLE) || defined(ERSPAN_TRANSPORT_INGRESS_ENABLE)
            ETHERTYPE_IPV4: parse_transport_ipv4;
#endif // defined(GRE_TRANSPORT_INGRESS_ENABLE) || defined(ERSPAN_TRANSPORT_INGRESS_ENABLE)
#if defined(GRE_TRANSPORT_INGRESS_ENABLE_V6) || defined(ERSPAN_TRANSPORT_INGRESS_ENABLE_V6)
            ETHERTYPE_IPV6: parse_transport_ipv6;
#endif // defined(GRE_TRANSPORT_INGRESS_ENABLE_V6) || defined(ERSPAN_TRANSPORT_INGRESS_ENABLE_V6)
           default: parse_udf;
        }
    }
        
    // -------------------------------------------------------------------------
    state parse_transport_ethernet_cpu {
        ig_md.flags.rmac_hit = true;
        pkt.extract(hdr.transport.ethernet);

#ifdef CPU_FABRIC_HEADER_ENABLE
        pkt.extract(hdr.fabric);
#endif // CPU_FABRIC_HEADER_ENABLE
        pkt.extract(hdr.cpu);

#ifdef CPU_IG_BYPASS_ENABLE
		ig_md.bypass = (bit<8>)hdr.cpu.reason_code;
#endif
        ig_md.port = (switch_port_t) hdr.cpu.ingress_port;
        ig_md.egress_port_lag_index = (switch_port_lag_index_t) hdr.cpu.port_lag_index;
		ig_md.bd = (switch_bd_t)hdr.cpu.ingress_bd;
#ifndef BUG_10933_WORKAROUND
		hdr.transport.ethernet.ether_type = hdr.cpu.ether_type; // done in port.p4 for now (see bf-case 10933)
#endif // BUG_10933_WORKAROUND
// #ifdef PTP_ENABLE
//         ig_md.flags.capture_ts = (bool) hdr.cpu.capture_ts;  // todo
// #endif // PTP_ENABLE
        
#ifdef INGRESS_PARSER_POPULATES_LKP_0
        ig_md.lkp_0.mac_src_addr = hdr.transport.ethernet.src_addr;
        ig_md.lkp_0.mac_dst_addr = hdr.transport.ethernet.dst_addr;
        ig_md.lkp_0.mac_type     = hdr.cpu.ether_type;
#endif // INGRESS_PARSER_POPULATES_LKP_0        

// populate for L3-tunnel case (where there's no L2 present)
#ifdef INGRESS_PARSER_POPULATES_LKP_1
        ig_md.lkp_1.mac_src_addr = hdr.transport.ethernet.src_addr;
        ig_md.lkp_1.mac_dst_addr = hdr.transport.ethernet.dst_addr;
        ig_md.lkp_1.mac_type     = hdr.cpu.ether_type;
#endif // INGRESS_PARSER_POPULATES_LKP_1

// populate for L3-tunnel case (where there's no L2 present)        
#ifdef INGRESS_PARSER_POPULATES_LKP_2
        ig_md.lkp_2.mac_src_addr = hdr.transport.ethernet.src_addr;
        ig_md.lkp_2.mac_dst_addr = hdr.transport.ethernet.dst_addr;
        ig_md.lkp_2.mac_type     = hdr.cpu.ether_type;
#endif // INGRESS_PARSER_POPULATES_LKP_2
        
        transition select(hdr.cpu.ether_type) {
            ETHERTYPE_NSH:  parse_transport_nsh;
            ETHERTYPE_VLAN: parse_transport_vlan;
            ETHERTYPE_QINQ: parse_transport_vlan;
#if defined(GRE_TRANSPORT_INGRESS_ENABLE) || defined(ERSPAN_TRANSPORT_INGRESS_ENABLE)
            ETHERTYPE_IPV4: parse_transport_ipv4;
#endif // defined(GRE_TRANSPORT_INGRESS_ENABLE) || defined(ERSPAN_TRANSPORT_INGRESS_ENABLE)
#if defined(GRE_TRANSPORT_INGRESS_ENABLE_V6) || defined(ERSPAN_TRANSPORT_INGRESS_ENABLE_V6)
            ETHERTYPE_IPV6: parse_transport_ipv6;
#endif // defined(GRE_TRANSPORT_INGRESS_ENABLE_V6) || defined(ERSPAN_TRANSPORT_INGRESS_ENABLE_V6)
            default: parse_udf;
        }
    }

    
    // -------------------------------------------------------------------------
    state parse_transport_vlan {

	    pkt.extract(hdr.transport.vlan_tag[0]);
        
#ifndef SF_0_L2_VLAN_ID_ENABLE
        ig_md.lkp_0.tunnel_type = SWITCH_TUNNEL_TYPE_VLAN;        
#endif // SF_0_L2_VLAN_ID_ENABLE

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
        ig_md.lkp_2.pcp = hdr.transport.vlan_tag[0].pcp;
  #ifdef SF_0_L2_VLAN_ID_ENABLE
        ig_md.lkp_2.vid = hdr.transport.vlan_tag[0].vid;
  #endif // SF_0_L2_VLAN_ID_ENABLE
        ig_md.lkp_2.mac_type = hdr.transport.vlan_tag[0].ether_type;
#endif // INGRESS_PARSER_POPULATES_LKP_2
        
        transition select(hdr.transport.vlan_tag[0].ether_type) {
            ETHERTYPE_NSH:  parse_transport_nsh;
#if defined(GRE_TRANSPORT_INGRESS_ENABLE) || defined(ERSPAN_TRANSPORT_INGRESS_ENABLE)
            ETHERTYPE_IPV4: parse_transport_ipv4;
#endif // defined(GRE_TRANSPORT_INGRESS_ENABLE) || defined(ERSPAN_TRANSPORT_INGRESS_ENABLE)
#if defined(GRE_TRANSPORT_INGRESS_ENABLE_V6) || defined(ERSPAN_TRANSPORT_INGRESS_ENABLE_V6)
            ETHERTYPE_IPV6: parse_transport_ipv6;
#endif // defined(GRE_TRANSPORT_INGRESS_ENABLE_V6) || defined(ERSPAN_TRANSPORT_INGRESS_ENABLE_V6)
            default: parse_udf;
        }
    }


    ///////////////////////////////////////////////////////////////////////////
    // Layer3 - Transport
    ///////////////////////////////////////////////////////////////////////////

#if defined(GRE_TRANSPORT_INGRESS_ENABLE) || defined(ERSPAN_TRANSPORT_INGRESS_ENABLE)
    
    state parse_transport_ipv4 {    
	    pkt.extract(hdr.transport.ipv4);

        ipv4_checksum_transport.add(hdr.transport.ipv4);
        ig_md.flags.ipv4_checksum_err_0 = ipv4_checksum_transport.verify();

#ifdef INGRESS_PARSER_POPULATES_LKP_0
        // todo: should the lkp struct be set in state parse_transport_ipv4_no_options_frags instead?
        ig_md.lkp_0.ip_type       = SWITCH_IP_TYPE_IPV4;
        ig_md.lkp_0.ip_proto      = hdr.transport.ipv4.protocol;
        ig_md.lkp.ip_tos          = hdr.transport.ipv4.tos; // not byte-aligned so set in mau
        ig_md.lkp_0.ip_flags      = hdr.transport.ipv4.flags;
        ig_md.lkp_0.ip_src_addr   = (bit<128>)hdr.transport.ipv4.src_addr;
        ig_md.lkp_0.ip_dst_addr   = (bit<128>)hdr.transport.ipv4.dst_addr;
        ig_md.lkp_0.ip_len        = hdr.transport.ipv4.total_len;
#endif // INGRESS_PARSER_POPULATES_LKP_0

        transition select(hdr.transport.ipv4.protocol) {
           IP_PROTOCOLS_GRE: parse_transport_gre;
           default : parse_udf;
        }
    }

#endif // defined(GRE_TRANSPORT_INGRESS_ENABLE) || defined(ERSPAN_TRANSPORT_INGRESS_ENABLE)
    

#if defined(GRE_TRANSPORT_INGRESS_ENABLE_V6) || defined(ERSPAN_TRANSPORT_INGRESS_ENABLE_V6)

    state parse_transport_ipv6 {
        pkt.extract(hdr.transport.ipv6);

#ifdef INGRESS_PARSER_POPULATES_LKP_0
        ig_md.lkp_0.ip_type       = SWITCH_IP_TYPE_IPV6;
        ig_md.lkp_0.ip_proto      = hdr.transport.ipv6.next_hdr;
        //ig_md.lkp_0.ip_tos        = hdr.transport.ipv6.tos; // not byte-aligned so set in mau
        ig_md.lkp_0.ip_src_addr   = hdr.transport.ipv6.src_addr;
        ig_md.lkp_0.ip_dst_addr   = hdr.transport.ipv6.dst_addr;
        ig_md.lkp_0.ip_len        = hdr.transport.ipv6.payload_len;
#endif // INGRESS_PARSER_POPULATES_LKP_0
        
        transition select(hdr.transport.ipv6.next_hdr) {
            IP_PROTOCOLS_GRE: parse_transport_gre;
            default: parse_udf;
        }
    }
#endif // defined(GRE_TRANSPORT_INGRESS_ENABLE_V6) || defined(ERSPAN_TRANSPORT_INGRESS_ENABLE_V6)

    

    ///////////////////////////////////////////////////////////////////////////
    // Tunnels - Transport
    ///////////////////////////////////////////////////////////////////////////    

#if defined(GRE_TRANSPORT_INGRESS_ENABLE) || defined(ERSPAN_TRANSPORT_INGRESS_ENABLE) || defined(GRE_TRANSPORT_INGRESS_ENABLE_V6) || defined(ERSPAN_TRANSPORT_INGRESS_ENABLE_V6)
    
    //-------------------------------------------------------------------------
    // GRE - Transport
    //-------------------------------------------------------------------------
    
    state parse_transport_gre {    
        pkt.extract(hdr.transport.gre);
        ig_md.lkp_0.tunnel_type = SWITCH_TUNNEL_TYPE_GRE;
        ig_md.lkp_0.tunnel_id = 0;
        
        transition select(
            hdr.transport.gre.C,
            hdr.transport.gre.R,
            hdr.transport.gre.K,
            hdr.transport.gre.S,
            hdr.transport.gre.s,
            hdr.transport.gre.recurse,
            hdr.transport.gre.flags,
            hdr.transport.gre.version,
            hdr.transport.gre.proto) {

          // C R K S s r f v
            (0,0,0,0,0,0,0,0,ETHERTYPE_IPV4): parse_outer_ipv4;
            (0,0,0,0,0,0,0,0,ETHERTYPE_IPV6): parse_outer_ipv6;            
#if defined(ERSPAN_TRANSPORT_INGRESS_ENABLE) || defined(ERSPAN_TRANSPORT_INGRESS_ENABLE_V6)
            (0,0,0,1,0,0,0,0,GRE_PROTOCOLS_ERSPAN_TYPE_2): parse_transport_erspan_t2;
          //(0,0,0,1,0,0,0,0,GRE_PROTOCOLS_ERSPAN_TYPE_3): parse_transport_erspan_t3;
#endif // defined(ERSPAN_TRANSPORT_INGRESS_ENABLE) || defined(ERSPAN_TRANSPORT_INGRESS_ENABLE_V6)
            default: parse_udf;
        }
    }

#endif // defined(GRE_TRANSPORT_INGRESS_ENABLE) || defined(ERSPAN_TRANSPORT_INGRESS_ENABLE) || defined(GRE_TRANSPORT_INGRESS_ENABLE_V6) || defined(ERSPAN_TRANSPORT_INGRESS_ENABLE_V6)

    
    //-------------------------------------------------------------------------
    // ERSPAN - Transport
    //-------------------------------------------------------------------------

#if defined(ERSPAN_TRANSPORT_INGRESS_ENABLE) || defined(ERSPAN_TRANSPORT_INGRESS_ENABLE_V6)

    state parse_transport_erspan_t2 {
        pkt.extract(hdr.transport.gre_sequence);
        pkt.extract(hdr.transport.erspan_type2);
        ig_md.lkp_0.tunnel_type = SWITCH_TUNNEL_TYPE_ERSPAN;
        ig_md.lkp_0.tunnel_id = 0; // todo: should this be populated?
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
   
#endif // defined(ERSPAN_TRANSPORT_INGRESS_ENABLE) || defined(ERSPAN_TRANSPORT_INGRESS_ENABLE_V6)

    
    //-------------------------------------------------------------------------
    // NSH - Transport
    //-------------------------------------------------------------------------

    state parse_transport_nsh {
	    pkt.extract(hdr.transport.nsh_type1);
        transition select(hdr.transport.nsh_type1.next_proto) {
            NSH_PROTOCOLS_ETH: parse_outer_ethernet;
            default: parse_udf;  // todo: support ipv4? ipv6?
        }
    }

    
    
    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////
    // "Outer" Headers / Stack
    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////
    
    ///////////////////////////////////////////////////////////////////////////
    // Layer2 - Outer (ETH)
    ///////////////////////////////////////////////////////////////////////////
    // todo: explore implementing a fanout state here to save tcam

    state parse_outer_ethernet {
        pkt.extract(hdr.outer.ethernet);

#ifdef INGRESS_PARSER_POPULATES_LKP_1
        ig_md.lkp_1.mac_src_addr = hdr.outer.ethernet.src_addr;
        ig_md.lkp_1.mac_dst_addr = hdr.outer.ethernet.dst_addr;
        ig_md.lkp_1.mac_type     = hdr.outer.ethernet.ether_type;
        ig_md.lkp_1.pcp = 0;
        ig_md.lkp_1.vid = 0;        
#endif // INGRESS_PARSER_POPULATES_LKP_1

// populate for L3-tunnel case (where there's no L2 present)
#ifdef INGRESS_PARSER_POPULATES_LKP_2
        ig_md.lkp_2.mac_src_addr = hdr.outer.ethernet.src_addr;
        ig_md.lkp_2.mac_dst_addr = hdr.outer.ethernet.dst_addr;
        ig_md.lkp_2.mac_type     = hdr.outer.ethernet.ether_type;
        ig_md.lkp_2.pcp = 0;
        ig_md.lkp_2.vid = 0;
#endif // INGRESS_PARSER_POPULATES_LKP_2

        transition select(hdr.outer.ethernet.ether_type) {

#ifdef ETAG_ENABLE
            ETHERTYPE_BR : parse_outer_br;
#endif // ETAG_ENABLE
#ifdef VNTAG_ENABLE
            ETHERTYPE_VN : parse_outer_vn;
#endif // VNTAG_ENABLE

            ETHERTYPE_VLAN : parse_outer_vlan_0;
            ETHERTYPE_QINQ : parse_outer_vlan_0;
#ifdef MPLS_ENABLE
            ETHERTYPE_MPLS : parse_outer_mpls;
#endif // MPLS_ENABLE
            ETHERTYPE_ARP  : parse_outer_arp;
            ETHERTYPE_IPV4 : parse_outer_ipv4;
            ETHERTYPE_IPV6 : parse_outer_ipv6;
            default : parse_udf;
        }
    }

    
    state parse_outer_ethernet_cpu {
        pkt.extract(hdr.outer.ethernet);
#ifdef CPU_FABRIC_HEADER_ENABLE
        pkt.extract(hdr.fabric);
#endif // CPU_FABRIC_HEADER_ENABLE
        pkt.extract(hdr.cpu);

        ig_md.port = (switch_port_t) hdr.cpu.ingress_port;
        ig_md.egress_port_lag_index = (switch_port_lag_index_t) hdr.cpu.port_lag_index;
		ig_md.bd = (switch_bd_t)hdr.cpu.ingress_bd;
#ifndef BUG_10933_WORKAROUND
		hdr.outer.ethernet.ether_type = hdr.cpu.ether_type; // done in port.p4 for now (see bf-case 10933)
#endif // BUG_10933_WORKAROUND
// #ifdef PTP_ENABLE
//         ig_md.flags.capture_ts = (bool) hdr.cpu.capture_ts;  // todo
// #endif // PTP_ENABLE

#ifdef INGRESS_PARSER_POPULATES_LKP_1
        ig_md.lkp_1.mac_src_addr = hdr.outer.ethernet.src_addr;
        ig_md.lkp_1.mac_dst_addr = hdr.outer.ethernet.dst_addr;
        ig_md.lkp_1.mac_type     = hdr.cpu.ether_type;
        ig_md.lkp_1.pcp = 0;
        ig_md.lkp_1.vid = 0;        
#endif // INGRESS_PARSER_POPULATES_LKP_1

// populate for L3-tunnel case (where there's no L2 present)
#ifdef INGRESS_PARSER_POPULATES_LKP_2
        ig_md.lkp_2.mac_src_addr = hdr.outer.ethernet.src_addr;
        ig_md.lkp_2.mac_dst_addr = hdr.outer.ethernet.dst_addr;
        ig_md.lkp_2.mac_type     = hdr.cpu.ether_type;
        ig_md.lkp_2.pcp = 0;
        ig_md.lkp_2.vid = 0;
#endif // INGRESS_PARSER_POPULATES_LKP_2

        transition select(hdr.cpu.ether_type) {
            
#ifdef ETAG_ENABLE
            ETHERTYPE_BR : parse_outer_br;
#endif // ETAG_ENABLE
#ifdef VNTAG_ENABLE
            ETHERTYPE_VN : parse_outer_vn;
#endif // VNTAG_ENABLE

            ETHERTYPE_VLAN : parse_outer_vlan_0;
            ETHERTYPE_QINQ : parse_outer_vlan_0;
#ifdef MPLS_ENABLE
            ETHERTYPE_MPLS : parse_outer_mpls;
#endif // MPLS_ENABLE
            ETHERTYPE_ARP  : parse_outer_arp;
            ETHERTYPE_IPV4 : parse_outer_ipv4;
            ETHERTYPE_IPV6 : parse_outer_ipv6;
            default : parse_udf;
        }
    }

#ifdef ETAG_ENABLE
    state parse_outer_br {
	    pkt.extract(hdr.outer.e_tag);
        
#ifdef INGRESS_PARSER_POPULATES_LKP_1        
        ig_md.lkp_1.mac_type = hdr.outer.e_tag.ether_type;        
        //ig_md.lkp_1.pcp = hdr.outer.e_tag.pcp;  // do not populate w/ e-tag
#endif // INGRESS_PARSER_POPULATES_LKP_1

// populate for L3-tunnel case (where there's no L2 present)
#ifdef INGRESS_PARSER_POPULATES_LKP_2
        ig_md.lkp_2.mac_type = hdr.outer.e_tag.ether_type;        
        //ig_md.lkp_2.pcp = hdr.outer.e_tag.pcp;  // do not populate w/ e-tag
#endif // INGRESS_PARSER_POPULATES_LKP_2

        transition select(hdr.outer.e_tag.ether_type) {
            ETHERTYPE_VLAN : parse_outer_vlan_0;
            ETHERTYPE_QINQ : parse_outer_vlan_0;
#ifdef MPLS_ENABLE
            ETHERTYPE_MPLS : parse_outer_mpls;
#endif // MPLS_ENABLE
            ETHERTYPE_IPV4 : parse_outer_ipv4;
            ETHERTYPE_ARP  : parse_outer_arp;
            ETHERTYPE_IPV6 : parse_outer_ipv6;
            default : parse_udf;
        }
    }
#endif // ETAG_ENABLE
    
#ifdef VNTAG_ENABLE
    state parse_outer_vn {
	    pkt.extract(hdr.outer.vn_tag);
        
#ifdef INGRESS_PARSER_POPULATES_LKP_1        
        ig_md.lkp_1.mac_type = hdr.outer.vn_tag.ether_type;
#endif // INGRESS_PARSER_POPULATES_LKP_1

// populate for L3-tunnel case (where there's no L2 present)
#ifdef INGRESS_PARSER_POPULATES_LKP_2
        ig_md.lkp_2.mac_type = hdr.outer.vn_tag.ether_type;        
#endif // INGRESS_PARSER_POPULATES_LKP_2

        transition select(hdr.outer.vn_tag.ether_type) {
            ETHERTYPE_VLAN : parse_outer_vlan_0;
            ETHERTYPE_QINQ : parse_outer_vlan_0;
#ifdef MPLS_ENABLE
            ETHERTYPE_MPLS : parse_outer_mpls;
#endif // MPLS_ENABLE
            ETHERTYPE_IPV4 : parse_outer_ipv4;
            ETHERTYPE_ARP  : parse_outer_arp;
            ETHERTYPE_IPV6 : parse_outer_ipv6;
            default : parse_udf;
        }
    }
#endif // VNTAG_ENABLE

    
    state parse_outer_vlan_0 {

	    pkt.extract(hdr.outer.vlan_tag[0]);

#ifndef SF_0_L2_VLAN_ID_ENABLE
        ig_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_VLAN;
#endif // SF_0_L2_VLAN_ID_ENABLE
        
#ifdef INGRESS_PARSER_POPULATES_LKP_1        
        ig_md.lkp_1.pcp = hdr.outer.vlan_tag[0].pcp;        
  #ifdef SF_0_L2_VLAN_ID_ENABLE
        ig_md.lkp_1.vid = hdr.outer.vlan_tag[0].vid;
  #endif // SF_0_L2_VLAN_ID_ENABLE
        ig_md.lkp_1.mac_type = hdr.outer.vlan_tag[0].ether_type;
#endif // INGRESS_PARSER_POPULATES_LKP_1

// populate for L3-tunnel case (where there's no L2 present)
#ifdef INGRESS_PARSER_POPULATES_LKP_2
        ig_md.lkp_2.pcp = hdr.outer.vlan_tag[0].pcp;        
  #ifdef SF_0_L2_VLAN_ID_ENABLE
        ig_md.lkp_2.vid = hdr.outer.vlan_tag[0].vid;
  #endif // SF_0_L2_VLAN_ID_ENABLE
        ig_md.lkp_2.mac_type = hdr.outer.vlan_tag[0].ether_type;
#endif // INGRESS_PARSER_POPULATES_LKP_2

        transition select(hdr.outer.vlan_tag[0].ether_type) {
            ETHERTYPE_VLAN : parse_outer_vlan_1;
            ETHERTYPE_QINQ : parse_outer_vlan_1;
#ifdef MPLS_ENABLE
            ETHERTYPE_MPLS : parse_outer_mpls;
#endif
            ETHERTYPE_IPV4 : parse_outer_ipv4;
            ETHERTYPE_ARP  : parse_outer_arp;
            ETHERTYPE_IPV6 : parse_outer_ipv6;
            default : parse_udf;
        }
    }

    
    state parse_outer_vlan_1 {
	    pkt.extract(hdr.outer.vlan_tag[1]);

#ifdef INGRESS_PARSER_POPULATES_LKP_1        
        ig_md.lkp_1.mac_type = hdr.outer.vlan_tag[1].ether_type;
#endif // INGRESS_PARSER_POPULATES_LKP_1

// populate for L3-tunnel case (where there's no L2 present)
#ifdef INGRESS_PARSER_POPULATES_LKP_2
        ig_md.lkp_2.mac_type = hdr.outer.vlan_tag[1].ether_type;
#endif // INGRESS_PARSER_POPULATES_LKP_2

        transition select(hdr.outer.vlan_tag[1].ether_type) {
#ifdef MPLS_ENABLE
            ETHERTYPE_MPLS : parse_outer_mpls;
#endif
            ETHERTYPE_IPV4 : parse_outer_ipv4;
            ETHERTYPE_ARP  : parse_outer_arp;
            ETHERTYPE_IPV6 : parse_outer_ipv6;
            default : parse_udf;
        }
    }
    

    ///////////////////////////////////////////////////////////////////////////
    // Layer 2.5 - Outer
    ///////////////////////////////////////////////////////////////////////////

    state parse_outer_arp {
        // pkt.extract(hdr.outer.arp);
        // transition accept;
        transition parse_udf;

    }


    ///////////////////////////////////////////////////////////////////////////
    // Layer 3 - Outer
    ///////////////////////////////////////////////////////////////////////////

//     state parse_outer_ipv4 {
//         pkt.extract(hdr.outer.ipv4);
//         protocol_outer = hdr.outer.ipv4.protocol;
// #ifdef INGRESS_PARSER_POPULATES_LKP_1
//         // todo: should the lkp struct be set in state parse_outer_ipv4_no_options_frags instead?
//         ig_md.lkp_1.ip_type       = SWITCH_IP_TYPE_IPV4;
//         ig_md.lkp_1.ip_proto      = hdr.outer.ipv4.protocol;
//         ig_md.lkp_1.ip_tos        = hdr.outer.ipv4.tos; // not byte-aligned so set in mau
//         ig_md.lkp_1.ip_flags      = hdr.outer.ipv4.flags;
//         ig_md.lkp_1.ip_src_addr   = (bit<128>)hdr.outer.ipv4.src_addr;
//         ig_md.lkp_1.ip_dst_addr   = (bit<128>)hdr.outer.ipv4.dst_addr;
//         ig_md.lkp_1.ip_len        = hdr.outer.ipv4.total_len;
// #endif // INGRESS_PARSER_POPULATES_LKP_1
//         // Flag packet (to be sent to host) if it's a frag or has options.
//         ipv4_checksum_outer.add(hdr.outer.ipv4);
//         transition select(hdr.outer.ipv4.ihl, hdr.outer.ipv4.frag_offset) {
//             (5, 0): parse_outer_ipv4_no_options_frags;
//             default : parse_udf;
//         }
//     }
// 
//     state parse_outer_ipv4_no_options_frags {
//         ig_md.flags.ipv4_checksum_err_1 = ipv4_checksum_outer.verify();
//         transition select(hdr.outer.ipv4.protocol) {
//             IP_PROTOCOLS_ICMP: parse_outer_icmp_igmp_overload;
//             IP_PROTOCOLS_IGMP: parse_outer_icmp_igmp_overload;
//             default: branch_outer_l3_protocol;
//         }
//     }

    state parse_outer_ipv4 {
        pkt.extract(hdr.outer.ipv4);
#ifdef INGRESS_PARSER_POPULATES_LKP_1
        // todo: should the lkp struct be set in state parse_outer_ipv4_no_options_frags instead?
        ig_md.lkp_1.ip_type       = SWITCH_IP_TYPE_IPV4;
        ig_md.lkp_1.ip_proto      = hdr.outer.ipv4.protocol;
        ig_md.lkp_1.ip_tos        = hdr.outer.ipv4.tos; // not byte-aligned so set in mau
        ig_md.lkp_1.ip_flags      = hdr.outer.ipv4.flags;
        ig_md.lkp_1.ip_src_addr   = (bit<128>)hdr.outer.ipv4.src_addr;
        ig_md.lkp_1.ip_dst_addr   = (bit<128>)hdr.outer.ipv4.dst_addr;
        ig_md.lkp_1.ip_len        = hdr.outer.ipv4.total_len;
#endif // INGRESS_PARSER_POPULATES_LKP_1
        // Flag packet (to be sent to host) if it's a frag or has options.
        ipv4_checksum_outer.add(hdr.outer.ipv4);
        transition select(hdr.outer.ipv4.ihl, hdr.outer.ipv4.frag_offset) {
            (5, 0): parse_outer_ipv4_no_options_frags;
            default : parse_udf;
        }
    }

    state parse_outer_ipv4_no_options_frags {
        ig_md.flags.ipv4_checksum_err_1 = ipv4_checksum_outer.verify();
        transition select(hdr.outer.ipv4.protocol) {
            IP_PROTOCOLS_ICMP: parse_outer_icmp_igmp_overload;
            IP_PROTOCOLS_IGMP: parse_outer_icmp_igmp_overload;
            IP_PROTOCOLS_IPV4: parse_outer_ipinip_set_tunnel_type;
            IP_PROTOCOLS_IPV6: parse_outer_ipv6inip_set_tunnel_type;
            IP_PROTOCOLS_UDP: parse_outer_udp;
            IP_PROTOCOLS_TCP: parse_outer_tcp;
            IP_PROTOCOLS_SCTP: parse_outer_sctp;
            IP_PROTOCOLS_GRE: parse_outer_gre;
            IP_PROTOCOLS_ESP: parse_outer_esp_overload;
            default: parse_udf;
        }
    }

    
//     state parse_outer_ipv6 {
// #ifdef IPV6_ENABLE
//         pkt.extract(hdr.outer.ipv6);
//         protocol_outer = hdr.outer.ipv6.next_hdr;
// #ifdef INGRESS_PARSER_POPULATES_LKP_1        
//         ig_md.lkp_1.ip_type       = SWITCH_IP_TYPE_IPV6;
//         ig_md.lkp_1.ip_proto      = hdr.outer.ipv6.next_hdr;
//         //ig_md.lkp_1.ip_tos        = hdr.outer.ipv6.tos; // not byte-aligned so set in mau
//         ig_md.lkp_1.ip_src_addr   = hdr.outer.ipv6.src_addr;
//         ig_md.lkp_1.ip_dst_addr   = hdr.outer.ipv6.dst_addr;
//         ig_md.lkp_1.ip_len        = hdr.outer.ipv6.payload_len;
// #endif // INGRESS_PARSER_POPULATES_LKP_1
//         transition select(hdr.outer.ipv6.next_hdr) {
//             IP_PROTOCOLS_ICMPV6: parse_outer_icmp_igmp_overload;
//             default: branch_outer_l3_protocol;
//         }
// #else
//         transition reject;
// #endif
//     }


    state parse_outer_ipv6 {
#ifdef IPV6_ENABLE
        pkt.extract(hdr.outer.ipv6);
#ifdef INGRESS_PARSER_POPULATES_LKP_1        
        ig_md.lkp_1.ip_type       = SWITCH_IP_TYPE_IPV6;
        ig_md.lkp_1.ip_proto      = hdr.outer.ipv6.next_hdr;
        //ig_md.lkp_1.ip_tos        = hdr.outer.ipv6.tos; // not byte-aligned so set in mau
        ig_md.lkp_1.ip_src_addr   = hdr.outer.ipv6.src_addr;
        ig_md.lkp_1.ip_dst_addr   = hdr.outer.ipv6.dst_addr;
        ig_md.lkp_1.ip_len        = hdr.outer.ipv6.payload_len;
#endif // INGRESS_PARSER_POPULATES_LKP_1
        transition select(hdr.outer.ipv6.next_hdr) {
            IP_PROTOCOLS_ICMPV6: parse_outer_icmp_igmp_overload;
            IP_PROTOCOLS_IPV4: parse_outer_ipinip_set_tunnel_type;
            IP_PROTOCOLS_IPV6: parse_outer_ipv6inip_set_tunnel_type;
            IP_PROTOCOLS_UDP: parse_outer_udp;
            IP_PROTOCOLS_TCP: parse_outer_tcp;
            IP_PROTOCOLS_SCTP: parse_outer_sctp;
            IP_PROTOCOLS_GRE: parse_outer_gre;
            IP_PROTOCOLS_ESP: parse_outer_esp_overload;
            default: parse_udf;
        }
#else
        transition reject;
#endif
    }

    
    // // shared fanout/branch state to save tcam resource
    // state branch_outer_l3_protocol {
    //     transition select(protocol_outer) {
    //         IP_PROTOCOLS_IPV4: parse_outer_ipinip_set_tunnel_type;
    //         IP_PROTOCOLS_IPV6: parse_outer_ipv6inip_set_tunnel_type;
    //         IP_PROTOCOLS_UDP: parse_outer_udp;
    //         IP_PROTOCOLS_TCP: parse_outer_tcp;
    //         IP_PROTOCOLS_SCTP: parse_outer_sctp;
    //         IP_PROTOCOLS_GRE: parse_outer_gre;
    //         IP_PROTOCOLS_ESP: parse_outer_esp_overload;
    //         default: parse_udf;
    //    }
    // }


    // For ICMP and IGMP, we're not actually extracting the header;
    // We're simply over-loading L4-port info for policy via lookahead.    
    state parse_outer_icmp_igmp_overload {
#if defined(PARSER_L4_PORT_OVERLOAD) && defined(INGRESS_PARSER_POPULATES_LKP_1)
        ig_md.lkp_1.l4_src_port = pkt.lookahead<bit<16>>();
#endif
        transition parse_udf;
    }


    ///////////////////////////////////////////////////////////////////////////
    // Layer 4 - Outer
    ///////////////////////////////////////////////////////////////////////////

    //-------------------------------------------------------------------------
    // User Datagram Protocol (UDP) - Outer
    //-------------------------------------------------------------------------

    state parse_outer_udp {
        pkt.extract(hdr.outer.udp);
        
#ifdef INGRESS_PARSER_POPULATES_LKP_1        
        ig_md.lkp_1.l4_src_port = hdr.outer.udp.src_port;
        ig_md.lkp_1.l4_dst_port = hdr.outer.udp.dst_port;       
#endif // INGRESS_PARSER_POPULATES_LKP_1
        
        transition select(hdr.outer.udp.src_port, hdr.outer.udp.dst_port) {
            
#ifdef VXLAN_ENABLE
            (_, UDP_PORT_VXLAN): parse_outer_vxlan;
#endif // VXLAN_ENABLE
            
#ifdef GTP_ENABLE
            (_, UDP_PORT_GTP_C): parse_outer_gtp_c;
            (UDP_PORT_GTP_C, _): parse_outer_gtp_c;
            (_, UDP_PORT_GTP_U): parse_outer_gtp_u;
            (UDP_PORT_GTP_U, _): parse_outer_gtp_u;
            // (UDP_PORT_GTP_C, UDP_PORT_GTP_C): parse_outer_gtp_c;
            // (UDP_PORT_GTP_U, UDP_PORT_GTP_U): parse_outer_gtp_u;            
#endif // GTP_ENABLE
            default : parse_udf;
        }
    }

    //-------------------------------------------------------------------------
    // Transmission Control Protocol (TCP) - Outer
    //-------------------------------------------------------------------------

    state parse_outer_tcp {
        pkt.extract(hdr.outer.tcp);
#ifdef INGRESS_PARSER_POPULATES_LKP_1        
        ig_md.lkp_1.l4_src_port = hdr.outer.tcp.src_port;
        ig_md.lkp_1.l4_dst_port = hdr.outer.tcp.dst_port;
        ig_md.lkp_1.tcp_flags   = hdr.outer.tcp.flags;
#endif // INGRESS_PARSER_POPULATES_LKP_1
        transition parse_udf;
    }

    //-------------------------------------------------------------------------
    // Stream Control Transmission Protocol (SCTP) - Outer
    //-------------------------------------------------------------------------

    state parse_outer_sctp {
        pkt.extract(hdr.outer.sctp);
#ifdef INGRESS_PARSER_POPULATES_LKP_1        
        ig_md.lkp_1.l4_src_port = hdr.outer.sctp.src_port;
        ig_md.lkp_1.l4_dst_port = hdr.outer.sctp.dst_port;
#endif // INGRESS_PARSER_POPULATES_LKP_1
        transition parse_udf;
    }


    ///////////////////////////////////////////////////////////////////////////////
    // Layer X - Outer
    ///////////////////////////////////////////////////////////////////////////////

    //-------------------------------------------------------------------------
    // Multi-Protocol Label Switching (MPLS) - Outer
    //-------------------------------------------------------------------------
        
#if defined(MPLS_ENABLE) || defined(MPLSoGRE_ENABLE)

    // Set tunnel info for outermost label only
    state parse_outer_mpls {
        ig_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_MPLS;
        // error: Inferred incompatible container alignments for field
        // ingress::ig_md.lkp_1.tunnel_id: alignment = 0 != alignment = 4 (little endian)       
        // ig_md.lkp_1.tunnel_id = (bit<switch_tunnel_id_width>)pkt.lookahead<mpls_h>().label;
        ig_md.lkp_1.tunnel_id = pkt.lookahead<bit<32>>();
#ifdef INGRESS_PARSER_INNER_TUNNEL_INFO_OVERLOAD
        ig_md.lkp_2.tunnel_type = SWITCH_TUNNEL_TYPE_MPLS;
        ig_md.lkp_2.tunnel_id = pkt.lookahead<bit<32>>();
#endif // INGRESS_PARSER_INNER_TUNNEL_INFO_OVERLOAD   
        transition extract_outer_mpls;
    }
    
    state extract_outer_mpls {
    //state parse_outer_mpls {
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

#endif  // defined(MPLS_ENABLE) || defined(MPLSoGRE_ENABLE)



    ///////////////////////////////////////////////////////////////////////////
    // Tunnels - Outer
    ///////////////////////////////////////////////////////////////////////////

    //-------------------------------------------------------------------------
    // Virtual Extensible Local Area Network (VXLAN) - Outer
    //-------------------------------------------------------------------------

#ifdef VXLAN_ENABLE
    
    state parse_outer_vxlan {
        pkt.extract(hdr.outer.vxlan);
        ig_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_VXLAN;
        ig_md.lkp_1.tunnel_id = (bit<switch_tunnel_id_width>)hdr.outer.vxlan.vni;
#ifdef INGRESS_PARSER_INNER_TUNNEL_INFO_OVERLOAD
        ig_md.lkp_2.tunnel_type = SWITCH_TUNNEL_TYPE_VXLAN;
        ig_md.lkp_2.tunnel_id = (bit<switch_tunnel_id_width>)hdr.outer.vxlan.vni;
#endif // INGRESS_PARSER_INNER_TUNNEL_INFO_OVERLOAD   
        transition parse_inner_ethernet; 
    }

#endif // VXLAN_ENABLE
    

    //-------------------------------------------------------------------------
    // Internet Protocol (IP) - Outer
    //-------------------------------------------------------------------------

    state parse_outer_ipinip_set_tunnel_type {
#ifdef IPINIP
        ig_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_IPINIP;
        ig_md.lkp_1.tunnel_id = 0;
#ifdef INGRESS_PARSER_INNER_TUNNEL_INFO_OVERLOAD
        ig_md.lkp_2.tunnel_type = SWITCH_TUNNEL_TYPE_IPINIP;
        ig_md.lkp_2.tunnel_id = 0;
#endif // INGRESS_PARSER_INNER_TUNNEL_INFO_OVERLOAD   
        transition parse_inner_ipv4;
#else
        transition parse_udf;
#endif /* IPINIP */
    }

    state parse_outer_ipv6inip_set_tunnel_type {
#ifdef IPINIP
        ig_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_IPINIP;
        ig_md.lkp_1.tunnel_id = 0;
#ifdef INGRESS_PARSER_INNER_TUNNEL_INFO_OVERLOAD
        ig_md.lkp_2.tunnel_type = SWITCH_TUNNEL_TYPE_IPINIP;
        ig_md.lkp_2.tunnel_id = 0;
#endif // INGRESS_PARSER_INNER_TUNNEL_INFO_OVERLOAD   
        transition parse_inner_ipv6;
#else
        transition parse_udf;
#endif /* IPINIP */
    }


    //-------------------------------------------------------------------------
    // Generic Routing Encapsulation (GRE) - Outer
    //-------------------------------------------------------------------------

    state parse_outer_gre {    
        pkt.extract(hdr.outer.gre);
        ig_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_GRE;
        ig_md.lkp_1.tunnel_id = 0;
#ifdef INGRESS_PARSER_INNER_TUNNEL_INFO_OVERLOAD
        ig_md.lkp_2.tunnel_type = SWITCH_TUNNEL_TYPE_GRE;
        ig_md.lkp_2.tunnel_id = 0;
#endif // INGRESS_PARSER_INNER_TUNNEL_INFO_OVERLOAD   

        transition select(
            hdr.outer.gre.C,
            hdr.outer.gre.R,
            hdr.outer.gre.K,
            hdr.outer.gre.S,
            hdr.outer.gre.s,
            hdr.outer.gre.recurse,
            hdr.outer.gre.flags,
            hdr.outer.gre.version,
            hdr.outer.gre.proto) {

          // C R K S s r f v
#ifdef NVGRE_ENABLE
            (0,0,1,0,0,0,0,0,GRE_PROTOCOLS_NVGRE): parse_outer_nvgre;
#endif // NVGRE_ENABLE
            (0,0,0,0,0,0,0,0,ETHERTYPE_IPV4): parse_inner_ipv4;
            (0,0,0,0,0,0,0,0,ETHERTYPE_IPV6): parse_inner_ipv6;                        
#ifdef MPLSoGRE_ENABLE
            (0,0,0,0,0,0,0,0,ETHERTYPE_MPLS): parse_outer_mpls;
#endif // MPLSoGRE_ENABLE            
            (1,0,0,0,0,0,0,0,_): parse_outer_gre_optional;
            (0,0,1,0,0,0,0,0,_): parse_outer_gre_optional;
            (0,0,0,1,0,0,0,0,_): parse_outer_gre_optional;
            default: parse_udf;
        }
    }

    state parse_outer_gre_optional {    
        pkt.extract(hdr.outer.gre_optional);
        transition select(hdr.outer.gre.proto) {

            ETHERTYPE_IPV4: parse_inner_ipv4;
            ETHERTYPE_IPV6: parse_inner_ipv6;                        
#ifdef MPLSoGRE_ENABLE
            ETHERTYPE_MPLS: parse_outer_mpls;
#endif // MPLSoGRE_ENABLE            
            default: parse_udf;
        }
    }
    
    
#ifdef NVGRE_ENABLE
    //-------------------------------------------------------------------------
    // Network Virtualization using GRE (NVGRE) - Outer
    //-------------------------------------------------------------------------

    state parse_outer_nvgre {
    	pkt.extract(hdr.outer.nvgre);
        ig_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_NVGRE;
        ig_md.lkp_1.tunnel_id = (bit<switch_tunnel_id_width>)hdr.outer.nvgre.vsid;
        ig_md.tunnel_1.nvgre_flow_id = hdr.outer.nvgre.flow_id; // from switch
#ifdef INGRESS_PARSER_INNER_TUNNEL_INFO_OVERLOAD
        ig_md.lkp_2.tunnel_type = SWITCH_TUNNEL_TYPE_NVGRE;
        ig_md.lkp_2.tunnel_id = (bit<switch_tunnel_id_width>)hdr.outer.nvgre.vsid;
#endif // INGRESS_PARSER_INNER_TUNNEL_INFO_OVERLOAD   
   	    transition parse_inner_ethernet;
    }
#endif // NVGRE_ENABLE

    
    //-------------------------------------------------------------------------
    // Encapsulating Security Payload (ESP) - Outer
    //-------------------------------------------------------------------------

    state parse_outer_esp_overload {
#if defined(PARSER_L4_PORT_OVERLOAD) && defined(INGRESS_PARSER_POPULATES_LKP_1)
        ig_md.lkp_1.l4_src_port = pkt.lookahead<esp_h>().spi_hi;
        ig_md.lkp_1.l4_dst_port = pkt.lookahead<esp_h>().spi_lo;
#endif
        transition parse_udf;
    }


    //-------------------------------------------------------------------------
    // GPRS (General Packet Radio Service) Tunneling Protocol (GTP) - Outer
    //-------------------------------------------------------------------------
    // Based on pseudo code from Glenn (see email from 03/11/2019):

#ifdef GTP_ENABLE

    // GTP-C
    //-------------------------------------------------------------------------
    // For GTP-C, we're not actually extracting the header;
    // We're simply grabbing TEID for policy via lookahead, then dumping to UDF
    
    state parse_outer_gtp_c {
        transition select(
            pkt.lookahead<gtp_v2_base_h>().version,
            pkt.lookahead<gtp_v2_base_h>().T
        ) {
            (2, 1): extract_outer_gtp_c;
            default: parse_udf;
        }
    }

    state extract_outer_gtp_c {
        ig_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_GTPC;
        ig_md.lkp_1.tunnel_id = pkt.lookahead<gtp_v2_base_h>().teid;
#ifdef INGRESS_PARSER_INNER_TUNNEL_INFO_OVERLOAD
        ig_md.lkp_2.tunnel_type = SWITCH_TUNNEL_TYPE_GTPC;
        ig_md.lkp_2.tunnel_id = pkt.lookahead<gtp_v2_base_h>().teid;
#endif // INGRESS_PARSER_INNER_TUNNEL_INFO_OVERLOAD   
    	transition parse_udf;
    }

    // GTP-U
    //-------------------------------------------------------------------------
    // Only supports optional header for sequence-number
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
            (1, 1, 0, 1, 0): extract_outer_gtp_u_with_optional;
            default: parse_udf;
        }
    }

    state extract_outer_gtp_u {
        pkt.extract(hdr.outer.gtp_v1_base);
        ig_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_GTPU;
        ig_md.lkp_1.tunnel_id = hdr.outer.gtp_v1_base.teid;
#ifdef INGRESS_PARSER_INNER_TUNNEL_INFO_OVERLOAD
        ig_md.lkp_2.tunnel_type = SWITCH_TUNNEL_TYPE_GTPU;
        ig_md.lkp_2.tunnel_id = hdr.outer.gtp_v1_base.teid;
#endif // INGRESS_PARSER_INNER_TUNNEL_INFO_OVERLOAD   
        transition select(pkt.lookahead<bit<4>>()) {
            4: parse_inner_ipv4;
            6: parse_inner_ipv6;
            default: parse_udf;
        }
    }

    state extract_outer_gtp_u_with_optional {
        pkt.extract(hdr.outer.gtp_v1_base);
        pkt.extract(hdr.outer.gtp_v1_optional);
        ig_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_GTPU;
        ig_md.lkp_1.tunnel_id = hdr.outer.gtp_v1_base.teid;
#ifdef INGRESS_PARSER_INNER_TUNNEL_INFO_OVERLOAD
        ig_md.lkp_2.tunnel_type = SWITCH_TUNNEL_TYPE_GTPU;
        ig_md.lkp_2.tunnel_id = hdr.outer.gtp_v1_base.teid;
#endif // INGRESS_PARSER_INNER_TUNNEL_INFO_OVERLOAD   
        transition select(
            hdr.outer.gtp_v1_base.E,
            pkt.lookahead<bit<4>>()) {
            (0, 4): parse_inner_ipv4;
            (0, 6): parse_inner_ipv6;
            default: parse_udf;
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
        
#ifdef INGRESS_PARSER_POPULATES_LKP_2
        ig_md.lkp_2.mac_src_addr = hdr.inner.ethernet.src_addr;
        ig_md.lkp_2.mac_dst_addr = hdr.inner.ethernet.dst_addr;
        ig_md.lkp_2.mac_type     = hdr.inner.ethernet.ether_type;
        ig_md.lkp_2.pcp = 0;
        ig_md.lkp_2.vid = 0;
#endif // INGRESS_PARSER_POPULATES_LKP_2
        
        transition select(hdr.inner.ethernet.ether_type) {
            ETHERTYPE_ARP:  parse_inner_arp;
            ETHERTYPE_VLAN: parse_inner_vlan;
            ETHERTYPE_IPV4: parse_inner_ipv4;
            ETHERTYPE_IPV6: parse_inner_ipv6;
            default : parse_udf;
        }
    }

    state parse_inner_vlan {

        pkt.extract(hdr.inner.vlan_tag[0]);

#ifndef SF_0_L2_VLAN_ID_ENABLE
        ig_md.lkp_2.tunnel_type = SWITCH_TUNNEL_TYPE_VLAN;
#endif // SF_0_L2_VLAN_ID_ENABLE
        
#ifdef INGRESS_PARSER_POPULATES_LKP_2
        ig_md.lkp_2.pcp = hdr.inner.vlan_tag[0].pcp;
  #ifdef SF_0_L2_VLAN_ID_ENABLE
        ig_md.lkp_2.vid = hdr.inner.vlan_tag[0].vid;
  #endif // SF_0_L2_VLAN_ID_ENABLE
        ig_md.lkp_2.mac_type = hdr.inner.vlan_tag[0].ether_type;
#endif // INGRESS_PARSER_POPULATES_LKP_2        

        transition select(hdr.inner.vlan_tag[0].ether_type) {
            ETHERTYPE_ARP:  parse_inner_arp;
            ETHERTYPE_IPV4: parse_inner_ipv4;
            ETHERTYPE_IPV6: parse_inner_ipv6;
            default : parse_udf;
        }
    }

    
    ///////////////////////////////////////////////////////////////////////////
    // Layer 2.5 - Inner
    ///////////////////////////////////////////////////////////////////////////

    state parse_inner_arp {
        // pkt.extract(hdr.inner.arp);
        // transition accept;
        transition parse_udf;
    }


    ///////////////////////////////////////////////////////////////////////////
    // Layer 3 - Inner
    ///////////////////////////////////////////////////////////////////////////

//     state parse_inner_ipv4 {
//         pkt.extract(hdr.inner.ipv4);
//         protocol_inner = hdr.inner.ipv4.protocol;
// 
// #ifdef INGRESS_PARSER_POPULATES_LKP_2
//         // todo: should the lkp struct be set in state parse_outer_ipv4_no_options_frags instead?
// 
//         // fixup ethertype for ip-n-ip case
//         ig_md.lkp_2.mac_type      = ETHERTYPE_IPV4;
// 
//         ig_md.lkp_2.ip_type       = SWITCH_IP_TYPE_IPV4;
//         ig_md.lkp_2.ip_proto      = hdr.inner.ipv4.protocol;
//         ig_md.lkp_2.ip_tos        = hdr.inner.ipv4.tos; // not byte-aligned so set in mau
//         ig_md.lkp_2.ip_flags      = hdr.inner.ipv4.flags;
//         ig_md.lkp_2.ip_src_addr   = (bit<128>)hdr.inner.ipv4.src_addr;
//         ig_md.lkp_2.ip_dst_addr   = (bit<128>)hdr.inner.ipv4.dst_addr;
//         ig_md.lkp_2.ip_len        = hdr.inner.ipv4.total_len;
// #endif // INGRESS_PARSER_POPULATES_LKP_2        
//         
//         // Flag packet (to be sent to host) if it's a frag or has options.
//         ipv4_checksum_inner.add(hdr.inner.ipv4);
//         transition select(
//             hdr.inner.ipv4.ihl,
//             hdr.inner.ipv4.frag_offset) {
//             (5, 0): parse_inner_ipv4_no_options_frags;
//             default: parse_udf;
//         }
//     }
// 
//     state parse_inner_ipv4_no_options_frags {
//         ig_md.flags.ipv4_checksum_err_2 = ipv4_checksum_inner.verify();
//         transition select(hdr.inner.ipv4.protocol) {
//             IP_PROTOCOLS_ICMP: parse_inner_icmp_igmp_overload;
//             IP_PROTOCOLS_IGMP: parse_inner_icmp_igmp_overload;
//             default: branch_inner_l3_protocol;
//         }
//     }

    state parse_inner_ipv4 {
        pkt.extract(hdr.inner.ipv4);

#ifdef INGRESS_PARSER_POPULATES_LKP_2
        // todo: should the lkp struct be set in state parse_outer_ipv4_no_options_frags instead?

        // fixup ethertype for ip-n-ip case
        ig_md.lkp_2.mac_type      = ETHERTYPE_IPV4;

        ig_md.lkp_2.ip_type       = SWITCH_IP_TYPE_IPV4;
        ig_md.lkp_2.ip_proto      = hdr.inner.ipv4.protocol;
        ig_md.lkp_2.ip_tos        = hdr.inner.ipv4.tos; // not byte-aligned so set in mau
        ig_md.lkp_2.ip_flags      = hdr.inner.ipv4.flags;
        ig_md.lkp_2.ip_src_addr   = (bit<128>)hdr.inner.ipv4.src_addr;
        ig_md.lkp_2.ip_dst_addr   = (bit<128>)hdr.inner.ipv4.dst_addr;
        ig_md.lkp_2.ip_len        = hdr.inner.ipv4.total_len;
#endif // INGRESS_PARSER_POPULATES_LKP_2        
        
        // Flag packet (to be sent to host) if it's a frag or has options.
        ipv4_checksum_inner.add(hdr.inner.ipv4);
        transition select(
            hdr.inner.ipv4.ihl,
            hdr.inner.ipv4.frag_offset) {
            (5, 0): parse_inner_ipv4_no_options_frags;
            default: parse_udf;
        }
    }

    state parse_inner_ipv4_no_options_frags {
        ig_md.flags.ipv4_checksum_err_2 = ipv4_checksum_inner.verify();
        transition select(hdr.inner.ipv4.protocol) {
            IP_PROTOCOLS_ICMP: parse_inner_icmp_igmp_overload;
            IP_PROTOCOLS_IGMP: parse_inner_icmp_igmp_overload;
            IP_PROTOCOLS_UDP: parse_inner_udp;
            IP_PROTOCOLS_TCP: parse_inner_tcp;
            IP_PROTOCOLS_SCTP: parse_inner_sctp;
#ifdef INNER_GRE_ENABLE
            IP_PROTOCOLS_GRE: parse_inner_gre;
#endif // INNER_GRE_ENABLE
            IP_PROTOCOLS_ESP: parse_inner_esp_overload;
            IP_PROTOCOLS_IPV4: parse_inner_ipinip_set_tunnel_type;
            IP_PROTOCOLS_IPV6: parse_inner_ipv6inip_set_tunnel_type;
            default : parse_udf;
        }
    }

    
//     state parse_inner_ipv6 {
// #ifdef IPV6_ENABLE
//         pkt.extract(hdr.inner.ipv6);
//         protocol_inner = hdr.inner.ipv6.next_hdr;
// 
// #ifdef INGRESS_PARSER_POPULATES_LKP_2
//         
//         // fixup ethertype for ip-n-ip case
//         ig_md.lkp_2.mac_type      = ETHERTYPE_IPV6;
//         
//         ig_md.lkp_2.ip_type       = SWITCH_IP_TYPE_IPV6;
//         ig_md.lkp_2.ip_proto      = hdr.inner.ipv6.next_hdr;
//         //ig_md.lkp_2.ip_tos        = hdr.inner.ipv6.tos; // not byte-aligned so set in mau
//         ig_md.lkp_2.ip_src_addr   = hdr.inner.ipv6.src_addr;
//         ig_md.lkp_2.ip_dst_addr   = hdr.inner.ipv6.dst_addr;
//         ig_md.lkp_2.ip_len        = hdr.inner.ipv6.payload_len;
// #endif // INGRESS_PARSER_POPULATES_LKP_2        
// 
//         transition select(hdr.inner.ipv6.next_hdr) {
//             IP_PROTOCOLS_ICMPV6: parse_inner_icmp_igmp_overload;
//             default: branch_inner_l3_protocol;
//         }
// #else
//         transition reject;
// #endif
//     }

    state parse_inner_ipv6 {
#ifdef IPV6_ENABLE
        pkt.extract(hdr.inner.ipv6);

#ifdef INGRESS_PARSER_POPULATES_LKP_2
        // fixup ethertype for ip-n-ip case
        ig_md.lkp_2.mac_type      = ETHERTYPE_IPV6;
        
        ig_md.lkp_2.ip_type       = SWITCH_IP_TYPE_IPV6;
        ig_md.lkp_2.ip_proto      = hdr.inner.ipv6.next_hdr;
        //ig_md.lkp_2.ip_tos        = hdr.inner.ipv6.tos; // not byte-aligned so set in mau
        ig_md.lkp_2.ip_src_addr   = hdr.inner.ipv6.src_addr;
        ig_md.lkp_2.ip_dst_addr   = hdr.inner.ipv6.dst_addr;
        ig_md.lkp_2.ip_len        = hdr.inner.ipv6.payload_len;
#endif // INGRESS_PARSER_POPULATES_LKP_2        

        transition select(hdr.inner.ipv6.next_hdr) {
            IP_PROTOCOLS_ICMPV6: parse_inner_icmp_igmp_overload;
            IP_PROTOCOLS_UDP: parse_inner_udp;
            IP_PROTOCOLS_TCP: parse_inner_tcp;
            IP_PROTOCOLS_SCTP: parse_inner_sctp;
#ifdef INNER_GRE_ENABLE
            IP_PROTOCOLS_GRE: parse_inner_gre;
#endif // INNER_GRE_ENABLE
            IP_PROTOCOLS_ESP: parse_inner_esp_overload;
            IP_PROTOCOLS_IPV4: parse_inner_ipinip_set_tunnel_type;
            IP_PROTOCOLS_IPV6: parse_inner_ipv6inip_set_tunnel_type;
            default : parse_udf;
        }
#else
        transition reject;
#endif
    }

    
//     // shared fanout/branch state to save tcam resource
//     state branch_inner_l3_protocol {
//         transition select(protocol_inner) {
//             IP_PROTOCOLS_UDP: parse_inner_udp;
//             IP_PROTOCOLS_TCP: parse_inner_tcp;
//             IP_PROTOCOLS_SCTP: parse_inner_sctp;
// #ifdef INNER_GRE_ENABLE
//             IP_PROTOCOLS_GRE: parse_inner_gre;
// #endif // INNER_GRE_ENABLE
//             IP_PROTOCOLS_ESP: parse_inner_esp_overload;
//             IP_PROTOCOLS_IPV4: parse_inner_ipinip_set_tunnel_type;
//             IP_PROTOCOLS_IPV6: parse_inner_ipv6inip_set_tunnel_type;
//             default : parse_udf;
//        }
//     }    

    // For ICMP and IGMP, we're not actually extracting the header;
    // We're simply over-loading L4-port info for policy via lookahead.     
    state parse_inner_icmp_igmp_overload {
#if defined(PARSER_L4_PORT_OVERLOAD) && defined(INGRESS_PARSER_POPULATES_LKP_2)
        ig_md.lkp_2.l4_src_port = pkt.lookahead<bit<16>>();
#endif
        transition parse_udf;
    }


    ///////////////////////////////////////////////////////////////////////////
    // Inner Layer 4 - Inner
    ///////////////////////////////////////////////////////////////////////////

    state parse_inner_udp {
        pkt.extract(hdr.inner.udp);
#ifdef INGRESS_PARSER_POPULATES_LKP_2
        ig_md.lkp_2.l4_src_port = hdr.inner.udp.src_port;
        ig_md.lkp_2.l4_dst_port = hdr.inner.udp.dst_port;
#endif // INGRESS_PARSER_POPULATES_LKP_2        
        transition select(hdr.inner.udp.src_port, hdr.inner.udp.dst_port) {
#ifdef INNER_GTP_ENABLE
            (_, UDP_PORT_GTP_C): parse_inner_gtp_c;
            (UDP_PORT_GTP_C, _): parse_inner_gtp_c;
            (_, UDP_PORT_GTP_U): parse_inner_gtp_u;
            (UDP_PORT_GTP_U, _): parse_inner_gtp_u;
            // (UDP_PORT_GTP_C, UDP_PORT_GTP_C): parse_inner_gtp_c;
            // (UDP_PORT_GTP_U, UDP_PORT_GTP_U): parse_inner_gtp_u;            
#endif // INNER_GTP_ENABLE
            default: parse_udf;
        }
    }

    state parse_inner_tcp {
        pkt.extract(hdr.inner.tcp);
#ifdef INGRESS_PARSER_POPULATES_LKP_2
        ig_md.lkp_2.l4_src_port = hdr.inner.tcp.src_port;
        ig_md.lkp_2.l4_dst_port = hdr.inner.tcp.dst_port;
        ig_md.lkp_2.tcp_flags   = hdr.inner.tcp.flags;        
#endif // INGRESS_PARSER_POPULATES_LKP_2
        transition parse_udf;
    }

    state parse_inner_sctp {
        pkt.extract(hdr.inner.sctp);
#ifdef INGRESS_PARSER_POPULATES_LKP_2
        ig_md.lkp_2.l4_src_port = hdr.inner.sctp.src_port;
        ig_md.lkp_2.l4_dst_port = hdr.inner.sctp.dst_port;
#endif // INGRESS_PARSER_POPULATES_LKP_2
        transition parse_udf;
    }    


    ///////////////////////////////////////////////////////////////////////////
    // Tunnels - Inner
    ///////////////////////////////////////////////////////////////////////////


    //-------------------------------------------------------------------------
    // Internet Protocol (IP) - Inner
    //-------------------------------------------------------------------------

    state parse_inner_ipinip_set_tunnel_type {
#ifdef IPINIP
        ig_md.lkp_2.tunnel_type = SWITCH_TUNNEL_TYPE_IPINIP;
        ig_md.lkp_2.tunnel_id = 0;
        transition parse_inner_inner_ipv4;
#else
        transition parse_udf;
#endif /* IPINIP */
    }

    state parse_inner_ipv6inip_set_tunnel_type {
#ifdef IPINIP
        ig_md.lkp_2.tunnel_type = SWITCH_TUNNEL_TYPE_IPINIP;
        ig_md.lkp_2.tunnel_id = 0;
        transition parse_inner_inner_ipv6;
#else
        transition parse_udf;
#endif /* IPINIP */
    }


    //-------------------------------------------------------------------------
    // Encapsulating Security Payload (ESP) - Inner
    //-------------------------------------------------------------------------
    
    state parse_inner_esp_overload {
#if defined(PARSER_L4_PORT_OVERLOAD) && defined(INGRESS_PARSER_POPULATES_LKP_2)
        ig_md.lkp_2.l4_src_port = pkt.lookahead<esp_h>().spi_hi;
        ig_md.lkp_2.l4_dst_port = pkt.lookahead<esp_h>().spi_lo;
#endif
        transition parse_udf;
    }    


    //-------------------------------------------------------------------------
    // Generic Routing Encapsulation (GRE) - Inner
    //-------------------------------------------------------------------------
    
#ifdef INNER_GRE_ENABLE

    state parse_inner_gre {    
        pkt.extract(hdr.inner.gre);
        ig_md.lkp_2.tunnel_type = SWITCH_TUNNEL_TYPE_GRE;
        ig_md.lkp_2.tunnel_id = 0;
        
        transition select(
            hdr.inner.gre.C,
            hdr.inner.gre.R,
            hdr.inner.gre.K,
            hdr.inner.gre.S,
            hdr.inner.gre.s,
            hdr.inner.gre.recurse,
            hdr.inner.gre.flags,
            hdr.inner.gre.version,
            hdr.inner.gre.proto) {

          // C R K S s r f v
            (0,0,0,0,0,0,0,0,ETHERTYPE_IPV4): parse_inner_inner_ipv4;
            (0,0,0,0,0,0,0,0,ETHERTYPE_IPV6): parse_inner_inner_ipv6;
            (1,0,0,0,0,0,0,0,_             ): parse_inner_gre_optional;
            (0,0,1,0,0,0,0,0,_             ): parse_inner_gre_optional;
            (0,0,0,1,0,0,0,0,_             ): parse_inner_gre_optional;                
            default: parse_udf;
        }
    }

    state parse_inner_gre_optional {    
        pkt.extract(hdr.inner.gre_optional);
        transition select(hdr.inner.gre.proto) {
            ETHERTYPE_IPV4: parse_inner_inner_ipv4;
            ETHERTYPE_IPV6: parse_inner_inner_ipv6;                        
            default: parse_udf;
        }
    }
   
#endif // INNER_GRE_ENABLE


#ifdef INNER_GTP_ENABLE
    
    //-------------------------------------------------------------------------
    // GPRS (General Packet Radio Service) Tunneling Protocol (GTP) - Outer
    //-------------------------------------------------------------------------
    // Based on pseudo code from Glenn (see email from 03/11/2019):

    // GTP-C
    //-------------------------------------------------------------------------
    // For GTP-C, we're not actually extracting the header;
    // We're simply grabbing TEID for policy via lookahead, then dumping to UDF
    
    state parse_inner_gtp_c {
        //gtp_v2_base_h snoop_inner_gtp_v2_base = pkt.lookahead<gtp_v2_base_h>();
        //transition select(
        //    snoop_inner_gtp_v2_base.version,
        //    snoop_inner_gtp_v2_base.T) {

        transition select(
            pkt.lookahead<gtp_v2_base_h>().version,
            pkt.lookahead<gtp_v2_base_h>().T
        ) {
            (2, 1): extract_inner_gtp_c;
            default: parse_udf;
        }
    }

    state extract_inner_gtp_c {
        //pkt.extract(hdr.inner.gtp_v2_base);
        //ig_md.lkp_2.tunnel_type = SWITCH_TUNNEL_TYPE_GTPC;
        //ig_md.lkp_2.tunnel_id = hdr.inner.gtp_v2_base.teid;

        ig_md.lkp_2.tunnel_type = SWITCH_TUNNEL_TYPE_GTPC;
        ig_md.lkp_2.tunnel_id = pkt.lookahead<gtp_v2_base_h>().teid;
        transition parse_udf;
    }

    // GTP-U
    //-------------------------------------------------------------------------
    // Only supports optional header for sequence-number
    // Does not support parsing (TLV) extension headers

    state parse_inner_gtp_u {
        gtp_v1_base_h snoop_inner_gtp_v1_base = pkt.lookahead<gtp_v1_base_h>();
        transition select(
            snoop_inner_gtp_v1_base.version,
            snoop_inner_gtp_v1_base.PT,
            snoop_inner_gtp_v1_base.E,
            snoop_inner_gtp_v1_base.S,
            snoop_inner_gtp_v1_base.PN) {

            (1, 1, 0, 0, 0): extract_inner_gtp_u;
            (1, 1, 0, 1, 0): extract_inner_gtp_u_with_optional;
            default: parse_udf;
        }
    }

    state extract_inner_gtp_u {
        pkt.extract(hdr.inner.gtp_v1_base);
        ig_md.lkp_2.tunnel_type = SWITCH_TUNNEL_TYPE_GTPU;
        ig_md.lkp_2.tunnel_id = hdr.inner.gtp_v1_base.teid;
        transition select(pkt.lookahead<bit<4>>()) {
            4: parse_inner_inner_ipv4;
            6: parse_inner_inner_ipv6;
            default: parse_udf;
        }
    }

    state extract_inner_gtp_u_with_optional {
        pkt.extract(hdr.inner.gtp_v1_base);
        pkt.extract(hdr.inner.gtp_v1_optional);
        ig_md.lkp_2.tunnel_type = SWITCH_TUNNEL_TYPE_GTPU;
        ig_md.lkp_2.tunnel_id = hdr.inner.gtp_v1_base.teid;
        transition select(
            hdr.inner.gtp_v1_base.E,
            pkt.lookahead<bit<4>>()) {
            (0, 4): parse_inner_inner_ipv4;
            (0, 6): parse_inner_inner_ipv6;
            default: parse_udf;
        }
    }    
    
#endif // INNER_GTP_ENABLE


    
    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////
    // "Inner Inner" Headers / Stack
    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////

    state parse_inner_inner_ipv4 {
		hdr.inner_inner.ipv4.setValid();
//      ig_md.inner_inner.ipv4_isValid = true;
		transition parse_udf;
    }
    state parse_inner_inner_ipv6 {
		hdr.inner_inner.ipv6.setValid();
//      ig_md.inner_inner.ipv6_isValid = true;
		transition parse_udf;
    }
    
    
    ///////////////////////////////////////////////////////////////////////////
    // UDF
    ///////////////////////////////////////////////////////////////////////////

    state parse_udf {
#ifdef UDF_ENABLE
        ig_md.flags.parse_udf_reached = true;
#endif  /* UDF_ENABLE */
        transition extract_udf;
    }

    @dontmerge ("ingress")
    state extract_udf {
#ifdef UDF_ENABLE
        pkt.extract(hdr.udf);
#endif  /* UDF_ENABLE */
        transition accept;
    }
        
}

#endif /* _NPB_ING_PARSER_ */

