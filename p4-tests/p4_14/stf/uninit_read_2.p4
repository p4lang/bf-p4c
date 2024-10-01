#ifdef __TARGET_TOFINO__
#include <tofino/constants.p4>
#include <tofino/intrinsic_metadata.p4>
#include <tofino/primitives.p4>
#else
#include "includes/tofino.p4"
#endif

header_type ethernet_t {
    fields {
        dstAddr   : 48;
        srcAddr   : 48;
        ethertype : 16;
    }
}

header ethernet_t ethernet;

header_type metadata_t {
    fields {
        port : 9; } }

metadata metadata_t md;

parser start {
    extract(ethernet);
    return ingress;
}

action upd(p) {
    modify_field(md.port, p);
}

action fwd() {
    modify_field(standard_metadata.egress_spec, md.port);
}

table update {
    reads { ethernet.ethertype : exact; }
    actions { upd; }
    default_action : upd(3);
    size : 128;
}

table forward {
    reads { ethernet.ethertype : exact; }
    actions { fwd; }
    default_action : fwd;
    size : 128;
}

control ingress {
    if (valid(ethernet)) {
        apply(update);
    }
    apply(forward);
}

control egress {
}
