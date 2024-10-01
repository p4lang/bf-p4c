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
header_type meta_t {
    fields {
        x : 8;
    }
}
metadata meta_t meta;

parser start {
    extract(data);
    return ingress;
}

action savex() { modify_field(meta.x, data.b2); }
table savex { actions { savex; } default_action: savex; }

register accum {
    width : 16;
    instance_count : 131072;
}

blackbox stateful_alu sful1 {
    reg: accum;
    update_lo_1_value: register_lo + data.b1;
    output_value: register_lo;
    output_dst: data.h1;
}

blackbox stateful_alu sful2 {
    reg: accum;
    update_lo_1_value: register_lo - data.b1;
    output_value: register_lo;
    output_dst: data.h1;
}

action noop() { }
action addb1(port) {
    modify_field(standard_metadata.egress_spec, port);
    sful1.execute_stateful_alu(data.h2);
}
action subb1(port) {
    modify_field(standard_metadata.egress_spec, port);
    sful2.execute_stateful_alu(data.h2);
    modify_field(data.b2, meta.x);
}

@pragma stage 2
table test1 {
    reads {
        data.f1 : exact;
    }
    actions {
        noop;
        addb1;
    }
    default_action: noop;
}

@pragma stage 3
table test2 {
    reads {
        data.f1 : exact;
    }
    actions {
        subb1;
        noop;
    }
    default_action: noop;
}

control ingress {
    apply(savex);
    if (data.f1 & 1 == 1) {
        apply(test1);
    } else {
        apply(test2);
    }
}
