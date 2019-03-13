#include <core.p4>
#include <v1model.p4>

header packet_t {
    bit<32> packet_read;
    bit<32> hash_field1;
    bit<32> hash_field2;
    bit<32> hash_field3;
    bit<32> hash_field4;
    bit<32> hash_field5;
    bit<32> hash_field6;
    bit<32> hash_field7;
    bit<16> hash_result1;
    bit<16> hash_result2;
    bit<16> hash_result3;
    bit<16> hash_result4;
    bit<16> hash_result5;
    bit<16> hash_result6;
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

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".set_port") action set_port() {
        standard_metadata.egress_spec = 9w1;
    }
    @name(".action1") action action1() {
        hash<bit<16>, bit<16>, tuple<bit<32>, bit<32>>, bit<32>>(hdr.packet.hash_result1, HashAlgorithm.random, 16w0, { hdr.packet.hash_field1, hdr.packet.hash_field2 }, 32w65536);
    }
    @name(".action2") action action2() {
        hash<bit<16>, bit<16>, tuple<bit<32>, bit<32>>, bit<32>>(hdr.packet.hash_result2, HashAlgorithm.random, 16w0, { hdr.packet.hash_field1, hdr.packet.hash_field3 }, 32w65536);
    }
    @name(".action3") action action3() {
        hash<bit<16>, bit<16>, tuple<bit<32>, bit<32>>, bit<32>>(hdr.packet.hash_result3, HashAlgorithm.crc16, 16w0, { hdr.packet.hash_field1, hdr.packet.hash_field4 }, 32w65536);
    }
    @name(".action4") action action4() {
        hash<bit<16>, bit<16>, tuple<bit<32>, bit<32>>, bit<32>>(hdr.packet.hash_result4, HashAlgorithm.random, 16w0, { hdr.packet.hash_field1, hdr.packet.hash_field5 }, 32w65536);
    }
    @name(".action5") action action5() {
        hash<bit<16>, bit<16>, tuple<bit<32>, bit<32>>, bit<32>>(hdr.packet.hash_result5, HashAlgorithm.random, 16w0, { hdr.packet.hash_field1, hdr.packet.hash_field6 }, 32w65536);
    }
    @name(".action6") action action6() {
        hash<bit<16>, bit<16>, tuple<bit<32>, bit<32>>, bit<32>>(hdr.packet.hash_result6, HashAlgorithm.crc16, 16w0, { hdr.packet.hash_field1, hdr.packet.hash_field7 }, 32w65536);
    }
    @name(".port") table port_0 {
        actions = {
            set_port();
        }
        default_action = set_port();
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
    @name(".test4") table test4_0 {
        actions = {
            action4();
        }
        default_action = action4();
    }
    @name(".test5") table test5_0 {
        actions = {
            action5();
        }
        default_action = action5();
    }
    @name(".test6") table test6_0 {
        actions = {
            action6();
        }
        default_action = action6();
    }
    apply {
        test1_0.apply();
        test2_0.apply();
        test3_0.apply();
        test4_0.apply();
        test5_0.apply();
        test6_0.apply();
        port_0.apply();
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

