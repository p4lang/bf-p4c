#include "tofino/stateful_alu_blackbox.p4"

header_type data_t {
    fields {
        f1 : 32;
        f2 : 32;
        f3 : 32;
        f4 : 32;
        h1 : 16;
        h2 : 16;
        h3 : 16;
        h4 : 16;
        b1 : 8;
        b2 : 8;
        b3 : 8;
        b4 : 8;
    }
}
header data_t data;

header_type pair32_t {
    fields {
        lo : 32;
        hi : 32;
    }
}

header_type meta_t {
    fields {
        tmp : 32;
    }
}
metadata meta_t meta;

parser start {
    extract(data);
    return ingress;
}

register accum {
    layout : pair32_t;
    instance_count : 65536;
}

blackbox stateful_alu sful {
    reg: accum;
    condition_lo: data.f2 > 1000;
    condition_hi: data.f2 < 2000;
    update_lo_1_predicate: condition_lo and condition_hi;
    update_lo_1_value: register_lo + data.f3;
    update_lo_2_predicate: not condition_lo and condition_hi;
    update_lo_2_value: register_lo - data.f3;
    update_hi_1_value: register_hi + 1;
    output_value: register_lo;
    output_dst: data.f4;
}

action noop() { }
action act1(port) {
    modify_field(standard_metadata.egress_spec, port);
    sful.execute_stateful_alu(data.h1 + 32w0);
}

table test1 {
    reads {
        data.f1 : exact;
    }
    actions {
        act1;
    }
}

control ingress {
    apply(test1);
}
