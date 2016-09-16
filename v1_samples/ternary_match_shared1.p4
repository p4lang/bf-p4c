header_type data_t {
    fields {
        b1 : 8;
        b2 : 8;
        b3 : 8;
        b4 : 8;
        b5 : 8;
        b7 : 80;
    }
}
header data_t data;

parser start {
    extract(data);
    return ingress;
}

action noop() {}

table test1 {
    reads {
        data.b1 : ternary;
        data.b2 : ternary;
    }
    actions {
        noop;
    }
}

table test2 {
    reads {
        data.b3 : ternary;
        data.b4 : ternary;
        data.b5 : ternary;
    }
    actions {
        noop;
    }
}

table test3 {
    reads {
        data.b1 : ternary;
        data.b2 : ternary;
        data.b3 : ternary;
        data.b4 : ternary;
        data.b7 : ternary;
    }
    actions {
        noop;
    }
}

control ingress {
    apply(test1);
    apply(test2);
    apply(test3);
}
