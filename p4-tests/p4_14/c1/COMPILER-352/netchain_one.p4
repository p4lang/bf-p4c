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

header_type udp_t {
    fields {
        sPort : 16;
        dPort : 16;
        hdr_length : 16;
        checksum : 16;
    }
}
header udp_t udp;

header_type kv_t {
    fields {
        op : 8;
        key : 32;
        value : 32;
    }
}

header kv_t kv;
@pragma pa_atomic ingress kv.value
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
        17: parse_udp;
    }
}
parser parse_tcp {
    extract(tcp);
    return ingress;
}
parser parse_udp {
    extract(udp);
    return select(latest.dPort) {
        8888 : parse_kv;
        default: ingress;
    }
}

parser parse_kv {
    extract(kv);
    return ingress;
}
#include "tofino/intrinsic_metadata.p4"
#include "tofino/stateful_alu_blackbox.p4"







action set_egr(egress_spec) {
    modify_field(ig_intr_md_for_tm.ucast_egress_port, egress_spec);
}

action _no_op() {
    no_op();
}

action _drop() {
    drop();
}

table forward {
    reads {
        ethernet.dmac : exact;
    }
    actions {
        set_egr; _no_op;
    }
}
register kv_register {
    width: 32;
    instance_count: 8192;
}

blackbox stateful_alu kv_alu {
    reg: kv_register;
    condition_lo : kv.op == 1;
    update_lo_1_predicate : condition_lo;
    update_lo_1_value : kv.value;

    output_value: alu_lo;
    output_dst: kv.value;
}

action kv_execute(index) {
    kv_alu.execute_stateful_alu(index);
}

table kv_process {
    reads { kv.key : exact; }
    actions { kv_execute; }
    size: 1024;
}







control ingress {

    if(valid(kv)) {
        apply(kv_process);
    }

    apply(forward);
}

control egress {

}
