#include "tofino/stateful_alu_blackbox.p4"

header_type data_t {
    fields {
        f1 : 32;
        f2 : 32;
        h1 : 16;
        h2 : 16;
        b1 : 8;
        b2 : 8;
    }
}
header data_t data;

parser start {
    extract(data);
    return ingress;
}

register accum1 {
    width : 16;
    direct : test1;
}

register accum2 {
    width : 16;
    direct : test2;
}

blackbox stateful_alu sful_lo {
    reg: accum1;
    initial_register_lo_value: 5;
    update_lo_1_value: register_lo + 1;
    output_value: register_lo;
    output_dst: data.h1;
}

blackbox stateful_alu sful_hi {
    reg: accum2;
    initial_register_hi_value: 1;
    update_hi_1_value: register_hi + 2;
    output_value: register_hi;
    output_dst: data.h2;
}

action noop() { }
action addb1(port) {
    modify_field(standard_metadata.egress_spec, port);
    sful_lo.execute_stateful_alu();
}

action addb2() {
    sful_hi.execute_stateful_alu();
}

table test1 {
    reads {
        data.f1 : exact;
    }
    actions {
        addb1;
    }
}

table test2 {
    reads {
        data.f2 : exact;
    }
    actions {
        addb2;
    }
}

control ingress {
    apply(test1);
    apply(test2);
}
