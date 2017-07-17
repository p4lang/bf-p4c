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
        x : 16;
        y : 16;
        z : 16;
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

@pragma pa_container ingress meta.x 132
@pragma pa_container ingress meta.y 132
@pragma pa_container ingress meta.z 134
@pragma pa_no_init ingress meta.y
metadata meta_t meta;

action do_nothing(){}

action set_type(t, x){
   modify_field(ethernet.etherType, t);
   modify_field(meta.x, x);
}

action set_mac_da(d){
   modify_field(ethernet.dstAddr, d);
}

action set_y(){
   modify_field(meta.y, 2);
}

action set_z(){
   modify_field(meta.z, 3);
}

action set_port(p){
   modify_field(ig_intr_md_for_tm.ucast_egress_port, p);
   modify_field(ethernet.etherType, meta.z);
}


table t0 {
   reads {
      ethernet.etherType : ternary;
   }
   actions {
      set_type;
      do_nothing;
   }
   size : 512;
}

table t1 {
   reads {
      ethernet.etherType : ternary;
      meta.x : ternary;
   }
   actions {
      set_mac_da;
      do_nothing;
   }
   size : 512;
}

table t2 {
   reads {
      ethernet.dstAddr : ternary;
   }
   actions {
      set_mac_da;
      do_nothing;
   }
   size : 512;
}

table t_y {
   reads {
      ethernet.dstAddr : ternary;
   }
   actions {
      set_y;
      do_nothing;
   }
   size : 512;
}

table t_z {
   reads {
      ethernet.dstAddr : ternary;
   }
   actions {
      set_z;
      do_nothing;
   }
   size : 512;
}

table t_last {
   reads {
      meta.y : ternary;
      ethernet.dstAddr : ternary;
   }
   actions {
      set_port;
      do_nothing;
   }
   size : 512;
}

control ingress {
   apply(t0);
   apply(t1);
   apply(t2);
   if (valid(ethernet)){
       apply(t_y);
   } else {
       apply(t_z);
   }
   apply(t_last);
}