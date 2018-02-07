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

struct metadata {
}

struct headers {
    @name(".pkt") 
    pkt_t pkt;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".parse_ethernet") state parse_ethernet {
        packet.extract<pkt_t>(hdr.pkt);
        transition accept;
    }
    @name(".start") state start {
        transition parse_ethernet;
    }
}

struct tuple_0 {
    bit<16> field;
}

struct tuple_1 {
    tuple_0 field_0;
    bit<16> field_1;
    bit<32> field_2;
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".NoAction") action NoAction_0() {
    }
    @name(".action_0") action action_1() {
        hash<bit<8>, bit<8>, tuple_1, bit<16>>(hdr.pkt.field_i_8, HashAlgorithm.crc16, 8w0, { { hdr.pkt.field_e_16 }, hdr.pkt.field_f_16, hdr.pkt.field_a_32 }, 16w256);
    }
    @name(".do_nothing") action do_nothing_0() {
    }
    @name(".table_0") table table_0 {
        actions = {
            action_1();
            do_nothing_0();
            @defaultonly NoAction_0();
        }
        key = {
            hdr.pkt.field_a_32: ternary @name("pkt.field_a_32") ;
        }
        default_action = NoAction_0();
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

