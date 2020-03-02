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

#include "types.p4"

// -----------------------------------------------------------------------------

// Flow hash calculation.
Hash<bit<32>>(HashAlgorithm_t.CRC32) ip_hash;

action compute_ip_hash(
    in switch_lookup_fields_t lkp,
    out bit<32> hash
) {
    hash = ip_hash.get({
#ifdef BUG_10439_WORKAROUND
        lkp.ip_src_addr_3,
        lkp.ip_src_addr_2,
        lkp.ip_src_addr_1,
        lkp.ip_src_addr_0,
        lkp.ip_dst_addr_3,
        lkp.ip_dst_addr_2,
        lkp.ip_dst_addr_1,
        lkp.ip_dst_addr_0,
#else
        lkp.ip_src_addr,
        lkp.ip_dst_addr,
#endif // BUG_10439_WORKAROUND
            
        lkp.ip_proto,
        lkp.l4_dst_port,
        lkp.l4_src_port
    });
}

Hash<bit<32>>(HashAlgorithm_t.CRC32) non_ip_hash;

action compute_non_ip_hash(
    in switch_lookup_fields_t lkp,
    out bit<32> hash
) {
    hash = non_ip_hash.get({
        lkp.mac_type,
        lkp.mac_src_addr,
        lkp.mac_dst_addr
    });
}

// -----------------------------------------------------------------------------

// Bridged metadata fields for Egress pipeline.
action add_bridged_md(
    inout switch_bridged_metadata_h bridged_md,
    in switch_ingress_metadata_t ig_md
) {
    bridged_md.setValid();
    bridged_md.src = SWITCH_PKT_SRC_BRIDGED;
    bridged_md.base = {
        ig_md.port,
        ig_md.port_lag_index,
        ig_md.bd,
        ig_md.nexthop,
//      ig_md.lkp.pkt_type,
//      ig_md.timestamp,
        ig_md.flags.rmac_hit,

        ig_md.nsh_type1.hdr_is_new,
        ig_md.nsh_type1.sf_bitmask         //  1 byte
    };

#ifdef TUNNEL_ENABLE
    bridged_md.tunnel = {
        ig_md.tunnel_0.index,
        ig_md.outer_nexthop,
        ig_md.hash[15:0],

        ig_md.tunnel_0.terminate,
        ig_md.tunnel_1.terminate,
        ig_md.tunnel_2.terminate,
		ig_md.nsh_terminate
    };
#endif

}

// -----------------------------------------------------------------------------

action set_ig_intr_md(
    in switch_ingress_metadata_t ig_md,
    inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
    inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm
) {
    // Set PRE hash values
//  ig_intr_md_for_tm.level1_mcast_hash = ig_md.hash[12:0];
    ig_intr_md_for_tm.level2_mcast_hash = ig_md.hash[28:16];
    ig_intr_md_for_tm.mcast_grp_b = ig_md.multicast.id;
}
