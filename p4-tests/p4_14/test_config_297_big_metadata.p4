#include "tofino/intrinsic_metadata.p4"

header_type single_word_t {
    fields {
        w : 32;
    }
}

header_type meta_t {
    fields {
        big_meta : 510;
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
action set_big(p) { modify_field(meta.big_meta, p); }
action set_p(p) { modify_field(ig_intr_md_for_tm.ucast_egress_port, p); }

table t1 {
    reads {
       w0.w : ternary;
    }
    actions {
       do_nothing;
       set_big;
    }
}

table t2 {
    reads {
       meta.big_meta : exact;
    }
    actions {
        do_nothing;
        set_p;
    }
}

control ingress {
    apply(t1);
    apply(t2);
}