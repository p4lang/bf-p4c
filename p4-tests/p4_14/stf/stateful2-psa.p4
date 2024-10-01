header_type data_t {
    fields {
        f1 : 32;
        f2 : 32;
        h1 : 16;
        b1 : 8;
        b2 : 8;
    }
}
header data_t data;

parser start {
    extract(data);
    return ingress;
}

register accum {
    width : 16;
    instance_count : 1024;
}

action noop() { }

action addb1(port, idx) {
    modify_field(standard_metadata.egress_spec, port);
    register_read(data.h1, accum, idx);
    register_write(accum, idx, data.b1 + 1);
}

table test1 {
    reads {
        data.f1 : exact;
    }
    actions {
        addb1;
    }
}

control ingress {
    apply(test1);
}
