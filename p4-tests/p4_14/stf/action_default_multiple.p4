header_type data_t {
    fields {
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

action b1_act(b1) {
    data.b1 = b1;
}

action b2_act(b2) {
    data.b2 = b2;
}

action b3_act(b3) {
    data.b3 = b3;
}

action b4_act(b4) {
    data.b4 = b4;
}

action set_port(port) {
    standard_metadata.egress_spec = port;
}

table first {
    actions { b1_act; }
    default_action : b1_act(1);
}

table second {
    actions { b2_act; }
    default_action : b2_act(2);
}

table third {
    actions { b3_act; }
    default_action : b3_act(3);
}

table fourth {
    actions { b4_act; }
    default_action : b4_act(4);
}

table port_set {
    actions { set_port; }
    default_action : set_port(5);
}

control ingress {
    apply(first);
    apply(second);
    apply(third);
    apply(fourth); 
    apply(port_set);
}

