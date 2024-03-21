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
        packet.extract(hdr.packet);
        transition accept;
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".action1") action action1() {
        hash(hdr.packet.hash_result1, HashAlgorithm.random, (bit<32>)0, { hdr.packet.hash_field1, hdr.packet.hash_field2 }, (bit<64>)16777216);
    }
    @name(".action2") action action2() {
        hash(hdr.packet.hash_result2, HashAlgorithm.random, (bit<32>)0, { hdr.packet.hash_field3, hdr.packet.hash_field4 }, (bit<64>)256);
    }
    @name(".action3") action action3() {
        hash(hdr.packet.hash_result3, HashAlgorithm.crc16, (bit<16>)0, { hdr.packet.hash_field5, hdr.packet.hash_field6 }, (bit<32>)8);
    }
    @name(".test1") table test1 {
        actions = {
            action1;
        }
        default_action = action1();
    }
    @name(".test2") table test2 {
        actions = {
            action2;
        }
        default_action = action2();
    }
    @name(".test3") table test3 {
        actions = {
            action3;
        }
        default_action = action3();
    }
    apply {
        test1.apply();
        test2.apply();
        test3.apply();
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit(hdr.packet);
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

V1Switch(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;

