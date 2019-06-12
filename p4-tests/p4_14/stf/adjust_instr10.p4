/**
 * The purpose of this program is to test the rotational around the slot boundary for
 * action data.  This is more for deposit-fields where this slice is non-contiguous, but
 * wrapped contiguous
 */

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
        x2 : 4;
        x3 : 4;
        x4 : 4;
    }
}
header cc1_t cc1;
@pragma pa_container_size ingress cc1.x1 8
@pragma pa_container_size ingress cc1.x3 8


@pragma pa_container_size ingress cc2.y1 8
@pragma pa_container_size ingress cc2.y3 8
header_type cc2_t {
    fields {
        y1 : 2;
        y2 : 2;
        y3 : 2;
        y4 : 2;
        y5 : 2;
        y6 : 2;
        y7 : 2;
        y8 : 2;
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

action cc1_act(p1, p2) {
    modify_field(cc1.x1, p1);
    modify_field(cc1.x2, p2);
    modify_field(cc1.x3, p2);
    modify_field(cc1.x4, p1);
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

action cc2_act(p1, p2, p3, p4) {
    modify_field(cc2.y1, p1);
    modify_field(cc2.y2, p2);
    modify_field(cc2.y3, p3);
    modify_field(cc2.y4, p4);
    modify_field(cc2.y5, p4);
    modify_field(cc2.y6, p1);
    modify_field(cc2.y7, p2);
}

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
