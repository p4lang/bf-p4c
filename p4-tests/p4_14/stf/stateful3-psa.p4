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

    // Constant propogation of data.b1
    // Occurs when Constant Folding & Copy Propogation are run before
    // before RegisterReadWrite pass in midend
    data.b1 = 1 + 4;
    register_write(accum, idx, data.b1);
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
