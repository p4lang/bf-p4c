#include <core.p4>
#include <v1model.p4>

header pkt_t {
    bit<32> field_a_32;
    bit<32> field_b_32;
    bit<32> field_c_32;
    bit<32> field_d_32;
    bit<16> field_e_16;
    bit<16> field_f_16;
    bit<16> field_g_16;
    bit<16> field_h_16;
    bit<8>  field_i_8;
    bit<8>  field_j_8;
    bit<8>  field_k_8;
    bit<8>  field_l_8;
}

header tags_t {
    bit<8>  field_a_8;
    bit<12> field_b_12;
    bit<4>  field_c_4;
    bit<8>  field_d_8;
}

struct metadata {
}

struct headers {
    @name(".pkt") 
    pkt_t     pkt;
    @name(".tags") 
    tags_t[5] tags;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".parse_rest") state parse_rest {
        packet.extract(hdr.tags[1]);
        packet.extract(hdr.tags[2]);
        packet.extract(hdr.tags[3]);
        packet.extract(hdr.tags[4]);
        transition accept;
    }
    @name(".parse_test") state parse_test {
        packet.extract(hdr.pkt);
        packet.extract(hdr.tags[0]);
        transition select(hdr.pkt.field_k_8) {
            8w0: parse_rest;
            default: accept;
        }
    }
    @name(".start") state start {
        transition parse_test;
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".push_action") action push_action() {
        {
            hdr.tags.push_front(3);
            hdr.tags[0].setValid();
            hdr.tags[1].setValid();
            hdr.tags[2].setValid();
        }
    }
    @name(".pop_action") action pop_action() {
        hdr.tags.pop_front(4);
    }
    @name(".table_0") table table_0 {
        actions = {
            push_action;
            pop_action;
        }
        key = {
            hdr.pkt.field_a_32: exact;
        }
        size = 1024;
    }
    apply {
        table_0.apply();
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit(hdr.pkt);
        packet.emit(hdr.tags[0]);
        packet.emit(hdr.tags[1]);
        packet.emit(hdr.tags[2]);
        packet.emit(hdr.tags[3]);
        packet.emit(hdr.tags[4]);
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

