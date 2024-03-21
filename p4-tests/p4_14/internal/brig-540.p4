#include "tofino/stateful_alu_blackbox.p4"

#define DTEL_HASH_WIDTH                        16
#define DTEL_BLOOM_FILTER_SIZE                 65536
#define DTEL_FLOW_HASH_WIDTH 32
#define DTEL_FLOW_HASH_RANGE 4294967296 // 2^32
#define DTEL_DIGEST_WIDTH    16         // size of each cell
#define DTEL_DIGEST_RANGE    65536      // 2^16

header_type dtel_metadata_t {
    fields {
        // flow hash for mirror load balancing and flow state change detection
        flow_hash           : DTEL_FLOW_HASH_WIDTH;

        // mirror id for mirror load balancing
        mirror_session_id   : 10;

        // quantized latency for flow state change detection
        quantized_latency   : 32;

        // local digest at egress pipe for flow state change detection
        local_digest        : DTEL_DIGEST_WIDTH;

        // encodes 2 bit information for flow state change detection
        // MSB = 1 if old == 0 in any filter --> new flow.
        // LSB = 1 if new == old in any filter --> no value change
        // suppress report if bfilter_output == 1 (MSB == 0 and LSB == 1).
        bfilter_output      : 2;

        // indicates if queue latency and/or depth exceed thresholds
        queue_alert         : 1;

        // common index for port-qid tuple for queue report tables
        queue_alert_index   : 10;

        // for regular egress indicates if queue latency and/or depth changed
        queue_change        : 1;

        // is 1 if we can still send more queue_report packets that have not changes
        queue_report_quota  : 1;

        // True if hit Mirror on Drop watchlist with watch action
        // higher bit is set if DoD is requested in the watchlist
        mod_watchlist_hit   : 2;

        // True if queue-based deflect on drop is enabled
        queue_dod_enable    : 1;

        // Uppoer 6 bits represent the dscp of report packets
        // Lower 2 bits can be used to pass control from ingress to egress
        dscp_report         : 8;

        // set by ingress_port_properties, matched in watchlists
        port_lag_label      : 8;
    }
}

metadata dtel_metadata_t dtel_md;

field_list dtel_flow_hash_field {
    dtel_md.flow_hash;
}

field_list_calculation dtel_eg_hash_1 {
    input { dtel_flow_hash_field; }
    algorithm : crc_16;
    output_width : DTEL_HASH_WIDTH;
}

register dtel_eg_bfilter_reg_1{
    width : DTEL_DIGEST_WIDTH;
    static : dtel_eg_bfilter_1;
    instance_count : DTEL_BLOOM_FILTER_SIZE;
}

blackbox stateful_alu dtel_eg_bfilter_alu_1{
    reg: dtel_eg_bfilter_reg_1;

    condition_hi: register_lo == 0;
    condition_lo: register_lo == dtel_md.local_digest;
    update_hi_2_predicate: condition_hi;
    update_hi_2_value: 2;
    update_hi_1_predicate: condition_lo;
    update_hi_1_value: 1;
    update_lo_1_value: dtel_md.local_digest;

    output_predicate: condition_lo or condition_hi;
    output_value: alu_hi;
    output_dst: dtel_md.bfilter_output;
    // reduction_or_group: or_group_egress;
}

action run_dtel_eg_bfilter_1() {
    dtel_eg_bfilter_alu_1.execute_stateful_alu_from_hash(dtel_eg_hash_1);
}

table dtel_eg_bfilter_1 {
    actions { run_dtel_eg_bfilter_1; }
    default_action : run_dtel_eg_bfilter_1;
}

parser start { return ingress; }

control ingress {
    apply(dtel_eg_bfilter_1);
}
