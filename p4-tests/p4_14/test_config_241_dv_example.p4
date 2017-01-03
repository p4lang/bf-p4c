#include "tofino/intrinsic_metadata.p4"

header_type hdr0_t {
    fields {
        a : 16;
        b : 8;
        c : 8;
    }
}

header_type hdr1_t {
    fields {
        a : 16;
        b : 8;
        c : 8;
   }
}

header_type hdr2_t {
    fields {
        a : 16;
        b : 8;
        c : 8;
   }
}

header_type meta_t {
    fields {
       x : 8;
       y : 8;
       z : 16;
    }
}

header hdr0_t hdr0;
header hdr1_t hdr1;
header hdr2_t hdr2;

metadata meta_t meta;

parser start {
   return p_hdr0;
}

parser p_hdr0 {
   extract(hdr0);
   return select(hdr0.c){
      0 : p_hdr1;
      1 : p_hdr2;
   }
}

parser p_hdr1 {
   extract(hdr1);
   return p_hdr2;
}

parser p_hdr2 {
   extract(hdr2);
   return ingress;
}

action do_nothing(){}


action action_0(p){
   modify_field(hdr0.b, p);
}
action action_1(p){
   add(hdr0.c, hdr0.b, p);  
}

table table_i0 {
    reads {
        hdr0.a : ternary;
    }
    actions {
        do_nothing;
        action_0;
    }
    size : 512;
}
table table_i1 {
    reads {

        hdr0.b : exact;
    }
    actions {
        do_nothing;
        action_1;
    }
    size : 1024;
}

control ingress {
  apply(table_i0);
  apply(table_i1);
}

control egress {
}
