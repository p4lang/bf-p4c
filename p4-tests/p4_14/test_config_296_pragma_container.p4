#include "tofino/intrinsic_metadata.p4"

/* Sample P4 program */
header_type pkt_t {
    fields {
        a : 32;
        b : 32;
        c : 64;
        d : 64;
        e : 8;
    }
}

parser start {
    return parse_pkt;
}


parser parse_pkt {
    extract(pkt);
    return ingress;
}

@pragma pa_container ingress pkt.c 3 2
header pkt_t pkt;

action do_nothing(){}


action wide_add_1(){
    add(pkt.c, pkt.c, pkt.d);
}

table t1 {
    reads {
         pkt.a : exact;
    }
    actions {
         wide_add_1;
         do_nothing;
    }
    size : 4096;
}
control ingress {
    apply(t1);
}

control egress { }