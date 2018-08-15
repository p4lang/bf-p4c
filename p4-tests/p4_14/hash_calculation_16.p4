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
    algorithm : random;
    output_width : 16;
}

action action0() {
    modify_field_with_hash_based_offset(packet.hash_result, 0, hash_0, 65536);
}

action set_port() {
    modify_field(standard_metadata.egress_spec, 1);
}

table test {
    reads {
        packet.packet_read : exact;
    }
    actions {
        action0;
    }
}

table test2 {
    actions {
        set_port;
    }
    default_action : set_port;
}

control ingress {
    apply(test);
    apply(test2);
}
