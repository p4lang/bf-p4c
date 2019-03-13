#include "tofino/intrinsic_metadata.p4"

#ifndef FP_PORT_1
#if __TARGET_TOFINO__ == 2
// Default ports for Tofino2 have offset 8
#define FP_PORT_1 9
#else
#define FP_PORT_1 1
#endif
#endif

header_type h_t {
  fields {
    f1 : 8;
    f2 : 8;
    f3 : 8;
  }
}

header h_t h;

parser start {
    return parse_h;
}

parser parse_h {
    extract(h);
    return ingress;
}

action do() {
  modify_field(h.f2, 5);
  modify_field(ig_intr_md_for_tm.ucast_egress_port, FP_PORT_1);
}

table t {
    actions { do; }
    default_action : do();
}

control ingress { 
    if (h.f1 == 0) 
        apply(t); 
}
