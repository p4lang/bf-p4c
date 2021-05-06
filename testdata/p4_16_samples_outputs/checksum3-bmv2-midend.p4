error {
    IPv4HeaderTooShort,
    IPv4IncorrectVersion
}
#include <core.p4>
#define V1MODEL_VERSION 20180101
#include <v1model.p4>

typedef bit<32> IPv4Address;
header ethernet_t {
    bit<48> dstAddr;
    bit<48> srcAddr;
    bit<16> etherType;
}

header ipv4_t {
    bit<4>      version;
    bit<4>      ihl;
    bit<8>      diffserv;
    bit<16>     totalLen;
    bit<16>     identification;
    bit<3>      flags;
    bit<13>     fragOffset;
    bit<8>      ttl;
    bit<8>      protocol;
    bit<16>     hdrChecksum;
    IPv4Address srcAddr;
    IPv4Address dstAddr;
}

header tcp_t {
    bit<16> srcPort;
    bit<16> dstPort;
    bit<32> seqNo;
    bit<32> ackNo;
    bit<4>  dataOffset;
    bit<3>  res;
    bit<3>  ecn;
    bit<6>  ctrl;
    bit<16> window;
    bit<16> checksum;
    bit<16> urgentPtr;
}

struct headers {
    ethernet_t ethernet;
    ipv4_t     ipv4;
    tcp_t      tcp;
}

struct mystruct1_t {
    bit<4> a;
    bit<4> b;
}

struct metadata {
    bit<4> _mystruct1_a0;
    bit<4> _mystruct1_b1;
}

parser parserI(packet_in pkt, out headers hdr, inout metadata meta, inout standard_metadata_t stdmeta) {
    state start {
        pkt.extract<ethernet_t>(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            16w0x800: parse_ipv4;
            default: accept;
        }
    }
    state parse_ipv4 {
        pkt.extract<ipv4_t>(hdr.ipv4);
        verify(hdr.ipv4.version == 4w4, error.IPv4IncorrectVersion);
        verify(hdr.ipv4.ihl >= 4w5, error.IPv4HeaderTooShort);
        transition select(hdr.ipv4.protocol) {
            8w6: parse_tcp;
            default: accept;
        }
    }
    state parse_tcp {
        pkt.extract<tcp_t>(hdr.tcp);
        transition accept;
    }
}

control cIngress(inout headers hdr, inout metadata meta, inout standard_metadata_t stdmeta) {
    @hidden action checksum3bmv2l130() {
        hdr.ethernet.srcAddr = 48w0xbad;
    }
    @hidden action checksum3bmv2l126() {
        stdmeta.egress_spec = 9w0;
    }
    @hidden action checksum3bmv2l134() {
        hdr.ethernet.dstAddr = 48w0xbad;
    }
    @hidden action checksum3bmv2l141() {
        hdr.ipv4.ttl = hdr.ipv4.ttl |-| 8w1;
    }
    @hidden table tbl_checksum3bmv2l126 {
        actions = {
            checksum3bmv2l126();
        }
        const default_action = checksum3bmv2l126();
    }
    @hidden table tbl_checksum3bmv2l130 {
        actions = {
            checksum3bmv2l130();
        }
        const default_action = checksum3bmv2l130();
    }
    @hidden table tbl_checksum3bmv2l134 {
        actions = {
            checksum3bmv2l134();
        }
        const default_action = checksum3bmv2l134();
    }
    @hidden table tbl_checksum3bmv2l141 {
        actions = {
            checksum3bmv2l141();
        }
        const default_action = checksum3bmv2l141();
    }
    apply {
        tbl_checksum3bmv2l126.apply();
        if (stdmeta.checksum_error == 1w1) {
            tbl_checksum3bmv2l130.apply();
        }
        if (stdmeta.parser_error != error.NoError) {
            tbl_checksum3bmv2l134.apply();
        }
        if (hdr.ipv4.isValid()) {
            tbl_checksum3bmv2l141.apply();
        }
    }
}

control cEgress(inout headers hdr, inout metadata meta, inout standard_metadata_t stdmeta) {
    apply {
    }
}

control vc(inout headers hdr, inout metadata meta) {
    apply {
    }
}

struct tuple_0 {
    bit<4>  f0;
    bit<4>  f1;
    bit<8>  f2;
    bit<16> f3;
    bit<16> f4;
    bit<3>  f5;
    bit<13> f6;
    bit<8>  f7;
    bit<8>  f8;
    bit<32> f9;
    bit<32> f10;
}

control uc(inout headers hdr, inout metadata meta) {
    apply {
        update_checksum<tuple_0, bit<16>>(hdr.ipv4.isValid(), { hdr.ipv4.version, hdr.ipv4.ihl, hdr.ipv4.diffserv, hdr.ipv4.totalLen, hdr.ipv4.identification, hdr.ipv4.flags, hdr.ipv4.fragOffset, hdr.ipv4.ttl, hdr.ipv4.protocol, hdr.ipv4.srcAddr, hdr.ipv4.dstAddr }, hdr.ipv4.hdrChecksum, HashAlgorithm.csum16);
    }
}

control DeparserI(packet_out packet, in headers hdr) {
    apply {
        packet.emit<ethernet_t>(hdr.ethernet);
        packet.emit<ipv4_t>(hdr.ipv4);
        packet.emit<tcp_t>(hdr.tcp);
    }
}

V1Switch<headers, metadata>(parserI(), vc(), cIngress(), cEgress(), uc(), DeparserI()) main;
