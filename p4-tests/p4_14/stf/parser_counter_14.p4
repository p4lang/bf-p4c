#include <tofino/intrinsic_metadata.p4>

header_type data_t {
    fields {
        f : 8;
        n : 8;
    }
}

header data_t a;
header data_t b;
header data_t c;

parser start {
    extract(a);
    set_metadata(ig_prsr_ctrl.parser_counter, 0x4);
    return select(a.n) {
        0xb : parse_b;
        default : ingress;
    }
}

parser parse_b {
    extract(b);
    set_metadata(ig_prsr_ctrl.parser_counter, ig_prsr_ctrl.parser_counter - 10);
    return select(b.n) {
        0xc : parse_c;
        default : ingress;
    }
}

parser parse_c {
    extract(c);
    return select(ig_prsr_ctrl.parser_counter) {
        255 : parse_port;    // this should translate to "is_negative()" in P4-16
        default : ingress;
    }
}

parser parse_port {
    set_metadata(standard_metadata.egress_spec, 0x2);
    return ingress;
}

control ingress { }
