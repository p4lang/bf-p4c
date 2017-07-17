#include "tofino/intrinsic_metadata.p4"

header_type pkt_t {
    fields {
        a : 16;
        b : 16;
        c : 16;
        d : 16;
    }
}

@pragma pa_container_size ingress pkt.a 16
@pragma pa_container_size ingress pkt.c 16
header pkt_t pkt;

parser start { return s0; }
parser s0{
    extract(pkt);
    return ingress;
}

action do_nothing(){}
action set_p(a){
   modify_field(pkt.a, a);
   modify_field(pkt.c, 0x5c, 0xfc);
}

@pragma immediate 0
table t1 {
   reads {
      pkt.b : ternary;
   }
   actions {
      do_nothing;
      set_p;
   }
}

control ingress {
    apply(t1);
}