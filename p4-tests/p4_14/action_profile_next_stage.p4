
header_type data_t {
    fields {
        f1 : 32;
        f2 : 32;
        b1 : 8;
        b2 : 8;
        b3 : 8;
        b4 : 8;
    }
}

header data_t data;
parser start {
    extract (data);
    return ingress;
}

action setb1(val1) {
    modify_field(data.b1, val1);
}

action setb2(val2) {
    modify_field(data.b2, val2); 
}

action setb3(val3) {
    modify_field(data.b3, val3);
}

action_profile set_b1_3 {
    actions {
        setb1;
        setb2;
        setb3;
    }
    size : 1024;
}

table test1 {
    reads {
        data.f1 : exact;
    }
    action_profile : set_b1_3;
    size : 10000;
}

table test2 {
    reads {
        data.b1 : exact;
    }
    action_profile : set_b1_3;
    size : 5000;
}

control ingress { 
    apply(test1); 
    apply(test2);
}
