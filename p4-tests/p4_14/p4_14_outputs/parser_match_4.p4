#include <core.p4>
#include <v1model.p4>

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

header ipv4_options_32b_t {
    bit<32> options;
}

header ipv4_options_64b_t {
    bit<64> options;
}

header ipv4_options_96b_t {
    bit<96> options;
}

header udp_t {
    bit<16> srcPort;
    bit<16> dstPort;
    bit<16> length_;
    bit<16> checksum;
}

struct metadata {
}

struct headers {
    @name(".ipv4") 
    ipv4_t             ipv4;
    @name(".ipv4_options_32b") 
    ipv4_options_32b_t ipv4_options_32b;
    @name(".ipv4_options_64b") 
    ipv4_options_64b_t ipv4_options_64b;
    @name(".ipv4_options_96b") 
    ipv4_options_96b_t ipv4_options_96b;
    @name(".udp") 
    udp_t              udp;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".parse_ipv4_no_options") state parse_ipv4_no_options {
        transition select(hdr.ipv4.fragOffset, hdr.ipv4.protocol) {
            (13w0x0, 8w0x11): parse_udp;
            default: accept;
        }
    }
    @name(".parse_ipv4_options_32b") state parse_ipv4_options_32b {
        packet.extract(hdr.ipv4_options_32b);
        transition parse_ipv4_no_options;
    }
    @name(".parse_ipv4_options_64b") state parse_ipv4_options_64b {
        packet.extract(hdr.ipv4_options_64b);
        transition parse_ipv4_no_options;
    }
    @name(".parse_ipv4_options_96b") state parse_ipv4_options_96b {
        packet.extract(hdr.ipv4_options_96b);
        transition parse_ipv4_no_options;
    }
    @name(".parse_udp") state parse_udp {
        packet.extract(hdr.udp);
        transition accept;
    }
    @name(".start") state start {
        packet.extract(hdr.ipv4);
        transition select(hdr.ipv4.ihl) {
            4w0x5: parse_ipv4_no_options;
            4w0x6: parse_ipv4_options_32b;
            4w0x7: parse_ipv4_options_64b;
            4w0x8: parse_ipv4_options_96b;
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
        packet.emit(hdr.ipv4);
        packet.emit(hdr.ipv4_options_96b);
        packet.emit(hdr.ipv4_options_64b);
        packet.emit(hdr.ipv4_options_32b);
        packet.emit(hdr.udp);
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

