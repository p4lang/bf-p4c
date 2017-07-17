#include "tofino/intrinsic_metadata.p4"

/* Sample P4 program */
header_type hdr1_t {
    fields {
        a : 8;
        b : 16;
        c : 8;
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
    return ingress;
}

@pragma pa_container_size ingress hdr1.a 16
@pragma pa_container_size ingress hdr1.c 16
header hdr1_t hdr1;
metadata meta_t meta;

action do_nothing(){}

action set_meta(x, y, z){
    modify_field(meta.x_16, x);
    modify_field(meta.y_8, y);
    modify_field(meta.z_8, z);
}


action set_pkt(){
    modify_field(hdr1.a, meta.y_8);
    modify_field(hdr1.b, meta.x_16);
    modify_field(hdr1.c, meta.z_8);
}


table t1 {
    reads {
         hdr1.a : exact;
    }
    actions {
         set_meta;
         do_nothing;
    }
    size : 4096;
}

table t2 {
    reads {
         hdr1.b : exact;
    }
    actions {
         set_pkt;
         do_nothing;
    }
    size : 4096;
}

control ingress {
    apply(t1);
    apply(t2);
}

control egress { }