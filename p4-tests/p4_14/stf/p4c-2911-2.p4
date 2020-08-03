#include "tofino/intrinsic_metadata.p4"

#ifndef FP_PORT_2
#if __TARGET_TOFINO__ == 2
// Default ports for Tofino2 have offset 8
#define FP_PORT_2 10
#else
#define FP_PORT_2 2
#endif
#endif


// Headers
header_type data_t {
    fields {
        f1 : 32;
        f2 : 32;
        h1 : 16;
        b1 : 8;
        b2 : 8;
        b3 : 8;
    }
}

header_type bridged_md_t {
    fields {
        bmd1 : 8;
        bmd2 : 8;
    }
}

header data_t hdr;
metadata bridged_md_t bmd;

// Parser
parser start {
    return parse_data;
}

parser parse_data {
    extract(hdr);
    return ingress;
}

// Ingress Control
action nop() { }

action set_bmd() {
    modify_field(bmd.bmd1, 0x11);
    modify_field(bmd.bmd2, 0x22);
}

table set_bridged {
    actions { set_bmd; nop; }
    reads { hdr.f1 : exact; }
    default_action : nop;
}


action act(port) {
    modify_field(ig_intr_md_for_tm.ucast_egress_port,  port);
}

table set_port {
    actions { act; nop; }
    reads { hdr.f1: exact; }
    default_action : nop;
}

@pragma adjust_byte_count 4
counter ICounterDirect {
    type : packets_and_bytes;
    direct : update_ingress_counter;
}

action update_ig() {
}

table update_ingress_counter {
    actions { update_ig; nop; }
    reads { hdr.f1: exact; }
    default_action : nop;
}

@pragma adjust_byte_count 4
counter ICounter {
    type : packets_and_bytes;
    instance_count : 1024;
    min_width : 64;
}

action update2_ig(idx) {
    count(ICounter, idx); 
}

table update_ingress_counter2 {
    actions { update2_ig; nop; }
    reads { hdr.f1: exact; }
    default_action : nop;
}

control ingress {
    apply(set_bridged);
    apply(set_port);
    apply(update_ingress_counter);
    apply(update_ingress_counter2);
}

// Egress Control
@pragma adjust_byte_count 4
counter ECounterDirect {
    type : packets_and_bytes;
    direct : update_egress_counter;
    min_width : 64;
}

action update_eg() {
    modify_field(hdr.b1, bmd.bmd1);
}

table update_egress_counter {
    actions { update_eg; nop; }
    reads { hdr.f1: exact; }
    default_action : nop;
}

@pragma adjust_byte_count 4
counter ECounter{
    type : packets_and_bytes;
    instance_count : 1024;
    min_width : 64;
}

action update2_eg(idx) {
    count(ECounter, idx);
    modify_field(hdr.b2, bmd.bmd2);
}

table update_egress_counter2 {
    actions { update2_eg; nop; }
    reads { hdr.f1: exact; }
    default_action : nop;
}

control egress{ 
    apply(update_egress_counter);
    apply(update_egress_counter2);
}
