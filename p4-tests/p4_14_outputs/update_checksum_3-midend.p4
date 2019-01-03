#include <core.p4>
#include <v1model.p4>

header data_t {
    bit<32> f1;
    bit<32> f2;
    bit<32> f3;
    bit<32> f4;
    bit<32> f5;
    bit<32> f6;
    bit<16> cksum;
}

struct metadata {
}

struct headers {
    @name(".data1") 
    data_t data1;
    @name(".data2") 
    data_t data2;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".start") state start {
        packet.extract<data_t>(hdr.data1);
        packet.extract<data_t>(hdr.data2);
        transition accept;
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".NoAction") action NoAction_0() {
    }
    @name(".modify_data1") action modify_data1() {
        hdr.data1.f1 = 32w0x1;
        hdr.data1.f2 = 32w0x10;
        hdr.data1.f3 = 32w0x100;
        hdr.data1.f4 = 32w0x1000;
        hdr.data1.f5 = 32w0x10000;
        hdr.data1.f6 = 32w0x100000;
    }
    @name(".modify_data2") action modify_data2() {
        hdr.data2.f5 = 32w0xbabebabe;
        hdr.data2.f6 = 32w0xfafafafa;
    }
    @name(".noop") action noop() {
    }
    @name(".test1") table test1_0 {
        actions = {
            modify_data1();
            modify_data2();
            noop();
            @defaultonly NoAction_0();
        }
        key = {
            hdr.data1.f1: exact @name("data1.f1") ;
        }
        default_action = NoAction_0();
    }
    apply {
        test1_0.apply();
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".set_port") action set_port() {
        standard_metadata.egress_spec = 9w0x2;
    }
    @name(".set_port") table set_port_2 {
        actions = {
            set_port();
        }
        default_action = set_port();
    }
    apply {
        set_port_2.apply();
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit<data_t>(hdr.data1);
        packet.emit<data_t>(hdr.data2);
    }
}

control verifyChecksum(inout headers hdr, inout metadata meta) {
    apply {
    }
}

struct tuple_0 {
    bit<32> field;
    bit<32> field_0;
    bit<32> field_1;
    bit<32> field_2;
    bit<32> field_3;
    bit<32> field_4;
}

control computeChecksum(inout headers hdr, inout metadata meta) {
    apply {
        update_checksum<tuple_0, bit<16>>(true, { hdr.data2.f1, hdr.data2.f2, hdr.data2.f3, hdr.data2.f4, hdr.data2.f5, hdr.data2.f6 }, hdr.data2.cksum, HashAlgorithm.csum16);
    }
}

V1Switch<headers, metadata>(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;

