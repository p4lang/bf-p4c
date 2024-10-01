#include "tofino/stateful_alu_blackbox.p4"

header_type data_t {
    fields {
        f1 : 32;
        f2 : 32;
        h1 : 16;
        b1 : 8;
        b2 : 8;
    }
}
header data_t data;

parser start {
    extract(data);
    return ingress;
}

register accum {
    width : 16;
    direct : test1;
}

blackbox stateful_alu sful {
    reg: accum;
    update_lo_1_value: register_lo + data.b1;
    output_value: register_lo;
    output_dst: data.h1;
}

action noop() { }
action addb1(port) {
    modify_field(standard_metadata.egress_spec, port);
    sful.execute_stateful_alu();
}

table test1 {
    reads {
        data.f1 : exact;
    }
    actions {
        addb1;
    }
}

control ingress {
    apply(test1);
}
