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

header_type meta_t {
    fields {
        color : 2;
        x : 4;
        y : 2;
    }
}


header ethernet_t ethernet;
header ipv4_t ipv4;
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
    return ingress;
}


meter my_meter {                                                              
    type : bytes;                                                               
    direct : table_0;
    result : meta.color;
}  

action do_nothing() {}

action action_0(y){
    modify_field(ipv4.diffserv, 5);
    modify_field(meta.y, y);
}                                                                               

action action_1(x){
    modify_field(meta.x, x);
}
                                                                               
action action_2(){
    drop();
}                                                                               


table table_0 {                                               
    reads {                                                                     
        ipv4.srcAddr : lpm;                                                   
    }                                                                           
    actions {                                                                   
        action_0;
    }
    size : 512;
}  

table table_1 {                                               
    reads { 
        ipv4.diffserv : exact;
    }                                                                           
    actions {                                                                   
        action_1;
    }
    size : 256;
} 

table table_2 {                                               
    reads { 
        meta.color : exact;
        meta.x : ternary;
        meta.y : exact;
    }                                                                           
    actions {                                                                   
        action_2;
        do_nothing;
    }
    size: 16;
}  

/* Main control flow */

control ingress {
    apply(table_0);
    apply(table_1);
    apply(table_2);
}
