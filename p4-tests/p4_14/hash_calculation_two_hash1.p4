/* 
  This P4 program is to test whether the compiler and assembler can handle a table that requires
  multiple things from hash distribution, and whether or not the input xbar would correctly
  assemble.  The table and the hash distribution all share the same input xbar group.
*/


header_type packet_t {
    fields {
        packet_read  : 32;
        hash_field1  : 16;
        hash_field2  : 16;
        hash_field3  : 16;
        hash_field4  : 16;
        hash_result1 : 16;
        hash_result2 : 16;
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

field_list_calculation hash_0 {
    input {
        first_list;
    }
    algorithm : crc16;
    output_width : 16;
}

field_list_calculation hash_1 {
    input {
        second_list;
    }
    algorithm : crc16;
    output_width : 16;
}

action action0() {
    modify_field_with_hash_based_offset(packet.hash_result1, 0, hash_0, 65536);
    modify_field_with_hash_based_offset(packet.hash_result2, 0, hash_1, 65536);
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
