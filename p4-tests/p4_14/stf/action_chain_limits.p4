header_type data_t {
     fields {
         f1 : 32;
         b1 : 8;
         b2 : 8;
         b3 : 8;
         b4 : 8;
         b5 : 8;
         b6 : 8;
         b7 : 8;
         b8 : 8;
         b9 : 8;
         h1 : 16;
         h2 : 16;
         h3 : 16;
         h4 : 16;
         h5 : 16;
         h6 : 16;
         h7 : 16;
         h8 : 16;
         h9 : 16;
     }
}

header data_t data;

parser start {
    extract(data);
    return ingress;
}

action setb1(b1) { data.b1 = b1; }
action setb2(b2) { data.b2 = b2; }
action setb3(b3) { data.b3 = b3; }
action setb4(b4) { data.b4 = b4; }
action setb5(b5) { data.b5 = b5; }
action setb6(b6) { data.b6 = b6; }
action setb7(b7) { data.b7 = b7; }
action setb8(b8) { data.b8 = b8; }
action setb9(b9) { data.b9 = b9; }

action seth1(h1) { data.h1 = h1; }
action seth2(h2) { data.h2 = h2; }
action seth3(h3) { data.h3 = h3; }
action seth4(h4) { data.h4 = h4; }
action seth5(h5) { data.h5 = h5; }
action seth6(h6) { data.h6 = h6; }
action seth7(h7) { data.h7 = h7; }
action seth8(h8) { data.h8 = h8; }
action seth9(h9) { data.h9 = h9; }

action port_set(port) { standard_metadata.egress_spec = port; }
action noop() { }

table tchain_0 {
    reads { data.f1 : exact; }
    actions {
        setb1;
        setb2;
        setb3;
        setb4;
        setb5;
        setb6;
        setb7;
        setb8;
        setb9;
        noop;
    }
    default_action : noop();
}

table t1_0 {
    reads { data.f1 : exact; }
    actions { seth1; noop; }
    default_action : noop();
}

table t2_0 {
    reads { data.f1 : exact; }
    actions { seth2; noop; }
    default_action : noop();
}

table tchain_1 {
    reads { data.f1 : exact; }
    actions {
        setb1;
        setb2;
        setb3;
        setb4;
        setb5;
        setb6;
        setb7;
        setb8;
        setb9;
        noop;
    }
    default_action : noop();
}

table t1_1 {
    reads { data.f1 : exact; }
    actions { seth1; noop; }
    default_action : noop();
}

table t2_1 {
    reads { data.f1 : exact; }
    actions { seth2; noop; }
    default_action : noop();
}

table t3_1 {
    reads { data.f1 : exact; }
    actions { seth3; noop; }
    default_action : noop();
}

table t4_1 {
    reads { data.f1 : exact; }
    actions { seth4; noop; }
    default_action : noop();
}

table t5_1 {
    reads { data.f1 : exact; }
    actions { seth5; noop; }
    default_action : noop();
}

table t6_1 {
    reads { data.f1 : exact; }
    actions { seth6; noop; }
    default_action : noop();
}

table t7_1 {
    reads { data.f1 : exact; }
    actions { seth7; noop; }
    default_action : noop();
}

table t8_1 {
    reads { data.f1 : exact; }
    actions { seth8; noop; }
    default_action : noop();
}

table t9_1 {
    reads { data.f1 : exact; }
    actions { seth9; noop; }
    default_action : noop();
}

table set_port {
    reads { data.f1 : ternary; }
    actions { port_set; noop; }
    default_action : noop;
}


control ingress {
    apply(tchain_0) {
        setb1 { apply(t1_0); }
        default { apply(t2_0); }        
    }

    apply(tchain_1) {
        setb1 { apply(t1_1); }
        setb2 { apply(t2_1); }
        setb3 { apply(t3_1); }
        setb4 { apply(t4_1); }
        setb5 { apply(t5_1); }
        setb6 { apply(t6_1); }
        setb7 { apply(t7_1); }
        setb8 { apply(t8_1); }
        setb9 { apply(t9_1); }
    }

    apply(set_port);
}
