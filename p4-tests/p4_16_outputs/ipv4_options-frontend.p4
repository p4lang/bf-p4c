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
    bool tmp;
    bool tmp_0;
    state start {
        b.extract<ipv4_t>(p.ipv4);
        tmp = p.ipv4.version == 4w4;
        verify(tmp, error.IPv4IncorrectVersion);
        tmp_0 = p.ipv4.ihl > 4w4;
        verify(tmp_0, error.IPv4IncorrectOptions);
        transition accept;
    }
}

control ingress(inout packet_t p, inout user_metadata_t m, inout standard_metadata_t meta) {
    bool tmp_1;
    @name("sendToCPU") action sendToCPU_0() {
        meta.egress_spec = 9w64;
    }
    @name("forward") action forward_0() {
        meta.egress_spec = 9w1;
    }
    apply {
        tmp_1 = p.ipv4.ihl > 4w5;
        if (tmp_1) 
            sendToCPU_0();
        else 
            forward_0();
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

control vck(in packet_t hdrs, inout user_metadata_t meta) {
    apply {
    }
}

control uck(inout packet_t hdrs, inout user_metadata_t meta) {
    apply {
    }
}

V1Switch<packet_t, user_metadata_t>(TopParser(), vck(), ingress(), egress(), uck(), deparser()) main;
