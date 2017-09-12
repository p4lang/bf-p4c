//#include <tofino/constants.p4>
#include <tofino/primitives.p4>
#include <tofino/intrinsic_metadata.p4>
#include <tofino/stateful_alu_blackbox.p4>
#include <tofino/pktgen_headers.p4>
//#include <tofino/pktgen_headers.p4>
//#include <tofino/wred_blackbox.p4>

#define MAC_LEARN_RECEIVER   0
#define TIMESTAMP_COUNT   143360
//#define TIMESTAMP_COUNT   131072
#define STAGE_TIMESTAMP_INDEX_BIT_COUNT   18
#define TIMESTAMP_INDEX_BIT_COUNT   21
#define TIMESTAMP_STAGE_COUNT   11
#define TIMESTAMP_STAGE_INDEX_MASK   0x1FFFF
#define TIMESTAMP_STAGE_SELECT_MASK   0x1E0000

header_type ethernet_t {
    fields {
        dstAddr : 48;
        srcAddr : 48;
        etherType : 16;
    }
}

header_type hct_metadata_t {
    fields {
        enable_capture_timestamp: 1;
        capture_timestamp_trigger: 1;
        timestamp_index: TIMESTAMP_INDEX_BIT_COUNT;
        stage_timestamp_index: STAGE_TIMESTAMP_INDEX_BIT_COUNT;
        timestamp_temp: 32;
        capture_timestamp_1: 4;
        capture_timestamp_2: 4;
        capture_timestamp_3: 4;
        capture_timestamp_4: 4;
        capture_timestamp_5: 4;
        capture_timestamp_6: 4;
        capture_timestamp_7: 4;
        capture_timestamp_8: 4;
        capture_timestamp_9: 4;
        capture_timestamp_10: 4;
        capture_timestamp_11: 4;
    }
}

header ethernet_t ethernet;
metadata hct_metadata_t hct_metadata;

action nop() {
} // end nop

action _drop() {
    drop();
} // end _drop

parser start {
    return parse_ethernet;
}

parser parse_ethernet {
    extract( ethernet );
    return ingress;
}


// =========================== Route START ===========================
action route( port_out ) {
    modify_field( ig_intr_md_for_tm.ucast_egress_port, port_out );
} // end l3_dst_miss

//@pragma idletime_precision 2
table route {
    reads {
        ig_intr_md.ingress_port: exact;
    }
    actions {
        _drop;
        route;
    }
    size : 260;
    //support_timeout: true;
} // end route
// =========================== Route END ===========================

// =========================== Synchronize Capture Timestamp Trigger START ===========================
action capture_timestamp_trigger_sync( enable ) {
    modify_field( hct_metadata.enable_capture_timestamp, enable );
} // end capture_timestamp_trigger_sync

table capture_timestamp_trigger_sync {
    actions {
        capture_timestamp_trigger_sync;
    }
    size: 1;
} // end capture_timestamp_trigger_sync
// =========================== Synchronize Capture Timestamp Trigger END ===========================

// =========================== Capture Timestamp Trigger START ===========================
action capture_timestamp_trigger( enable ) {
    modify_field( hct_metadata.capture_timestamp_trigger, enable );
} // end capture_timestamp_trigger

table capture_timestamp_trigger {
    reads {
        ig_intr_md.ingress_port: exact;
    }
    actions {
        capture_timestamp_trigger;
    }
    size : 5;
} // end capture_timestamp_trigger
// =========================== Capture Timestamp Trigger END ===========================

// =========================== Capture Timestamp Index START ===========================
register timestamp_index {
    width  : TIMESTAMP_INDEX_BIT_COUNT;
    instance_count : 1;
}

blackbox stateful_alu timestamp_index {
    reg : timestamp_index;
    condition_lo: register_lo < ( TIMESTAMP_STAGE_COUNT * TIMESTAMP_COUNT );
    update_lo_1_predicate: condition_lo;
    update_lo_1_value: register_lo + 1;
    output_value: register_lo;
    output_dst: hct_metadata.timestamp_index;
} // end timestamp_index

action timestamp_index_counter() {
    timestamp_index.execute_stateful_alu();
    modify_field( hct_metadata.timestamp_temp, eg_intr_md_from_parser_aux.egress_global_tstamp, 0xFFFFFFFF );
    //bit_and( eg_intr_md_from_parser_aux.egress_global_tstamp, 0xFFFFFFFF )
    //drop();
} // end timestamp_index_counter

table timestamp_index {
    actions {
        timestamp_index_counter;
    }
    size : 1;
} // end timestamp_index

register stage_timestamp_index {
    width  : TIMESTAMP_INDEX_BIT_COUNT;
    instance_count : 1;
}

blackbox stateful_alu stage_timestamp_index {
    reg : stage_timestamp_index;
    condition_lo: register_lo < TIMESTAMP_COUNT;
    update_lo_1_predicate: condition_lo;
    update_lo_1_value: register_lo + 1;
    update_lo_2_predicate: not condition_lo;
    update_lo_2_value: 0;
    output_value: register_lo;
    output_dst: hct_metadata.stage_timestamp_index;
} // end stage_timestamp_index

action stage_timestamp_index_counter() {
    stage_timestamp_index.execute_stateful_alu();
} // end timestamp_index_counter

table stage_timestamp_index {
    actions {
        stage_timestamp_index_counter;
    }
    size : 1;
} // end timestamp_index
// =========================== Capture Timestamp Index END ===========================

// =========================== Capture Timestamp START ===========================
register timestamp_1 {
    width  : 32;
    instance_count : TIMESTAMP_COUNT;
} // end timestamp_1

blackbox stateful_alu capture_timestamp_1 {
    reg : timestamp_1;
    condition_lo: hct_metadata.timestamp_index < ( 1 * TIMESTAMP_COUNT );
    condition_hi: hct_metadata.timestamp_index >= ( 0 * TIMESTAMP_COUNT );
    update_lo_1_predicate: condition_lo and condition_hi;
    update_lo_1_value: hct_metadata.timestamp_temp;
    output_value: predicate;
    output_dst: hct_metadata.capture_timestamp_1;
} // end capture_timestamp_1

action write_timestamp_1() {
    capture_timestamp_1.execute_stateful_alu( hct_metadata.stage_timestamp_index );
} // end write_timestamp_1

table capture_timestamp_1 {
//    reads {
//        //hct_metadata.enable_capture_timestamp: exact;
//        hct_metadata.timestamp_index mask TIMESTAMP_STAGE_SELECT_MASK: exact;
//    }
    actions {
//        nop;
        write_timestamp_1;
    }
} // end capture_timestamp_1

register timestamp_2 {
    width  : 32;
    instance_count : TIMESTAMP_COUNT;
} // end timestamp_2

blackbox stateful_alu capture_timestamp_2 {
    reg : timestamp_2;
    condition_lo: hct_metadata.timestamp_index < ( 2 * TIMESTAMP_COUNT );
    condition_hi: hct_metadata.timestamp_index >= ( 1 * TIMESTAMP_COUNT );
    update_lo_1_predicate: condition_lo and condition_hi;
    update_lo_1_value: hct_metadata.timestamp_temp;
    output_value: predicate;
    output_dst: hct_metadata.capture_timestamp_2;
} // end capture_timestamp_2

action write_timestamp_2() {
    capture_timestamp_2.execute_stateful_alu( hct_metadata.stage_timestamp_index );
} // end write_timestamp_2

table capture_timestamp_2 {
    actions {
        write_timestamp_2;
    }
} // end capture_timestamp_2

register timestamp_3 {
    width  : 32;
    instance_count : TIMESTAMP_COUNT;
} // end timestamp_3

blackbox stateful_alu capture_timestamp_3 {
    reg : timestamp_3;
    condition_lo: hct_metadata.timestamp_index < ( 3 * TIMESTAMP_COUNT );
    condition_hi: hct_metadata.timestamp_index >= ( 2 * TIMESTAMP_COUNT );
    update_lo_1_predicate: condition_lo and condition_hi;
    update_lo_1_value: hct_metadata.timestamp_temp;
    output_value: predicate;
    output_dst: hct_metadata.capture_timestamp_3;
} // end capture_timestamp_3

action write_timestamp_3() {
    capture_timestamp_3.execute_stateful_alu( hct_metadata.stage_timestamp_index );
} // end write_timestamp_3

table capture_timestamp_3 {
    actions {
        write_timestamp_3;
    }
} // end capture_timestamp_3

register timestamp_4 {
    width  : 32;
    instance_count : TIMESTAMP_COUNT;
} // end timestamp_4

blackbox stateful_alu capture_timestamp_4 {
    reg : timestamp_4;
    condition_lo: hct_metadata.timestamp_index < ( 4 * TIMESTAMP_COUNT );
    condition_hi: hct_metadata.timestamp_index >= ( 3 * TIMESTAMP_COUNT );
    update_lo_1_predicate: condition_lo and condition_hi;
    update_lo_1_value: hct_metadata.timestamp_temp;
    output_value: predicate;
    output_dst: hct_metadata.capture_timestamp_4;
} // end capture_timestamp_4

action write_timestamp_4() {
    capture_timestamp_4.execute_stateful_alu( hct_metadata.stage_timestamp_index );
} // end write_timestamp_4

table capture_timestamp_4 {
    actions {
        write_timestamp_4;
    }
} // end capture_timestamp_4

register timestamp_5 {
    width  : 32;
    instance_count : TIMESTAMP_COUNT;
} // end timestamp_5

blackbox stateful_alu capture_timestamp_5 {
    reg : timestamp_5;
    condition_lo: hct_metadata.timestamp_index < ( 5 * TIMESTAMP_COUNT );
    condition_hi: hct_metadata.timestamp_index >= ( 4 * TIMESTAMP_COUNT );
    update_lo_1_predicate: condition_lo and condition_hi;
    update_lo_1_value: hct_metadata.timestamp_temp;
    output_value: predicate;
    output_dst: hct_metadata.capture_timestamp_5;
} // end capture_timestamp_5

action write_timestamp_5() {
    capture_timestamp_5.execute_stateful_alu( hct_metadata.stage_timestamp_index );
} // end write_timestamp_5

table capture_timestamp_5 {
    actions {
        write_timestamp_5;
    }
} // end capture_timestamp_5

register timestamp_6 {
    width  : 32;
    instance_count : TIMESTAMP_COUNT;
} // end timestamp_6

blackbox stateful_alu capture_timestamp_6 {
    reg : timestamp_6;
    condition_lo: hct_metadata.timestamp_index < ( 6 * TIMESTAMP_COUNT );
    condition_hi: hct_metadata.timestamp_index >= ( 5 * TIMESTAMP_COUNT );
    update_lo_1_predicate: condition_lo and condition_hi;
    update_lo_1_value: hct_metadata.timestamp_temp;
    output_value: predicate;
    output_dst: hct_metadata.capture_timestamp_6;
} // end capture_timestamp_6

action write_timestamp_6() {
    capture_timestamp_6.execute_stateful_alu( hct_metadata.stage_timestamp_index );
} // end write_timestamp_6

table capture_timestamp_6 {
    actions {
        write_timestamp_6;
    }
} // end capture_timestamp_6

register timestamp_7 {
    width  : 32;
    instance_count : TIMESTAMP_COUNT;
} // end timestamp_7

blackbox stateful_alu capture_timestamp_7 {
    reg : timestamp_7;
    condition_lo: hct_metadata.timestamp_index < ( 7 * TIMESTAMP_COUNT );
    condition_hi: hct_metadata.timestamp_index >= ( 6 * TIMESTAMP_COUNT );
    update_lo_1_predicate: condition_lo and condition_hi;
    update_lo_1_value: hct_metadata.timestamp_temp;
    output_value: predicate;
    output_dst: hct_metadata.capture_timestamp_7;
} // end capture_timestamp_7

action write_timestamp_7() {
    capture_timestamp_7.execute_stateful_alu( hct_metadata.stage_timestamp_index );
} // end write_timestamp_7

table capture_timestamp_7 {
    actions {
        write_timestamp_7;
    }
} // end capture_timestamp_7

register timestamp_8 {
    width  : 32;
    instance_count : TIMESTAMP_COUNT;
} // end timestamp_8

blackbox stateful_alu capture_timestamp_8 {
    reg : timestamp_8;
    condition_lo: hct_metadata.timestamp_index < ( 8 * TIMESTAMP_COUNT );
    condition_hi: hct_metadata.timestamp_index >= ( 7 * TIMESTAMP_COUNT );
    update_lo_1_predicate: condition_lo and condition_hi;
    update_lo_1_value: hct_metadata.timestamp_temp;
    output_value: predicate;
    output_dst: hct_metadata.capture_timestamp_8;
} // end capture_timestamp_8

action write_timestamp_8() {
    capture_timestamp_8.execute_stateful_alu( hct_metadata.stage_timestamp_index );
} // end write_timestamp_8

table capture_timestamp_8 {
    actions {
        write_timestamp_8;
    }
} // end capture_timestamp_8

register timestamp_9 {
    width  : 32;
    instance_count : TIMESTAMP_COUNT;
} // end timestamp_9

blackbox stateful_alu capture_timestamp_9 {
    reg : timestamp_9;
    condition_lo: hct_metadata.timestamp_index < ( 9 * TIMESTAMP_COUNT );
    condition_hi: hct_metadata.timestamp_index >= ( 8 * TIMESTAMP_COUNT );
    update_lo_1_predicate: condition_lo and condition_hi;
    update_lo_1_value: hct_metadata.timestamp_temp;
    output_value: predicate;
    output_dst: hct_metadata.capture_timestamp_9;
} // end capture_timestamp_9

action write_timestamp_9() {
    capture_timestamp_9.execute_stateful_alu( hct_metadata.stage_timestamp_index );
} // end write_timestamp_9

table capture_timestamp_9 {
    actions {
        write_timestamp_9;
    }
} // end capture_timestamp_9

register timestamp_10 {
    width  : 32;
    instance_count : TIMESTAMP_COUNT;
} // end timestamp_10

blackbox stateful_alu capture_timestamp_10 {
    reg : timestamp_10;
    condition_lo: hct_metadata.timestamp_index < ( 10 * TIMESTAMP_COUNT );
    condition_hi: hct_metadata.timestamp_index >= ( 9 * TIMESTAMP_COUNT );
    update_lo_1_predicate: condition_lo and condition_hi;
    update_lo_1_value: hct_metadata.timestamp_temp;
    output_value: predicate;
    output_dst: hct_metadata.capture_timestamp_10;
} // end capture_timestamp_10

action write_timestamp_10() {
    capture_timestamp_10.execute_stateful_alu( hct_metadata.stage_timestamp_index );
} // end write_timestamp_10

table capture_timestamp_10 {
    actions {
        write_timestamp_10;
    }
} // end capture_timestamp_10

register timestamp_11 {
    width  : 32;
    instance_count : TIMESTAMP_COUNT;
} // end timestamp_11

blackbox stateful_alu capture_timestamp_11 {
    reg : timestamp_11;
    condition_lo: hct_metadata.timestamp_index < ( 11 * TIMESTAMP_COUNT );
    condition_hi: hct_metadata.timestamp_index >= ( 10 * TIMESTAMP_COUNT );
    update_lo_1_predicate: condition_lo and condition_hi;
    update_lo_1_value: hct_metadata.timestamp_temp;
    output_value: predicate;
    output_dst: hct_metadata.capture_timestamp_11;
} // end capture_timestamp_11

action write_timestamp_11() {
    capture_timestamp_11.execute_stateful_alu( hct_metadata.stage_timestamp_index );
} // end write_timestamp_11

table capture_timestamp_11 {
    actions {
        write_timestamp_11;
    }
} // end capture_timestamp_11
// =========================== Capture Timestamp END ===========================


table drop_table {
    actions {
       _drop;
    }
} // stream_learn_notification

// =========================== Control START ===========================
control ingress {
    apply( route );
    apply( capture_timestamp_trigger_sync );
    if ( ( hct_metadata.enable_capture_timestamp == 1 ) ) {
        apply( capture_timestamp_trigger );
    } else {
    } // end if & else
} // end ingress

control egress {
    //if ( ( hct_metadata.enable_capture_timestamp == 1 ) and ( hct_metadata.within_range == 0x8 ) ) {
    if ( ( hct_metadata.capture_timestamp_trigger == 1 ) ) {
        apply( timestamp_index );
        apply( stage_timestamp_index );
        apply( capture_timestamp_1 );
        apply( capture_timestamp_2 );
        apply( capture_timestamp_3 );
        apply( capture_timestamp_4 );
        apply( capture_timestamp_5 );
        apply( capture_timestamp_6 );
        apply( capture_timestamp_7 );
        apply( capture_timestamp_8 );
        apply( capture_timestamp_9 );
        apply( capture_timestamp_10 );
        apply( capture_timestamp_11 );
    } else {
    } // end if & else
} // end egress
// =========================== Control END ===========================
