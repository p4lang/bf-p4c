header_type data_t {
    fields {
        f1 : 32;
        f2 : 32;
        f3 : 32;
        f4 : 32;
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

action noop() { }

action set_port_act(port) {
    modify_field(standard_metadata.egress_spec, port);
}

action a1() {
    modify_field(data.f1, data.f2);
}

action a2() {
    modify_field(data.b1, data.b2);
}

action a3(param) {
    modify_field(data.h1, param);
}

action a4(param1, param2) {
    modify_field(data.f3, param1);
    modify_field(data.f4, param2);
}

table t1 {
    actions { a1; a2; }
    default_action: a1();
}

table t2 {
    actions { a3; } 
    default_action: a3(0x6789);
}

table t3 {
    actions { a4; }
    default_action: a4(0x12345678, 0x76543210);
}

table set_port {
    reads { data.f1 : exact; }
    actions { set_port_act; noop; }
    default_action: noop;
}

control ingress {
    apply(t1);
    apply(t2);
    apply(t3);
    apply(set_port);
}


