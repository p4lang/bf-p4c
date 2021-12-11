#include <v1model.p4>

#define CPU_PORT 64

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
    ipv4_t  ipv4;
}

struct user_metadata_t {
    bit<8>  data;
}

// Declare user-defined errors that may be signaled during parsing
error {
    IPv4IncorrectVersion,
    IPv4ChecksumError,
    IPv4IncorrectOptions
}

parser TopParser(packet_in b, out packet_t p,
                 inout user_metadata_t m, inout standard_metadata_t meta)
{
    Checksum16() ck;  // instantiate checksum unit

    state start {
        b.extract(p.ipv4);
        verify(p.ipv4.version == 4w4, error.IPv4IncorrectVersion);
        verify(p.ipv4.ihl > 4w4, error.IPv4IncorrectOptions);
        // ck.clear();
        // ck.update(p.ip);
        // // Verify that packet checksum is zero
        // verify(ck.get() == 16w0, error.IPv4ChecksumError);
        transition accept;
    }
}

control ingress(inout packet_t p, inout user_metadata_t m,
                inout standard_metadata_t meta) {
    action sendToCPU() {
        meta.egress_spec = CPU_PORT;
    }
    action forward() {
        meta.egress_spec = 2;
    }
    action cloneToCPU() {
        // to be implemented when we figure out how to clone in P4_16
    }

    // table t {
    //     key = { p.ipv4.ihl : exact; }
    //     actions = {
    //         copyToCPU;
    //         forward;
    //     }
    // }

    apply {
        if(p.ipv4.ihl > 5) sendToCPU();
        else forward();
    }
}


control egress(inout packet_t hdrs, inout user_metadata_t m,
               inout standard_metadata_t meta) {
    apply { }
}

control deparser(packet_out b, in packet_t p) {
    apply {
        b.emit(p.ipv4);
    }
}

control vck(inout packet_t hdrs, inout user_metadata_t meta) {
    apply {}
}

control uck(inout packet_t hdrs, inout user_metadata_t meta) {
    apply {}
}

V1Switch(TopParser(), vck(), ingress(), egress(), uck(), deparser()) main;
