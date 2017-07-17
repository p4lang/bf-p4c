#include "tofino/intrinsic_metadata.p4"

/* Sample P4 program */
header_type hdr1_t {
    fields {
        a_4 : 4;
        b_8 : 8;
        c_8 : 8;
        d_12 : 12;
    }
}

header_type hdr2_t {
    fields {
        a_32 : 32;
        b_32 : 32;
    }
}

header_type meta_t {
    fields {
        x_8 : 8;
    }
}


parser start {
    return parse_pkt;
}


parser parse_pkt {
    extract(hdr1);
    return parse_pkt2;
}

parser parse_pkt2 {
    extract(hdr2);
    set_metadata(meta.x_8, 1);
    return ingress;
}

header hdr1_t hdr1;
header hdr2_t hdr2;
metadata meta_t meta;


action do_nothing(){}
action a0(){ modify_field(hdr1.b_8, meta.x_8); }

table t0 {
    reads { meta.x_8 : ternary; hdr1.d_12 : exact; }
    actions {
         a0;
         do_nothing;
    }
    size : 256;
}

control ingress {
    apply(t0);
}

control egress { }