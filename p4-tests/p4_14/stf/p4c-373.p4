header_type data_t {
    fields {
        key : 32;
        f1 : 2;
        f2 : 2;
        f3 : 2;
        f4 : 2;
        f5 : 2;
        f6 : 2;
        f7 : 2;
        f8 : 2;
        f9 : 2;
        fa : 2;
        fb : 2;
        fc : 2;
    }
}

header data_t data;

parser start {
    extract(data);
    return ingress;
}

action a1(port) {
    modify_field(data.f1, data.f5);
    modify_field(data.f2, data.fa);
    modify_field(data.f3, data.f7);
    modify_field(data.f4, data.f8);
    modify_field(standard_metadata.egress_spec, port);
}

table test {
    reads {
        data.key : exact;
    }
    actions {
        a1;
    }
}

control ingress {
    apply(test);
}
