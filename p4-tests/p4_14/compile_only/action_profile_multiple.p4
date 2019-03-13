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
        b5 : 8;
        b6 : 8;
        b7 : 8;
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

action setb5(val5) {
    modify_field(data.b5, val5);
}

action setb6(val6) {
    modify_field(data.b6, val6);
}

action setb7(val7) {
    modify_field(data.b7, val7);
}

action_profile set_b1_3 {
    actions {
        setb1;
        setb2;
        setb3;
    }
    size : 1024;
}

action_profile set_b5_7 {
    actions {
        setb5;
        setb6;
        setb7;
    }
    size : 2048;
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
        data.f2 : exact;
    }
    action_profile : set_b1_3;
    size : 5000;
}

table test3 {
    reads {
        data.f3 : exact;
    }
    action_profile : set_b5_7;
    size : 5000;
}

table test4 {
    reads {
        data.f4 : exact;
    }
    action_profile : set_b5_7;
    size : 10000;
}

control ingress {
    if (data.b4 == 0) {
        apply(test1);
        apply(test3);
    } else {
        apply(test2);
        apply(test4);
    }
}

