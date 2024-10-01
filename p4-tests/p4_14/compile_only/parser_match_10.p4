#ifdef __TARGET_TOFINO__
#include <tofino/constants.p4>
#include <tofino/intrinsic_metadata.p4>
#include <tofino/primitives.p4>
#include <tofino/pktgen_headers.p4>
#endif

header_type ethernet_t { fields { ethernet: 96; } }
header ethernet_t ethernet;

parser start {
    return select(ig_intr_md.ingress_port) {
        0x0000 mask 0x0001 : parse_ethernet;
        default : ingress;
    }
}

parser parse_ethernet {
    extract(ethernet);
    return ingress;
}

control ingress { }
