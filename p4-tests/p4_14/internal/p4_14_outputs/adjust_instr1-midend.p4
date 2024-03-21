#include <core.p4>
#include <v1model.p4>

struct offset_meta_t {
    bit<6> x1;
    bit<6> x2;
}

header hdr_t {
    bit<32> f1;
    bit<32> f2;
    bit<32> f3;
    bit<4>  n1;
    bit<6>  x1;
    bit<6>  x2;
    bit<6>  x3;
    bit<6>  x4;
    bit<4>  n2;
}

struct metadata {
    @name(".offset_meta") 
    offset_meta_t offset_meta;
}

struct headers {
    @name(".hdr") 
    hdr_t hdr;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".start") state start {
        packet.extract<hdr_t>(hdr.hdr);
        transition accept;
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".NoAction") action NoAction_0() {
    }
    @name(".NoAction") action NoAction_4() {
    }
    @name(".NoAction") action NoAction_5() {
    }
    @name(".adjust_first") action adjust_first() {
        hdr.hdr.x1 = meta.offset_meta.x1;
        hdr.hdr.x2 = meta.offset_meta.x2;
    }
    @name(".adjust_first_ad") action adjust_first_ad(bit<6> param1, bit<6> param2) {
        hdr.hdr.x1 = param1;
        hdr.hdr.x2 = param2;
    }
    @name(".adjust_second") action adjust_second() {
        hdr.hdr.x3 = hdr.hdr.x1;
        hdr.hdr.x4 = hdr.hdr.x2;
    }
    @name(".set_offset") action set_offset(bit<6> off_val1, bit<6> off_val2) {
        meta.offset_meta.x1 = off_val1;
        meta.offset_meta.x2 = off_val2;
    }
    @name(".setport") action setport(bit<9> port) {
        standard_metadata.egress_spec = port;
    }
    @name(".adjust1") table adjust1_0 {
        actions = {
            adjust_first();
            adjust_first_ad();
            @defaultonly NoAction_0();
        }
        key = {
            hdr.hdr.f2: exact @name("hdr.f2") ;
        }
        default_action = NoAction_0();
    }
    @name(".adjust2") table adjust2_0 {
        actions = {
            adjust_second();
            @defaultonly NoAction_4();
        }
        key = {
            hdr.hdr.f3: exact @name("hdr.f3") ;
        }
        default_action = NoAction_4();
    }
    @name(".offset") table offset_0 {
        actions = {
            set_offset();
            @defaultonly NoAction_5();
        }
        key = {
            hdr.hdr.f1: exact @name("hdr.f1") ;
        }
        default_action = NoAction_5();
    }
    @name(".setting_port") table setting_port_0 {
        actions = {
            setport();
        }
        default_action = setport(9w1);
    }
    apply {
        offset_0.apply();
        adjust1_0.apply();
        adjust2_0.apply();
        setting_port_0.apply();
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit<hdr_t>(hdr.hdr);
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

