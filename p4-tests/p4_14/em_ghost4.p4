/** The purpose of this test case is to ghost an entire input xbar group so that a potential
 *  two input xbar table only takes one wide match on SRAM
 */
header_type data_t {
    fields {
        f1 : 32;
        f2 : 32;
        f3 : 32;
        x1 : 24;
        n1 : 4;
        n2 : 4;
        n3 : 4;
        n4 : 4;
        f5 : 32;
    }
}

header data_t data;
parser start {
    extract(data);
    return ingress;
}

action noop() { }
action setf5(val, port) {
    modify_field(data.f5, val);
    modify_field(standard_metadata.egress_spec, port);
}

table test1 {
    reads {
        data.f1 : exact;
        data.f2 : exact;
        data.f3 : exact;
        data.x1 : exact;
        data.n1 : exact;
        data.n3 : exact;
    }
    actions {
        setf5;
        noop;
    }
    default_action : noop;
}

control ingress {
    apply(test1);
}
