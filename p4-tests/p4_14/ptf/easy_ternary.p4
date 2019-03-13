#include "tofino/intrinsic_metadata.p4"

header_type h_t {
  fields {
    f1 : 16;
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
action nop() { }
action do(val, port) {
  modify_field(h.f2, val);
  modify_field(ig_intr_md_for_tm.ucast_egress_port, port);
}
table t {
    reads { h.f1 : lpm; }
    actions { nop; do; }
    default_action : nop();
}
control ingress { apply(t); }
