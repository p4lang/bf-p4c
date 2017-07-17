#include <tofino/intrinsic_metadata.p4>

header_type hdr_t {
    fields { f32: 32; }
}

header hdr_t hdr1;
header hdr_t hdr2;

parser start {
    return select(current(0, 32)) {
        0 : parse_hdr1;
        default : parse_hdr2;
    }
}

parser parse_hdr1 {
    extract(hdr1);
    return parse_hdr2;
}

parser parse_hdr2 {
    extract(hdr2);
    return ingress;
}

action set_port(port) {
    modify_field(ig_intr_md_for_tm.ucast_egress_port, port);
}

table t1 {
    actions { set_port; }
}

control ingress {
    apply(t1);
}
