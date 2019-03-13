#include "tofino/stateful_alu_blackbox.p4"

header_type data_t {
    fields {
        f1 : 32;
        f2 : 32;
        f3 : 32;
        f4 : 32;
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

field_list sel_fields {
    data.f1;
    data.f2;
    data.f3;
    data.f4;
}

field_list_calculation sel_hash {
    input {
        sel_fields;
    }
    algorithm : crc16;
    output_width : 16;
}

action_selector sel {
    selection_key : sel_hash;
    selection_mode : fair;
}

action set_output(port) { modify_field(standard_metadata.egress_spec, port); }

action_profile sel_profile {
    actions {
        set_output;
    }
    size : 1024;
    dynamic_action_selection : sel;
}

table select_output {
    reads {
        data.b1 : exact;
    }
    action_profile : sel_profile;
    size : 1024;
}

blackbox stateful_alu port_up {
    selector_binding: select_output;
    update_lo_1_value: clr_bit;
}
blackbox stateful_alu port_down {
    selector_binding: select_output;
    update_lo_1_value: set_bit;
}

action set_port_up() {
    port_up.execute_stateful_alu(data.b4);
    modify_field(standard_metadata.egress_spec, 0);
}

action set_port_down() {
    port_down.execute_stateful_alu(data.b4);
    modify_field(standard_metadata.egress_spec, 0);
}

table update_output {
    reads {
        data.b3 : exact;
    }
    actions { set_port_up; set_port_down; }
    size : 1024;
}

control ingress {
    if (data.b2 == 1) {
        apply(update_output);
    } else {
        apply(select_output);
    }
}
