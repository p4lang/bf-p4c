@pragma command_line --disable-init-metadata

header_type wred_metadata_t {
    fields {
        index : 8;
    }
}

header_type data_t {
    fields {
        foo : 32;
    }
}

metadata wred_metadata_t wred_metadata;
header data_t data;

parser start {
    extract(data);
    return ingress;
}

action noop() { }

action set_port() {
    standard_metadata.egress_spec = 0x2;
}

table test1 {
    reads {
        data.foo : exact;
    }
    actions {
        set_port;
        noop;
    }
    default_action : noop;
}

action set_index() {
    modify_field(wred_metadata.index, 0x1);
}

table test2 {
    reads {
        data.foo : exact;
    }
    actions {
        set_index;
    }
}

action rewrite_data() {
    modify_field(data.foo, 0x03030303);
}

table test3 {
    reads {
        wred_metadata.index : exact;
        data.foo : ternary;
    }

    actions {
        rewrite_data;
        noop;
    }
    default_action : noop;
    size : 1024;
}

control ingress {
    apply(test1);
//    apply(test2);
//    apply(test3);
}

control egress {
    apply(test2);
    apply(test3);
}
