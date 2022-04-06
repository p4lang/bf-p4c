// Copyright 2020-2021 Extreme Networks, Inc.
// All rights reserved.

#ifndef _NPB_EGR_PARSER_
#define _NPB_EGR_PARSER_

parser EgressParser(
    packet_in pkt,
    out switch_header_t hdr,
    out switch_egress_metadata_t eg_md,
    out egress_intrinsic_metadata_t eg_intr_md
) ( // constructor parameters
    MODULE_DEPLOYMENT_PARAMS
) {

    bit<8> scope;
    bool   l2_fwd_en;
    bool   transport_valid;

	bit<8>  protocol_outer;
	bit<8>  protocol_inner;

    
    state start {
        pkt.extract(eg_intr_md);
//      eg_md.pkt_length = eg_intr_md.pkt_length;
        eg_md.payload_len = eg_intr_md.pkt_length; // initially populate with pkt length...we will fix later
        eg_md.port = eg_intr_md.egress_port;
		eg_md.qos.qdepth = eg_intr_md.deq_qdepth;

#ifdef PA_NO_INIT
        eg_md.tunnel_0.terminate = false;
        eg_md.tunnel_1.terminate = false;
        eg_md.tunnel_2.terminate = false;
#endif

#if defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
        // initialize lookup struct to zeros
/*
        eg_md.lkp_1.mac_src_addr = 0;
        eg_md.lkp_1.mac_dst_addr = 0;
        eg_md.lkp_1.mac_type = 0;
        eg_md.lkp_1.pcp = 0;
        eg_md.lkp_1.pad = 0;
        eg_md.lkp_1.vid = 0;
        eg_md.lkp_1.ip_type = SWITCH_IP_TYPE_NONE;
        eg_md.lkp_1.ip_proto = 0;
        eg_md.lkp_1.ip_tos = 0;
        eg_md.lkp_1.ip_flags = 0;
        eg_md.lkp_1.ip_src_addr = 0;
        eg_md.lkp_1.ip_dst_addr = 0;
        eg_md.lkp_1.ip_len = 0;
        eg_md.lkp_1.tcp_flags = 0;
        eg_md.lkp_1.l4_src_port = 0;
        eg_md.lkp_1.l4_dst_port = 0;
        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_NONE;
        eg_md.lkp_1.tunnel_id = 0;
        eg_md.lkp_1.tunnel_outer_type = SWITCH_TUNNEL_TYPE_NONE; // note: outer here means "current scope - 2"
        eg_md.lkp_1.tunnel_inner_type = SWITCH_TUNNEL_TYPE_NONE; // note: inner here means "current scope - 1"
*/
#endif // defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
        
#ifdef MIRROR_INGRESS_ENABLE
        switch_cpu_mirror_ingress_metadata_h mirror_md = pkt.lookahead<switch_cpu_mirror_ingress_metadata_h>();
        transition select(eg_intr_md.deflection_flag, mirror_md.src, mirror_md.type) {
            (1, _,                             _                                   ) : parse_deflected_pkt;
            (_, SWITCH_PKT_SRC_BRIDGED,        _                                   ) : parse_bridged_pkt;
//          (_, _,                             SWITCH_MIRROR_TYPE_PORT             ) : parse_port_mirrored_metadata;
/*
            (_, SWITCH_PKT_SRC_CLONED_INGRESS, SWITCH_MIRROR_TYPE_PORT             ) : parse_ig_port_mirrored_metadata; // derek added
            (_, SWITCH_PKT_SRC_CLONED_EGRESS,  SWITCH_MIRROR_TYPE_PORT             ) : parse_eg_port_mirrored_metadata; // derek added
            (_, SWITCH_PKT_SRC_CLONED_INGRESS, SWITCH_MIRROR_TYPE_CPU              ) : parse_ig_cpu_mirrored_metadata; // derek added
            (_, SWITCH_PKT_SRC_CLONED_EGRESS,  SWITCH_MIRROR_TYPE_CPU              ) : parse_eg_cpu_mirrored_metadata; // derek added
*/
            (_, SWITCH_PKT_SRC_CLONED_INGRESS, SWITCH_MIRROR_TYPE_CPU              ) : parse_ig_cpu_mirrored_metadata; // derek added
            (_, _,                             SWITCH_MIRROR_TYPE_CPU              ) : parse_eg_cpu_mirrored_metadata; // derek added
            (_, SWITCH_PKT_SRC_CLONED_INGRESS, SWITCH_MIRROR_TYPE_DTEL_DROP        ) : parse_dtel_drop_metadata_from_ingress;
            (_, _,                             SWITCH_MIRROR_TYPE_DTEL_DROP        ) : parse_dtel_drop_metadata_from_egress;
            (_, _,                             SWITCH_MIRROR_TYPE_DTEL_SWITCH_LOCAL) : parse_dtel_switch_local_metadata;
            (_, _,                             SWITCH_MIRROR_TYPE_SIMPLE           ) : parse_simple_mirrored_metadata;
        }
#else
        transition parse_bridged_pkt;
#endif
    }

    state parse_bridged_pkt {
		pkt.extract(hdr.bridged_md);
        eg_md.pkt_src = SWITCH_PKT_SRC_BRIDGED;

		// ---- extract base bridged metadata -----
        eg_md.ingress_port         = hdr.bridged_md.base.ingress_port;
#ifdef CPU_HDR_CONTAINS_EG_PORT
#else
        eg_md.port_lag_index       = hdr.bridged_md.base.ingress_port_lag_index;
#endif
//      eg_md.bd                   = hdr.bridged_md.base.ingress_bd;
        eg_md.nexthop              = hdr.bridged_md.base.nexthop;
//      eg_md.pkt_type             = hdr.bridged_md.base.pkt_type;
		eg_md.flags.bypass_egress  = hdr.bridged_md.base.bypass_egress;
        eg_md.cpu_reason           = hdr.bridged_md.base.cpu_reason;
        eg_md.ingress_timestamp    = hdr.bridged_md.base.timestamp;
		eg_md.qos.qid              = hdr.bridged_md.base.qid;

		eg_md.hash                 = hdr.bridged_md.base.hash;
#ifdef TUNNEL_ENABLE
        eg_md.tunnel_nexthop       = hdr.bridged_md.tunnel.tunnel_nexthop;
        eg_md.tunnel_0.dip_index   = hdr.bridged_md.tunnel.dip_index;
//      eg_md.tunnel_0.hash        = hdr.bridged_md.tunnel.hash;

//      eg_md.tunnel_0.terminate   = hdr.bridged_md.tunnel.terminate_0;
//      eg_md.tunnel_1.terminate   = hdr.bridged_md.tunnel.terminate_1;
//      eg_md.tunnel_2.terminate   = hdr.bridged_md.tunnel.terminate_2;
#endif

		// ----- extract nsh bridged metadata -----
        eg_md.flags.transport_valid= hdr.bridged_md.base.transport_valid;
		eg_md.nsh_md.end_of_path   = hdr.bridged_md.base.nsh_md_end_of_path;
		eg_md.nsh_md.l2_fwd_en     = hdr.bridged_md.base.nsh_md_l2_fwd_en;
		eg_md.nsh_md.dedup_en      = hdr.bridged_md.base.nsh_md_dedup_en;

//      eg_md.dtel.report_type     = hdr.bridged_md.dtel.report_type;
//      eg_md.dtel.hash            = hdr.bridged_md.dtel.hash;
        eg_md.dtel.hash            = hdr.bridged_md.base.hash[31:0]; // derek hack
//      eg_md.dtel.session_id      = hdr.bridged_md.dtel.session_id;

        // -----------------------------
        // packet will always have NSH present

        //  L2   My   MAU                   First   
        //  Fwd  MAC  Path                  Stack
        //  ----------------------------    ------------
        //  0    0    SFC Optical-Tap       Outer       
        //  0    1    SFC Optical-Tap       Outer       
        //  1    0    Bridging              Outer       
        //  1    1    SFC Network-Tap       Transport   
        //            or SFC Bypass (nsh)   Transport

        transition select(
            (bit<1>)hdr.bridged_md.base.nsh_md_l2_fwd_en,
            (bit<1>)hdr.bridged_md.base.transport_valid) {

            (1, 0):  parse_outer_ethernet_scope0; // SFC Optical-Tap / Bridging Path
//          default: parse_transport_ethernet;    // SFC Network-Tap / SFC Bypass Path
            default: parse_transport_nsh;         // SFC Network-Tap / SFC Bypass Path
        }               

    }
/*
    state parse_ig_port_mirrored_metadata {
        switch_port_mirror_ingress_metadata_h port_md;
        pkt.extract(port_md);
        pkt.extract(hdr.outer.ethernet);
        eg_md.pkt_src = port_md.src;                          // for cpu header
        eg_md.bd = port_md.bd;                                // for cpu header (derek added)
		eg_md.ingress_port = port_md.port;                    // for cpu header (derek added)
#ifdef CPU_HDR_CONTAINS_EG_PORT
        eg_md.port = port_md.eg_port;                         // for cpu header (derek added)
#else
        eg_md.port_lag_index = port_md.port_lag_index;        // for cpu header (derek added)
#endif
//		eg_md.cpu_reason = SWITCH_CPU_REASON_IG_PORT_MIRROR;  // for cpu header (derek added)
		eg_md.cpu_reason = port_md.reason_code;               // for cpu header
//      eg_md.mirror.session_id = port_md.session_id;         // for ??? header
////    eg_md.ingress_timestamp = port_md.timestamp;          // for ??? header
		eg_md.flags.bypass_egress = true;
#ifdef PACKET_LENGTH_ADJUSTMENT
        eg_md.mirror.type = port_md.type;
#endif
#ifdef DTEL_ENABLE
        // Initialize eg_md.dtel.session_id to prevent it from being marked @pa_no_init.
        eg_md.dtel.session_id = 0;
#endif
        eg_md.qos.qid = port_md.qos_qid;
        eg_md.qos.qdepth = port_md.qos_qdepth;
        transition accept;
    }
*/
/*
    state parse_eg_port_mirrored_metadata {
        switch_port_mirror_egress_metadata_h port_md;
        pkt.extract(port_md);
        pkt.extract(hdr.outer.ethernet);
        eg_md.pkt_src = port_md.src;                          // for cpu header
        eg_md.bd = port_md.bd;                                // for cpu header (derek added)
		eg_md.ingress_port = port_md.port;                    // for cpu header (derek added)
#ifdef CPU_HDR_CONTAINS_EG_PORT
        eg_md.port = port_md.eg_port;                         // for cpu header (derek added)
#else
        eg_md.port_lag_index = port_md.port_lag_index;        // for cpu header (derek added)
#endif
//		eg_md.cpu_reason = SWITCH_CPU_REASON_EG_PORT_MIRROR;  // for cpu header (derek added)
		eg_md.cpu_reason = port_md.reason_code;               // for cpu header
//      eg_md.mirror.session_id = port_md.session_id;         // for ??? header
////    eg_md.ingress_timestamp = port_md.timestamp;          // for ??? header
		eg_md.flags.bypass_egress = true;
#ifdef PACKET_LENGTH_ADJUSTMENT
        eg_md.mirror.type = port_md.type;
#endif
#ifdef DTEL_ENABLE
        // Initialize eg_md.dtel.session_id to prevent it from being marked @pa_no_init.
        eg_md.dtel.session_id = 0;
#endif
        eg_md.qos.qid = port_md.qos_qid;
        eg_md.qos.qdepth = port_md.qos_qdepth;
        transition accept;
    }
*/
    state parse_ig_cpu_mirrored_metadata {
        switch_cpu_mirror_ingress_metadata_h cpu_md;
        pkt.extract(cpu_md);
        pkt.extract(hdr.outer.ethernet);
        eg_md.pkt_src = cpu_md.src;                           // for cpu header
		eg_md.flags.bypass_egress = true;
        eg_md.bd = cpu_md.bd;                                 // for cpu header
        eg_md.ingress_port = cpu_md.port;                     // for cpu header
#ifdef CPU_HDR_CONTAINS_EG_PORT
        eg_md.port = cpu_md.eg_port;                          // for cpu header (derek added)
#else
        eg_md.port_lag_index = cpu_md.port_lag_index;         // for cpu header (derek added)
#endif
        eg_md.ingress_timestamp = cpu_md.timestamp;           // for ??? header
        eg_md.cpu_reason = cpu_md.reason_code;                // for cpu header
#ifdef PACKET_LENGTH_ADJUSTMENT
        eg_md.mirror.type = cpu_md.type;
#endif
#ifdef DTEL_ENABLE
        // Initialize eg_md.dtel.session_id to prevent it from being marked @pa_no_init.
        eg_md.dtel.session_id = 0;
#endif
/*
        eg_md.qos.qid = cpu_md.qos_qid;
        eg_md.qos.qdepth = cpu_md.qos_qdepth;
*/
        transition accept;
    }

    state parse_eg_cpu_mirrored_metadata {
        switch_cpu_mirror_egress_metadata_h cpu_md;
        pkt.extract(cpu_md);
        pkt.extract(hdr.outer.ethernet);
        eg_md.pkt_src = cpu_md.src;                           // for cpu header
		eg_md.flags.bypass_egress = true;
        eg_md.bd = cpu_md.bd;                                 // for cpu header
        eg_md.ingress_port = cpu_md.port;                     // for cpu header
#ifdef CPU_HDR_CONTAINS_EG_PORT
        eg_md.port = cpu_md.eg_port;                          // for cpu header (derek added)
#else
        eg_md.port_lag_index = cpu_md.port_lag_index;         // for cpu header (derek added)
#endif
        eg_md.ingress_timestamp = cpu_md.timestamp;           // for ??? header
        eg_md.cpu_reason = cpu_md.reason_code;                // for cpu header
#ifdef PACKET_LENGTH_ADJUSTMENT
        eg_md.mirror.type = cpu_md.type;
#endif
#ifdef DTEL_ENABLE
        // Initialize eg_md.dtel.session_id to prevent it from being marked @pa_no_init.
        eg_md.dtel.session_id = 0;
#endif
        eg_md.qos.qid = cpu_md.qos_qid;
        eg_md.qos.qdepth = cpu_md.qos_qdepth;
        transition accept;
    }

    state parse_deflected_pkt {
#ifdef DTEL_ENABLE
        pkt.extract(hdr.bridged_md);
        eg_md.pkt_src = SWITCH_PKT_SRC_DEFLECTED;
#ifdef PACKET_LENGTH_ADJUSTMENT
        eg_md.mirror.type = SWITCH_MIRROR_TYPE_DTEL_DEFLECT;
#endif
//      eg_md.dtel.report_type = hdr.bridged_md.dtel.report_type; // derek hack
//      eg_md.dtel.hash = hdr.bridged_md.dtel.hash; 
        eg_md.dtel.hash = hdr.bridged_md.base.hash; // derek hack
        // Initialize eg_md.dtel.session_id to prevent it from being marked @pa_no_init.
        eg_md.dtel.session_id = 0;
//      eg_md.mirror.session_id = hdr.bridged_md.dtel.session_id; // derek hack
        eg_md.qos.qid = hdr.bridged_md.base.qid;
#ifdef INT_V2 
        hdr.transport.dtel_metadata_1 = {
            0,
            hdr.bridged_md.base.ingress_port,
            0,
//          hdr.bridged_md.dtel.egress_port};
        	eg_intr_md.egress_port}; // derek hack
        hdr.transport.dtel_metadata_4 = {
            0,
            hdr.bridged_md.base.timestamp};
        hdr.transport.dtel_drop_report = {
            0,
            hdr.bridged_md.base.qid,
            SWITCH_DROP_REASON_TRAFFIC_MANAGER,
            0};
#else
        eg_md.ingress_timestamp = hdr.bridged_md.base.timestamp;
        hdr.transport.dtel_report = {
            0,
            hdr.bridged_md.base.ingress_port,
            0,
//          hdr.bridged_md.dtel.egress_port,
        	eg_intr_md.egress_port, // derek hack
            0,
            hdr.bridged_md.base.qid};
        hdr.transport.dtel_drop_report = {
            SWITCH_DROP_REASON_TRAFFIC_MANAGER,
            0};
#endif /* INT_V2 */
        transition accept;
#else
        transition reject;
#endif /* DTEL_ENABLE */
    }

    state parse_dtel_drop_metadata_from_egress {
#ifdef DTEL_ENABLE
        switch_dtel_drop_mirror_metadata_h dtel_md;
        pkt.extract(dtel_md);
        eg_md.pkt_src = dtel_md.src;
        eg_md.mirror.type = dtel_md.type;
        eg_md.dtel.report_type = dtel_md.report_type;
        eg_md.dtel.hash = dtel_md.hash;
        // Initialize eg_md.dtel.session_id to prevent it from being marked @pa_no_init.
        eg_md.dtel.session_id = 0;
        eg_md.mirror.session_id = dtel_md.session_id;
#ifdef INT_V2
        hdr.transport.dtel_metadata_1 = {
            0,
            dtel_md.ingress_port,
            0,
            dtel_md.egress_port};
        hdr.transport.dtel_metadata_4 = {
            0,
            dtel_md.timestamp};
        hdr.transport.dtel_drop_report = {
            0,
            dtel_md.qid,
            dtel_md.drop_reason,
            0};
#else
        eg_md.ingress_timestamp = dtel_md.timestamp;
        hdr.transport.dtel_report = {
            0,
            dtel_md.ingress_port,
            0,
            dtel_md.egress_port,
            0,
            dtel_md.qid};
        hdr.transport.dtel_drop_report = {
            dtel_md.drop_reason,
            0};
#endif /* INT_V2 */
        transition accept;
#else
        transition reject;
#endif /* DTEL_ENABLE */
    }

    /* Separate parse state for drop metadata from ingress, in order to set
     * hdr.transport.dtel_report.egress_port to SWITCH_PORT_INVALID */
    state parse_dtel_drop_metadata_from_ingress {
#ifdef DTEL_ENABLE
        switch_dtel_drop_mirror_metadata_h dtel_md;
        pkt.extract(dtel_md);
        eg_md.pkt_src = dtel_md.src;
        eg_md.mirror.type = dtel_md.type;
        eg_md.dtel.report_type = dtel_md.report_type;
        eg_md.dtel.hash = dtel_md.hash;
        // Initialize eg_md.dtel.session_id to prevent it from being marked @pa_no_init.
        eg_md.dtel.session_id = 0;
        eg_md.mirror.session_id = dtel_md.session_id;
#ifdef INT_V2
        hdr.transport.dtel_metadata_1 = {
            0,
            dtel_md.ingress_port,
            0,
            SWITCH_PORT_INVALID};
        hdr.transport.dtel_metadata_4 = {
            0,
            dtel_md.timestamp};
        hdr.transport.dtel_drop_report = {
            0,
            dtel_md.qid,
            dtel_md.drop_reason, 
            0};
#else         
        eg_md.ingress_timestamp = dtel_md.timestamp;
        hdr.transport.dtel_report = {
            0,
            dtel_md.ingress_port,
            0,
            SWITCH_PORT_INVALID,
            0,
            dtel_md.qid};
        hdr.transport.dtel_drop_report = {
            dtel_md.drop_reason,
            0};
#endif /* INT_V2 */
        transition accept;
#else
        transition reject;
#endif /* DTEL_ENABLE */
    }

    state parse_dtel_switch_local_metadata {
#ifdef DTEL_ENABLE
        switch_dtel_switch_local_mirror_metadata_h dtel_md;
        pkt.extract(dtel_md);
        eg_md.pkt_src = dtel_md.src;
        eg_md.mirror.type = dtel_md.type;
        eg_md.dtel.report_type = dtel_md.report_type;
        eg_md.dtel.hash = dtel_md.hash;
        // Initialize eg_md.dtel.session_id to prevent it from being marked @pa_no_init.
        eg_md.dtel.session_id = 0;
        eg_md.mirror.session_id = dtel_md.session_id;
#ifdef INT_V2
        hdr.transport.dtel_metadata_1 = {
            0,
            dtel_md.ingress_port,
            0,
            dtel_md.egress_port};
        //TODO: Preserve latency as well as quantized latency
        //      and add to mirror metadata
        //hdr.transport.dtel_metadata_2 = {
        //    dtel_md.latency};
        hdr.transport.dtel_metadata_3 = {
            0,
            dtel_md.qid,
            0,
            dtel_md.qdepth};
        hdr.transport.dtel_metadata_4 = {
            0,
            dtel_md.timestamp};
        hdr.transport.dtel_metadata_5 = {
            0,
            dtel_md.egress_timestamp};
#else
        eg_md.ingress_timestamp = dtel_md.timestamp;
        hdr.transport.dtel_report = {
            0,
            dtel_md.ingress_port,
            0,
            dtel_md.egress_port,
            0,
            dtel_md.qid};
        hdr.transport.dtel_switch_local_report = {
            0,
            dtel_md.qdepth,
            dtel_md.egress_timestamp};
#endif /* INT_V2 */
        transition accept;
#else
        transition reject;
#endif /* DTEL_ENABLE */
    }

    state parse_simple_mirrored_metadata {
#ifdef DTEL_ENABLE
        switch_simple_mirror_metadata_h simple_mirror_md;
        pkt.extract(simple_mirror_md);
        eg_md.pkt_src = simple_mirror_md.src;
        eg_md.mirror.type = simple_mirror_md.type;
        eg_md.mirror.session_id = simple_mirror_md.session_id;
		eg_md.flags.bypass_egress = true;
//      transition parse_ethernet;
		transition select(
            pkt.lookahead<ethernet_h>().ether_type
        ) {
			ETHERTYPE_NSH: parse_transport_ethernet;
			default:       parse_outer_ethernet_scope0;
        }
#else
        transition reject;
#endif
    }

    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////
    // Transport Layer 2 (L2-U)
    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////

    ////////////////////////////////////////////////////////////////////////////
    // NSH
    ////////////////////////////////////////////////////////////////////////////

    state parse_transport_ethernet {
        pkt.extract(hdr.transport.ethernet);
        transition select(hdr.transport.ethernet.ether_type) {
            ETHERTYPE_VLAN: parse_transport_vlan;
            ETHERTYPE_NSH: parse_transport_nsh;
            default: accept; // should never get here
        }
    }
    state parse_transport_vlan {
        pkt.extract(hdr.transport.vlan_tag[0]);
        transition select(hdr.transport.vlan_tag[0].ether_type) {
            ETHERTYPE_NSH: parse_transport_nsh;
            default: accept; // should never get here
        }
    }
    state parse_transport_nsh {
/*
	    pkt.extract(hdr.transport.nsh_type1);
        scope = hdr.transport.nsh_type1.scope;

        transition select(scope, hdr.transport.nsh_type1.next_proto) {
            (0, NSH_PROTOCOLS_ETH): parse_outer_ethernet_scope0;

#ifdef EGRESS_PARSER_POPULATES_LKP_SCOPED
            (1, NSH_PROTOCOLS_ETH): parse_outer_ethernet_scope1;
#else
            (1, NSH_PROTOCOLS_ETH): parse_outer_ethernet_scope0;
#endif // EGRESS_PARSER_POPULATES_LKP_SCOPED
            
            default: reject;  // todo: support ipv4? ipv6?
        }
*/
	    pkt.extract(hdr.transport.nsh_type1_internal);
        scope = hdr.transport.nsh_type1_internal.scope;

		eg_md.nsh_md.ttl           = hdr.transport.nsh_type1_internal.ttl;
		eg_md.nsh_md.spi           = hdr.transport.nsh_type1_internal.spi;
		eg_md.nsh_md.si            = hdr.transport.nsh_type1_internal.si;
		eg_md.nsh_md.vpn           = hdr.transport.nsh_type1_internal.vpn;
		eg_md.nsh_md.scope         = hdr.transport.nsh_type1_internal.scope;
		eg_md.nsh_md.sap           = hdr.transport.nsh_type1_internal.sap;

        transition select(scope) {
            (1): parse_outer_ethernet_scope0;

#ifdef EGRESS_PARSER_POPULATES_LKP_SCOPED
            (2): parse_outer_ethernet_scope1;
#else
            (2): parse_outer_ethernet_scope0;
#endif // EGRESS_PARSER_POPULATES_LKP_SCOPED
            
            default: reject;  // todo: support ipv4? ipv6?
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

    // todo: Can we implement scope0/1 as single sub-parser, w/ parameters
    //--------------------------------------------------------------------------
    // Scope 0
    //--------------------------------------------------------------------------
    
    state parse_outer_ethernet_scope0 {
        pkt.extract(hdr.outer.ethernet);
#if defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || \
    defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
        eg_md.lkp_1.mac_src_addr = hdr.outer.ethernet.src_addr;
        eg_md.lkp_1.mac_dst_addr = hdr.outer.ethernet.dst_addr;
        eg_md.lkp_1.mac_type     = hdr.outer.ethernet.ether_type;
#endif
        transition select(hdr.outer.ethernet.ether_type) {
            ETHERTYPE_BR : construct_outer_br_scope0;
            ETHERTYPE_VN : construct_outer_vn_scope0;
            ETHERTYPE_VLAN : parse_outer_vlan_0_scope0;
            ETHERTYPE_QINQ : parse_outer_vlan_0_scope0;
            ETHERTYPE_MPLS : construct_outer_mpls_scope0;
            ETHERTYPE_IPV4 : parse_outer_ipv4_scope0;
            ETHERTYPE_IPV6 : construct_outer_ipv6_scope0;
            default : accept;
        }
    }

    state construct_outer_br_scope0 {
        transition select(OUTER_ETAG_ENABLE) {
            true: parse_outer_br_scope0;
            false: accept;
        }
    }

    state parse_outer_br_scope0 {
	    pkt.extract(hdr.outer.e_tag);
#if defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || \
    defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
        eg_md.lkp_1.mac_type = hdr.outer.e_tag.ether_type;        
        //eg_md.lkp_1.pcp = hdr.outer.e_tag.pcp;  // do not populate w/ e-tag
#endif
        transition select(hdr.outer.e_tag.ether_type) {
            ETHERTYPE_VLAN : parse_outer_vlan_0_scope0;
            ETHERTYPE_QINQ : parse_outer_vlan_0_scope0;
            ETHERTYPE_MPLS : construct_outer_mpls_scope0;
            ETHERTYPE_IPV4 : parse_outer_ipv4_scope0;
            ETHERTYPE_IPV6 : construct_outer_ipv6_scope0;
            default : accept;
        }
    }

    state construct_outer_vn_scope0 {
        transition select(OUTER_VNTAG_ENABLE) {
            true: parse_outer_vn_scope0;
            false: accept;
        }
    }

    state parse_outer_vn_scope0 {
	    pkt.extract(hdr.outer.vn_tag);
#if defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || \
    defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
        eg_md.lkp_1.mac_type = hdr.outer.vn_tag.ether_type;
#endif
        transition select(hdr.outer.vn_tag.ether_type) {
            ETHERTYPE_VLAN : parse_outer_vlan_0_scope0;
            ETHERTYPE_QINQ : parse_outer_vlan_0_scope0;
            ETHERTYPE_MPLS : construct_outer_mpls_scope0;
            ETHERTYPE_IPV4 : parse_outer_ipv4_scope0;
            ETHERTYPE_IPV6 : construct_outer_ipv6_scope0;
            default : accept;
        }
    }


    state parse_outer_vlan_0_scope0 {
	    pkt.extract(hdr.outer.vlan_tag[0]);

#if defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || \
    defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
        eg_md.lkp_1.pcp = hdr.outer.vlan_tag[0].pcp;
  #ifdef SF_2_L2_VLAN_ID_ENABLE
		eg_md.lkp_1.vid = hdr.outer.vlan_tag[0].vid;
  #endif
        eg_md.lkp_1.mac_type = hdr.outer.vlan_tag[0].ether_type;

  #ifndef SF_2_L2_VLAN_ID_ENABLE
        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_VLAN;
        //eg_md.lkp_1.tunnel_id[11:0] = hdr.outer.vlan_tag.last.vid;
        //eg_md.lkp_1.tunnel_id = (bit<switch_tunnel_id_width>)hdr.outer.vlan_tag.last.vid;
  #endif
#endif
        transition select(hdr.outer.vlan_tag[0].ether_type) {
            ETHERTYPE_VLAN : parse_outer_vlan_1_scope0;
            ETHERTYPE_MPLS : construct_outer_mpls_scope0;
            ETHERTYPE_IPV4 : parse_outer_ipv4_scope0;
            ETHERTYPE_IPV6 : construct_outer_ipv6_scope0;
            default : accept;
        }
    }

    state parse_outer_vlan_1_scope0 {
	    pkt.extract(hdr.outer.vlan_tag[1]);

#if defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || \
    defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
        eg_md.lkp_1.pcp = hdr.outer.vlan_tag[1].pcp;
  #ifdef SF_2_L2_VLAN_ID_ENABLE
		eg_md.lkp_1.vid = hdr.outer.vlan_tag[1].vid;
  #endif
        eg_md.lkp_1.mac_type = hdr.outer.vlan_tag[1].ether_type;

  #ifndef SF_2_L2_VLAN_ID_ENABLE
        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_VLAN;
        //eg_md.lkp_1.tunnel_id[11:0] = hdr.outer.vlan_tag.last.vid;
        //eg_md.lkp_1.tunnel_id = (bit<switch_tunnel_id_width>)hdr.outer.vlan_tag.last.vid;
  #endif
#endif
        transition select(hdr.outer.vlan_tag[1].ether_type) {
            ETHERTYPE_VLAN : parse_outer_vlan_unsupported_scope0;
            ETHERTYPE_MPLS : construct_outer_mpls_scope0;
            ETHERTYPE_IPV4 : parse_outer_ipv4_scope0;
            ETHERTYPE_IPV6 : construct_outer_ipv6_scope0;
            default : accept;
        }
    }
    state parse_outer_vlan_unsupported_scope0 {
        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_UNSUPPORTED;
        eg_md.lkp_1.tunnel_id = 0;
        transition reject;
    }



    
    // todo: Can we implement scope0/1 as single sub-parser, w/ parameters
    //--------------------------------------------------------------------------
    // Scope 1
    //--------------------------------------------------------------------------
    
    state parse_outer_ethernet_scope1 {
        pkt.extract(hdr.outer.ethernet);

// populate for L3-tunnel case (where there's no L2 present)
#if defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || \
    defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
        eg_md.lkp_1.mac_src_addr = hdr.outer.ethernet.src_addr;
        eg_md.lkp_1.mac_dst_addr = hdr.outer.ethernet.dst_addr;
        eg_md.lkp_1.mac_type     = hdr.outer.ethernet.ether_type;
#endif
        transition select(hdr.outer.ethernet.ether_type) {
            ETHERTYPE_BR : construct_outer_br_scope1;
            ETHERTYPE_VN : construct_outer_vn_scope1;
            ETHERTYPE_VLAN : parse_outer_vlan_0_scope1;
            ETHERTYPE_QINQ : parse_outer_vlan_0_scope1;
            ETHERTYPE_MPLS : construct_outer_mpls_scope1;
            ETHERTYPE_IPV4 : parse_outer_ipv4_scope1;
            ETHERTYPE_IPV6 : construct_outer_ipv6_scope1;
            default : accept;
        }
    }

    state construct_outer_br_scope1 {
        transition select(OUTER_ETAG_ENABLE) {
            true: parse_outer_br_scope1;
            false: accept;
        }
    }

    state parse_outer_br_scope1 {
	    pkt.extract(hdr.outer.e_tag);

// populate for L3-tunnel case (where there's no L2 present)
#if defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || \
    defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
        eg_md.lkp_1.mac_type = hdr.outer.e_tag.ether_type;        
#endif  
        transition select(hdr.outer.e_tag.ether_type) {
            ETHERTYPE_VLAN : parse_outer_vlan_0_scope1;
            ETHERTYPE_QINQ : parse_outer_vlan_0_scope1;
            ETHERTYPE_MPLS : construct_outer_mpls_scope1;
            ETHERTYPE_IPV4 : parse_outer_ipv4_scope1;
            ETHERTYPE_IPV6 : construct_outer_ipv6_scope1;
            default : accept;
        }
    }


    state construct_outer_vn_scope1 {
        transition select(OUTER_VNTAG_ENABLE) {
            true: parse_outer_vn_scope1;
            false: accept;
        }
    }

    state parse_outer_vn_scope1 {
	    pkt.extract(hdr.outer.vn_tag);

// populate for L3-tunnel case (where there's no L2 present)
#if defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || \
    defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
        eg_md.lkp_1.mac_type = hdr.outer.vn_tag.ether_type;
#endif        
        transition select(hdr.outer.vn_tag.ether_type) {
            ETHERTYPE_VLAN : parse_outer_vlan_0_scope1;
            ETHERTYPE_QINQ : parse_outer_vlan_0_scope1;
            ETHERTYPE_MPLS : construct_outer_mpls_scope1;
            ETHERTYPE_IPV4 : parse_outer_ipv4_scope1;
            ETHERTYPE_IPV6 : construct_outer_ipv6_scope1;
            default : accept;
        }
    }


    state parse_outer_vlan_0_scope1 {
	    pkt.extract(hdr.outer.vlan_tag[0]);

// populate for L3-tunnel case (where there's no L2 present)
#if defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || \
    defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
        eg_md.lkp_1.pcp = hdr.outer.vlan_tag[0].pcp;
  #ifdef SF_2_L2_VLAN_ID_ENABLE
		eg_md.lkp_1.vid = hdr.outer.vlan_tag[0].vid;
  #endif
        eg_md.lkp_1.mac_type = hdr.outer.vlan_tag[0].ether_type;

  #ifndef SF_2_L2_VLAN_ID_ENABLE
        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_VLAN;
        //eg_md.lkp_1.tunnel_id[11:0] = hdr.outer.vlan_tag.last.vid;
        //eg_md.lkp_1.tunnel_id = (bit<switch_tunnel_id_width>)hdr.outer.vlan_tag.last.vid;
  #endif
#endif
        transition select(hdr.outer.vlan_tag[0].ether_type) {
            ETHERTYPE_VLAN : parse_outer_vlan_1_scope1;
            ETHERTYPE_MPLS : construct_outer_mpls_scope1;
            ETHERTYPE_IPV4 : parse_outer_ipv4_scope1;
            ETHERTYPE_IPV6 : construct_outer_ipv6_scope1;
            default : accept;
        }
    }

    state parse_outer_vlan_1_scope1 {
	    pkt.extract(hdr.outer.vlan_tag[1]);

// populate for L3-tunnel case (where there's no L2 present)
#if defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || \
    defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
        eg_md.lkp_1.pcp = hdr.outer.vlan_tag[1].pcp;
  #ifdef SF_2_L2_VLAN_ID_ENABLE
		eg_md.lkp_1.vid = hdr.outer.vlan_tag[1].vid;
  #endif
        eg_md.lkp_1.mac_type = hdr.outer.vlan_tag[1].ether_type;

  #ifndef SF_2_L2_VLAN_ID_ENABLE
        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_VLAN;
        //eg_md.lkp_1.tunnel_id[11:0] = hdr.outer.vlan_tag.last.vid;
        //eg_md.lkp_1.tunnel_id = (bit<switch_tunnel_id_width>)hdr.outer.vlan_tag.last.vid;
  #endif
#endif
        transition select(hdr.outer.vlan_tag[1].ether_type) {
            ETHERTYPE_VLAN : parse_outer_vlan_unsupported_scope1;
            ETHERTYPE_MPLS : construct_outer_mpls_scope1;
            ETHERTYPE_IPV4 : parse_outer_ipv4_scope1;
            ETHERTYPE_IPV6 : construct_outer_ipv6_scope1;
            default : accept;
        }
    }
    state parse_outer_vlan_unsupported_scope1 {
        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_UNSUPPORTED;
        eg_md.lkp_1.tunnel_id = 0;
        transition reject;
    }

    
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

    //--------------------------------------------------------------------------
    // Scope 0
    //--------------------------------------------------------------------------
    
    state parse_outer_ipv4_scope0 {
        pkt.extract(hdr.outer.ipv4);
        protocol_outer = hdr.outer.ipv4.protocol;
#if defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || \
    defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
        //eg_md.lkp_1.ip_type        = SWITCH_IP_TYPE_IPV4;
        eg_md.lkp_1.ip_proto       = hdr.outer.ipv4.protocol;
        eg_md.lkp_1.ip_tos         = hdr.outer.ipv4.tos;
        eg_md.lkp_1.ip_flags       = hdr.outer.ipv4.flags;
        eg_md.lkp_1.ip_src_addr_v4 = hdr.outer.ipv4.src_addr;
        eg_md.lkp_1.ip_dst_addr_v4 = hdr.outer.ipv4.dst_addr;
        eg_md.lkp_1.ip_len         = hdr.outer.ipv4.total_len;
#endif
        transition select(
            hdr.outer.ipv4.ihl,
            hdr.outer.ipv4.frag_offset,
            hdr.outer.ipv4.protocol) {

            //(5, 0, IP_PROTOCOLS_ICMP): parse_outer_icmp_igmp_overload_scope0;
            //(5, 0, IP_PROTOCOLS_IGMP): parse_outer_icmp_igmp_overload_scope0;
            (5, 0, _): branch_outer_l3_protocol_scope0;
            default: parse_outer_ip_unsupported_scope0;
        }
    }

    state construct_outer_ipv6_scope0 {
        transition select(OUTER_IPV6_ENABLE) {
            true: parse_outer_ipv6_scope0;
            default: reject;
        }
    }

    state parse_outer_ipv6_scope0 {
        pkt.extract(hdr.outer.ipv6);
        protocol_outer = hdr.outer.ipv6.next_hdr;
#if defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || \
    defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
        //eg_md.lkp_1.ip_type     = SWITCH_IP_TYPE_IPV6;
        eg_md.lkp_1.ip_proto    = hdr.outer.ipv6.next_hdr;
        //eg_md.lkp_1.ip_tos      = hdr.outer.ipv6.tos; // not byte-aligned - set in mau
        eg_md.lkp_1.ip_src_addr = hdr.outer.ipv6.src_addr;
        eg_md.lkp_1.ip_dst_addr = hdr.outer.ipv6.dst_addr;
        eg_md.lkp_1.ip_len      = hdr.outer.ipv6.payload_len;
#endif
        transition branch_outer_l3_protocol_scope0;
        // transition select(hdr.outer.ipv6.next_hdr) {
        //     IP_PROTOCOLS_ICMPV6: parse_outer_icmp_igmp_overload_scope0;
        //     default: branch_outer_l3_protocol_scope0;
        // }
    }

    // shared fanout/branch state to save tcam resource
    state branch_outer_l3_protocol_scope0 {
        transition select(protocol_outer) {
           IP_PROTOCOLS_IPV4: construct_outer_ipinip_set_tunnel_scope0;
           IP_PROTOCOLS_IPV6: construct_outer_ipv6inip_set_tunnel_scope0;
           IP_PROTOCOLS_UDP: parse_outer_udp_scope0;
           IP_PROTOCOLS_TCP: parse_outer_tcp_scope0;
           IP_PROTOCOLS_SCTP: parse_outer_sctp_scope0;
           IP_PROTOCOLS_GRE: construct_outer_gre_scope0;
           //IP_PROTOCOLS_ESP: parse_outer_esp_overload_scope0;
           default: accept;
       }
    }

    state parse_outer_ip_unsupported_scope0 {
        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_UNSUPPORTED;
        eg_md.lkp_1.tunnel_id = 0;
        transition reject;
    }


    //--------------------------------------------------------------------------
    // Scope 1
    //--------------------------------------------------------------------------
    
    state parse_outer_ipv4_scope1 {
        pkt.extract(hdr.outer.ipv4);
        protocol_outer = hdr.outer.ipv4.protocol;
        transition select(
            hdr.outer.ipv4.ihl,
            hdr.outer.ipv4.frag_offset) {

            (5, 0): branch_outer_l3_protocol_scope1;
            default: accept;
        }
    }    

    state construct_outer_ipv6_scope1 {
        transition select(OUTER_IPV6_ENABLE) {
            true: parse_outer_ipv6_scope1;
            default: reject;
        }
    }
    
    state parse_outer_ipv6_scope1 {
        pkt.extract(hdr.outer.ipv6);
        protocol_outer = hdr.outer.ipv6.next_hdr;
        transition branch_outer_l3_protocol_scope1;
    }
    
    // shared fanout/branch state to save tcam resource
    state branch_outer_l3_protocol_scope1 {
        transition select(protocol_outer) {
           IP_PROTOCOLS_IPV4: construct_outer_ipinip_set_tunnel_scope1;
           IP_PROTOCOLS_IPV6: construct_outer_ipv6inip_set_tunnel_scope1;
           IP_PROTOCOLS_UDP: parse_outer_udp_scope1;
           IP_PROTOCOLS_TCP: parse_outer_tcp_scope1;
           IP_PROTOCOLS_SCTP: parse_outer_sctp_scope1;
           IP_PROTOCOLS_GRE: construct_outer_gre_scope1;
           default: accept;
       }
    }
            
//     // For ICMP and IGMP, we're not actually extracting the header;
//     // We're simply over-loading L4-port info for policy via lookahead.    
//     state parse_outer_icmp_igmp_overload_scope0 {
// #ifdef PARSER_L4_PORT_OVERLOAD   
// #if defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || \
//     defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
//         eg_md.lkp_1.l4_src_port = pkt.lookahead<bit<16>>();
// #endif
// #endif // PARSER_L4_PORT_OVERLOAD
//         transition accept;
//     }

    
    ////////////////////////////////////////////////////////////////////////////
    // Layer 4 - Outer
    ////////////////////////////////////////////////////////////////////////////

    //--------------------------------------------------------------------------
    // User Datagram Protocol (UDP) - Outer
    //--------------------------------------------------------------------------

    state parse_outer_udp_scope0 {
        pkt.extract(hdr.outer.udp);
        
#if defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || \
    defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
        eg_md.lkp_1.l4_src_port = hdr.outer.udp.src_port;
        eg_md.lkp_1.l4_dst_port = hdr.outer.udp.dst_port;  
#endif
        transition select(hdr.outer.udp.src_port, hdr.outer.udp.dst_port) {
            (_, UDP_PORT_GENV): construct_outer_geneve_scope0;
            (_, UDP_PORT_VXLAN): construct_outer_vxlan_scope0;
            (_, UDP_PORT_GTP_C): construct_outer_gtp_c_scope0;
            (UDP_PORT_GTP_C, _): construct_outer_gtp_c_scope0;
            (_, UDP_PORT_GTP_U): construct_outer_gtp_u_scope0;
            (UDP_PORT_GTP_U, _): construct_outer_gtp_u_scope0;
            // (UDP_PORT_GTP_C, UDP_PORT_GTP_C): construct_outer_gtp_c_scope0;
            // (UDP_PORT_GTP_U, UDP_PORT_GTP_U): construct_outer_gtp_u_scope0;
            default : accept;
        }
    }

    state parse_outer_udp_scope1 {
        pkt.extract(hdr.outer.udp);
        transition select(hdr.outer.udp.src_port, hdr.outer.udp.dst_port) {
            (_, UDP_PORT_GENV): construct_outer_geneve_scope1;
            (_, UDP_PORT_VXLAN): construct_outer_vxlan_scope1;
            (_, UDP_PORT_GTP_C): construct_outer_gtp_c_scope1;
            (UDP_PORT_GTP_C, _): construct_outer_gtp_c_scope1;
            (_, UDP_PORT_GTP_U): construct_outer_gtp_u_scope1;
            (UDP_PORT_GTP_U, _): construct_outer_gtp_u_scope1;
            // (UDP_PORT_GTP_C, UDP_PORT_GTP_C): construct_outer_gtp_c_scope1;
            // (UDP_PORT_GTP_U, UDP_PORT_GTP_U): construct_outer_gtp_u_scope1;
            default : accept;
        }
    }
            
    //--------------------------------------------------------------------------
    // Transmission Control Protocol (TCP) - Outer
    //--------------------------------------------------------------------------

    // todo: do we need to flag tcp w/ options as UNSUPPORTED tunnel?

    state parse_outer_tcp_scope0 {
        pkt.extract(hdr.outer.tcp);
#if defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || \
    defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
        eg_md.lkp_1.l4_src_port = hdr.outer.tcp.src_port;
        eg_md.lkp_1.l4_dst_port = hdr.outer.tcp.dst_port;
        eg_md.lkp_1.tcp_flags   = hdr.outer.tcp.flags;
#endif
        transition select(hdr.outer.tcp.data_offset) {
            5: accept;
            default: parse_outer_tcp_unsupported;
        }
    }

    state parse_outer_tcp_scope1 {
        pkt.extract(hdr.outer.tcp);
        transition accept;
    }

    state parse_outer_tcp_unsupported {
        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_UNSUPPORTED;
        eg_md.lkp_1.tunnel_id = 0;
        transition reject;
    }

    //--------------------------------------------------------------------------
    // Stream Control Transmission Protocol (SCTP) - Outer
    //--------------------------------------------------------------------------

    state parse_outer_sctp_scope0 {
        pkt.extract(hdr.outer.sctp);
#if defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
        eg_md.lkp_1.l4_src_port = hdr.outer.sctp.src_port;
        eg_md.lkp_1.l4_dst_port = hdr.outer.sctp.dst_port;
#endif // defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
        transition accept;
    }

    state parse_outer_sctp_scope1 {
        pkt.extract(hdr.outer.sctp);
        transition accept;
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
    // EoMPLS-PWCW assumes pw_cw follows bos (and ethernet follows pw_cw).
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
    //
    // For all MPLS enabled combinations above, the user can select between
    // 2, 4, or 6 supported labels (depth).

    state construct_outer_mplsogre_scope0 {
        transition select(OUTER_MPLSoGRE_ENABLE) {
            true: construct_outer_mpls_scope0;
            default: reject;
        }
    }
    state construct_outer_mpls_scope0 {
    transition select(
        OUTER_EoMPLS_ENABLE,
        OUTER_EoMPLS_PWCW_ENABLE,
        OUTER_IPoMPLS_ENABLE) {
            //(true,      _,     _): parse_outer_eompls_scope0;
            //(false,  true, false): parse_outer_eompls_pwcw_scope0;
            //(false, false,  true): parse_outer_ipompls_scope0;
            //(false,  true,  true): parse_outer_eompls_pwcw_ipompls_scope0;
            (true,      _,     _): parse_outer_eompls_0_scope0;
            (false,  true, false): parse_outer_eompls_pwcw_0_scope0;
            (false, false,  true): parse_outer_ipompls_0_scope0;
            (false,  true,  true): parse_outer_eompls_pwcw_ipompls_0_scope0;
            default: reject;
        }
    }

    //--------------------------------------------------------------------------
    state parse_outer_eompls_0_scope0 {
#if defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || \
    defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_MPLS;
        eg_md.lkp_1.tunnel_id = pkt.lookahead<bit<32>>();
#endif
        pkt.extract(hdr.outer.mpls_0);
        transition select(hdr.outer.mpls_0.bos) {
            0: parse_outer_eompls_1_scope0;
            1: parse_inner_ethernet_scope0;
        }
    }
    state parse_outer_eompls_1_scope0 {
#if defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || \
    defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_MPLS;
        eg_md.lkp_1.tunnel_id = pkt.lookahead<bit<32>>();
#endif
        pkt.extract(hdr.outer.mpls_1);
        transition select(hdr.outer.mpls_1.bos) {
            0: construct_outer_eompls_2_scope0;
            1: parse_inner_ethernet_scope0;
        }
    }
    state construct_outer_eompls_2_scope0 {
        transition select(MPLS_DEPTH_OUTER) {
            1: parse_outer_mpls_unsupported_scope0; // unsupported param value
            2: parse_outer_mpls_unsupported_scope0;
            default: parse_outer_eompls_2_scope0;
        }
    }
    state parse_outer_eompls_2_scope0 {
#if defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || \
    defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_MPLS;
        eg_md.lkp_1.tunnel_id = pkt.lookahead<bit<32>>();
#endif
        pkt.extract(hdr.outer.mpls_2);
        transition select(hdr.outer.mpls_2.bos) {
            0: parse_outer_eompls_3_scope0;
            1: parse_inner_ethernet_scope0;
        }
    }
    state parse_outer_eompls_3_scope0 {
#if defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || \
    defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_MPLS;
        eg_md.lkp_1.tunnel_id = pkt.lookahead<bit<32>>();
#endif
        pkt.extract(hdr.outer.mpls_3);
        transition select(hdr.outer.mpls_3.bos) {
            //0: construct_outer_eompls_4_scope0;
            0: parse_outer_mpls_unsupported_scope0;
            1: parse_inner_ethernet_scope0;
        }
    }
//     state construct_outer_eompls_4_scope0 {
//         transition select(MPLS_DEPTH_OUTER) {
//             3: parse_outer_mpls_unsupported_scope0; // unsupported param value
//             4: parse_outer_mpls_unsupported_scope0;
//             default: parse_outer_eompls_4_scope0;
//         }
//     }
//     state parse_outer_eompls_4_scope0 {
// #if defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || \
//     defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
//         eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_MPLS;
//         eg_md.lkp_1.tunnel_id = pkt.lookahead<bit<32>>();
// #endif
//         pkt.extract(hdr.outer.mpls_4);
//         transition select(hdr.outer.mpls_4.bos) {
//             0: parse_outer_eompls_5_scope0;
//             1: parse_inner_ethernet_scope0;
//         }
//     }
//     state parse_outer_eompls_5_scope0 {
// #if defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || \
//     defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
//         eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_MPLS;
//         eg_md.lkp_1.tunnel_id = pkt.lookahead<bit<32>>();
// #endif
//         pkt.extract(hdr.outer.mpls_5);
//         transition select(hdr.outer.mpls_5.bos) {
//             0: parse_outer_mpls_unsupported_scope0;
//             1: parse_inner_ethernet_scope0;
//         }
//     }

    //-------------------------------------------------------------------------
    state parse_outer_eompls_pwcw_0_scope0 {
#if defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || \
    defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_MPLS;
        eg_md.lkp_1.tunnel_id = pkt.lookahead<bit<32>>();
#endif
        pkt.extract(hdr.outer.mpls_0);
        transition select(hdr.outer.mpls_0.bos, pkt.lookahead<bit<4>>()) {
            (0, _): parse_outer_eompls_pwcw_1_scope0;
            (1, 0): parse_outer_eompls_pwcw_extract_pwcw_scope0;
            default: reject; // todo: unexpected - flag this as error?
        }
    }
    state parse_outer_eompls_pwcw_1_scope0 {
#if defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || \
    defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_MPLS;
        eg_md.lkp_1.tunnel_id = pkt.lookahead<bit<32>>();
#endif
        pkt.extract(hdr.outer.mpls_1);
        transition select(hdr.outer.mpls_1.bos, pkt.lookahead<bit<4>>()) {
            (0, _): construct_outer_eompls_pwcw_2_scope0;
            (1, 0): parse_outer_eompls_pwcw_extract_pwcw_scope0;
            default: reject; // todo: unexpected - flag this as error?
        }
    }
    state construct_outer_eompls_pwcw_2_scope0 {
        transition select(MPLS_DEPTH_OUTER) {
            1: parse_outer_mpls_unsupported_scope0; // unsupported param value
            2: parse_outer_mpls_unsupported_scope0;
            default: parse_outer_eompls_pwcw_2_scope0;
        }
    }
    state parse_outer_eompls_pwcw_2_scope0 {
#if defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || \
    defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_MPLS;
        eg_md.lkp_1.tunnel_id = pkt.lookahead<bit<32>>();
#endif
        pkt.extract(hdr.outer.mpls_2);
        transition select(hdr.outer.mpls_2.bos, pkt.lookahead<bit<4>>()) {
            (0, _): parse_outer_eompls_pwcw_3_scope0;
            (1, 0): parse_outer_eompls_pwcw_extract_pwcw_scope0;
            default: reject; // todo: unexpected - flag this as error?
        }
    }
    state parse_outer_eompls_pwcw_3_scope0 {
#if defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || \
    defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_MPLS;
        eg_md.lkp_1.tunnel_id = pkt.lookahead<bit<32>>();
#endif
        pkt.extract(hdr.outer.mpls_3);
        transition select(hdr.outer.mpls_3.bos, pkt.lookahead<bit<4>>()) {
            // (0, _): construct_outer_eompls_pwcw_4_scope0;
            (0, _): parse_outer_mpls_unsupported_scope0;
            (1, 0): parse_outer_eompls_pwcw_extract_pwcw_scope0;
            default: reject; // todo: unexpected - flag this as error?
        }
    }
//     state construct_outer_eompls_pwcw_4_scope0 {
//         transition select(MPLS_DEPTH_OUTER) {
//             1: parse_outer_mpls_unsupported_scope0; // unsupported param value
//             2: parse_outer_mpls_unsupported_scope0;
//             default: parse_outer_eompls_pwcw_4_scope0;
//         }
//     }
//     state parse_outer_eompls_pwcw_4_scope0 {
// #if defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || \
//     defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
//         eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_MPLS;
//         eg_md.lkp_1.tunnel_id = pkt.lookahead<bit<32>>();
// #endif
//         pkt.extract(hdr.outer.mpls_4);
//         transition select(hdr.outer.mpls_4.bos, pkt.lookahead<bit<4>>()) {
//             (0, _): parse_outer_eompls_pwcw_5_scope0;
//             (1, 0): parse_outer_eompls_pwcw_extract_pwcw_scope0;
//             default: reject; // todo: unexpected - flag this as error?
//         }
//     }
//     state parse_outer_eompls_pwcw_5_scope0 {
// #if defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || \
//     defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
//         eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_MPLS;
//         eg_md.lkp_1.tunnel_id = pkt.lookahead<bit<32>>();
// #endif
//         pkt.extract(hdr.outer.mpls_5);
//         transition select(hdr.outer.mpls_5.bos, pkt.lookahead<bit<4>>()) {
//             (0, _): parse_outer_mpls_unsupported_scope0;
//             (1, 0): parse_outer_eompls_pwcw_extract_pwcw_scope0;
//             default: reject; // todo: unexpected - flag this as error?
//         }
//     }
    state parse_outer_eompls_pwcw_extract_pwcw_scope0 {
        pkt.extract(hdr.outer.mpls_pw_cw); 
        transition parse_inner_ethernet_scope0;
    }


    //--------------------------------------------------------------------------
    state parse_outer_ipompls_0_scope0 {
#if defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || \
    defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_MPLS;
        eg_md.lkp_1.tunnel_id = pkt.lookahead<bit<32>>();
#endif    
        pkt.extract(hdr.outer.mpls_0);
        transition select(hdr.outer.mpls_0.bos, pkt.lookahead<bit<4>>()) {
            (0, _): parse_outer_ipompls_1_scope0;
            (1, 4): parse_inner_ipv4_scope0;
            (1, 6): construct_inner_ipv6_scope0;
            default: reject; // todo: unexpected - flag this as error?
        }
    }
    state parse_outer_ipompls_1_scope0 {
#if defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || \
    defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_MPLS;
        eg_md.lkp_1.tunnel_id = pkt.lookahead<bit<32>>();
#endif
        pkt.extract(hdr.outer.mpls_1);
        transition select(hdr.outer.mpls_1.bos, pkt.lookahead<bit<4>>()) {
            (0, _): construct_outer_ipompls_2_scope0;
            (1, 4): parse_inner_ipv4_scope0;
            (1, 6): construct_inner_ipv6_scope0;
            default: reject; // todo: unexpected - flag this as error?
        }
    }
    state construct_outer_ipompls_2_scope0 {
        transition select(MPLS_DEPTH_OUTER) {
            1: parse_outer_mpls_unsupported_scope0; // unsupported param value
            2: parse_outer_mpls_unsupported_scope0;
            default: parse_outer_ipompls_2_scope0;
        }
    }
    state parse_outer_ipompls_2_scope0 {
#if defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || \
    defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_MPLS;
        eg_md.lkp_1.tunnel_id = pkt.lookahead<bit<32>>();
#endif    
        pkt.extract(hdr.outer.mpls_2);
        transition select(hdr.outer.mpls_2.bos, pkt.lookahead<bit<4>>()) {
            (0, _): parse_outer_ipompls_3_scope0;
            (1, 4): parse_inner_ipv4_scope0;
            (1, 6): construct_inner_ipv6_scope0;
            default: reject; // todo: unexpected - flag this as error?
        }
    }
    state parse_outer_ipompls_3_scope0 {
#if defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || \
    defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_MPLS;
        eg_md.lkp_1.tunnel_id = pkt.lookahead<bit<32>>();
#endif
        pkt.extract(hdr.outer.mpls_3);
        transition select(hdr.outer.mpls_3.bos, pkt.lookahead<bit<4>>()) {
            // (0, _): construct_outer_ipompls_4_scope0;
            (0, _): parse_outer_mpls_unsupported_scope0;
            (1, 4): parse_inner_ipv4_scope0;
            (1, 6): construct_inner_ipv6_scope0;
            default: reject; // todo: unexpected - flag this as error?
        }
    }
//     state construct_outer_ipompls_4_scope0 {
//         transition select(MPLS_DEPTH_OUTER) {
//             3: parse_outer_mpls_unsupported_scope0; // unsupported param value
//             4: parse_outer_mpls_unsupported_scope0;
//             default: parse_outer_ipompls_4_scope0;
//         }
//     }
//     state parse_outer_ipompls_4_scope0 {
// #if defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || \
//     defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
//         eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_MPLS;
//         eg_md.lkp_1.tunnel_id = pkt.lookahead<bit<32>>();
// #endif    
//         pkt.extract(hdr.outer.mpls_4);
//         transition select(hdr.outer.mpls_4.bos, pkt.lookahead<bit<4>>()) {
//             (0, _): parse_outer_ipompls_5_scope0;
//             (1, 4): parse_inner_ipv4_scope0;
//             (1, 6): construct_inner_ipv6_scope0;
//             default: reject; // todo: unexpected - flag this as error?
//         }
//     }
//     state parse_outer_ipompls_5_scope0 {
// #if defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || \
//     defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
//         eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_MPLS;
//         eg_md.lkp_1.tunnel_id = pkt.lookahead<bit<32>>();
// #endif
//         pkt.extract(hdr.outer.mpls_5);
//         transition select(hdr.outer.mpls_5.bos, pkt.lookahead<bit<4>>()) {
//             (0, _): parse_outer_mpls_unsupported_scope0;
//             (1, 4): parse_inner_ipv4_scope0;
//             (1, 6): construct_inner_ipv6_scope0;
//             default: reject; // todo: unexpected - flag this as error?
//         }
//     }


    //--------------------------------------------------------------------------
    state parse_outer_eompls_pwcw_ipompls_0_scope0 {
#if defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || \
    defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_MPLS;
        eg_md.lkp_1.tunnel_id = pkt.lookahead<bit<32>>();
#endif
        pkt.extract(hdr.outer.mpls_0);
        transition select(hdr.outer.mpls_0.bos, pkt.lookahead<bit<4>>()) {
            (0, _): parse_outer_eompls_pwcw_ipompls_1_scope0;
            (1, 4): parse_inner_ipv4_scope0;
            (1, 6): construct_inner_ipv6_scope0;
            (1, 0): parse_outer_eompls_pwcw_ipompls_extract_pwcw_scope0;
            default: reject; // todo: unexpected - flag this as error?
        }
    }
    state parse_outer_eompls_pwcw_ipompls_1_scope0 {
#if defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || \
    defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_MPLS;
        eg_md.lkp_1.tunnel_id = pkt.lookahead<bit<32>>();
#endif
        pkt.extract(hdr.outer.mpls_1);
        transition select(hdr.outer.mpls_1.bos, pkt.lookahead<bit<4>>()) {
            (0, _): construct_outer_eompls_pwcw_ipompls_2_scope0;
            (1, 4): parse_inner_ipv4_scope0;
            (1, 6): construct_inner_ipv6_scope0;
            (1, 0): parse_outer_eompls_pwcw_ipompls_extract_pwcw_scope0;
            default: reject; // todo: unexpected - flag this as error?
        }
    }
    state construct_outer_eompls_pwcw_ipompls_2_scope0 {
        transition select(MPLS_DEPTH_OUTER) {
            1: parse_outer_mpls_unsupported_scope0; // unsupported param value
            2: parse_outer_mpls_unsupported_scope0;
            default: parse_outer_eompls_pwcw_ipompls_2_scope0;
        }
    }
    state parse_outer_eompls_pwcw_ipompls_2_scope0 {
#if defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || \
    defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_MPLS;
        eg_md.lkp_1.tunnel_id = pkt.lookahead<bit<32>>();
#endif
        pkt.extract(hdr.outer.mpls_2);
        transition select(hdr.outer.mpls_2.bos, pkt.lookahead<bit<4>>()) {
            (0, _): parse_outer_eompls_pwcw_ipompls_3_scope0;
            (1, 4): parse_inner_ipv4_scope0;
            (1, 6): construct_inner_ipv6_scope0;
            (1, 0): parse_outer_eompls_pwcw_ipompls_extract_pwcw_scope0;
            default: reject; // todo: unexpected - flag this as error?
        }
    }
    state parse_outer_eompls_pwcw_ipompls_3_scope0 {
#if defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || \
    defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_MPLS;
        eg_md.lkp_1.tunnel_id = pkt.lookahead<bit<32>>();
#endif
        pkt.extract(hdr.outer.mpls_3);
        transition select(hdr.outer.mpls_3.bos, pkt.lookahead<bit<4>>()) {
            // (0, _): construct_outer_eompls_pwcw_ipompls_4_scope0;
            (0, _): parse_outer_mpls_unsupported_scope0;
            (1, 4): parse_inner_ipv4_scope0;
            (1, 6): construct_inner_ipv6_scope0;
            (1, 0): parse_outer_eompls_pwcw_ipompls_extract_pwcw_scope0;
            default: reject; // todo: unexpected - flag this as error?
        }
    }
//     state construct_outer_eompls_pwcw_ipompls_4_scope0 {
//         transition select(MPLS_DEPTH_OUTER) {
//             3: parse_outer_mpls_unsupported_scope0; // unsupported param value
//             4: parse_outer_mpls_unsupported_scope0;
//             default: parse_outer_eompls_pwcw_ipompls_4_scope0;
//         }
//     }
//     state parse_outer_eompls_pwcw_ipompls_4_scope0 {
// #if defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || \
//     defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
//         eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_MPLS;
//         eg_md.lkp_1.tunnel_id = pkt.lookahead<bit<32>>();
// #endif
//         pkt.extract(hdr.outer.mpls_4);
//         transition select(hdr.outer.mpls_4.bos, pkt.lookahead<bit<4>>()) {
//             (0, _): parse_outer_eompls_pwcw_ipompls_5_scope0;
//             (1, 4): parse_inner_ipv4_scope0;
//             (1, 6): construct_inner_ipv6_scope0;
//             (1, 0): parse_outer_eompls_pwcw_ipompls_extract_pwcw_scope0;
//             default: reject; // todo: unexpected - flag this as error?
//         }
//     }
//     state parse_outer_eompls_pwcw_ipompls_5_scope0 {
// #if defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || \
//     defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
//         eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_MPLS;
//         eg_md.lkp_1.tunnel_id = pkt.lookahead<bit<32>>();
// #endif
//         pkt.extract(hdr.outer.mpls_5);
//         transition select(hdr.outer.mpls_5.bos, pkt.lookahead<bit<4>>()) {
//             (0, _): parse_outer_mpls_unsupported_scope0;
//             (1, 4): parse_inner_ipv4_scope0;
//             (1, 6): construct_inner_ipv6_scope0;
//             (1, 0): parse_outer_eompls_pwcw_ipompls_extract_pwcw_scope0;
//             default: reject; // todo: unexpected - flag this as error?
//         }
//     }
    state parse_outer_eompls_pwcw_ipompls_extract_pwcw_scope0 {
        pkt.extract(hdr.outer.mpls_pw_cw); 
        transition parse_inner_ethernet_scope0;
    }

    state parse_outer_mpls_unsupported_scope0 {
#if defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || \
    defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)    
        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_UNSUPPORTED;
        eg_md.lkp_1.tunnel_id = 0;
#endif    
        transition reject;
    }
    


    //--------------------------------------------------------------------------
    //--------------------------------------------------------------------------
    state construct_outer_mplsogre_scope1 {
        transition select(OUTER_MPLSoGRE_ENABLE) {
            true: construct_outer_mpls_scope1;
            default: reject;
        }
    }
    state construct_outer_mpls_scope1 {
        transition select(
          OUTER_EoMPLS_ENABLE,
          OUTER_EoMPLS_PWCW_ENABLE,
          OUTER_IPoMPLS_ENABLE) {
            // (true,      _,     _): parse_outer_eompls_scope1;
            // (false,  true, false): parse_outer_eompls_pwcw_scope1;
            // (false, false,  true): parse_outer_ipompls_scope1;
            // (false,  true,  true): parse_outer_eompls_pwcw_ipompls_scope1;
            (true,      _,     _): parse_outer_eompls_0_scope1;
            (false,  true, false): parse_outer_eompls_pwcw_0_scope1;
            (false, false,  true): parse_outer_ipompls_0_scope1;
            (false,  true,  true): parse_outer_eompls_pwcw_ipompls_0_scope1;
            default: reject;
        }
    }

    //--------------------------------------------------------------------------
    // state parse_outer_eompls_scope1 {
    //     // note: inner here means "current scope - 1"
    //     eg_md.lkp_1.tunnel_inner_type = SWITCH_TUNNEL_TYPE_MPLS;
    //     pkt.extract(hdr.outer.mpls.next);
    //     transition select(hdr.outer.mpls.last.bos) {
    //         0: parse_outer_eompls_scope1;
    //         1: parse_inner_ethernet_scope1;
    //     }
    // }
    state parse_outer_eompls_0_scope1 {
        // note: inner here means "current scope - 1"
        eg_md.lkp_1.tunnel_inner_type = SWITCH_TUNNEL_TYPE_MPLS;
        pkt.extract(hdr.outer.mpls_0);
        transition select(hdr.outer.mpls_0.bos) {
            0: parse_outer_eompls_1_scope1;
            1: parse_inner_ethernet_scope1;
        }
    }
    state parse_outer_eompls_1_scope1 {
        // note: inner here means "current scope - 1"
        eg_md.lkp_1.tunnel_inner_type = SWITCH_TUNNEL_TYPE_MPLS;
        pkt.extract(hdr.outer.mpls_1);
        transition select(hdr.outer.mpls_1.bos) {
            0: construct_outer_eompls_2_scope1;
            1: parse_inner_ethernet_scope1;
        }
    }
    state construct_outer_eompls_2_scope1 {
        transition select(MPLS_DEPTH_OUTER) {
            1: parse_outer_mpls_unsupported_scope1; // unsupported param value
            2: parse_outer_mpls_unsupported_scope1;
            default: parse_outer_eompls_2_scope1;
        }
    }
    state parse_outer_eompls_2_scope1 {
        // note: inner here means "current scope - 1"
        eg_md.lkp_1.tunnel_inner_type = SWITCH_TUNNEL_TYPE_MPLS;
        pkt.extract(hdr.outer.mpls_2);
        transition select(hdr.outer.mpls_2.bos) {
            0: parse_outer_eompls_3_scope1;
            1: parse_inner_ethernet_scope1;
        }
    }
    state parse_outer_eompls_3_scope1 {
        // note: inner here means "current scope - 1"
        eg_md.lkp_1.tunnel_inner_type = SWITCH_TUNNEL_TYPE_MPLS;
        pkt.extract(hdr.outer.mpls_3);
        transition select(hdr.outer.mpls_3.bos) {
            // 0: construct_outer_eompls_4_scope1;
            0: parse_outer_mpls_unsupported_scope1;
            1: parse_inner_ethernet_scope1;
        }
    }
//     state construct_outer_eompls_4_scope1 {
//         transition select(MPLS_DEPTH_OUTER) {
//             3: parse_outer_mpls_unsupported_scope1; // unsupported param value
//             4: parse_outer_mpls_unsupported_scope1;
//             default: parse_outer_eompls_4_scope1;
//         }
//     }
//     state parse_outer_eompls_4_scope1 {
//         // note: inner here means "current scope - 1"
//         eg_md.lkp_1.tunnel_inner_type = SWITCH_TUNNEL_TYPE_MPLS;
//         pkt.extract(hdr.outer.mpls_4);
//         transition select(hdr.outer.mpls_4.bos) {
//             0: parse_outer_eompls_5_scope1;
//             1: parse_inner_ethernet_scope1;
//         }
//     }
//     state parse_outer_eompls_5_scope1 {
//         // note: inner here means "current scope - 1"
//         eg_md.lkp_1.tunnel_inner_type = SWITCH_TUNNEL_TYPE_MPLS;
//         pkt.extract(hdr.outer.mpls_5);
//         transition select(hdr.outer.mpls_5.bos) {
//             0: parse_outer_mpls_unsupported_scope1;
//             1: parse_inner_ethernet_scope1;
//         }
//     }


    //--------------------------------------------------------------------------
    // state parse_outer_eompls_pwcw_scope1 {
    //     // note: inner here means "current scope - 1"
    //     eg_md.lkp_1.tunnel_inner_type = SWITCH_TUNNEL_TYPE_MPLS;
    //     pkt.extract(hdr.outer.mpls.next);
    //     transition select(hdr.outer.mpls.last.bos, pkt.lookahead<bit<4>>()) {
    //         (0, _): parse_outer_eompls_pwcw_scope1;
    //         (1, 0): parse_outer_eompls_pwcw_extract_pwcw_scope1;
    //         default: reject; // todo: unexpected - flag this as error?
    //     }
    // }    
    state parse_outer_eompls_pwcw_0_scope1 {
        // note: inner here means "current scope - 1"
        eg_md.lkp_1.tunnel_inner_type = SWITCH_TUNNEL_TYPE_MPLS;
        pkt.extract(hdr.outer.mpls_0);
        transition select(hdr.outer.mpls_0.bos, pkt.lookahead<bit<4>>()) {
            (0, _): parse_outer_eompls_pwcw_1_scope1;
            (1, 0): parse_outer_eompls_pwcw_extract_pwcw_scope1;
            default: reject; // todo: unexpected - flag this as error?
        }
    }    
    state parse_outer_eompls_pwcw_1_scope1 {
        // note: inner here means "current scope - 1"
        eg_md.lkp_1.tunnel_inner_type = SWITCH_TUNNEL_TYPE_MPLS;
        pkt.extract(hdr.outer.mpls_1);
        transition select(hdr.outer.mpls_1.bos, pkt.lookahead<bit<4>>()) {
            (0, _): construct_outer_eompls_pwcw_2_scope1;
            (1, 0): parse_outer_eompls_pwcw_extract_pwcw_scope1;
            default: reject; // todo: unexpected - flag this as error?
        }
    }    
    state construct_outer_eompls_pwcw_2_scope1 {
        transition select(MPLS_DEPTH_OUTER) {
            1: parse_outer_mpls_unsupported_scope1; // unsupported param value
            2: parse_outer_mpls_unsupported_scope1;
            default: parse_outer_eompls_pwcw_2_scope1;
        }
    }
    state parse_outer_eompls_pwcw_2_scope1 {
        // note: inner here means "current scope - 1"
        eg_md.lkp_1.tunnel_inner_type = SWITCH_TUNNEL_TYPE_MPLS;
        pkt.extract(hdr.outer.mpls_2);
        transition select(hdr.outer.mpls_2.bos, pkt.lookahead<bit<4>>()) {
            (0, _): parse_outer_eompls_pwcw_3_scope1;
            (1, 0): parse_outer_eompls_pwcw_extract_pwcw_scope1;
            default: reject; // todo: unexpected - flag this as error?
        }
    }    
    state parse_outer_eompls_pwcw_3_scope1 {
        // note: inner here means "current scope - 1"
        eg_md.lkp_1.tunnel_inner_type = SWITCH_TUNNEL_TYPE_MPLS;
        pkt.extract(hdr.outer.mpls_3);
        transition select(hdr.outer.mpls_3.bos, pkt.lookahead<bit<4>>()) {
            // (0, _): construct_outer_eompls_pwcw_4_scope1;
            (0, _): parse_outer_mpls_unsupported_scope1;
            (1, 0): parse_outer_eompls_pwcw_extract_pwcw_scope1;
            default: reject; // todo: unexpected - flag this as error?
        }
    }    
//     state construct_outer_eompls_pwcw_4_scope1 {
//         transition select(MPLS_DEPTH_OUTER) {
//             3: parse_outer_mpls_unsupported_scope1; // unsupported param value
//             4: parse_outer_mpls_unsupported_scope1;
//             default: parse_outer_eompls_pwcw_4_scope1;
//         }
//     }
//     state parse_outer_eompls_pwcw_4_scope1 {
//         // note: inner here means "current scope - 1"
//         eg_md.lkp_1.tunnel_inner_type = SWITCH_TUNNEL_TYPE_MPLS;
//         pkt.extract(hdr.outer.mpls_4);
//         transition select(hdr.outer.mpls_4.bos, pkt.lookahead<bit<4>>()) {
//             (0, _): parse_outer_eompls_pwcw_5_scope1;
//             (1, 0): parse_outer_eompls_pwcw_extract_pwcw_scope1;
//             default: reject; // todo: unexpected - flag this as error?
//         }
//     }    
//     state parse_outer_eompls_pwcw_5_scope1 {
//         // note: inner here means "current scope - 1"
//         eg_md.lkp_1.tunnel_inner_type = SWITCH_TUNNEL_TYPE_MPLS;
//         pkt.extract(hdr.outer.mpls_5);
//         transition select(hdr.outer.mpls_5.bos, pkt.lookahead<bit<4>>()) {
//             (0, _): parse_outer_mpls_unsupported_scope1;
//             (1, 0): parse_outer_eompls_pwcw_extract_pwcw_scope1;
//             default: reject; // todo: unexpected - flag this as error?
//         }
//     }
    state parse_outer_eompls_pwcw_extract_pwcw_scope1 {
        pkt.extract(hdr.outer.mpls_pw_cw); 
        transition parse_inner_ethernet_scope1;
    }


    //--------------------------------------------------------------------------
    // state parse_outer_ipompls_scope1 {
    //     // note: inner here means "current scope - 1"
    //     eg_md.lkp_1.tunnel_inner_type = SWITCH_TUNNEL_TYPE_MPLS;
    //     pkt.extract(hdr.outer.mpls.next);
    //     transition select(hdr.outer.mpls.last.bos, pkt.lookahead<bit<4>>()) {
    //         (0, _): parse_outer_ipompls_scope1;
    //         (1, 4): parse_inner_ipv4_scope1;
    //         (1, 6): construct_inner_ipv6_scope1;
    //         default: reject; // todo: unexpected - flag this as error?
    //     }
    // }
    state parse_outer_ipompls_0_scope1 {
        // note: inner here means "current scope - 1"
        eg_md.lkp_1.tunnel_inner_type = SWITCH_TUNNEL_TYPE_MPLS;
        pkt.extract(hdr.outer.mpls_0);
        transition select(hdr.outer.mpls_0.bos, pkt.lookahead<bit<4>>()) {
            (0, _): parse_outer_ipompls_1_scope1;
            (1, 4): parse_inner_ipv4_scope1;
            (1, 6): construct_inner_ipv6_scope1;
            default: reject; // todo: unexpected - flag this as error?
        }
    }
    state parse_outer_ipompls_1_scope1 {
        // note: inner here means "current scope - 1"
        eg_md.lkp_1.tunnel_inner_type = SWITCH_TUNNEL_TYPE_MPLS;
        pkt.extract(hdr.outer.mpls_1);
        transition select(hdr.outer.mpls_1.bos, pkt.lookahead<bit<4>>()) {
            (0, _): construct_outer_ipompls_2_scope1;
            (1, 4): parse_inner_ipv4_scope1;
            (1, 6): construct_inner_ipv6_scope1;
            default: reject; // todo: unexpected - flag this as error?
        }
    }
    state construct_outer_ipompls_2_scope1 {
        transition select(MPLS_DEPTH_OUTER) {
            1: parse_outer_mpls_unsupported_scope1; // unsupported param value
            2: parse_outer_mpls_unsupported_scope1;
            default: parse_outer_ipompls_2_scope1;
        }
    }
    state parse_outer_ipompls_2_scope1 {
        // note: inner here means "current scope - 1"
        eg_md.lkp_1.tunnel_inner_type = SWITCH_TUNNEL_TYPE_MPLS;
        pkt.extract(hdr.outer.mpls_2);
        transition select(hdr.outer.mpls_2.bos, pkt.lookahead<bit<4>>()) {
            (0, _): parse_outer_ipompls_3_scope1;
            (1, 4): parse_inner_ipv4_scope1;
            (1, 6): construct_inner_ipv6_scope1;
            default: reject; // todo: unexpected - flag this as error?
        }
    }
    state parse_outer_ipompls_3_scope1 {
        // note: inner here means "current scope - 1"
        eg_md.lkp_1.tunnel_inner_type = SWITCH_TUNNEL_TYPE_MPLS;
        pkt.extract(hdr.outer.mpls_3);
        transition select(hdr.outer.mpls_3.bos, pkt.lookahead<bit<4>>()) {
            // (0, _): construct_outer_ipompls_4_scope1;
            (0, _): parse_outer_mpls_unsupported_scope1;
            (1, 4): parse_inner_ipv4_scope1;
            (1, 6): construct_inner_ipv6_scope1;
            default: reject; // todo: unexpected - flag this as error?
        }
    }
//     state construct_outer_ipompls_4_scope1 {
//         transition select(MPLS_DEPTH_OUTER) {
//             1: parse_outer_mpls_unsupported_scope1; // unsupported param value
//             2: parse_outer_mpls_unsupported_scope1;
//             default: parse_outer_ipompls_4_scope1;
//         }
//     }
//     state parse_outer_ipompls_4_scope1 {
//         // note: inner here means "current scope - 1"
//         eg_md.lkp_1.tunnel_inner_type = SWITCH_TUNNEL_TYPE_MPLS;
//         pkt.extract(hdr.outer.mpls_4);
//         transition select(hdr.outer.mpls_4.bos, pkt.lookahead<bit<4>>()) {
//             (0, _): parse_outer_ipompls_5_scope1;
//             (1, 4): parse_inner_ipv4_scope1;
//             (1, 6): construct_inner_ipv6_scope1;
//             default: reject; // todo: unexpected - flag this as error?
//         }
//     }
//     state parse_outer_ipompls_5_scope1 {
//         // note: inner here means "current scope - 1"
//         eg_md.lkp_1.tunnel_inner_type = SWITCH_TUNNEL_TYPE_MPLS;
//         pkt.extract(hdr.outer.mpls_5);
//         transition select(hdr.outer.mpls_5.bos, pkt.lookahead<bit<4>>()) {
//             (0, _): parse_outer_mpls_unsupported_scope1;
//             (1, 4): parse_inner_ipv4_scope1;
//             (1, 6): construct_inner_ipv6_scope1;
//             default: reject; // todo: unexpected - flag this as error?
//         }
//     }

    //--------------------------------------------------------------------------
    // state parse_outer_eompls_pwcw_ipompls_scope1 {
    //     // note: inner here means "current scope - 1"
    //     eg_md.lkp_1.tunnel_inner_type = SWITCH_TUNNEL_TYPE_MPLS;
    //     pkt.extract(hdr.outer.mpls.next);
    //     transition select(hdr.outer.mpls.last.bos, pkt.lookahead<bit<4>>()) {
    //         (0, _): parse_outer_eompls_pwcw_ipompls_scope1;
    //         (1, 4): parse_inner_ipv4_scope1;
    //         (1, 6): construct_inner_ipv6_scope1;
    //         (1, 0): parse_outer_eompls_pwcw_ipompls_extract_pwcw_scope1;
    //         default: reject; // todo: unexpected - flag this as error?
    //     }
    // }
    state parse_outer_eompls_pwcw_ipompls_0_scope1 {
        // note: inner here means "current scope - 1"
        eg_md.lkp_1.tunnel_inner_type = SWITCH_TUNNEL_TYPE_MPLS;
        pkt.extract(hdr.outer.mpls_0);
        transition select(hdr.outer.mpls_0.bos, pkt.lookahead<bit<4>>()) {
            (0, _): parse_outer_eompls_pwcw_ipompls_1_scope1;
            (1, 4): parse_inner_ipv4_scope1;
            (1, 6): construct_inner_ipv6_scope1;
            (1, 0): parse_outer_eompls_pwcw_ipompls_extract_pwcw_scope1;
            default: reject; // todo: unexpected - flag this as error?
        }
    }
    state parse_outer_eompls_pwcw_ipompls_1_scope1 {
        // note: inner here means "current scope - 1"
        eg_md.lkp_1.tunnel_inner_type = SWITCH_TUNNEL_TYPE_MPLS;
        pkt.extract(hdr.outer.mpls_1);
        transition select(hdr.outer.mpls_1.bos, pkt.lookahead<bit<4>>()) {
            (0, _): construct_outer_eompls_pwcw_ipompls_2_scope1;
            (1, 4): parse_inner_ipv4_scope1;
            (1, 6): construct_inner_ipv6_scope1;
            (1, 0): parse_outer_eompls_pwcw_ipompls_extract_pwcw_scope1;
            default: reject; // todo: unexpected - flag this as error?
        }
    }
    state construct_outer_eompls_pwcw_ipompls_2_scope1 {
        transition select(MPLS_DEPTH_OUTER) {
            1: parse_outer_mpls_unsupported_scope1; // unsupported param value
            2: parse_outer_mpls_unsupported_scope1;
            default: parse_outer_eompls_pwcw_ipompls_2_scope1;
        }
    }
    state parse_outer_eompls_pwcw_ipompls_2_scope1 {
        // note: inner here means "current scope - 1"
        eg_md.lkp_1.tunnel_inner_type = SWITCH_TUNNEL_TYPE_MPLS;
        pkt.extract(hdr.outer.mpls_2);
        transition select(hdr.outer.mpls_2.bos, pkt.lookahead<bit<4>>()) {
            (0, _): parse_outer_eompls_pwcw_ipompls_3_scope1;
            (1, 4): parse_inner_ipv4_scope1;
            (1, 6): construct_inner_ipv6_scope1;
            (1, 0): parse_outer_eompls_pwcw_ipompls_extract_pwcw_scope1;
            default: reject; // todo: unexpected - flag this as error?
        }
    }
    state parse_outer_eompls_pwcw_ipompls_3_scope1 {
        // note: inner here means "current scope - 1"
        eg_md.lkp_1.tunnel_inner_type = SWITCH_TUNNEL_TYPE_MPLS;
        pkt.extract(hdr.outer.mpls_3);
        transition select(hdr.outer.mpls_3.bos, pkt.lookahead<bit<4>>()) {
            // (0, _): construct_outer_eompls_pwcw_ipompls_4_scope1;
            (0, _): parse_outer_mpls_unsupported_scope1;
            (1, 4): parse_inner_ipv4_scope1;
            (1, 6): construct_inner_ipv6_scope1;
            (1, 0): parse_outer_eompls_pwcw_ipompls_extract_pwcw_scope1;
            default: reject; // todo: unexpected - flag this as error?
        }
    }
//     state construct_outer_eompls_pwcw_ipompls_4_scope1 {
//         transition select(MPLS_DEPTH_OUTER) {
//             1: parse_outer_mpls_unsupported_scope1; // unsupported param value
//             2: parse_outer_mpls_unsupported_scope1;
//             default: parse_outer_eompls_pwcw_ipompls_4_scope1;
//         }
//     }
//     state parse_outer_eompls_pwcw_ipompls_4_scope1 {
//         // note: inner here means "current scope - 1"
//         eg_md.lkp_1.tunnel_inner_type = SWITCH_TUNNEL_TYPE_MPLS;
//         pkt.extract(hdr.outer.mpls_4);
//         transition select(hdr.outer.mpls_4.bos, pkt.lookahead<bit<4>>()) {
//             (0, _): parse_outer_eompls_pwcw_ipompls_5_scope1;
//             (1, 4): parse_inner_ipv4_scope1;
//             (1, 6): construct_inner_ipv6_scope1;
//             (1, 0): parse_outer_eompls_pwcw_ipompls_extract_pwcw_scope1;
//             default: reject; // todo: unexpected - flag this as error?
//         }
//     }
//     state parse_outer_eompls_pwcw_ipompls_5_scope1 {
//         // note: inner here means "current scope - 1"
//         eg_md.lkp_1.tunnel_inner_type = SWITCH_TUNNEL_TYPE_MPLS;
//         pkt.extract(hdr.outer.mpls_5);
//         transition select(hdr.outer.mpls_5.bos, pkt.lookahead<bit<4>>()) {
//             (0, _): parse_outer_mpls_unsupported_scope1;
//             (1, 4): parse_inner_ipv4_scope1;
//             (1, 6): construct_inner_ipv6_scope1;
//             (1, 0): parse_outer_eompls_pwcw_ipompls_extract_pwcw_scope1;
//             default: reject; // todo: unexpected - flag this as error?
//         }
//     }
    state parse_outer_eompls_pwcw_ipompls_extract_pwcw_scope1 {
        pkt.extract(hdr.outer.mpls_pw_cw); 
        transition parse_inner_ethernet_scope1;
    }

    state parse_outer_mpls_unsupported_scope1 {
        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_UNSUPPORTED;
        eg_md.lkp_1.tunnel_id = 0;
        transition reject;
    }
    

    ////////////////////////////////////////////////////////////////////////////
    // Tunnels - Outer
    ////////////////////////////////////////////////////////////////////////////

    //--------------------------------------------------------------------------
    // Generic Network Virtualization Encapsulation (GENEVE) - Outer
    //--------------------------------------------------------------------------

    state construct_outer_geneve_scope0 {
        transition select(OUTER_GENEVE_ENABLE) {
            true: qualify_outer_geneve_scope0;
            false: reject;
        }
    }

    state qualify_outer_geneve_scope0 {
        geneve_h snoop_geneve = pkt.lookahead<geneve_h>();
#if defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || \
    defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_UNSUPPORTED;
#endif
        transition select(
            snoop_geneve.ver,
            snoop_geneve.opt_len,
            snoop_geneve.O,
            snoop_geneve.C,
            snoop_geneve.proto_type) {

          //     O C 
            (0,0,0,0,ETHERTYPE_ENET): parse_outer_geneve_qualified_scope0;
            (0,0,0,0,ETHERTYPE_IPV4): parse_outer_geneve_qualified_scope0;
            (0,0,0,0,ETHERTYPE_IPV6): parse_outer_geneve_qualified_scope0;
            default: accept;
        }
    }

    state parse_outer_geneve_qualified_scope0 {
        pkt.extract(hdr.outer.geneve);
#if defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || \
    defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_GENEVE;
        eg_md.lkp_1.tunnel_id = (bit<switch_tunnel_id_width>)hdr.outer.geneve.vni;
#endif
    
        transition select(hdr.outer.geneve.proto_type) {
            ETHERTYPE_ENET: parse_inner_ethernet_scope0;
            ETHERTYPE_IPV4: parse_inner_ipv4_scope0;
            ETHERTYPE_IPV6: construct_inner_ipv6_scope0;
            default: accept;
        }
    }


    state construct_outer_geneve_scope1 {
        transition select(OUTER_GENEVE_ENABLE) {
            true: qualify_outer_geneve_scope1;
            false: reject;
        }
    }

    state qualify_outer_geneve_scope1 {
        geneve_h snoop_geneve = pkt.lookahead<geneve_h>();
        // note: inner here means "current scope - 1"
        eg_md.lkp_1.tunnel_inner_type = SWITCH_TUNNEL_TYPE_UNSUPPORTED;

        transition select(
            snoop_geneve.ver,
            snoop_geneve.opt_len,
            snoop_geneve.O,
            snoop_geneve.C,
            snoop_geneve.proto_type) {

          //     O C 
            (0,0,0,0,ETHERTYPE_ENET): parse_outer_geneve_qualified_scope1;
            (0,0,0,0,ETHERTYPE_IPV4): parse_outer_geneve_qualified_scope1;
            (0,0,0,0,ETHERTYPE_IPV6): parse_outer_geneve_qualified_scope1;
            default: accept;
        }
    }

    state parse_outer_geneve_qualified_scope1 {
        pkt.extract(hdr.outer.geneve);
        // note: inner here means "current scope - 1"
        eg_md.lkp_1.tunnel_inner_type = SWITCH_TUNNEL_TYPE_GENEVE;
        transition select(hdr.outer.geneve.proto_type) {
            ETHERTYPE_ENET: parse_inner_ethernet_scope1;
            ETHERTYPE_IPV4: parse_inner_ipv4_scope1;
            ETHERTYPE_IPV6: construct_inner_ipv6_scope1;
            default: accept;
        }
    }


    //--------------------------------------------------------------------------
    // Virtual Extensible Local Area Network (VXLAN) - Outer
    //--------------------------------------------------------------------------

    state construct_outer_vxlan_scope0 {
        transition select(OUTER_VXLAN_ENABLE) {
            true: parse_outer_vxlan_scope0;
            false: reject;
        }
    }

    state parse_outer_vxlan_scope0 {
        pkt.extract(hdr.outer.vxlan);
#if defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || \
    defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_VXLAN;
        eg_md.lkp_1.tunnel_id = (bit<switch_tunnel_id_width>)hdr.outer.vxlan.vni;
#endif
        transition parse_inner_ethernet_scope0;
    }

    state construct_outer_vxlan_scope1 {
        transition select(OUTER_VXLAN_ENABLE) {
            true: parse_outer_vxlan_scope1;
            false: reject;
        }
    }

    state parse_outer_vxlan_scope1 {
        pkt.extract(hdr.outer.vxlan);
        // note: inner here means "current scope - 1"
        eg_md.lkp_1.tunnel_inner_type = SWITCH_TUNNEL_TYPE_VXLAN;
        transition parse_inner_ethernet_scope1;
    }

            
    //--------------------------------------------------------------------------
    // Internet Protocol (IP) - Outer
    //--------------------------------------------------------------------------

    state construct_outer_ipinip_set_tunnel_scope0 {
        transition select(OUTER_IPINIP_ENABLE) {    
            true: parse_outer_ipinip_set_tunnel_scope0;
            default: reject;
        }
    }
    state parse_outer_ipinip_set_tunnel_scope0 {
#if defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || \
    defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_IPINIP;
        eg_md.lkp_1.tunnel_id = 0;
#endif
        transition parse_inner_ipv4_scope0;
    }

    state construct_outer_ipv6inip_set_tunnel_scope0 {
        transition select(OUTER_IPINIP_ENABLE) {    
            true: parse_outer_ipv6inip_set_tunnel_scope0;
            default: reject;
        }
    }    
    state parse_outer_ipv6inip_set_tunnel_scope0 {
#if defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || \
    defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_IPINIP;
        eg_md.lkp_1.tunnel_id = 0;
#endif
        transition construct_inner_ipv6_scope0;
    }

    state construct_outer_ipinip_set_tunnel_scope1 {
        transition select(OUTER_IPINIP_ENABLE) {    
            true: parse_outer_ipinip_set_tunnel_scope1;
            default: reject;
        }
    }
    state parse_outer_ipinip_set_tunnel_scope1 {
        // note: inner here means "current scope - 1"
        eg_md.lkp_1.tunnel_inner_type = SWITCH_TUNNEL_TYPE_IPINIP;
        transition parse_inner_ipv4_scope1;
    }

    state construct_outer_ipv6inip_set_tunnel_scope1 {
        transition select(OUTER_IPINIP_ENABLE) {    
            true: parse_outer_ipv6inip_set_tunnel_scope1;
            default: reject;
        }
    }
    state parse_outer_ipv6inip_set_tunnel_scope1 {
        // note: inner here means "current scope - 1"
        eg_md.lkp_1.tunnel_inner_type = SWITCH_TUNNEL_TYPE_IPINIP;
        transition construct_inner_ipv6_scope1;
    }


    //--------------------------------------------------------------------------
    // Generic Routing Encapsulation (GRE) - Outer
    //--------------------------------------------------------------------------

    state construct_outer_gre_scope0 {
        transition select(OUTER_GRE_ENABLE) {    
            true: parse_outer_gre_scope0;
            default: reject;
        }
    }

    state parse_outer_gre_scope0 {    
        gre_h snoop_gre = pkt.lookahead<gre_h>();
#if defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || \
    defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_UNSUPPORTED;
#endif

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
            (0,0,0,0,0,0,0,0): parse_outer_gre_qualified_scope0;
            (1,0,0,0,0,0,0,0): parse_outer_gre_qualified_scope0;
            (0,0,1,0,0,0,0,0): parse_outer_gre_qualified_scope0;
            (0,0,0,1,0,0,0,0): parse_outer_gre_qualified_scope0;
            default: accept;
        }
    }

    state construct_outer_gre_scope1 {
        transition select(OUTER_GRE_ENABLE) {    
            true: parse_outer_gre_scope1;
            default: reject;
        }
    }

    state parse_outer_gre_scope1 {    
        gre_h snoop_gre = pkt.lookahead<gre_h>();
        // note: inner here means "current scope - 1"
        eg_md.lkp_1.tunnel_inner_type = SWITCH_TUNNEL_TYPE_UNSUPPORTED;

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
            (0,0,0,0,0,0,0,0): parse_outer_gre_qualified_scope1;
            (1,0,0,0,0,0,0,0): parse_outer_gre_qualified_scope1;
            (0,0,1,0,0,0,0,0): parse_outer_gre_qualified_scope1;
            (0,0,0,1,0,0,0,0): parse_outer_gre_qualified_scope1;
            default: accept;
        }
    }
        
    state parse_outer_gre_qualified_scope0 {    
        pkt.extract(hdr.outer.gre);
#if defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || \
    defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_GRE;
        eg_md.lkp_1.tunnel_id = 0;
#endif

        transition select(
            hdr.outer.gre.C,
            hdr.outer.gre.K,
            hdr.outer.gre.S,
            hdr.outer.gre.proto) {

          // C K S
            (0,1,0,GRE_PROTOCOLS_NVGRE): construct_outer_nvgre_scope0;
            (0,0,0,ETHERTYPE_IPV4): parse_inner_ipv4_scope0;
            (0,0,0,ETHERTYPE_IPV6): construct_inner_ipv6_scope0;
            (0,0,0,ETHERTYPE_MPLS): construct_outer_mplsogre_scope0;
            (1,0,0,_): parse_outer_gre_optional_scope0;
            (0,1,0,_): parse_outer_gre_optional_scope0;
            (0,0,1,_): parse_outer_gre_optional_scope0;
            default: accept;
        }
    }

    state parse_outer_gre_qualified_scope1 {    
        pkt.extract(hdr.outer.gre);
        // note: inner here means "current scope - 1"
        eg_md.lkp_1.tunnel_inner_type = SWITCH_TUNNEL_TYPE_GRE;

        transition select(
            hdr.outer.gre.C,
            hdr.outer.gre.K,
            hdr.outer.gre.S,
            hdr.outer.gre.proto) {

          // C K S
            (0,1,0,GRE_PROTOCOLS_NVGRE): construct_outer_nvgre_scope1;
            (0,0,0,ETHERTYPE_IPV4): parse_inner_ipv4_scope1;
            (0,0,0,ETHERTYPE_IPV6): construct_inner_ipv6_scope1;
            (0,0,0,ETHERTYPE_MPLS): construct_outer_mplsogre_scope1;
            (1,0,0,_): parse_outer_gre_optional_scope1;
            (0,1,0,_): parse_outer_gre_optional_scope1;
            (0,0,1,_): parse_outer_gre_optional_scope1;
            default: accept;
        }
    }
        
    state parse_outer_gre_optional_scope0 {    
        pkt.extract(hdr.outer.gre_optional);  
        transition select(hdr.outer.gre.proto) {

            ETHERTYPE_IPV4: parse_inner_ipv4_scope0;
            ETHERTYPE_IPV6: construct_inner_ipv6_scope0;                        
            ETHERTYPE_MPLS: construct_outer_mplsogre_scope0;
            default: accept;
        }
    }

    state parse_outer_gre_optional_scope1 {    
        pkt.extract(hdr.outer.gre_optional);  
        transition select(hdr.outer.gre.proto) {

            ETHERTYPE_IPV4: parse_inner_ipv4_scope1;
            ETHERTYPE_IPV6: construct_inner_ipv6_scope1;                        
            ETHERTYPE_MPLS: construct_outer_mplsogre_scope1;
            default: accept;
        }
    }

    
    //--------------------------------------------------------------------------
    // Network Virtualization using GRE (NVGRE) - (aka: L2 GRE) - Outer
    //--------------------------------------------------------------------------

    state construct_outer_nvgre_scope0 {
        transition select(OUTER_NVGRE_ENABLE) {
            true: parse_outer_nvgre_scope0;
            false: reject;
        }
    }

    state parse_outer_nvgre_scope0 {
    	pkt.extract(hdr.outer.nvgre);
        eg_md.tunnel_1.nvgre_flow_id = hdr.outer.nvgre.flow_id; //todo: ingress-only in switch
#if defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || \
    defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_NVGRE;
        eg_md.lkp_1.tunnel_id = (bit<switch_tunnel_id_width>)hdr.outer.nvgre.vsid;
#endif
    	transition parse_inner_ethernet_scope0;
    }

    state construct_outer_nvgre_scope1 {
        transition select(OUTER_NVGRE_ENABLE) {
            true: parse_outer_nvgre_scope1;
            false: reject;
        }
    }

    state parse_outer_nvgre_scope1 {
    	pkt.extract(hdr.outer.nvgre);
        eg_md.tunnel_1.nvgre_flow_id = hdr.outer.nvgre.flow_id; //todo: ingress-only in switch
        // note: inner here means "current scope - 1"
        eg_md.lkp_1.tunnel_inner_type = SWITCH_TUNNEL_TYPE_NVGRE;
    	transition parse_inner_ethernet_scope1;
    }


//     //--------------------------------------------------------------------------
//     // Encapsulating Security Payload (ESP) - Outer
//     //--------------------------------------------------------------------------
//     
//     state parse_outer_esp_overload_scope0 {
// #ifdef PARSER_L4_PORT_OVERLOAD   
// #if defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || \
//     defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
//          eg_md.lkp_1.l4_src_port = pkt.lookahead<esp_h>().spi_hi;
//          eg_md.lkp_1.l4_dst_port = pkt.lookahead<esp_h>().spi_lo;
// #endif
// #endif // PARSER_L4_PORT_OVERLOAD
//         transition accept;
//     }


    //--------------------------------------------------------------------------
    // GPRS (General Packet Radio Service) Tunneling Protocol (GTP) - Outer
    //--------------------------------------------------------------------------
    // Based on pseudo code from Glenn (see email from 03/11/2019):

    // GTP-C
    //--------------------------------------------------------------------------
    // Simply set tunnel type and ID for policy via lookahead (no extraction).

    state construct_outer_gtp_c_scope0 {
        transition select(OUTER_GTP_ENABLE) {    
            true: parse_outer_gtp_c_scope0;
            default: reject;
        }
    }

    state parse_outer_gtp_c_scope0 {

#if defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || \
    defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_UNSUPPORTED;
#endif
            
        transition select(
            pkt.lookahead<gtp_v2_base_h>().version,
            pkt.lookahead<gtp_v2_base_h>().T
        ) {
            (2, 1): parse_outer_gtp_c_qualified_scope0;
            default: accept;
        }
    }

    state parse_outer_gtp_c_qualified_scope0 {
#if defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || \
    defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_GTPC;
        eg_md.lkp_1.tunnel_id = pkt.lookahead<gtp_v2_base_h>().teid;
#endif
    	transition accept;
    }

    state construct_outer_gtp_c_scope1 {
        transition select(OUTER_GTP_ENABLE) {    
            true: parse_outer_gtp_c_scope1;
            default: reject;
        }
    }

    state parse_outer_gtp_c_scope1 {
        // note: inner here means "current scope - 1"
        eg_md.lkp_1.tunnel_inner_type = SWITCH_TUNNEL_TYPE_UNSUPPORTED;
            
        transition select(
            pkt.lookahead<gtp_v2_base_h>().version,
            pkt.lookahead<gtp_v2_base_h>().T
        ) {
            (2, 1): parse_outer_gtp_c_qualified_scope1;
            default: accept;
        }
    }

    state parse_outer_gtp_c_qualified_scope1 {
        // note: inner here means "current scope - 1"
        eg_md.lkp_1.tunnel_inner_type = SWITCH_TUNNEL_TYPE_GTPC; 
    	transition accept;
    }


    // GTP-U
    //--------------------------------------------------------------------------
    // Only supports optional header for sequence-number
    // Does not support parsing (TLV) extension headers

    state construct_outer_gtp_u_scope0 {
        transition select(OUTER_GTP_ENABLE) {    
            true: parse_outer_gtp_u_scope0;
            default: reject;
        }
    }

    state parse_outer_gtp_u_scope0 {
#if defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || \
    defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_UNSUPPORTED;
#endif
        gtp_v1_base_h snoop_gtp_v1_base = pkt.lookahead<gtp_v1_base_h>();
        transition select(
            snoop_gtp_v1_base.version,
            snoop_gtp_v1_base.PT,
            snoop_gtp_v1_base.E,
            snoop_gtp_v1_base.S,
            snoop_gtp_v1_base.PN) {

            (1, 1, 0, 0, 0): parse_outer_gtp_u_qualified_scope0;
            (1, 1, 0, 1, 0): parse_outer_gtp_u_with_optional_qualified_scope0;            
            default: accept;
        }
    }

    state parse_outer_gtp_u_qualified_scope0 {
        pkt.extract(hdr.outer.gtp_v1_base);
#if defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || \
    defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_GTPU;
        eg_md.lkp_1.tunnel_id = hdr.outer.gtp_v1_base.teid;
#endif
        transition select(pkt.lookahead<bit<4>>()) {
            4: parse_inner_ipv4_scope0;
            6: construct_inner_ipv6_scope0;
            default: accept;
        }
    }

    state parse_outer_gtp_u_with_optional_qualified_scope0 {
        pkt.extract(hdr.outer.gtp_v1_base);
        pkt.extract(hdr.outer.gtp_v1_optional);
#if defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || \
    defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_GTPU;
        eg_md.lkp_1.tunnel_id = hdr.outer.gtp_v1_base.teid;
#endif
        transition select(
            hdr.outer.gtp_v1_base.E,
            pkt.lookahead<bit<4>>()) {
            (0, 4): parse_inner_ipv4_scope0;
            (0, 6): construct_inner_ipv6_scope0;
            default: accept;
        }
    }    

    state construct_outer_gtp_u_scope1 {
        transition select(OUTER_GTP_ENABLE) {    
            true: parse_outer_gtp_u_scope1;
            default: reject;
        }
    }

    state parse_outer_gtp_u_scope1 {
        gtp_v1_base_h snoop_gtp_v1_base = pkt.lookahead<gtp_v1_base_h>();
        // note: inner here means "current scope - 1"
        eg_md.lkp_1.tunnel_inner_type = SWITCH_TUNNEL_TYPE_UNSUPPORTED; 
            
        transition select(
            snoop_gtp_v1_base.version,
            snoop_gtp_v1_base.PT,
            snoop_gtp_v1_base.E,
            snoop_gtp_v1_base.S,
            snoop_gtp_v1_base.PN) {

            (1, 1, 0, 0, 0): parse_outer_gtp_u_qualified_scope1;
            (1, 1, 0, 1, 0): parse_outer_gtp_u_with_optional_qualified_scope1;
            default: accept;
        }
    }

    state parse_outer_gtp_u_qualified_scope1 {
        pkt.extract(hdr.outer.gtp_v1_base);
        // note: inner here means "current scope - 1"    
        eg_md.lkp_1.tunnel_inner_type = SWITCH_TUNNEL_TYPE_GTPU;
        transition select(pkt.lookahead<bit<4>>()) {
            4: parse_inner_ipv4_scope1;
            6: construct_inner_ipv6_scope1;
            default: accept;
        }
    }

    state parse_outer_gtp_u_with_optional_qualified_scope1 {
        pkt.extract(hdr.outer.gtp_v1_base);
        pkt.extract(hdr.outer.gtp_v1_optional);
        // note: inner here means "current scope - 1"
        eg_md.lkp_1.tunnel_inner_type = SWITCH_TUNNEL_TYPE_GTPU;
        transition select(
            hdr.outer.gtp_v1_base.E,
            pkt.lookahead<bit<4>>()) {
            (0, 4): parse_inner_ipv4_scope1;
            (0, 6): construct_inner_ipv6_scope1;
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

    //--------------------------------------------------------------------------
    // Scope 0
    //--------------------------------------------------------------------------
            
    state parse_inner_ethernet_scope0 {
        pkt.extract(hdr.inner.ethernet);
        transition select(hdr.inner.ethernet.ether_type) {
            ETHERTYPE_VLAN: parse_inner_vlan_0_scope0;
            ETHERTYPE_IPV4: parse_inner_ipv4_scope0;
            ETHERTYPE_IPV6: construct_inner_ipv6_scope0;
            default: accept;
        }
    }
    state parse_inner_vlan_0_scope0 {
        pkt.extract(hdr.inner.vlan_tag[0]);
        transition select(hdr.inner.vlan_tag[0].ether_type) {
            ETHERTYPE_VLAN: parse_inner_vlan_unsupported_scope0;
            ETHERTYPE_IPV4: parse_inner_ipv4_scope0;
            ETHERTYPE_IPV6: construct_inner_ipv6_scope0;
            default: accept;
        }
    }
    state parse_inner_vlan_unsupported_scope0 {
        transition reject;
    }

    //--------------------------------------------------------------------------
    // Scope 1
    //--------------------------------------------------------------------------            

    state parse_inner_ethernet_scope1 {
        pkt.extract(hdr.inner.ethernet);
        eg_md.lkp_1.mac_src_addr = hdr.inner.ethernet.src_addr;
        eg_md.lkp_1.mac_dst_addr = hdr.inner.ethernet.dst_addr;
        eg_md.lkp_1.mac_type = hdr.inner.ethernet.ether_type;
        eg_md.lkp_1.pcp = 0;
        eg_md.lkp_1.vid = 0;
        
        transition select(hdr.inner.ethernet.ether_type) {
            ETHERTYPE_VLAN: parse_inner_vlan_0_scope1;
            ETHERTYPE_IPV4: parse_inner_ipv4_scope1;
            ETHERTYPE_IPV6: construct_inner_ipv6_scope1;
            default: accept;
        }
    }
    state parse_inner_vlan_0_scope1 {
        pkt.extract(hdr.inner.vlan_tag[0]);
        eg_md.lkp_1.pcp = hdr.inner.vlan_tag[0].pcp;
#ifdef SF_2_L2_VLAN_ID_ENABLE
		eg_md.lkp_1.vid = hdr.inner.vlan_tag[0].vid;
#endif
        eg_md.lkp_1.mac_type = hdr.inner.vlan_tag[0].ether_type;

#ifndef SF_2_L2_VLAN_ID_ENABLE
        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_VLAN;
        //eg_md.lkp_1.tunnel_id = (bit<switch_tunnel_id_width>)hdr.inner.vlan_tag[0].vid;
#endif
        transition select(hdr.inner.vlan_tag[0].ether_type) {
            ETHERTYPE_VLAN: parse_inner_vlan_unsupported_scope1;
            ETHERTYPE_IPV4: parse_inner_ipv4_scope1;
            ETHERTYPE_IPV6: construct_inner_ipv6_scope1;
            default: accept;
        }
    }
    state parse_inner_vlan_unsupported_scope1 {
        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_UNSUPPORTED;
        eg_md.lkp_1.tunnel_id = 0;
        transition reject;
    }
       

    ////////////////////////////////////////////////////////////////////////////
    // Layer 3 - Inner
    ////////////////////////////////////////////////////////////////////////////

    //--------------------------------------------------------------------------
    // Scope 0
    //--------------------------------------------------------------------------            

    // For scope0 inner parsing, l2 and v4 or v6 is all that's needed downstream.
        
    state parse_inner_ipv4_scope0 {
        pkt.extract(hdr.inner.ipv4);
        transition accept;
    }

    state construct_inner_ipv6_scope0 {
        transition select(INNER_IPV6_ENABLE) {
            true: parse_inner_ipv6_scope0;
            default: reject;
        }
    }            
    state parse_inner_ipv6_scope0 {
        pkt.extract(hdr.inner.ipv6);
        transition accept;
    }
    
            
    //--------------------------------------------------------------------------
    // Scope 1
    //--------------------------------------------------------------------------

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

    state parse_inner_ipv4_scope1 {
        pkt.extract(hdr.inner.ipv4);
        protocol_inner = hdr.inner.ipv4.protocol;

        // fixup ethertype for ip-n-ip case
        eg_md.lkp_1.mac_type    = ETHERTYPE_IPV4;        
        //eg_md.lkp_1.ip_type     = SWITCH_IP_TYPE_IPV4;
        eg_md.lkp_1.ip_proto    = hdr.inner.ipv4.protocol;
        eg_md.lkp_1.ip_tos      = hdr.inner.ipv4.tos;
        eg_md.lkp_1.ip_flags    = hdr.inner.ipv4.flags;
        eg_md.lkp_1.ip_src_addr_v4 = hdr.inner.ipv4.src_addr;
        eg_md.lkp_1.ip_dst_addr_v4 = hdr.inner.ipv4.dst_addr;
        eg_md.lkp_1.ip_len      = hdr.inner.ipv4.total_len;

        transition select(
            hdr.inner.ipv4.ihl,
            hdr.inner.ipv4.frag_offset,
            hdr.inner.ipv4.protocol) {
            //(5, 0, IP_PROTOCOLS_ICMP): parse_inner_icmp_igmp_overload_scope1;
            //(5, 0, IP_PROTOCOLS_IGMP): parse_inner_icmp_igmp_overload_scope1;
            (5, 0, _): branch_inner_l3_protocol_scope1;
            default: parse_inner_ip_unsupported_scope1;
       }
    }

    state construct_inner_ipv6_scope1 {
        transition select(INNER_IPV6_ENABLE) {
            true: parse_inner_ipv6_scope1;
            default: reject;
        }
    }
    state parse_inner_ipv6_scope1 {
        pkt.extract(hdr.inner.ipv6);
        protocol_inner = hdr.inner.ipv6.next_hdr;

        // fixup ethertype for ip-n-ip case
        eg_md.lkp_1.mac_type      = ETHERTYPE_IPV6;

        //eg_md.lkp_1.ip_type       = SWITCH_IP_TYPE_IPV6;
        eg_md.lkp_1.ip_proto      = hdr.inner.ipv6.next_hdr;
        //eg_md.lkp_1.ip_tos        = hdr.inner.ipv6.tos; // not byte-aligned - set in mau
        eg_md.lkp_1.ip_src_addr   = hdr.inner.ipv6.src_addr;
        eg_md.lkp_1.ip_dst_addr   = hdr.inner.ipv6.dst_addr;
        eg_md.lkp_1.ip_len        = hdr.inner.ipv6.payload_len;

        transition branch_inner_l3_protocol_scope1;
        // transition select(hdr.inner.ipv6.next_hdr) {
        //     IP_PROTOCOLS_ICMPV6: parse_inner_icmp_igmp_overload_scope1;
        //     default: branch_inner_l3_protocol_scope1;
        // }
    }

    state branch_inner_l3_protocol_scope1 {
        transition select(protocol_inner) {
           IP_PROTOCOLS_UDP: parse_inner_udp_scope1;
           IP_PROTOCOLS_TCP: parse_inner_tcp_scope1;
           IP_PROTOCOLS_SCTP: parse_inner_sctp_scope1;
           IP_PROTOCOLS_GRE: construct_inner_gre_scope1;
           //IP_PROTOCOLS_ESP:  parse_inner_esp_overload_scope1;
           IP_PROTOCOLS_IPV4: construct_inner_ipinip_set_tunnel_scope1;
           IP_PROTOCOLS_IPV6: construct_inner_ipv6inip_set_tunnel_scope1;
        }
    }
    
    state parse_inner_ip_unsupported_scope1 {
        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_UNSUPPORTED;
        eg_md.lkp_1.tunnel_id = 0;
        transition reject;
    }




//     // For ICMP and IGMP, we're not actually extracting the header;
//     // We're simply over-loading L4-port info for policy via lookahead.    
//     state parse_inner_icmp_igmp_overload_scope1 {
// #ifdef PARSER_L4_PORT_OVERLOAD   
//         eg_md.lkp_1.l4_src_port = pkt.lookahead<bit<16>>();
// #endif // PARSER_L4_PORT_OVERLOAD
//         transition accept;
//     }
    
            
    ////////////////////////////////////////////////////////////////////////////
    // Inner Layer 4 - Inner
    ////////////////////////////////////////////////////////////////////////////

    //--------------------------------------------------------------------------
    // Scope 1
    //--------------------------------------------------------------------------

    state parse_inner_udp_scope1 {
        pkt.extract(hdr.inner.udp);
        eg_md.lkp_1.l4_src_port = hdr.inner.udp.src_port;
        eg_md.lkp_1.l4_dst_port = hdr.inner.udp.dst_port;              
        transition select(
            hdr.inner.udp.src_port,
            hdr.inner.udp.dst_port) {

            (_, UDP_PORT_GTP_C): construct_inner_gtp_c_scope1;
            (UDP_PORT_GTP_C, _): construct_inner_gtp_c_scope1;
            (_, UDP_PORT_GTP_U): construct_inner_gtp_u_scope1;
            (UDP_PORT_GTP_U, _): construct_inner_gtp_u_scope1;
            // (UDP_PORT_GTP_C, UDP_PORT_GTP_C): construct_inner_gtp_c_scope1;
            // (UDP_PORT_GTP_U, UDP_PORT_GTP_U): construct_inner_gtp_u_scope1;
            default: accept;
        }
    }

    // todo: do we need to flag tcp w/ options as UNSUPPORTED tunnel?
    state parse_inner_tcp_scope1 {
        pkt.extract(hdr.inner.tcp);
        eg_md.lkp_1.tcp_flags = hdr.inner.tcp.flags;
        eg_md.lkp_1.l4_src_port = hdr.inner.tcp.src_port;
        eg_md.lkp_1.l4_dst_port = hdr.inner.tcp.dst_port;        
        transition select(hdr.inner.tcp.data_offset) {
            5: accept;
            default: parse_inner_tcp_unsupported;
        }
    }
    state parse_inner_tcp_unsupported {
        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_UNSUPPORTED;
        eg_md.lkp_1.tunnel_id = 0;
        transition reject;
    }

    state parse_inner_sctp_scope1 {
        pkt.extract(hdr.inner.sctp);
        eg_md.lkp_1.l4_src_port = hdr.inner.sctp.src_port;
        eg_md.lkp_1.l4_dst_port = hdr.inner.sctp.dst_port;              
        transition accept;
    }     


            
    ////////////////////////////////////////////////////////////////////////////
    // Tunnels - Inner
    ////////////////////////////////////////////////////////////////////////////

    //--------------------------------------------------------------------------
    // Internet Protocol (IP) - Inner
    //--------------------------------------------------------------------------
    
    state construct_inner_ipinip_set_tunnel_scope1 {
        transition select(INNER_IPINIP_ENABLE) {    
            true: parse_inner_ipinip_set_tunnel_scope1;
            default: reject;
        }
    }
    state parse_inner_ipinip_set_tunnel_scope1 {
#if defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || \
    defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_IPINIP;
        eg_md.lkp_1.tunnel_id = 0;
#endif
        transition parse_inner_inner_ipv4;
    }

    state construct_inner_ipv6inip_set_tunnel_scope1 {
        transition select(INNER_IPINIP_ENABLE) {    
            true: parse_inner_ipv6inip_set_tunnel_scope1;
            default: reject;
        }
    }           
    state parse_inner_ipv6inip_set_tunnel_scope1 {
#if defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || \
    defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_IPINIP;
        eg_md.lkp_1.tunnel_id = 0;
#endif
        transition construct_inner_inner_ipv6;
    }


//     //--------------------------------------------------------------------------
//     // Encapsulating Security Payload (ESP) - Inner
//     //--------------------------------------------------------------------------
//      
//     state parse_inner_esp_overload_scope1 {
// #ifdef PARSER_L4_PORT_OVERLOAD   
//         eg_md.lkp_1.l4_src_port = pkt.lookahead<esp_h>().spi_hi;
//         eg_md.lkp_1.l4_dst_port = pkt.lookahead<esp_h>().spi_lo;
// #endif // PARSER_L4_PORT_OVERLOAD
//         transition accept;
//     }


    //--------------------------------------------------------------------------
    // Generic Routing Encapsulation (GRE) - Inner
    //--------------------------------------------------------------------------

    state construct_inner_gre_scope1 {
        transition select(INNER_GRE_ENABLE) {    
            true: parse_inner_gre_scope1;
            default: reject;
        }
    }
    
    state parse_inner_gre_scope1 {    
        gre_h snoop_gre = pkt.lookahead<gre_h>();
        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_UNSUPPORTED;

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
            (0,0,0,0,0,0,0,0): parse_inner_gre_qualified_scope1;
            (1,0,0,0,0,0,0,0): parse_inner_gre_qualified_scope1;
            (0,0,1,0,0,0,0,0): parse_inner_gre_qualified_scope1;
            (0,0,0,1,0,0,0,0): parse_inner_gre_qualified_scope1;
            default: accept;
        }
    }
            
    state parse_inner_gre_qualified_scope1 {    
        pkt.extract(hdr.inner.gre);
        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_GRE;
        eg_md.lkp_1.tunnel_id = 0;            

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

    state construct_inner_gtp_c_scope1 {
        transition select(INNER_GTP_ENABLE) {    
            true: parse_inner_gtp_c_scope1;
            default: reject;
        }
    }

    state parse_inner_gtp_c_scope1 {
        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_UNSUPPORTED;
            
        transition select(
            pkt.lookahead<gtp_v2_base_h>().version,
            pkt.lookahead<gtp_v2_base_h>().T
        ) {
            (2, 1): parse_inner_gtp_c_qualified_scope1;
            default: accept;
        }
    }

    state parse_inner_gtp_c_qualified_scope1 {
        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_GTPC;
        eg_md.lkp_1.tunnel_id = pkt.lookahead<gtp_v2_base_h>().teid;
   	    transition accept;
    }


    // GTP-U
    //--------------------------------------------------------------------------
    // Only supports optional header for sequence-number
    // Does not support parsing (TLV) extension headers

    state construct_inner_gtp_u_scope1 {
        transition select(INNER_GTP_ENABLE) {    
            true: parse_inner_gtp_u_scope1;
            default: reject;
        }
    }

    state parse_inner_gtp_u_scope1 {
        gtp_v1_base_h snoop_inner_gtp_v1_base = pkt.lookahead<gtp_v1_base_h>();
        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_UNSUPPORTED;
            
        transition select(
            snoop_inner_gtp_v1_base.version,
            snoop_inner_gtp_v1_base.PT,
            snoop_inner_gtp_v1_base.E,
            snoop_inner_gtp_v1_base.S,
            snoop_inner_gtp_v1_base.PN) {

            (1, 1, 0, 0, 0): parse_inner_gtp_u_qualified_scope1;
            (1, 1, 0, 1, 0): parse_inner_gtp_u_with_optional_qualified_scope1;
            default: accept;
        }
    }

    state parse_inner_gtp_u_qualified_scope1 {
        pkt.extract(hdr.inner.gtp_v1_base);
        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_GTPU;
        eg_md.lkp_1.tunnel_id = hdr.inner.gtp_v1_base.teid;
        transition select(pkt.lookahead<bit<4>>()) {
            4: parse_inner_inner_ipv4;
            6: construct_inner_inner_ipv6;
            default: accept;
        }
    }

    state parse_inner_gtp_u_with_optional_qualified_scope1 {
        pkt.extract(hdr.inner.gtp_v1_base);
        pkt.extract(hdr.inner.gtp_v1_optional);
        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_GTPU;
        eg_md.lkp_1.tunnel_id = hdr.inner.gtp_v1_base.teid;
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
#ifdef INNER_INNER_IP_LEN_ENABLE
        hdr.inner_inner.ipv4.total_len = pkt.lookahead<ipv4_h>().total_len;
#endif // INNER_INNER_IP_LEN_ENABLE

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
#ifdef INNER_INNER_IP_LEN_ENABLE
        hdr.inner_inner.ipv6.payload_len = pkt.lookahead<ipv6_truncated_h>().payload_len;
#endif // INNER_INNER_IP_LEN_ENABLE
	    transition accept;
    }

}

#endif /* _NPB_EGR_PARSER_ */
