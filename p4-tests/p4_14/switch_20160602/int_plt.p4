/*
 * INT processing
 *
 */

#ifdef __TARGET_TOFINO__
#include "tofino/stateful_alu_blackbox.p4"
#endif

// bloom filter settings
// ingress bloom filter for new flow & upstream change detection: 4 hashways
// egress bloom filter for sink local change detection: 3 hashways

// The followings are defined in p4_table_sizes.h
// PLT_HASH_WIDTH = 16
// PLT_BLOOM_FILTER_SIZE = 65536   // 2^16

// 2^16 (64K) cells per hashway
// 64K * 4 hashways = total 262K cells
// new flow detection failure rate for 10K connections: 0.04%
// new flow detection failure rate for 20K connections: 0.48%

// value change detection failure rate: 0.01%
// mainly caused by digest collision between prev value and new value.
#define PLT_DIGEST_WIDTH    16       // size of each cell
#define PLT_DIGEST_RANGE    65536     // 2^16

#ifdef __TARGET_TOFINO__
#define OUTPUT_WIDTH    1   // staful alu outputs binary comparison result
#else
#define OUTPUT_WIDTH    PLT_DIGEST_WIDTH // output XORed value for comparison
#endif

#ifdef INT_ENABLE
header_type int_metadata_i2e_t {
    fields {
        // 4b
        source          : 1;
        plt_source      : 1;
        sink            : 1;
        report          : 1; // for EP & PLT
    }
}
metadata int_metadata_i2e_t int_metadata_i2e;

header_type int_metadata_t {
    fields {
        // transit add 40B headers
        // 9B md
        switch_id           : 32;
        insert_cnt          : 8;
        remove_byte_cnt     : 16;
        insert_byte_cnt     : 16;
        int_hdr_word_len    : 8; // set by parser

        hit_state    : 2; // won't be needed w/ new compiler doing hit/miss

#ifdef INT_EP_ENABLE
        // carry INT info into e2e cloned copy
        // 7B
        deq_timedelta       : 32;
        enq_qdepth          : 24;
        // additional 2B for EP added in tunnel_metadata
#endif

#ifdef INT_PLT_ENABLE
        // PLT headers: 12B
        // HASH lookup key fields at egress (tcp src/dst ports): 4B
        // md : 9B
        quantized_latency   : 32;
        path_latency_digest : PLT_DIGEST_WIDTH;
        local_latency_digest: PLT_DIGEST_WIDTH;
        same_in_any_filter  : 1;
        bf_tmp_1            : OUTPUT_WIDTH;
        bf_tmp_2            : OUTPUT_WIDTH;
        bf_tmp_3            : OUTPUT_WIDTH;
        bf_tmp_4            : OUTPUT_WIDTH;

#ifndef __TARGET_TOFINO__
        old_digest          : PLT_DIGEST_WIDTH; // used in both ingress, egress but not bridge

        hash_val_1          : PLT_HASH_WIDTH;
        hash_val_2          : PLT_HASH_WIDTH;
        hash_val_3          : PLT_HASH_WIDTH;
        hash_val_4          : PLT_HASH_WIDTH;
        local_latency_hash_val_1 : PLT_HASH_WIDTH;
        local_latency_hash_val_2 : PLT_HASH_WIDTH;
        local_latency_hash_val_3 : PLT_HASH_WIDTH;
        local_latency_bf_tmp_1  : OUTPUT_WIDTH;
        local_latency_bf_tmp_2  : OUTPUT_WIDTH;
        local_latency_bf_tmp_3  : OUTPUT_WIDTH;
#endif
#endif // PLT
    }
}

#ifdef INT_PLT_ENABLE
metadata int_metadata_t int_metadata {
    same_in_any_filter  : 1;
};
#else
metadata int_metadata_t int_metadata;
#endif

#ifdef INT_PLT_ENABLE
// these pragmas don't help to avoid 40b immediate action limitation
//@pragma pa_solitary ingress int_metadata.path_latency_digest
//@pragma pa_atomic ingress int_metadata.path_latency_digest
#endif


/*****************************************************************/
/* Tables and actions for INT metadata update, used at egress */
/*****************************************************************/

/*
 * INT instruction decode
 * 4 tables, each look at 4 bits of insturction
 * BOS table to set the bottom-of-stack bit on the last INT data
 */

/* Instr Bit 0 */
field_list switch_and_port_ids {
    int_metadata.switch_id;
    // physical port ids
    ig_intr_md.ingress_port;
    eg_intr_md.egress_port;
}
field_list_calculation switch_n_ports {
    input { switch_and_port_ids; }
    algorithm : identity_lsb;
    output_width : 31;
}
action int_set_header_0() { //switch_id
    add_header(int_switch_id_header);
    modify_field(int_switch_id_header.switch_id, int_metadata.switch_id);
}

/* Instr Bit 1 */
action int_set_header_1() { // ingress and egress port ids
    add_header(int_port_ids_header);
    modify_field(int_port_ids_header.ingress_port_id, ingress_metadata.ingress_port);
    modify_field(int_port_ids_header.egress_port_id, eg_intr_md.egress_port);
}

/* Instr Bit 2 */
action int_set_header_2() { //hop_latency
    add_header(int_hop_latency_header);
#ifdef INT_EP_ENABLE
    // source or last-hop sink, e2e mirrored
    modify_field(int_hop_latency_header.hop_latency,
                    int_metadata.deq_timedelta);  // timedelta in nanoseconds
#else // if TRANSIT
    modify_field(int_hop_latency_header.hop_latency,
                    eg_intr_md.deq_timedelta);  // timedelta in nanoseconds
#endif
}
/* Instr Bit 3 */
action int_set_header_3() { //q_occupancy
    add_header(int_q_occupancy_header);
    modify_field(int_q_occupancy_header.q_occupancy1, 0);
#ifdef INT_EP_ENABLE
    // source or last-hop sink, e2e mirrored
    modify_field(int_q_occupancy_header.q_occupancy0,
                    int_metadata.enq_qdepth);
#else
    modify_field(int_q_occupancy_header.q_occupancy0,
                    eg_intr_md.enq_qdepth);
#endif

}

/* action function for bits 0-3 combinations, 0 is msb, 3 is lsb */
/* Each bit set indicates that corresponding INT header should be added */
action int_set_header_0003_i0() {
}
action int_set_header_0003_i1() {
    int_set_header_3();
}
action int_set_header_0003_i2() {
    int_set_header_2();
}
action int_set_header_0003_i3() {
    int_set_header_3();
    int_set_header_2();
}
action int_set_header_0003_i4() {
    int_set_header_1();
}
action int_set_header_0003_i5() {
    int_set_header_3();
    int_set_header_1();
}
action int_set_header_0003_i6() {
    int_set_header_2();
    int_set_header_1();
}
action int_set_header_0003_i7() {
    int_set_header_3();
    int_set_header_2();
    int_set_header_1();
}
action int_set_header_0003_i8() {
    int_set_header_0();
}
action int_set_header_0003_i9() {
    int_set_header_3();
    int_set_header_0();
}
action int_set_header_0003_i10() {
    int_set_header_2();
    int_set_header_0();
}
action int_set_header_0003_i11() {
    int_set_header_3();
    int_set_header_2();
    int_set_header_0();
}
action int_set_header_0003_i12() {
    int_set_header_1();
    int_set_header_0();
}
action int_set_header_0003_i13() {
    int_set_header_3();
    int_set_header_1();
    int_set_header_0();
}
action int_set_header_0003_i14() {
    int_set_header_2();
    int_set_header_1();
    int_set_header_0();
}
action int_set_header_0003_i15() {
    int_set_header_3();
    int_set_header_2();
    int_set_header_1();
    int_set_header_0();
}

@pragma ternary 1
table int_inst_0003 {
    reads {
        int_header.instruction_mask_0003 : exact;
    }
    actions {
        int_set_header_0003_i0;
        int_set_header_0003_i1;
        int_set_header_0003_i2;
        int_set_header_0003_i3;
        int_set_header_0003_i4;
        int_set_header_0003_i5;
        int_set_header_0003_i6;
        int_set_header_0003_i7;
        int_set_header_0003_i8;
        int_set_header_0003_i9;
        int_set_header_0003_i10;
        int_set_header_0003_i11;
        int_set_header_0003_i12;
        int_set_header_0003_i13;
        int_set_header_0003_i14;
        int_set_header_0003_i15;
    }
    size : 17;
}


@pragma ternary 1
table int_inst_0407 {
    reads {
        int_header.instruction_mask_0407 : exact;
    }
    actions {
        nop;
    }
    size : 17;
}

table int_inst_0811 {
    reads {
        int_header.instruction_mask_0811 : exact;
    }
    actions {
        nop;
    }
    size : 17;
}

table int_inst_1215 {
    reads {
        int_header.instruction_mask_1215 : exact;
    }
    actions {
        nop;
    }
    size : 17;
}

/* BOS bit - set for the bottom most header added by INT src device */
action int_set_header_0_bos() { //switch_id
    modify_field(int_switch_id_header.bos, 1);
}
action int_set_header_1_bos() { //ingress_port_id
    modify_field(int_port_ids_header.bos, 1);
}
action int_set_header_2_bos() { //hop_latency
    modify_field(int_hop_latency_header.bos, 1);
}
action int_set_header_3_bos() { //q_occupancy
    modify_field(int_q_occupancy_header.bos, 1);
}
table int_bos {
    reads {
        int_header.total_hop_cnt            : ternary;
        int_header.instruction_mask_0003    : ternary;
        int_header.instruction_mask_0407    : ternary;
        int_header.instruction_mask_0811    : ternary;
        int_header.instruction_mask_1215    : ternary;
    }
    actions {
        int_set_header_0_bos;
        int_set_header_1_bos;
        int_set_header_2_bos;
        int_set_header_3_bos;
        nop;
    }
    size : 17;    // number of instruction bits
}

// update the INT metadata header
action int_set_e_bit() {
    modify_field(int_header.e, 1);
}

action int_update_total_hop_cnt() {
    add_to_field(int_header.total_hop_cnt, 1);
}

table int_meta_header_update {
    // This table is applied only if int_insert table is a hit, which
    // computes insert_cnt
    // E bit is set if insert_cnt == 0
    // Else total_hop_cnt is incremented by one
    reads {
        int_metadata.insert_cnt : exact;
    }
    actions {
        int_set_e_bit;
        int_update_total_hop_cnt;
    }
    size : 2;
}
#endif // INT_ENABLE


/**********************************************************/
// Bloom Filters for detecting path or latency changes
// 4 hashways
// Use only 5 tuple for hash indexing
// Store 16-bit path+latency digests in each cell
/*********************************************************/

#if defined(INT_EP_ENABLE) && defined(INT_PLT_ENABLE)
field_list hash_7fields_path_latency {
    lkp_ipv4_hash1_fields;
    int_plt_header.pl_encoding;
}

/* 4 Hash computation for path change detection. */
// avoid csum algorithms when possible
field_list_calculation pl_hash_1 {
    input { lkp_ipv4_hash1_fields; }
#ifdef __TARGET_TOFINO__
    algorithm : crc16_extend;
#else
    algorithm : csum16;
#endif
    output_width : PLT_HASH_WIDTH; }

field_list_calculation pl_hash_2 {
    input { lkp_ipv4_hash1_fields; }
#ifdef __TARGET_TOFINO__
    algorithm : crc32_msb;
#else
    algorithm : crc32;
#endif
    output_width : PLT_HASH_WIDTH; }
 
field_list_calculation pl_hash_3 {
    input { lkp_ipv4_hash1_fields; }
#ifdef __TARGET_TOFINO__
    algorithm : crc32_lsb;
#else
    algorithm : crc16;
#endif
    output_width : PLT_HASH_WIDTH; }
 
field_list_calculation pl_hash_4 {
    input { lkp_ipv4_hash1_fields; }
#ifdef __TARGET_TOFINO__
    algorithm : random;
#else
    algorithm : crcCCITT;
#endif
    output_width : PLT_HASH_WIDTH; }

/* A bit vector representing the filter.
 * Replicated per hash function. */
register pl_bloom_filter_1{
    width : PLT_DIGEST_WIDTH;
    static : pl_bloom_filter_1;
    instance_count : PLT_BLOOM_FILTER_SIZE;
}
register pl_bloom_filter_2{
    width : PLT_DIGEST_WIDTH;
    static : pl_bloom_filter_2;
    instance_count : PLT_BLOOM_FILTER_SIZE;
}
register pl_bloom_filter_3{
    width : PLT_DIGEST_WIDTH;
    static : pl_bloom_filter_3;
    instance_count : PLT_BLOOM_FILTER_SIZE;
}
register pl_bloom_filter_4{
    width : PLT_DIGEST_WIDTH;
    static : pl_bloom_filter_4;
    instance_count : PLT_BLOOM_FILTER_SIZE;
}

/* hash functions to generate 16-bit digests */
field_list_calculation pl_digest {
    input { hash_7fields_path_latency; }
    algorithm : crc16;
    output_width : PLT_DIGEST_WIDTH;
}

// make path+latency digests to store in the filter
action make_pl_digest() {
    modify_field_with_hash_based_offset(int_metadata.path_latency_digest, 0,
                                        pl_digest, PLT_DIGEST_RANGE);
}

#ifdef __TARGET_TOFINO__
/* stateful ALU blackboxes running the bloom filter.
 * Note there is no reduction-OR support yet so each ALU outputs to a separate
 * metadata temp variable.
 * Output is 1 if new value != cell value. */
blackbox stateful_alu pl_bloom_filter_alu_1{
    reg: pl_bloom_filter_1;
    condition_lo: register_lo != int_metadata.path_latency_digest;
    update_lo_1_value: int_metadata.path_latency_digest;
    output_predicate: condition_lo;
    output_value: combined_predicate;
    output_dst: int_metadata.bf_tmp_1;
}
blackbox stateful_alu pl_bloom_filter_alu_2{
    reg: pl_bloom_filter_2;
    condition_lo: register_lo != int_metadata.path_latency_digest;
    update_lo_1_value: int_metadata.path_latency_digest;
    output_predicate: condition_lo;
    output_value: combined_predicate;
    output_dst: int_metadata.bf_tmp_2;
}
blackbox stateful_alu pl_bloom_filter_alu_3{
    reg: pl_bloom_filter_3;
    condition_lo: register_lo != int_metadata.path_latency_digest;
    update_lo_1_value: int_metadata.path_latency_digest;
    output_predicate: condition_lo;
    output_value: combined_predicate;
    output_dst: int_metadata.bf_tmp_3;
}
blackbox stateful_alu pl_bloom_filter_alu_4{
    reg: pl_bloom_filter_4;
    condition_lo: register_lo != int_metadata.path_latency_digest;
    update_lo_1_value: int_metadata.path_latency_digest;
    output_predicate: condition_lo;
    output_value: combined_predicate;
    output_dst: int_metadata.bf_tmp_4;
}
#else   // if BM
/* we need to pre-compute the hashes and save them in metadata for BM */
action set_bloom_filter_hash_1() {
    modify_field_with_hash_based_offset(int_metadata.hash_val_1, 0,
                                            pl_hash_1, PLT_BLOOM_FILTER_SIZE);
}
action set_bloom_filter_hash_2() {
    modify_field_with_hash_based_offset(int_metadata.hash_val_2, 0,
                                            pl_hash_2, PLT_BLOOM_FILTER_SIZE);
}
action set_bloom_filter_hash_3() {
    modify_field_with_hash_based_offset(int_metadata.hash_val_3, 0,
                                            pl_hash_3, PLT_BLOOM_FILTER_SIZE);
}
action set_bloom_filter_hash_4() {
    modify_field_with_hash_based_offset(int_metadata.hash_val_4, 0,
                                            pl_hash_4, PLT_BLOOM_FILTER_SIZE);
}
#endif

/*  actions to execute the filters */
action check_pl_bloom_filter_1() {
#ifdef __TARGET_TOFINO__
    pl_bloom_filter_alu_1.execute_stateful_alu_from_hash(pl_hash_1);
#else
    register_read(int_metadata.old_digest, pl_bloom_filter_1,
                  int_metadata.hash_val_1);
    register_write(pl_bloom_filter_1, int_metadata.hash_val_1,
                    int_metadata.path_latency_digest);
    // if old != new, non-zero value into tmp
    bit_xor(int_metadata.bf_tmp_1, int_metadata.old_digest,
            int_metadata.path_latency_digest);
#endif
}
action check_pl_bloom_filter_2() {
#ifdef __TARGET_TOFINO__
    pl_bloom_filter_alu_2.execute_stateful_alu_from_hash(pl_hash_2);
#else
    register_read(int_metadata.old_digest, pl_bloom_filter_2,
                  int_metadata.hash_val_2);
    register_write(pl_bloom_filter_2, int_metadata.hash_val_2,
                    int_metadata.path_latency_digest);
    bit_xor(int_metadata.bf_tmp_2, int_metadata.old_digest,
            int_metadata.path_latency_digest);
#endif
}
action check_pl_bloom_filter_3() {
#ifdef __TARGET_TOFINO__
    pl_bloom_filter_alu_3.execute_stateful_alu_from_hash(pl_hash_3);
#else
    register_read(int_metadata.old_digest, pl_bloom_filter_3,
                  int_metadata.hash_val_3);
    register_write(pl_bloom_filter_3, int_metadata.hash_val_3,
                    int_metadata.path_latency_digest);
    bit_xor(int_metadata.bf_tmp_3, int_metadata.old_digest,
            int_metadata.path_latency_digest);
#endif
}
action check_pl_bloom_filter_4() {
#ifdef __TARGET_TOFINO__
    pl_bloom_filter_alu_4.execute_stateful_alu_from_hash(pl_hash_4);
#else
    register_read(int_metadata.old_digest, pl_bloom_filter_4,
                  int_metadata.hash_val_4);
    register_write(pl_bloom_filter_4, int_metadata.hash_val_4,
                    int_metadata.path_latency_digest);
    bit_xor(int_metadata.bf_tmp_4, int_metadata.old_digest,
            int_metadata.path_latency_digest);
#endif
}

#ifndef __TARGET_TOFINO__
/* only for BM: extra tables to precompute the bloom filter hash indices. */
table bloom_filter_setup_1 {
    actions { set_bloom_filter_hash_1; }
    size: 1;
}
table bloom_filter_setup_2 {
    actions { set_bloom_filter_hash_2; }
    size: 1;
}
table bloom_filter_setup_3 {
    actions { set_bloom_filter_hash_3; }
    size: 1;
}
table bloom_filter_setup_4 {
    actions { set_bloom_filter_hash_4; }
    size: 1;
}
#endif

/* separate tables to run the bloom filters. */
table pl_bloom_filter_1 {
    actions { check_pl_bloom_filter_1; }
    size: 1;
}
table pl_bloom_filter_2 {
    actions { check_pl_bloom_filter_2; }
    size: 1;
}
table pl_bloom_filter_3 {
    actions { check_pl_bloom_filter_3; }
    size: 1;
}
table pl_bloom_filter_4 {
    actions { check_pl_bloom_filter_4; }
    size: 1;
}

action unset_upstream_report() {
    modify_field(int_metadata_i2e.report, 0);
}

// additional table for combining bloom filter results
table suppress_upstream_report {
    actions {
       unset_upstream_report;
    }
    size : 1;
}

#endif // EP & PLT


/**********************************************************/
// Bloom Filters for detecting sink LOCAL latency changes.
// The logic is the same with ingress bloom filter except for
// that local latency is used rather than upstream path, latency encondings.
// And use only 3 filters since it doesn't detect new flow events.
/*********************************************************/

#if defined(INT_EP_ENABLE) && defined(INT_PLT_ENABLE)
field_list hash_5fields_egress {
    // use inner 5tuple. Filter tables must be placed before tunnel decap.
    // Then it doesn't matter if the switch is VTEP or not.
    // lkp fields are set by parser. There is a phv alloc bug in using those fields in egress (bridge-md).
    // thus use inner headers
    inner_ipv4.srcAddr;
    inner_ipv4.dstAddr;
    inner_ipv4.protocol;
    inner_tcp.srcPort;
    inner_tcp.dstPort;
    // should include inner_udp?
}
field_list hash_6fields_local_latency {
    inner_ipv4.srcAddr;
    inner_ipv4.dstAddr;
    inner_ipv4.protocol;
    inner_tcp.srcPort;
    inner_tcp.dstPort;
    int_metadata.quantized_latency;
}

/* 3 Hash computation for local latency change detection. */
field_list_calculation local_latency_hash_1 {
    input { hash_5fields_egress; }
#ifdef __TARGET_TOFINO__
    algorithm : crc16_extend;
#else
    algorithm : csum16;
#endif
    output_width : PLT_HASH_WIDTH; }

field_list_calculation local_latency_hash_2 {
    input { hash_5fields_egress; }
#ifdef __TARGET_TOFINO__
    algorithm : crc32_msb;
#else
    algorithm : crc32;
#endif
    output_width : PLT_HASH_WIDTH; }

field_list_calculation local_latency_hash_3 {
    input { hash_5fields_egress; }
#ifdef __TARGET_TOFINO__
    algorithm : random;
#else
    algorithm : crc16;
#endif
    output_width : PLT_HASH_WIDTH; }

/* A bit vector representing the filter.
 * Replicated per hash function. */
register local_latency_bloom_filter_1{
    width : PLT_DIGEST_WIDTH;
#ifdef __TARGET_TOFINO__
    static : local_latency_bloom_filter_1;
#endif
    instance_count : PLT_BLOOM_FILTER_SIZE;
}
register local_latency_bloom_filter_2{
    width : PLT_DIGEST_WIDTH;
#ifdef __TARGET_TOFINO__
    static : local_latency_bloom_filter_2;
#endif
    instance_count : PLT_BLOOM_FILTER_SIZE;
}
register local_latency_bloom_filter_3{
    width : PLT_DIGEST_WIDTH;
#ifdef __TARGET_TOFINO__
    static : local_latency_bloom_filter_3;
#endif
    instance_count : PLT_BLOOM_FILTER_SIZE;
}

field_list_calculation local_latency_1st_digest {
    input { hash_6fields_local_latency; }
#ifdef __TARGET_TOFINO__
    algorithm : crc16_msb;
#else
    algorithm : crc16;
#endif
    output_width : PLT_DIGEST_WIDTH;
}
field_list_calculation local_latency_2nd_digest {
    input { hash_6fields_local_latency; }
#ifdef __TARGET_TOFINO__
    algorithm : crc16_lsb;
#else
    algorithm : csum16;
#endif
    output_width : PLT_DIGEST_WIDTH;
}

action make_local_latency_digest() {
    modify_field_with_hash_based_offset(int_metadata.local_latency_digest, 0,
                                        local_latency_1st_digest, PLT_DIGEST_RANGE);
}

#ifdef __TARGET_TOFINO__
blackbox stateful_alu local_latency_bloom_filter_alu_1{
    reg: local_latency_bloom_filter_1;
    condition_lo: register_lo == int_metadata.local_latency_digest;
    update_lo_1_value: int_metadata.local_latency_digest;
    output_predicate: condition_lo;
    output_value: combined_predicate;
    output_dst: int_metadata.same_in_any_filter;
    reduction_or_group: or_group_1;
}
blackbox stateful_alu local_latency_bloom_filter_alu_2{
    reg: local_latency_bloom_filter_2;
    condition_lo: register_lo == int_metadata.local_latency_digest;
    update_lo_1_value: int_metadata.local_latency_digest;
    output_predicate: condition_lo;
    output_value: combined_predicate;
    output_dst: int_metadata.same_in_any_filter;
    reduction_or_group: or_group_1;
}
blackbox stateful_alu local_latency_bloom_filter_alu_3{
    reg: local_latency_bloom_filter_3;
    condition_lo: register_lo == int_metadata.local_latency_digest;
    update_lo_1_value: int_metadata.local_latency_digest;
    output_predicate: condition_lo;
    output_value: combined_predicate;
    output_dst: int_metadata.same_in_any_filter;
    reduction_or_group: or_group_1;
}
#else   // if BM
action set_local_bloom_filter_hash_1() {
    modify_field_with_hash_based_offset(int_metadata.local_latency_hash_val_1, 0,
                                        local_latency_hash_1, PLT_BLOOM_FILTER_SIZE);
}
action set_local_bloom_filter_hash_2() {
    modify_field_with_hash_based_offset(int_metadata.local_latency_hash_val_2, 0,
                                        local_latency_hash_2, PLT_BLOOM_FILTER_SIZE);
}
action set_local_bloom_filter_hash_3() {
    modify_field_with_hash_based_offset(int_metadata.local_latency_hash_val_3, 0,
                                        local_latency_hash_3, PLT_BLOOM_FILTER_SIZE);
}
#endif

action check_local_latency_bloom_filter_1() {
#ifdef __TARGET_TOFINO__
    local_latency_bloom_filter_alu_1.execute_stateful_alu_from_hash(local_latency_hash_1);
#else
    register_read(int_metadata.old_digest, local_latency_bloom_filter_1,
                  int_metadata.local_latency_hash_val_1);
    register_write(local_latency_bloom_filter_1, int_metadata.local_latency_hash_val_1,
                    int_metadata.local_latency_digest);
    // if old != new, non-zero value into tmp
    bit_xor(int_metadata.local_latency_bf_tmp_1, int_metadata.old_digest,
            int_metadata.local_latency_digest);
#endif
}

action check_local_latency_bloom_filter_2() {
#ifdef __TARGET_TOFINO__
    local_latency_bloom_filter_alu_2.execute_stateful_alu_from_hash(local_latency_hash_2);
#else
    register_read(int_metadata.old_digest, local_latency_bloom_filter_2,
                  int_metadata.local_latency_hash_val_2);
    register_write(local_latency_bloom_filter_2, int_metadata.local_latency_hash_val_2,
                    int_metadata.local_latency_digest);
    bit_xor(int_metadata.local_latency_bf_tmp_2, int_metadata.old_digest,
            int_metadata.local_latency_digest);
#endif
}

action check_local_latency_bloom_filter_3() {
#ifdef __TARGET_TOFINO__
    local_latency_bloom_filter_alu_3.execute_stateful_alu_from_hash(local_latency_hash_3);
#else
    register_read(int_metadata.old_digest, local_latency_bloom_filter_3,
                  int_metadata.local_latency_hash_val_3);
    register_write(local_latency_bloom_filter_3, int_metadata.local_latency_hash_val_3,
                    int_metadata.local_latency_digest);
    bit_xor(int_metadata.local_latency_bf_tmp_3, int_metadata.old_digest,
            int_metadata.local_latency_digest);
#endif
}

#ifndef __TARGET_TOFINO__
/* table to precompute the bloom filter hashes. */
table local_bloom_filter_setup_1 {
    actions { set_local_bloom_filter_hash_1; }
    size: 1;
}
table local_bloom_filter_setup_2 {
    actions { set_local_bloom_filter_hash_2; }
    size: 1;
}
table local_bloom_filter_setup_3 {
    actions { set_local_bloom_filter_hash_3; }
    size: 1;
}
#endif

/* Three separate tables to run the path bloom filter. */
table local_latency_bloom_filter_1 {
    actions { check_local_latency_bloom_filter_1; }
    size: 1;
}
table local_latency_bloom_filter_2 {
    actions { check_local_latency_bloom_filter_2; }
    size: 1;
}
table local_latency_bloom_filter_3 {
    actions { check_local_latency_bloom_filter_3; }
    size: 1;
}

action mark_local_latency_change() {
    modify_field(int_metadata_i2e.report, 1);
}

table mark_local_bloom_filter {
    actions {
       mark_local_latency_change;
    }
    size : 1;
}

#endif // EP & PLT

/************************************************************/
// INT tables for ingress pipeline
// 1. Identify role (src, transit, or sink)
// 2. If sink,
//      1) remove INT/PLT related headers
//      2) set report flag = 1
//      3) if PLT header is valid and detects no change, reset the flag
//      4) if flag == 1, send upstream report by clone i2e
/************************************************************/
#ifdef INT_EP_ENABLE
action int_set_src (plt_activate) {
    modify_field(int_metadata_i2e.source, 1);
    modify_field(int_metadata_i2e.plt_source, plt_activate);
}

action int_set_no_src () {
    modify_field(int_metadata_i2e.source, 0);
    modify_field(int_metadata_i2e.plt_source, 0);
}

table int_source {
    // Decide to initiate INT based on client IP address pair
    // lkp_src, lkp_dst addresses are either outer or inner based
    // on if this switch is VTEP src or not respectively.
    //
    // {int_header, lkp_src, lkp_dst}
    //      0, src, dst => int_src=1
    //      1, x, x => mis-config, transient error, int_src=0
    //      miss => int_src=0
    reads {
        int_header                  : valid;
        // use client ipv4/6 header when VTEP src
        ipv4                        : valid;
        ipv4_metadata.lkp_ipv4_da   : ternary;
        ipv4_metadata.lkp_ipv4_sa   : ternary;

        // use inner_ipv4 header when not VTEP src
        // Packet is already vxlan-gpe encapped upstream
        inner_ipv4                  : valid;
        inner_ipv4.dstAddr          : ternary;
        inner_ipv4.srcAddr          : ternary;
    }
    actions {
        int_set_src;
        int_set_no_src;
    }
    size : INT_SOURCE_TABLE_SIZE;
}

action int_sink () {
    modify_field(int_metadata_i2e.sink, 1);
#ifdef INT_PLT_ENABLE
    // Send INT to monitor.
    // This bit can be unset later by PLT
    modify_field(int_metadata_i2e.report, 1);
#endif
    // remove all the INT information from the packet
    // max 24 headers are supported
    remove_header(int_header);
#ifndef __TARGET_TOFINO__
    remove_header(int_val[0]);
    remove_header(int_val[1]);
    remove_header(int_val[2]);
    remove_header(int_val[3]);
    remove_header(int_val[4]);
    remove_header(int_val[5]);
    remove_header(int_val[6]);
    remove_header(int_val[7]);
    remove_header(int_val[8]);
    remove_header(int_val[9]);
    remove_header(int_val[10]);
    remove_header(int_val[11]);
    remove_header(int_val[12]);
    remove_header(int_val[13]);
    remove_header(int_val[14]);
    remove_header(int_val[15]);
    remove_header(int_val[16]);
    remove_header(int_val[17]);
    remove_header(int_val[18]);
    remove_header(int_val[19]);
    remove_header(int_val[20]);
    remove_header(int_val[21]);
    remove_header(int_val[22]);
    remove_header(int_val[23]);
#endif
}

action int_sink_gpe () {
    // convert the word len to byte_cnt
    shift_left(int_metadata.remove_byte_cnt, vxlan_gpe_int_header.len, 2);
    int_sink();
}

table int_terminate {
    actions {
        int_sink_gpe;
    }
    size : 1;
}

action int_no_sink() {
    modify_field(int_metadata_i2e.sink, 0);
}

table int_set_no_sink {
    actions {
        int_no_sink;
    }
    size : 1;
}

#ifdef INT_PLT_ENABLE
table plt_make_hash_digest {
    actions {make_pl_digest;}
    size: 1;
}

action plt_sink_gpe () {
    add_to_field(int_metadata.remove_byte_cnt, 8); // plt len : 12B
    remove_header(int_plt_header);
    remove_header(vxlan_gpe_int_plt_header);
}

table plt_terminate {
    actions {plt_sink_gpe;}
    size : 1;
}

control process_plt_upstream_change {
    // Use bloom filter to detect any change in path or latency
    // If there is need to report,
    //  int_metadata_i2e.report will contain non-zero value
    // Otherwise, report flag = 0
#ifndef __TARGET_TOFINO__
    apply(bloom_filter_setup_1);
    apply(bloom_filter_setup_2);
    apply(bloom_filter_setup_3);
    apply(bloom_filter_setup_4);
#endif
    apply(pl_bloom_filter_1);
    apply(pl_bloom_filter_2);
    apply(pl_bloom_filter_3);
    apply(pl_bloom_filter_4);

    // report flag was already set to 1.
    // reset to zero if PLT detects no change.
    // if change: t1 != 0 and t2 != 0 and t3 != 0
    // if no change: t1 == 0 or t2 == 0 or t3 == 0
    if (int_metadata.bf_tmp_1 == 0 or int_metadata.bf_tmp_2 == 0
            or int_metadata.bf_tmp_3 == 0 or int_metadata.bf_tmp_4 == 0) {
        apply(suppress_upstream_report);
    }
}

#ifdef INT_DEBUG
table plt_debug {
    reads {
#ifndef __TARGET_TOFINO__
        int_metadata.old_digest:    exact;
        int_metadata.local_latency_bf_tmp_1        : exact;
        int_metadata.local_latency_bf_tmp_2        : exact;
        int_metadata.local_latency_bf_tmp_3        : exact;
#endif
        int_plt_header.pl_encoding: exact;
        int_metadata.path_latency_digest:    exact;
        int_metadata.bf_tmp_1           : exact;
        int_metadata.bf_tmp_2           : exact;
        int_metadata.bf_tmp_3           : exact;
        int_metadata_i2e.report: exact;
    }
    actions {
        nop;
    }
}
#endif
#endif  // INT_PLT_ENABLE

action int_sink_update_vxlan_gpe_v4() {
    modify_field(vxlan_gpe.next_proto, vxlan_gpe_int_header.next_proto);
    remove_header(vxlan_gpe_int_header);
    subtract(ipv4.totalLen, ipv4.totalLen, int_metadata.remove_byte_cnt);
    subtract(udp.length_, udp.length_, int_metadata.remove_byte_cnt);
}

@pragma ternary 1
table int_sink_update_outer {
    // This table is used to update the outer(underlay) headers on int_sink
    // to reflect removal of INT headers
    // Add more entries as other underlay protocols are added
    // {sink, gpe}
    // 1, 1 => update ipv4 and udp headers
    // miss => nop
    reads {
        vxlan_gpe_int_header        : valid;
        ipv4                        : valid;
        int_metadata_i2e.sink       : exact;
    }
    actions {
        int_sink_update_vxlan_gpe_v4;
        nop;
    }
    size : 2; //1+1;
}

field_list int_i2e_mirror_info {
    // up to 9B
    int_metadata_i2e.sink;          // 1B
    i2e_metadata.mirror_session_id; // 2B
    i2e_metadata.ingress_tstamp;    // 4B
    tunnel_metadata.erspan_t3_ft_d_other; // 2B
}

action int_send_to_monitor_i2e (mirror_id) {
    // send the upstream INT information to the
    // pre-processor/monitor. This is done via mirroring
    modify_field(i2e_metadata.mirror_session_id, mirror_id);
    modify_field(i2e_metadata.ingress_tstamp, _ingress_global_tstamp_);
    // frame type 16 for INT
    // direction bit 0 for ingress mirroring
    modify_field(tunnel_metadata.erspan_t3_ft_d_other, 0x4000);
    clone_ingress_pkt_to_egress(mirror_id, int_i2e_mirror_info);
}

table int_upstream_report {
    actions {
        int_send_to_monitor_i2e;
    }
    size : 1;
}
#endif // INT_EP_ENABLE

control process_int_endpoint{
#ifdef INT_EP_ENABLE
    // EP_ENABLE is mutually exclusive to int transit.
    // This switch is either int source or sink.
    if (not valid(int_header)) {
        /*
         * Check if this switch needs to act as INT source
         */
        apply(int_source);
    } else {
        // int_header is valid
        /*
         * It would be nice to keep this encap un-aware. But this is used
         * to compute byte count of INT info from shim headers from outer
         * protocols (vxlan_gpe_shim, geneve_tlv etc)
         * That make us to check if vxlan_gpe_int_header.valid
        */
        if (valid(vxlan_gpe_int_header)) {
            // this switch is int sink
            apply(int_terminate);
#ifdef INT_PLT_ENABLE
            if (valid(int_plt_header)) {
                // pre-compute hash digest
                apply(plt_make_hash_digest);
                process_plt_upstream_change();
                apply(plt_terminate);
#ifdef INT_DEBUG
                apply(plt_debug);
#endif
            }
#endif // PLT
        } else {
            // gpe INT shim header is not valid.
            // it's an error as we support INT only with gpe for now.
            apply(int_set_no_sink);
        }
    }
#endif // EP
}

control process_int_upstream_report {
    // this should be invoked after acl_mirror
    // favor existing acl mirror session over int mirror
#ifdef INT_EP_ENABLE
    if (i2e_metadata.mirror_session_id == 0 and int_metadata_i2e.sink == 1) {
#ifdef INT_PLT_ENABLE
        if (int_metadata_i2e.report == 1) {
#endif
            apply(int_upstream_report);
#ifdef INT_PLT_ENABLE
        }
#endif
    }
#endif
}

control process_int_sink_update_outer {
#ifdef INT_EP_ENABLE
    apply(int_sink_update_outer);
#endif
}


/***************************************************************/
// INT/PLT tables for egress pipeline
// If src/transit
//      insert INT data, update meta header
//      if plt, also insert/update plt encondings
//      update vxlan gpe and ipv4 len
// If sink, original pkt
//      if report flag == 1 or local_latency changes,
//          clone e2e mirror for sink local report
// If sink i2e mirrored (upstream report)
//      decap outer and int shim (keep int meta hdr and value stack)
//      encap erspan_t3 (via mirroring) and update ipv4 len
// If sink e2e mirrored (local report)
//      add int hdrs and stack of local info
//      decap outer and int shim (keep int meta hdr and value stack)
//      encap erspan_t3 (via mirroring) and update ipv4 len
/***************************************************************/

#ifdef INT_ENABLE
action config_int_switch_id(switch_id) {
    modify_field(int_metadata.switch_id, switch_id);
}

table int_config {
    reads {
        ethernet    : valid;
    }
    actions {
        config_int_switch_id;
    }
    size : 1;
}

#ifdef INT_PLT_ENABLE
action copy_latency() {
    modify_field(int_metadata.quantized_latency, eg_intr_md.deq_timedelta);}
action quantize_latency_1() {
    shift_right(int_metadata.quantized_latency, eg_intr_md.deq_timedelta, 1);}
action quantize_latency_2() {
    shift_right(int_metadata.quantized_latency, eg_intr_md.deq_timedelta, 2);}
action quantize_latency_3() {
    shift_right(int_metadata.quantized_latency, eg_intr_md.deq_timedelta, 3);}
action quantize_latency_4() {
    shift_right(int_metadata.quantized_latency, eg_intr_md.deq_timedelta, 4);}
action quantize_latency_5() {
    shift_right(int_metadata.quantized_latency, eg_intr_md.deq_timedelta, 5);}
action quantize_latency_6() {
    shift_right(int_metadata.quantized_latency, eg_intr_md.deq_timedelta, 6);}
action quantize_latency_7() {
    shift_right(int_metadata.quantized_latency, eg_intr_md.deq_timedelta, 7);}
action quantize_latency_8() {
    shift_right(int_metadata.quantized_latency, eg_intr_md.deq_timedelta, 8);}
action quantize_latency_9() {
    shift_right(int_metadata.quantized_latency, eg_intr_md.deq_timedelta, 9);}
action quantize_latency_10() {
    shift_right(int_metadata.quantized_latency, eg_intr_md.deq_timedelta, 10);}
action quantize_latency_11() {
    shift_right(int_metadata.quantized_latency, eg_intr_md.deq_timedelta, 11);}
action quantize_latency_12() {
    shift_right(int_metadata.quantized_latency, eg_intr_md.deq_timedelta, 12);}
action quantize_latency_13() {
    shift_right(int_metadata.quantized_latency, eg_intr_md.deq_timedelta, 13);}
action quantize_latency_14() {
    shift_right(int_metadata.quantized_latency, eg_intr_md.deq_timedelta, 14);}
action quantize_latency_15() {
    shift_right(int_metadata.quantized_latency, eg_intr_md.deq_timedelta, 15);}

table plt_quantize_latency {
    reads { ethernet: valid; }
    actions {
        // control plane will choose the quantization action
        quantize_latency_1;
        quantize_latency_2;
        quantize_latency_3;
        quantize_latency_4;
        quantize_latency_5;
        quantize_latency_6;
        quantize_latency_7;
        quantize_latency_8;
        quantize_latency_9;
        quantize_latency_10;
        quantize_latency_11;
        quantize_latency_12;
        quantize_latency_13;
        quantize_latency_14;
        quantize_latency_15;
        copy_latency;
    }
    size: 2;   // default copy_latency + one selected quantized_latency
}

// reduce the chance of quantized_latency of different hops
// cancel each other by PLT XOR encoding
action scramble_latency() {
    // subtract seems better than add, which can overflow more easily.
    subtract(int_metadata.quantized_latency,
            int_metadata.switch_id,
            int_metadata.quantized_latency);
}

table plt_scramble_latency {
    actions {scramble_latency;}
    size : 1;
}
#endif // PLT
#endif // INT

#ifdef INT_EP_ENABLE
action prep_metadata() {
    // this is applied for int source or sink normal
    modify_field(int_metadata.deq_timedelta, eg_intr_md.deq_timedelta);
    modify_field(int_metadata.enq_qdepth, eg_intr_md.enq_qdepth);
#ifdef INT_PLT_ENABLE
    // also make local latency digest if PLT
    // local digest is needed only for sink normal, but doing for int source is okay
    make_local_latency_digest();
#endif
}

table int_init_metadata {
    actions {prep_metadata;}
    size : 1;
}

#ifdef INT_PLT_ENABLE
control process_plt_sink_local_change {
    // Use bloom filter to detect change in quantized local latency
    // This should be executed before tunnel_decap

#ifndef __TARGET_TOFINO__
    apply(local_bloom_filter_setup_1);
    apply(local_bloom_filter_setup_2);
    apply(local_bloom_filter_setup_3);
#endif
    apply(local_latency_bloom_filter_1);
    apply(local_latency_bloom_filter_2);
    apply(local_latency_bloom_filter_3);

#ifndef __TARGET_TOFINO__
    if (int_metadata.local_latency_bf_tmp_1 != 0
            and int_metadata.local_latency_bf_tmp_2 != 0
            and int_metadata.local_latency_bf_tmp_3 != 0) {
        apply(mark_local_bloom_filter);
    }
#endif
}
#endif // INT_PLT_ENABLE

#endif // INT_EP_ENABLE

control process_int_egress_prep {
#ifdef INT_ENABLE
    apply(int_config);
#ifdef INT_PLT_ENABLE
    apply(plt_quantize_latency);
#endif

#ifdef INT_EP_ENABLE
    // If sink e2e_mirror, sink local TM metadata are
    // copied from the original pkt via mirror_info.
    // Otherwise, (if source or sink normal), copy from intrinsic metadata
    // sink i2e_mirror doesn't use local info, thus do nothing
    if (int_metadata_i2e.source == 1 or
            (int_metadata_i2e.sink == 1 and not pkt_is_mirrored))
    {
        apply(int_init_metadata);
#ifdef INT_PLT_ENABLE
        if (int_metadata_i2e.sink == 1) {
            process_plt_sink_local_change();
#ifdef INT_DEBUG
            apply(plt_egress_debug);
#endif
        }
#endif
    }
#endif // EP

#ifdef INT_PLT_ENABLE
    if (int_metadata_i2e.sink == 0) {
        // for int source and transit PLT
        apply(plt_scramble_latency);
    }
#endif
#endif // INT
}

#ifdef INT_ENABLE

#define MISS        0
#define TRANSIT     1
#define SRC_OR_SINK_E2E    2

#ifdef INT_TRANSIT_ENABLE
action int_transit() {
    modify_field(int_metadata.hit_state, TRANSIT);
    subtract(int_metadata.insert_cnt, int_header.max_hop_cnt,
                                            int_header.total_hop_cnt);
    // int_metadata.int_hdr_word_len was initialized to int_header.ins_cnt by parser
    shift_left(int_metadata.insert_byte_cnt, int_metadata.int_hdr_word_len, 2);
}
#endif

action int_reset() {
    // this is applied if not src, transit or sink e2e clone.
    // i.e., if sink normal, sink i2e, or no int
    // sink i2e stores int size in insert_byte_cnt, must not reset.
    //modify_field(int_metadata.insert_byte_cnt, 0);
    modify_field(int_metadata.insert_cnt, 0);
    modify_field(int_metadata.int_hdr_word_len, 0);
}

#ifdef INT_EP_ENABLE
action int_src(hop_cnt, ins_cnt, ins_mask0003, ins_mask0407, ins_byte_cnt, total_words) {
    modify_field(int_metadata.hit_state, SRC_OR_SINK_E2E);
    modify_field(int_metadata.insert_cnt, hop_cnt);
    modify_field(int_metadata.insert_byte_cnt, ins_byte_cnt);
    modify_field(int_metadata.int_hdr_word_len, total_words);
    add_header(int_header);
    modify_field(int_header.ver, 0);
    modify_field(int_header.rep, 0);
    modify_field(int_header.c, 0);
    modify_field(int_header.e, 0);
    modify_field(int_header.rsvd1, 0);
    modify_field(int_header.ins_cnt, ins_cnt);
    modify_field(int_header.max_hop_cnt, hop_cnt);
    modify_field(int_header.total_hop_cnt, 0);
    modify_field(int_header.instruction_mask_0003, ins_mask0003);
    modify_field(int_header.instruction_mask_0407, ins_mask0407);
    modify_field(int_header.instruction_mask_0811, 0); // not supported
    modify_field(int_header.instruction_mask_1215, 0); // not supported
    modify_field(int_header.rsvd2, 0);
}

action int_sink_e2e(ins_cnt, ins_mask0003, ins_mask0407, ins_byte_cnt, total_words) {
    // reuse int_src
    int_src(1, ins_cnt, ins_mask0003, ins_mask0407, ins_byte_cnt, total_words);
}
#endif

table int_insert {
    /* REMOVE - changed src/sink bits to ternary to use TCAM
     * keep int_header.valid in the key to force reset on error condition
     */

    // int_sink takes precedence over int_src
    // {int_src, int_sink, int_header, pkt_type} :
    //      0, 0, 1, 0 => transit  => insert_cnt = max-total
    //      1, 0, 0, 0 => insert (src) => insert_cnt = max
    //      0, 1, 0, 2 => sink e2e clone => insert by reuse int_src
    //      1, 0, 1 => nop (error) (reset) => insert_cnt = 0
    //      miss (0,0,0) => nop (reset)
    reads {
        int_metadata_i2e.source       : ternary;
        int_metadata_i2e.sink         : ternary;
        int_header                    : valid;
        standard_metadata.instance_type : ternary;
    }
    actions {
#ifdef INT_TRANSIT_ENABLE
        int_transit;
#endif
#ifdef INT_EP_ENABLE
        int_src;
        int_sink_e2e;
#endif
        int_reset;
        nop;
    }
    size : 4;  // TRANSIT and EP are mutually exclusive
}

#ifdef INT_TRANSIT_ENABLE
action clear_upper() {
    // insert_byte_cnt got shift_lefted by 2 from 5bit ins_cnt
    // reset the most significant 9 (16-2-5) bits that could have been contaminated
    bit_and(int_metadata.insert_byte_cnt, int_metadata.insert_byte_cnt, 0x007F );
}

table int_transit_clear_byte_cnt {
    // needed because insert_byte_cnt was copied from 8bit metadata
    actions{ clear_upper; }
    size : 1;
}
#endif
#endif  // end of INT_ENABLE

control process_int_insertion {
#ifdef INT_ENABLE
    apply(int_insert);
    if (int_metadata.hit_state != MISS) {
#ifdef INT_TRANSIT_ENABLE
        if (int_metadata.hit_state == TRANSIT) {
            apply(int_transit_clear_byte_cnt);
        }
#endif
        // int_transit | int_src | sink egress clone
        // insert_cnt = max_hop_cnt - total_hop_cnt
        // (cannot be -ve, not checked)
        if (int_metadata.insert_cnt != 0) {
            apply(int_inst_0003);
            apply(int_inst_0407);
            apply(int_inst_0811);
            apply(int_inst_1215);
            apply(int_bos);
        }
        apply(int_meta_header_update);
    }
#endif
}

#ifdef INT_PLT_ENABLE
action update_int_plt_header() {
    // quantized_latency = switch_id - quantized_latency.
    bit_xor(int_plt_header.pl_encoding, int_plt_header.pl_encoding,
            int_metadata.quantized_latency);
}

action add_int_plt_header() {
    add_header(vxlan_gpe_int_plt_header);
    add_header(int_plt_header);
    modify_field(vxlan_gpe_int_plt_header.int_type, 0x03);
    modify_field(vxlan_gpe_int_plt_header.next_proto, 5); // INT
    modify_field(vxlan_gpe_int_plt_header.len, 2); // word len
    add_to_field(int_metadata.insert_byte_cnt, 8); // byte len

    // Encode local data
    update_int_plt_header();
}

#ifdef INT_EP_ENABLE
table int_plt_insert {
    actions {
        add_int_plt_header;
    }
    size : 1;
}
#endif

#ifdef INT_TRANSIT_ENABLE
table int_plt_encode {
    actions {
        update_int_plt_header;
    }
    size : 1;
}
#endif
#endif  // INT_PLT_ENABLE

control process_plt_insertion {
#ifdef INT_PLT_ENABLE
#ifdef INT_EP_ENABLE
    if ((int_metadata_i2e.plt_source == 1) and (not valid(int_plt_header))) {
        // This is source: insert PLT hdrs and encode local data
        apply(int_plt_insert);
    }
#endif
#ifdef INT_TRANSIT_ENABLE
    // TRANSIT and EP are mutually exclusive.
    if (int_metadata_i2e.source == 0 and int_metadata_i2e.sink == 0
            and valid(int_plt_header)) {
        // PLT encoding transit
        apply(int_plt_encode);
    }
#endif
#endif
}

#ifdef INT_EP_ENABLE
action remove_outer_i2e() {
    copy_header(ethernet, inner_ethernet);

    // 34 = udp 8, gpe 8, int shim 4, inner_ethernet 14
    add(egress_metadata.payload_length, udp.length_, -34);
    remove_header(vxlan_gpe_int_header);
    remove_header(vxlan_gpe);
    remove_header(udp);
    remove_header(ipv4);
    modify_field(tunnel_metadata.inner_ip_proto, IP_PROTOCOLS_IPV4);
    modify_field(tunnel_metadata.skip_encap_inner, 1);
}

#ifdef INT_PLT_ENABLE
action remove_outer_and_plt_i2e() {
    copy_header(ethernet, inner_ethernet);

    // 42 = udp 8, gpe 8, int shim 4, inner_ethernet 14
    //      plt shim 4, plt hdr 4
    add(egress_metadata.payload_length, udp.length_, -42);
    remove_header(vxlan_gpe_int_plt_header);
    remove_header(int_plt_header);
    remove_header(vxlan_gpe_int_header);
    remove_header(vxlan_gpe);
    remove_header(udp);
    remove_header(ipv4);
    modify_field(tunnel_metadata.inner_ip_proto, IP_PROTOCOLS_IPV4);
    modify_field(tunnel_metadata.skip_encap_inner, 1);
}
#endif

action remove_outer_e2e() {
    copy_header(ethernet, inner_ethernet);

    // 30 = udp 8, gpe 8, inner_ethernet 14
    add(egress_metadata.payload_length, udp.length_, -30);
    remove_header(vxlan_gpe);
    remove_header(udp);
    remove_header(ipv4);
    modify_field(tunnel_metadata.inner_ip_proto, IP_PROTOCOLS_IPV4);
    modify_field(tunnel_metadata.skip_encap_inner, 1);
}

table int_decap_vxlan_gpe {
    reads {
        standard_metadata.instance_type : exact;
        int_plt_header                  : valid;
    }
    actions {
        remove_outer_i2e;
        remove_outer_and_plt_i2e;
        remove_outer_e2e;
        nop;
    }
    size : 4;
}

#ifdef INT_PLT_ENABLE
#ifdef INT_DEBUG
table plt_egress_debug {
    reads {
        int_metadata_i2e.sink:        exact;
#ifndef __TARGET_TOFINO__
        int_metadata.old_digest:        exact;
#endif
        eg_intr_md.deq_timedelta:       exact;
        int_metadata.quantized_latency: exact;
        int_metadata.local_latency_digest:    exact;
        int_metadata_i2e.report: exact;
    }
    actions {
        nop;
    }
}
#endif
#endif // INT_PLT_ENABLE

field_list int_e2e_mirror_info {
    // 16B w/ tunnel, 18B w/o tunnel
    i2e_metadata.mirror_session_id; // 2B w/ tunnel, 4B w/o tunnel.
    i2e_metadata.ingress_tstamp;    // 4B
    int_metadata_i2e.sink;          // 1B
    int_metadata.deq_timedelta;     // 4B
    int_metadata.enq_qdepth;        // 3B
    tunnel_metadata.erspan_t3_ft_d_other; // 2B
    //tunnel_metadata.frame_type; // phv allocation error
    //tunnel_metadata.direction;
}

action int_send_to_monitor_e2e (mirror_id) {
    // send the upstream INT information to the
    // pre-processor/monitor. This is done via mirroring
    modify_field(i2e_metadata.mirror_session_id, mirror_id);
    // frame type 16 for INT
    // direction bit 1 for egress mirroring
    modify_field(tunnel_metadata.erspan_t3_ft_d_other, 0x4008);
    clone_egress_pkt_to_egress(mirror_id, int_e2e_mirror_info);
}

table int_sink_local_report {
    actions {
        int_send_to_monitor_e2e;
    }
    size : 1;
}
#endif // EP

control process_int_egress {
#ifdef INT_ENABLE
    if (int_metadata_i2e.sink == 1 and not pkt_is_mirrored) {
#ifdef INT_EP_ENABLE
#ifdef INT_PLT_ENABLE
        if (int_metadata_i2e.report == 1 or int_metadata.same_in_any_filter == 0 ) {
#endif
            // sink normal, do e2e clone
            // mirror_session_id can be overwritten by egress_acl later
            apply(int_sink_local_report);
#ifdef INT_PLT_ENABLE
        }
#endif
#endif
    }
    else {
        // src, transit, sink mirrored
        process_int_insertion(); // for src, transit, sink e2e
        if (int_metadata_i2e.sink == 1 and pkt_is_mirrored) {
#ifdef INT_EP_ENABLE
            if (valid(vxlan_gpe)) {
                // Decap vxlan_gpe from sink mirrored pkt.
                // erspan_t3 encap will happen later.
                apply(int_decap_vxlan_gpe);
            }
#endif
        }
        else {
#ifdef INT_PLT_ENABLE
            // src or transit
            process_plt_insertion();
#endif
        }
    }
#endif
}

#ifdef INT_TRANSIT_ENABLE
action int_update_vxlan_gpe_ipv4() {
    add_to_field(ipv4.totalLen, int_metadata.insert_byte_cnt);
    add_to_field(udp.length_, int_metadata.insert_byte_cnt);
    add_to_field(vxlan_gpe_int_header.len, int_metadata.int_hdr_word_len);
}
#endif

#ifdef INT_EP_ENABLE
action int_add_update_vxlan_gpe_ipv4() {
    // INT source - vxlan gpe header is already added (or present)
    // Add the INT shim header for vxlan GPE
    add_header(vxlan_gpe_int_header);
    modify_field(vxlan_gpe_int_header.int_type, 0x01);
    modify_field(vxlan_gpe_int_header.next_proto, 3); // Ethernet
    modify_field(vxlan_gpe.next_proto, 5); // Set proto = INT
    modify_field(vxlan_gpe_int_header.len, int_metadata.int_hdr_word_len);
    add_to_field(ipv4.totalLen, int_metadata.insert_byte_cnt);
    add_to_field(udp.length_, int_metadata.insert_byte_cnt);
}

action int_update_erspan_ipv4() {
    add_to_field(ipv4.totalLen, int_metadata.insert_byte_cnt);
}
#endif

#ifdef INT_ENABLE
#ifdef INT_DEBUG
table int_egress_debug2 {
    reads {
        ipv4.totalLen:        exact;
        int_metadata.insert_byte_cnt: exact;
    }
    actions {
        nop;
    }
}
#endif

table int_outer_encap {
    /* REMOVE from open-srouce version -
     * ipv4 and gpe valid bits are used as key so that other outer protocols
     * can be added in future. Table size
     */
    // This table is applied only if it is decided to add INT info
    // as part of transit, source, or sink report functionality
    // based on outer(underlay) encap, vxlan-GPE, erspan_t3, .. update
    // outer headers, options, IP total len etc.
    // {int_src, int_sink, vxlan_gpe, erspan_t3, egr_tunnel_type} :
    //      0, 0, 1, 0, X : update_vxlan_gpe_int (transit case)
    //      1, 0, 0, 0, tunnel_gpe : VTEP-src, add_update_vxlan_gpe_int
    //      1, 0, 1, 0, X : upstream is VTEP-src, add_update_vxlan_gpe_int
    //      0, 1, 0, 1, tunnel_erspan_t3 : sink report, update_erspan_ipv4
    //      miss => nop
    reads {
        ipv4                                : valid;
        vxlan_gpe                           : valid;
        erspan_t3_header                    : valid;
        int_metadata_i2e.source             : exact;
        int_metadata_i2e.sink               : exact;
        tunnel_metadata.egress_tunnel_type  : ternary;
    }
    actions {
#ifdef INT_TRANSIT_ENABLE
        int_update_vxlan_gpe_ipv4;
#endif
#ifdef INT_EP_ENABLE
        int_add_update_vxlan_gpe_ipv4;
        int_update_erspan_ipv4;
#endif
        nop;
    }
    size : INT_UNDERLAY_ENCAP_TABLE_SIZE;
}
#endif

control process_int_outer_encap {
#ifdef INT_ENABLE
    if ((int_metadata.insert_cnt != 0)
            or (int_metadata_i2e.sink == 1 and pkt_is_e2e_mirrored))
    {
        //source, transit or sink e2e mirrored
        apply(int_outer_encap);
#ifdef INT_DEBUG
        apply(int_egress_debug2);
#endif
    }
#endif
}
