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

#ifndef _VALIDATION_
#define _VALIDATION_

// ============================================================================
// Transport Validation
// ============================================================================

control PktValidation(
        in    switch_header_transport_t hdr,    // src
		in    bool ipv4_checksum_err,           // src
		in    switch_tunnel_metadata_t tunnel,  // src
        inout switch_lookup_fields_t lkp,       // dst
        out   switch_drop_reason_t drop_reason  // dst
) {

    const switch_uint32_t table_size = 64;

    // -----------------------------
	// L2
    // -----------------------------

    action malformed_pkt(bit<8> reason) {
        drop_reason = reason;
    }

    action malformed_non_ip_pkt(bit<8> reason) {
        malformed_pkt(reason);
    }

    action valid_unicast_pkt_untagged() {
    }

    action valid_unicast_pkt_tagged() {
    }

    table validate_ethernet {
        key = {
            hdr.ethernet.isValid() : exact;
            hdr.ethernet.src_addr : ternary;
            hdr.ethernet.dst_addr : ternary;
            hdr.vlan_tag[0].isValid() : ternary;
        }

        actions = {
            malformed_non_ip_pkt;
            valid_unicast_pkt_untagged;
            valid_unicast_pkt_tagged;
        }

        size = table_size;
        /* const entries = {
            (_, _, _) : malformed_non_ip_pkt(SWITCH_DROP_SRC_MAC_MULTICAST);
            (0, _, _) : malformed_non_ip_pkt(SWITCH_DROP_SRC_MAC_ZERO);
            (_, 0, _) : malformed_non_ip_pkt(SWITCH_DROP_DST_MAC_ZERO);
        } */
    }

    // -----------------------------
	// L3, v4
    // -----------------------------

#ifdef ERSPAN_TRANSPORT_INGRESS_ENABLE
    action malformed_ipv4_pkt(bit<8> reason) {
        // Set common lookup fields just for dtel acl and hash purposes
        malformed_pkt(reason);
    }

    action valid_ipv4_pkt(switch_ip_frag_t ip_frag) {
        // Set common lookup fields
    }

    table validate_ipv4 {
        key = {
            ipv4_checksum_err : ternary;
            hdr.ipv4.version : ternary;
            hdr.ipv4.ihl : ternary;
            hdr.ipv4.flags : ternary;
            hdr.ipv4.frag_offset : ternary;
            hdr.ipv4.ttl : ternary;
            hdr.ipv4.src_addr[31:24] : ternary;
        }

        actions = {
            valid_ipv4_pkt;
            malformed_ipv4_pkt;
        }

        size = table_size;
    }
#endif /* ERSPAN_TRANSPORT_INGRESS_ENABLE */

// Current encap requirments do not include UDP in the transport stack
//     // -----------------------------
// 	// L4
//     // -----------------------------
// 
//     action set_udp_ports() {
//         lkp.l4_src_port = hdr.udp.src_port;
//         lkp.l4_dst_port = hdr.udp.dst_port;
//     }
// 
//     // Not much of a validation as it only sets the lookup fields.
//     table validate_other {
//         key = {
//             hdr.udp.isValid() : exact;
//         }
// 
//         actions = {
// 			NoAction;
//             set_udp_ports;
//         }
// 
//         const default_action = NoAction;
//         const entries = {
// /*
//             (true, false, false, false, false, false) : set_tcp_ports();
//             (false, true, false, false, false, false) : set_udp_ports();
//             (false, false, true, false, false, false) : set_sctp_ports();
//             (false, false, false, true, false, false) : set_icmp_type();
//             (false, false, false, false, true, false) : set_igmp_type();
//             (false, false, false, false, false, true) : set_arp_opcode();
// */
//             (true) : set_udp_ports();
//         }
//     }
// 
// 
//     // -----------------------------
// 	   // L4
//     // -----------------------------
// 
//     action set_udp_ports() {
//     }
// 
//     // Not much of a validation as it only sets the lookup fields.
//     table validate_other {
//         key = {
//             hdr.udp.isValid() : exact;
//         }
// 
//         actions = {
// 			NoAction;
//             set_udp_ports;
//         }
// 
//         const default_action = NoAction;
//         const entries = {
//             (true) : set_udp_ports();
//         }
//     }

    // -----------------------------
    // TUNNEL
    // -----------------------------

    action validate_tunnel_none() {
    }

    action validate_tunnel_vlan() {
    }

    action validate_tunnel_vni() {
    }

    table validate_tunnel {
        key = {
            tunnel.type : ternary;
            hdr.vlan_tag[0].isValid(): exact;
            hdr.vlan_tag[0].vid: ternary;
        }
        actions = {
            validate_tunnel_vni;
            validate_tunnel_vlan;
            validate_tunnel_none;
        }
        const entries = {
			// highest -> lowest priority in tcam
            (0, true,  0): validate_tunnel_none(); // tag has priority only
            (0, true,  _): validate_tunnel_vlan(); // tag has priority and vlan
            (_, true,  _): validate_tunnel_vni();
            (_, false, _): validate_tunnel_vni();
            (0, false, _): validate_tunnel_none();
        }

    }

    // -------------------------------------
    // Extreme Networks - Added
    // -------------------------------------

    // Validate Extreme NSH underlay header.
    //
    // Currently, we only support parsing of our own, fixed length Extreme
    // (MD-Type1), NSH. This validation logic will drop any NSH pkt that does
    // not conform. In the future, when PHV resources are less tight, we plan
    // to add support for parsing non-Extreme NSH as well.
    //
    //   Drop the packet if:
    //
    //        version != 0                     -> Base Header          
    //              o == 1  (oam)                     :                
    //            ttl == 0                            :                
    //            len != 6  (4B words)                :                
    //        md_type != 1                            :                
    //     next_proto != 3  (enet)                    :                
    //             si == 0                     -> Service Path Header      
    //       md_class != ?  (todo)             -> Variable Length Context Header
    //           type != ?  (todo)                    :                
    //         md_len != 8  (bytes)                   :                
    //           todo == ?  (any checks here?) -> Variable Length Metadata   

    table validate_nsh {

        key = {
            hdr.nsh_type1.version : range;
            hdr.nsh_type1.o : ternary;
            hdr.nsh_type1.ttl : ternary;
            hdr.nsh_type1.len : range;
            hdr.nsh_type1.md_type : range;
            hdr.nsh_type1.next_proto : range;
            hdr.nsh_type1.si : ternary;
            //hdr.nsh_type1.md_class : ternary;
            //hdr.nsh_type1.type : ternary;
            //hdr.nsh_type1.md_len : range;
            //hdr.nsh_type1.xxx : ternary;
        }

        actions = {
            NoAction;
            malformed_pkt;
        }

        size = table_size;
        const default_action = NoAction;
        const entries = {
            // Can a range match type be a don't care? (it compiles..)
            (2w1 .. 2w3, _, _, _, _, _, _):
            malformed_pkt(SWITCH_DROP_REASON_TRANSPORT_NSH_VERSION_INVALID);
            (_, 1, _, _, _, _, _):
            malformed_pkt(SWITCH_DROP_REASON_TRANSPORT_NSH_OAM);
			// Derek: Consider removing this ttl check.  The RFC allows
			// an incoming TTL of 0 for backwards compatibility....
            (_, _, 0, _, _, _, _):
            malformed_pkt(SWITCH_DROP_REASON_TRANSPORT_NSH_TTL_ZERO);
            (_, _, _, 6w0 .. 6w5, _, _, _):
            malformed_pkt(SWITCH_DROP_REASON_TRANSPORT_NSH_LEN_INVALID);
            (_, _, _, 6w7 .. 6w63, _, _, _):
            malformed_pkt(SWITCH_DROP_REASON_TRANSPORT_NSH_LEN_INVALID);
            (_, _, _, _, 4w0 .. 4w0, _, _):
            malformed_pkt(SWITCH_DROP_REASON_TRANSPORT_NSH_MDTYPE_INVALID);
            (_, _, _, _, 4w2 .. 4w15, _, _):
            malformed_pkt(SWITCH_DROP_REASON_TRANSPORT_NSH_MDTYPE_INVALID);
            (_, _, _, _, _, 8w0 .. 8w0, _):
            malformed_pkt(SWITCH_DROP_REASON_TRANSPORT_NSH_NEXT_PROTO_INVALID);
            (_, _, _, _, _, 8w4 .. 8w255, _):
            malformed_pkt(SWITCH_DROP_REASON_TRANSPORT_NSH_NEXT_PROTO_INVALID);
            (_, _, _, _, _, _, 0):
            malformed_pkt(SWITCH_DROP_REASON_TRANSPORT_NSH_SI_ZERO);
//          (_, _, _, _, _, _, _, 7w0 .. 7w7):
//          malformed_pkt(SWITCH_DROP_REASON_TRANSPORT_NSH_MD_LEN_INVALID);
//          (_, _, _, _, _, _, _, 7w9 .. 7w127):
//          malformed_pkt(SWITCH_DROP_REASON_TRANSPORT_NSH_MD_LEN_INVALID);
            // todo: Instead of all the above ranges, would it be better to
            // create a single bit key field (len_eq_5) based on a length
            // compare?
        }
    }

    // -----------------------------
	// Apply
    // -----------------------------

    apply {
        // -------------------------------------
        // Extreme Networks - Modified
        // -------------------------------------
/*
        switch(validate_ethernet.apply().action_run) {
            malformed_non_ip_pkt : {}
            default : {
                if (hdr.ipv4.isValid()) {
                    validate_ipv4.apply();
                }
#ifdef IPV6_ENABLE
                else if (hdr.ipv6.isValid()) {
                    validate_ipv6.apply();
                }
#endif

                validate_other.apply();
            }
        }
    }
*/
        if (hdr.nsh_type1.isValid()) { // extreme added
            // --- PACKET HAS UNDERLAY ---
            switch(validate_nsh.apply().action_run) { // extreme added
                malformed_pkt : {} // extreme added
                default: { // extreme added
                    switch(validate_ethernet.apply().action_run) {
                        malformed_non_ip_pkt : {}

                        default : {
#ifdef ERSPAN_TRANSPORT_INGRESS_ENABLE
                            if (hdr.ipv4.isValid()) {
                                validate_ipv4.apply();
                            }
#endif /* ERSPAN_TRANSPORT_INGRESS_ENABLE */
                            //validate_other.apply();

                            validate_tunnel.apply();
                        }
                    }
                } // extreme added
            } // extreme added
        }

        // currently only NSH transport supported
        // if NSH invalid, then there will be no transport headers to validate
        // else { // extreme added
        //     // --- PACKET DOES NOT HAVE UNDERLAY ---
        //             switch(validate_ethernet.apply().action_run) {
        //                 malformed_non_ip_pkt : {}
        //                 default : {
        //                     if (hdr.ipv4.isValid()) {
        //                         validate_ipv4.apply();
        //                     }
        // 
        //                     validate_other.apply();
        // 
        //                     validate_tunnel.apply();
        //                 }
        //             }
        // } // extreme added
    }
}

// ============================================================================
// Outer Validation
// ============================================================================

control OuterPktValidation(
    in    switch_header_outer_t hdr,       // src
	in    bool ipv4_checksum_err,          // src
	in    switch_tunnel_metadata_reduced_t tunnel, // src
    inout switch_lookup_fields_t lkp,      // dst
    out   switch_drop_reason_t drop_reason // dst
) {

    const switch_uint32_t table_size = 64;

    // -----------------------------
	// L2
    // -----------------------------

    action malformed_pkt(bit<8> reason) {
        drop_reason = reason;
    }

    action malformed_non_ip_pkt(bit<8> reason) {
        malformed_pkt(reason);
    }

    action valid_unicast_pkt_untagged() {
    }

    action valid_unicast_pkt_tagged() {
    }

    action valid_unicast_pkt_double_tagged() {
    }

#ifdef ETAG_ENABLE
    action valid_unicast_pkt_e_tagged() {
    }
#endif // ETAG_ENABLE

#ifdef VNTAG_ENABLE
    action valid_unicast_pkt_vn_tagged() {
    }
#endif // VNTAG_ENABLE

    table validate_ethernet {
        key = {
            hdr.ethernet.isValid() : exact;
            hdr.ethernet.src_addr : ternary;
            hdr.ethernet.dst_addr : ternary;
            hdr.vlan_tag[0].isValid() : ternary;
            hdr.vlan_tag[1].isValid() : ternary;
#ifdef ETAG_ENABLE
            hdr.e_tag.isValid() : ternary;
#endif // ETAG_ENABLE
#ifdef VNTAG_ENABLE
            hdr.vn_tag.isValid() : ternary;
#endif // VNTAG_ENABLE
        }

        actions = {
            malformed_non_ip_pkt;
            valid_unicast_pkt_untagged;
            valid_unicast_pkt_tagged;
            valid_unicast_pkt_double_tagged;
#ifdef ETAG_ENABLE
            valid_unicast_pkt_e_tagged;
#endif // ETAG_ENABLE
#ifdef VNTAG_ENABLE
            valid_unicast_pkt_vn_tagged;
#endif // VNTAG_ENABLE
        }

        size = table_size;
        /* const entries = {
            (_, _, _) : malformed_non_ip_pkt(SWITCH_DROP_SRC_MAC_MULTICAST);
            (0, _, _) : malformed_non_ip_pkt(SWITCH_DROP_SRC_MAC_ZERO);
            (_, 0, _) : malformed_non_ip_pkt(SWITCH_DROP_DST_MAC_ZERO);
        } */
    }

    // -----------------------------
	// L3, v4
    // -----------------------------

    action malformed_ipv4_pkt(bit<8> reason) {
        // Set common lookup fields just for dtel acl and hash purposes
        malformed_pkt(reason);
    }

    action valid_ipv4_pkt(switch_ip_frag_t ip_frag) {
        // Set common lookup fields
    }

    table validate_ipv4 {
        key = {
            ipv4_checksum_err : ternary;
            hdr.ipv4.version : ternary;
            hdr.ipv4.ihl : ternary;
            hdr.ipv4.flags : ternary;
            hdr.ipv4.frag_offset : ternary;
            hdr.ipv4.ttl : ternary;
            hdr.ipv4.src_addr[31:24] : ternary;
        }

        actions = {
            valid_ipv4_pkt;
            malformed_ipv4_pkt;
        }

        size = table_size;
    }

    // -----------------------------
	// L3, v6
    // -----------------------------

#ifdef IPV6_ENABLE

    action malformed_ipv6_pkt(bit<8> reason) {
        // Set common lookup fields just for dtel acl and hash purposes
        malformed_pkt(reason);
    }

    action valid_ipv6_pkt() {
        // Set common lookup fields
    }

    table validate_ipv6 {
        key = {
            hdr.ipv6.version : ternary;
            hdr.ipv6.hop_limit : ternary;
            hdr.ipv6.src_addr[127:96] : ternary; //TODO define the bit range.
        }

        actions = {
            valid_ipv6_pkt;
            malformed_ipv6_pkt;
        }

        size = table_size;
    }

#endif /* IPV6_ENABLE */

    // -----------------------------
	// L4
    // -----------------------------

    action set_tcp_ports() {
    }

    action set_udp_ports() {
    }

    action set_sctp_ports() {
    }

    // Not much of a validation as it only sets the lookup fields.
    table validate_other {
        key = {
            hdr.tcp.isValid() : exact;
            hdr.udp.isValid() : exact;
            hdr.sctp.isValid() : exact;
        }

        actions = {
			NoAction;
            set_tcp_ports;
            set_udp_ports;
            set_sctp_ports;
        }

        const default_action = NoAction;
        const entries = {
            ( true, false, false) : set_tcp_ports();
            (false,  true, false) : set_udp_ports();
            (false, false,  true) : set_sctp_ports();
        }
    }

    // -----------------------------
    // TUNNEL
    // -----------------------------

    action validate_tunnel_none() {
    }

    action validate_tunnel_vlan() {
    }

    action validate_tunnel_vni() {
    }

    table validate_tunnel {
        key = {
            tunnel.type : ternary;
            hdr.vlan_tag[0].isValid(): exact;
            hdr.vlan_tag[0].vid: ternary;
        }
        actions = {
            validate_tunnel_vni;
            validate_tunnel_vlan;
            validate_tunnel_none;
        }
        const entries = {
			// highest -> lowest priority in tcam
            (0, true,  0): validate_tunnel_none(); // tag has priority only
            (0, true,  _): validate_tunnel_vlan(); // tag has priority and vlan
            (_, true,  _): validate_tunnel_vni();
            (_, false, _): validate_tunnel_vni();
            (0, false, _): validate_tunnel_none();
        }

    }

    // -----------------------------
	// Apply
    // -----------------------------

    apply {
        // -------------------------------------
        // Extreme Networks - Modified
        // -------------------------------------

/*
        switch(validate_ethernet.apply().action_run) {
            malformed_non_ip_pkt : {}
            default : {
                if (hdr.ipv4.isValid()) {
                    validate_ipv4.apply();
                }
#ifdef IPV6_ENABLE
                else if (hdr.ipv6.isValid()) {
                    validate_ipv6.apply();
                }
#endif
                validate_other.apply();

				validate_tunnel.apply();
            }
        }
*/
				validate_ethernet.apply();

                if (hdr.ipv4.isValid()) {
                    validate_ipv4.apply();
                }
#ifdef IPV6_ENABLE
                else if (hdr.ipv6.isValid()) {
                    validate_ipv6.apply();
                }
#endif
                validate_other.apply();

				validate_tunnel.apply();
    }
}

// ============================================================================
// Inner Validation
// ============================================================================

control InnerPktValidation(
    in    switch_header_inner_t hdr,       // src
	in    bool ipv4_checksum_err,          // src
	in    switch_tunnel_metadata_reduced_t tunnel, // src
    inout switch_lookup_fields_t lkp,      // dst
    inout switch_drop_reason_t drop_reason // dst
) (
	bool test=true
) {

    // -------------------------------------
    // L2
    // -------------------------------------

    action valid_unicast_pkt_untagged() {
        // Set the common L2 lookup fields

    }

    action valid_unicast_pkt_tagged() {
    }

    action malformed_pkt(bit<8> reason) {
        drop_reason = reason;
    }

    table validate_ethernet {
        key = {
            hdr.ethernet.isValid() : exact;
            hdr.ethernet.dst_addr : ternary;
            hdr.vlan_tag[0].isValid() : ternary;
        }

        actions = {
            NoAction;
            valid_unicast_pkt_untagged;
            valid_unicast_pkt_tagged;
            malformed_pkt;
        }
    }

    // -------------------------------------
    // L3, v4
    // -------------------------------------

    action valid_ipv4_pkt() {
        // Set the common IP lookup fields
    }

    table validate_ipv4 {
        key = {
            ipv4_checksum_err : ternary;
            hdr.ipv4.version : ternary;
            hdr.ipv4.ihl : ternary;
            hdr.ipv4.ttl : ternary;
        }

        actions = {
            valid_ipv4_pkt;
            malformed_pkt;
        }
        /*
        const default_action = malformed_pkt(SWITCH_DROP_REASON_OUTER_IP_VERSION_INVALID);
        const entries = {
            (_, _, _, _, 0x7f) : malformed_pkt(SWITCH_DROP_REASON_OUTER_IP_SRC_LOOPBACK);
            (_, _, _, _, 0xe0 &&& 0xf0) : malformed_pkt(SWITCH_DROP_REASON_OUTER_IP_SRC_MULTICAST);
            (_, _, _, 0, _) : malformed_pkt(SWITCH_DROP_REASON_OUTER_IP_TTL_ZERO);
            (_, _, 0 &&& 0xc, _, _) : malformed_pkt(SWITCH_DROP_REASON_OUTER_IP_IHL_INVALID);
            (_, _, 4 &&& 0xf, _, _) : malformed_pkt(SWITCH_DROP_REASON_OUTER_IP_IHL_INVALID);
            (false, 4 &&& 0xf, _, _, _) : valid_ipv4_pkt();
            (true, 4 &&& 0xf, _, _, _) : malformed_pkt(SWITCH_DROP_REASON_OUTER_IP_VERSION_INVALID);
        }
        */
    }

    // -------------------------------------
    // L3, v6
    // -------------------------------------

#ifdef IPV6_ENABLE
    action valid_ipv6_pkt() {
        // Set the common IP lookup fields
    }

    table validate_ipv6 {
        key = {
            hdr.ipv6.version : ternary;
            hdr.ipv6.hop_limit : ternary;
        }

        actions = {
            valid_ipv6_pkt;
            malformed_pkt;
        }
        const entries = {
            (0 &&& 0, 0) : malformed_pkt(SWITCH_DROP_REASON_IP_IHL_INVALID);
            (6, 0 &&& 0) : valid_ipv6_pkt();
            (0 &&& 0, 0 &&& 0) : malformed_pkt(SWITCH_DROP_REASON_IP_VERSION_INVALID);
        }
    }
#endif  /* IPV6_ENABLE */

    // -------------------------------------
    // L4
    // -------------------------------------

    action set_tcp_ports() {
    }

    action set_udp_ports() {
    }

    action set_sctp_ports() {
    }

    table validate_other {
        key = {
            hdr.tcp.isValid() : exact;
            hdr.udp.isValid() : exact;
            hdr.sctp.isValid() : exact;
        }

        actions = {
            NoAction;
            set_tcp_ports;
            set_udp_ports;
            set_sctp_ports;
        }

        const default_action = NoAction;
        const entries = {
            (true, false, false) : set_tcp_ports();
            (false, true, false) : set_udp_ports();
            (false, false, true) : set_sctp_ports();
        }
    }

    // -----------------------------
    // TUNNEL
    // -----------------------------

    action validate_tunnel_none() {
    }

    action validate_tunnel_vlan() {
    }

    action validate_tunnel_vni() {
    }

    table validate_tunnel {
        key = {
            tunnel.type : ternary;
            hdr.vlan_tag[0].isValid(): exact;
            hdr.vlan_tag[0].vid: ternary;
        }
        actions = {
            validate_tunnel_vni;
            validate_tunnel_vlan;
            validate_tunnel_none;
        }
        const entries = {
			// highest -> lowest priority in tcam
            (0, true,  0): validate_tunnel_none(); // tag has priority only
            (0, true,  _): validate_tunnel_vlan(); // tag has priority and vlan
            (_, true,  _): validate_tunnel_vni();
            (_, false, _): validate_tunnel_vni();
            (0, false, _): validate_tunnel_none();
        }

    }

    // -----------------------------
	// Apply
    // -----------------------------

    apply {
/*
        switch(validate_ethernet.apply().action_run) {
            malformed_pkt : {}
            default : {
                if (hdr.ipv4.isValid()) {
                    validate_ipv4.apply();
                }
#ifdef IPV6_TUNNEL_ENABLE
                else if (hdr.ipv6.isValid()) {
					if(test == true) {
                        validate_ipv6.apply();
					}
                }
#endif

                validate_other.apply();

  				validate_tunnel.apply();
            }
        }
*/
				validate_ethernet.apply();

                if (hdr.ipv4.isValid()) {
                    validate_ipv4.apply();
                }
//#ifdef IPV6_TUNNEL_ENABLE
#ifdef IPV6_ENABLE
               else if (hdr.ipv6.isValid()) {
					if(test == true) {
                        validate_ipv6.apply();
					}
                }
#endif

                validate_other.apply();

  				validate_tunnel.apply();
    }
}

// ============================================================================
// Parser Validation
// ============================================================================

// From tofino2.p4:  todo: are these mutually exclusive?
// ------------------------------------------------------
// typedef error ParserError_t;
// const bit<16> PARSER_ERROR_OK            = 16w0x0000;
// const bit<16> PARSER_ERROR_NO_TCAM       = 16w0x0001;
// const bit<16> PARSER_ERROR_PARTIAL_HDR   = 16w0x0002;
// const bit<16> PARSER_ERROR_CTR_RANGE     = 16w0x0004;
// const bit<16> PARSER_ERROR_TIMEOUT_USER  = 16w0x0008;
// const bit<16> PARSER_ERROR_TIMEOUT_HW    = 16w0x0010;
// const bit<16> PARSER_ERROR_SRC_EXT       = 16w0x0020;
// const bit<16> PARSER_ERROR_PHV_OWNER     = 16w0x0080;
// const bit<16> PARSER_ERROR_MULTIWRITE    = 16w0x0100;
// const bit<16> PARSER_ERROR_ARAM_MBE      = 16w0x0400;
// const bit<16> PARSER_ERROR_FCS           = 16w0x0800;
// const bit<16> PARSER_ERROR_CSUM_MBE      = 16w0x1000;

control ParserValidation(
        inout switch_header_t hdr,
		in    switch_ingress_metadata_t ig_md,
        in    ingress_intrinsic_metadata_from_parser_t  ig_intr_from_prsr,
        out   ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm
) {

    // see slide 97 of the BF Training Material (Data Plane Programming):
    // default actions can be changed at runtime using the APIs.
    // todo: do we need to invalidate udf header here too?
    action drop()          { ig_intr_md_for_dprsr.drop_ctl = 1; exit; }
    action except()        { ig_intr_md_for_dprsr.drop_ctl = 0; }
//     action copy_to_cpu()   { ig_intr_md_for_tm.copy_to_cpu = 1; }
// #ifdef MIRROR_INGRESS_ENABLE
//     action mirror_to_cpu() { ig_intr_md_for_dprsr.mirror_type = 1; }
// #endif // MIRROR_INGRESS_ENABLE

    table handle_parser_errors {
        key = {
            //hdr.udf.isValid() : exact;
            ig_md.flags.parse_udf_reached : exact;
            ig_intr_from_prsr.parser_err: exact;
        }

        actions = {
            drop;
            except;
//             copy_to_cpu;
// #ifdef MIRROR_INGRESS_ENABLE
//             mirror_to_cpu;
// #endif // MIRROR_INGRESS_ENABLE
            NoAction;
        }

        const default_action = drop;
        const entries = {
            // the parser is able to roll off the end of small packets
            // when extracting the opaque UDF data. we want to make an
            // exception for this case, and not drop these frame.
            (true, PARSER_ERROR_PARTIAL_HDR) : except();
            //(false,  true, PARSER_ERROR_PARTIAL_HDR) : except();
            //(false,  1, (0x0002 & PARSER_ERROR_PARTIAL_HDR)) : except(); 
            //(false,  1, (PARSER_ERROR_PARTIAL_HDR & PARSER_ERROR_SRC_EXT)) : except();
            //(false,  1, (0xFFFF &&& PARSER_ERROR_PARTIAL_HDR)) : except(); 
            //PARSER_ERROR_PARTIAL_HDR: except(); 
        }
    }

    // -----------------------------

	apply {
        if (ig_intr_from_prsr.parser_err != 0) {
            handle_parser_errors.apply();
        }
	}
}

#endif // _VALIDATION_
