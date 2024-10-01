header_type read_values_t {
    fields {
        f1 : 32;
    }
}

header_type write_values_t {
    fields {
        x1 : 12;
        y1 : 4;
        y2 : 4;
        x2 : 12;
        z1 : 2;
        x3 : 12;
        z2 : 2;
    }
}

header_type metadata_values_t {
    fields {
        m1 : 12;
    }
}

header read_values_t read_values;
header write_values_t write_values;
metadata metadata_values_t meta_values;

@pragma pa_container_size ingress write_values.x1 16
@pragma pa_container_size ingress write_values.x2 16
@pragma pa_container_size ingress write_values.x3 16

parser start {
    extract(read_values);
    extract(write_values);
    return ingress;
}


action noop() {
}


action set_test1(param, port) {
    modify_field(write_values.x1, param); 
    modify_field(write_values.x2, param);
    modify_field(standard_metadata.egress_spec, port);
}

action xor_test1(param, port) {
    bit_xor(meta_values.m1, write_values.x3, param);
    modify_field(write_values.x2, param);
    modify_field(standard_metadata.egress_spec, port);
}

action xor_result() {
    modify_field(write_values.x1, meta_values.m1);
}


table test1 {
    reads {
        read_values.f1 : exact;
    }
    actions {
        noop;
        set_test1;
        xor_test1;
    }
    default_action : noop;
}

table test1_result {
    reads {
       read_values.f1 : exact;
    }
    actions {
        xor_result;
        noop;
    }
    default_action : noop;
}

table test1_result2 {
    actions {
        xor_result;
    }
    default_action : xor_result;
}

control ingress {
    apply(test1) {
        xor_test1 { apply(test1_result2); }
    }
}

