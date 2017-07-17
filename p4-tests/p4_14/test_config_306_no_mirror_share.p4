#include "tofino/intrinsic_metadata.p4"

header_type ethernet_t {
    fields {
        dstAddr : 48;
        srcAddr : 48;
        etherType : 16;
    }
}

header_type meta_t {
    fields {
        x : 4;
        y : 4;
        z : 8;
    }
}

parser start {
    return parse_ethernet;
}

parser parse_ethernet {
    extract(ethernet);
    return ingress;
}

header ethernet_t ethernet;

@pragma pa_do_not_share_with_mirrored egress meta.x
metadata meta_t meta;

action do_nothing(){}

action set_meta(x, y, z){
   modify_field(meta.x, x);
   modify_field(meta.y, y);
   modify_field(meta.z, z);
}

action set_port(p){
   modify_field(ig_intr_md_for_tm.ucast_egress_port, p);
}

field_list e2e_0 { meta.y; }

action do_mirror(p){
   clone_egress_pkt_to_egress(0, e2e_0);
   modify_field(ig_intr_md_for_tm.ucast_egress_port, p);
}


table i_t0 {
   reads {
      ethernet.etherType : ternary;
   }
   actions {
      set_meta;
      do_nothing;
   }
   size : 512;
}

table e_t0 {
  reads {
     meta.x : exact;
     meta.y : exact;
     meta.z : exact;
     ethernet.etherType : ternary;
  }
  actions {
     do_mirror;
  }
}     

table e_mt1 {
  reads {
     meta.x : exact;
     meta.y : exact;
     ethernet.etherType : ternary;
  }
  actions {
     set_port;
  }
}  


control ingress {
   apply(i_t0);
}

control egress {
   if (eg_intr_md_from_parser_aux.clone_src == 0){
       apply(e_t0);
   } else {
       apply(e_mt1);
   }
}