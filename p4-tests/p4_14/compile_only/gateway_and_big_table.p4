header_type data_t {
    fields {
        f1 : 32;
        b1 : 8;
        b2 : 8;
    }
}

header data_t data;

parser start {
    extract(data);
    return ingress;
}

action setb1(val1) {
    modify_field(data.b1, val1);
}

table test1 {
    reads {
        data.f1 : exact;
    }
    actions {
        setb1;
    }
    size : 300000;
}

control ingress {
    if (data.b2 == 1) {
        apply(test1);
    }
}
