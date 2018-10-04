#include <core.p4>
#include <v1model.p4>

header boring_t {
    bit<128> yawn;
}

header ipv4_t {
    bit<4>  version;
    bit<4>  ihl;
    bit<8>  diffserv;
    bit<16> totalLen;
    bit<16> identification;
    bit<3>  flags;
    bit<13> fragOffset;
    bit<8>  ttl;
    bit<8>  protocol;
    bit<16> hdrChecksum;
    bit<32> srcAddr;
    bit<32> dstAddr;
}

header magic_t {
    bit<16> glue;
    bit<8>  powder;
    bit<5>  hat;
    bit<3>  trick;
}

struct metadata {
}

struct headers {
    @name(".boring") 
    boring_t boring;
    @name(".ipv4") 
    ipv4_t   ipv4;
    @name(".magic") 
    magic_t  magic;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".parse_boring") state parse_boring {
        packet.extract<boring_t>(hdr.boring);
        transition accept;
    }
    @name(".parse_magic") state parse_magic {
        packet.extract<magic_t>(hdr.magic);
        transition select(hdr.magic.hat, hdr.magic.trick, hdr.magic.powder, hdr.magic.glue) {
            (5w0x2, 3w0x2, 8w0x34, 16w0x5678): parse_boring;
            default: accept;
        }
    }
    @name(".start") state start {
        packet.extract<ipv4_t>(hdr.ipv4);
        transition select(hdr.ipv4.flags, hdr.ipv4.fragOffset, hdr.ipv4.ihl, hdr.ipv4.protocol) {
            (3w0x0, 13w0x508, 4w0x0, 8w0x80): parse_magic;
            default: accept;
        }
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit<ipv4_t>(hdr.ipv4);
        packet.emit<magic_t>(hdr.magic);
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

