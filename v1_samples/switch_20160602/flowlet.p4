/*
 * Flowlet related processing
 */

#include "flowlet_bmv2.p4"

#ifdef HARLYN
/*
 * flowlet metadata
 */
header_type flowlet_metadata_t {
    fields {
        id : 16;                            /* flowlet id */
        inactive_timeout : 32;              /* flowlet inactivity timeout */
    }
}
metadata flowlet_metadata_t flowlet_metadata;

register flowlet_state {
    width : 64;
    instance_count : FLOWLET_MAP_SIZE;
}

blackbox stateful_alu flowlet_alu {
    reg : flowlet_state;
    initial_register_hi_value : 0;
    initial_register_lo_value : 0;
    //TODO inactivity_tout should be configurable.
    // (global_ts - flowlet_lastseen) > inactivity_tout
    condition_lo : i2e_metadata.ingress_tstamp - register_lo > 1;
    update_lo_2_value : i2e_metadata.ingress_tstamp;
    update_hi_1_value : register_hi + 1;
    update_hi_1_predicate: condition_lo;
    update_hi_2_value : register_hi;
    update_hi_2_predicate: not condition_lo;
    output_value : alu_hi;
    output_dst : flowlet_metadata.id;
}

action flowlet_lookup() {
    flowlet_alu.execute_stateful_alu_from_hash(flowlet_hash);
}
#endif /* HARLYN */

field_list flowlet_hash_fields {
    hash_metadata.hash1;
}

field_list_calculation flowlet_hash {
    input {
        flowlet_hash_fields;
    }
    algorithm : identity;
    output_width : FLOWLET_MAP_WIDTH;
}

table flowlet {
    actions {
        flowlet_lookup;
    }
    size : 1;
}

control process_flowlet {
    if (flowlet_metadata.inactive_timeout != 0) {
        apply(flowlet);
#ifndef HARLYN
        if (flowlet_metadata.inter_packet_gap != 0) {
            apply(new_flowlet);
        }
#endif /* HARLYN */
    }
}
