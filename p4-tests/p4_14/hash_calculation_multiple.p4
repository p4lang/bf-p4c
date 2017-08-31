
header_type packet_t {
    fields {
        packet_read : 32;
        hash_field1 : 32;
        hash_field2 : 32;
        hash_field3 : 32;
        hash_field4 : 32;
        hash_field5 : 32;
        hash_field6 : 32;
        hash_field7 : 32;
        hash_result1 : 16;
        hash_result2 : 16;
        hash_result3 : 16;
        hash_result4 : 16;
        hash_result5 : 16;
        hash_result6 : 16;
    }
}

header packet_t packet;

parser start {
    extract(packet);
    return ingress;
}

field_list hash_first {
    packet.hash_field1;
    packet.hash_field2;
}

field_list hash_second {
    packet.hash_field1;
    packet.hash_field3;
}

field_list hash_third {
    packet.hash_field1;
    packet.hash_field4;
}

field_list hash_fourth {
    packet.hash_field1;
    packet.hash_field5;
}

field_list hash_fifth {
    packet.hash_field1;
    packet.hash_field6;
}

field_list hash_sixth {
    packet.hash_field1;
    packet.hash_field7;
}

field_list_calculation hash_1 {
    input {
        hash_first;
    }
    algorithm : random;
    output_width : 16;
}

field_list_calculation hash_2 {
    input {
        hash_second;
    }
    algorithm : random;
    output_width : 16;
}

field_list_calculation hash_3 {
    input {
        hash_third;
    }
    algorithm : crc16;
    output_width : 16;
}

field_list_calculation hash_4 {
    input {
        hash_fourth;
    }
    algorithm : random;
    output_width : 16;
}

field_list_calculation hash_5 {
    input {
        hash_fifth;
    }
    algorithm : random;
    output_width : 16;
}

field_list_calculation hash_6 {
    input {
        hash_sixth;
    }
    algorithm : crc16;
    output_width : 16;
}

action action1() {
    modify_field_with_hash_based_offset(packet.hash_result1, 0, hash_1, 65536);
}

action action2() {
    modify_field_with_hash_based_offset(packet.hash_result2, 0, hash_2, 65536);
}

action action3() {
    modify_field_with_hash_based_offset(packet.hash_result3, 0, hash_3, 65536);
}

action action4() {
    modify_field_with_hash_based_offset(packet.hash_result4, 0, hash_4, 65536);
}

action action5() {
    modify_field_with_hash_based_offset(packet.hash_result5, 0, hash_5, 65536);
}

action action6() {
    modify_field_with_hash_based_offset(packet.hash_result6, 0, hash_6, 65536);
}

action set_port() {
    modify_field(standard_metadata.egress_spec, 1);
}

table test1 {
    actions {
        action1;
    }
    default_action : action1;
}

table test2 {
    actions {
        action2;
    }
    default_action : action2;
}

table test3 {
    actions {
        action3;
    }
    default_action : action3;
}

table test4 {
    actions {
        action4;
    }
    default_action : action4;
}

table test5 {
    actions {
        action5;
    }
    default_action : action5;
}

table test6 {
    actions {
        action6;
    }
    default_action : action6;
}

table port {
    actions {
        set_port;
    }
    default_action : set_port;
}

control ingress {
    apply(test1);
    apply(test2);
    apply(test3);
    apply(test4);
    apply(test5);
    apply(test6);
    apply(port);
}
