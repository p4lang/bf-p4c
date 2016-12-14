
header_type data_t {
    fields {
        f1 : 32;
        f2 : 32;
        f3 : 32;
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

action set_f1_2(val1, val2) {
    modify_field(data.f1, val1);
    modify_field(data.f2, val2);
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
        data.f2 : exact;
    }
    action_profile : set_b1_3;
    size : 5000;
}

table test_mid {
    reads {
        data.f3 : exact;
    }
    actions {
        set_f1_2;
    }
}

table test3 {
    reads {
        data.f1 : exact;
    }
    action_profile : set_b1_3;
    size : 5000;
}

table test4 {
    reads {
        data.f2 : exact;
    }
    action_profile : set_b1_3;
    size : 10000;
}

control ingress {
    if (data.b4 == 0) {
        apply(test1);
    } else {
        apply(test2);
    }

    apply(test_mid);

    if (data.b4 != 0) {
        apply(test3);
    } else {
        apply(test4);
    }
}
