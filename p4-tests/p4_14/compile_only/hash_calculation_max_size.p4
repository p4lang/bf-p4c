header_type packet_t {
    fields {
        hash_field1 : 32;
        hash_field2 : 32;
        hash_field3 : 32;
        hash_field4 : 32;
        hash_field5 : 32;
        hash_field6 : 32;
        hash_result1 : 32;
        hash_result2 : 32;
        hash_result3 : 16;
    }
}

header packet_t packet;

parser start {
    extract(packet);
    return ingress;
}

field_list first_list {
    packet.hash_field1;
    packet.hash_field2;
}

field_list second_list {
    packet.hash_field3;
    packet.hash_field4;
}

field_list third_list {
    packet.hash_field5;
    packet.hash_field6;
}

field_list_calculation hash1 {
    input {
        first_list;
    }
    algorithm : random;
    output_width : 32;
}

field_list_calculation hash2 {
    input {
        second_list;
    }
    algorithm : random;
    output_width : 32;
}

field_list_calculation hash3 {
    input {
        third_list;
    }
    algorithm : crc16;
    output_width : 16;
}

action set_port() {
    modify_field(standard_metadata.egress_spec, 1);
}

action action1() {
    modify_field_with_hash_based_offset(packet.hash_result1, 0, hash1, 16777216);
}

action action2() {
    modify_field_with_hash_based_offset(packet.hash_result2, 0, hash2, 256);
}

action action3() {
    modify_field_with_hash_based_offset(packet.hash_result3, 0, hash3, 8);
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
}


