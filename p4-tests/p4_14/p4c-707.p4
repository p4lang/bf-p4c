
header_type data_t {
    fields {
       r1 : 32;
       w1 : 32;
       w2 : 32;
    }
}

header data_t data;

parser start {
    extract(data);
    return ingress;
}

action setw1(param1, port) {
    modify_field(data.w1, param1);
    modify_field(standard_metadata.egress_spec, port);
}

action setw2(param1) {
    modify_field(data.w2, param1);
}

action noop() { }

@pragma stage 1
table i1 {
    reads {
        data.r1 : exact;
    }
    actions {
        setw1;
        noop;
    }
    default_action : noop();
}

@pragma stage 2
table e1 {
    reads {
        data.r1 : exact;
    }
    actions {
        setw2;
        noop;
    }
    default_action : noop();
}

control ingress {
    apply(i1);
}

control egress {
    apply(e1);
}
