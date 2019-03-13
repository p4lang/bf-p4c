#include <core.p4>
#include <v1model.p4>

header mini_t {
    bit<48> a;
    bit<48> b;
    bit<8>  c;
    bit<16> csum;
}

struct headers_t {
    mini_t mini;
}

struct metadata_t {
}

parser ParserImpl(packet_in packet, out headers_t hdr, inout metadata_t meta, inout standard_metadata_t standard_metadata) {
    state start {
        packet.extract<mini_t>(hdr.mini);
        transition accept;
    }
}

control ingress(inout headers_t hdr, inout metadata_t meta, inout standard_metadata_t standard_metadata) {
    bool hasExited;
    @hidden action act() {
        mark_to_drop();
        hasExited = true;
    }
    @hidden action act_0() {
        hasExited = false;
    }
    @hidden action act_1() {
        hdr.mini.c = hdr.mini.c + 8w255;
    }
    @hidden action act_2() {
        standard_metadata.egress_spec = 9w2;
    }
    @hidden table tbl_act {
        actions = {
            act_0();
        }
        const default_action = act_0();
    }
    @hidden table tbl_act_0 {
        actions = {
            act();
        }
        const default_action = act();
    }
    @hidden table tbl_act_1 {
        actions = {
            act_1();
        }
        const default_action = act_1();
    }
    @hidden table tbl_act_2 {
        actions = {
            act_2();
        }
        const default_action = act_2();
    }
    apply {
        tbl_act.apply();
        if (standard_metadata.checksum_error == 1w1) {
            tbl_act_0.apply();
        }
        if (!hasExited) {
            if (hdr.mini.isValid()) 
                tbl_act_1.apply();
            tbl_act_2.apply();
        }
    }
}

control egress(inout headers_t hdr, inout metadata_t meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control DeparserImpl(packet_out packet, in headers_t hdr) {
    apply {
        packet.emit<mini_t>(hdr.mini);
    }
}

struct tuple_0 {
    bit<48> field;
    bit<48> field_0;
    bit<8>  field_1;
}

control verifyChecksum(inout headers_t hdr, inout metadata_t meta) {
    apply {
        verify_checksum<tuple_0, bit<16>>(hdr.mini.isValid(), { hdr.mini.a, hdr.mini.b, hdr.mini.c }, hdr.mini.csum, HashAlgorithm.csum16);
    }
}

control computeChecksum(inout headers_t hdr, inout metadata_t meta) {
    apply {
    }
}

V1Switch<headers_t, metadata_t>(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;

