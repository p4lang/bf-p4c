

header_type data_t {
    fields {
        b1 : 8;
        b2 : 8;
        b3 : 8;
        b4 : 8;
        b5 : 8;
        b6 : 8;
        b7 : 8;
        b8 : 8;
        b9 : 8;
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
        data.b1 : exact;
    }
    actions {
        noop;
    }

}

table test2 {
    reads {
        data.b2 : exact;
    }
    actions {
        noop;
    }

}

table test3 {
    reads {
        data.b3 : exact;
    }
    actions {
        noop;
    }
}


table test4 {
    reads {
        data.b4 : exact;
    }
    actions {
        noop;
    }
}

table test5 {
    reads {
        data.b5 : exact;
    }
    actions {
        noop;
    }

}

table test6 {
    reads {
        data.b6 : exact;
    }
    actions {
        noop;
    }

}

table test7 {
    reads {
        data.b7 : exact;
    }
    actions {
        noop;
    }
}

table test8 {
    reads { 
        data.b8 : exact;
        data.b9 : exact;
    }
    actions {
        noop;
    }
}

control ingress {
    apply (test1);
    apply (test2);
    apply (test3);
    apply (test4);
    apply (test5);
    apply (test6);
    apply (test7);
    apply (test8);
}
