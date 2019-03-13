
header_type data_t {
    fields {
        f1 : 32;
        f2 : 32;
        h1 : 16;
        h2 : 16;
        h3 : 16;
        h4 : 16;
        h5 : 16;
        h6 : 16;
        b1 : 8;
        b2 : 8;
        b3 : 8;
        b4 : 8;
        b5 : 8;
        b6 : 8;
    }
}

header data_t data;
parser start {
    extract (data);
    return ingress;
}

field_list h1_3 {
    data.h1;
    data.h2;
    data.h3;
}

field_list h4_6 {
    data.h4;
    data.h5;
    data.h6;
}

field_list_calculation sel_hash {
    input {
        h1_3;
    }
    algorithm : crc16;
    output_width : 14;
}

field_list_calculation sel_hash2 {
    input {
        h4_6;
    }
    algorithm : random;
    output_width : 14;
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
    size : 160000;
    dynamic_action_selection : my_sel;
}

action_selector my_sel {
    selection_key : sel_hash;
    selection_mode : fair;
}

action setb4(val4) {
    modify_field(data.b4, val4);
}

action setb5(val5) {
    modify_field(data.b5, val5);
}

action setb6(val6) {
    modify_field(data.b6, val6);
}

action_profile set_b4_6 {
    actions {
        setb4;
        setb5;
        setb6;
    }
    size : 1024;
    dynamic_action_selection : my_sel2;
}

action_selector my_sel2 {
    selection_key : sel_hash2;
    selection_mode : fair;
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
    action_profile : set_b4_6;
    size : 5000;
}

control ingress {
    apply(test1);
    apply(test2);
}
