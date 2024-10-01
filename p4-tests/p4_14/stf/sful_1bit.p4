#include "tofino/stateful_alu_blackbox.p4"

header_type data_t {
    fields {
        f1 : 32;
        f2 : 32;
        b1 : 8;
        b2 : 8;
        pad : 4;
        bit1 : 1;
        bit2 : 1;
        bit3 : 1;
        bit4 : 1;
    }
}
header data_t data;

parser start {
    extract(data);
    return ingress;
}

register reg {
    width : 1;
    instance_count : 1000;
}

blackbox stateful_alu sful1 {
    reg: reg;
    update_lo_1_value: set_bit;
    output_value: register_lo;
    output_dst: data.bit1;
}
blackbox stateful_alu sful2 {
    reg: reg;
    update_lo_1_value: clr_bit;
    output_value: register_lo;
    output_dst: data.bit1;
}
blackbox stateful_alu sful3 {
    reg: reg;
    update_lo_1_value: read_bit;
    output_value: register_lo;
    output_dst: data.bit1;
}
blackbox stateful_alu sful4 {
    reg: reg;
    update_lo_1_value: read_bitc;
    output_value: register_lo;
    output_dst: data.bit1;
}

action noop() { }
action set() { sful1.execute_stateful_alu(1); }
action clr() { sful2.execute_stateful_alu(1); }
action read() { sful3.execute_stateful_alu(1); }
action readc() { sful4.execute_stateful_alu(1); }

table test1 {
    reads {
        data.b1 : exact;
    }
    actions {
        set; clr; read; readc; noop;
    }
    default_action : noop;
}

action output(port) {
    modify_field(standard_metadata.egress_spec, port);
}

table do_out {
    reads { data.f1 : exact; }
    actions { output; }
}

control ingress {
    apply(test1);
    apply(do_out);
}
