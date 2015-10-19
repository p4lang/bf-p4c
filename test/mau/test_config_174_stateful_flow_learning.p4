#include "tofino/intrinsic_metadata.p4"
#include "tofino/stateful_alu_blackbox.p4"


header_type ethernet_t {
    fields {
        dstAddr : 48;
        srcAddr : 48;
        etherType : 16;
    }
}

header_type ipv4_t {
    fields {
        version : 4;
        ihl : 4;
        diffserv : 8;
        totalLen : 16;
        identification : 16;
        flags : 3;
        fragOffset : 13;
        ttl : 8;
        protocol : 8;
        hdrChecksum : 16;
        srcAddr : 32;
        dstAddr: 32;
    }
}

header_type tcp_t {
    fields {
        srcPort : 16;
        dstPort : 16;
        seqNo : 32;
        ackNo : 32;
        dataOffset : 4;
        res : 4;
        flags : 8;
        window : 16;
        checksum : 16;
        urgentPtr : 16;
    }
}

header_type meta_t {
     fields {
         hash_1 : 16;
         hash_2 : 16;
         
         fc_1_1_hit : 1;
         fc_1_2_hit : 1;
         fc_2_1_hit : 1;
         fc_2_2_hit : 1;
         pad_0 : 4;

         port_numbers: 16;
         ports : 16;
         proto_idx_pair1: 16;
         proto_idx_pair2: 16;

         same_proto_1 : 8;
         same_proto_2 : 8;

         rewrite_idx : 16;
     }
}


header ethernet_t ethernet;
header ipv4_t ipv4;
header tcp_t tcp;
metadata meta_t meta;

parser start {
    return parse_ethernet;
}


parser parse_ethernet {
    extract(ethernet);
    return select(latest.etherType) {
        0x0800 : parse_ipv4;
        default : ingress;
    }
}

parser parse_ipv4 {
    extract(ipv4);
    return select(ipv4.protocol){
       0x06 : parse_tcp;
       default : ingress;
    }
}

parser parse_tcp {
    extract(tcp);
    return ingress;
}



field_list fields_for_hash {
    ipv4.srcAddr;
    ipv4.dstAddr;
}

field_list_calculation hash_1 {
    input { fields_for_hash; }
    algorithm: crc16;
    output_width: 16;
}

field_list_calculation hash_2 {
    input { fields_for_hash; }
    algorithm: identity;
    output_width: 16;
}


header_type flow_cache_1_layout {
     fields {
         src_ip : 32;
         dst_ip : 32;
     }
}

header_type flow_cache_2_layout {
     fields {
         pad : 8;
         protocol : 8;
         rewrite_idx : 16;
     }
}

register flow_cache_1_way_1 {
     layout : flow_cache_1_layout;
     instance_count : 16384;
}

register flow_cache_2_way_1 {
     layout : flow_cache_2_layout;
     instance_count : 16384;
}

register flow_cache_1_way_2 {
     layout : flow_cache_1_layout;
     instance_count : 16384;
}

register flow_cache_2_way_2 {
     layout : flow_cache_2_layout;
     instance_count : 16384;
}

register flow_cache_1_age {
     width: 64;
     instance_count : 16384;
}

register flow_cache_2_age {
     width: 64;
     instance_count : 16384;
}



blackbox stateful_alu flow_cache_1_way_1_alu {
    reg: flow_cache_1_way_1;

    condition_hi: register_lo == ipv4.dstAddr;
    condition_lo: register_hi == ipv4.srcAddr;

    update_lo_1_value: 1;

    output_predicate: condition_hi and condition_lo;
    output_value: alu_lo;
    output_dst: meta.fc_1_1_hit;
}

blackbox stateful_alu flow_cache_2_way_1_alu {
    reg: flow_cache_2_way_1;

    condition_hi: register_hi == meta.port_numbers;

    update_lo_1_value : register_lo;    

    output_predicate: condition_hi;
    output_value: alu_lo;
    output_dst: meta.proto_idx_pair1;
}

blackbox stateful_alu flow_cache_1_way_2_alu {
    reg: flow_cache_1_way_2;

    condition_hi: register_lo == ipv4.dstAddr;
    condition_lo: register_hi == ipv4.srcAddr;

    update_lo_1_value: 1;

    output_predicate: condition_hi and condition_lo;
    output_value: alu_lo;
    output_dst: meta.fc_1_1_hit;
}

blackbox stateful_alu flow_cache_2_way_2_alu {
    reg: flow_cache_2_way_2;

    condition_hi: register_hi == meta.port_numbers;

    update_lo_1_value : register_lo;    

    output_predicate: condition_hi;
    output_value: alu_lo;
    output_dst: meta.proto_idx_pair1;
}

blackbox stateful_alu flow_cache_1_way_1_learn_alu {
    reg: flow_cache_1_way_1;

    condition_hi: register_lo == 0;
    condition_lo: register_hi == 0;

    update_hi_1_predicate: condition_hi and condition_lo;
    update_hi_1_value: ipv4.srcAddr;

    update_lo_1_predicate: condition_hi and condition_lo;
    update_lo_1_value: ipv4.dstAddr;
}

blackbox stateful_alu flow_cache_2_way_1_learn_alu {
    reg: flow_cache_2_way_1;

    condition_hi: register_lo == 0;
    condition_lo: register_hi == 0;

    update_hi_1_predicate: condition_hi and condition_lo;
    update_hi_1_value: meta.port_numbers;

    update_lo_1_predicate: condition_hi and condition_lo;
    update_lo_1_value: meta.proto_idx_pair1;
}

action do_flow_table_cache_1_1(){
    flow_cache_1_way_1_alu.execute_stateful_alu();
}

action do_flow_table_cache_2_1(){
    flow_cache_2_way_1_alu.execute_stateful_alu();
    /* bit_xor(meta.same_proto_1, ipv4.protocol, meta.proto_idx_pair1); */
}

action do_flow_table_cache_1_2(){
    flow_cache_1_way_2_alu.execute_stateful_alu();
}

action do_flow_table_cache_2_2(){
    flow_cache_2_way_2_alu.execute_stateful_alu();
    /* bit_xor(meta.same_proto_2, ipv4.protocol, meta.proto_idx_pair2); */
}

action do_flow_table_learn_1_1(){
    flow_cache_1_way_1_learn_alu.execute_stateful_alu();
}

action do_flow_table_learn_2_1(){
    flow_cache_2_way_1_learn_alu.execute_stateful_alu();
}


action set_hashes_1_and_2(){
     modify_field_with_hash_based_offset(meta.hash_1, 0, hash_1, 65536);
     modify_field_with_hash_based_offset(meta.hash_2, 0, hash_2, 65536);
}

action set_rewrite_idx(rewrite_idx){
    modify_field(meta.rewrite_idx, rewrite_idx);
}

action on_miss(){}
action do_nothing(){}

action set_dst_port(port){
    modify_field(tcp.dstPort, port);
}


table flow_table_cpu {
    reads {
        ipv4.srcAddr  : exact;
        ipv4.dstAddr  : exact;
        ipv4.protocol : exact;
        meta.ports    : exact;
    }
    actions { 
       set_rewrite_idx; 
       on_miss; 
    }
    size : 4096;
}



table set_hashes_1_and_2_tbl {
    actions {
        set_hashes_1_and_2;
    }
    size : 1;
}

table flow_table_cache_1_1 {
    reads {
        meta.hash_1 : exact;
    }
    actions { do_flow_table_cache_1_1; }
    size: 65536;
}

table flow_table_cache_2_1 {
    reads {
        meta.hash_2 : exact;
    }
    actions { do_flow_table_cache_2_1; }
    size: 65536;
}

table flow_table_cache_1_2 {
    reads {
        meta.hash_1 : exact;
    }
    actions { do_flow_table_cache_1_2; }
    size: 1;
}

table flow_table_cache_2_2 {
    reads {
        meta.hash_2 : exact;
    }
    actions { do_flow_table_cache_2_2; }
    size: 1;
}

table flow_table_cache_1_age {
    reads {
        meta.hash_1 : exact;
    }
    actions {
        do_flow_table_learn_1_1;
    }
    size : 65536;
}

table flow_table_cache_2_age {
    reads {
        meta.hash_2 : exact;
    }
    actions {
        do_flow_table_learn_2_1;
    }
    size : 65536;
}


table slow_path {
    reads {
       ipv4.totalLen : exact;
       meta.port_numbers: exact;  /* HACK */
    }
    actions {
       do_nothing;
    }
    size : 3072;
}

table rewrite_tbl {
    reads {
        meta.rewrite_idx : exact;
    }
    actions {
        set_dst_port;
        do_nothing;
    }
    size : 4096;
}


/* Main control flow */

control ingress {
    apply(flow_table_cpu) {
        on_miss {
            apply(flow_table_cache_1_1);
            apply(flow_table_cache_2_1);
            apply(flow_table_cache_1_2);
            apply(flow_table_cache_2_2);
            if ((meta.fc_1_1_hit == 1) and (meta.same_proto_1 == 0) and
    ((meta.proto_idx_pair1 & 0xffff) != 0)) {
                /* apply( rewrite_tbl_1 ); */
                apply(flow_table_cache_1_age);
            } else if ((meta.fc_1_2_hit == 1) and (meta.same_proto_2 ==
    0) and ((meta.proto_idx_pair2 & 0xffff) != 0)) {
                /* apply( rewrite_tbl_2 ); */
                apply(flow_table_cache_2_age);
            } else {
                apply( slow_path );
            }
        }
        default {
            apply( rewrite_tbl );
        }
    }
}
