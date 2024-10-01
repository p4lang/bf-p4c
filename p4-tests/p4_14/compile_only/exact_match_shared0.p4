
header_type data_t {
    fields {
        f1 : 32;
        f2 : 32;
        f3 : 32;
        f4 : 32;
        b1 : 8;
        b2 : 8;
        b3 : 8;
        b4 : 8;
    }
}
header data_t data;

parser start {
    extract(data);
    return ingress;
}

action noop() { }

table test1 { 
    reads {
        data.f1  : exact;
        data.f2  : exact;
        data.b2  : exact;
        data.b3  : exact;
    }
    actions {
        noop;
    }
}

table test2 { 
    reads {
        data.f1 : exact;
        data.f3 : exact;
    }
    actions {
        noop;
    }
}

table test3 { 
    reads {
        data.f3 : exact;
        data.b1 : exact;
        data.b2 : exact;
        data.b4 : exact;
    }
    actions {
        noop;
    }
}

table test4 { 
    reads {
        data.f1 : exact;
        data.b2 : exact;
        data.b3 : exact;
    }
    actions {
        noop;
    }
}

control ingress {
    apply(test1);
    apply(test2);
    apply(test3);
    apply(test4);
}

control egress {

}
