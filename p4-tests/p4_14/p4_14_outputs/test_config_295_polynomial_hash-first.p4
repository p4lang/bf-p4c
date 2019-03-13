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
    @name(".parse_pkt") state parse_pkt {
        packet.extract<pkt_t>(hdr.pkt);
        transition accept;
    }
    @name(".start") state start {
        transition parse_pkt;
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".a0") action a0() {
        hash<bit<32>, bit<32>, tuple<bit<32>, bit<32>, bit<16>, bit<16>, bit<8>, bit<8>>, bit<64>>(hdr.pkt.field_d_32, custom_hash<>("poly_0x104c11db7_init_0x0_xout_0xffffffff"), 32w0, { hdr.pkt.field_a_32, hdr.pkt.field_b_32, hdr.pkt.field_e_16, hdr.pkt.field_f_16, hdr.pkt.field_i_8, hdr.pkt.field_j_8 }, 64w2147483648);
    }
    @name(".do_nothing") action do_nothing() {
    }
    @name(".a1") action a1() {
        hash<bit<16>, bit<16>, tuple<bit<32>, bit<32>, bit<16>, bit<16>, bit<8>, bit<8>>, bit<32>>(hdr.pkt.field_h_16, custom_hash<>("poly_0x11021_not_rev_xout_0x0"), 16w0, { hdr.pkt.field_a_32, hdr.pkt.field_b_32, hdr.pkt.field_e_16, hdr.pkt.field_f_16, hdr.pkt.field_i_8, hdr.pkt.field_j_8 }, 32w0x10000);
    }
    @name(".a2") action a2() {
        hash<bit<16>, bit<16>, tuple<bit<32>, bit<32>, bit<16>, bit<16>, bit<8>, bit<8>>, bit<32>>(hdr.pkt.field_g_16, custom_hash<>("crc_8_extend"), 16w0, { hdr.pkt.field_a_32, hdr.pkt.field_b_32, hdr.pkt.field_e_16, hdr.pkt.field_f_16, hdr.pkt.field_i_8, hdr.pkt.field_j_8 }, 32w0x10000);
    }
    @name(".a3") action a3() {
        hash<bit<8>, bit<8>, tuple<bit<32>, bit<32>, bit<16>, bit<16>, bit<8>, bit<8>>, bit<16>>(hdr.pkt.field_k_8, custom_hash<>("poly_0x11021_not_rev_xout_0x0_msb"), 8w0, { hdr.pkt.field_a_32, hdr.pkt.field_b_32, hdr.pkt.field_e_16, hdr.pkt.field_f_16, hdr.pkt.field_i_8, hdr.pkt.field_j_8 }, 16w0x100);
    }
    @name(".table_0") table table_0 {
        actions = {
            a0();
            do_nothing();
            @defaultonly NoAction();
        }
        key = {
            hdr.pkt.field_a_32: lpm @name("pkt.field_a_32") ;
        }
        size = 512;
        default_action = NoAction();
    }
    @name(".table_1") table table_1 {
        actions = {
            a1();
            do_nothing();
            @defaultonly NoAction();
        }
        key = {
            hdr.pkt.field_a_32: lpm @name("pkt.field_a_32") ;
        }
        size = 512;
        default_action = NoAction();
    }
    @stage(1) @name(".table_2") table table_2 {
        actions = {
            a2();
            do_nothing();
            @defaultonly NoAction();
        }
        key = {
            hdr.pkt.field_a_32: lpm @name("pkt.field_a_32") ;
        }
        size = 512;
        default_action = NoAction();
    }
    @stage(2) @name(".table_3") table table_3 {
        actions = {
            a3();
            do_nothing();
            @defaultonly NoAction();
        }
        key = {
            hdr.pkt.field_a_32: lpm @name("pkt.field_a_32") ;
        }
        size = 512;
        default_action = NoAction();
    }
    apply {
        table_0.apply();
        table_1.apply();
        table_2.apply();
        table_3.apply();
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

