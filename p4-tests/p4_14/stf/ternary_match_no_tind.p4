header_type data_t {
    fields {
        f1 : 32;
        f2 : 32;
        b1 : 8;
    }
}

header data_t data;

parser start {
    extract(data);
    return ingress;
}


action setb1() {
    modify_field(data.b1, 7);
}

action noop() {}

action set_port(port) {
    modify_field(standard_metadata.egress_spec, port);
}

table test1 {
    reads {
        data.f1 : ternary;
        data.f2 : ternary;
    }
    actions {
        setb1;
    }
    default_action : noop;
    size : 1024;
}


table test2 {
    reads {
        data.f1 : ternary;
    }
    actions {
        set_port;
    }
}

control ingress {
    apply(test1);
    apply(test2);
}
