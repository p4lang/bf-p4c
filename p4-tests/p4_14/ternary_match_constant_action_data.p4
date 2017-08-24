
#include "tofino/intrinsic_metadata.p4"

header_type h_t {
  fields {
    f1 : 16;
    f2 : 8;
    f3 : 8;
    n1 : 4;
    n2 : 4;
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
action nop() { }
action do() {
  modify_field(h.n1, 0xa);
  modify_field(ig_intr_md_for_tm.ucast_egress_port, 3);
}
table t {
    reads { h.f1 : lpm; }
    actions { nop; do; }
    default_action : nop();
}
control ingress { apply(t); }
