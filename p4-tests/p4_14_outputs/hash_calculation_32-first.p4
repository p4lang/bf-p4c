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
    @name(".action0") action action0() {
        hash<bit<32>, bit<32>, tuple<bit<32>, bit<32>, bit<32>>, bit<64>>(hdr.packet.hash_result, HashAlgorithm.crc32, 32w0, { hdr.packet.hash_field1, hdr.packet.hash_field2, hdr.packet.hash_field3 }, 64w4294967296);
    }
    @name(".set_port") action set_port() {
        standard_metadata.egress_spec = 9w1;
    }
    @name(".test") table test {
        actions = {
            action0();
            @defaultonly NoAction();
        }
        key = {
            hdr.packet.packet_read: exact @name("packet.packet_read") ;
        }
        default_action = NoAction();
    }
    @name(".test2") table test2 {
        actions = {
            set_port();
        }
        default_action = set_port();
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

control verifyChecksum(inout headers hdr, inout metadata meta) {
    apply {
    }
}

control computeChecksum(inout headers hdr, inout metadata meta) {
    apply {
    }
}

V1Switch<headers, metadata>(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;

