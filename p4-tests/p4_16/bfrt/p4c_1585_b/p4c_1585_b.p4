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
#if defined(A0_PROFILE)
#include "switch_profile_a0.p4"
#elif defined(B0_PROFILE)
#include "switch_profile_b0.p4"
#else /* Default profile */

#include <core.p4>
#if __TARGET_TOFINO__ >= 2
#include <t2na.p4>
#else
#include <tna.p4>
#endif

#include "features.p4"
#include "headers.p4"
#include "types.p4"
#include "table_sizes.p4"
#include "util.p4"

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
#include "dtel.p4"

#ifdef TEST_SWITCH_32Q
#include "switch_32q.p4"
#endif

// -----------------------------
// ----- EXTREME NETWORKS -----
// -----------------------------

#include "npb_ing_sfc_top.p4"
#include "npb_ing_sff_top.p4"

#include "npb_egr_sff_top.p4"
#include "npb_egr_sff_tunnel.p4"
#include "npb_egr_sff_top2.p4"

#ifdef ING_HDR_STACK_COUNTERS
  #include "npb_ing_hdr_stack_counters.p4"
#endif

// Test program exceeds Tof1 egress parse depth
@command_line("--disable-parse-max-depth-limit")

// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------

control SwitchIngress(
        inout switch_header_t hdr,
        inout switch_ingress_metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_intr_from_prsr,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm) {

	// -------------------------------------------------------------------------

    IngressPortMapping(PORT_VLAN_TABLE_SIZE,
                       BD_TABLE_SIZE,
                       DOUBLE_TAG_TABLE_SIZE) ingress_port_mapping;
    PktValidation() pkt_validation;
    IngressSTP() stp;
    SMAC(MAC_TABLE_SIZE) smac;
    DMAC(MAC_TABLE_SIZE) dmac;
    IngressTunnel(IPV4_SRC_TUNNEL_TABLE_SIZE) tunnel;
    IngressBd(BD_TABLE_SIZE) bd_stats;
    IngressMulticast(IPV4_MULTICAST_S_G_TABLE_SIZE,
                     IPV4_MULTICAST_STAR_G_TABLE_SIZE,
                     IPV6_MULTICAST_S_G_TABLE_SIZE,
                     IPV6_MULTICAST_STAR_G_TABLE_SIZE) multicast;
    IngressUnicast(dmac,
                   IPV4_HOST_TABLE_SIZE,
                   IPV4_LPM_TABLE_SIZE,
                   IPV6_HOST_TABLE_SIZE,
                   IPV6_LPM_TABLE_SIZE) unicast;
    IngressAcl(
        INGRESS_IPV4_ACL_TABLE_SIZE, INGRESS_IPV6_ACL_TABLE_SIZE, INGRESS_MAC_ACL_TABLE_SIZE) acl;
    MirrorAcl() mirror_acl;
    RouterAcl(IPV4_RACL_TABLE_SIZE, IPV6_RACL_TABLE_SIZE, true, RACL_STATS_TABLE_SIZE) racl;

    IngressQos() qos;
    IngressDtel() dtel;
    StormControl(STORM_CONTROL_TABLE_SIZE) storm_control;
    Nexthop(NEXTHOP_TABLE_SIZE, ECMP_GROUP_TABLE_SIZE, ECMP_SELECT_TABLE_SIZE) nexthop;
    OuterNexthop(
        OUTER_NEXTHOP_TABLE_SIZE, OUTER_ECMP_GROUP_TABLE_SIZE, ECMP_SELECT_TABLE_SIZE) outer_nexthop;
    LAG() lag;
    MulticastFlooding(BD_FLOOD_TABLE_SIZE) flood;
    IngressSystemAcl() system_acl;

	// -------------------------------------------------------------------------

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

        pkt_validation.apply(hdr, ig_md.flags, ig_md.lkp, ig_intr_md_for_tm, ig_md.drop_reason);

		ig_md.lkp_nsh = ig_md.lkp; // Derek added

        ingress_port_mapping.apply(hdr, ig_md, ig_intr_md_for_tm, ig_intr_md_for_dprsr);
//      stp.apply(ig_md, ig_md.stp);

        tunnel.apply(hdr, ig_md, ig_md.lkp, ig_md.lkp_nsh);
//      smac.apply(ig_md.lkp.mac_src_addr, ig_md, ig_intr_md_for_dprsr.digest_type);
//      bd_stats.apply(ig_md.bd, ig_md.lkp.pkt_type);
//      acl.apply(ig_md.lkp, ig_md);
        mirror_acl.apply(ig_md.lkp, ig_md);

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
            ig_intr_md_for_tm
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
            ig_intr_md_for_tm
        );

        // =====================================
        // Path B: Switch Processing
        // =====================================

#ifdef ENABLE_SWITCH_MAC_AND_FIB_TABLES

        if (ig_md.lkp.pkt_type == SWITCH_PKT_TYPE_UNICAST) {
            // Unicast packets.
            unicast.apply(ig_md.lkp, ig_md, ig_intr_md_for_tm);
        } else if (ig_md.lkp.pkt_type == SWITCH_PKT_TYPE_MULTICAST &&
                ig_md.lkp.ip_type != SWITCH_IP_TYPE_NONE) {
            // IP multicast packets.
            multicast.apply(ig_md.lkp, ig_md, ig_md.multicast.id);
        } else {
            // Non-IP multicast and broadcast packets.
            dmac.apply(ig_md.lkp.mac_dst_addr, ig_md);
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
        ig_md.ipv4.unicast_enable        = ig_md.ipv4_nsh.unicast_enable;
        ig_md.ipv4.multicast_enable      = ig_md.ipv4_nsh.multicast_enable;
        ig_md.ipv4.multicast_snooping    = ig_md.ipv4_nsh.multicast_snooping;
        ig_md.ipv6.unicast_enable        = ig_md.ipv6_nsh.unicast_enable;
        ig_md.ipv6.multicast_enable      = ig_md.ipv6_nsh.multicast_enable;
        ig_md.ipv6.multicast_snooping    = ig_md.ipv6_nsh.multicast_snooping;
        ig_md.tunnel.terminate           = ig_md.tunnel_nsh.terminate;

#ifdef ENABLE_SWITCH_MAC_AND_FIB_TABLES

}

#endif // ENABLE_SWITCH_MAC_AND_FIB_TABLES

        racl.apply(ig_md.lkp, ig_md);
        if (ig_md.lkp.ip_type == SWITCH_IP_TYPE_NONE)
            compute_non_ip_hash(ig_md.lkp, ig_md.hash);
        else
            compute_ip_hash(ig_md.lkp, ig_md.hash);

        nexthop.apply(ig_md.lkp, ig_md, ig_md.hash[15:0]);
        qos.apply(hdr, ig_md.lkp, ig_md.qos, ig_md, ig_intr_md_for_tm);
        storm_control.apply(ig_md, ig_md.lkp.pkt_type, ig_md.flags.storm_control_drop);
        outer_nexthop.apply(ig_md, ig_md.hash[31:16]);

        if (ig_md.egress_ifindex == SWITCH_IFINDEX_FLOOD) {
//          flood.apply(ig_md);
        } else {
//          lag.apply(ig_md, ig_md.hash[31:16], ig_intr_md_for_tm.ucast_egress_port);
        }

//      system_acl.apply(ig_md, ig_md.lkp, ig_intr_md_for_tm, ig_intr_md_for_dprsr);
        dtel.apply(hdr, ig_md.lkp, ig_md, ig_md.hash[15:0], ig_intr_md_for_dprsr, ig_intr_md_for_tm);

        // Only add bridged metadata if we are NOT bypassing egress pipeline.
        if (ig_intr_md_for_tm.bypass_egress == 0) {
            add_bridged_md(hdr.bridged_md, ig_md);
        }

        set_ig_intr_md(ig_md, ig_intr_md_for_dprsr, ig_intr_md_for_tm);

#else   /* ING_STUBBED_OUT */

// Derek: have to comment this out because of compiler bug "ran out of constant output slots"
//      add_bridged_md(hdr.bridged_md, ig_md);

#endif  /* ING_STUBBED_OUT */

    }
}

// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------

control SwitchEgress(
        inout switch_header_t hdr,
        inout switch_egress_metadata_t eg_md,
        in egress_intrinsic_metadata_t eg_intr_md,
        in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
        inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
        inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {

	// -------------------------------------------------------------------------

    EgressPortMapping(PORT_TABLE_SIZE) egress_port_mapping;
    EgressSTP() stp;
    EgressAcl() acl;
    EgressQos(EGRESS_QOS_MAP_TABLE_SIZE) qos;
    EgressSystemAcl() system_acl;
    Rewrite(NEXTHOP_TABLE_SIZE, BD_TABLE_SIZE) rewrite;
    EgressDtel() dtel;
    MirrorRewrite() mirror_rewrite;
    VlanXlate(VLAN_TABLE_SIZE, PORT_VLAN_TABLE_SIZE) vlan_xlate;
    VlanDecap() vlan_decap;
    TunnelDecap(switch_tunnel_mode_t.PIPE) tunnel_decap;
    TunnelEncap(switch_tunnel_mode_t.PIPE) tunnel_encap;
    TunnelRewrite() tunnel_rewrite;

    MTU() mtu;
    WRED() wred;
    MulticastReplication(RID_TABLE_SIZE) multicast_replication;

	// -------------------------------------------------------------------------

    apply {

#ifndef EGR_STUBBED_OUT

        eg_md.timestamp = eg_intr_md_from_prsr.global_tstamp[31:0];
        egress_port_mapping.apply(hdr, eg_md, eg_intr_md_for_dprsr, eg_intr_md.egress_port);
        multicast_replication.apply(
            eg_intr_md.egress_rid, eg_intr_md.egress_port, eg_md);

        // -------------------------------------
        // SFF and SF(s): Part 1
        // -------------------------------------

        npb_egr_sff_top.apply (
            hdr,
            eg_md,
            eg_intr_md,
            eg_intr_md_from_prsr,
            eg_intr_md_for_dprsr,
            eg_intr_md_for_oport
        );

        // -------------------------------------

        if (eg_md.pkt_src != SWITCH_PKT_SRC_BRIDGED) {
            // Packet is mirrored.
            mirror_rewrite.apply(hdr, eg_md);
        } else {
            stp.apply(eg_intr_md.egress_port, eg_md.bd, eg_md.checks.stp);
            if (eg_md.port_type == SWITCH_PORT_TYPE_NORMAL) {
                vlan_decap.apply(hdr, eg_md);
                if (eg_md.tunnel.terminate) {
                    tunnel_decap.apply(hdr, eg_md.tunnel);
                }

                // -------------------------------------
                // Delete NSH Header
                // -------------------------------------

/*
                // not needed if decap being done in ingress parser
                npb_egr_sff_vlan_decap.apply(hdr, eg_md.ingress_port);

                if(eg_md.nsh_extr.end_of_chain == 1) {
                    npb_egr_sff_tunnel_decap.apply(
                        hdr,
                        eg_md,
                        eg_intr_md,
                        eg_intr_md_from_prsr,
                        eg_intr_md_for_dprsr,
                        eg_intr_md_for_oport
                    );
                };
*/

                // -------------------------------------

                qos.apply(hdr, eg_intr_md.egress_port, eg_md);
                wred.apply(hdr, eg_md.qos, eg_intr_md, eg_md.flags.wred_drop);
            }
        }

        // -------------------------------------
        // SFF and SF(s): Part 2
        // -------------------------------------

        npb_egr_sff_top2.apply (
            hdr,
            eg_md,
            eg_intr_md,
            eg_intr_md_from_prsr,
            eg_intr_md_for_dprsr,
            eg_intr_md_for_oport
        );

        rewrite.apply(hdr, eg_md);

        // -------------------------------------
        // Rewrite NSH Header
        // -------------------------------------

/*
        // not needed if decap being done in ingress parser
        npb_egr_sff_rewrite.apply(
            hdr,
            eg_md,
            eg_intr_md,
            eg_intr_md_from_prsr,
            eg_intr_md_for_dprsr,
            eg_intr_md_for_oport
        );
*/

        // -------------------------------------

//      acl.apply(hdr, eg_md.lkp, eg_md);
        tunnel_encap.apply(hdr, eg_md);
        tunnel_rewrite.apply(hdr, eg_md);

        // -------------------------------------
        // Insert NSH Header
        // -------------------------------------

/*
        // not needed if decap being done in ingress parser
        npb_egr_sff_tunnel_encap.apply(
            hdr,
            eg_md,
            eg_intr_md,
            eg_intr_md_from_prsr,
            eg_intr_md_for_dprsr,
            eg_intr_md_for_oport
        );
*/

        // -------------------------------------

        mtu.apply(hdr, eg_md.checks.mtu);
        if (eg_md.port_type == SWITCH_PORT_TYPE_NORMAL) {
            vlan_xlate.apply(hdr, eg_md);
        }

//      system_acl.apply(hdr, eg_md, eg_intr_md, eg_intr_md_for_dprsr);
        dtel.apply(hdr, eg_md, eg_intr_md, eg_md.dtel.hash, eg_intr_md_for_dprsr);

        set_eg_intr_md(eg_md, eg_intr_md_for_dprsr, eg_intr_md_for_oport);

#endif  /* EGR_STUBBED_OUT */

    }
}

// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------

Pipeline(
//      SwitchIngressParser(),
        NpbIngressParser(),
        SwitchIngress(),
        SwitchIngressDeparser(),
//      SwitchEgressParser(),
        NpbEgressParser(),
        SwitchEgress(),
        SwitchEgressDeparser()) pipe;

#ifdef TEST_SWITCH_32Q
Switch(pipe, custom_pipe) main;
#else
Switch(pipe) main;
#endif

#endif /* Default profile */
