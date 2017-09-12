#include "tofino/intrinsic_metadata.p4"


header_type ethernet_t {
    fields {
        dstAddr_hi : 24;
        dstAddr_lo : 24;
        srcAddr_hi : 24;
        srcAddr_lo : 24;
        etherType : 16;
    }
}

field_list my_digest {
    ethernet.dstAddr_hi;
    ethernet.srcAddr_hi;
    ethernet.dstAddr_lo;
    ethernet.srcAddr_lo;
    ethernet.etherType;
}


header ethernet_t ethernet;

parser start {
    return parse_ethernet;
}


parser parse_ethernet {
    extract(ethernet);
    return ingress;
}


action action_0(){
    modify_field(ethernet.etherType, 4);
}

action action_1(){
    generate_digest(0, my_digest);
}

action do_nothing(){}


table table_0 {
    reads {
        ethernet.etherType: ternary;
    }
    actions {
        action_0;
        action_1;
        do_nothing;
    }
    size : 512;
}

control ingress { 
        apply(table_0);
}