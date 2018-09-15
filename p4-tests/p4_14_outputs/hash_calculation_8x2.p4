#include <core.p4>
#include <v1model.p4>

header byte_t {
    bit<8> val;
}

header packet_t {
    bit<32> packet_read;
    bit<32> hash_field1;
    bit<32> hash_field2;
    bit<32> hash_field3;
    bit<16> hash_result;
}

struct metadata {
}

struct headers {
    @name(".b1") 
    byte_t   b1;
    @name(".b2") 
    byte_t   b2;
    @name(".packet") 
    packet_t packet;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".start") state start {
        packet.extract(hdr.packet);
        packet.extract(hdr.b1);
        packet.extract(hdr.b2);
        transition accept;
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".action0") action action0() {
        hash(hdr.packet.hash_result, HashAlgorithm.random, (bit<16>)0, { hdr.packet.hash_field1, hdr.packet.hash_field2, hdr.packet.hash_field3 }, (bit<32>)65536);
        hdr.b1.val = (bit<8>)(hdr.packet.hash_result & 16w0xff);
        hdr.b2.val[7:0] = (hdr.packet.hash_result >> 8)[7:0];
    }
    @name(".set_port") action set_port() {
        standard_metadata.egress_spec = 9w1;
    }
    @name(".test") table test {
        actions = {
            action0;
        }
        key = {
            hdr.packet.packet_read: exact;
        }
    }
    @name(".test2") table test2 {
        actions = {
            set_port;
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
        packet.emit(hdr.packet);
        packet.emit(hdr.b1);
        packet.emit(hdr.b2);
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

