#include "tofino/intrinsic_metadata.p4"

header_type single_word_t {
    fields {
        w : 32;
    }
}

header_type meta_t {
    fields {
        x : 32;
    }
}

header single_word_t w0;
header single_word_t w1;
metadata meta_t meta;

parser start {
   return p_s0;
}

parser p_s0 {
   extract(w0);
   return ingress;
}


action do_nothing(){}
action set_p() { modify_field(ig_intr_md_for_tm.ucast_egress_port, 1); }
action a2() { modify_field(w0.w, 2); }

table t1 {
    reads {
       w0.w : ternary;
    }
    actions {
       do_nothing;
       set_p;
    }
    default_action : set_p;
}

table et1 {
    reads {
       ig_intr_md.ingress_port : exact;
    }
    actions {
        do_nothing;
        a2;
    }
}

control ingress {
    apply(t1);
}

control egress {
    apply(et1);
}