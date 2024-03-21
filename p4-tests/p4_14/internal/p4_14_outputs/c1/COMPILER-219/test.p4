#include <core.p4>
#include <v1model.p4>

struct M {
    bit<1> a;
    bit<1> b;
    bit<6> c;
}

@name("EthernetHdr") header EthernetHdr_0 {
    bit<48> dmac;
    bit<48> smac;
    bit<16> etherType;
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

struct metadata {
    @name(".m") 
    M m;
}

struct headers {
    @name(".eth") 
    EthernetHdr_0 eth;
    @name(".ipv4") 
    ipv4_t        ipv4;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".parseEthernet") state parseEthernet {
        packet.extract(hdr.eth);
        transition parse_ipv4;
    }
    @name(".parse_ipv4") state parse_ipv4 {
        packet.extract(hdr.ipv4);
        transition accept;
    }
    @name(".start") state start {
        transition parseEthernet;
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".a1") action a1() {
    }
    @name(".T1") table T1 {
        actions = {
            a1;
        }
        size = 1;
    }
    apply {
        if (meta.m.a == 1w0 && hdr.ipv4.ttl > 8w0) {
            T1.apply();
        }
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit(hdr.eth);
        packet.emit(hdr.ipv4);
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

