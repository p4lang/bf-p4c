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
    bit<16> tmp;
    tuple<bit<32>, bit<32>> tmp_0;
    bit<16> tmp_1;
    tuple<bit<32>, bit<32>> tmp_2;
    bit<16> tmp_3;
    tuple<bit<32>, bit<32>> tmp_4;
    bit<16> tmp_5;
    tuple<bit<32>, bit<32>> tmp_6;
    bit<16> tmp_7;
    tuple<bit<32>, bit<32>> tmp_8;
    bit<16> tmp_9;
    tuple<bit<32>, bit<32>> tmp_10;
    @name(".set_port") action set_port_0() {
        standard_metadata.egress_spec = 9w1;
    }
    @name(".action1") action action1_0() {
        tmp_0 = { hdr.packet.hash_field1, hdr.packet.hash_field2 };
        hash<bit<16>, bit<16>, tuple<bit<32>, bit<32>>, bit<32>>(tmp, HashAlgorithm.random, 16w0, tmp_0, 32w63356);
        hdr.packet.hash_result1 = tmp;
    }
    @name(".action2") action action2_0() {
        tmp_2 = { hdr.packet.hash_field1, hdr.packet.hash_field3 };
        hash<bit<16>, bit<16>, tuple<bit<32>, bit<32>>, bit<32>>(tmp_1, HashAlgorithm.random, 16w0, tmp_2, 32w65536);
        hdr.packet.hash_result2 = tmp_1;
    }
    @name(".action3") action action3_0() {
        tmp_4 = { hdr.packet.hash_field1, hdr.packet.hash_field4 };
        hash<bit<16>, bit<16>, tuple<bit<32>, bit<32>>, bit<32>>(tmp_3, HashAlgorithm.crc16, 16w0, tmp_4, 32w65536);
        hdr.packet.hash_result3 = tmp_3;
    }
    @name(".action4") action action4_0() {
        tmp_6 = { hdr.packet.hash_field1, hdr.packet.hash_field5 };
        hash<bit<16>, bit<16>, tuple<bit<32>, bit<32>>, bit<32>>(tmp_5, HashAlgorithm.random, 16w0, tmp_6, 32w65536);
        hdr.packet.hash_result4 = tmp_5;
    }
    @name(".action5") action action5_0() {
        tmp_8 = { hdr.packet.hash_field1, hdr.packet.hash_field6 };
        hash<bit<16>, bit<16>, tuple<bit<32>, bit<32>>, bit<32>>(tmp_7, HashAlgorithm.random, 16w0, tmp_8, 32w65536);
        hdr.packet.hash_result5 = tmp_7;
    }
    @name(".action6") action action6_0() {
        tmp_10 = { hdr.packet.hash_field1, hdr.packet.hash_field7 };
        hash<bit<16>, bit<16>, tuple<bit<32>, bit<32>>, bit<32>>(tmp_9, HashAlgorithm.crc16, 16w0, tmp_10, 32w65536);
        hdr.packet.hash_result6 = tmp_9;
    }
    @name("port") table port_0 {
        actions = {
            set_port_0();
        }
        default_action = set_port_0();
    }
    @name("test1") table test1_0 {
        actions = {
            action1_0();
        }
        default_action = action1_0();
    }
    @name("test2") table test2_0 {
        actions = {
            action2_0();
        }
        default_action = action2_0();
    }
    @name("test3") table test3_0 {
        actions = {
            action3_0();
        }
        default_action = action3_0();
    }
    @name("test4") table test4_0 {
        actions = {
            action4_0();
        }
        default_action = action4_0();
    }
    @name("test5") table test5_0 {
        actions = {
            action5_0();
        }
        default_action = action5_0();
    }
    @name("test6") table test6_0 {
        actions = {
            action6_0();
        }
        default_action = action6_0();
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

control verifyChecksum(in headers hdr, inout metadata meta) {
    apply {
    }
}

control computeChecksum(inout headers hdr, inout metadata meta) {
    apply {
    }
}

V1Switch<headers, metadata>(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;
