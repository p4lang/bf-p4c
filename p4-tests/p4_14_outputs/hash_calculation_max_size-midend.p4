#include <core.p4>
#include <v1model.p4>

header packet_t {
    bit<32> hash_field1;
    bit<32> hash_field2;
    bit<32> hash_field3;
    bit<32> hash_field4;
    bit<32> hash_field5;
    bit<32> hash_field6;
    bit<32> hash_result1;
    bit<32> hash_result2;
    bit<16> hash_result3;
}

struct metadata {
}

struct headers {
    @name(".packet") 
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
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".action1") action action1() {
        hash<bit<32>, bit<32>, tuple_0, bit<64>>(hdr.packet.hash_result1, HashAlgorithm.random, 32w0, { hdr.packet.hash_field1, hdr.packet.hash_field2 }, 64w16777216);
    }
    @name(".action2") action action2() {
        hash<bit<32>, bit<32>, tuple_0, bit<64>>(hdr.packet.hash_result2, HashAlgorithm.random, 32w0, { hdr.packet.hash_field3, hdr.packet.hash_field4 }, 64w256);
    }
    @name(".action3") action action3() {
        hash<bit<16>, bit<16>, tuple_0, bit<32>>(hdr.packet.hash_result3, HashAlgorithm.crc16, 16w0, { hdr.packet.hash_field5, hdr.packet.hash_field6 }, 32w8);
    }
    @name(".test1") table test1_0 {
        actions = {
            action1();
        }
        default_action = action1();
    }
    @name(".test2") table test2_0 {
        actions = {
            action2();
        }
        default_action = action2();
    }
    @name(".test3") table test3_0 {
        actions = {
            action3();
        }
        default_action = action3();
    }
    apply {
        test1_0.apply();
        test2_0.apply();
        test3_0.apply();
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

control verifyChecksum(inout headers hdr, inout metadata meta) {
    apply {
    }
}

control computeChecksum(inout headers hdr, inout metadata meta) {
    apply {
    }
}

V1Switch<headers, metadata>(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;

