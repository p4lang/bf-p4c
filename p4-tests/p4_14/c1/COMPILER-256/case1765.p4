#include <tofino/intrinsic_metadata.p4>

header_type ethernet_t {
    fields {
        dstAddr     : 48;
        srcAddr     : 48;
        ethertype   : 16;
    }
}

header ethernet_t ethernet;

parser start {
    extract(ethernet);
    return ingress;
}

header_type m_t {
    fields {
        f1 : 8;
        f2 : 8;
    }
}

metadata m_t m;

action a1(r1) {
    modify_field(m.f1, r1);
}

table t1 {
    reads {
        ethernet.dstAddr : exact;
    }
    actions {
        a1;
    }
}

action a2() {
    modify_field(m.f2, m.f1);
}

table t2 {
    reads {
        ethernet.srcAddr : exact;
    }
    actions {
        a2;
    }
}

action do_forward(port) {
    modify_field(ig_intr_md_for_tm.ucast_egress_port, port);
}

table forward {
    reads {
        m.f1 : ternary;
        m.f2 : ternary;
    }
    actions {
        do_forward;
    }
}

control ingress {
    apply(t1);
    apply(t2);
    apply(forward);
}

control egress {
}
