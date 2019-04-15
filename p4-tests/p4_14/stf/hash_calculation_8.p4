
header_type packet_t {
    fields {
        packet_read : 32;
        hash_field1 : 32;
        hash_field2 : 32;
        hash_field3 : 32;
        hash_result1 : 8;
        hash_result2 : 8;
        hash_result3 : 8;
        hash_result4 : 8;
    }
}

header packet_t packet;

parser start {
    extract(packet);
    return ingress;
}

field_list my_hash {
    packet.hash_field1;
    packet.hash_field2;
    packet.hash_field3;
}

field_list_calculation hash_0 {
    input {
        my_hash;
    }
    algorithm : crc_8;
    output_width : 8;
}

field_list_calculation hash_1 {
    input {
        my_hash;
    }
    algorithm : crc_8_darc;
    output_width : 8;
}

field_list_calculation hash_2 {
    input {
        my_hash;
    }
    algorithm : crc_8_i_code;
    output_width : 8;
}

field_list_calculation hash_3 {
    input {
        my_hash;
    }
    algorithm : crc_8_rohc;
    output_width : 8;
}

action action0() {
    modify_field_with_hash_based_offset(packet.hash_result1, 0, hash_0, 256);
}

action action1() {
    modify_field_with_hash_based_offset(packet.hash_result2, 0, hash_1, 256);
}

action action2() {
    modify_field_with_hash_based_offset(packet.hash_result3, 0, hash_2, 256);
}

action action3() {
    modify_field_with_hash_based_offset(packet.hash_result4, 0, hash_3, 256);
}

action set_port(port) {
    modify_field(standard_metadata.egress_spec, port);
}

table hash_rev {
    reads {
        packet.packet_read : exact;
    }
    actions {
        action0;
    }
}

table hash_calc {
    reads {
        packet.packet_read : exact;
    }
    actions {
        action0;
        action1;
        action2;
        action3;
    }
}

table port {
    reads {
        packet.packet_read : exact;
    }
    actions {
        set_port;
    }
    default_action : set_port;
}

control ingress {
    apply(hash_calc);
    apply(port);
}
