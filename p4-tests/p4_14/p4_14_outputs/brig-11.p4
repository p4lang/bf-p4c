#include <core.p4>
#include <v1model.p4>

header banneker_t {
    bit<23> downbeat;
    bit<31> reissues;
    bit<2>  banneker_padding;
}

struct metadata {
}

struct headers {
    @name(".banneker") 
    banneker_t banneker;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".parse_banneker") state parse_banneker {
        packet.extract(hdr.banneker);
        transition accept;
    }
    @name(".start") state start {
        transition parse_banneker;
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".banneker_charisma") action banneker_charisma() {
        hdr.banneker.banneker_padding = 2w0;
        hdr.banneker.reissues = hdr.banneker.reissues + 31w31;
    }
    @name(".banneker_monicker") action banneker_monicker() {
        hdr.banneker.reissues = hdr.banneker.reissues - 31w48;
    }
    @name(".banneker_hamlets") action banneker_hamlets() {
        hdr.banneker.reissues = hdr.banneker.reissues + 31w59;
        hdr.banneker.downbeat = 23w56;
    }
    @name(".banneker_acquisitions") action banneker_acquisitions() {
        hdr.banneker.reissues = 31w25;
        hdr.banneker.downbeat = hdr.banneker.downbeat - 23w42;
    }
    @name(".banneker_defections") action banneker_defections() {
        hdr.banneker.reissues = hdr.banneker.reissues + 31w38;
        hdr.banneker.banneker_padding = hdr.banneker.banneker_padding - 2w3;
    }
    @name(".allegorys") table allegorys {
        actions = {
            banneker_charisma;
        }
        key = {
            hdr.banneker.reissues: exact;
            hdr.banneker.downbeat: ternary;
        }
        size = 5;
    }
    @name(".bozos") table bozos {
        actions = {
            banneker_monicker;
            banneker_charisma;
            banneker_hamlets;
        }
        key = {
            hdr.banneker.reissues        : lpm;
            hdr.banneker.downbeat        : exact;
            hdr.banneker.banneker_padding: exact;
        }
        size = 4;
    }
    @name(".probables") table probables {
        actions = {
            banneker_acquisitions;
        }
        key = {
            hdr.banneker.downbeat        : lpm;
            hdr.banneker.banneker_padding: range;
            hdr.banneker.reissues        : exact;
        }
    }
    @name(".scrambles") table scrambles {
        actions = {
            banneker_acquisitions;
            banneker_defections;
        }
        key = {
            hdr.banneker.banneker_padding: lpm;
            hdr.banneker.downbeat        : range;
        }
        size = 4;
    }
    @name(".serenenesss") table serenenesss {
        actions = {
            banneker_defections;
        }
        key = {
            hdr.banneker.reissues        : range;
            hdr.banneker.banneker_padding: ternary;
        }
        size = 4;
    }
    apply {
        allegorys.apply();
        if (!hdr.banneker.isValid() || false) {
            probables.apply();
        }
        else {
            serenenesss.apply();
            scrambles.apply();
            bozos.apply();
        }
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit(hdr.banneker);
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

