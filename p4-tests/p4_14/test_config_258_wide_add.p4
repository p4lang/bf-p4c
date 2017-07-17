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

header pkt_t pkt;

action do_nothing(){}

action wide_add_1(x){
    add(pkt.c, pkt.c, x);
}

action wide_add_2(){
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

table t2 {
    reads {
         pkt.b : exact;
    }
    actions {
         wide_add_2;
         do_nothing;
    }
    size : 4096;
}

control ingress {
    apply(t1);
    apply(t2);
}

control egress { }