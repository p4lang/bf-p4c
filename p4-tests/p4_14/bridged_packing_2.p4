header_type pkt_t {
    fields {
        f1 : 2;
        f2 : 3;
        f3 : 3;
    }
}

header_type meta_t {
    fields {
        f1 : 2;
        f2 : 3;
        f3 : 3;
    }
}

header pkt_t pkt;
metadata meta_t meta1;
metadata meta_t meta2;

parser start {
    extract(pkt);
    return ingress;
}

action action_0(a, b, c) {
    modify_field(meta1.f1, pkt.f1);
    modify_field(meta1.f2, pkt.f2);
    modify_field(meta1.f3, pkt.f3);
    modify_field(meta2.f1, a);
    modify_field(meta2.f2, b);
    modify_field(meta2.f3, c);
}

action action_1(a, b, c) {
    modify_field(meta2.f1, pkt.f1);
    modify_field(meta2.f2, pkt.f2);
    modify_field(meta2.f3, pkt.f3);
    modify_field(meta1.f1, a);
    modify_field(meta1.f2, b);
    modify_field(meta1.f3, c);
}

table table_0 {
    reads {
        pkt.f1 : exact;
    }
    actions {
        action_0;
        action_1;
    }
    size : 1024;
}

action setport(port) {
    modify_field(standard_metadata.egress_spec, port);
}

table setting_port {
    reads {
        pkt.f1 : exact;
    }
    actions {
        setport;
    }
}

action action_2() {
    modify_field(pkt.f2, meta2.f2);
    modify_field(pkt.f1, 2);
    modify_field(pkt.f3, 6);
}

action action_3() {
    modify_field(pkt.f3, meta1.f3);
    modify_field(pkt.f2, 4);
    modify_field(pkt.f1, 1);
}

table table_1 {
    reads {
        pkt.f1 : exact;
    }
    actions {
        action_2;
        action_3;
    }
    size : 1024;
}

control ingress {
    apply(table_0);
    apply(setting_port);
}

control egress {
    apply(table_1);
}
