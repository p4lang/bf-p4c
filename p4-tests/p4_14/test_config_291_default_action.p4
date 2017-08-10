#include "tofino/intrinsic_metadata.p4"

/* Sample P4 program */
header_type hdr1_t {
    fields {
        a : 16;
        b : 16;
        c : 16;
        d : 16;
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

action do_nothing(){}

action a0(x){ modify_field(hdr1.a, x); }
action a1(x){ modify_field(ig_intr_md_for_tm.ucast_egress_port, x); }
action a2(x){ modify_field(hdr1.b, x); }
action a3(x){ modify_field(hdr1.c, x); }
action a4(x){ modify_field(hdr1.d, x); }

table t1 {
    reads {
         hdr1.a : ternary;
    }
    actions {
         a0;
         a1;
         a2;
         do_nothing;
    }
    default_action : a0(1);
    size : 256;
}

table t2 {
    reads {
         hdr1.a : ternary;
    }
    actions {
         a3;
         do_nothing;
    }
    size : 256;
}

table t3 {
    reads {
         hdr1.a : ternary;
    }
    actions {
         a4;
         do_nothing;
    }
    size : 256;
}

table t4 {
    reads {
         hdr1.a : ternary;
    }
    actions {
         a3;
         do_nothing;
    }
    size : 256;
}

control ingress {
    apply(t1){
        a0 {
             apply(t2);
             apply(t3);
        }
    }
    apply(t4);
}
