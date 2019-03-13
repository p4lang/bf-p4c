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

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".NoAction") action NoAction_0() {
    }
    HashAlgorithm tmp_1;
    HashAlgorithm tmp_2;
    @name(".action_0") action action_3() {
        tmp_1 = custom_hash<>("identity_lsb");
        tmp_2 = tmp_1;
        hash<bit<32>, bit<31>, tuple<bit<16>, bit<16>>, bit<62>>(hdr.pkt.field_b_32, tmp_2, 31w0, { hdr.pkt.field_e_16, hdr.pkt.field_f_16 }, 62w2147483648);
        hdr.pkt.field_k_8 = 8w0;
    }
    @name(".action_1") action action_4() {
        tmp_1 = custom_hash<>("identity_lsb");
        tmp_2 = tmp_1;
        hash<bit<32>, bit<31>, tuple<bit<16>, bit<16>>, bit<62>>(hdr.pkt.field_b_32, tmp_2, 31w0, { hdr.pkt.field_e_16, hdr.pkt.field_f_16 }, 62w2147483648);
        hdr.pkt.field_k_8 = 8w1;
    }
    @name(".action_2") action action_5() {
        tmp_1 = custom_hash<>("identity_lsb");
        tmp_2 = tmp_1;
        hash<bit<32>, bit<31>, tuple<bit<16>, bit<16>>, bit<62>>(hdr.pkt.field_b_32, tmp_2, 31w0, { hdr.pkt.field_e_16, hdr.pkt.field_f_16 }, 62w2147483648);
        hdr.pkt.field_k_8 = 8w2;
    }
    @name(".table_0") table table_0 {
        actions = {
            action_3();
            action_4();
            action_5();
            @defaultonly NoAction_0();
        }
        key = {
            hdr.pkt.field_a_32: lpm @name("pkt.field_a_32") ;
        }
        size = 512;
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

