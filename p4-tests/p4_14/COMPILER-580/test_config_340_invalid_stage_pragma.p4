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

header ethernet_t ethernet;
header ipv4_t ipv4;

parser start {
    return parse_ethernet;
}


parser parse_ethernet {
    extract(ethernet);
    return parse_ipv4;
}

parser parse_ipv4 {
    extract(ipv4);
    return ingress;
}

action set_v(v){
    modify_field(ipv4.version, v);
}

action set_ihl(i){
    modify_field(ipv4.ihl, i);
}

action set_p(p){
    modify_field(ig_intr_md_for_tm.ucast_egress_port, p);
}

action do_nothing(){}

table table_0 {
    reads {
        ethernet.etherType: exact;
    }
    actions {
        set_p;
        set_v;
        do_nothing;
    }
    size : 4096;
}

@pragma stage 1
table table_1 {
   reads {
        ethernet.etherType : exact;
   }
   actions {
       set_ihl;
       do_nothing;
   }
}

control ingress { 
    apply(table_0);
    apply(table_1);
}