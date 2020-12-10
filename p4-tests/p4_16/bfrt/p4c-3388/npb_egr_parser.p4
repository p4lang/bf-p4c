#ifndef _NPB_EGR_PARSER_
#define _NPB_EGR_PARSER_

parser NpbEgressParser(
        packet_in pkt,
        out switch_header_t hdr,
        out switch_egress_metadata_t eg_md,
        out egress_intrinsic_metadata_t eg_intr_md) {

    bit<8> scope;
//  bool   l2_fwd_en;
//  bool   rmac_hit;

	bit<8>  protocol_outer;
	bit<8>  protocol_inner;

    
    state start {
        pkt.extract(eg_intr_md);
        eg_md.pkt_length = eg_intr_md.pkt_length;
        eg_md.port = eg_intr_md.egress_port;

#if defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
        // initialize lookup struct to zeros
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
#endif // defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
        
//      eg_md.inner_inner.ethernet_isValid = false;
//      eg_md.inner_inner.ipv4_isValid = false;
//      eg_md.inner_inner.ipv6_isValid = false;

#ifdef MIRROR_INGRESS_ENABLE
        switch_port_mirror_metadata_h mirror_md = pkt.lookahead<switch_port_mirror_metadata_h>();
        transition select(eg_intr_md.deflection_flag, mirror_md.src, mirror_md.type) {
            (1, _,                             _                                   ) : parse_deflected_pkt;

            (_, SWITCH_PKT_SRC_BRIDGED,        _                                   ) : parse_bridged_pkt;
//          (_, _,                             SWITCH_MIRROR_TYPE_PORT             ) : parse_port_mirrored_metadata;
            (_, SWITCH_PKT_SRC_CLONED_INGRESS, SWITCH_MIRROR_TYPE_PORT             ) : parse_port_mirrored_metadata_ig; // derek added
            (_, SWITCH_PKT_SRC_CLONED_EGRESS,  SWITCH_MIRROR_TYPE_PORT             ) : parse_port_mirrored_metadata_eg; // derek added
            (_, SWITCH_PKT_SRC_CLONED_EGRESS,  SWITCH_MIRROR_TYPE_CPU              ) : parse_cpu_mirrored_metadata; // egress copy-to-cpu uses mirror mechanism

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
        eg_md.port_lag_index       = hdr.bridged_md.base.ingress_port_lag_index;
        eg_md.bd                   = hdr.bridged_md.base.ingress_bd;
        eg_md.nexthop              = hdr.bridged_md.base.nexthop;
//      eg_md.pkt_type             = hdr.bridged_md.base.pkt_type;
        eg_md.cpu_reason           = hdr.bridged_md.base.cpu_reason;
//      eg_md.ingress_timestamp    = hdr.bridged_md.base.timestamp;
        eg_md.flags.rmac_hit       = hdr.bridged_md.base.rmac_hit;
#ifdef TUNNEL_ENABLE
        eg_md.outer_nexthop        = hdr.bridged_md.tunnel.outer_nexthop;
        eg_md.tunnel_0.index       = hdr.bridged_md.tunnel.index;
//      eg_md.tunnel_0.hash        = hdr.bridged_md.tunnel.hash;

//      eg_md.tunnel_0.terminate   = hdr.bridged_md.tunnel.terminate_0;
//      eg_md.tunnel_1.terminate   = hdr.bridged_md.tunnel.terminate_1;
//      eg_md.tunnel_2.terminate   = hdr.bridged_md.tunnel.terminate_2;
#endif

		// ----- extract nsh bridged metadata -----
        eg_md.nsh_md.start_of_path = hdr.bridged_md.nsh.nsh_md_start_of_path;
		eg_md.nsh_md.end_of_path   = hdr.bridged_md.nsh.nsh_md_end_of_path;
		eg_md.nsh_md.l2_fwd_en     = hdr.bridged_md.nsh.nsh_md_l2_fwd_en;
//      eg_md.nsh_md.sf1_active    = hdr.bridged_md.nsh.nsh_md_sf1_active;

		// ----- extract dedup bridged metadata -----
//#ifdef SF_2_DEDUP_ENABLE
		eg_md.nsh_md.dedup_en      = hdr.bridged_md.nsh.nsh_md_dedup_en;
//#endif

#ifdef DTEL_ENABLE
        eg_md.dtel.report_type = hdr.bridged_md.dtel.report_type;
        eg_md.dtel.hash = hdr.bridged_md.dtel.hash;
        eg_md.dtel.session_id = hdr.bridged_md.dtel.session_id;
#endif

        // ----- add cpu header by default -----
#ifdef CPU_HDR_ADDED_IN_PARSER
        //hdr.cpu.setValid();
        hdr.cpu.egress_queue       = 0;
        hdr.cpu.tx_bypass          = 0;
        hdr.cpu.capture_ts         = 0;
        hdr.cpu.reserved           = 0;
        // Both these line are commented out due to compiler... "error: Field is
        // extracted in the parser into multiple containers, but the container
        // slices after the first aren't byte aligned"
        //hdr.cpu.ingress_port       = (bit<16>) hdr.bridged_md.base.ingress_port;
        //hdr.cpu.port_lag_index     = (bit<16>) hdr.bridged_md.base.ingress_port_lag_index;
        hdr.cpu.ingress_bd         = (bit<16>) hdr.bridged_md.base.ingress_bd;
        hdr.cpu.reason_code        = (bit<16>) hdr.bridged_md.base.cpu_reason;
#endif

        // -----------------------------

        //  L2   My   MAU                   First   
        //  Fwd  MAC  Path                  Stack
        //  ----------------------------    ------------
        //  0    0    SFC Optical-Tap       Outer       
        //  0    1    SFC Optical-Tap       Outer       
        //  1    0    Bridging              Outer       
        //  1    1    SFC Network-Tap       Transport   
        //            or SFC Bypass (nsh)   Transport

        transition select(
            (bit<1>)hdr.bridged_md.nsh.nsh_md_l2_fwd_en,
            (bit<1>)hdr.bridged_md.base.rmac_hit) {

            (1, 0):  parse_outer_ethernet_scope0; // SFC Optical-Tap / Bridging Path
//          default: parse_transport_ethernet;    // SFC Network-Tap / SFC Bypass Path
            default: parse_transport_nsh;         // SFC Network-Tap / SFC Bypass Path
        }               
    }

    state parse_deflected_pkt {
#ifdef DTEL_ENABLE
        pkt.extract(hdr.bridged_md);
        eg_md.pkt_src = SWITCH_PKT_SRC_DEFLECTED;
#ifdef PACKET_LENGTH_ADJUSTMENT
        eg_md.mirror.type = SWITCH_MIRROR_TYPE_DTEL_DEFLECT;
#endif
        eg_md.dtel.report_type = hdr.bridged_md.dtel.report_type;
        eg_md.dtel.hash = hdr.bridged_md.dtel.hash;
        // Initialize eg_md.dtel.session_id to prevent it from being marked @pa_no_init.
        eg_md.dtel.session_id = 0;
        eg_md.mirror.session_id = hdr.bridged_md.dtel.session_id;
//      eg_md.qos.qid = hdr.bridged_md.base.qid; // derek hack
#ifdef INT_V2 
        hdr.outer.dtel_metadata_1 = {
            0,
            hdr.bridged_md.base.ingress_port,
            0,
            hdr.bridged_md.dtel.egress_port};
        hdr.outer.dtel_metadata_4 = {
            0,
            hdr.bridged_md.base.timestamp};
        hdr.outer.dtel_drop_report = {
            0,
//          hdr.bridged_md.base.qid, // derek hack
			0,
            SWITCH_DROP_REASON_TRAFFIC_MANAGER,
            0};
#else
//      eg_md.ingress_timestamp = hdr.bridged_md.base.timestamp; // derek hack
        hdr.outer.dtel_report = {
            0,
            hdr.bridged_md.base.ingress_port,
            0,
            hdr.bridged_md.dtel.egress_port,
            0,
//          hdr.bridged_md.base.qid}; // derek hack
            0};
        hdr.outer.dtel_drop_report = {
            SWITCH_DROP_REASON_TRAFFIC_MANAGER,
            0};
#endif /* INT_V2 */
        transition accept;
#endif /* DTEL_ENABLE */
    }

    state parse_port_mirrored_metadata_ig {
        switch_port_mirror_metadata_h port_md;
        pkt.extract(port_md);
//      pkt.extract(hdr.outer.ethernet);
        eg_md.pkt_src = port_md.src;
        eg_md.mirror.session_id = port_md.session_id;
//      eg_md.ingress_timestamp = port_md.timestamp;
		hdr.transport.nsh_type1.timestamp = port_md.timestamp;
        eg_md.bypass = ~SWITCH_EGRESS_BYPASS_MTU;
#ifdef PACKET_LENGTH_ADJUSTMENT
        eg_md.mirror.type = port_md.type;
#endif
#ifdef DTEL_ENABLE
        // Initialize eg_md.dtel.session_id to prevent it from being marked @pa_no_init.
        eg_md.dtel.session_id = 0;
#endif
        eg_md.ingress_port         = port_md.port; // derek added
        eg_md.port_lag_index       = port_md.port_lag_index; // derek added
        eg_md.bd                   = port_md.bd; // derek added

        // ----- add cpu header by default -----
#ifdef CPU_HDR_ADDED_IN_PARSER
        //hdr.cpu.setValid();
        hdr.cpu.egress_queue       = 0;
        hdr.cpu.tx_bypass          = 0;
        hdr.cpu.capture_ts         = 0;
        hdr.cpu.reserved           = 0;
        // Both these line are commented out due to compiler... "error: Field is
        // extracted in the parser into multiple containers, but the container
        // slices after the first aren't byte aligned"
        //hdr.cpu.ingress_port       = (bit<16>) port_md.port; // derek added
        //hdr.cpu.port_lag_index     = (bit<16>) port_md.port_lag_index; // derek added
        hdr.cpu.ingress_bd         = (bit<16>) port_md.bd; // derek added
        hdr.cpu.reason_code        = (bit<16>) SWITCH_CPU_REASON_IG_PORT_MIRRROR;
// derek: I think this is broken -- packet may have an nsh header at the start instead of an ethernet header -- code needs to look more like above "transition select"?
//      hdr.cpu.ether_type         = hdr.outer.ethernet.ether_type;
#endif

//		transition accept;

        // -----------------------------

        //  L2   My   MAU                   First   
        //  Fwd  MAC  Path                  Stack
        //  ----------------------------    ------------
        //  0    0    SFC Optical-Tap       Outer       
        //  0    1    SFC Optical-Tap       Outer       
        //  1    0    Bridging              Outer       
        //  1    1    SFC Network-Tap       Transport   
        //            or SFC Bypass (nsh)   Transport

#ifdef DEREK
        transition select(
            (bit<1>)port_md.l2_fwd_en,
            (bit<1>)port_md.rmac_hit) {

            (1, 0):  parse_port_mirrored_metadata_ig_outer;     // SFC Optical-Tap / Bridging Path
            default: parse_port_mirrored_metadata_ig_transport; // SFC Network-Tap / SFC Bypass Path
        }               
#else
		// assume packet always has an npb header
		transition parse_port_mirrored_metadata_ig_transport;
#endif
    }

// DEREK

	state parse_port_mirrored_metadata_ig_transport {
		// just kill the nsh header for ingress mirrored pkts,
		// since I assume nobody wants to see it (and it's not
		// a valid ethernet frame)....
	    pkt.extract(hdr.transport.nsh_type1);
//	    hdr.transport.nsh_type1.setInvalid();
//		transition parse_port_mirrored_metadata_ig_outer;

		// -----------------------

        pkt.extract(hdr.outer.ethernet);
#ifdef CPU_HDR_ADDED_IN_PARSER
        hdr.cpu.ether_type         = hdr.outer.ethernet.ether_type;
#endif
		transition accept;
	}

	state parse_port_mirrored_metadata_ig_outer {
        pkt.extract(hdr.outer.ethernet);
#ifdef CPU_HDR_ADDED_IN_PARSER
        hdr.cpu.ether_type         = hdr.outer.ethernet.ether_type;
#endif
		transition accept;
	}

    state parse_port_mirrored_metadata_eg {
        switch_port_mirror_metadata_h port_md;
        pkt.extract(port_md);
        pkt.extract(hdr.outer.ethernet);
        eg_md.pkt_src = port_md.src;
        eg_md.mirror.session_id = port_md.session_id;
//      eg_md.ingress_timestamp = port_md.timestamp;
		hdr.transport.nsh_type1.timestamp = port_md.timestamp;
        eg_md.bypass = ~SWITCH_EGRESS_BYPASS_MTU;
#ifdef PACKET_LENGTH_ADJUSTMENT
        eg_md.mirror.type = port_md.type;
#endif
#ifdef DTEL_ENABLE
        // Initialize eg_md.dtel.session_id to prevent it from being marked @pa_no_init.
        eg_md.dtel.session_id = 0;
#endif
        eg_md.ingress_port         = port_md.port; // derek added
        eg_md.port_lag_index       = port_md.port_lag_index; // derek added
        eg_md.bd                   = port_md.bd; // derek added

        // ----- add cpu header by default -----
#ifdef CPU_HDR_ADDED_IN_PARSER
        //hdr.cpu.setValid();
        hdr.cpu.egress_queue       = 0;
        hdr.cpu.tx_bypass          = 0;
        hdr.cpu.capture_ts         = 0;
        hdr.cpu.reserved           = 0;
        // Both these line are commented out due to compiler... "error: Field is
        // extracted in the parser into multiple containers, but the container
        // slices after the first aren't byte aligned"
        //hdr.cpu.ingress_port       = (bit<16>) port_md.port; // derek added
        //hdr.cpu.port_lag_index     = (bit<16>) port_md.port_lag_index; // derek added
        hdr.cpu.ingress_bd         = (bit<16>) port_md.bd; // derek added
        hdr.cpu.reason_code        = (bit<16>) SWITCH_CPU_REASON_EG_PORT_MIRRROR;
        hdr.cpu.ether_type         = hdr.outer.ethernet.ether_type; // derek: does this need to be done after reframings?
#endif

        transition accept;
    }

    state parse_cpu_mirrored_metadata { // egress copy-to-cpu uses mirror mechanism
        switch_cpu_mirror_metadata_h cpu_md;
        pkt.extract(cpu_md);
        pkt.extract(hdr.outer.ethernet);
        eg_md.pkt_src = cpu_md.src;
        eg_md.bypass = ~SWITCH_EGRESS_BYPASS_MTU;
        eg_md.bd = cpu_md.bd;                   // for cpu header
        // eg_md.ingress_port = cpu_md.md.port; // for cpu header
        eg_md.cpu_reason = cpu_md.reason_code;  // for cpu header
#ifdef PACKET_LENGTH_ADJUSTMENT
        eg_md.mirror.type = cpu_md.type;
#endif
#ifdef DTEL_ENABLE
        // Initialize eg_md.dtel.session_id to prevent it from being marked @pa_no_init.
        eg_md.dtel.session_id = 0;
#endif
        eg_md.ingress_port         = cpu_md.port; // derek added
        eg_md.port_lag_index       = cpu_md.port_lag_index; // derek added
        eg_md.bd                   = cpu_md.bd; // derek added

        // ----- add cpu header by default -----
#ifdef CPU_HDR_ADDED_IN_PARSER
        //hdr.cpu.setValid();
        hdr.cpu.egress_queue       = 0;
        hdr.cpu.tx_bypass          = 0;
        hdr.cpu.capture_ts         = 0;
        hdr.cpu.reserved           = 0;
        // Both these line are commented out due to compiler... "error: Field is
        // extracted in the parser into multiple containers, but the container
        // slices after the first aren't byte aligned"
        //hdr.cpu.ingress_port       = (bit<16>) cpu_md.port;
        //hdr.cpu.port_lag_index     = (bit<16>) cpu_md.port_lag_index;
        hdr.cpu.ingress_bd         = (bit<16>) cpu_md.bd;
        hdr.cpu.reason_code        = (bit<16>) cpu_md.reason_code;
  #ifndef BUG_11583_WORKAROUND
        hdr.cpu.ether_type         = hdr.outer.ethernet.ether_type; // derek: does this need to be done after reframings? // derek: this line is needed in the code, but get a compiler error!
  #endif
#endif

        transition accept;
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
        hdr.outer.dtel_metadata_1 = {
            0,
            dtel_md.ingress_port,
            0,
            dtel_md.egress_port};
        hdr.outer.dtel_metadata_4 = {
            0,
            dtel_md.timestamp};
        hdr.outer.dtel_drop_report = {
            0,
            dtel_md.qid,
            dtel_md.drop_reason,
            0};
#else
//      eg_md.ingress_timestamp = dtel_md.timestamp; // derek hack
        hdr.outer.dtel_report = {
            0,
            dtel_md.ingress_port,
            0,
            dtel_md.egress_port,
            0,
            dtel_md.qid};
        hdr.outer.dtel_drop_report = {
            dtel_md.drop_reason,
            0};
#endif /* INT_V2 */
        transition accept;
#else
        transition reject;
#endif /* DTEL_ENABLE */
    }

    /* Separate parse state for drop metadata from ingress, in order to set
     * hdr.outer.dtel_report.egress_port to SWITCH_PORT_INVALID */
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
        hdr.outer.dtel_metadata_1 = {
            0,
            dtel_md.ingress_port,
            0,
            SWITCH_PORT_INVALID};
        hdr.outer.dtel_metadata_4 = {
            0,
            dtel_md.timestamp};
        hdr.outer.dtel_drop_report = {
            0,
            dtel_md.qid,
            dtel_md.drop_reason, 
            0};
#else         
//      eg_md.ingress_timestamp = dtel_md.timestamp; // derek hack
        hdr.outer.dtel_report = {
            0,
            dtel_md.ingress_port,
            0,
            SWITCH_PORT_INVALID,
            0,
            dtel_md.qid};
        hdr.outer.dtel_drop_report = {
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
        hdr.outer.dtel_metadata_1 = {
            0,
            dtel_md.ingress_port,
            0,
            dtel_md.egress_port};
        //TODO: Preserve latency as well as quantized latency
        //      and add to mirror metadata
        //hdr.outer.dtel_metadata_2 = {
        //    dtel_md.latency};
        hdr.outer.dtel_metadata_3 = {
            0,
            dtel_md.qid,
            0,
            dtel_md.qdepth};
        hdr.outer.dtel_metadata_4 = {
            0,
            dtel_md.timestamp};
        hdr.outer.dtel_metadata_5 = {
            0,
            dtel_md.egress_timestamp};
#else
//      eg_md.ingress_timestamp = dtel_md.timestamp; // derek hack
        hdr.outer.dtel_report = {
            0,
            dtel_md.ingress_port,
            0,
            dtel_md.egress_port,
            0,
            dtel_md.qid};
        hdr.outer.dtel_switch_local_report = {
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
        eg_md.bypass = SWITCH_EGRESS_BYPASS_ALL;
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
    }


    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////
    // "Outer" Headers / Stack
    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////

    ///////////////////////////////////////////////////////////////////////////
    // Layer2 - Outer (ETH)
    ///////////////////////////////////////////////////////////////////////////

    // todo: Can we implement scope0/1 as single sub-parser, w/ parameters
    //-------------------------------------------------------------------------
    // Scope 0
    //-------------------------------------------------------------------------
    
    state parse_outer_ethernet_scope0 {
        pkt.extract(hdr.outer.ethernet);
#ifdef CPU_HDR_ADDED_IN_PARSER
        hdr.cpu.ether_type = hdr.outer.ethernet.ether_type;
#endif
#if defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
        eg_md.lkp_1.mac_src_addr = hdr.outer.ethernet.src_addr;
        eg_md.lkp_1.mac_dst_addr = hdr.outer.ethernet.dst_addr;
        eg_md.lkp_1.mac_type     = hdr.outer.ethernet.ether_type;
#endif // defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)

        transition select(hdr.outer.ethernet.ether_type) {

#ifdef ETAG_ENABLE
            ETHERTYPE_BR : parse_outer_br_scope0;
#endif // ETAG_ENABLE
#ifdef VNTAG_ENABLE
            ETHERTYPE_VN : parse_outer_vn_scope0;
#endif // VNTAG_ENABLE
            ETHERTYPE_VLAN : parse_outer_vlan_0_scope0;
            ETHERTYPE_QINQ : parse_outer_vlan_0_scope0;
#ifdef MPLS_ENABLE
            ETHERTYPE_MPLS : parse_outer_mpls_scope0;
#endif // MPLS_ENABLE
            ETHERTYPE_IPV4 : parse_outer_ipv4_scope0;
            ETHERTYPE_IPV6 : parse_outer_ipv6_scope0;
            default : accept;
        }
    }

#ifdef ETAG_ENABLE
    state parse_outer_br_scope0 {
	    pkt.extract(hdr.outer.e_tag);
#if defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
        eg_md.lkp_1.mac_type = hdr.outer.e_tag.ether_type;        
        //eg_md.lkp_1.pcp = hdr.outer.e_tag.pcp;  // do not populate w/ e-tag
#endif // defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
        transition select(hdr.outer.e_tag.ether_type) {
            ETHERTYPE_VLAN : parse_outer_vlan_0_scope0;
            ETHERTYPE_QINQ : parse_outer_vlan_0_scope0;
#ifdef MPLS_ENABLE
            ETHERTYPE_MPLS : parse_outer_mpls_scope0;
#endif // MPLS_ENABLE
            ETHERTYPE_IPV4 : parse_outer_ipv4_scope0;
            ETHERTYPE_IPV6 : parse_outer_ipv6_scope0;
            default : accept;
        }
    }
#endif // ETAG_ENABLE

#ifdef VNTAG_ENABLE    
    state parse_outer_vn_scope0 {
	    pkt.extract(hdr.outer.vn_tag);
#if defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
        eg_md.lkp_1.mac_type = hdr.outer.vn_tag.ether_type;
#endif // defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
        transition select(hdr.outer.vn_tag.ether_type) {
            ETHERTYPE_VLAN : parse_outer_vlan_0_scope0;
            ETHERTYPE_QINQ : parse_outer_vlan_0_scope0;
#ifdef MPLS_ENABLE
            ETHERTYPE_MPLS : parse_outer_mpls_scope0;
#endif // MPLS_ENABLE
            ETHERTYPE_IPV4 : parse_outer_ipv4_scope0;
            ETHERTYPE_IPV6 : parse_outer_ipv6_scope0;
            default : accept;
        }
    }
#endif // VNTAG_ENABLE

    state parse_outer_vlan_0_scope0 {
	    pkt.extract(hdr.outer.vlan_tag[0]);
#if defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
        eg_md.lkp_1.pcp = hdr.outer.vlan_tag[0].pcp;
  #ifdef SF_2_L2_VLAN_ID_ENABLE
		eg_md.lkp_1.vid = hdr.outer.vlan_tag[0].vid;
  #endif
        eg_md.lkp_1.mac_type = hdr.outer.vlan_tag[0].ether_type;

  #ifndef SF_2_L2_VLAN_ID_ENABLE
        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_VLAN;
        //eg_md.lkp_1.tunnel_id[11:0] = hdr.outer.vlan_tag[0].vid;
        //eg_md.lkp_1.tunnel_id = (bit<switch_tunnel_id_width>)hdr.outer.vlan_tag[0].vid;
  #endif
#endif // defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
        transition select(hdr.outer.vlan_tag[0].ether_type) {
            ETHERTYPE_VLAN : parse_outer_vlan_1_scope0;
            ETHERTYPE_QINQ : parse_outer_vlan_1_scope0;
#ifdef MPLS_ENABLE
            ETHERTYPE_MPLS : parse_outer_mpls_scope0;
#endif // MPLS_ENABLE
            ETHERTYPE_IPV4 : parse_outer_ipv4_scope0;
            ETHERTYPE_IPV6 : parse_outer_ipv6_scope0;
            default : accept;
        }
    }

    state parse_outer_vlan_1_scope0 {
	    pkt.extract(hdr.outer.vlan_tag[1]);
        
#if defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
        eg_md.lkp_1.mac_type = hdr.outer.vlan_tag[1].ether_type;
  #ifndef SF_2_L2_VLAN_ID_ENABLE
        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_VLAN;
  #endif
#endif // defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
        transition select(hdr.outer.vlan_tag[1].ether_type) {
#ifdef MPLS_ENABLE
            ETHERTYPE_MPLS : parse_outer_mpls_scope0;
#endif // MPLS_ENABLE
            ETHERTYPE_IPV4 : parse_outer_ipv4_scope0;
            ETHERTYPE_IPV6 : parse_outer_ipv6_scope0;
            default : accept;
        }
    }
    
    
    // todo: Can we implement scope0/1 as single sub-parser, w/ parameters
    //-------------------------------------------------------------------------
    // Scope 1
    //-------------------------------------------------------------------------
    
    state parse_outer_ethernet_scope1 {
        pkt.extract(hdr.outer.ethernet);
#ifdef CPU_HDR_ADDED_IN_PARSER
        hdr.cpu.ether_type = hdr.outer.ethernet.ether_type;
#endif

// populate for L3-tunnel case (where there's no L2 present)
#if defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
        eg_md.lkp_1.mac_src_addr = hdr.outer.ethernet.src_addr;
        eg_md.lkp_1.mac_dst_addr = hdr.outer.ethernet.dst_addr;
        eg_md.lkp_1.mac_type     = hdr.outer.ethernet.ether_type;
#endif // defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)

        transition select(hdr.outer.ethernet.ether_type) {

#ifdef ETAG_ENABLE
            ETHERTYPE_BR : parse_outer_br_scope1;
#endif // ETAG_ENABLE

#ifdef VNTAG_ENABLE
            ETHERTYPE_VN : parse_outer_vn_scope1;
#endif // VNTAG_ENABLE

            ETHERTYPE_VLAN : parse_outer_vlan_0_scope1;
            ETHERTYPE_QINQ : parse_outer_vlan_0_scope1;
#ifdef MPLS_ENABLE
            ETHERTYPE_MPLS : parse_outer_mpls_scope1;
#endif // MPLS_ENABLE
            ETHERTYPE_IPV4 : parse_outer_ipv4_scope1;
            ETHERTYPE_IPV6 : parse_outer_ipv6_scope1;
            default : accept;
        }
    }

#ifdef ETAG_ENABLE
    state parse_outer_br_scope1 {
	    pkt.extract(hdr.outer.e_tag);

// populate for L3-tunnel case (where there's no L2 present)
#if defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
        eg_md.lkp_1.mac_type = hdr.outer.e_tag.ether_type;        
#endif // defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
        
        transition select(hdr.outer.e_tag.ether_type) {
            ETHERTYPE_VLAN : parse_outer_vlan_0_scope1;
            ETHERTYPE_QINQ : parse_outer_vlan_0_scope1;
#ifdef MPLS_ENABLE
            ETHERTYPE_MPLS : parse_outer_mpls_scope1;
#endif // MPLS_ENABLE
            ETHERTYPE_IPV4 : parse_outer_ipv4_scope1;
            ETHERTYPE_IPV6 : parse_outer_ipv6_scope1;
            default : accept;
        }
    }
#endif // ETAG_ENABLE

#ifdef VNTAG_ENABLE
    state parse_outer_vn_scope1 {
	    pkt.extract(hdr.outer.vn_tag);

// populate for L3-tunnel case (where there's no L2 present)
#if defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
        eg_md.lkp_1.mac_type = hdr.outer.vn_tag.ether_type;
#endif // defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
        
        transition select(hdr.outer.vn_tag.ether_type) {
            ETHERTYPE_VLAN : parse_outer_vlan_0_scope1;
            ETHERTYPE_QINQ : parse_outer_vlan_0_scope1;
#ifdef MPLS_ENABLE
            ETHERTYPE_MPLS : parse_outer_mpls_scope1;
#endif // MPLS_ENABLE
            ETHERTYPE_IPV4 : parse_outer_ipv4_scope1;
            ETHERTYPE_IPV6 : parse_outer_ipv6_scope1;
            default : accept;
        }
    }
#endif // VNTAG_ENABLE


    state parse_outer_vlan_0_scope1 {
	    pkt.extract(hdr.outer.vlan_tag[0]);

// populate for L3-tunnel case (where there's no L2 present)
#if defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
        eg_md.lkp_1.pcp = hdr.outer.vlan_tag[0].pcp;
  #ifdef SF_2_L2_VLAN_ID_ENABLE
		eg_md.lkp_1.vid = hdr.outer.vlan_tag[0].vid;
  #endif
        eg_md.lkp_1.mac_type = hdr.outer.vlan_tag[0].ether_type;

  #ifndef SF_2_L2_VLAN_ID_ENABLE
        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_VLAN;
        //eg_md.lkp_1.tunnel_id[11:0] = hdr.outer.vlan_tag[0].vid;
        //eg_md.lkp_1.tunnel_id = (bit<switch_tunnel_id_width>)hdr.outer.vlan_tag[0].vid;
  #endif
#endif // defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
        
        transition select(hdr.outer.vlan_tag[0].ether_type) {
            ETHERTYPE_VLAN : parse_outer_vlan_1_scope1;
            ETHERTYPE_QINQ : parse_outer_vlan_1_scope1;
#ifdef MPLS_ENABLE
            ETHERTYPE_MPLS : parse_outer_mpls_scope1;
#endif // MPLS_ENABLE
            ETHERTYPE_IPV4 : parse_outer_ipv4_scope1;
            ETHERTYPE_IPV6 : parse_outer_ipv6_scope1;
            default : accept;
        }
    }


    state parse_outer_vlan_1_scope1 {
	    pkt.extract(hdr.outer.vlan_tag[1]);

#if defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
        eg_md.lkp_1.mac_type = hdr.outer.vlan_tag[1].ether_type;
  #ifndef SF_2_L2_VLAN_ID_ENABLE
        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_VLAN;
  #endif
#endif // defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)        
        
        transition select(hdr.outer.vlan_tag[1].ether_type) {
#ifdef MPLS_ENABLE
            ETHERTYPE_MPLS : parse_outer_mpls_scope1;
#endif // MPLS_ENABLE
            ETHERTYPE_IPV4 : parse_outer_ipv4_scope1;
            ETHERTYPE_IPV6 : parse_outer_ipv6_scope1;
            default : accept;
        }
    }


    
    ///////////////////////////////////////////////////////////////////////////
    // Layer 3 - Outer
    ///////////////////////////////////////////////////////////////////////////

    //-------------------------------------------------------------------------
    // Scope 0
    //-------------------------------------------------------------------------
    
    state parse_outer_ipv4_scope0 {
        pkt.extract(hdr.outer.ipv4);
        protocol_outer = hdr.outer.ipv4.protocol;
#if defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
        // todo: should the lkp struct be set only if no frag and options?
        eg_md.lkp_1.ip_type       = SWITCH_IP_TYPE_IPV4;
        eg_md.lkp_1.ip_proto      = hdr.outer.ipv4.protocol;
        eg_md.lkp_1.ip_tos        = hdr.outer.ipv4.tos;
        eg_md.lkp_1.ip_flags      = hdr.outer.ipv4.flags;
        eg_md.lkp_1.ip_src_addr   = (bit<128>)hdr.outer.ipv4.src_addr;
        eg_md.lkp_1.ip_dst_addr   = (bit<128>)hdr.outer.ipv4.dst_addr;
        eg_md.lkp_1.ip_len        = hdr.outer.ipv4.total_len;
#endif // defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
        // Flag packet (to be sent to host) if it's a frag or has options.
        
        transition select(
            hdr.outer.ipv4.ihl,
            hdr.outer.ipv4.frag_offset,
            hdr.outer.ipv4.protocol) {

            (5, 0, IP_PROTOCOLS_ICMP): parse_outer_icmp_igmp_overload_scope0;
            (5, 0, IP_PROTOCOLS_IGMP): parse_outer_icmp_igmp_overload_scope0;
            (5, 0, _): branch_outer_l3_protocol_scope0;
            default: accept;
        }
    }

    state parse_outer_ipv6_scope0 {
#ifdef IPV6_ENABLE
        pkt.extract(hdr.outer.ipv6);
        protocol_outer = hdr.outer.ipv6.next_hdr;
#if defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
        eg_md.lkp_1.ip_type       = SWITCH_IP_TYPE_IPV6;
        eg_md.lkp_1.ip_proto      = hdr.outer.ipv6.next_hdr;
        //eg_md.lkp_1.ip_tos        = hdr.outer.ipv6.tos; // not byte-aligned so set in mau
        eg_md.lkp_1.ip_src_addr   = hdr.outer.ipv6.src_addr;
        eg_md.lkp_1.ip_dst_addr   = hdr.outer.ipv6.dst_addr;
        eg_md.lkp_1.ip_len        = hdr.outer.ipv6.payload_len;
#endif // defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)

        transition select(hdr.outer.ipv6.next_hdr) {
            IP_PROTOCOLS_ICMPV6: parse_outer_icmp_igmp_overload_scope0;
            default: branch_outer_l3_protocol_scope0;
        }
#else
        transition reject;
#endif // IPV6_ENABLE
    }

    // shared fanout/branch state to save tcam resource
    state branch_outer_l3_protocol_scope0 {
        transition select(protocol_outer) {
           IP_PROTOCOLS_IPV4: parse_outer_ipinip_set_tunnel_type_scope0;
           IP_PROTOCOLS_IPV6: parse_outer_ipv6inip_set_tunnel_type_scope0;
           IP_PROTOCOLS_UDP: parse_outer_udp_scope0;
           IP_PROTOCOLS_TCP: parse_outer_tcp_scope0;
           IP_PROTOCOLS_SCTP: parse_outer_sctp_scope0;
           IP_PROTOCOLS_GRE: parse_outer_gre_scope0;
           IP_PROTOCOLS_ESP: parse_outer_esp_overload_scope0;
           default: accept;
       }
    }
    

    //-------------------------------------------------------------------------
    // Scope 1
    //-------------------------------------------------------------------------
    
    state parse_outer_ipv4_scope1 {
        pkt.extract(hdr.outer.ipv4);
        protocol_outer = hdr.outer.ipv4.protocol;
        // Flag packet (to be sent to host) if it's a frag or has options.
        transition select(
            hdr.outer.ipv4.ihl,
            hdr.outer.ipv4.frag_offset) {

            (5, 0): branch_outer_l3_protocol_scope1;
            default: accept;
        }
    }    

    state parse_outer_ipv6_scope1 {
#ifdef IPV6_ENABLE
        pkt.extract(hdr.outer.ipv6);
        protocol_outer = hdr.outer.ipv6.next_hdr;
        transition branch_outer_l3_protocol_scope1;
#else
        transition reject;
#endif // IPV6_ENABLE
    }
    
    // shared fanout/branch state to save tcam resource
    state branch_outer_l3_protocol_scope1 {
        transition select(protocol_outer) {
           IP_PROTOCOLS_IPV4: parse_outer_ipinip_set_tunnel_type_scope1;
           IP_PROTOCOLS_IPV6: parse_outer_ipv6inip_set_tunnel_type_scope1;
           IP_PROTOCOLS_UDP: parse_outer_udp_scope1;
           IP_PROTOCOLS_TCP: parse_outer_tcp_scope1;
           IP_PROTOCOLS_SCTP: parse_outer_sctp_scope1;
           IP_PROTOCOLS_GRE: parse_outer_gre_scope1;
           default: accept;
       }
    }
    
        
    // For ICMP and IGMP, we're not actually extracting the header;
    // We're simply over-loading L4-port info for policy via lookahead.    
    state parse_outer_icmp_igmp_overload_scope0 {
#ifdef PARSER_L4_PORT_OVERLOAD   
#if defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
        eg_md.lkp_1.l4_src_port = pkt.lookahead<bit<16>>();
#endif // defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
#endif // PARSER_L4_PORT_OVERLOAD
        transition accept;
    }


    
    ///////////////////////////////////////////////////////////////////////////
    // Layer 4 - Outer
    ///////////////////////////////////////////////////////////////////////////

    //-------------------------------------------------------------------------
    // User Datagram Protocol (UDP) - Outer
    //-------------------------------------------------------------------------

    state parse_outer_udp_scope0 {
        pkt.extract(hdr.outer.udp);
        
#if defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
        eg_md.lkp_1.l4_src_port = hdr.outer.udp.src_port;
        eg_md.lkp_1.l4_dst_port = hdr.outer.udp.dst_port;  
#endif // defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)

        transition select(hdr.outer.udp.src_port, hdr.outer.udp.dst_port) {

#ifdef VXLAN_ENABLE
            (_, UDP_PORT_VXLAN): parse_outer_vxlan_scope0;
#endif // VXLAN_ENABLE
            
#ifdef GTP_ENABLE
            (_, UDP_PORT_GTP_C): parse_outer_gtp_c_scope0;
            (UDP_PORT_GTP_C, _): parse_outer_gtp_c_scope0;
            (_, UDP_PORT_GTP_U): parse_outer_gtp_u_scope0;
            (UDP_PORT_GTP_U, _): parse_outer_gtp_u_scope0;
            // (UDP_PORT_GTP_C, UDP_PORT_GTP_C): parse_outer_gtp_c_scope0;
            // (UDP_PORT_GTP_U, UDP_PORT_GTP_U): parse_outer_gtp_u_scope0;
#endif // GTP_ENABLE
            default : accept;
        }
    }

    state parse_outer_udp_scope1 {
        pkt.extract(hdr.outer.udp);
        transition select(hdr.outer.udp.src_port, hdr.outer.udp.dst_port) {
            
#ifdef VXLAN_ENABLE
            (_, UDP_PORT_VXLAN): parse_outer_vxlan_scope1;
#endif // VXLAN_ENABLE

#ifdef GTP_ENABLE
            (_, UDP_PORT_GTP_C): parse_outer_gtp_c_scope1;
            (UDP_PORT_GTP_C, _): parse_outer_gtp_c_scope1;
            (_, UDP_PORT_GTP_U): parse_outer_gtp_u_scope1;
            (UDP_PORT_GTP_U, _): parse_outer_gtp_u_scope1;
            // (UDP_PORT_GTP_C, UDP_PORT_GTP_C): parse_outer_gtp_c_scope1;
            // (UDP_PORT_GTP_U, UDP_PORT_GTP_U): parse_outer_gtp_u_scope1;
#endif // GTP_ENABLE
            default : accept;
        }
    }
            
    //-------------------------------------------------------------------------
    // Transmission Control Protocol (TCP) - Outer
    //-------------------------------------------------------------------------

    state parse_outer_tcp_scope0 {
        pkt.extract(hdr.outer.tcp);
#if defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
        eg_md.lkp_1.l4_src_port = hdr.outer.tcp.src_port;
        eg_md.lkp_1.l4_dst_port = hdr.outer.tcp.dst_port;
        eg_md.lkp_1.tcp_flags   = hdr.outer.tcp.flags;
#endif // defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
        transition accept;
    }

    state parse_outer_tcp_scope1 {
        pkt.extract(hdr.outer.tcp);
        transition accept;
    }
            
    //-------------------------------------------------------------------------
    // Stream Control Transmission Protocol (SCTP) - Outer
    //-------------------------------------------------------------------------

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

    ///////////////////////////////////////////////////////////////////////////////
    // Layer X - Outer
    ///////////////////////////////////////////////////////////////////////////////

    //-------------------------------------------------------------------------
    // Multi-Protocol Label Switching (MPLS) - Outer
    //-------------------------------------------------------------------------
        
#if defined(MPLS_ENABLE) || defined(MPLSoGRE_ENABLE)

    // Set tunnel info for outermost label only
    state parse_outer_mpls_scope0 {
#if defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_MPLS;

        // error: Inferred incompatible container alignments for field
        // ingress::ig_md.lkp_1.tunnel_id: alignment = 0 != alignment = 4 (little endian)
        //eg_md.lkp_1.tunnel_id = (bit<switch_tunnel_id_width>)pkt.lookahead<mpls_h>().label;
        eg_md.lkp_1.tunnel_id = pkt.lookahead<bit<32>>();
#endif // defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
        transition extract_outer_mpls_scope0;
    }
    
    state extract_outer_mpls_scope0 {
    //state parse_outer_mpls_scope0 {
    	pkt.extract(hdr.outer.mpls.next);
        transition select(hdr.outer.mpls.last.bos, pkt.lookahead<bit<4>>()) {
            (0, _): parse_outer_mpls_scope0;
            (1, 4): parse_inner_ipv4_scope0;
            (1, 6): parse_inner_ipv6_scope0;
            default: parse_outer_eompls_scope0;
        }
    }
    
    state parse_outer_eompls_scope0 {
        pkt.extract(hdr.outer.mpls_pw_cw); 
        transition parse_inner_ethernet_scope0;
    }


     // Set tunnel info for outermost label only
    state parse_outer_mpls_scope1 {
        eg_md.lkp_1.tunnel_inner_type = SWITCH_TUNNEL_TYPE_MPLS; // note: inner here means "current scope - 1"
        transition extract_outer_mpls_scope1;
    }
       
    state extract_outer_mpls_scope1 {
    //state parse_outer_mpls_scope1 {
    	pkt.extract(hdr.outer.mpls.next);
        transition select(hdr.outer.mpls.last.bos, pkt.lookahead<bit<4>>()) {
            (0, _): parse_outer_mpls_scope1;
            (1, 4): parse_inner_ipv4_scope1;
            (1, 6): parse_inner_ipv6_scope1;
            default: parse_outer_eompls_scope1;
        }
    }
    
    state parse_outer_eompls_scope1 {
        pkt.extract(hdr.outer.mpls_pw_cw); 
        transition parse_inner_ethernet_scope1;
    }
            
#endif  // defined(MPLS_ENABLE) || defined(MPLSoGRE_ENABLE)



    ///////////////////////////////////////////////////////////////////////////
    // Tunnels - Outer
    ///////////////////////////////////////////////////////////////////////////

#ifdef VXLAN_ENABLE
    
    //-------------------------------------------------------------------------
    // Virtual Extensible Local Area Network (VXLAN) - Outer
    //-------------------------------------------------------------------------

    state parse_outer_vxlan_scope0 {
        pkt.extract(hdr.outer.vxlan);
#if defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_VXLAN;
        eg_md.lkp_1.tunnel_id = (bit<switch_tunnel_id_width>)hdr.outer.vxlan.vni;
#endif // defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
        transition parse_inner_ethernet_scope0;
    }

    state parse_outer_vxlan_scope1 {
        pkt.extract(hdr.outer.vxlan);
        eg_md.lkp_1.tunnel_inner_type = SWITCH_TUNNEL_TYPE_VXLAN; // note: inner here means "current scope - 1"
        transition parse_inner_ethernet_scope1;
    }

#endif // VXLAN_ENABLE

            
    //-------------------------------------------------------------------------
    // Internet Protocol (IP) - Outer
    //-------------------------------------------------------------------------

    state parse_outer_ipinip_set_tunnel_type_scope0 {
#ifdef IPINIP
#if defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_IPINIP;
        eg_md.lkp_1.tunnel_id = 0;
#endif // defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
        transition parse_inner_ipv4_scope0;
#else
        transition reject;
#endif // IPINIP
    }

    state parse_outer_ipv6inip_set_tunnel_type_scope0 {
#ifdef IPINIP
#if defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_IPINIP;
        eg_md.lkp_1.tunnel_id = 0;
#endif // defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
        transition parse_inner_ipv6_scope0;
#else
        transition reject;
#endif // IPINIP
    }


    state parse_outer_ipinip_set_tunnel_type_scope1 {
#ifdef IPINIP
        eg_md.lkp_1.tunnel_inner_type = SWITCH_TUNNEL_TYPE_IPINIP; // note: inner here means "current scope - 1"
        transition parse_inner_ipv4_scope1;
#else
        transition reject;
#endif // IPINIP
    }

    state parse_outer_ipv6inip_set_tunnel_type_scope1 {
#ifdef IPINIP
        eg_md.lkp_1.tunnel_inner_type = SWITCH_TUNNEL_TYPE_IPINIP; // note: inner here means "current scope - 1"
        transition parse_inner_ipv6_scope1;
#else
        transition reject;
#endif // IPINIP
    }


            
    //-------------------------------------------------------------------------
    // Generic Routing Encapsulation (GRE) - Outer
    //-------------------------------------------------------------------------

    state parse_outer_gre_scope0 {    
        pkt.extract(hdr.outer.gre);
#if defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_GRE;
        eg_md.lkp_1.tunnel_id = 0;
#endif // defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)

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
            (0,0,1,0,0,0,0,0,GRE_PROTOCOLS_NVGRE): parse_outer_nvgre_scope0;
#endif // NVGRE_ENABLE
            (0,0,0,0,0,0,0,0,ETHERTYPE_IPV4): parse_inner_ipv4_scope0;
            (0,0,0,0,0,0,0,0,ETHERTYPE_IPV6): parse_inner_ipv6_scope0;
#ifdef MPLSoGRE_ENABLE
            (0,0,0,0,0,0,0,0,ETHERTYPE_MPLS): parse_outer_mpls_scope0;
#endif // MPLSoGRE_ENABLE            
            (1,0,0,0,0,0,0,0,_): parse_outer_gre_optional_scope0;
            (0,0,1,0,0,0,0,0,_): parse_outer_gre_optional_scope0;
            (0,0,0,1,0,0,0,0,_): parse_outer_gre_optional_scope0;
            default: accept;
        }
    }

    state parse_outer_gre_scope1 {    
        pkt.extract(hdr.outer.gre);
        eg_md.lkp_1.tunnel_inner_type = SWITCH_TUNNEL_TYPE_GRE; // note: inner here means "current scope - 1"

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
            (0,0,1,0,0,0,0,0,GRE_PROTOCOLS_NVGRE): parse_outer_nvgre_scope1;
#endif // NVGRE_ENABLE
            (0,0,0,0,0,0,0,0,ETHERTYPE_IPV4): parse_inner_ipv4_scope1;
            (0,0,0,0,0,0,0,0,ETHERTYPE_IPV6): parse_inner_ipv6_scope1;            
#ifdef MPLSoGRE_ENABLE
            (0,0,0,0,0,0,0,0,ETHERTYPE_MPLS): parse_outer_mpls_scope1;
#endif // MPLSoGRE_ENABLE            
            (1,0,0,0,0,0,0,0,_): parse_outer_gre_optional_scope1;
            (0,0,1,0,0,0,0,0,_): parse_outer_gre_optional_scope1;
            (0,0,0,1,0,0,0,0,_): parse_outer_gre_optional_scope1;
            default: accept;
        }
    }

    
    state parse_outer_gre_optional_scope0 {    
        pkt.extract(hdr.outer.gre_optional);  
        transition select(hdr.outer.gre.proto) {

            ETHERTYPE_IPV4: parse_inner_ipv4_scope0;
            ETHERTYPE_IPV6: parse_inner_ipv6_scope0;                        
#ifdef MPLSoGRE_ENABLE
            ETHERTYPE_MPLS: parse_outer_mpls_scope0;
#endif // MPLSoGRE_ENABLE            
            default: accept;
        }
    }

    state parse_outer_gre_optional_scope1 {    
        pkt.extract(hdr.outer.gre_optional);  
        transition select(hdr.outer.gre.proto) {

            ETHERTYPE_IPV4: parse_inner_ipv4_scope1;
            ETHERTYPE_IPV6: parse_inner_ipv6_scope1;                        
#ifdef MPLSoGRE_ENABLE
            ETHERTYPE_MPLS: parse_outer_mpls_scope1;
#endif // MPLSoGRE_ENABLE            
            default: accept;
        }
    }

    
    
#ifdef NVGRE_ENABLE
    //-------------------------------------------------------------------------
    // Network Virtualization using GRE (NVGRE) - Outer
    //-------------------------------------------------------------------------

    state parse_outer_nvgre_scope0 {
    	pkt.extract(hdr.outer.nvgre);
        eg_md.tunnel_1.nvgre_flow_id = hdr.outer.nvgre.flow_id; //todo: ingress-only in switch
#if defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_NVGRE;
        eg_md.lkp_1.tunnel_id = (bit<switch_tunnel_id_width>)hdr.outer.nvgre.vsid;
#endif // defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
    	transition parse_inner_ethernet_scope0;
    }

    state parse_outer_nvgre_scope1 {
    	pkt.extract(hdr.outer.nvgre);
        eg_md.tunnel_1.nvgre_flow_id = hdr.outer.nvgre.flow_id; //todo: ingress-only in switch
        eg_md.lkp_1.tunnel_inner_type = SWITCH_TUNNEL_TYPE_NVGRE; // note: inner here means "current scope - 1"
    	transition parse_inner_ethernet_scope1;
    }
#endif // NVGRE_ENABLE


    //-------------------------------------------------------------------------
    // Encapsulating Security Payload (ESP) - Outer
    //-------------------------------------------------------------------------
    
    state parse_outer_esp_overload_scope0 {
#ifdef PARSER_L4_PORT_OVERLOAD   
#if defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
         eg_md.lkp_1.l4_src_port = pkt.lookahead<esp_h>().spi_hi;
         eg_md.lkp_1.l4_dst_port = pkt.lookahead<esp_h>().spi_lo;
#endif // defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
#endif // PARSER_L4_PORT_OVERLOAD
        transition accept;
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

    state parse_outer_gtp_c_scope0 {
        transition select(
            pkt.lookahead<gtp_v2_base_h>().version,
            pkt.lookahead<gtp_v2_base_h>().T
        ) {
            (2, 1): extract_outer_gtp_c_scope0;
            default: accept;
        }
    }

    state extract_outer_gtp_c_scope0 {
#if defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_GTPC;
        eg_md.lkp_1.tunnel_id = pkt.lookahead<gtp_v2_base_h>().teid;
#endif // defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
    	transition accept;
    }

    state parse_outer_gtp_c_scope1 {
        transition select(
            pkt.lookahead<gtp_v2_base_h>().version,
            pkt.lookahead<gtp_v2_base_h>().T
        ) {
            (2, 1): extract_outer_gtp_c_scope1;
            default: accept;
        }
    }

    state extract_outer_gtp_c_scope1 {
        eg_md.lkp_1.tunnel_inner_type = SWITCH_TUNNEL_TYPE_GTPC; // note: inner here means "current scope - 1"
    	transition accept;
    }


    // GTP-U
    //-------------------------------------------------------------------------
    // Only supports optional header for sequence-number
    // Does not support parsing (TLV) extension headers

    state parse_outer_gtp_u_scope0 {
        gtp_v1_base_h snoop_gtp_v1_base = pkt.lookahead<gtp_v1_base_h>();
        transition select(
            snoop_gtp_v1_base.version,
            snoop_gtp_v1_base.PT,
            snoop_gtp_v1_base.E,
            snoop_gtp_v1_base.S,
            snoop_gtp_v1_base.PN) {

            (1, 1, 0, 0, 0): extract_outer_gtp_u_scope0;
            (1, 1, 0, 1, 0): extract_outer_gtp_u_with_optional_scope0;            
            default: accept;
        }
    }

    state extract_outer_gtp_u_scope0 {
        pkt.extract(hdr.outer.gtp_v1_base);
#if defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_GTPU;
        eg_md.lkp_1.tunnel_id = hdr.outer.gtp_v1_base.teid;
#endif // defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
        transition select(pkt.lookahead<bit<4>>()) {
            4: parse_inner_ipv4_scope0;
            6: parse_inner_ipv6_scope0;
            default: accept;
        }
    }

    state extract_outer_gtp_u_with_optional_scope0 {
        pkt.extract(hdr.outer.gtp_v1_base);
        pkt.extract(hdr.outer.gtp_v1_optional);
#if defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_GTPU;
        eg_md.lkp_1.tunnel_id = hdr.outer.gtp_v1_base.teid;
#endif // defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
        transition select(
            hdr.outer.gtp_v1_base.E,
            pkt.lookahead<bit<4>>()) {
            (0, 4): parse_inner_ipv4_scope0;
            (0, 6): parse_inner_ipv6_scope0;
            default: accept;
        }
    }    

    
    state parse_outer_gtp_u_scope1 {
        gtp_v1_base_h snoop_gtp_v1_base = pkt.lookahead<gtp_v1_base_h>();
        transition select(
            snoop_gtp_v1_base.version,
            snoop_gtp_v1_base.PT,
            snoop_gtp_v1_base.E,
            snoop_gtp_v1_base.S,
            snoop_gtp_v1_base.PN) {

            (1, 1, 0, 0, 0): extract_outer_gtp_u_scope1;
            (1, 1, 0, 1, 0): extract_outer_gtp_u_with_optional_scope1;
            default: accept;
        }
    }

    state extract_outer_gtp_u_scope1 {
        pkt.extract(hdr.outer.gtp_v1_base);
        eg_md.lkp_1.tunnel_inner_type = SWITCH_TUNNEL_TYPE_GTPU; // note: inner here means "current scope - 1"
        transition select(pkt.lookahead<bit<4>>()) {
            4: parse_inner_ipv4_scope1;
            6: parse_inner_ipv6_scope1;
            default: accept;
        }
    }

    state extract_outer_gtp_u_with_optional_scope1 {
        pkt.extract(hdr.outer.gtp_v1_base);
        pkt.extract(hdr.outer.gtp_v1_optional);
        eg_md.lkp_1.tunnel_inner_type = SWITCH_TUNNEL_TYPE_GTPU; // note: inner here means "current scope - 1"
        transition select(
            hdr.outer.gtp_v1_base.E,
            pkt.lookahead<bit<4>>()) {
            (0, 4): parse_inner_ipv4_scope1;
            (0, 6): parse_inner_ipv6_scope1;
            default: accept;
        }
    }    
    
#endif  // GTP_ENABLE



    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////
    // "Inner" Headers / Stack
    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////

    ///////////////////////////////////////////////////////////////////////////
    // Layer 2 (ETH-T) - Inner
    ///////////////////////////////////////////////////////////////////////////

    //-------------------------------------------------------------------------
    // Scope 0
    //-------------------------------------------------------------------------
            
    state parse_inner_ethernet_scope0 {
        pkt.extract(hdr.inner.ethernet);
        transition select(hdr.inner.ethernet.ether_type) {
            ETHERTYPE_VLAN : parse_inner_vlan_scope0;
            ETHERTYPE_IPV4 : parse_inner_ipv4_scope0;
            ETHERTYPE_IPV6 : parse_inner_ipv6_scope0;
            default : accept;
        }
    }

    state parse_inner_vlan_scope0 {
        pkt.extract(hdr.inner.vlan_tag[0]);
        transition select(hdr.inner.vlan_tag[0].ether_type) {
            ETHERTYPE_IPV4 : parse_inner_ipv4_scope0;
            ETHERTYPE_IPV6 : parse_inner_ipv6_scope0;
            default : accept;
        }
    }

    //-------------------------------------------------------------------------
    // Scope 1
    //-------------------------------------------------------------------------            

    state parse_inner_ethernet_scope1 {
        pkt.extract(hdr.inner.ethernet);
        
        eg_md.lkp_1.mac_src_addr = hdr.inner.ethernet.src_addr;
        eg_md.lkp_1.mac_dst_addr = hdr.inner.ethernet.dst_addr;
        eg_md.lkp_1.mac_type = hdr.inner.ethernet.ether_type;
        eg_md.lkp_1.pcp = 0;
        eg_md.lkp_1.vid = 0;
        
        transition select(hdr.inner.ethernet.ether_type) {
            ETHERTYPE_VLAN : parse_inner_vlan_scope1;
            ETHERTYPE_IPV4 : parse_inner_ipv4_scope1;
            ETHERTYPE_IPV6 : parse_inner_ipv6_scope1;
            default : accept;
        }
    }

    state parse_inner_vlan_scope1 {
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
            ETHERTYPE_IPV4 : parse_inner_ipv4_scope1;
            ETHERTYPE_IPV6 : parse_inner_ipv6_scope1;
            default : accept;
        }
    }

            

    ///////////////////////////////////////////////////////////////////////////
    // Layer 3 - Inner
    ///////////////////////////////////////////////////////////////////////////

    //-------------------------------------------------------------------------
    // Scope 0
    //-------------------------------------------------------------------------            

    state parse_inner_ipv4_scope0 {
        pkt.extract(hdr.inner.ipv4);
        protocol_inner = hdr.inner.ipv4.protocol;
            transition select(
                hdr.inner.ipv4.ihl,
                hdr.inner.ipv4.frag_offset) {

           (5, 0): branch_inner_l3_protocol_scope0;
           default : accept;
       }
    }

    state parse_inner_ipv6_scope0 {
#ifdef IPV6_ENABLE
        pkt.extract(hdr.inner.ipv6);
        protocol_inner = hdr.inner.ipv6.next_hdr;
        transition branch_inner_l3_protocol_scope0;
#else
        transition reject;
#endif // IPV6_ENABLE
    }

    state branch_inner_l3_protocol_scope0 {
        transition select(protocol_inner) {
           IP_PROTOCOLS_UDP: parse_inner_udp_scope0;
           IP_PROTOCOLS_TCP: parse_inner_tcp_scope0;
           IP_PROTOCOLS_SCTP: parse_inner_sctp_scope0;
#ifdef INNER_GRE_ENABLE
           IP_PROTOCOLS_GRE: parse_inner_gre_scope0;
#endif
           IP_PROTOCOLS_IPV4: parse_inner_ipinip_set_tunnel_type_scope0;
           IP_PROTOCOLS_IPV6: parse_inner_ipv6inip_set_tunnel_type_scope0;
        }
    }
    
            
    //-------------------------------------------------------------------------
    // Scope 1
    //-------------------------------------------------------------------------

    state parse_inner_ipv4_scope1 {
        pkt.extract(hdr.inner.ipv4);
        protocol_inner = hdr.inner.ipv4.protocol;

        // fixup ethertype for ip-n-ip case
        eg_md.lkp_1.mac_type    = ETHERTYPE_IPV4;
        
        // todo: should the lkp struct be set only if no frag and options?
        eg_md.lkp_1.ip_type     = SWITCH_IP_TYPE_IPV4;
        eg_md.lkp_1.ip_proto    = hdr.inner.ipv4.protocol;
        eg_md.lkp_1.ip_tos      = hdr.inner.ipv4.tos;
        eg_md.lkp_1.ip_flags    = hdr.inner.ipv4.flags;
        eg_md.lkp_1.ip_src_addr = (bit<128>)hdr.inner.ipv4.src_addr;
        eg_md.lkp_1.ip_dst_addr = (bit<128>)hdr.inner.ipv4.dst_addr;
        eg_md.lkp_1.ip_len      = hdr.inner.ipv4.total_len;

        // Flag packet (to be sent to host) if it's a frag or has options.
        transition select(
            hdr.inner.ipv4.ihl,
            hdr.inner.ipv4.frag_offset,
            hdr.inner.ipv4.protocol) {
            (5, 0, IP_PROTOCOLS_ICMP): parse_inner_icmp_igmp_overload_scope1;
            (5, 0, IP_PROTOCOLS_IGMP): parse_inner_icmp_igmp_overload_scope1;
            (5, 0, _): branch_inner_l3_protocol_scope1;
            default : accept;
       }
    }

    state parse_inner_ipv6_scope1 {
#ifdef IPV6_ENABLE
        pkt.extract(hdr.inner.ipv6);
        protocol_inner = hdr.inner.ipv6.next_hdr;

        // fixup ethertype for ip-n-ip case
        eg_md.lkp_1.mac_type      = ETHERTYPE_IPV6;

        eg_md.lkp_1.ip_type       = SWITCH_IP_TYPE_IPV6;
        eg_md.lkp_1.ip_proto      = hdr.inner.ipv6.next_hdr;
        //eg_md.lkp_1.ip_tos        = hdr.inner.ipv6.tos; // not byte-aligned so set in mau
        eg_md.lkp_1.ip_src_addr   = hdr.inner.ipv6.src_addr;
        eg_md.lkp_1.ip_dst_addr   = hdr.inner.ipv6.dst_addr;
        eg_md.lkp_1.ip_len        = hdr.inner.ipv6.payload_len;

        transition select(hdr.inner.ipv6.next_hdr) {
            IP_PROTOCOLS_ICMPV6: parse_inner_icmp_igmp_overload_scope1;
            default: branch_inner_l3_protocol_scope1;
        }
#else
        transition reject;
#endif // IPV6_ENABLE
    }

    state branch_inner_l3_protocol_scope1 {
        transition select(protocol_inner) {
           IP_PROTOCOLS_UDP: parse_inner_udp_scope1;
           IP_PROTOCOLS_TCP: parse_inner_tcp_scope1;
           IP_PROTOCOLS_SCTP: parse_inner_sctp_scope1;
#ifdef INNER_GRE_ENABLE
           IP_PROTOCOLS_GRE: parse_inner_gre_scope1;
#endif
           IP_PROTOCOLS_ESP:  parse_inner_esp_overload_scope1;
           IP_PROTOCOLS_IPV4: parse_inner_ipinip_set_tunnel_type_scope1;
           IP_PROTOCOLS_IPV6: parse_inner_ipv6inip_set_tunnel_type_scope1;
        }
    }
    

    // For ICMP and IGMP, we're not actually extracting the header;
    // We're simply over-loading L4-port info for policy via lookahead.    
    state parse_inner_icmp_igmp_overload_scope1 {
#ifdef PARSER_L4_PORT_OVERLOAD   
        eg_md.lkp_1.l4_src_port = pkt.lookahead<bit<16>>();
#endif // PARSER_L4_PORT_OVERLOAD
        transition accept;
    }
    
            
    ///////////////////////////////////////////////////////////////////////////
    // Inner Layer 4 - Inner
    ///////////////////////////////////////////////////////////////////////////

    //-------------------------------------------------------------------------
    // Scope 0
    //-------------------------------------------------------------------------

    state parse_inner_udp_scope0 {
        pkt.extract(hdr.inner.udp);
        transition select(hdr.inner.udp.src_port, hdr.inner.udp.dst_port) {
#ifdef INNER_GTP_ENABLE
            (_, UDP_PORT_GTP_C): parse_inner_gtp_c_scope0;
            (UDP_PORT_GTP_C, _): parse_inner_gtp_c_scope0;
            (_, UDP_PORT_GTP_U): parse_inner_gtp_u_scope0;
            (UDP_PORT_GTP_U, _): parse_inner_gtp_u_scope0;
            // (UDP_PORT_GTP_C, UDP_PORT_GTP_C): parse_inner_gtp_c_scope0;
            // (UDP_PORT_GTP_U, UDP_PORT_GTP_U): parse_inner_gtp_u_scope0;
#endif // INNER_GTP_ENABLE
            default: accept;
        }
    }

    state parse_inner_tcp_scope0 {
        pkt.extract(hdr.inner.tcp);
        transition accept;
    }

    state parse_inner_sctp_scope0 {
        pkt.extract(hdr.inner.sctp);
        transition accept;
    }    

    //-------------------------------------------------------------------------
    // Scope 1
    //-------------------------------------------------------------------------

    state parse_inner_udp_scope1 {
        pkt.extract(hdr.inner.udp);
        eg_md.lkp_1.l4_src_port = hdr.inner.udp.src_port;
        eg_md.lkp_1.l4_dst_port = hdr.inner.udp.dst_port;              
        transition select(
            hdr.inner.udp.src_port,
            hdr.inner.udp.dst_port) {

#ifdef INNER_GTP_ENABLE
            (_, UDP_PORT_GTP_C): parse_inner_gtp_c_scope1;
            (UDP_PORT_GTP_C, _): parse_inner_gtp_c_scope1;
            (_, UDP_PORT_GTP_U): parse_inner_gtp_u_scope1;
            (UDP_PORT_GTP_U, _): parse_inner_gtp_u_scope1;
            // (UDP_PORT_GTP_C, UDP_PORT_GTP_C): parse_inner_gtp_c_scope1;
            // (UDP_PORT_GTP_U, UDP_PORT_GTP_U): parse_inner_gtp_u_scope1;
#endif // INNER_GTP_ENABLE
            default: accept;
        }
    }

    state parse_inner_tcp_scope1 {
        pkt.extract(hdr.inner.tcp);
        eg_md.lkp_1.tcp_flags = hdr.inner.tcp.flags;
        eg_md.lkp_1.l4_src_port = hdr.inner.tcp.src_port;
        eg_md.lkp_1.l4_dst_port = hdr.inner.tcp.dst_port;        
        transition accept;
    }

    state parse_inner_sctp_scope1 {
        pkt.extract(hdr.inner.sctp);
        eg_md.lkp_1.l4_src_port = hdr.inner.sctp.src_port;
        eg_md.lkp_1.l4_dst_port = hdr.inner.sctp.dst_port;              
        transition accept;
    }     


            
    ///////////////////////////////////////////////////////////////////////////
    // Tunnels - Inner
    ///////////////////////////////////////////////////////////////////////////


    //-------------------------------------------------------------------------
    // Internet Protocol (IP) - Inner
    //-------------------------------------------------------------------------

    state parse_inner_ipinip_set_tunnel_type_scope0 {
#ifdef IPINIP
        eg_md.lkp_1.tunnel_inner_type = SWITCH_TUNNEL_TYPE_IPINIP; // note: inner here means "current scope - 1"
        transition parse_inner_inner_ipv4;
#else
        transition reject;
#endif // IPINIP
    }

    state parse_inner_ipv6inip_set_tunnel_type_scope0 {
#ifdef IPINIP
        eg_md.lkp_1.tunnel_inner_type = SWITCH_TUNNEL_TYPE_IPINIP; // note: inner here means "current scope - 1"
        transition parse_inner_inner_ipv6;
#else
        transition reject;
#endif // IPINIP
    }

    
    state parse_inner_ipinip_set_tunnel_type_scope1 {
#ifdef IPINIP
#if defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_IPINIP;
        eg_md.lkp_1.tunnel_id = 0;
#endif // defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
        transition parse_inner_inner_ipv4;
#else
        transition reject;
#endif // IPINIP
    }

    state parse_inner_ipv6inip_set_tunnel_type_scope1 {
#ifdef IPINIP
#if defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_IPINIP;
        eg_md.lkp_1.tunnel_id = 0;
#endif // defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
        transition parse_inner_inner_ipv6;
#else
        transition reject;
#endif // IPINIP
    }


    //-------------------------------------------------------------------------
    // Encapsulating Security Payload (ESP) - Inner
    //-------------------------------------------------------------------------
     
    state parse_inner_esp_overload_scope1 {
#ifdef PARSER_L4_PORT_OVERLOAD   
        eg_md.lkp_1.l4_src_port = pkt.lookahead<esp_h>().spi_hi;
        eg_md.lkp_1.l4_dst_port = pkt.lookahead<esp_h>().spi_lo;
#endif // PARSER_L4_PORT_OVERLOAD
        transition accept;
    }


    //-------------------------------------------------------------------------
    // Generic Routing Encapsulation (GRE) - Inner
    //-------------------------------------------------------------------------
    
#ifdef INNER_GRE_ENABLE
    
    state parse_inner_gre_scope0 {    
        pkt.extract(hdr.inner.gre);
        
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
            default: accept;
        }
    }

    state parse_inner_gre_scope1 {    
        pkt.extract(hdr.inner.gre);
        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_GRE;
        eg_md.lkp_1.tunnel_id = 0;
        
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
            default: accept;
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

    state parse_inner_gtp_c_scope0 {
        transition select(
            pkt.lookahead<gtp_v2_base_h>().version,
            pkt.lookahead<gtp_v2_base_h>().T
        ) {
            (2, 1): extract_inner_gtp_c_scope0;
            default: accept;
        }
    }
    state extract_inner_gtp_c_scope0 {
    	transition accept;
    }


    state parse_inner_gtp_c_scope1 {
        transition select(
            pkt.lookahead<gtp_v2_base_h>().version,
            pkt.lookahead<gtp_v2_base_h>().T
        ) {
            (2, 1): extract_inner_gtp_c_scope1;
            default: accept;
        }
    }
    state extract_inner_gtp_c_scope1 {
        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_GTPC;
        eg_md.lkp_1.tunnel_id = pkt.lookahead<gtp_v2_base_h>().teid;
   	    transition accept;
    }


    // GTP-U
    //-------------------------------------------------------------------------
    // Only supports optional header for sequence-number
    // Does not support parsing (TLV) extension headers

    state parse_inner_gtp_u_scope0 {
        gtp_v1_base_h snoop_inner_gtp_v1_base = pkt.lookahead<gtp_v1_base_h>();
        transition select(
            snoop_inner_gtp_v1_base.version,
            snoop_inner_gtp_v1_base.PT,
            snoop_inner_gtp_v1_base.E,
            snoop_inner_gtp_v1_base.S,
            snoop_inner_gtp_v1_base.PN) {

            (1, 1, 0, 0, 0): extract_inner_gtp_u_scope0;
            (1, 1, 0, 1, 0): extract_inner_gtp_u_with_optional_scope0;
            default: accept;
        }
    }

    state extract_inner_gtp_u_scope0 {
        pkt.extract(hdr.inner.gtp_v1_base);
        transition select(pkt.lookahead<bit<4>>()) {
            4: parse_inner_inner_ipv4;
            6: parse_inner_inner_ipv6;
            default: accept;
        }
    }

    state extract_inner_gtp_u_with_optional_scope0 {
        pkt.extract(hdr.inner.gtp_v1_base);
        pkt.extract(hdr.inner.gtp_v1_optional);
        transition select(
            hdr.inner.gtp_v1_base.E,
            pkt.lookahead<bit<4>>()) {
            (0, 4): parse_inner_inner_ipv4;
            (0, 6): parse_inner_inner_ipv6;
            default: accept;
        }
    }    
    
    
    state parse_inner_gtp_u_scope1 {
        gtp_v1_base_h snoop_inner_gtp_v1_base = pkt.lookahead<gtp_v1_base_h>();
        transition select(
            snoop_inner_gtp_v1_base.version,
            snoop_inner_gtp_v1_base.PT,
            snoop_inner_gtp_v1_base.E,
            snoop_inner_gtp_v1_base.S,
            snoop_inner_gtp_v1_base.PN) {

            (1, 1, 0, 0, 0): extract_inner_gtp_u_scope1;
            (1, 1, 0, 1, 0): extract_inner_gtp_u_with_optional_scope1;
            default: accept;
        }
    }

    state extract_inner_gtp_u_scope1 {
        pkt.extract(hdr.inner.gtp_v1_base);
        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_GTPU;
        eg_md.lkp_1.tunnel_id = hdr.inner.gtp_v1_base.teid;
        transition select(pkt.lookahead<bit<4>>()) {
            4: parse_inner_inner_ipv4;
            6: parse_inner_inner_ipv6;
            default: accept;
        }
    }

    state extract_inner_gtp_u_with_optional_scope1 {
        pkt.extract(hdr.inner.gtp_v1_base);
        pkt.extract(hdr.inner.gtp_v1_optional);
        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_GTPU;
        eg_md.lkp_1.tunnel_id = hdr.inner.gtp_v1_base.teid;
        transition select(
            hdr.inner.gtp_v1_base.E,
            pkt.lookahead<bit<4>>()) {
            (0, 4): parse_inner_inner_ipv4;
            (0, 6): parse_inner_inner_ipv6;
            default: accept;
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
//      eg_md.inner_inner.ipv4_isValid = true;
		transition accept;
    }
    state parse_inner_inner_ipv6 {
		hdr.inner_inner.ipv6.setValid();
//      eg_md.inner_inner.ipv6_isValid = true;
		transition accept;
    }


    
    

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
