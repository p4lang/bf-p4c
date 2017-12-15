#include <core.p4>
#include <v1model.p4>

struct meta_t {
    bit<16> hash_1;
}

header pkt_t {
    bit<32> field_a_32;
    int<32> field_b_32;
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
    int<32> field_x_32;
}

struct metadata {
    @name(".meta") 
    meta_t meta;
}

struct headers {
    @name(".pkt") 
    pkt_t pkt;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".parse_ethernet") state parse_ethernet {
        packet.extract(hdr.pkt);
        transition accept;
    }
    @name(".start") state start {
        transition parse_ethernet;
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".action_0") action action_0() {
        hash(meta.meta.hash_1, HashAlgorithm.crc16, (bit<16>)0, { hdr.pkt.field_c_32, hdr.pkt.field_d_32 }, (bit<32>)16777216);
    }
    @name(".do_nothing") action do_nothing() {
    }
    @name(".table_0") table table_0 {
        actions = {
            action_0;
            do_nothing;
        }
        key = {
            hdr.pkt.field_g_16: ternary;
        }
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

