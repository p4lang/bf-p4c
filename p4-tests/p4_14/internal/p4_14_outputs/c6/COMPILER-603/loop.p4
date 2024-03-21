#include <core.p4>
#include <v1model.p4>

header mpls_t {
    bit<20> label;
    bit<3>  exp;
    bit<1>  bos;
    bit<8>  ttl;
}

struct metadata {
}

struct headers {
    @name(".mpls_bos") 
    mpls_t    mpls_bos;
    @name(".mpls") 
    mpls_t[4] mpls;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".parse_mpls") state parse_mpls {
        transition select((packet.lookahead<bit<24>>())[0:0]) {
            1w0: parse_mpls_no_bos;
            1w1: parse_mpls_bos;
        }
    }
    @name(".parse_mpls_bos") state parse_mpls_bos {
        packet.extract(hdr.mpls_bos);
        transition accept;
    }
    @name(".parse_mpls_no_bos") state parse_mpls_no_bos {
        packet.extract(hdr.mpls.next);
        transition parse_mpls;
    }
    @name(".start") state start {
        transition parse_mpls;
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".do_nothing") action do_nothing() {
    }
    @name(".action_1") action action_1() {
        hdr.mpls_bos.label = 20w0;
    }
    @name(".table1") table table1 {
        actions = {
            do_nothing;
            action_1;
        }
        key = {
            hdr.mpls_bos.isValid(): exact;
        }
    }
    apply {
        table1.apply();
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit(hdr.mpls);
        packet.emit(hdr.mpls_bos);
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

