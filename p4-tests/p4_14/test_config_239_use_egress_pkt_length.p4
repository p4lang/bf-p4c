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


action action_0(py, pz) {
   modify_field(meta.x, 1);  
   modify_field(meta.y, py);
   modify_field(meta.z, pz);    
}

action action_1(){
   add(hdr2.a, hdr2.a, eg_intr_md.pkt_length);
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

table table_e0 {
    reads {
        hdr1.b : exact;
        meta.x : ternary;
        meta.y : exact;
        meta.z : exact;
    }
    actions {
        do_nothing;
        action_1;
    }
    size : 512;
}

control ingress {
  apply(table_i0);
}

control egress {
  apply(table_e0);
}
