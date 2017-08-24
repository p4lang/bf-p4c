#include "tofino/intrinsic_metadata.p4"

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
  modify_field(ig_intr_md_for_tm.ucast_egress_port, 1);
}

table t {
    actions { do; }
    default_action : do();
}

control ingress { apply(t); }
