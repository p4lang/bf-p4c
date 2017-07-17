#include "tofino/intrinsic_metadata.p4"

header_type pkt_t {
    fields {
        a : 16;
        b : 16;
        c : 16;
        d : 16;
    }
}

@pragma pa_container_size ingress pkt.c 16
@pragma pa_solitary ingress pkt.c
header pkt_t pkt;

parser start { return s0; }
parser s0{
    extract(pkt);
    return ingress;
}

field_list field_list_1 {
    pkt.a;
}

field_list_calculation hash_1 {
   input {
       field_list_1;
   }
   algorithm : identity;
   output_width : 16;
}

field_list field_list_2 {
    pkt.b;
}

field_list_calculation hash_2 {
   input {
       field_list_2;
   }
   algorithm : identity;
   output_width : 16;
}

action do_nothing(){}
action a0(){
   modify_field_with_hash_based_offset(pkt.c, 0, hash_1, 65536);
}
action a1(){
   modify_field_with_hash_based_offset(pkt.d, 0, hash_2, 65536);
}

action set_p() { 
    modify_field(ig_intr_md_for_tm.ucast_egress_port, 1); 
}

table t1 {
   reads {
      pkt.a : ternary;
   }
   actions {
      a0;
      a1;
   }
}

table t2 {
   actions {
      set_p;
   }
}

control ingress {
    apply(t1);
    apply(t2);
}