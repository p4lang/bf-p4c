#include "tofino/intrinsic_metadata.p4"

header_type data_t {
    fields {
        f1 : 32;
        f2 : 32;
        h1 : 16;
        h2 : 16 (signed);
        b1 : 8;
        b2 : 8 (signed);
    }
}
header data_t data;

parser start {
    extract(data);
    return ingress;
}

action act(port) {
    modify_field(ig_intr_md_for_tm.ucast_egress_port, port);
    add_to_field(data.h2, data.b2);
}

table test1 {
    reads {
        data.f1 : exact;
    }
    actions {
        act;
    }
}

control ingress {
    apply(test1);
}
