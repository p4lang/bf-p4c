header_type init_t {
    fields {
        read : 32;
        class : 8;
    }
}

header init_t init;

header_type cc1_t {
    fields {
        x1 : 4;
        y1 : 2;
        z1 : 2;
        x2 : 4;
        y2 : 2;
        z2 : 2;
    }
}
header cc1_t cc1;
@pragma pa_container_size ingress cc1.x1 8

/*
header_type cc2_t {
    fields {
        u1 : 3;
        v1 : 3;
        w1 : 2;
        u2 : 3;
        v2 : 2;
        w2 : 3;
    }
}
header cc2_t cc2;
@pragma pa_container_size ingress cc2.x1 8
@pragma pa_container_size ingress cc2.x2 8
*/

header_type cc2_t {
    fields {
        u1 : 4;
        v1 : 4;
        u2 : 4;
        v2 : 4;
    }
}
header cc2_t cc2;

parser start {
    extract(init);
    return select(init.class) {
        0x1 : parse_cc1;
        0x2 : parse_cc2;
        default : ingress;
    }
}

parser parse_cc1 {
    extract(cc1);
    return ingress;
}

parser parse_cc2 {
    extract(cc2);
    return ingress;
}

action noop() {
}

action cc1_act() {
    modify_field(cc1.x1, cc1.x2);
    modify_field(cc1.z1, cc1.z2);
}

table cc1_table {
    reads {
        init.read : exact;
    }
    actions {
        noop;
        cc1_act;
    }
    default_action : noop;
}

action cc2_act() {
    modify_field(cc2.u1, cc2.v2);
    modify_field(cc2.v1, cc2.u2);
}

/*
action cc2_act() {
    modify_field(cc2.u1, cc2.w2);
    modify_field(cc2.v1, cc2.u2);
}
*/

table cc2_table {
    reads {
        init.read : exact;
    }
    actions {
        noop;
        cc2_act;
    }
    default_action : noop;
}

action port_action(port) {
    modify_field(standard_metadata.egress_spec, port);
}

table port_table {
    reads {
        init.read : ternary;
    }
    actions {
        noop;
        port_action;
    }
    default_action : noop;
}

control ingress {
    if (valid(cc1)) {
        apply(cc1_table);
    }
    if (valid(cc2)) {
        apply(cc2_table);
    }
    apply(port_table);
}
