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

// Should always forward to port 0
action fwd() {
    modify_field(standard_metadata.egress_spec, md.port);
}

table forward {
    reads { ethernet.ethertype : exact; }
    actions { fwd; }
    default_action : fwd;
    size : 128;
}

control ingress {
    apply(forward);
}

control egress {
}
