#include <core.p4>
#include <v1model.p4>

header packet_t {
    bit<32> packet_read;
    bit<32> hash_field1;
    bit<32> hash_field2;
    bit<32> hash_field3;
    bit<32> hash_result;
}

struct metadata {
}

struct headers {
    @name("packet") 
    packet_t packet;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".start") state start {
        packet.extract<packet_t>(hdr.packet);
        transition accept;
    }
}

struct tuple_0 {
    bit<32> field;
    bit<32> field_0;
    bit<32> field_1;
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    bit<32> tmp_1;
    tuple_0 tmp_2;
    @name("NoAction") action NoAction_0() {
    }
    @name(".action0") action action0_0() {
        tmp_2.field = hdr.packet.hash_field1;
        tmp_2.field_0 = hdr.packet.hash_field2;
        tmp_2.field_1 = hdr.packet.hash_field3;
        hash<bit<32>, bit<32>, tuple_0, bit<64>>(tmp_1, HashAlgorithm.crc32, 32w0, tmp_2, 64w4294967296);
        hdr.packet.hash_result = tmp_1;
    }
    @name(".set_port") action set_port_0() {
        standard_metadata.egress_spec = 9w1;
    }
    @name(".test") table test {
        actions = {
            action0_0();
            @defaultonly NoAction_0();
        }
        key = {
            hdr.packet.packet_read: exact @name("hdr.packet.packet_read") ;
        }
        default_action = NoAction_0();
    }
    @name(".test2") table test2 {
        actions = {
            set_port_0();
        }
        default_action = set_port_0();
    }
    apply {
        test.apply();
        test2.apply();
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit<packet_t>(hdr.packet);
    }
}

control verifyChecksum(in headers hdr, inout metadata meta) {
    apply {
    }
}

control computeChecksum(inout headers hdr, inout metadata meta) {
    apply {
    }
}

V1Switch<headers, metadata>(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;
