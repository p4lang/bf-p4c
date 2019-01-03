#include <core.p4>
#include <v1model.p4>

struct metadata {
    bool flag1;
    bool flag2;
}

header data_t {
    bit<32> f1;
    bit<32> f2;
    bit<16> h1;
    bit<8>  b1;
    bit<8>  b2;
}

struct headers {
    data_t data;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    state start {
        packet.extract<data_t>(hdr.data);
        transition accept;
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".NoAction") action NoAction_0() {
    }
    @name(".NoAction") action NoAction_3() {
    }
    @name("ingress.setb1") action setb1(bit<8> val) {
        hdr.data.b1 = val;
    }
    @name("ingress.noop") action noop() {
    }
    @name("ingress.noop") action noop_3() {
    }
    @name("ingress.noop") action noop_4() {
    }
    @name("ingress.set_flag1") action set_flag1() {
        meta.flag1 = true;
    }
    @name("ingress.set_flag2") action set_flag2() {
        meta.flag2 = true;
    }
    @name("ingress.flg1") table flg1_0 {
        key = {
            hdr.data.f1[31:16]: exact @name("hdr.data.f1[31:16]") ;
        }
        actions = {
            set_flag1();
            noop();
            @defaultonly NoAction_0();
        }
        default_action = NoAction_0();
    }
    @name("ingress.flg2") table flg2_0 {
        key = {
            hdr.data.f1[15:0]: exact @name("hdr.data.f1[15:0]") ;
        }
        actions = {
            set_flag2();
            noop_3();
            @defaultonly NoAction_3();
        }
        default_action = NoAction_3();
    }
    @name("ingress.test") table test_0 {
        key = {
            hdr.data.f1: ternary @name("hdr.data.f1") ;
        }
        actions = {
            setb1();
            noop_4();
        }
        default_action = setb1(8w0xaa);
    }
    apply {
        standard_metadata.egress_spec = 9w2;
        flg1_0.apply();
        flg2_0.apply();
        if (hdr.data.f2[7:0] == 8w2 && hdr.data.f2[15:12] == 4w0 && meta.flag1 && meta.flag2) 
            test_0.apply();
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit<data_t>(hdr.data);
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

