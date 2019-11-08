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
 ******************************************************************************/

#ifndef _P4_QOS_
#define _P4_QOS_

#include "acl.p4"
#include "meter.p4"

//-----------------------------------------------------------------------------
// Common QoS related actions used by QoS ACL slices or QoS dscp/pcp mappings.
//-----------------------------------------------------------------------------
action set_ingress_tc(inout switch_qos_metadata_t qos_md, switch_tc_t tc) {
    qos_md.tc = tc;
}

action set_ingress_color(inout switch_qos_metadata_t qos_md, switch_pkt_color_t color) {
    qos_md.color = color;
}

action set_ingress_tc_and_color(
        inout switch_qos_metadata_t qos_md, switch_tc_t tc, switch_pkt_color_t color) {
    set_ingress_tc(qos_md, tc);
    set_ingress_color(qos_md, color);
}

action set_ingress_tc_color_and_meter(
        inout switch_qos_metadata_t qos_md,
        switch_tc_t tc,
        switch_pkt_color_t color,
        switch_policer_meter_index_t index) {
#ifdef INGRESS_POLICER_ENABLE
    set_ingress_tc_and_color(qos_md, tc, color);
    qos_md.meter_index = index;
#endif
}

control MacQosAcl(
    in switch_lookup_fields_t lkp,
    inout switch_qos_metadata_t qos_md,
    inout switch_ingress_metadata_t ig_md)(
    switch_uint32_t table_size=512) {

    table acl {
        key = {
            INGRESS_MAC_ACL_KEY
            ig_md.port_lag_label : ternary;
            lkp.pcp : ternary;
        }

        actions = {
            NoAction;
            set_ingress_tc(qos_md);
            set_ingress_color(qos_md);
            set_ingress_tc_and_color(qos_md);
            set_ingress_tc_color_and_meter(qos_md);
        }

        size = table_size;
    }

    apply {
        acl.apply();
    }
}

control Ipv4QosAcl(
    in switch_lookup_fields_t lkp,
    inout switch_qos_metadata_t qos_md,
    inout switch_ingress_metadata_t ig_md)(
    switch_uint32_t table_size=512) {

    table acl {
        key = {
            INGRESS_IPV4_ACL_KEY
            ig_md.port_lag_label : ternary;
            ig_md.bd_label : ternary;
            ig_md.l4_port_label : ternary;
        }

        actions = {
            NoAction;
            set_ingress_tc(qos_md);
            set_ingress_color(qos_md);
            set_ingress_tc_and_color(qos_md);
            set_ingress_tc_color_and_meter(qos_md);
        }

        size = table_size;
    }

    apply {
        acl.apply();
    }
}

control Ipv6QosAcl(
    in switch_lookup_fields_t lkp,
    inout switch_qos_metadata_t qos_md,
    inout switch_ingress_metadata_t ig_md)(
    switch_uint32_t table_size=512) {

    table acl {
        key = {
            INGRESS_IPV6_ACL_KEY
            ig_md.port_lag_label : ternary;
            ig_md.bd_label : ternary;
            ig_md.l4_port_label : ternary;
        }

        actions = {
            NoAction;
            set_ingress_tc(qos_md);
            set_ingress_color(qos_md);
            set_ingress_tc_and_color(qos_md);
            set_ingress_tc_color_and_meter(qos_md);
        }

        size = table_size;
    }

    apply {
        acl.apply();
    }
}

control IngressQos(
        in switch_header_t hdr,
        in switch_lookup_fields_t lkp,
        inout switch_qos_metadata_t qos_md,
        inout switch_ingress_metadata_t ig_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm)(
        switch_uint32_t dscp_map_size=1024,
        switch_uint32_t pcp_map_size=1024) {

    const bit<32> ppg_table_size = 1024;
    const bit<32> queue_table_size = 1024;
    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) ppg_stats;
    IngressPolicer(1 << switch_policer_meter_index_width) policer;
    MacQosAcl() mac_acl;
    Ipv4QosAcl() ipv4_acl;
    Ipv6QosAcl() ipv6_acl;

    table dscp_tc_map {
        key = {
            qos_md.group : exact;
            lkp.ip_tos : exact;
        }

        actions = {
            NoAction;
            set_ingress_tc(qos_md);
            set_ingress_color(qos_md);
            set_ingress_tc_and_color(qos_md);
            set_ingress_tc_color_and_meter(qos_md);
        }

        size = dscp_map_size;
    }

    table pcp_tc_map {
        key = {
            qos_md.group : ternary;
            lkp.pcp : exact;
        }

        actions = {
            NoAction;
            set_ingress_tc(qos_md);
            set_ingress_color(qos_md);
            set_ingress_tc_and_color(qos_md);
            set_ingress_tc_color_and_meter(qos_md);
        }

        size = pcp_map_size;
    }


    action set_icos(switch_cos_t icos) {
        ig_intr_md_for_tm.ingress_cos = icos;
    }

    action set_queue(switch_qid_t qid) {
        ig_md.qos.qid = qid;
    }

    action set_icos_and_queue(switch_cos_t icos, switch_qid_t qid) {
        set_icos(icos);
        set_queue(qid);
    }

    table traffic_class {
        key = {
            ig_md.port : ternary;
            qos_md.color : ternary;
            qos_md.tc : exact;
        }

        actions = {
            set_icos;
            set_queue;
            set_icos_and_queue;
        }

        size = queue_table_size;
    }

    action count() {
        ppg_stats.count();
    }

    // Asymmetric table to maintain statistics per local port and cos pair.
    table ppg {
        key = {
            ig_md.port : exact @name("port");
            ig_intr_md_for_tm.ingress_cos : exact @name("icos");
        }

        actions = {
            @defaultonly NoAction;
            count;
        }

        const default_action = NoAction;
        size = ppg_table_size;
        counters = ppg_stats;
    }

    apply {
#ifdef QOS_ENABLE
        if (!BYPASS(QOS)) {
#ifdef QOS_ACL_ENABLE
            if (qos_md.trust_mode & SWITCH_QOS_TRUST_MODE_TRUST_DSCP == SWITCH_QOS_TRUST_MODE_TRUST_DSCP &&
                    lkp.ip_type == SWITCH_IP_TYPE_IPV4) {
                ipv4_acl.apply(lkp, qos_md, ig_md);
            } else if (qos_md.trust_mode & SWITCH_QOS_TRUST_MODE_TRUST_DSCP == SWITCH_QOS_TRUST_MODE_TRUST_DSCP &&
                    lkp.ip_type == SWITCH_IP_TYPE_IPV6) {
#ifdef IPV6_ENABLE
                ipv6_acl.apply(lkp, qos_md, ig_md);
#endif /* IPV6_ENABLE */
            } else if (qos_md.trust_mode & SWITCH_QOS_TRUST_MODE_TRUST_PCP == SWITCH_QOS_TRUST_MODE_TRUST_PCP &&
                    hdr.vlan_tag[0].isValid()) {
                mac_acl.apply(lkp, qos_md, ig_md);
            }
#else
            if (qos_md.trust_mode & SWITCH_QOS_TRUST_MODE_TRUST_DSCP == SWITCH_QOS_TRUST_MODE_TRUST_DSCP &&
                    lkp.ip_type != SWITCH_IP_TYPE_NONE) {
                dscp_tc_map.apply();
            } else if(qos_md.trust_mode & SWITCH_QOS_TRUST_MODE_TRUST_PCP == SWITCH_QOS_TRUST_MODE_TRUST_PCP &&
                    hdr.vlan_tag[0].isValid()) {
                pcp_tc_map.apply();
            }
#endif /* QOS_ACL_ENABLE */
        }

        policer.apply(ig_md, ig_md.qos, ig_md.flags.qos_policer_drop);
        traffic_class.apply();
        ppg.apply();
#endif /* QOS_ENABLE */
    }
}


control EgressQos(inout switch_header_t hdr,
                  in switch_port_t port,
                  inout switch_egress_metadata_t eg_md)(
                  switch_uint32_t table_size=1024) {

    const bit<32> queue_table_size = 1024;
    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) queue_stats;

    // Overwrites 6-bit dscp only.
    action set_ipv4_dscp(bit<6> dscp) {
        hdr.ipv4.diffserv[7:2] = dscp;
    }

    action set_ipv4_tos(switch_uint8_t tos) {
        hdr.ipv4.diffserv = tos;
    }

    // Overwrites 6-bit dscp only.
    action set_ipv6_dscp(bit<6> dscp) {
#ifdef IPV6_ENABLE
        hdr.ipv6.traffic_class[7:2] = dscp;
#endif
    }

    action set_ipv6_tos(switch_uint8_t tos) {
#ifdef IPV6_ENABLE
        hdr.ipv6.traffic_class = tos;
#endif
    }

    action set_vlan_pcp(bit<3> pcp) {
        eg_md.lkp.pcp = pcp;
    }

    table qos_map {
        key = {
            eg_md.qos.group : exact @name("group");
            eg_md.qos.tc : exact @name("tc");
            eg_md.qos.color : exact @name("color");
            hdr.ipv4.isValid() : exact;
            hdr.ipv6.isValid() : exact;
        }

        actions = {
            NoAction;
            set_ipv4_dscp;
            set_ipv4_tos;
            set_ipv6_dscp;
            set_ipv6_tos;
            set_vlan_pcp;
        }

        const default_action = NoAction;
        size = table_size;
    }

    action count() {
        queue_stats.count();
    }

    // Asymmetric table to maintain statistics per local port and queue pair. This table does NOT
    // take care of packets that get dropped or sent to cpu by system acl.
    table queue {
        key = {
            port : exact;
            eg_md.qos.qid : exact @name("qid");
        }

        actions = {
            @defaultonly NoAction;
            count;
        }

        size = queue_table_size;
        const default_action = NoAction;
        counters = queue_stats;
    }

    apply {
#ifdef QOS_ENABLE
        qos_map.apply();
        queue.apply();
#endif /* QOS_ENABLE */
    }
}

#endif /* _P4_QOS_ */
