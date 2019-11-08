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
 * Milad Sharif (msharif@barefootnetworks.com)
 *
 ******************************************************************************/

//-------------------------------------------------------------------------------------------------
// ECN Access control list
//
// @param ig_md : Ingress metadata fields.
// @param lkp : Lookup fields.
// @param qos_md : QoS metadata fields.
// @param table_size : Size of the ACL table.
//-------------------------------------------------------------------------------------------------
control EcnAcl(in switch_ingress_metadata_t ig_md,
               in switch_lookup_fields_t lkp,
               inout switch_pkt_color_t pkt_color)(
               switch_uint32_t table_size=512) {
    action set_ingress_color(switch_pkt_color_t color) {
        pkt_color = color;
    }

    table acl {
        key =  {
            ig_md.port_lag_label : ternary;
            lkp.ip_tos : ternary;
            lkp.tcp_flags : ternary;
        }

        actions = {
            NoAction;
            set_ingress_color;
        }

        const default_action = NoAction;
        size = table_size;
    }

    apply {
        acl.apply();
    }
}

//-------------------------------------------------------------------------------------------------
// Weighted Random Early Dropping (WRED)
//
// @param hdr : Parse headers. Only ipv4.diffserv or ipv6.traffic_class are modified.
// @param eg_md : Egress metadata fields.
// @param qos_md
// @param eg_intr_md
// @param wred_sie : Number of WRED profiles.
//-------------------------------------------------------------------------------------------------
control WRED(inout switch_header_t hdr,
             in switch_qos_metadata_t qos_md,
             in egress_intrinsic_metadata_t eg_intr_md,
             out bool flag) {

    switch_wred_index_t index;
    switch_wred_stats_index_t stats_index;
    bit<1> drop_flag;
    const switch_uint32_t wred_size = 1 << switch_wred_index_width;
    // Per color/qid/port counter.
    const switch_uint32_t wred_index_table_size = 10480; // P4C-1549

    Counter<bit<32>, switch_wred_stats_index_t>(
        wred_index_table_size, CounterType_t.PACKETS_AND_BYTES) wred_stats;

    Wred<bit<19>, switch_wred_index_t>(wred_size, 1 /* drop value*/, 0 /* no drop value */) wred;

    action set_ipv4_ecn() {
        hdr.ipv4.diffserv[1:0] = SWITCH_ECN_CODEPOINT_CE;
        wred_stats.count(stats_index);
    }

    action set_ipv6_ecn() {
        hdr.ipv6.traffic_class[1:0] = SWITCH_ECN_CODEPOINT_CE;
        wred_stats.count(stats_index);
    }

    action drop() {
        flag = true;
    }

    // Packets from flows that are not ECN capable will continue to be dropped by RED (as was the
    // case before ECN) -- RFC2884
    table wred_action {
        key = {
            index : exact;
            hdr.ipv4.isValid() : ternary;
            hdr.ipv4.diffserv : ternary;
            hdr.ipv6.isValid() : ternary;
            hdr.ipv6.traffic_class : ternary;
        }

        actions = {
            NoAction;
            drop;
            set_ipv4_ecn;
            set_ipv6_ecn;
        }

        // Requires 4 entries per WRED profile to drop or mark IPv4/v6 packets.
        size = 4 * wred_size;
    }

    action set_wred_index(switch_wred_index_t wred_index,
                          switch_wred_stats_index_t wred_stats_index) {
        index = wred_index;
        stats_index = wred_stats_index;
        drop_flag = (bit<1>) wred.execute(qos_md.qdepth, wred_index);
    }

    table wred_index {
        key = {
           eg_intr_md.egress_port : exact;
           qos_md.qid : exact;
           qos_md.color : exact;
        }

        actions = {
            NoAction;
            set_wred_index;
        }

        const default_action = NoAction;
        size = wred_index_table_size;
    }

    apply {
#ifdef WRED_ENABLE
        wred_index.apply();
        if (drop_flag == 1) {
            wred_action.apply();
        }
#endif
    }
}

