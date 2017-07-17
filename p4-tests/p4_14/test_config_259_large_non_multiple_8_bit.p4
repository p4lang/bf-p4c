#include "tofino/intrinsic_metadata.p4"

/* Sample P4 program */
header_type pkt_t {
    fields {
        a : 32;
        b : 32;
        c : 64;
        d : 64;
        e : 8;
        f : 36;
        g : 4;
    }
}

parser start {
    return parse_pkt;
}


parser parse_pkt {
    extract(pkt);
    return ingress;
}

header pkt_t pkt;

action do_nothing(){}

action a1(x){
    modify_field(pkt.a, x);
}

table t1 {
    reads {
         pkt.a : exact;
    }
    actions {
         a1;
         do_nothing;
    }
   
 size : 4096;
}

control ingress {
    apply(t1);
}

control egress { }