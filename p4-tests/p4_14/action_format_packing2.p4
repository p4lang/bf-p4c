header_type read_values_t {
    fields {
         f1 : 32;
    }
}

header_type write_values_t {
    fields {
        u1 : 4;
        v1 : 2;
        u2 : 4;
        v2 : 2;
        u3 : 4;

        w1 : 4;
        x1 : 2;
        w2 : 4;
        x2 : 2;
        w3 : 4;

        y1 : 4;
        z1 : 8;
        y2 : 4;
    }
}

header read_values_t read_values;
header write_values_t write_values;

@pragma pa_container_size ingress write_values.u1 16
@pragma pa_container_size ingress write_values.w1 16
@pragma pa_container_size ingress write_values.y1 16

parser start {
    extract(read_values);
    extract(write_values);
    return ingress;
}

action noop() { } 

action port_set(port) {
    modify_field(standard_metadata.egress_spec, port);
}

action bm_set1(param1, param2, param3) {
    modify_field(write_values.u1, param1);
    modify_field(write_values.u2, param2);
    modify_field(write_values.u3, param3);

    modify_field(write_values.w1, param1);
    modify_field(write_values.y1, param1);
}

action bm_set2(param1, param2, param3) {
    modify_field(write_values.u1, param1);
    modify_field(write_values.u2, param2);
    modify_field(write_values.u3, param3);

    modify_field(write_values.w2, param1);
    modify_field(write_values.y2, param1);
}

action bm_set3(param1, param2, param3) {
    modify_field(write_values.u1, param1);
    modify_field(write_values.u2, param2);
    modify_field(write_values.u3, param3);

    // BMV2 ERROR:
    // modify_field(write_values.w1, param1)

    modify_field(write_values.w1, param2);
    modify_field(write_values.w3, param3);
}

action bm_set4(param1, param2, param3) {
    modify_field(write_values.u1, param1);
    modify_field(write_values.u2, param2);
    modify_field(write_values.u3, param3);

    modify_field(write_values.w1, param1);
    modify_field(write_values.w2, param2);
    modify_field(write_values.w3, param3);
}

action bm_set5(param1, param2, param3) {
    modify_field(write_values.u1, param1);
    modify_field(write_values.u2, param2);
    modify_field(write_values.u3, param3);

    modify_field(write_values.w1, param3);
    modify_field(write_values.w2, param2);
    modify_field(write_values.w3, param1);
}

action bm_set6(param1, param2, param3) {
    modify_field(write_values.u1, param1);
    modify_field(write_values.u2, param2);
    modify_field(write_values.u3, param3);

    modify_field(write_values.w1, param1);
    modify_field(write_values.w2, param2);
    modify_field(write_values.w3, param3);

    modify_field(write_values.y1, param3);
}

action bm_set7(param1, param2, param3) {
    modify_field(write_values.u1, param1);
    modify_field(write_values.u2, param2);
    modify_field(write_values.u3, param3);

    modify_field(write_values.w1, param1);
    modify_field(write_values.w2, param2);
    modify_field(write_values.w3, param3);

    modify_field(write_values.y1, param1);
    modify_field(write_values.y2, param3);
}

table set_port {
    reads {
        read_values.f1 : ternary;
    }
    actions {
        noop;
        port_set;
    }
    default_action : noop;
}

table test1 {
    reads {
        read_values.f1 : exact;
    }
    actions {
        noop;
        bm_set1;
        bm_set2;
        bm_set3;
        bm_set4;
        bm_set5;
        bm_set6;
        bm_set7;
    }
    default_action : noop;
}

control ingress {
    apply(set_port);
    apply(test1);
}
