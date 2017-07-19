#include <core.p4>
#include <v1model.p4>

header pkt_t {
    bit<32> field_a_32;
    bit<32> field_b_32;
    bit<16> field_e_16;
    bit<16> field_f_16;
    bit<8>  field_i_8;
    bit<8>  field_j_8;
}

struct metadata {
}

struct headers {
    @name("pkt") 
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
    bit<16> tmp;
    tuple<bit<16>> tmp_0;
    @name(".action_0") action action_1() {
        tmp_0 = { hdr.pkt.field_f_16 };
        hash<bit<16>, bit<16>, tuple<bit<16>>, bit<32>>(tmp, HashAlgorithm.identity, 16w0, tmp_0, 32w65536);
        hdr.pkt.field_e_16 = tmp;
    }
    @name(".table_0") table table_1 {
        actions = {
            action_1();
            @defaultonly NoAction();
        }
        default_action = NoAction();
    }
    apply {
        table_1.apply();
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

control verifyChecksum(in headers hdr, inout metadata meta) {
    apply {
    }
}

control computeChecksum(inout headers hdr, inout metadata meta) {
    apply {
    }
}

V1Switch<headers, metadata>(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;
