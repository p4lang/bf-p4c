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

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    bit<32> tmp;
    tuple<bit<32>, bit<32>, bit<32>> tmp_0;
    @name(".action0") action action0_0() {
        tmp_0 = { hdr.packet.hash_field1, hdr.packet.hash_field2, hdr.packet.hash_field3 };
        hash<bit<32>, bit<32>, tuple<bit<32>, bit<32>, bit<32>>, bit<64>>(tmp, HashAlgorithm.crc32, 32w0, tmp_0, 64w4294967296);
        hdr.packet.hash_result = tmp;
    }
    @name(".set_port") action set_port_0() {
        standard_metadata.egress_spec = 9w1;
    }
    @name(".test") table test_0 {
        actions = {
            action0_0();
            @defaultonly NoAction();
        }
        key = {
            hdr.packet.packet_read: exact @name("hdr.packet.packet_read") ;
        }
        default_action = NoAction();
    }
    @name(".test2") table test2_0 {
        actions = {
            set_port_0();
        }
        default_action = set_port_0();
    }
    apply {
        test_0.apply();
        test2_0.apply();
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
