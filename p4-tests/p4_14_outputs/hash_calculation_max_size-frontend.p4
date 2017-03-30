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
    @name("packet") 
    packet_t packet;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name("start") state start {
        packet.extract<packet_t>(hdr.packet);
        transition accept;
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    bit<32> tmp;
    tuple<bit<32>, bit<32>> tmp_0;
    bit<32> tmp_1;
    tuple<bit<32>, bit<32>> tmp_2;
    bit<16> tmp_3;
    tuple<bit<32>, bit<32>> tmp_4;
    @name(".action1") action action1_0() {
        tmp_0 = { hdr.packet.hash_field1, hdr.packet.hash_field2 };
        hash<bit<32>, bit<32>, tuple<bit<32>, bit<32>>, bit<64>>(tmp, HashAlgorithm.random, 32w0, tmp_0, 64w16777216);
        hdr.packet.hash_result1 = tmp;
    }
    @name(".action2") action action2_0() {
        tmp_2 = { hdr.packet.hash_field3, hdr.packet.hash_field4 };
        hash<bit<32>, bit<32>, tuple<bit<32>, bit<32>>, bit<64>>(tmp_1, HashAlgorithm.random, 32w0, tmp_2, 64w256);
        hdr.packet.hash_result2 = tmp_1;
    }
    @name(".action3") action action3_0() {
        tmp_4 = { hdr.packet.hash_field5, hdr.packet.hash_field6 };
        hash<bit<16>, bit<16>, tuple<bit<32>, bit<32>>, bit<32>>(tmp_3, HashAlgorithm.crc16, 16w0, tmp_4, 32w8);
        hdr.packet.hash_result3 = tmp_3;
    }
    @name("test1") table test1_0 {
        actions = {
            action1_0();
        }
        const default_action = action1_0();
    }
    @name("test2") table test2_0 {
        actions = {
            action2_0();
        }
        const default_action = action2_0();
    }
    @name("test3") table test3_0 {
        actions = {
            action3_0();
        }
        const default_action = action3_0();
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

control verifyChecksum(in headers hdr, inout metadata meta) {
    apply {
    }
}

control computeChecksum(inout headers hdr, inout metadata meta) {
    apply {
    }
}

V1Switch<headers, metadata>(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;
