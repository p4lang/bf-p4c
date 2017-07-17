#include "tofino/intrinsic_metadata.p4"

header_type single_byte_t {
    fields {
        b : 8;
    }
}

header_type single_word_t {
    fields {
        w : 32;
    }
}

header single_word_t w0;
header single_word_t w1;
header single_byte_t b0;
header single_byte_t b1;


parser start {
   return p_s0;
}

parser p_s0 {
   extract(w0);
   return select (current(0, 8)){
      0 : p_s1a;
      default : p_s1b;
   }
}

parser p_s1a {
    extract(b0);
    extract(b1);
    return p_s2;
}
parser p_s1b {
    extract(b1);
    extract(b0);
    return p_s2;
}

parser p_s2 {
    extract(w1);
    return ingress;
}

action do_nothing(){}
action set_p(p) { modify_field(ig_intr_md_for_tm.ucast_egress_port, p); }

table t1 {
    reads {
       w0.w : ternary;
    }
    actions {
       do_nothing;
       set_p;
    }
}

control ingress {
    apply(t1);
}