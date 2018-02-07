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
        packet.extract<banneker_t>(hdr.banneker);
        transition accept;
    }
    @name(".start") state start {
        transition parse_banneker;
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".NoAction") action NoAction_0() {
    }
    @name(".NoAction") action NoAction_6() {
    }
    @name(".NoAction") action NoAction_7() {
    }
    @name(".NoAction") action NoAction_8() {
    }
    @name(".NoAction") action NoAction_9() {
    }
    @name(".banneker_charisma") action banneker_charisma_0() {
        hdr.banneker.banneker_padding = 2w0;
        hdr.banneker.reissues = hdr.banneker.reissues + 31w31;
    }
    @name(".banneker_charisma") action banneker_charisma_2() {
        hdr.banneker.banneker_padding = 2w0;
        hdr.banneker.reissues = hdr.banneker.reissues + 31w31;
    }
    @name(".banneker_monicker") action banneker_monicker_0() {
        hdr.banneker.reissues = hdr.banneker.reissues + 31w2147483600;
    }
    @name(".banneker_hamlets") action banneker_hamlets_0() {
        hdr.banneker.reissues = hdr.banneker.reissues + 31w59;
        hdr.banneker.downbeat = 23w56;
    }
    @name(".banneker_acquisitions") action banneker_acquisitions_0() {
        hdr.banneker.reissues = 31w25;
        hdr.banneker.downbeat = hdr.banneker.downbeat + 23w8388566;
    }
    @name(".banneker_acquisitions") action banneker_acquisitions_2() {
        hdr.banneker.reissues = 31w25;
        hdr.banneker.downbeat = hdr.banneker.downbeat + 23w8388566;
    }
    @name(".banneker_defections") action banneker_defections_0() {
        hdr.banneker.reissues = hdr.banneker.reissues + 31w38;
        hdr.banneker.banneker_padding = hdr.banneker.banneker_padding + 2w1;
    }
    @name(".banneker_defections") action banneker_defections_2() {
        hdr.banneker.reissues = hdr.banneker.reissues + 31w38;
        hdr.banneker.banneker_padding = hdr.banneker.banneker_padding + 2w1;
    }
    @name(".allegorys") table allegorys {
        actions = {
            banneker_charisma_0();
            @defaultonly NoAction_0();
        }
        key = {
            hdr.banneker.reissues: exact @name("banneker.reissues") ;
            hdr.banneker.downbeat: ternary @name("banneker.downbeat") ;
        }
        size = 5;
        default_action = NoAction_0();
    }
    @name(".bozos") table bozos {
        actions = {
            banneker_monicker_0();
            banneker_charisma_2();
            banneker_hamlets_0();
            @defaultonly NoAction_6();
        }
        key = {
            hdr.banneker.reissues        : lpm @name("banneker.reissues") ;
            hdr.banneker.downbeat        : exact @name("banneker.downbeat") ;
            hdr.banneker.banneker_padding: exact @name("banneker.banneker_padding") ;
        }
        size = 4;
        default_action = NoAction_6();
    }
    @name(".probables") table probables {
        actions = {
            banneker_acquisitions_0();
            @defaultonly NoAction_7();
        }
        key = {
            hdr.banneker.downbeat        : lpm @name("banneker.downbeat") ;
            hdr.banneker.banneker_padding: range @name("banneker.banneker_padding") ;
            hdr.banneker.reissues        : exact @name("banneker.reissues") ;
        }
        default_action = NoAction_7();
    }
    @name(".scrambles") table scrambles {
        actions = {
            banneker_acquisitions_2();
            banneker_defections_0();
            @defaultonly NoAction_8();
        }
        key = {
            hdr.banneker.banneker_padding: lpm @name("banneker.banneker_padding") ;
            hdr.banneker.downbeat        : range @name("banneker.downbeat") ;
        }
        size = 4;
        default_action = NoAction_8();
    }
    @name(".serenenesss") table serenenesss {
        actions = {
            banneker_defections_2();
            @defaultonly NoAction_9();
        }
        key = {
            hdr.banneker.reissues        : range @name("banneker.reissues") ;
            hdr.banneker.banneker_padding: ternary @name("banneker.banneker_padding") ;
        }
        size = 4;
        default_action = NoAction_9();
    }
    apply {
        allegorys.apply();
        if (!hdr.banneker.isValid()) 
            probables.apply();
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
        packet.emit<banneker_t>(hdr.banneker);
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

