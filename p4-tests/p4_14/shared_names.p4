
header_type data_t {
    fields {
        f1 : 32;
        f2 : 32;
        f3 : 32;
        f4 : 32;
        h1 : 16;
        h2 : 16;
        h3 : 16;
        b1 : 8;
        b2 : 8;
        b3 : 8;
        b4 : 8;
        color1 : 8;
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

action_profile same_name {
    actions {
        setb1;
        setb2;
        setb3;
    }
    size : 1024;
    dynamic_action_selection : same_name;
}

action_selector same_name {
    selection_key : sel_hash;
    selection_mode : fair;
}

table same_name {
    reads {
        data.f1 : exact;
    }
    action_profile : same_name;
}

counter same_name {
    type : bytes;
    direct : same_name;
}

meter same_name {
    type : bytes;
    direct : same_name;
    result : data.color1;
}

control ingress {
    apply(same_name);
}
