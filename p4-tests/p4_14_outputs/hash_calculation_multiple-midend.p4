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

struct tuple_0 {
    bit<32> field;
    bit<32> field_0;
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".set_port") action set_port_0() {
        standard_metadata.egress_spec = 9w1;
    }
    @name(".action1") action action1_0() {
        hash<bit<16>, bit<16>, tuple_0, bit<32>>(hdr.packet.hash_result1, HashAlgorithm.random, 16w0, { hdr.packet.hash_field1, hdr.packet.hash_field2 }, 32w65536);
    }
    @name(".action2") action action2_0() {
        hash<bit<16>, bit<16>, tuple_0, bit<32>>(hdr.packet.hash_result2, HashAlgorithm.random, 16w0, { hdr.packet.hash_field1, hdr.packet.hash_field3 }, 32w65536);
    }
    @name(".action3") action action3_0() {
        hash<bit<16>, bit<16>, tuple_0, bit<32>>(hdr.packet.hash_result3, HashAlgorithm.crc16, 16w0, { hdr.packet.hash_field1, hdr.packet.hash_field4 }, 32w65536);
    }
    @name(".action4") action action4_0() {
        hash<bit<16>, bit<16>, tuple_0, bit<32>>(hdr.packet.hash_result4, HashAlgorithm.random, 16w0, { hdr.packet.hash_field1, hdr.packet.hash_field5 }, 32w65536);
    }
    @name(".action5") action action5_0() {
        hash<bit<16>, bit<16>, tuple_0, bit<32>>(hdr.packet.hash_result5, HashAlgorithm.random, 16w0, { hdr.packet.hash_field1, hdr.packet.hash_field6 }, 32w65536);
    }
    @name(".action6") action action6_0() {
        hash<bit<16>, bit<16>, tuple_0, bit<32>>(hdr.packet.hash_result6, HashAlgorithm.crc16, 16w0, { hdr.packet.hash_field1, hdr.packet.hash_field7 }, 32w65536);
    }
    @name(".port") table port {
        actions = {
            set_port_0();
        }
        default_action = set_port_0();
    }
    @name(".test1") table test1 {
        actions = {
            action1_0();
        }
        default_action = action1_0();
    }
    @name(".test2") table test2 {
        actions = {
            action2_0();
        }
        default_action = action2_0();
    }
    @name(".test3") table test3 {
        actions = {
            action3_0();
        }
        default_action = action3_0();
    }
    @name(".test4") table test4 {
        actions = {
            action4_0();
        }
        default_action = action4_0();
    }
    @name(".test5") table test5 {
        actions = {
            action5_0();
        }
        default_action = action5_0();
    }
    @name(".test6") table test6 {
        actions = {
            action6_0();
        }
        default_action = action6_0();
    }
    apply {
        test1.apply();
        test2.apply();
        test3.apply();
        test4.apply();
        test5.apply();
        test6.apply();
        port.apply();
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

