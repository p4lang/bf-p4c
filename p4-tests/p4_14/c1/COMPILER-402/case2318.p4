#include <tofino/intrinsic_metadata.p4>

header_type ethernet_t {
    fields {
        dstAddr    : 48;
        srcAddr    : 48;
        ethertype  : 16;
    }
}

header ethernet_t ethernet;

header_type m_t {
    fields {
        f : 12;
    }
}

metadata m_t m;

parser start {
    extract(ethernet);
    set_metadata(m.f, 64);
    return ingress;
}

action do_stuff() {
    add(ethernet.ethertype, m.f, 4096);
    modify_field(ig_intr_md_for_tm.ucast_egress_port, ig_intr_md.ingress_port);
}

table t {
    actions {
        do_stuff;
    }
    default_action: do_stuff();
}

control ingress {
    apply(t);
}
