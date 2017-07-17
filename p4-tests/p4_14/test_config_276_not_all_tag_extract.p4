#include "tofino/intrinsic_metadata.p4"

/* Sample P4 program */
header_type hdr1_t {
    fields {
        a_8 : 8;
        b_16 : 16;
        c_8 : 8;
        d_8 : 8;
    }
}

parser start {
    return parse_pkt;
}


parser parse_pkt {
    extract(hdr1[next]);
    return ingress;
}


header hdr1_t hdr1[2];

action do_nothing(){}

action a1(){
    modify_field(hdr1[0].a_8, 1);
}

table t1 {
    reads {
         hdr1[0].a_8 : exact;
    }
    actions {
         a1;
         do_nothing;
    }
    size : 256;
}

control ingress {
    apply(t1);
}

control egress { }