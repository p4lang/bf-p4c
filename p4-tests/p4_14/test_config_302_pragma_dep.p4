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
header single_word_t w2;
header single_word_t w3;
metadata meta_t meta;


parser start {
   return p_s0;
}

parser p_s0 {
   extract(w0);
   return p_s1;
}

parser p_s1 {
   extract(w1);
   return p_s2;
}

parser p_s2 {
   extract(w2);
   return p_s3;
}

parser p_s3 {
   extract(w3);
   return ingress;
}

action do_nothing(){}
action set_w0(p){  modify_field(w0.w, p); }
action set_w1(){  modify_field(w1.w, 2); }
action set_p() { 
     modify_field(ig_intr_md_for_tm.ucast_egress_port, 1); 
     modify_field(w0.w, 2);
}

table t0 {
    reads {
       w0.w : ternary;
    }
    actions {
       do_nothing;
       set_w0;
    }
}

table t1 {
    reads {
       w0.w : ternary;
    }
    actions {
       do_nothing;
       set_w0;
    }
}

@pragma ignore_table_dependency t1
table t2 {
    reads {
       w0.w : ternary;
    }
    actions {
       do_nothing;
       set_w0;
    }
}


table t3 {
    reads {
       w0.w : ternary;
    }
    actions {
       do_nothing;
       set_p;
    }
}

@pragma force_table_dependency t3
table t4 {
    reads {
       w2.w : ternary;
    }
    actions {
       do_nothing;
       set_w1;
    }
}

control ingress {
    apply(t0);
    if (valid(w2)){
        apply(t1);
    }
    apply(t2);
    if (valid(w1)){
        apply(t3);
    }
    apply(t4);
}

control egress {
}