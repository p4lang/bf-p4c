#include <v1model.p4>

header mini_t {
    bit<48> a;
    bit<48> b;
    bit<8> c;
    bit<16> csum;
}

struct headers_t {
    mini_t mini;
}

struct metadata_t { }

parser ParserImpl(packet_in packet, out headers_t hdr, inout metadata_t meta,
                  inout standard_metadata_t standard_metadata) {
    state start {
        packet.extract(hdr.mini);
        transition accept;
    }
}

control ingress(inout headers_t hdr, inout metadata_t meta,
                inout standard_metadata_t standard_metadata) {
    apply {
        // drop packet if checksum error
        if (standard_metadata.checksum_error == 1w1) {
            mark_to_drop();
            exit;
        }
        if (hdr.mini.isValid()) {
            hdr.mini.c = hdr.mini.c - 1;
        }
        // loopback packet
        standard_metadata.egress_spec = 2;
    }
}

control egress(inout headers_t hdr, inout metadata_t meta, inout standard_metadata_t standard_metadata) {
    apply { }
}

control DeparserImpl(packet_out packet, in headers_t hdr) {
    apply {
        packet.emit(hdr.mini);
    }
}

control verifyChecksum(inout headers_t hdr, inout metadata_t meta) {
    apply {
        verify_checksum(hdr.mini.isValid(),
            {
                hdr.mini.a,
                hdr.mini.b,
                hdr.mini.c
            },
            hdr.mini.csum,
            HashAlgorithm.csum16
        );
    }
}

control computeChecksum(inout headers_t hdr, inout metadata_t meta) {
    apply { }
}

V1Switch(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;
