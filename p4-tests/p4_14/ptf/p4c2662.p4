/* -*- P4_14 -*- */

#ifdef __TARGET_TOFINO__
#include <tofino/constants.p4>
#include <tofino/intrinsic_metadata.p4>
#include <tofino/primitives.p4>
#include <tofino/stateful_alu_blackbox.p4>
#else
#error This program is intended to compile for Tofino P4 architecture only
#endif

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
        src_addr : 32;
        dst_addr : 32;
    }
}

header ethernet_t ethernet;
header ipv4_t ipv4;

#define ETHERTYPE_IPV4 0x0800
#define TCP_PROTC 0x000006
#define MY_HEADER 0x20

parser start {
    return parse_ethernet;
}

parser parse_ethernet {
    extract(ethernet);
    return select(latest.etherType) {
        ETHERTYPE_IPV4: parse_ipv4;
        default: ingress;
    }
}

parser parse_ipv4 {
    extract(ipv4);
    return ingress;
}

action send() {
    modify_field(ig_intr_md_for_tm.ucast_egress_port, ig_intr_md.ingress_port);
    bypass_egress();
}

table ipv4_host {
    reads {
        ipv4.dst_addr : exact;
    }
    actions {
        send;
    }
    default_action: send();
}

register my_reg {
    width: 32;
    instance_count: 65536;
}

blackbox stateful_alu get_my_reg_update_three_quarters {
    reg: my_reg;

    update_lo_2_value: math_unit;
    output_value: register_lo;
    output_dst: ipv4.dst_addr;

    math_unit_input: register_lo;
    math_unit_exponent_shift: 0;
    math_unit_exponent_invert: false;
    math_unit_output_scale: -5;
    math_unit_lookup_table: 45 42 39 36 33 30 27 24 21 18 15 12 9 6 3 0;   
}

action get_avg_value() {
    get_my_reg_update_three_quarters.execute_stateful_alu(0);
}

table get_hist_avg_value {
    actions {
        get_avg_value;
    }
    default_action: get_avg_value();
    size: 1;
}

control ingress {
    /* Send the packet to the port */
    apply(ipv4_host);
    /* Update ipv4.dst_addr = (my_reg(0) *= 0.75) */
    apply(get_hist_avg_value);
}

