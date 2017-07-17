#include "tofino/intrinsic_metadata.p4"

/* Sample P4 program */
header_type hdr1_t {
    fields {
        a_6 : 6;
        b_10 : 10;
        c_8 : 8;
        d_8 : 8;
        e_16 : 16;
    }
}

header_type meta_t {
    fields {
        x_16 : 16;
    }
}


parser start {
    return parse_pkt;
}

parser parse_pkt {
    extract(hdr1);
    return ingress;
}

@pragma pa_container_size ingress hdr1.a_6 8
@pragma pa_container_size ingress hdr1.c_8 16
@pragma pa_solitary ingress hdr1.d_8
header hdr1_t hdr1;
metadata meta_t meta;

action do_nothing(){}

action a0(x){
    modify_field(meta.x_16, x);
}

action a1(){
    modify_field(hdr1.b_10, meta.x_16);
}

table t0 {
    reads {
         hdr1.e_16 : ternary;
    }
    actions {
         a0;
         do_nothing;
    }
    size : 512;
}


table t1 {
    reads {
         hdr1.d_8 : exact;
    }
    actions {
         a1;
         do_nothing;
    }
    size : 256;
}

control ingress {
    apply(t0);
    apply(t1);
}

control egress { }