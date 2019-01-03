#include <core.p4>
#include <v1model.p4>

header pkt_t {
    bit<12> f1;
    bit<10> f2;
    bit<12> f3;
    bit<30> f4;
    bit<12> f5;
    bit<10> f6;
    bit<12> f7;
    bit<30> f8;
    bit<12> f9;
    bit<10> fa;
    bit<12> fb;
    bit<30> fc;
}

struct metadata {
}

struct headers {
    @name(".pkt") 
    pkt_t pkt;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".parse_pkt") state parse_pkt {
        packet.extract<pkt_t>(hdr.pkt);
        transition accept;
    }
    @name(".start") state start {
        transition parse_pkt;
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".setport") action setport(bit<9> port) {
        standard_metadata.egress_spec = port;
    }
    @name(".action_0") action action_0() {
        hdr.pkt.f1 = hdr.pkt.f5;
    }
    @name(".action_1") action action_1() {
        hdr.pkt.f1 = (bit<12>)hdr.pkt.f8;
    }
    @name(".action_2") action action_2() {
        hdr.pkt.f1 = hdr.pkt.f5;
        hdr.pkt.f2 = hdr.pkt.fa;
    }
    @name(".action_3") action action_3() {
        hdr.pkt.f1 = hdr.pkt.f5;
        hdr.pkt.f2 = hdr.pkt.f6;
        hdr.pkt.f3 = hdr.pkt.fb;
        hdr.pkt.f4 = hdr.pkt.fc;
    }
    @name(".setting_port") table setting_port {
        actions = {
            setport();
            @defaultonly NoAction();
        }
        key = {
            hdr.pkt.fc: exact @name("pkt.fc") ;
        }
        default_action = NoAction();
    }
    @name(".table_0") table table_0 {
        actions = {
            action_0();
            action_1();
            action_2();
            action_3();
            @defaultonly NoAction();
        }
        key = {
            hdr.pkt.f3: exact @name("pkt.f3") ;
            hdr.pkt.f4: exact @name("pkt.f4") ;
            hdr.pkt.f6: exact @name("pkt.f6") ;
            hdr.pkt.f7: exact @name("pkt.f7") ;
        }
        size = 1024;
        default_action = NoAction();
    }
    apply {
        table_0.apply();
        setting_port.apply();
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit<pkt_t>(hdr.pkt);
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

