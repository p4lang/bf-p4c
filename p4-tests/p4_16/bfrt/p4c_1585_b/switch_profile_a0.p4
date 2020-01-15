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

#include <core.p4>
#if __TARGET_TOFINO__ == 3
#include <t3na.p4>
#elif __TARGET_TOFINO__ == 2
#include <t2na.p4>
#elif __TARGET_TOFINO__ == 1
#include <tna.p4>
#else
#error Unsupported target
#endif

//-----------------------------------------------------------------------------
// Features.
//-----------------------------------------------------------------------------
#define ACL_REDIRECT_ENABLE
#define COPP_ENABLE
#define ECN_ACL_ENABLE
#define EGRESS_ACL_ENABLE
#define EGRESS_PORT_MIRROR_ENABLE
#define ERSPAN_ENABLE
#define ERSPAN_TYPE2_ENABLE
#define INGRESS_POLICER_ENABLE
#define INGRESS_PORT_MIRROR_ENABLE
#define IPV6_ENABLE
#define L4_PORT_LOU_ENABLE
#define MIRROR_ENABLE
#define MIRROR_ACL_ENABLE
// #define MLAG_ENABLE
#define QOS_ENABLE
#define STORM_CONTROL_ENABLE
#define UNICAST_SELF_FORWARDING_CHECK
#define WRED_ENABLE
#define PACKET_LENGTH_ADJUSTMENT

//-----------------------------------------------------------------------------
// Table sizes.
//-----------------------------------------------------------------------------
// 4K L2 vlans
const bit<32> VLAN_TABLE_SIZE = 4096;
const bit<32> BD_FLOOD_TABLE_SIZE = VLAN_TABLE_SIZE * 4;

// 1K (port, vlan) <--> BD
const bit<32> PORT_VLAN_TABLE_SIZE = 1024;

// 5K BDs
const bit<32> BD_TABLE_SIZE = 5120;

// 16K MACs
const bit<32> MAC_TABLE_SIZE = 16384;

// IP Hosts/Routes
const bit<32> IPV4_HOST_TABLE_SIZE = 65536;
const bit<32> IPV4_LOCAL_HOST_TABLE_SIZE = 8192;
const bit<32> IPV4_LPM_TABLE_SIZE = 32768;
const bit<32> IPV6_HOST_TABLE_SIZE = 16384;
const bit<32> IPV6_LPM_TABLE_SIZE = 16384;

// ECMP/Nexthop
const bit<32> ECMP_GROUP_TABLE_SIZE = 1024;
const bit<32> ECMP_SELECT_TABLE_SIZE = 16384;
const bit<32> NEXTHOP_TABLE_SIZE = 65536;

// Ingress ACLs
const bit<32> INGRESS_MAC_ACL_TABLE_SIZE = 512;
const bit<32> INGRESS_IPV4_ACL_TABLE_SIZE = 1024;
const bit<32> INGRESS_IPV6_ACL_TABLE_SIZE = 512;

const bit<32> EGRESS_IPV6_ACL_TABLE_SIZE = 512;
const bit<32> EGRESS_MAC_ACL_TABLE_SIZE = 512;
const bit<32> EGRESS_IPV4_ACL_TABLE_SIZE = 512;

#include "headers.p4"
#include "types.p4"
#include "util.p4"

#include "l3.p4"
#include "nexthop.p4"
#include "parde.p4"
#include "port.p4"
#include "validation.p4"
#include "rewrite.p4"
#include "multicast.p4"
#include "qos.p4"
#include "meter.p4"
#include "wred.p4"
#include "tunnel.p4"
#include "acl.p4"

control SwitchIngress(
        inout switch_header_t hdr,
        inout switch_ingress_metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_intr_from_prsr,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm) {
    IngressPortMapping(PORT_VLAN_TABLE_SIZE, 512, BD_TABLE_SIZE) ingress_port_mapping;
    PktValidation() pkt_validation;
    SMAC(MAC_TABLE_SIZE) smac;
    DMAC(MAC_TABLE_SIZE) dmac;
    IngressBd(BD_TABLE_SIZE) bd_stats;
    IngressUnicast(dmac,
                   IPV4_HOST_TABLE_SIZE,
                   IPV4_LPM_TABLE_SIZE,
                   IPV6_HOST_TABLE_SIZE,
                   IPV6_LPM_TABLE_SIZE,
                   true,
                   IPV4_LOCAL_HOST_TABLE_SIZE) unicast;
    IngressAcl(
        INGRESS_IPV4_ACL_TABLE_SIZE, INGRESS_IPV6_ACL_TABLE_SIZE, INGRESS_MAC_ACL_TABLE_SIZE) acl;
    MirrorAcl(stats_enable=true) mirror_acl;
    EcnAcl() ecn_acl;
    IngressQos() qos;
    StormControl() storm_control;
    Nexthop(NEXTHOP_TABLE_SIZE, ECMP_GROUP_TABLE_SIZE, ECMP_SELECT_TABLE_SIZE) nexthop;
    LAG() lag;
    MulticastFlooding(BD_FLOOD_TABLE_SIZE) flood;
    IngressSystemAcl() system_acl;

    apply {
        pkt_validation.apply(
            hdr, ig_md.flags, ig_md.lkp, ig_intr_md_for_tm, ig_md.drop_reason);
        ingress_port_mapping.apply(hdr, ig_md, ig_intr_md_for_tm, ig_intr_md_for_dprsr);
        smac.apply(ig_md.lkp.mac_src_addr, ig_md, ig_intr_md_for_dprsr.digest_type);
        bd_stats.apply(ig_md.bd, ig_md.lkp.pkt_type);
        if (ig_md.lkp.pkt_type == SWITCH_PKT_TYPE_UNICAST) {
            // Unicast packets.
            unicast.apply(ig_md.lkp, ig_md, ig_intr_md_for_tm);
        } else if (ig_md.lkp.pkt_type == SWITCH_PKT_TYPE_MULTICAST &&
                ig_md.lkp.ip_type != SWITCH_IP_TYPE_NONE) {
            // IP multicast packets.
        } else {
            // Broadcast packets.
            dmac.apply(ig_md.lkp.mac_dst_addr, ig_md);
        }

        acl.apply(ig_md.lkp, ig_md);
        mirror_acl.apply(ig_md.lkp, ig_md);
        if (ig_md.lkp.ip_type == SWITCH_IP_TYPE_NONE) {
            compute_non_ip_hash(ig_md.lkp, ig_md.hash);
        } else {
            compute_ip_hash(ig_md.lkp, ig_md.hash);
        }

        nexthop.apply(ig_md.lkp, ig_md, ig_md.hash[15:0]);
        qos.apply(hdr, ig_md.lkp, ig_md.qos, ig_md, ig_intr_md_for_tm);
        storm_control.apply(ig_md, ig_md.lkp.pkt_type, ig_md.flags.storm_control_drop);

        if (ig_md.egress_ifindex == SWITCH_IFINDEX_FLOOD) {
            flood.apply(ig_md);
        } else {
            lag.apply(ig_md, ig_md.hash[31:16], ig_intr_md_for_tm.ucast_egress_port);
        }

        ecn_acl.apply(ig_md, ig_md.lkp, ig_intr_md_for_tm.packet_color);
        system_acl.apply(
            ig_md, ig_md.lkp, ig_intr_md_for_tm, ig_intr_md_for_dprsr);

        // Only add bridged metadata if we are NOT bypassing egress pipeline.
        if (!ig_intr_md_for_tm.bypass_egress) {
            add_bridged_md(hdr.bridged_md, ig_md);
        }

        set_ig_intr_md(ig_md, ig_intr_md_for_dprsr, ig_intr_md_for_tm);
    }
}

control SwitchEgress(
        inout switch_header_t hdr,
        inout switch_egress_metadata_t eg_md,
        in egress_intrinsic_metadata_t eg_intr_md,
        in egress_intrinsic_metadata_from_parser_t eg_intr_from_prsr,
        inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
        inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {
    EgressPortMapping() egress_port_mapping;
    EgressAcl(
        EGRESS_MAC_ACL_TABLE_SIZE, EGRESS_IPV4_ACL_TABLE_SIZE, EGRESS_IPV6_ACL_TABLE_SIZE) acl;
    EgressQos() qos;
    EgressSystemAcl() system_acl;
    Rewrite(NEXTHOP_TABLE_SIZE, BD_TABLE_SIZE) rewrite;
    MirrorRewrite() mirror_rewrite;
    VlanXlate(VLAN_TABLE_SIZE, PORT_VLAN_TABLE_SIZE) vlan_xlate;
    VlanDecap() vlan_decap;
    MTU() mtu;
    WRED() wred;
    MulticastReplication() multicast_replication;

    apply {
        egress_port_mapping.apply(hdr, eg_md, eg_intr_md_for_dprsr, eg_intr_md.egress_port);
        multicast_replication.apply(
            eg_intr_md.egress_rid, eg_intr_md.egress_port, eg_md);
        if (eg_md.pkt_src != SWITCH_PKT_SRC_BRIDGED) {
            // Packet is mirrored.
            mirror_rewrite.apply(hdr, eg_md);
        } else {
            if (eg_md.port_type == SWITCH_PORT_TYPE_NORMAL) {
                vlan_decap.apply(hdr, eg_md);
                qos.apply(hdr, eg_intr_md.egress_port, eg_md);
                wred.apply(hdr, eg_md.qos, eg_intr_md, eg_md.flags.wred_drop);
            }
        }

        rewrite.apply(hdr, eg_md);
        acl.apply(hdr, eg_md.lkp, eg_md);
        mtu.apply(hdr, eg_md.checks.mtu);
        if (eg_md.port_type == SWITCH_PORT_TYPE_NORMAL) {
            vlan_xlate.apply(hdr, eg_md);
        }

        system_acl.apply(hdr, eg_md, eg_intr_md, eg_intr_md_for_dprsr);

        set_eg_intr_md(eg_md, eg_intr_md_for_dprsr, eg_intr_md_for_oport);
    }
}

Pipeline(SwitchIngressParser(),
        SwitchIngress(),
        SwitchIngressDeparser(),
        SwitchEgressParser(),
        SwitchEgress(),
        SwitchEgressDeparser()) pipe;

Switch(pipe) main;
