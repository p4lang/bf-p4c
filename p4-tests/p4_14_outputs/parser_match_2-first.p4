#include <core.p4>
#include <v1model.p4>

header boring_t {
    bit<32> yawn;
}

header homework_t {
    bit<4>  juicebox;
    bit<4>  bully;
    bit<16> detergent;
    bit<3>  flags;
    bit<13> lunchbox;
}

struct metadata {
}

struct headers {
    @name(".boring") 
    boring_t   boring;
    @name(".homework") 
    homework_t homework;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".parse_boring") state parse_boring {
        standard_metadata.egress_spec = 9w0x2;
        transition accept;
    }
    @name(".parse_schoolbus") state parse_schoolbus {
        packet.extract<boring_t>(hdr.boring);
        transition select(hdr.homework.flags, hdr.homework.lunchbox, hdr.homework.juicebox) {
            (3w0x0 &&& 3w0x0, 13w0x0 &&& 13w0x0, 4w0x6 &&& 4w0xf): parse_boring;
            default: accept;
        }
    }
    @name(".start") state start {
        packet.extract<homework_t>(hdr.homework);
        transition select(hdr.homework.bully, hdr.homework.flags, hdr.homework.lunchbox) {
            (4w0x5 &&& 4w0xf, 3w0x0 &&& 3w0x0, 13w0x0 &&& 13w0x0): parse_schoolbus;
            default: accept;
        }
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit<homework_t>(hdr.homework);
        packet.emit<boring_t>(hdr.boring);
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

