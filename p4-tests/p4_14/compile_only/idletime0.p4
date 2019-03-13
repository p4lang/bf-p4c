#include "tofino/intrinsic_metadata.p4"

header_type data_t {
    fields {
        f1 : 32;
        f2 : 32;
        f3 : 32;
        f4 : 32;
        b1 : 8;
        b2 : 8;
        b3 : 8;
        b4 : 8;
    }
}
header data_t data;

parser start {
    extract(data);
    return ingress;
}

action noop() { }

@pragma idletime_precision 3
@pragma idletime_two_way_notification 1
@pragma idletime_per_flow_idletime 1
table test1 {
    reads {
        data.f1 : exact;
    }
    actions {
        noop;
    }
    support_timeout: true;
}

control ingress {
    apply(test1);
}
