header_type data_t {
     fields {
         f1 : 32;
         f2 : 32;
         f3 : 32;
         f4 : 32;
         f5 : 32;
         f6 : 32;
         f7 : 32;
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

action noop() {}

table test1 {
    reads {
        data.f1 : ternary;
        data.f2 : ternary;
        data.f3 : ternary;
        data.f4 : ternary;
        data.f5 : ternary;
        data.f6 : ternary;
        data.f7 : ternary;
        data.b1 : ternary;
        data.b2 : ternary;
        data.b3 : ternary;
        data.b4 : ternary;
    }
    actions {
        noop;
    }
}

table test2 {
    reads {
        data.f1 : ternary;
    }
    actions {
        noop;
    }
}

table test3 {
    reads {
        data.f3 : ternary;
    }
    actions {
        noop;
    }
}

table test4 {
    reads {
        data.f1 : ternary;
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

control egress {}
