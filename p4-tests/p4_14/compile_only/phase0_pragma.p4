#include "tofino/intrinsic_metadata.p4"

/* Sample P4 program */
header_type hdr1_t {
    fields {
        a : 16;
        b : 16;
        c : 16;
        d : 16;
        e : 32;
    }
}

header_type meta_t {
    fields { 
        w : 8;
        x : 4;
        y : 4;
        z : 8;
    }
}

parser start {
    return parse_pkt;
}


parser parse_pkt {
    extract(hdr1);
    return ingress;
}

header hdr1_t hdr1;
metadata meta_t meta;

action do_nothing(){}

action a0(x, y){
    modify_field(meta.x, x);
    modify_field(meta.y, y);
}

action a1(a){
    modify_field(hdr1.a, a);
}

// Add a phase0 pragma to force table to not be recognized as phase0. Generated
// bfa must not have a phase0_match table
@pragma phase0 0
table t0 {
    reads {
         ig_intr_md.ingress_port : exact;
    }
    actions {
         a0;
    }
    size : 288;
}

table t1 {
    reads {
         //meta.w : ternary;
         meta.x : exact;
         meta.y : exact;
         //meta.z : exact;
    }
    actions {
         a1;
         do_nothing;
    }
    default_action : do_nothing;
    size : 512;
}

control ingress {
    if (ig_intr_md.resubmit_flag == 0){
        apply(t0);
    }
}

control egress { 
    apply(t1);
}
