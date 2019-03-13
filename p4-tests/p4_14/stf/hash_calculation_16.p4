

header_type packet_t {
    fields {
        packet_read : 32;
        hash_field1 : 32;
        hash_field2 : 32;
        hash_field3 : 32;
        hash_result : 16;
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
    algorithm : crc_16;
    output_width : 16;
}

field_list_calculation hash_1 {
    input {
        my_hash;
    }
    algorithm : crc_16_dds_110;
    output_width : 16;
}

field_list_calculation hash_2 {
    input {
        my_hash;
    }
    algorithm : crc_16_usb;
    output_width : 16;
}

action action0() {
    modify_field_with_hash_based_offset(packet.hash_result, 0, hash_0, 65536);
}

action action1() {
    modify_field_with_hash_based_offset(packet.hash_result, 0, hash_1, 65536);
}

action action2() {
    modify_field_with_hash_based_offset(packet.hash_result, 0, hash_2, 65536);
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

table hash_init {
    reads {
        packet.packet_read : exact;
    }
    actions {
        action1;
    }
}

table hash_init_rev_xor {
    reads {
        packet.packet_read : exact;
    }
    actions {
        action2;
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
    apply(hash_rev);
    apply(hash_init);
    apply(hash_init_rev_xor);
    apply(port);
}
