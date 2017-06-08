
header_type data_t {
    fields {
        f1 : 32;
        f2 : 32;
        r1 : 32;
        r2 : 32;
        r3 : 32;
        r4 : 32;
        r5 : 32;
        r6 : 32;
        r7 : 32;
        r8 : 32;
        r9 : 32;
        r10 : 32;
        h1 : 16;
        h2 : 16;
        h3 : 16;
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

field_list_calculation sel_hash {
    input {
        h1_3;
    }
    algorithm : crc16;
    output_width : 14;
}

action setr1_5(val1, val2, val3, val4, val5) {
    modify_field(data.r1, val1);
    modify_field(data.r2, val2);
    modify_field(data.r3, val3);
    modify_field(data.r4, val4);
    modify_field(data.r5, val5);
}

action setr6_10(val6, val7, val8, val9, val10) {
    modify_field(data.r6, val6);
    modify_field(data.r7, val7);
    modify_field(data.r8, val8);
    modify_field(data.r9, val9);
    modify_field(data.r10, val10);
}


action_profile set_r1_10 {
    actions {
        setr1_5;
        setr6_10;
    }
    size : 1024;
    dynamic_action_selection : my_sel;
}

action_selector my_sel {
    selection_key : sel_hash;
    selection_mode : fair;
}

table test1 {
    reads {
        data.f1 : exact;
    }
    action_profile : set_r1_10;
    size : 10000;
}

control ingress {
    apply(test1);
}
