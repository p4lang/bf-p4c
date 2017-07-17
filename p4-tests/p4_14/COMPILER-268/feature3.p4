#include "tofino/stateful_alu_blackbox.p4"


/******Headers*********/

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

header_type feature_header_t {
    fields {
        f1 : 16;
        f2: 1;
    }
}

/**********Parsers***********/

parser start {
    return parse_ethernet;
}

header ethernet_t ethernet;

parser parse_ethernet {
    extract(ethernet);
    return select(latest.etherType) {
        0x800 : parse_ipv4;
        default: ingress;
    }
}

header ipv4_t ipv4;

parser parse_ipv4 {
    extract(ipv4);
    return ingress;
}

metadata feature_header_t feature_header;

/**********Registers*********/

register feature_register1 {
    width : 16;
    instance_count : 256;
}

register feature_register2 {
    width : 16;
    instance_count : 256;
}

register feature_register3 {
    width : 16;
    instance_count : 256;
}

/********SALUs*********/

blackbox stateful_alu feature_salu1 {
    reg: feature_register1;

    update_lo_1_value: register_lo + ipv4.totalLen;

    output_value : register_lo;
    output_dst: feature_header.f1;

}

blackbox stateful_alu feature_salu2 {
    reg: feature_register2;

    update_lo_1_value: register_lo + ipv4.totalLen;

}

blackbox stateful_alu feature_salu3 {
    reg: feature_register3;

    update_lo_1_value: register_lo + ipv4.totalLen;

}


/*************Actions******************/

action feature_action1(my_value) {
    feature_salu1.execute_stateful_alu(feature_header.f1);
}

action feature_action2() {
    feature_salu2.execute_stateful_alu(feature_header.f1);
}

action feature_action3() {
    feature_salu3.execute_stateful_alu(feature_header.f1);
}


/******************Tables************/
table feature_table1 {
    actions {
        feature_action1;
    }
    size : 1;
}

//@pragma stage 0
table feature_table2 {
    actions {
        feature_action2;
    }
    size : 1;
}

table feature_table3 {
    actions {
        feature_action3;
    }
    size : 1;
}

/*********Controls*********/

control ingress {
    apply(feature_table1);
    if (ipv4.protocol == 6) {
        apply(feature_table2);
    }
    else
    {
        apply(feature_table3);
    }
}
