#ifdef __TARGET_TOFINO__
#include <tofino/constants.p4>
#include <tofino/intrinsic_metadata.p4>
#include <tofino/primitives.p4>
#else
#include "includes/tofino.p4"
#endif

header_type data_t {
    fields {
        m : 16;
        k : 16;
        p : 7;
        f : 9;
    }
}

header data_t data;

parser start {
    extract(data);
    return ingress;
}

action a1() {
    modify_field(ig_intr_md_for_tm.ucast_egress_port, data.f);
}

action a2() {
    modify_field(data.f, ig_intr_md_for_tm.ucast_egress_port);
}

action a3() {
    modify_field(data.f, ig_intr_md_for_tm.ucast_egress_port);
    modify_field(ig_intr_md_for_tm.ucast_egress_port, 0x2);
}

table t1 {
    reads {
        data.m : exact;
    }
    actions {
        a1;
    }
}

table t2 {
    reads {
        data.k : exact;
    }
    actions {
        a2;
    }
}

table t3 {
    reads {
        data.k : exact;
    }
    actions {
        a3;
    }
}

control ingress {
    apply(t1);
}

control egress {
    apply(t2);
    apply(t3);
}
