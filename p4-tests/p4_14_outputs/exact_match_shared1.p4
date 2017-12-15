#include <core.p4>
#include <v1model.p4>

header data_t {
    bit<8> b1;
    bit<8> b2;
    bit<8> b3;
    bit<8> b4;
    bit<8> b5;
    bit<8> b6;
    bit<8> b7;
    bit<8> b8;
    bit<8> b9;
}

struct metadata {
}

struct headers {
    @name(".data") 
    data_t data;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".start") state start {
        packet.extract(hdr.data);
        transition accept;
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".noop") action noop() {
    }
    @name(".test1") table test1 {
        actions = {
            noop;
        }
        key = {
            hdr.data.b1: exact;
        }
    }
    @name(".test2") table test2 {
        actions = {
            noop;
        }
        key = {
            hdr.data.b2: exact;
        }
    }
    @name(".test3") table test3 {
        actions = {
            noop;
        }
        key = {
            hdr.data.b3: exact;
        }
    }
    @name(".test4") table test4 {
        actions = {
            noop;
        }
        key = {
            hdr.data.b4: exact;
        }
    }
    @name(".test5") table test5 {
        actions = {
            noop;
        }
        key = {
            hdr.data.b5: exact;
        }
    }
    @name(".test6") table test6 {
        actions = {
            noop;
        }
        key = {
            hdr.data.b6: exact;
        }
    }
    @name(".test7") table test7 {
        actions = {
            noop;
        }
        key = {
            hdr.data.b7: exact;
        }
    }
    @name(".test8") table test8 {
        actions = {
            noop;
        }
        key = {
            hdr.data.b8: exact;
            hdr.data.b9: exact;
        }
    }
    apply {
        test1.apply();
        test2.apply();
        test3.apply();
        test4.apply();
        test5.apply();
        test6.apply();
        test7.apply();
        test8.apply();
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

