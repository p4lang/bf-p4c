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

// Data-plane telemetry (DTel).

//-----------------------------------------------------------------------------
// DTel ACL for v4/v6 traffic that specifies which flows to monitor.
//
// @param lkp : Lookup fields.
// @param ig_md : Ingress metadata fields.
// @param report_type : Telemetry report type is a bit-map that indicates which type of telemetry
// reports (D/Q/F) can be generated for the tracked flow.
//-----------------------------------------------------------------------------
control DtelAcl(in switch_lookup_fields_t lkp,
                in switch_ingress_metadata_t ig_md,
                out switch_dtel_report_type_t report_type)(
                switch_uint32_t table_size=512) {
    action acl_hit(switch_dtel_report_type_t type) {
        report_type = type;
    }

    table acl {
        key = {
            ig_md.port_lag_label : ternary;
            ig_md.bd_label : ternary;
            ig_md.l4_port_label : ternary;
            lkp.ipv4_src_addr : ternary;
            lkp.ipv4_dst_addr : ternary;
            lkp.ipv6_src_addr : ternary;
            lkp.ipv6_dst_addr : ternary;
            lkp.ip_proto : ternary;
            lkp.tcp_flags : ternary;
        }

        actions = {
            acl_hit;
        }

        const default_action = acl_hit(SWITCH_DTEL_REPORT_TYPE_NONE);
        size = table_size;
    }

    apply {
        acl.apply();
    }
}

control Ipv4DtelAcl(in switch_lookup_fields_t lkp,
                    in switch_ingress_metadata_t ig_md,
                    out switch_dtel_report_type_t report_type)(
                    switch_uint32_t table_size=512) {
    action acl_hit(switch_dtel_report_type_t type) {
        report_type = type;
    }

    table acl {
        key = {
            INGRESS_IPV4_ACL_KEY
            ig_md.port_lag_label : ternary;
            ig_md.bd_label : ternary;
            ig_md.l4_port_label : ternary;
        }

        actions = {
            acl_hit();
        }

        const default_action = acl_hit(SWITCH_DTEL_REPORT_TYPE_NONE);
        size = table_size;
    }

    apply {
        acl.apply();
    }
}

control Ipv6DtelAcl(in switch_lookup_fields_t lkp,
                    in switch_ingress_metadata_t ig_md,
                    out switch_dtel_report_type_t report_type)(
                    switch_uint32_t table_size=512) {
    action acl_hit(switch_dtel_report_type_t type) {
        report_type = type;
    }

    table acl {
        key = {
            INGRESS_IPV6_ACL_KEY
            ig_md.port_lag_label : ternary;
            ig_md.bd_label : ternary;
            ig_md.l4_port_label : ternary;
        }

        actions = {
            acl_hit();
        }

        const default_action = acl_hit(SWITCH_DTEL_REPORT_TYPE_NONE);
        size = table_size;
    }

    apply {
        acl.apply();
    }
}

//-----------------------------------------------------------------------------
// Deflect on drop configuration checks if deflect on drop is enabled for a given queue/port pair.
// DOD must be only enabled for unicast traffic.
//
// @param report_type : Telemetry report type.
// @param ig_intr_for_tm : Ingress metadata fiels consumed by traffic manager.
// @param table_size
//-----------------------------------------------------------------------------
control DeflectOnDrop(
        in switch_ingress_metadata_t ig_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm)(
        switch_uint32_t table_size=1024) {

    action enable_dod() {
        ig_intr_md_for_tm.deflect_on_drop = 1;
    }

    action disable_dod() {
        ig_intr_md_for_tm.deflect_on_drop = 0;
    }

    table config {
        key = {
            ig_md.dtel.report_type : ternary;
            ig_intr_md_for_tm.ucast_egress_port : ternary @name("egress_port");
            ig_md.qos.qid: ternary @name("qid");
            ig_md.multicast.id : ternary;
        }

        actions = {
            enable_dod;
            disable_dod;
        }

        size = table_size;
        const default_action = disable_dod;
    }

    apply {
        config.apply();
    }
}

//-----------------------------------------------------------------------------
// Mirror on drop configuration
// Checks if mirror on drop is enabled for a given drop reason.
//
// @param report_type : Telemetry report type.
// @param ig_intr_for_tm : Ingress metadata fiels consumed by traffic manager.
// @param table_size
//-----------------------------------------------------------------------------
control MirrorOnDrop(in switch_drop_reason_t drop_reason,
                     inout switch_dtel_metadata_t dtel_md,
                     inout switch_mirror_metadata_t mirror_md) {
    action mirror() {
        mirror_md.type = SWITCH_MIRROR_TYPE_DTEL_DROP;
        mirror_md.src = SWITCH_PKT_SRC_CLONED_INGRESS;
    }

    table config {
        key = {
            drop_reason : ternary;
            dtel_md.report_type : ternary;
        }

        actions = {
            NoAction;
            mirror;
        }

        const default_action = NoAction;
        // const entries = {
        //    (SWITCH_DROP_REASON_UNKNOWN, _) : NoAction();
        //    (_, SWITCH_DTEL_REPORT_TYPE_DROP &&& SWITCH_DTEL_REPORT_TYPE_DROP) : mirror();
        // }
    }

    apply {
       config.apply();
    }
}


//-----------------------------------------------------------------------------
// Simple bloom filter for drop report suppression to avoid generating duplicate reports.
//
// @param hash : Hash value used to query the bloom filter.
// @param flag : A flag indicating that the report needs to be suppressed.
//-----------------------------------------------------------------------------
control DropReport(in switch_dtel_metadata_t dtel_md, in bit<32> hash, inout bit<2> flag) {
    // Two bit arrays of 128K bits.
    Register<bit<1>, bit<17>>(1 << 17, 1) array1;
    Register<bit<1>, bit<17>>(1 << 17, 1) array2;
    RegisterAction<bit<1>, bit<17>, bit<1>>(array1) filter1 = {
        void apply(inout bit<1> val, out bit<1> rv) {
            rv = val;
        }
    };

    RegisterAction<bit<1>, bit<17>, bit<1>>(array2) filter2 = {
        void apply(inout bit<1> val, out bit<1> rv) {
            rv = val;
        }
    };

    apply {
        if (dtel_md.report_type & SWITCH_DTEL_REPORT_TYPE_FLOW == SWITCH_DTEL_REPORT_TYPE_FLOW)
            flag[0:0] = filter1.execute(hash[16:0]);
        if (dtel_md.report_type & SWITCH_DTEL_REPORT_TYPE_FLOW == SWITCH_DTEL_REPORT_TYPE_FLOW)
            flag[1:1] = filter2.execute(hash[31:15]);
    }
}

//-----------------------------------------------------------------------------
// Generates queue reports if hop latency (or queue depth) exceeds a configurable thresholds.
// Quota-based report suppression to avoid generating excessive amount of reports.
// @param port : Egress port
// @param qid : Queue Id.
// @param qdepth : Queue depth.
//-----------------------------------------------------------------------------
struct switch_queue_alert_threshold_t {
    bit<32> qdepth;
    bit<32> latency;
}

struct switch_queue_report_quota_t {
    bit<32> counter;
    bit<32> latency;  // Qunatized latency
}

// Quota policy -- The policy maintains counters to track the number of generated reports.

// @param flag : indicating whether to generate a telemetry report or not.
control QueueReport(inout switch_egress_metadata_t eg_md,
                    in egress_intrinsic_metadata_t eg_intr_md,
                    out bit<1> qalert) {
    // Quota for a (port, queue) pair.
    bit<16> quota_;
    const bit<32> queue_table_size = 2048;

    // Register to store latency/qdepth thresholds per (port, queue) pair.
    Register<switch_queue_alert_threshold_t, bit<16>>(queue_table_size) thresholds;
    RegisterAction<switch_queue_alert_threshold_t, bit<16>, bit<1>>(thresholds) check_thresholds = {
        void apply(inout switch_queue_alert_threshold_t reg, out bit<1> flag) {
            // Set the flag if either of qdepth or latency exceeds the threshold.
            if (reg.latency < eg_md.dtel.latency || reg.qdepth < (bit<32>) eg_intr_md.enq_qdepth) {
                flag = 1;
            }
        }
    };

    action set_qalert(bit<16> index, bit<16> quota, bit<32> quantization_mask) {
        qalert = check_thresholds.execute(index);
        quota_ = quota;
        // Quantize the latency.
        eg_md.dtel.latency = eg_md.dtel.latency & quantization_mask;
    }

    table queue_alert {
        key = {
            eg_md.qos.qid : exact @name("qid");
            eg_intr_md.egress_port : exact @name("port");
        }

        actions = {
            NoAction;
            set_qalert;
        }

        const default_action = NoAction;
        size = queue_table_size;
    }

    // Register to store last observed quantized latency and a counter to track available quota.
    Register<switch_queue_report_quota_t, bit<16>>(queue_table_size) quotas;
    RegisterAction<switch_queue_report_quota_t, bit<16>, bit<1>>(quotas) reset_quota = {
        void apply(inout switch_queue_report_quota_t reg, out bit<1> flag) {
            flag = 0;
            reg.counter = (bit<32>) quota_[15:0];
        }
    };

    RegisterAction<switch_queue_report_quota_t, bit<16>, bit<1>>(quotas) check_latency_and_update_quota = {
        void apply(inout switch_queue_report_quota_t reg, out bit<1> flag) {
            flag = 0;

            // Send a report if number of generated reports is not exceeding the quota
            if (reg.counter > 0) {
                reg.counter = reg.counter - 1;
                flag = 1;
            }

            // Send a report if quantized latency is changed.
            if (reg.latency != eg_md.dtel.latency) {
                reg.latency = eg_md.dtel.latency;
                flag = 1;
            }
        }
    };

    // This is only used for deflected packets.
    RegisterAction<switch_queue_report_quota_t, bit<16>, bit<1>>(quotas) update_quota = {
        void apply(inout switch_queue_report_quota_t reg, out bit<1> flag) {
            flag = 0;
            // Send a report if number of generated reports is not exceeding the quota
            if (reg.counter > 0) {
                reg.counter = reg.counter - 1;
                flag = 1;
            }
        }
    };


    action reset_quota_(bit<16> index) {
        qalert = reset_quota.execute(index);
    }

    action update_quota_(bit<16> index) {
        qalert = update_quota.execute(index);
    }

    action check_latency_and_update_quota_(bit<16> index) {
        qalert = check_latency_and_update_quota.execute(index);
    }

    table check_quota {
        key = {
            qalert : exact;
            eg_md.qos.qid : exact @name("qid");
            eg_intr_md.egress_port : exact @name("port");
        }

        actions = {
            NoAction;
            reset_quota_;
            update_quota_;
            check_latency_and_update_quota_;
        }

        const default_action = NoAction;
        size = 3 * queue_table_size;
    }

    apply {
#ifdef DTEL_QUEUE_REPORT_ENABLE
        if (eg_md.pkt_src == SWITCH_PKT_SRC_BRIDGED)
            queue_alert.apply();

        if (eg_md.pkt_src == SWITCH_PKT_SRC_BRIDGED)
            check_quota.apply();
#endif
    }
}


control FlowReport(inout switch_egress_metadata_t eg_md, out bit<2> flag) {
    bit<16> digest;

    //TODO(msharif): Use a better hash
    Hash<bit<16>>(HashAlgorithm_t.CRC16) hash;

    // Two bit arrays of 32K bits. The probability of false positive is about 1% for 4K flows.
    Register<bit<16>, bit<16>>(1 << 16, 1) array1;
    Register<bit<16>, bit<16>>(1 << 16, 1) array2;

    // Encodes 2 bit information for flow state change detection
    // rv = 0b1* : New flow.
    // rv = 0b01 : No change in digest is detected.

    @reduction_or_group("filter")
    RegisterAction<bit<16>, bit<16>, bit<2>>(array1) filter1 = {
        void apply(inout bit<16> reg, out bit<2> rv) {
            if (reg == digest) {
                rv = 1;
            } // else if (reg == 16w0) {
              //   rv = 2;
              // }
            reg = digest;
        }
    };

    @reduction_or_group("filter")
    RegisterAction<bit<16>, bit<16>, bit<2>>(array2) filter2 = {
        void apply(inout bit<16> reg, out bit<2> rv) {
            if (reg == digest) {
                rv = 0b01;
            } // else if (reg == 16w0) {
              //  rv = 0b10;
              // }
            reg = digest;
        }
    };

    apply {
#ifdef DTEL_FLOW_REPORT_ENABLE
        digest = hash.get({eg_md.dtel.latency, eg_md.ingress_port /* Add more fields */});
        if (eg_md.dtel.report_type & SWITCH_DTEL_REPORT_TYPE_FLOW == SWITCH_DTEL_REPORT_TYPE_FLOW)
            flag = filter1.execute(eg_md.dtel.hash[15:0]);
        if (eg_md.dtel.report_type & SWITCH_DTEL_REPORT_TYPE_FLOW == SWITCH_DTEL_REPORT_TYPE_FLOW)
            flag = filter2.execute(eg_md.dtel.hash[31:16]);
#endif
    }
}

control IngressDtel(in  switch_header_t hdr,
                    in switch_lookup_fields_t lkp,
                    inout switch_ingress_metadata_t ig_md,
                    in bit<16> hash,
                    inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
                    inout ingress_intrinsic_metadata_for_tm_t ig_intr_for_tm) {

    Ipv4DtelAcl() ipv4_dtel_acl;
    DtelAcl() dtel_acl;

    DeflectOnDrop() dod;
    MirrorOnDrop() mod;

    Hash<switch_uint16_t>(HashAlgorithm_t.IDENTITY) selector_hash;
    ActionSelector(120, selector_hash, SelectorMode_t.FAIR) session_selector;
    action set_mirror_session(switch_mirror_session_t session_id) {
        ig_md.dtel.session_id = session_id;
    }

    table mirror_session {
        key = { hash : selector; }
        actions = {
            NoAction;
            set_mirror_session;
        }

        implementation = session_selector;
    }

    apply {
#ifdef DTEL_ENABLE
#ifdef DTEL_ACL_ENABLE
        if (!BYPASS(ACL)) {
#ifdef IPV6_ENABLE
            dtel_acl.apply(lkp, ig_md, ig_md.dtel.report_type);
#else
            if (lkp.ip_type == SWITCH_IP_TYPE_IPV4) {
                ipv4_dtel_acl.apply(lkp, ig_md, ig_md.dtel.report_type);
            }
#endif /* IPV6_ENABLE */
        }
#endif /* DTEL_ACL_ENABLE */

#ifdef DTEL_DROP_REPORT_ENABLE
        dod.apply(ig_md, ig_intr_for_tm);
        mod.apply(ig_md.drop_reason, ig_md.dtel, ig_md.mirror);
#endif /* DTEL_DROP_REPORT_ENABLE */
        mirror_session.apply();
#endif
    }
}


control EgressDtel(inout switch_header_t hdr,
                   inout switch_egress_metadata_t eg_md,
                   in egress_intrinsic_metadata_t eg_intr_md,
                   in bit<32> hash,
                   inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {
    DropReport() drop_report;
    QueueReport() queue_report;
    FlowReport() flow_report;

    bit<2> drop_report_flag;
    bit<2> flow_report_flag;
    bit<1> queue_report_flag;

    Register<bit<32>, switch_mirror_session_t>(1024) seq_number;
    RegisterAction<bit<32>, switch_mirror_session_t, bit<32>>(seq_number) get_seq_number = {
        void apply(inout bit<32> reg, out bit<32> rv) {
            reg = reg + 1;
            rv = reg;
        }
    };

    action mirror() {
        // Generate switch local telemetry report for flow/queue reports.
        eg_md.mirror.type = SWITCH_MIRROR_TYPE_DTEL_SWITCH_LOCAL;
        eg_md.mirror.src = SWITCH_PKT_SRC_CLONED_EGRESS;
    }

    action drop() {
        // Drop the report.
        eg_intr_md_for_dprsr.drop_ctl = 0x1;
    }

    action update(
            switch_uint32_t switch_id,
            bit<6> hw_id,
            bit<4> next_proto,
            switch_dtel_report_type_t report_type) {
        hdr.dtel.setValid();
        hdr.dtel.version = 0;
        hdr.dtel.next_proto = next_proto;
        hdr.dtel.d_q_f = report_type;
        hdr.dtel.reserved = 0;
        hdr.dtel.hw_id = hw_id;
        hdr.dtel.seq_number = get_seq_number.execute(eg_md.dtel.session_id);
        hdr.dtel.timestamp = (bit<32>) eg_md.ingress_timestamp;
        hdr.dtel.switch_id = switch_id;
    }

    // config table is responsible for triggering the flow/queue report generation for normal
    // traffic and updating the dtel report headers for telemetry reports.
    // pkt_src         report_type drop_report_flag flow_report_flag queue_report_flag  action
    // CLONED_INGRESS  DROP        0                *                *                  update
    // CLONED_INGRESS  DROP        1                *                *                  drop
    // DEFLECTED       DROP        0                *                *                  update
    // DEFLECTED       DROP        1                *                *                  drop
    // BRIDGED         DROP        *                *                *                  NoAction
    // This table is asymmetric as hw_id is pipe specific.

    table config {
        key = {
            eg_md.pkt_src : ternary;
            eg_md.dtel.report_type : ternary;
            drop_report_flag : ternary;
            flow_report_flag : ternary;
            queue_report_flag : ternary;
        }

        actions = {
            NoAction;
            drop;
            mirror;
            update;
        }

        const default_action = NoAction;
    }

    action convert_ingress_port(switch_port_t port) {
        eg_md.ingress_port = port;
    }

    action convert_egress_port(switch_port_t port) {
        eg_md.port = port;
    }

    //TODO(msharif) :  Convert h/w port to front panel port for telemetry reports.
    table egress_port_conversion {
        key = { eg_md.port : exact @name("port"); }
        actions = {
            NoAction;
            convert_egress_port;
        }

        const default_action = NoAction;
    }

    table ingress_port_conversion {
        key = { eg_md.ingress_port : exact @name("port"); }
        actions = {
            NoAction;
            convert_ingress_port;
        }

        const default_action = NoAction;
    }

    apply {
#ifdef DTEL_ENABLE
        eg_md.dtel.latency =
            eg_md.timestamp[31:0] - eg_md.ingress_timestamp[31:0];
        if (eg_md.pkt_src == SWITCH_PKT_SRC_CLONED_INGRESS)
            drop_report.apply(eg_md.dtel, hash, drop_report_flag);

        if (eg_md.pkt_src == SWITCH_PKT_SRC_BRIDGED)
            flow_report.apply(eg_md, flow_report_flag);

        queue_report.apply(eg_md, eg_intr_md, queue_report_flag);

        if (eg_md.pkt_src != SWITCH_PKT_SRC_BRIDGED) {
            ingress_port_conversion.apply();
            egress_port_conversion.apply();
        }

        config.apply();
#endif
    }
}

