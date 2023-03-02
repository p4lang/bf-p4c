#ifndef _DTEL_
#define _DTEL_

// Data-plane telemetry (DTel).

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

	// ------------------------------------------------

    action enable_dod() {
        ig_intr_md_for_tm.deflect_on_drop = 1w1;
    }

    action disable_dod() {
        ig_intr_md_for_tm.deflect_on_drop = 1w0;
    }

    table config {
        key = {
            ig_md.dtel.report_type : ternary;
            ig_intr_md_for_tm.ucast_egress_port : ternary @name("egress_port");
            ig_md.qos.qid: ternary @name("qid");
            ig_md.multicast.id : ternary;
            ig_md.cpu_reason : ternary;  // to avoid validity issues, replaces
                                         // ig_intr_md_for_tm.copy_to_cpu
        }

        actions = {
            enable_dod;
            disable_dod;
        }

        size = table_size;
        const default_action = disable_dod;
    }

	// ------------------------------------------------

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

	// ------------------------------------------------

    action mirror() {
        mirror_md.type = SWITCH_MIRROR_TYPE_DTEL_DROP;
        mirror_md.src = SWITCH_PKT_SRC_CLONED_INGRESS;
    }

    action mirror_and_set_d_bit() {
        dtel_md.report_type = dtel_md.report_type | SWITCH_DTEL_REPORT_TYPE_DROP;
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
            mirror_and_set_d_bit;
        }

        const default_action = NoAction;
        // const entries = {
        //    (SWITCH_DROP_REASON_UNKNOWN, _) : NoAction();
        //    (_, SWITCH_DTEL_REPORT_TYPE_DROP &&& SWITCH_DTEL_REPORT_TYPE_DROP) : mirror();
        // }
    }

	// ------------------------------------------------

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
control DropReport(in switch_header_transport_t hdr,
                   in switch_egress_metadata_t eg_md,
                   in bit<32> hash, inout bit<2> flag) {

    // Two bit arrays of 128K bits.
    Register<bit<1>, bit<egress_dtel_drop_report_width>>(1 << egress_dtel_drop_report_width, 0) array1;
    Register<bit<1>, bit<egress_dtel_drop_report_width>>(1 << egress_dtel_drop_report_width, 0) array2;

    RegisterAction<bit<1>, bit<egress_dtel_drop_report_width>, bit<1>>(array1) filter1 = {
        void apply(inout bit<1> val, out bit<1> rv) {
            rv = val;
            val = 0b1;
        }
    };

    RegisterAction<bit<1>, bit<egress_dtel_drop_report_width>, bit<1>>(array2) filter2 = {
        void apply(inout bit<1> val, out bit<1> rv) {
            rv = val;
            val = 0b1;
        }
    };

    apply {
        if (eg_md.dtel.report_type & (SWITCH_DTEL_REPORT_TYPE_DROP |
                                      SWITCH_DTEL_SUPPRESS_REPORT |
                                      SWITCH_DTEL_REPORT_TYPE_ETRAP_CHANGE)
            == SWITCH_DTEL_REPORT_TYPE_DROP
            && hdr.dtel_drop_report.isValid())
            flag[0:0] = filter1.execute(hash[(egress_dtel_drop_report_width - 1):0]);

        if (eg_md.dtel.report_type & (SWITCH_DTEL_REPORT_TYPE_DROP |
                                      SWITCH_DTEL_SUPPRESS_REPORT |
                                      SWITCH_DTEL_REPORT_TYPE_ETRAP_CHANGE)
            == SWITCH_DTEL_REPORT_TYPE_DROP
            && hdr.dtel_drop_report.isValid())
            flag[1:1] = filter2.execute(hash[31:(32 - egress_dtel_drop_report_width)]);
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
    const bit<32> queue_table_size = 1024;
    const bit<32> queue_register_size = 2048;

	// ---------------------------------------------------------------

	// TABLE 1 AND ASSOCIATED REGISTERS (QUEUE ALERT)

    // Register to store latency/qdepth thresholds per (port, queue) pair.
    Register<switch_queue_alert_threshold_t, bit<16>>(queue_register_size) thresholds;

	// -----------------------

    RegisterAction<switch_queue_alert_threshold_t, bit<16>, bit<1>>(thresholds) check_thresholds = {
        void apply(inout switch_queue_alert_threshold_t reg, out bit<1> flag) {
            // Set the flag if either of qdepth or latency exceeds the threshold.
            if (reg.latency <= eg_md.dtel.latency || reg.qdepth <= (bit<32>) eg_md.qos.qdepth) {
                flag = 1;
            }
        }
    };

	// -----------------------

    action set_qmask(bit<32> quantization_mask) {
        // Quantize the latency.
        eg_md.dtel.latency = eg_md.dtel.latency & quantization_mask;
    }

    action set_qalert(bit<16> index, bit<16> quota, bit<32> quantization_mask) {
        qalert = check_thresholds.execute(index);
        quota_ = quota;
        set_qmask(quantization_mask);
    }

	@ways(2)
    table queue_alert {
        key = {
            eg_md.qos.qid : exact @name("qid");
            eg_md.egress_port : exact @name("port");
        }

        actions = {
            set_qalert;
            set_qmask;
        }

        size = queue_table_size;
    }

	// ---------------------------------------------------------------

	// TABLE 2 AND ASSOCIATED REGISTERS (CHECK QUOTA)

    // Register to store last observed quantized latency and a counter to track available quota.
    Register<switch_queue_report_quota_t, bit<16>>(queue_register_size) quotas;

	// -----------------------

    RegisterAction<switch_queue_report_quota_t, bit<16>, bit<1>>(quotas) reset_quota = {
        void apply(inout switch_queue_report_quota_t reg, out bit<1> flag) {
            flag = 0;
            reg.counter = (bit<32>) quota_[15:0];
        }
    };

	// -----------------------

    RegisterAction<switch_queue_report_quota_t, bit<16>, bit<1>>(quotas) check_latency_and_update_quota = {
        void apply(inout switch_queue_report_quota_t reg, out bit<1> flag) {
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

	// -----------------------

    // This is only used for deflected packets.
    RegisterAction<switch_queue_report_quota_t, bit<16>, bit<1>>(quotas) update_quota = {
        void apply(inout switch_queue_report_quota_t reg, out bit<1> flag) {
            // Send a report if number of generated reports is not exceeding the quota
            if (reg.counter > 0) {
                reg.counter = reg.counter - 1;
                flag = 1;
            }
        }
    };

	// -----------------------

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
            eg_md.pkt_src : exact;
            qalert : exact;
            eg_md.qos.qid : exact @name("qid");
            eg_md.egress_port : exact @name("port");
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

	// ------------------------------------------------

    apply {
        if (eg_md.pkt_src == SWITCH_PKT_SRC_BRIDGED)
            queue_alert.apply();
        check_quota.apply();
    }
}

// =============================================================================
// =============================================================================
// =============================================================================

control FlowReport(in switch_egress_metadata_t eg_md, out bit<2> flag) {

    bit<16> digest;

    //TODO(msharif): Use a better hash
    Hash<bit<16>>(HashAlgorithm_t.CRC16) hash;

    // Two bit arrays of 32K bits. The probability of false positive is about 1% for 4K flows.
    Register<bit<16>, bit<egress_dtel_flow_report_width>>(1 << egress_dtel_flow_report_width, 0) array1;
    Register<bit<16>, bit<egress_dtel_flow_report_width>>(1 << egress_dtel_flow_report_width, 0) array2;

    // Encodes 2 bit information for flow state change detection
    // rv = 0b1* : New flow.
    // rv = 0b01 : No change in digest is detected.

    @reduction_or_group("filter")
    RegisterAction<bit<16>, bit<egress_dtel_flow_report_width>, bit<2>>(array1) filter1 = {
        void apply(inout bit<16> reg, out bit<2> rv) {
            if (reg == 16w0) {
               rv = 0b10;
            } else if (reg == digest) {
                rv = 0b01;
            }
            reg = digest;
        }
    };

    @reduction_or_group("filter")
    RegisterAction<bit<16>, bit<egress_dtel_flow_report_width>, bit<2>>(array2) filter2 = {
        void apply(inout bit<16> reg, out bit<2> rv) {
            if (reg == 16w0) {
               rv = 0b10;
            } else if (reg == digest) {
                rv = 0b01;
            }
            reg = digest;
        }
    };

    apply {
#ifdef DTEL_FLOW_REPORT_ENABLE
#ifndef DTEL_QUEUE_REPORT_ENABLE
        // TODO: Add table with action set_qmask
#endif
        digest = hash.get({eg_md.dtel.latency, eg_md.ingress_port, eg_md.egress_port, eg_md.dtel.hash});

        if (eg_md.dtel.report_type & (SWITCH_DTEL_REPORT_TYPE_FLOW | SWITCH_DTEL_SUPPRESS_REPORT) == SWITCH_DTEL_REPORT_TYPE_FLOW
            && eg_md.pkt_src == SWITCH_PKT_SRC_BRIDGED)
//          flag = filter1.execute(eg_md.dtel.hash[15:0]);
            flag = filter1.execute(eg_md.dtel.hash[(egress_dtel_flow_report_width - 1):0]);

        if (eg_md.dtel.report_type & (SWITCH_DTEL_REPORT_TYPE_FLOW | SWITCH_DTEL_SUPPRESS_REPORT) == SWITCH_DTEL_REPORT_TYPE_FLOW
            && eg_md.pkt_src == SWITCH_PKT_SRC_BRIDGED)
//          flag = flag | filter2.execute(eg_md.dtel.hash[31:16]);
            flag = flag | filter2.execute(eg_md.dtel.hash[31:(32 - egress_dtel_flow_report_width)]);
#endif
    }
}

// =============================================================================
// =============================================================================
// =============================================================================

control IngressDtel(in  switch_header_transport_t hdr,
                    in switch_lookup_fields_t lkp,
                    inout switch_ingress_metadata_t ig_md,
                    in bit<16> hash,
                    inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
                    inout ingress_intrinsic_metadata_for_tm_t ig_intr_for_tm
) (
	switch_uint32_t DTEL_SELECTOR_TABLE_SIZE,
	switch_uint32_t DTEL_MAX_MEMBERS_PER_GROUP,
	switch_uint32_t DTEL_GROUP_TABLE_SIZE
) {

    DeflectOnDrop() dod;
    MirrorOnDrop() mod;

    Hash<switch_uint16_t>(HashAlgorithm_t.IDENTITY) selector_hash;
    ActionProfile(DTEL_SELECTOR_TABLE_SIZE) dtel_action_profile;
    ActionSelector(dtel_action_profile,
                   selector_hash,
                   SelectorMode_t.FAIR,
                   DTEL_MAX_MEMBERS_PER_GROUP,
                   DTEL_GROUP_TABLE_SIZE) session_selector;

	// ------------------------------------------------

    action set_mirror_session(switch_mirror_session_t session_id) {
        ig_md.dtel.session_id = session_id;
    }

    table mirror_session {
        key = {
            hdr.ethernet.isValid() : ternary;
            hash : selector;
        }
        actions = {
            NoAction;
            set_mirror_session;
        }

        implementation = session_selector;
    }

	// ------------------------------------------------

    apply {
#ifdef DTEL_ENABLE
#if defined(DTEL_DROP_REPORT_ENABLE) || defined(DTEL_QUEUE_REPORT_ENABLE)
        dod.apply(ig_md, ig_intr_for_tm);
#ifdef DTEL_DROP_REPORT_ENABLE
        if (ig_md.mirror.type == SWITCH_MIRROR_TYPE_INVALID)
            mod.apply(ig_md.drop_reason, ig_md.dtel, ig_md.mirror);
#endif /* DTEL_DROP_REPORT_ENABLE */
#endif /* DTEL_DROP_REPORT_ENABLE || DTEL_QUEUE_REPORT_ENABLE */
//        mirror_session.apply(); // derek hack
#endif
    }
}

// =============================================================================
// =============================================================================
// =============================================================================

control DtelConfig(inout switch_header_transport_t hdr,
                   inout switch_egress_metadata_t eg_md,
                   inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr
) (
	MODULE_DEPLOYMENT_PARAMS
) {

    Register<bit<32>, switch_mirror_session_t>(1024) seq_number;
    RegisterAction<bit<32>, switch_mirror_session_t, bit<32>>(seq_number) get_seq_number = {
        void apply(inout bit<32> reg, out bit<32> rv) {
#ifdef INT_V2
            /* Telemetry Report v2.0 Sequence Number definition is 22 bits,
             * while hdr.dtel.seq_number definition is 24 bits.
             * Wrap sequence number at 2^22. */
            if (reg > 0x3ffffe) {
                reg = 0;
            } else {
                reg = reg + 1;
            }
#else
            reg = reg + 1;
#endif
            rv = reg;
        }
    };

	// ------------------------------------------------

    action mirror_switch_local() {
        // Generate switch local telemetry report for flow/queue reports.
        eg_md.mirror.type = SWITCH_MIRROR_TYPE_DTEL_SWITCH_LOCAL;
        eg_md.mirror.src = SWITCH_PKT_SRC_CLONED_EGRESS;
    }

    action mirror_switch_local_and_set_q_bit() {
        eg_md.dtel.report_type = eg_md.dtel.report_type | SWITCH_DTEL_REPORT_TYPE_QUEUE;
        mirror_switch_local();
    }

    action mirror_switch_local_and_drop() {
        mirror_switch_local();
        eg_intr_md_for_dprsr.drop_ctl = 0x1;
    }

    action mirror_switch_local_and_set_f_bit_and_drop() {
        eg_md.dtel.report_type = eg_md.dtel.report_type | SWITCH_DTEL_REPORT_TYPE_FLOW;
        mirror_switch_local();
        eg_intr_md_for_dprsr.drop_ctl = 0x1;
    }

    action mirror_switch_local_and_set_q_f_bits_and_drop() {
        eg_md.dtel.report_type = eg_md.dtel.report_type | (
            SWITCH_DTEL_REPORT_TYPE_QUEUE | SWITCH_DTEL_REPORT_TYPE_FLOW);
        mirror_switch_local();
        eg_intr_md_for_dprsr.drop_ctl = 0x1;
    }

    action mirror_drop() {
        // Generate telemetry drop report.
        eg_md.mirror.type = SWITCH_MIRROR_TYPE_DTEL_DROP;
        eg_md.mirror.src = SWITCH_PKT_SRC_CLONED_EGRESS;
    }

    action mirror_drop_and_set_q_bit() {
        eg_md.dtel.report_type = eg_md.dtel.report_type | SWITCH_DTEL_REPORT_TYPE_QUEUE;
        mirror_drop();
    }

    action mirror_clone() {
        // Generate (sampled) clone on behalf of downstream IFA capable devices
        eg_md.mirror.type = SWITCH_MIRROR_TYPE_SIMPLE;
        eg_md.mirror.src = SWITCH_PKT_SRC_CLONED_EGRESS;
        eg_md.dtel.session_id = eg_md.dtel.clone_session_id;
    }

    action drop() {
        // Drop the report.
        eg_intr_md_for_dprsr.drop_ctl = 0x1;
    }

    action update(
            switch_uint32_t switch_id,
            switch_dtel_hw_id_t hw_id,
#ifdef INT_V2
            bit<8> md_length,
            bit<16> rep_md_bits,
#else
            bit<4> next_proto,
#endif
            switch_dtel_report_type_t report_type) {
        hdr.dtel.setValid();
        hdr.dtel.hw_id = hw_id;
        hdr.dtel.switch_id = switch_id;
        hdr.dtel.d_q_f = (bit<3>) report_type;
        hdr.dtel.reserved = 0;
        hdr.dtel.ds_md_bits = 0;
        hdr.dtel.ds_md_status = 0;
        hdr.dtel.domain_specific_id = 0;
#ifdef INT_V2
        hdr.dtel.version = 2;
        hdr.dtel.seq_number =
            (bit<24>) get_seq_number.execute(eg_md.mirror.session_id);
        // rep_type = 1 (INT)
        // in_type = 3 (Ethernet)
        hdr.dtel.report_length[15:8] = 0x13;
        hdr.dtel.md_length = md_length;
        hdr.dtel.rep_md_bits = rep_md_bits;
		eg_md.payload_len = eg_md.payload_len + 16w44; // derek added
#else
        hdr.dtel.version = 0;
        hdr.dtel.next_proto = next_proto;
        hdr.dtel.seq_number = get_seq_number.execute(eg_md.mirror.session_id);
        hdr.dtel.timestamp = (bit<32>) eg_md.ingress_timestamp;
#endif
    }

    action update_and_mirror_truncate(
            switch_uint32_t switch_id,
            switch_dtel_hw_id_t hw_id,
            bit<4> next_proto,
            bit<8> md_length,
            bit<16> rep_md_bits,
            switch_dtel_report_type_t report_type) {
#ifdef INT_V2
        update(switch_id, hw_id, md_length, rep_md_bits, report_type);
#else
        update(switch_id, hw_id, next_proto, report_type);
#endif
        eg_md.mirror.type = SWITCH_MIRROR_TYPE_SIMPLE;
        eg_md.mirror.src = SWITCH_PKT_SRC_CLONED_EGRESS;
        // Drop the report.
        eg_intr_md_for_dprsr.drop_ctl = 0x1;
    }

    action update_and_set_etrap(
            switch_uint32_t switch_id,
            switch_dtel_hw_id_t hw_id,
            bit<4> next_proto,
            bit<8> md_length,
            bit<16> rep_md_bits,
            switch_dtel_report_type_t report_type,
            bit<2> etrap_status) {
        hdr.dtel.setValid();
        hdr.dtel.hw_id = hw_id;
        hdr.dtel.switch_id = switch_id;
        hdr.dtel.d_q_f = (bit<3>) report_type;
#ifdef INT_V2
        hdr.dtel.version = 2;
        hdr.dtel.seq_number =
            (bit<24>) get_seq_number.execute(eg_md.mirror.session_id);
        // rep_type = 1 (INT)
        // in_type = 3 (Ethernet)
        hdr.dtel.report_length[15:8] = 0x13;
        hdr.dtel.md_length = md_length;
        hdr.dtel.reserved[3:2] = etrap_status;  // etrap indication
        hdr.dtel.rep_md_bits = rep_md_bits;
#else
        hdr.dtel.version = 0;
        hdr.dtel.next_proto = next_proto;
        hdr.dtel.reserved[14:13] = etrap_status;  // etrap indication
        hdr.dtel.seq_number = get_seq_number.execute(eg_md.mirror.session_id);
        hdr.dtel.timestamp = (bit<32>) eg_md.ingress_timestamp;
#endif
    }

    action set_ipv4_dscp_all(bit<6> dscp) {
        hdr.ipv4.tos[7:2] = dscp;
    }

    action set_ipv6_dscp_all(bit<6> dscp) {
		if((OUTER_IPV6_ENABLE) || (INNER_IPV6_ENABLE)) {
	        hdr.ipv6.tos[7:2] = dscp;
		}
    }

    action set_ipv4_dscp_2(bit<1> dscp_bit_value) {
        hdr.ipv4.tos[2:2] = dscp_bit_value;
    }

    action set_ipv6_dscp_2(bit<1> dscp_bit_value) {
		if((OUTER_IPV6_ENABLE) || (INNER_IPV6_ENABLE)) {
	        hdr.ipv6.tos[2:2] = dscp_bit_value;
		}
    }

    action set_ipv4_dscp_3(bit<1> dscp_bit_value) {
        hdr.ipv4.tos[3:3] = dscp_bit_value;
    }

    action set_ipv6_dscp_3(bit<1> dscp_bit_value) {
		if((OUTER_IPV6_ENABLE) || (INNER_IPV6_ENABLE)) {
	        hdr.ipv6.tos[3:3] = dscp_bit_value;
		}
    }

    action set_ipv4_dscp_4(bit<1> dscp_bit_value) {
        hdr.ipv4.tos[4:4] = dscp_bit_value;
    }

    action set_ipv6_dscp_4(bit<1> dscp_bit_value) {
		if((OUTER_IPV6_ENABLE) || (INNER_IPV6_ENABLE)) {
	        hdr.ipv6.tos[4:4] = dscp_bit_value;
		}
    }

    action set_ipv4_dscp_5(bit<1> dscp_bit_value) {
        hdr.ipv4.tos[5:5] = dscp_bit_value;
    }

    action set_ipv6_dscp_5(bit<1> dscp_bit_value) {
		if((OUTER_IPV6_ENABLE) || (INNER_IPV6_ENABLE)) {
	        hdr.ipv6.tos[5:5] = dscp_bit_value;
		}
    }

    action set_ipv4_dscp_6(bit<1> dscp_bit_value) {
        hdr.ipv4.tos[6:6] = dscp_bit_value;
    }

    action set_ipv6_dscp_6(bit<1> dscp_bit_value) {
		if((OUTER_IPV6_ENABLE) || (INNER_IPV6_ENABLE)) {
	        hdr.ipv6.tos[6:6] = dscp_bit_value;
		}
    }

    action set_ipv4_dscp_7(bit<1> dscp_bit_value) {
        hdr.ipv4.tos[7:7] = dscp_bit_value;
    }

    action set_ipv6_dscp_7(bit<1> dscp_bit_value) {
		if((OUTER_IPV6_ENABLE) || (INNER_IPV6_ENABLE)) {
	        hdr.ipv6.tos[7:7] = dscp_bit_value;
		}
    }

    /* config table is responsible for triggering the flow/queue report generation for normal
     * traffic and updating the dtel report headers for telemetry reports.
     *
     * pkt_src        report_type     drop_ flow_ queue drop_  drop_ action
     *                                flag  flag  _flag reason report
     *                                                         valid
     * CLONED_INGRESS DROP | SUPPRESS *     *     *     *      y     update(df)
     *                | FLOW
     * CLONED_INGRESS DROP | FLOW     0b11  *     *     *      y     drop
     * CLONED_INGRESS DROP | FLOW     *     *     *     *      y     update(df)
     * CLONED_INGRESS DROP | SUPPRESS *     *     *     *      y     update(d)
     * CLONED_INGRESS DROP            0b11  *     *     *      y     drop
     * CLONED_INGRESS DROP            *     *     *     *      y     update(d)
     *
     * DEFLECTED      DROP | SUPPRESS *     *     1     *      *     update(dqf)
     *                | FLOW
     * DEFLECTED      DROP | FLOW     0b11  *     1     *      *     update(dqf)
     * DEFLECTED      DROP | FLOW     *     *     1     *      *     update(dqf)
     * DEFLECTED      DROP | SUPPRESS *     *     *     *      *     update(df)
     *                | FLOW
     * DEFLECTED      DROP | FLOW     0b11  *     *     *      *     drop
     * DEFLECTED      DROP | FLOW     *     *     *     *      *     update(df)
     * DEFLECTED      DROP | SUPPRESS *     *     1     *      *     update(dq)
     * DEFLECTED      DROP            0b11  *     1     *      *     update(dq)
     * DEFLECTED      DROP            *     *     1     *      *     update(dq)
     * DEFLECTED      DROP | SUPPRESS *     *     *     *      *     update(d)
     * DEFLECTED      DROP            0b11  *     *     *      *     drop
     * DEFLECTED      DROP            *     *     *     *      *     update(d)
     * DEFLECTED      *               *     *     0     *      *     drop
     * DEFLECTED      *               *     *     1     *      *     update(q)
     *
     * CLONED_EGRESS  FLOW | QUEUE    *     *     *     *      n     update(qf)
     * CLONED_EGRESS  QUEUE           *     *     *     *      n     update(q)
     * CLONED_EGRESS  FLOW            *     *     *     *      n     update(f)
     * CLONED_EGRESS  DROP | SUPPRESS *     *     *     *      y     update(dqf)
     *                | FLOW | QUEUE
     * CLONED_EGRESS  DROP            0b11  *     *     *      y     update(dqf)
     *                | FLOW | QUEUE
     * CLONED_EGRESS  DROP            *     *     *     *      y     update(dqf)
     *                | FLOW | QUEUE
     * CLONED_EGRESS  DROP | SUPPRESS *     *     *     *      y     update(df)
     *                | FLOW
     * CLONED_EGRESS  DROP | FLOW     0b11  *     *     *      y     drop
     * CLONED_EGRESS  DROP | FLOW     *     *     *     *      y     update(df)
     * CLONED_EGRESS  DROP | SUPPRESS *     *     *     *      y     update(dq)
     *                | QUEUE
     * CLONED_EGRESS  DROP | QUEUE    0b11  *     *     *      y     update(dq)
     * CLONED_EGRESS  DROP | QUEUE    *     *     *     *      y     update(dq)
     * CLONED_EGRESS  DROP | SUPPRESS *     *     *     *      y     update(d)
     * CLONED_EGRESS  DROP            0b11  *     *     *      y     drop
     * CLONED_EGRESS  DROP            *     *     *     *      y     update(d)
     *
     * BRIDGED        FLOW | SUPPRESS *     *     1     0      *     mirror_sw
     * BRIDGED        FLOW            *     0b00  1     0      *     mirror_sw_l
     * BRIDGED        FLOW            *     0b1*  1     0      *     mirror_sw_l
     * BRIDGED        *               *     *     1     0      *     mirror_sw_l
     * BRIDGED        FLOW | SUPPRESS *     *     *     0      *     mirror_sw_l
     * BRIDGED        FLOW            *     0b00  *     0      *     mirror_sw_l
     * BRIDGED        FLOW            *     0b1*  *     0      *     mirror_sw_l
     * BRIDGED        FLOW            *     TCPfl *     0      *     mirror_sw_l
     *
     * BRIDGED        DROP            *     *     *     0      *     NoAction
     * User specified entries for egress drop_reason values: mirror or NoAction
     * BRIDGED        DROP            *     *     1     value  *     mirror_drop
     * BRIDGED        DROP            *     *     *     value  *     action
     * BRIDGED        *               *     *     1     value  *     mirror_sw_l
     * Drop report catch all entries
     * BRIDGED        DROP            *     *     1     *      *     mirror_drop
     * BRIDGED        DROP            *     *     *     *      *     mirror_drop
     * BRIDGED        *               *     *     1     *      *     mirror_sw_l
     *
     * *              *               *     *     *     *      *     NoAction
     * This table is asymmetric as hw_id is pipe specific.
     */

    table config {
        key = {
            eg_md.pkt_src : ternary;
            eg_md.dtel.report_type : ternary;
            eg_md.dtel.drop_report_flag : ternary;
            eg_md.dtel.flow_report_flag : ternary;
            eg_md.dtel.queue_report_flag : ternary;
//          eg_md.drop_reason : ternary;
            eg_md.mirror.type : ternary;
            hdr.dtel_drop_report.isValid() : ternary;
#ifdef DTEL_FLOW_REPORT_ENABLE
            eg_md.lkp_1.tcp_flags[2:0] : ternary;
#endif
#if defined(DTEL_IFA_CLONE) || defined(DTEL_IFA_EDGE)
            hdr.ipv4.isValid() : ternary;
            hdr.ipv6.isValid() : ternary;
#endif
#ifdef DTEL_IFA_EDGE
            hdr.ipv4.diffserv[7:2] : ternary;
            hdr.ipv6.traffic_class[7:2] : ternary;
#endif
#ifdef DTEL_IFA_CLONE
            eg_md.dtel.ifa_cloned : ternary;
#endif
        }

        actions = {
            NoAction;
            drop;
            mirror_switch_local;
            mirror_switch_local_and_set_q_bit;
            mirror_drop;
            mirror_drop_and_set_q_bit;
            update;
#if __TARGET_TOFINO__ == 1
            update_and_mirror_truncate;
#endif
#ifdef DTEL_ETRAP_REPORT_ENABLE
            update_and_set_etrap;
#endif
#ifdef DTEL_IFA_CLONE
            mirror_clone;
            set_ipv4_dscp_all;
            set_ipv6_dscp_all;
            set_ipv4_dscp_2;
            set_ipv6_dscp_2;
            set_ipv4_dscp_3;
            set_ipv6_dscp_3;
            set_ipv4_dscp_4;
            set_ipv6_dscp_4;
            set_ipv4_dscp_5;
            set_ipv6_dscp_5;
            set_ipv4_dscp_6;
            set_ipv6_dscp_6;
            set_ipv4_dscp_7;
            set_ipv6_dscp_7;
#endif
#ifdef DTEL_IFA_EDGE
            mirror_switch_local_and_set_f_bit_and_drop;
            mirror_switch_local_and_set_q_f_bits_and_drop;
#endif
        }

        const default_action = NoAction;
    }

	// ------------------------------------------------

    apply {
        config.apply();
    }
}

// =============================================================================
// =============================================================================
// =============================================================================

control IntEdge(inout switch_egress_metadata_t eg_md)(
                switch_uint32_t port_table_size=288) {

	// ------------------------------------------------

    action set_clone_mirror_session_id(switch_mirror_session_t session_id) {
        eg_md.dtel.clone_session_id = session_id;
    }

    action set_ifa_edge() {
        eg_md.dtel.report_type = eg_md.dtel.report_type | SWITCH_DTEL_IFA_EDGE;
    }

    table port_lookup {
        key = {
            eg_md.egress_port : exact;
        }
        actions = {
            NoAction;
            set_clone_mirror_session_id;
            set_ifa_edge;
        }

        const default_action = NoAction;
        size = port_table_size;
    }

	// ------------------------------------------------

    apply {
        if (eg_md.pkt_src == SWITCH_PKT_SRC_BRIDGED)
            port_lookup.apply();
    }
}

// =============================================================================
// =============================================================================
// =============================================================================

control EgressDtel(inout switch_header_transport_t hdr,
                   inout switch_egress_metadata_t eg_md,
                   in egress_intrinsic_metadata_t eg_intr_md,
                   in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
                   in bit<32> hash) {

    DropReport() drop_report;
    QueueReport() queue_report;
    FlowReport() flow_report0;
    FlowReport() flow_report1;
    FlowReport() flow_report2;
    FlowReport() flow_report3;
    FlowReport() flow_report4;
    FlowReport() flow_report5;
    FlowReport() flow_report6;
    FlowReport() flow_report7;
    FlowReport() flow_report8;
    FlowReport() flow_report9;
    FlowReport() flow_report10;
    FlowReport() flow_report11;
    FlowReport() flow_report12;
    FlowReport() flow_report13;
    FlowReport() flow_report14;
    FlowReport() flow_report15;
    IntEdge() int_edge;

	// ------------------------------------------------

    action convert_ingress_port(switch_port_t port) {
#ifdef INT_V2
        hdr.dtel_metadata_1.ingress_port = port;
#else
        hdr.dtel_report.ingress_port = port;
#endif
    }

    table ingress_port_conversion {
        key = {
#ifdef INT_V2
          hdr.dtel_metadata_1.ingress_port : exact @name("port");
          hdr.dtel_metadata_1.isValid() : exact @name("dtel_report_valid");
#else
          hdr.dtel_report.ingress_port : exact @name("port");
          hdr.dtel_report.isValid() : exact @name("dtel_report_valid");
#endif
        }
        actions = {
            NoAction;
            convert_ingress_port;
        }

        const default_action = NoAction;
    }

	// ------------------------------------------------

    action convert_egress_port(switch_port_t port) {
#ifdef INT_V2
        hdr.dtel_metadata_1.egress_port = port;
#else
        hdr.dtel_report.egress_port = port;
#endif
    }

    table egress_port_conversion {
        key = {
#ifdef INT_V2
          hdr.dtel_metadata_1.egress_port : exact @name("port");
          hdr.dtel_metadata_1.isValid() : exact @name("dtel_report_valid");
#else
          hdr.dtel_report.egress_port : exact @name("port");
          hdr.dtel_report.isValid() : exact @name("dtel_report_valid");
#endif
        }
        actions = {
            NoAction;
            convert_egress_port;
        }

        const default_action = NoAction;
    }

	// ------------------------------------------------

    action update_dtel_timestamps() {
        eg_md.dtel.latency = eg_intr_md_from_prsr.global_tstamp[31:0] -
                             eg_md.ingress_timestamp[31:0];
#ifdef INT_V2
        eg_md.egress_timestamp = eg_intr_md_from_prsr.global_tstamp;
#else
        eg_md.egress_timestamp = eg_intr_md_from_prsr.global_tstamp[31:0];
#endif
    }

    apply {
#ifdef DTEL_ENABLE
        update_dtel_timestamps();
        if (eg_md.pkt_src == SWITCH_PKT_SRC_DEFLECTED && hdr.dtel_drop_report.isValid())
#ifdef INT_V2
            eg_md.egress_port = hdr.dtel_metadata_1.egress_port;
#else
            eg_md.egress_port = hdr.dtel_report.egress_port;
#endif
        ingress_port_conversion.apply();
        egress_port_conversion.apply();

#ifdef DTEL_QUEUE_REPORT_ENABLE
        queue_report.apply(eg_md, eg_intr_md, eg_md.dtel.queue_report_flag);
#endif

#ifdef DTEL_FLOW_REPORT_ENABLE
        /* if DTEL_QUEUE_REPORT_ENABLE,
         * flow_report must come after queue_report,
         * since latency masking is done in table queue_alert */

#if egress_dtel_flow_report_num_blocks == 1
		flow_report0.apply(eg_md, eg_md.dtel.flow_report_flag);
#elif egress_dtel_flow_report_num_blocks == 2
		bit<1> upper_addr = eg_md.dtel.hash[31:31];
		if(upper_addr == 0) {
			flow_report0.apply(eg_md, eg_md.dtel.flow_report_flag);
		} else {
			flow_report1.apply(eg_md, eg_md.dtel.flow_report_flag);
		}
#elif egress_dtel_flow_report_num_blocks == 4
		bit<2> upper_addr = eg_md.dtel.hash[31:30];
		if(upper_addr == 0) {
			flow_report0.apply(eg_md, eg_md.dtel.flow_report_flag);
		} else if(upper_addr == 1) {
			flow_report1.apply(eg_md, eg_md.dtel.flow_report_flag);
		} else if(upper_addr == 2) {
			flow_report2.apply(eg_md, eg_md.dtel.flow_report_flag);
		} else {
			flow_report3.apply(eg_md, eg_md.dtel.flow_report_flag);
		}
#elif egress_dtel_flow_report_num_blocks == 8
		bit<3> upper_addr = eg_md.dtel.hash[31:29];
		if(upper_addr == 0) {
			flow_report0.apply(eg_md, eg_md.dtel.flow_report_flag);
		} else if(upper_addr == 1) {
			flow_report1.apply(eg_md, eg_md.dtel.flow_report_flag);
		} else if(upper_addr == 2) {
			flow_report2.apply(eg_md, eg_md.dtel.flow_report_flag);
		} else if(upper_addr == 3) {
			flow_report3.apply(eg_md, eg_md.dtel.flow_report_flag);
		} else if(upper_addr == 4) {
			flow_report4.apply(eg_md, eg_md.dtel.flow_report_flag);
		} else if(upper_addr == 5) {
			flow_report5.apply(eg_md, eg_md.dtel.flow_report_flag);
		} else if(upper_addr == 6) {
			flow_report6.apply(eg_md, eg_md.dtel.flow_report_flag);
		} else {
			flow_report7.apply(eg_md, eg_md.dtel.flow_report_flag);
		}
#elif egress_dtel_flow_report_num_blocks == 16
		bit<4> upper_addr = eg_md.dtel.hash[31:28];
		if(upper_addr == 0) {
			flow_report0.apply(eg_md, eg_md.dtel.flow_report_flag);
		} else if(upper_addr == 1) {
			flow_report1.apply(eg_md, eg_md.dtel.flow_report_flag);
		} else if(upper_addr == 2) {
			flow_report2.apply(eg_md, eg_md.dtel.flow_report_flag);
		} else if(upper_addr == 3) {
			flow_report3.apply(eg_md, eg_md.dtel.flow_report_flag);
		} else if(upper_addr == 4) {
			flow_report4.apply(eg_md, eg_md.dtel.flow_report_flag);
		} else if(upper_addr == 5) {
			flow_report5.apply(eg_md, eg_md.dtel.flow_report_flag);
		} else if(upper_addr == 6) {
			flow_report6.apply(eg_md, eg_md.dtel.flow_report_flag);
		} else if(upper_addr == 7) {
			flow_report7.apply(eg_md, eg_md.dtel.flow_report_flag);
		} else if(upper_addr == 8) {
			flow_report8.apply(eg_md, eg_md.dtel.flow_report_flag);
		} else if(upper_addr == 9) {
			flow_report9.apply(eg_md, eg_md.dtel.flow_report_flag);
		} else if(upper_addr == 10) {
			flow_report10.apply(eg_md, eg_md.dtel.flow_report_flag);
		} else if(upper_addr == 11) {
			flow_report11.apply(eg_md, eg_md.dtel.flow_report_flag);
		} else if(upper_addr == 12) {
			flow_report12.apply(eg_md, eg_md.dtel.flow_report_flag);
		} else if(upper_addr == 13) {
			flow_report13.apply(eg_md, eg_md.dtel.flow_report_flag);
		} else if(upper_addr == 14) {
			flow_report14.apply(eg_md, eg_md.dtel.flow_report_flag);
		} else {
			flow_report15.apply(eg_md, eg_md.dtel.flow_report_flag);
		}
#endif

#endif

#ifdef DTEL_DROP_REPORT_ENABLE
        drop_report.apply(hdr, eg_md, hash, eg_md.dtel.drop_report_flag);
#endif

#if defined(DTEL_IFA_CLONE) || defined(DTEL_IFA_EDGE)
        int_edge.apply(eg_md);
#endif

#ifdef INT_V2
#if __TARGET_TOFINO__ == 1
        // For deflected packets, adjust report_length for upcoming truncation
        // Note that eg_md.pkt_length already contains max report_length
        if (eg_md.pkt_src == SWITCH_PKT_SRC_DEFLECTED) {
            eg_md.pkt_length = hdr.dtel.report_length |-| eg_md.pkt_length;
            hdr.dtel.report_length = hdr.dtel.report_length - eg_md.pkt_length;
        }
#endif /* __TARGET_TOFINO__ == 1 */

        if (hdr.dtel.report_length & 0xff00 != 0)
            hdr.dtel.report_length = 0xff;
#endif
#endif /* DTEL_ENABLE */
    }
}

#endif /* _DTEL_ */
