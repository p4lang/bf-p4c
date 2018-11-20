
header_type packet_t {
    fields {
        packet_read : 32;
        hash_field1 : 32;
        hash_field2 : 32;
        hash_field3 : 32;
        hash_result : 32;
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
    algorithm : crc_32;
    output_width : 32;
}

action action0() {
    modify_field_with_hash_based_offset(packet.hash_result, 0, hash_0, 4294967296);
}

action set_port(p) {
    modify_field(standard_metadata.egress_spec, p);
}

table hash_normal {
    reads {
        packet.packet_read : exact;
    }
    actions {
        action0;
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
    apply(hash_normal);
    apply(port);
}
