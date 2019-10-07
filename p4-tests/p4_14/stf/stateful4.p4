#include "tofino/stateful_alu_blackbox.p4"

header_type data_t {
    fields {
        f1 : 32;
        f2 : 32;
        h1 : 16;
        h2 : 16;
        b1 : 1;
        b2 : 1;
        b3 : 1;
        b4 : 1;
        pad : 4;
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
    output_predicate: condition_lo;
    output_value: combined_predicate;
    output_dst: data.b1;
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
