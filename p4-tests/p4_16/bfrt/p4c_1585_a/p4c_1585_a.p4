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
 *
 * Milad Sharif (msharif@barefootnetworks.com)
 *
 ******************************************************************************/

// Custom profiles.
#ifdef A0_PROFILE
#include "switch_profile_a0.p4"
#else /* Default profile */

#include <core.p4>
#include <tna.p4>

#include "features.p4"
#include "headers.p4"
#include "types.p4"
#include "table_sizes.p4"

#include "l3.p4"
#include "nexthop.p4"
#include "parde.p4"
#include "port.p4"
#include "validation.p4"
#include "rewrite.p4"
#include "tunnel.p4"
#include "multicast.p4"
#include "qos.p4"
#include "meter.p4"
#include "wred.p4"

// -----------------------------
// ----- EXTREME NETWORKS -----
// -----------------------------

#include "npb_ing_sfc_top.p4"
#include "npb_ing_sff_top.p4"

#include "npb_egr_sff_top.p4"
#include "npb_egr_sff_tunnel.p4"

#ifdef ING_HDR_STACK_COUNTERS
  #include "npb_ing_hdr_stack_counters.p4"
#endif

// ----------------------------------------------------------------------------

control SwitchIngress(
        inout switch_header_t hdr,
        inout switch_ingress_metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_intr_from_prsr,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm) {

#ifndef ING_STUBBED_OUT
    IngressPortMapping(PORT_VLAN_TABLE_SIZE, BD_TABLE_SIZE) ingress_port_mapping;
    PktValidation() pkt_validation;
    IngressSTP() stp;
    SMAC(MAC_TABLE_SIZE) smac;
    DMAC(MAC_TABLE_SIZE) dmac;
    IngressTunnel(IPV4_SRC_TUNNEL_TABLE_SIZE) tunnel;
    IngressBd(BD_STATS_TABLE_SIZE) bd_stats;
    IngressMulticast(IPV4_MULTICAST_S_G_TABLE_SIZE,
                     IPV4_MULTICAST_STAR_G_TABLE_SIZE,
                     IPV6_MULTICAST_S_G_TABLE_SIZE,
                     IPV6_MULTICAST_STAR_G_TABLE_SIZE) multicast;
    IngressUnicast(dmac,
                   IPV4_HOST_TABLE_SIZE,
                   IPV4_LPM_TABLE_SIZE,
                   IPV6_HOST_TABLE_SIZE,
                   IPV6_LPM_TABLE_SIZE) unicast;
    IngressAcl() acl;
    MirrorAcl() mirror_acl;
    RouterAcl(
        INGRESS_IPV4_RACL_TABLE_SIZE, INGRESS_IPV6_RACL_TABLE_SIZE, true, RACL_STATS_TABLE_SIZE) racl;

    IngressQos() qos;
    StormControl(STORM_CONTROL_TABLE_SIZE) storm_control;
    Nexthop(NEXTHOP_TABLE_SIZE, ECMP_GROUP_TABLE_SIZE, ECMP_SELECT_TABLE_SIZE) nexthop;
    OuterNexthop(
        OUTER_NEXTHOP_TABLE_SIZE, OUTER_ECMP_GROUP_TABLE_SIZE, ECMP_SELECT_TABLE_SIZE) outer_nexthop;
    LAG() lag;
    MulticastFlooding(BD_FLOOD_TABLE_SIZE) flood;
    IngressSystemAcl() system_acl;
#endif  /* ING_STUBBED_OUT */

	// ----------------------------------------------------------------------------

    //TODO(msharif) : Use different algorithms for upper and lower 16 bits.
    Hash<bit<32>>(HashAlgorithm_t.CRC32) flow_hash;

    switch_lookup_fields_t lkp;
    switch_lookup_fields_t lkp_nsh;

	// ----------------------------------------------------------------------------

    //XXX Tofino can generate 4 bytes of hash per logical table, we need to make sure PHV
    // container(s) allocated for hash is less than 32 bits. P4C-669.
    @pa_container_size("ingress", "hash_1", 16)
    bit<32> hash;

    action add_bridged_md() {
        hdr.bridged_md.setValid();
        hdr.bridged_md.src = SWITCH_PKT_SRC_BRIDGE;
        // hdr.bridged_md.ingress_port = ig_md.port;
        // hdr.bridged_md.ingress_ifindex = ig_md.ifindex;
        // hdr.bridged_md.ingress_bd = ig_md.bd;
        hdr.bridged_md.nexthop = ig_md.nexthop;
        // hdr.bridged_md.routed = (bit<1>) ig_md.flags.routed;
        // hdr.bridged_md.peer_link = (bit<1>) ig_md.flags.peer_link;
        // hdr.bridged_md.capture_ts = (bit<1>) ig_md.flags.capture_ts;
        // hdr.bridged_md.tunnel_terminate = (bit<1>) ig_md.tunnel.terminate;
        // hdr.bridged_md.tc = ig_md.qos.tc;
        // hdr.bridged_md.cpu_reason = ig_md.cpu_reason;
        // hdr.bridged_md.timestamp = ig_md.timestamp;
        // hdr.bridged_md.qid = ig_intr_md_for_tm.qid;

#ifdef EGRESS_ACL_ENABLE
        hdr.bridged_md.l4_src_port = lkp.l4_src_port;
        hdr.bridged_md.l4_dst_port = lkp.l4_src_port;
        hdr.bridged_md.l4_port_label = ig_md.l4_port_label;
#endif

#ifdef TUNNEL_ENABLE
        hdr.bridged_tunnel_md.setValid();
        hdr.bridged_tunnel_md.index = ig_md.tunnel.index;
        hdr.bridged_tunnel_md.outer_nexthop = ig_md.outer_nexthop;
        hdr.bridged_tunnel_md.hash = hash[15:0];
#endif

        //TODO(msharif) : Move this to deparser.
        hdr.mirror.port.session_id = (bit<16>) ig_md.mirror.session_id;

        // -----------------------------
        // ----- Extreme Networks -----
        // -----------------------------

		// metadata
        hdr.bridged_md.orig_pkt_had_nsh                  = ig_md.orig_pkt_had_nsh;

        hdr.bridged_md.nsh_extr_valid                    = ig_md.nsh_extr.valid;
        hdr.bridged_md.nsh_extr_end_of_chain             = ig_md.nsh_extr.end_of_chain;

        // base: word 0
    
        // base: word 1
        hdr.bridged_md.nsh_extr_spi                      = ig_md.nsh_extr.spi;
        hdr.bridged_md.nsh_extr_si                       = ig_md.nsh_extr.si;
    
        // ext: type 2 - word 0

        // ext: type 2 - word 1+
        hdr.bridged_md.nsh_extr_srvc_func_bitmask_local  = ig_md.nsh_extr.extr_srvc_func_bitmask_local;  //  1 byte
        hdr.bridged_md.nsh_extr_srvc_func_bitmask_remote = ig_md.nsh_extr.extr_srvc_func_bitmask_remote; //  1 byte
        hdr.bridged_md.nsh_extr_tenant_id                = ig_md.nsh_extr.extr_tenant_id;                //  3 bytes
        hdr.bridged_md.nsh_extr_flow_type                = ig_md.nsh_extr.extr_flow_type;                //  1 byte?
    }

	// ----------------------------------------------------------------------------

    action compute_ip_hash() {
        hash = flow_hash.get({lkp.ipv4_src_addr,
                              lkp.ipv4_dst_addr,
                              lkp.ipv6_src_addr,
                              lkp.ipv6_dst_addr,
                              lkp.ip_proto,
                              lkp.l4_dst_port,
                              lkp.l4_src_port});
    }

	// ----------------------------------------------------------------------------

    action compute_non_ip_hash() {
        hash = flow_hash.get({lkp.mac_type, lkp.mac_src_addr, lkp.mac_dst_addr});
    }

	// ----------------------------------------------------------------------------

	table table_debug_ingress {
        key = {
            hdr.ethernet.dst_addr   : exact;
            hdr.ethernet.src_addr   : exact;
            hdr.ethernet.ether_type : exact;
        }
		actions = {
			NoAction;
		}
	}

    apply {

        // -----------------------------------------------------
        // derek: just set the tx-port to the rx-port, for debug!
        // -----------------------------------------------------

#ifdef SEND_PKT_OUT_PORT_IT_CAME_IN_ON
        ig_intr_md_for_tm.ucast_egress_port = ig_intr_md.ingress_port;
#endif

        // -----------------------------------------------------
        // cmace: header stack id experiment
        // -----------------------------------------------------

#ifdef ING_HDR_STACK_COUNTERS
        IngressHdrStackCounters.apply(hdr);
#endif  /* ING_HDR_STACK_COUNTERS */

        // -----------------------------------------------------

#ifndef ING_STUBBED_OUT

        pkt_validation.apply(
            hdr, ig_md.flags, lkp, ig_intr_md_for_tm, ig_md.drop_reason);
		lkp_nsh = lkp; // Derek added
        ingress_port_mapping.apply(hdr, ig_md, ig_intr_md_for_tm, ig_intr_md_for_dprsr);
//      stp.apply(ig_md, ig_md.stp);

        tunnel.apply(hdr, ig_md, lkp, lkp_nsh);
//      smac.apply(lkp.mac_src_addr, ig_md, ig_intr_md_for_dprsr.digest_type);
//      bd_stats.apply(ig_md.bd, lkp.pkt_type);
//      acl.apply(lkp, ig_md);
//      mirror_acl.apply(lkp, ig_md, ig_intr_md_for_dprsr);

        // =====================================
		// Paths Fork
        // =====================================

        // =====================================
		// Path A: NSH Processing
        // =====================================

        // -------------------------------------
        // SFC
        // -------------------------------------

        npb_ing_sfc_top.apply (
            hdr,
            ig_md,
            ig_intr_md,
            ig_intr_from_prsr,
            ig_intr_md_for_dprsr,
            ig_intr_md_for_tm,

            lkp_nsh
        );

        // -------------------------------------
        // SFF and SF(s)
        // -------------------------------------

        npb_ing_sff_top.apply (
            hdr,
            ig_md,
            ig_intr_md,
            ig_intr_from_prsr,
            ig_intr_md_for_dprsr,
            ig_intr_md_for_tm,

            lkp_nsh
        );

        // =====================================
		// Path B: Switch Processing
        // =====================================

#ifdef ENABLE_SWITCH_MAC_AND_FIB_TABLES

        if (lkp.pkt_type == SWITCH_PKT_TYPE_UNICAST) {
            // Unicast packets.
            unicast.apply(lkp, ig_md, ig_intr_md_for_tm);
        } else if (lkp.pkt_type == SWITCH_PKT_TYPE_MULTICAST &&
                lkp.ip_type != SWITCH_IP_TYPE_NONE) {
            // IP multicast packets.
            multicast.apply(lkp, ig_md, ig_intr_md_for_tm.mcast_grp_b);
        } else {
            // Non-IP multicast and broadcast packets.
            dmac.apply(lkp.mac_dst_addr, ig_md, ig_intr_md_for_tm);
        }

#endif // ENABLE_SWITCH_MAC_AND_FIB_TABLES

        // =====================================
		// Paths Join
        // =====================================

		// Give higher priority to nsh forwarding than switch forwarding....

#ifdef ENABLE_SWITCH_MAC_AND_FIB_TABLES

if((ig_md.nsh_extr.valid == 1) && (ig_md.nsh_extr.end_of_chain == 0)) {

#endif // ENABLE_SWITCH_MAC_AND_FIB_TABLES

		// nsh tunnel settings become switch tunnel settings (see tunnel.p4)....

		ig_md.tunnel.ifindex             = ig_md.tunnel_nsh.ifindex;

        ig_md.bd                         = ig_md.bd_nsh;
        ig_md.bd_label                   = ig_md.bd_label_nsh;
        ig_md.vrf                        = ig_md.vrf_nsh;
        // ig_intr_md_for_tm.rid         = ig_intr_md_for_tm.rid;
        ig_md.rmac_group                 = ig_md.rmac_group_nsh;
        ig_md.multicast.rpf_group        = ig_md.multicast_nsh.rpf_group;
        ig_md.learning.bd_mode           = ig_md.learning_nsh.bd_mode;
        ig_md.ipv4_md.unicast_enable     = ig_md.ipv4_md_nsh.unicast_enable;
        ig_md.ipv4_md.multicast_enable   = ig_md.ipv4_md_nsh.multicast_enable;
        ig_md.ipv4_md.multicast_snooping = ig_md.ipv4_md_nsh.multicast_snooping;
        ig_md.ipv6_md.unicast_enable     = ig_md.ipv6_md_nsh.unicast_enable;
        ig_md.ipv6_md.multicast_enable   = ig_md.ipv6_md_nsh.multicast_enable;
        ig_md.ipv6_md.multicast_snooping = ig_md.ipv6_md_nsh.multicast_snooping;
		ig_md.tunnel.terminate           = ig_md.tunnel_nsh.terminate;

#ifdef ENABLE_SWITCH_MAC_AND_FIB_TABLES

}

#endif // ENABLE_SWITCH_MAC_AND_FIB_TABLES

//      racl.apply(lkp, ig_md);
#ifndef BASIC_HASH_CALCULATION
        if (lkp.ip_type == SWITCH_IP_TYPE_NONE) {
            compute_non_ip_hash();
        } else {
            compute_ip_hash();
        }
#endif
        nexthop.apply(lkp, ig_md, ig_intr_md_for_tm, hash[15:0]);
//      qos.apply(hdr, lkp, ig_md.qos, ig_md, ig_intr_md_for_tm);
//      storm_control.apply(ig_md, lkp.pkt_type, ig_md.flags.storm_control_drop);
        outer_nexthop.apply(ig_md, hash[31:16]);

        if (ig_md.egress_ifindex == SWITCH_IFINDEX_FLOOD) {
//          flood.apply(
//              lkp.pkt_type, ig_md.bd, ig_md.flags.flood_to_multicast_routers, ig_intr_md_for_tm);
        } else {
//          lag.apply(ig_md, hash[31:16], ig_intr_md_for_tm.ucast_egress_port);
        }

//      system_acl.apply(
//          ig_md, lkp, ig_intr_md_for_tm, ig_intr_md_for_dprsr);

        // Only add bridged metadata if we are NOT bypassing egress pipeline.
        if (ig_intr_md_for_tm.bypass_egress == 0) {
            add_bridged_md();
        }

#ifdef MULTICAST_ENABLE
        // Set PRE hash values
//XXX Compiler doesn't like this copy!!!!
//        ig_intr_md_for_tm.level1_mcast_hash = hash[12:0];
//        ig_intr_md_for_tm.level2_mcast_hash = hash[28:16];
#endif

#else   /* ING_STUBBED_OUT */

// Derek: have to comment this out because of compiler bug "ran out of constant output slots"
        add_bridged_md();

#endif  /* ING_STUBBED_OUT */

		table_debug_ingress.apply();

    }
}

// ----------------------------------------------------------------------------

control SwitchEgress(
        inout switch_header_t hdr,
        inout switch_egress_metadata_t eg_md,
        in egress_intrinsic_metadata_t eg_intr_md,
        in egress_intrinsic_metadata_from_parser_t eg_intr_from_prsr,
        inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
        inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {

#ifndef EGR_STUBBED_OUT
    EgressPortMapping(PORT_TABLE_SIZE) egress_port_mapping;
    EgressSTP() stp;
    EgressAcl() acl;
    EgressQos(EGRESS_QOS_MAP_TABLE_SIZE) qos;
    EgressSystemAcl() system_acl;
    Rewrite() rewrite;
    MirrorRewrite() mirror_rewrite;
    VlanXlate(VLAN_TABLE_SIZE, PORT_VLAN_TABLE_SIZE) vlan_xlate;
    VlanDecap() vlan_decap;
    TunnelDecap(switch_tunnel_mode_t.PIPE) tunnel_decap;
#ifdef INNER_INNER_MAU_ENABLE
    TunnelDecapInner(switch_tunnel_mode_t.PIPE) tunnel_decap_inner;
#endif
    TunnelEncap(switch_tunnel_mode_t.PIPE) tunnel_encap;
    MTU() mtu;
    WRED() wred;
    MulticastReplication(RID_TABLE_SIZE) multicast_replication;
#endif  /* EGR_STUBBED_OUT */

    switch_lookup_fields_t lkp;

	// ----------------------------------------------------------------------------

	table table_debug_egress {
        key = {
            hdr.ethernet.dst_addr   : exact;
            hdr.ethernet.src_addr   : exact;
            hdr.ethernet.ether_type : exact;
        }
		actions = {
			NoAction;
		}
	}

    apply {

		table_debug_egress.apply();

#ifndef EGR_STUBBED_OUT

        lkp.l4_src_port = hdr.bridged_md.l4_src_port;
        lkp.l4_dst_port = hdr.bridged_md.l4_dst_port;

        egress_port_mapping.apply(hdr, eg_md, eg_intr_md_for_dprsr, eg_intr_md.egress_port);

        // -------------------------------------
        // SFF and SF(s)
        // -------------------------------------

        npb_egr_sff_top.apply (
            hdr,
            eg_md,
            eg_intr_md,
            eg_intr_from_prsr,
            eg_intr_md_for_dprsr,
            eg_intr_md_for_oport
        );

        // -------------------------------------

        multicast_replication.apply(
            eg_intr_md.egress_rid, eg_intr_md.egress_port, eg_md);
        if (eg_md.pkt_src != SWITCH_PKT_SRC_BRIDGE) {
            // Packet is mirrored.
//          mirror_rewrite.apply(hdr, eg_md);
        } else {
//          stp.apply(eg_intr_md.egress_port, eg_md.bd, eg_md.checks.stp);
            if (eg_md.port_type == SWITCH_PORT_TYPE_NORMAL) {
                vlan_decap.apply(hdr, eg_md.ingress_port);
                if (eg_md.tunnel.terminate) {
                    tunnel_decap.apply(hdr);
                }

                // -------------------------------------
                // Delete NSH Header
                // -------------------------------------

/*
                npb_egr_sff_vlan_decap.apply(hdr, eg_md.ingress_port);

                if(eg_md.nsh_extr.end_of_chain == 1) {
                    npb_egr_sff_tunnel_decap.apply(
                        hdr,
                        eg_md,
                        eg_intr_md,
                        eg_intr_from_prsr,
                        eg_intr_md_for_dprsr,
                        eg_intr_md_for_oport
                    );
                };
*/

                // -------------------------------------

//              qos.apply(hdr, eg_intr_md.egress_port, eg_md.qos);
//              wred.apply(hdr, eg_md.qos, eg_intr_md, eg_md.flags.wred_drop);
            }
        }

        rewrite.apply(hdr, eg_md);

        // -------------------------------------
        // Rewrite NSH Header
        // -------------------------------------

/*
        npb_egr_sff_rewrite.apply(
            hdr,
            eg_md,
            eg_intr_md,
            eg_intr_from_prsr,
            eg_intr_md_for_dprsr,
            eg_intr_md_for_oport
        );
*/

        // -------------------------------------

//      acl.apply(hdr, lkp, eg_md);
        tunnel_encap.apply(hdr, eg_md);

        // -------------------------------------
        // Insert NSH Header
        // -------------------------------------

/*
        npb_egr_sff_tunnel_encap.apply(
            hdr,
            eg_md,
            eg_intr_md,
            eg_intr_from_prsr,
            eg_intr_md_for_dprsr,
            eg_intr_md_for_oport
        );
*/

        // -------------------------------------

        mtu.apply(hdr, eg_md.checks.mtu);
        if (eg_md.port_type == SWITCH_PORT_TYPE_NORMAL) {
            vlan_xlate.apply(hdr, eg_md.port_lag_index, eg_md.bd);
        }

//      system_acl.apply(hdr, eg_md, eg_intr_md, eg_intr_md_for_dprsr);
#if __TARGET_TOFINO__ >= 2
        eg_intr_md_for_dprsr.mirror_io_select = 1;
#endif
        eg_intr_md_for_oport.capture_tstamp_on_tx = (bit<1>) eg_md.flags.capture_ts;
        //TODO(msharif) : Move this to deparser.
        hdr.mirror.port.session_id = (bit<16>) eg_md.mirror.session_id;

#endif  /* EGR_STUBBED_OUT */

    }
}

// ----------------------------------------------------------------------------

Pipeline(
        SwitchIngressParser(),
//        NpbIngressParser(),
        SwitchIngress(),
        SwitchIngressDeparser(),
        SwitchEgressParser(),
//        NpbEgressParser(),
        SwitchEgress(),
        SwitchEgressDeparser()) pipe;

Switch(pipe) main;

#endif /* Default profile */
