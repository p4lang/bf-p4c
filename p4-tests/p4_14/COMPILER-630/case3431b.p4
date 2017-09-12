#include <tofino/intrinsic_metadata.p4>

header_type ethernet_t {
    fields {
        dstAddr    : 48;
        srcAddr    : 48;
        etherType  : 16;
    }
}

header_type ipv4_t {
    fields {
        version : 4;
        ihl : 4;
        diffserv : 8;
        totalLen : 16;
        identification : 16;
        flags : 3;
        fragOffset : 13;
        ttl : 8;
        protocol : 8;
        hdrChecksum : 16;
        srcAddr : 32;
        dstAddr: 32;
    }
}

header ethernet_t ethernet;
header ipv4_t     ipv4;

header_type m_t {
    fields {
        f : 20;
    }
}

metadata m_t m;

parser start {
    extract(ethernet);
    return select(ethernet.etherType) {
        0x0800 : parse_ipv4;
        default: ingress;
    }
}

parser parse_ipv4 {
    extract(ipv4);
    set_metadata(m.f, 0x12345);
    return ingress;
}

action do_stuff(p) {
    bit_or(ipv4.srcAddr, m.f, p);
    modify_field(ig_intr_md_for_tm.ucast_egress_port, ig_intr_md.ingress_port);
}

table t {
    actions {
        do_stuff;
    }
    default_action: do_stuff;
}

control ingress {
    if (valid(ipv4)) {
        apply(t);
    }
}
