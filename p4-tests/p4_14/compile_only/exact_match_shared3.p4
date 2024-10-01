header_type data_t {
    fields {
        f1 : 32;
        f2 : 32;
        f3 : 32;
        f4 : 32;
        f5 : 32;
        f6 : 32;
        f7 : 32;
        f8 : 32;
        f9 : 32;
        f10 : 32;
        f11 : 32;
        f12 : 32;    
        f13 : 32;
        f14 : 32;
        f15 : 32;
        f16 : 32;
    }
}

header data_t data;

parser start {
    extract(data);
    return ingress;
}

action noop () {}

table test1 {
    reads {
        data.f1 : exact;
        data.f2 : exact;
    } 
    actions {
        noop;
    }
}

table test2 { 
    reads {
        data.f3 : exact;
        data.f4 : exact;
        data.f5 : exact;
    }
    actions {
        noop;
    }
}

table test3 {
    reads {
        data.f6 : exact;
        data.f12 : exact;
        data.f13 : exact;
        data.f14 : exact;
    }
}

table test4 {
    reads {
        data.f6 : exact;
        data.f7 : exact;
        data.f8 : exact;
        data.f9 : exact;
        data.f10 : exact;
        data.f11 : exact;
    }
    actions {
        noop;
    }
}

table test5 {
    reads {
        data.f12 : exact;
        data.f13 : exact;
        data.f14 : exact;
        data.f7 : exact;
        data.f8 : exact;
    }
}

control ingress {
    apply(test1);
    apply(test2);
    apply(test3);
    apply(test4);
    apply(test5);
}

control egress {}
