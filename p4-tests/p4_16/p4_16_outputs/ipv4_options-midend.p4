error {
    IPv4IncorrectVersion,
    IPv4ChecksumError,
    IPv4IncorrectOptions
}
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

struct packet_t {
    ipv4_t ipv4;
}

struct user_metadata_t {
    bit<8> data;
}

parser TopParser(packet_in b, out packet_t p, inout user_metadata_t m, inout standard_metadata_t meta) {
    @name("TopParser.ck") Checksum16() ck_0;
    state start {
        b.extract<ipv4_t>(p.ipv4);
        verify(p.ipv4.version == 4w4, error.IPv4IncorrectVersion);
        verify(p.ipv4.ihl > 4w4, error.IPv4IncorrectOptions);
        transition accept;
    }
}

control ingress(inout packet_t p, inout user_metadata_t m, inout standard_metadata_t meta) {
    @name("ingress.sendToCPU") action sendToCPU() {
        meta.egress_spec = 9w64;
    }
    @name("ingress.forward") action forward() {
        meta.egress_spec = 9w1;
    }
    @hidden table tbl_sendToCPU {
        actions = {
            sendToCPU();
        }
        const default_action = sendToCPU();
    }
    @hidden table tbl_forward {
        actions = {
            forward();
        }
        const default_action = forward();
    }
    apply {
        if (p.ipv4.ihl > 4w5) 
            tbl_sendToCPU.apply();
        else 
            tbl_forward.apply();
    }
}

control egress(inout packet_t hdrs, inout user_metadata_t m, inout standard_metadata_t meta) {
    apply {
    }
}

control deparser(packet_out b, in packet_t p) {
    apply {
        b.emit<ipv4_t>(p.ipv4);
    }
}

control vck(inout packet_t hdrs, inout user_metadata_t meta) {
    apply {
    }
}

control uck(inout packet_t hdrs, inout user_metadata_t meta) {
    apply {
    }
}

V1Switch<packet_t, user_metadata_t>(TopParser(), vck(), ingress(), egress(), uck(), deparser()) main;

