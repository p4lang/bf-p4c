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

@pragma pa_container ingress hdr1.a 123
@pragma pa_container ingress hdr1.c 66
@pragma pa_container egress hdr1.a 312
@pragma pa_container egress hdr1.c 126
header hdr1_t hdr1;
metadata meta_t meta;

action do_nothing(){}

action set_pkt(){
    modify_field(hdr1.a, 1);
    modify_field(hdr1.b, 2);
    modify_field(hdr1.c, 3);
}

table t1 {
    reads {
         hdr1.a : exact;
    }
    actions {
         set_pkt;
         do_nothing;
    }
    size : 4096;
}


control ingress {
    apply(t1);
}

control egress { }