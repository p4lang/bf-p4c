
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
        
        w1 : 16;
        w2 : 16;
        w3 : 16;
        w4 : 16;
        w5 : 16;
        w6 : 16;
        w7 : 16;
        w8 : 16;

        b1 : 8;
        b2 : 8;
        b3 : 8;
        b4 : 8;
        b5 : 8;
        b6 : 8;
        b7 : 8;
        b8 : 8;
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
        data.w1 : exact;
        data.w2 : exact;
    }
    actions {
        noop;
    }
}

table test2 {
    reads {
        data.f3 : exact;
        data.f4 : exact;
        data.w3 : exact;
        data.b1 : exact;
    }
    actions {
        noop;
    }
}

table test3 {
    reads {
        data.f5 : exact;
        data.w4 : exact;
        data.w5 : exact;
        data.b2 : exact;
        data.b3 : exact;
        
    }
    actions {
        noop; 
    }
}

table test4 {
    reads {
        data.f6 : exact;
        data.f7 : exact;
    }
    actions {
        noop;
    }
}

table test5 {
    reads {
        data.w6 : exact;
        data.w7 : exact;
        data.b6 : exact;
    }
    actions {
        noop;
    }
}

table test6 {
    reads {
        data.w8 : exact;
        data.b7 : exact;
    }
    actions {
        noop;
    }
}

table test7 {
    reads {
        data.f8 : exact;
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
    apply(test5);
    apply(test6);
    apply(test7);
}

