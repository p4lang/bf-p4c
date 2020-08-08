#include "tofino/intrinsic_metadata.p4"

header_type h1_t {
    fields {
        f1 : 56;
    }
}
header h1_t h1;

header_type h2_t {
    fields {
        f2 : 64;
    }
}
header h2_t h2;

header_type h3_t {
    fields {
        f3 : 8;
    }
}
header h3_t h3;

parser start {
    extract(h1);
    extract(h2);
    extract(h3);
    return ingress;
}

action noop() { }

table test1 {
    reads {
        h3.f3 : exact;
    }
    actions {
        noop;
    }
}

control ingress {
    apply(test1);
}