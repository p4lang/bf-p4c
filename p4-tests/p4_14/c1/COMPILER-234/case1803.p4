#include <tofino/intrinsic_metadata.p4>

header_type ethernet_t {
    fields {
        dstAddr : 48;
        srcAddr : 48;
        ethertype : 16;
    }
}

header ethernet_t ethernet;

parser start {
    extract(ethernet);
    return ingress;
}

action a() { }
table t {
    actions { a; }
}

control ingress {
    apply(t);
}
