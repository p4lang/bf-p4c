#include "tofino/intrinsic_metadata.p4"
#include "tofino/stateful_alu_blackbox.p4"

/******************************************************************************
 *
 * Headers
 *
 *****************************************************************************/

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

header_type user_metadata_t {
    fields {
        ifid : 16;
        egr_ifid : 16;
        timestamp : 48;
        nh_id : 16;
    }
}
metadata user_metadata_t md;

header_type kv_t {
    fields {
        option : 8;
        key : 32;
        value : 32;
    }
}

header kv_t kv;

/******************************************************************************
 *
 * Parser
 *
 *****************************************************************************/

parser start {
    return select( current(0,8) ) {
        default: parse_ethernet;
    }
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

/******************************************************************************
 *
 * IPv4 Route Table
 *
 *****************************************************************************/
action set_next_hop(nh) {
    modify_field(md.nh_id, nh);
}

table ipv4_route {
    reads { ipv4.dip : lpm; }
    actions {
        set_next_hop;
    }
    size : 512;
}

/******************************************************************************
 *
 * Next Hop Table
 *
 *****************************************************************************/

action set_egr_ifid(ifid) {
    modify_field(md.egr_ifid, ifid);
}

table next_hop {
    reads   { md.nh_id : ternary; }
    actions {
        set_egr_ifid;
    }
    size: 4096;
}


/******************************************************************************
 *
 * Egress Ifid Table
 *
 *****************************************************************************/
register lag_reg {
    width : 1;
    instance_count : 131072;
}

@pragma seletor_num_max_groups 128
@pragma selector_max_group_size 1200
table egr_ifid {
    reads {md.egr_ifid : exact;}
    action_profile : lag_ap;
    size : 16384;
}
action_profile lag_ap {
    actions { set_egr_port; }
    size : 4096;
    dynamic_action_selection : lag_as;
}
action_selector lag_as {
    selection_key: lag_hash;
    selection_mode: resilient;
}
field_list_calculation lag_hash {
    input { lag_fields; }
    algorithm: random;
    output_width: 66;
}
field_list lag_fields {
    ipv4.proto;
    ipv4.sip;
    ipv4.dip;
    tcp.sPort;
    tcp.dPort;
    ig_intr_md.ingress_port;
}
action set_egr_port(port) {
    modify_field(ig_intr_md_for_tm.ucast_egress_port, port);
}

action drop_ifid_update_pkt() {
    drop();
}

/******************************************************************************
 *
 * Egress Port Table
 *
 *****************************************************************************/

action set_dest(port) {
    modify_field(ig_intr_md_for_tm.ucast_egress_port, port);
}
table egr_port {
    reads { md.egr_ifid : ternary; }
    actions { set_dest; }
    size : 16384;
}

/******************************************************************************
 *
 * Key-Value table Table
 *
 *****************************************************************************/

action _no_op() {
    no_op();
}

register kv_register {
    width: 32;
    instance_count: 8192;
}

blackbox stateful_alu kv_alu {
    reg: kv_register;
    output_value: register_lo;
    output_dst: kv.value;
}

action kv_read(index) {
    kv_alu.execute_stateful_alu(index);
}

table kv_process {
    reads { kv.key : exact; }
    actions { kv_read; }
    size: 1024;
}

control ingress {

    if(valid(kv)) {
        apply(kv_process);
    }

    apply(ipv4_route);

    apply(next_hop);

    apply(egr_ifid) {
        miss {
            apply(egr_port);
        }
    }
}

control egress {

}
