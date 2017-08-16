header_type ethernet_t {
    fields {
        dstAddr : 48;
        srcAddr : 48;
        etherType : 16;
    }
}
header ethernet_t ethernet;

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
header ipv4_t ipv4;

header_type tcp_t {
    fields {
        srcPort : 16;
        dstPort : 16;
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

header_type udp_t {
    fields {
        srcPort : 16;
        dstPort : 16;
        hdr_length : 16;
        checksum : 16;
    }
}
header udp_t udp;

header_type netchain_hdr_t {
    fields {
        op : 8;
        key : 64;
        seq : 32;
    }
}

@pragma pa_atomic ingress netchain_hdr.seq
header netchain_hdr_t netchain_hdr;

header_type netchain_val_t {
    fields {
        val1 : 32;
        val2 : 32;
    }
}

@pragma pa_atomic ingress netchain_value.val1
@pragma pa_atomic ingress netchain_value.val2
header netchain_val_t netchain_value;

header_type user_metadata_t {
    fields {
        key_exist : 1;
        write_valid : 1;
        seq_index : 16;
        val_index1 : 16;
        val_index2 : 16;
    }
}
metadata user_metadata_t md;
parser start {
    return parse_ethernet;
}

parser parse_ethernet {
    extract(ethernet);
    return select(latest.etherType) {
        0x0800 : parse_ipv4;
    }
}

parser parse_ipv4 {
    extract(ipv4);
    return select(latest.protocol) {
        6 : parse_tcp;
        17: parse_udp;
    }
}

parser parse_tcp {
    extract(tcp);
    return ingress;
}

parser parse_udp {
    extract(udp);
    return select(latest.dstPort) {
        8888 : parse_netchain;
        default: ingress;
    }
}

parser parse_netchain {
    extract(netchain_hdr);
    return select(latest.op) {
        1 : parse_netchain_val;
        default: ingress;
    }
}

parser parse_netchain_val {
    extract(netchain_value);
    return ingress;
}
#include "tofino/intrinsic_metadata.p4"

action set_egress(egress_spec) {
    modify_field(ig_intr_md_for_tm.ucast_egress_port, egress_spec);
}

table ipv4_routing {
    reads {
        ipv4.dstAddr : lpm;
    }
    actions {
        set_egress;
        _no_op;
    }
    size : 512;
}

action _no_op() {
    no_op();
}

action _drop() {
    drop();
}
#include "tofino/stateful_alu_blackbox.p4"

action get_index(seq_idx, val_idx1, val_idx2) {
    modify_field(md.seq_index, seq_idx);
    modify_field(md.val_index1, val_idx1);
    modify_field(md.val_index2, val_idx2);
    modify_field(md.key_exist, 1);
}

table netchain_index {
    reads {
        netchain_hdr.key : exact;
    }
    actions {
        get_index;
    }
    size: 65536;
}

register seq_register {
    width: 32;
    instance_count: 65536;
}

blackbox stateful_alu seq_alu {
    reg: seq_register;
    condition_lo : netchain_hdr.seq > register_lo;
    update_lo_1_predicate : condition_lo;
    update_lo_1_value : netchain_hdr.seq;

    output_value: combined_predicate;
    output_dst: md.write_valid;
}

action run_seq_alu() {
    seq_alu.execute_stateful_alu(md.seq_index);
}

table netchain_seq_check {
    actions {
        run_seq_alu;
    }
    size: 1;
}

register value_register_1 {
    width: 32;
    instance_count: 65536;
}

register value_register_2 {
    width: 32;
    instance_count: 65536;
}

blackbox stateful_alu value_alu_1 {
    reg: value_register_1;
    condition_lo : md.write_valid == 1;
    update_lo_1_predicate : condition_lo;
    update_lo_1_value : netchain_value.val1;

    output_value: alu_lo;
    output_dst: netchain_value.val1;
}

blackbox stateful_alu value_alu_2 {
    reg: value_register_2;
    condition_lo : md.write_valid == 1;
    update_lo_1_predicate : condition_lo;
    update_lo_1_value : netchain_value.val2;

    output_value: alu_lo;
    output_dst: netchain_value.val2;
}

action run_value_alu_1() {
    value_alu_1.execute_stateful_alu(md.val_index1);
}

action run_value_alu_2() {
    value_alu_2.execute_stateful_alu(md.val_index2);
}

table netchain_value_1 {
    actions {
        run_value_alu_1;
    }
    size : 1;
}

table netchain_value_2 {
    actions {
        run_value_alu_2;
    }
    size : 1;
}

control ingress {

    if(valid(netchain_hdr)) {
        apply(netchain_index);
        if(md.key_exist == 1) {
            if(netchain_hdr.op == 1) {
                apply(netchain_seq_check);
            }
            apply(netchain_value_1);
            apply(netchain_value_2);
        }
    }

    apply(ipv4_routing);
}

control egress {

}
