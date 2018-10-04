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
        packet.extract(hdr.data);
        transition accept;
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    action setb1(bit<8> val) {
        hdr.data.b1 = val;
    }
    action noop() {
    }
    action set_flag1() {
        meta.flag1 = true;
    }
    action set_flag2() {
        meta.flag2 = true;
    }
    table flg1 {
        key = {
            hdr.data.f1[31:16]: exact;
        }
        actions = {
            set_flag1;
            noop;
        }
    }
    table flg2 {
        key = {
            hdr.data.f1[15:0]: exact;
        }
        actions = {
            set_flag2;
            noop;
        }
    }
    table test {
        key = {
            hdr.data.f1: ternary;
        }
        actions = {
            setb1;
            noop;
        }
        default_action = setb1(0xaa);
    }
    apply {
        standard_metadata.egress_spec = 2;
        flg1.apply();
        flg2.apply();
        if (hdr.data.f2[7:0] == 2 && hdr.data.f2[15:12] == 0 && meta.flag1 && meta.flag2) {
            test.apply();
        }
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit(hdr.data);
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

