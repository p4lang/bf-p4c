#include "tofino/intrinsic_metadata.p4"
#include "tofino/stateful_alu_blackbox.p4"

header_type ethernet_t {
    fields {
        dmac : 48;
        smac : 48;
        ethertype : 16;
    }
}
header ethernet_t ethernet;

header_type ipv4_t {
    fields {
        ver : 4;
        len : 4;
        diffserv : 8;
        totalLen : 16;
        id : 16;
        flags : 3;
        offset : 13;
        ttl : 8;
        proto : 8;
        csum : 16;
        sip : 32;
        dip : 32;
    }
}
header ipv4_t ipv4;

header_type tcp_t {
    fields {
        sPort : 16;
        dPort : 16;
        seqNo : 32;
        ackNo : 32;
        dataOffset : 4;
        res : 3;
        ecn : 3;
        ctrl : 6;
        window : 16;
        checksum : 16;
        urgentPtr : 16;
    }
}
header tcp_t tcp;

header_type user_metadata_t {
    fields {
        bf_tmp : 1;
    }
}
metadata user_metadata_t md;

parser start {
    return parse_ethernet;
}

parser parse_ethernet {
    extract(ethernet);
    return select(latest.ethertype) {
        0x0800 : parse_ipv4;
    }
}

parser parse_ipv4 {
    extract(ipv4);
    return select(latest.proto) {
        6 : parse_tcp;
    }
}
parser parse_tcp {
    extract(tcp);
    return ingress;
}

/******************************************************************************
 *
 * Bloom Filter Table
 *  - Will set the C2C flag for packets not part of the filter
 *  - Will add the packet to the filter
 *
 *****************************************************************************/

/* Field list describing which fields contribute to the bloom filter hash. */
field_list bf_hash_fields {
    ipv4.proto;
    ipv4.sip;
    ipv4.dip;
    tcp.sPort;
    tcp.dPort;
}

/* Three hash functions for the filter, just using random hash functions right
 * now. */
field_list_calculation bf_hash_1 {
    input { bf_hash_fields; }
    algorithm: random;
    output_width: 18;
}
field_list_calculation bf_hash_2 {
    input { bf_hash_fields; }
    algorithm: random;
    output_width: 18;
}
field_list_calculation bf_hash_3 {
    input { bf_hash_fields; }
    algorithm: random;
    output_width: 18;
}

/* Three registers implementing the bloom filter.  Each register takes 3 RAMs;
 * each RAM has 128k entries so two RAMs to make 256k plus a third RAM as the
 * spare, so 9 RAMs total. */
register bloom_filter_1 {
    width : 1;
    instance_count : 262144;
}
register bloom_filter_2 {
    width : 1;
    instance_count : 262144;
}
register bloom_filter_3 {
    width : 1;
    instance_count : 262144;
}

/* Three stateful ALU blackboxes running the bloom filter.
 * With reduction-OR support, all ALUs output to the same temp variable.
 * Output is 1 if the packet is not in the filter and 0 if it is in. */
blackbox stateful_alu bloom_filter_alu_1 {
    reg: bloom_filter_1;
    update_lo_1_value: set_bitc;
    output_value: alu_lo;
    output_dst: md.bf_tmp;
    reduction_or_group: bloom_filter;
}
blackbox stateful_alu bloom_filter_alu_2 {
    reg: bloom_filter_2;
    update_lo_1_value: set_bitc;
    output_value: alu_lo;
    output_dst: md.bf_tmp;
    reduction_or_group: bloom_filter;
}
blackbox stateful_alu bloom_filter_alu_3 {
    reg: bloom_filter_3;
    update_lo_1_value: set_bitc;
    output_value: alu_lo;
    output_dst: md.bf_tmp;
    reduction_or_group: bloom_filter;
}

/* Note that we need additional actions here to OR the bloom filter results
 * into a single result. */
action check_bloom_filter_1() {
    bloom_filter_alu_1.execute_stateful_alu_from_hash(bf_hash_1);
}
action check_bloom_filter_2() {
    bloom_filter_alu_2.execute_stateful_alu_from_hash(bf_hash_2);
}
action check_bloom_filter_3() {
    bloom_filter_alu_3.execute_stateful_alu_from_hash(bf_hash_3);
}
action bloom_filter_mark_sample() {
    modify_field(ig_intr_md_for_tm.copy_to_cpu, 1);
}

table bloom_filter_1 {
    actions { check_bloom_filter_1; }
    size : 1;
}
table bloom_filter_2 {
    actions { check_bloom_filter_2; }
    size : 1;
}
table bloom_filter_3 {
    actions { check_bloom_filter_3; }
    size : 1;
}

/* Extra tables to run an action to mark a packet for sampling.
 * This will be removed once the compiler supports the reduction-OR
 * operation. */
table bloom_filter_sample {
    actions { bloom_filter_mark_sample; }
    size : 1;
}

control ingress {
    apply(bloom_filter_1);
    apply(bloom_filter_2);
    apply(bloom_filter_3);
    if (md.bf_tmp != 0) {
        apply(bloom_filter_sample);
    }
}
