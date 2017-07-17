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

header_type meta_t {
    fields {
        x_16 : 16;
        y_8  : 8;
        z_8  : 8;
    }
}


parser start {
    return parse_pkt;
}


parser parse_pkt {
    extract(hdr1);
    return parse_pkt2;
}

parser parse_pkt2 {
    extract(hdr2);
    return ingress;
}

header hdr1_t hdr1;
header hdr1_t hdr2;
metadata meta_t meta;

action do_nothing(){}

action a1(){
    modify_field(hdr1.b_16, hdr2.b_16);
    modify_field(hdr1.c_8, meta.y_8);
}


action a2(){
    modify_field(hdr1.b_16, hdr2.b_16);
    modify_field(hdr1.c_8, hdr2.a_8);
}


table t1 {
    reads {
         hdr1.a_8 : exact;
    }
    actions {
         //a1;
         do_nothing;
    }
    size : 256;
}

table t2 {
    reads {
         hdr2.c_8 : exact;
    }
    actions {
         a2;
         do_nothing;
    }
    size : 256;
}

control ingress {
    apply(t1);
    apply(t2);
}

control egress { }