/** This checks the corner case of a 5 wide TCAM match sharing their midbyte correctly, raised
 *  in BRIG-451
 */

header_type data_t {
    fields {
        f1 : 32;
        f2 : 32;
        f3 : 32;
        f4 : 32;
        f5 : 32;
        f6 : 32;
        b1 : 8;
    }
}

header data_t data;

parser start {
    extract(data);
    return ingress;
}

action noop() { }

action setb1(val, port) {
    data.b1 = val;
    standard_metadata.egress_spec = port;
}

table test1 {
    reads {
        data.f1 : ternary;
        data.f2 : ternary;
        data.f3 : ternary;
        data.f4 : ternary;
        data.f5 : ternary;
        data.f6 : ternary;
    }
    actions {
        setb1;
        noop;
    }
    default_action : noop;
    size : 1024;
}

control ingress {
    apply(test1);
}
