header_type data_t {
    fields {
        f0 : 32;
        f1 : 8;
        f2 : 8;
        pad1: 7;
        f3 : 1;
        pad2 : 7;
        f4 : 1;
    }
}

header data_t data;

parser start {
    extract(data);
    return ingress;
}

action noop() { }

action and_action() {
    bit_and(data.f4, data.f3, data.f4);
    bit_and(data.pad2, data.pad1, data.pad2);
}

table and_action {
    reads {
        data.f1 : exact;
    }
    actions {
        and_action;
        noop;
    }
}

control ingress { }

control egress {
    apply(and_action);
}
