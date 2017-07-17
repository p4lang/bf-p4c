#include "tofino/intrinsic_metadata.p4"

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


parser start {
    return parse_ethernet;
}

header ethernet_t ethernet;
header ipv4_t ipv4;

parser parse_ethernet {
    extract(ethernet);
    return select(ethernet.etherType) {
        0x800 : parse_ipv4;
        default: ingress;
    }
}

parser parse_ipv4 {
    extract(ipv4);
    return ingress;
}

/* Field lists */

/* Negative test, can't be symmetric with field not in field list. */
@pragma symmetric ethernet.etherType ipv4.totalLen
field_list fl_1 {
    ethernet.etherType;
    ipv4.dstAddr;
    ipv4.srcAddr;
}

field_list fl_2 {
    ethernet.dstAddr;
    ipv4.ttl;
    ipv4.protocol;
}

field_list fl_3 {
    ethernet.srcAddr;
    ethernet.dstAddr;
}


/* Selectable hash algorithms */

field_list_calculation fl_calc {
   input {
       fl_1;
       //fl_2;
       //fl_3;
   }
   algorithm {
       random;
       crc_64;
   }
   output_width : 64;
}

/* Selector actions */

action do_nothing(){}

action sel_action_0(p0, p1){
    modify_field(ethernet.etherType, p0);
    modify_field(ipv4.diffserv, p1);
}

action sel_action_1(p0, p1, p2){
    modify_field(ethernet.etherType, p0);
    modify_field(ipv4.diffserv, p1);
    modify_field(ipv4.dstAddr, p2);
}

action set_p(p){
   modify_field(ig_intr_md_for_tm.ucast_egress_port, p);
}

action_selector the_sel {
    selection_key : fl_calc;
    selection_mode : fair;
}

action_profile prof {
    actions {
       sel_action_0;
       sel_action_1;
       do_nothing;
    }
    size : 4096;
    dynamic_action_selection : the_sel;
}


/* Tables */

@pragma selector_max_group_size 121
table t0 {
    reads {
        ethernet.etherType : exact;
        ethernet.srcAddr : exact;
    }
    action_profile : prof;
    size : 8192;
}

table t1 {
    reads {
        ipv4.diffserv : ternary;
    }
    actions {
        do_nothing;
        set_p;
    }
    size : 512;
}


/* Control */

control ingress {
    apply(t0);
    apply(t1);
}