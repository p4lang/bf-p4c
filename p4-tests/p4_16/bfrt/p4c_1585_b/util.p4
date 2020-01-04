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

#include "types.p4"

// --------------------------------------------------------------------------

// Flow hash calculation.
Hash<bit<32>>(HashAlgorithm_t.CRC32) ip_hash;
Hash<bit<32>>(HashAlgorithm_t.CRC32) non_ip_hash;

action compute_ip_hash(in switch_lookup_fields_t lkp, out bit<32> hash) {
    hash = ip_hash.get({lkp.ipv4_src_addr,
                        lkp.ipv4_dst_addr,
                        lkp.ipv6_src_addr,
                        lkp.ipv6_dst_addr,
                        lkp.ip_proto,
                        lkp.l4_dst_port,
                        lkp.l4_src_port});
}

action compute_non_ip_hash(in switch_lookup_fields_t lkp, out bit<32> hash) {
    hash = non_ip_hash.get({lkp.mac_type, lkp.mac_src_addr, lkp.mac_dst_addr});
}

// --------------------------------------------------------------------------

// Bridged metadata fields for Egress pipeline.
action add_bridged_md(
        inout switch_bridged_metadata_h bridged_md, in switch_ingress_metadata_t ig_md) {
    bridged_md.setValid();
    bridged_md.src = SWITCH_PKT_SRC_BRIDGED;
    bridged_md.base = {
        ig_md.port, ig_md.ifindex, ig_md.bd, ig_md.nexthop, ig_md.lkp.pkt_type,
        ig_md.flags.routed, ig_md.flags.peer_link,
        ig_md.qos.tc, ig_md.cpu_reason, ig_md.timestamp, ig_md.qos.qid};

#ifdef EGRESS_ACL_ENABLE
    bridged_md.acl = {ig_md.lkp.l4_src_port,
                      ig_md.lkp.l4_src_port,
                      ig_md.lkp.tcp_flags,
                      ig_md.l4_port_label};
#endif

#ifdef TUNNEL_ENABLE
    bridged_md.tunnel =
        {ig_md.tunnel.index, ig_md.outer_nexthop, ig_md.hash[15:0], ig_md.tunnel.terminate};
#endif

#ifdef DTEL_ENABLE
    bridged_md.dtel = {ig_md.dtel.report_type, ig_md.dtel.session_id, ig_md.hash};
#endif

        // -----------------------------
        // ----- Extreme Networks -----
        // -----------------------------

        // metadata
        bridged_md.orig_pkt_had_nsh                  = ig_md.orig_pkt_had_nsh;

        bridged_md.nsh_extr_valid                    = ig_md.nsh_extr.valid;
        bridged_md.nsh_extr_end_of_chain             = ig_md.nsh_extr.end_of_chain;

        // base: word 0

        // base: word 1
        bridged_md.nsh_extr_spi                      = ig_md.nsh_extr.spi;
        bridged_md.nsh_extr_si                       = ig_md.nsh_extr.si;

        // ext: type 2 - word 0

        // ext: type 2 - word 1+
        bridged_md.nsh_extr_srvc_func_bitmask_local  = ig_md.nsh_extr.extr_srvc_func_bitmask_local;  //  1 byte
        bridged_md.nsh_extr_srvc_func_bitmask_remote = ig_md.nsh_extr.extr_srvc_func_bitmask_remote; //  1 byte
        bridged_md.nsh_extr_tenant_id                = ig_md.nsh_extr.extr_tenant_id;                //  3 bytes
        bridged_md.nsh_extr_flow_type                = ig_md.nsh_extr.extr_flow_type;                //  1 byte?
}

// --------------------------------------------------------------------------

action set_ig_intr_md(in switch_ingress_metadata_t ig_md,
                      inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
                      inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm) {
#ifdef MULTICAST_ENABLE
// Set PRE hash values
//XXX Compiler doesn't like this copy!!!!
//  ig_intr_md_for_tm.level1_mcast_hash = hash[12:0];
//  ig_intr_md_for_tm.level2_mcast_hash = hash[28:16];
#endif
    ig_intr_md_for_tm.mcast_grp_b = ig_md.multicast.id;
#if __TARGET_TOFINO__ == 1
    ig_intr_md_for_dprsr.mirror_type = (bit<3>) ig_md.mirror.type;
#elif __TARGET_TOFINO__ >= 2
    ig_intr_md_for_dprsr.mirror_type = (bit<4>) ig_md.mirror.type;
#endif
    ig_intr_md_for_tm.qid = ig_md.qos.qid;
}

// --------------------------------------------------------------------------

action set_eg_intr_md(in switch_egress_metadata_t eg_md,
                      inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
                      inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {
#ifdef PTP_ENABLE
    eg_intr_md_for_oport.capture_tstamp_on_tx = eg_md.flags.capture_ts;
#endif

#if __TARGET_TOFINO__ == 1
    eg_intr_md_for_dprsr.mirror_type = (bit<3>) eg_md.mirror.type;
#elif __TARGET_TOFINO__ >= 2
    eg_intr_md_for_dprsr.mirror_type = (bit<4>) eg_md.mirror.type;
    eg_intr_md_for_dprsr.mirror_io_select = 1;
#endif
}
