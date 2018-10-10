#include "tofino/intrinsic_metadata.p4"
#include "tofino/meter_blackbox.p4"

header_type single_word_t {
    fields {
        a : 8;
        b : 8;
        c : 8;
        d : 8;
    }
}

header_type meta_t {
    fields {
        color_0 : 8;
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

action drop_it(){
  drop();
}

action set_p() {
     modify_field(ig_intr_md_for_tm.ucast_egress_port, 1);
}

@pragma meter_profile 9
meter meter_0 {
    type : bytes;
    instance_count : 2048;
}

action mtr_0(idx){
     execute_meter(meter_0, idx, w1.c);
}

blackbox meter meter_1 {
    type : bytes;
    instance_count: 4096;

    green_value : 0;
    yellow_value: 127;
    red_value: 255;

    meter_profile : 3;
}

action mtr_1(idx){
     meter_1.execute(w2.a, idx);
}


table t0 {
    reads {
       w0.a : ternary;
       w0.b : ternary;
       w0.c : ternary;
       w0.d : ternary;
    }
    actions {
       do_nothing;
       mtr_0;
       drop_it;
    }
}

/* ------------------------ */

table t1 {
    reads {
       w0.d : ternary;
    }
    actions {
       do_nothing;
       mtr_1;
    }
}

control ingress {
    apply(t0);
    apply(t1);
}

control egress {
}
