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
    @name("pkt") 
    pkt_t pkt;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name("parse_ethernet") state parse_ethernet {
        packet.extract<pkt_t>(hdr.pkt);
        transition accept;
    }
    @name("start") state start {
        transition parse_ethernet;
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".action_0") action action_2() {
    }
    @name(".action_1") action action_3() {
    }
    @name("table_0") table table_10 {
        actions = {
            action_2();
            action_3();
            @default_only NoAction();
        }
        key = {
            hdr.pkt.field_i_8: exact @name("hdr.pkt.field_i_8") ;
        }
        size = 256;
        default_action = NoAction();
    }
    @name("table_1") table table_11 {
        actions = {
            action_2();
            action_3();
            @default_only NoAction();
        }
        key = {
            hdr.pkt.field_i_8: exact @name("hdr.pkt.field_i_8") ;
        }
        size = 256;
        default_action = NoAction();
    }
    @name("table_2") table table_12 {
        actions = {
            action_2();
            action_3();
            @default_only NoAction();
        }
        key = {
            hdr.pkt.field_i_8: exact @name("hdr.pkt.field_i_8") ;
        }
        size = 256;
        default_action = NoAction();
    }
    @name("table_3") table table_13 {
        actions = {
            action_2();
            action_3();
            @default_only NoAction();
        }
        key = {
            hdr.pkt.field_i_8: exact @name("hdr.pkt.field_i_8") ;
        }
        size = 256;
        default_action = NoAction();
    }
    @name("table_4") table table_14 {
        actions = {
            action_2();
            action_3();
            @default_only NoAction();
        }
        key = {
            hdr.pkt.field_i_8: exact @name("hdr.pkt.field_i_8") ;
        }
        size = 256;
        default_action = NoAction();
    }
    @name("table_5") table table_15 {
        actions = {
            action_2();
            action_3();
            @default_only NoAction();
        }
        key = {
            hdr.pkt.field_i_8: exact @name("hdr.pkt.field_i_8") ;
        }
        size = 256;
        default_action = NoAction();
    }
    @name("table_6") table table_16 {
        actions = {
            action_2();
            action_3();
            @default_only NoAction();
        }
        key = {
            hdr.pkt.field_i_8: exact @name("hdr.pkt.field_i_8") ;
        }
        size = 256;
        default_action = NoAction();
    }
    @name("table_7") table table_17 {
        actions = {
            action_2();
            action_3();
            @default_only NoAction();
        }
        key = {
            hdr.pkt.field_i_8: exact @name("hdr.pkt.field_i_8") ;
        }
        size = 256;
        default_action = NoAction();
    }
    @name("table_8") table table_18 {
        actions = {
            action_2();
            action_3();
            @default_only NoAction();
        }
        key = {
            hdr.pkt.field_i_8: exact @name("hdr.pkt.field_i_8") ;
        }
        size = 256;
        default_action = NoAction();
    }
    @name("table_9") table table_19 {
        actions = {
            action_2();
            action_3();
            @default_only NoAction();
        }
        key = {
            hdr.pkt.field_a_32: exact @name("hdr.pkt.field_a_32") ;
        }
        size = 512;
        default_action = NoAction();
    }
    @ways(2) @name("table_a") table table_a_0 {
        actions = {
            action_2();
            action_3();
            @default_only NoAction();
        }
        key = {
            hdr.pkt.field_a_32: exact @name("hdr.pkt.field_a_32") ;
        }
        size = 1024;
        default_action = NoAction();
    }
    @name("table_b") table table_b_0 {
        actions = {
            action_2();
            action_3();
            @default_only NoAction();
        }
        key = {
            hdr.pkt.field_j_8: exact @name("hdr.pkt.field_j_8") ;
        }
        size = 256;
        default_action = NoAction();
    }
    @name("table_c") table table_c_0 {
        actions = {
            action_2();
            action_3();
            @default_only NoAction();
        }
        key = {
            hdr.pkt.field_k_8: exact @name("hdr.pkt.field_k_8") ;
        }
        size = 256;
        default_action = NoAction();
    }
    @name("table_d") table table_d_0 {
        actions = {
            action_2();
            action_3();
            @default_only NoAction();
        }
        key = {
            hdr.pkt.field_b_32: exact @name("hdr.pkt.field_b_32") ;
        }
        size = 1024;
        default_action = NoAction();
    }
    @name("table_e") table table_e_0 {
        actions = {
            action_2();
            action_3();
            @default_only NoAction();
        }
        key = {
            hdr.pkt.field_j_8: exact @name("hdr.pkt.field_j_8") ;
        }
        size = 256;
        default_action = NoAction();
    }
    @name("table_f") table table_f_0 {
        actions = {
            action_2();
            action_3();
            @default_only NoAction();
        }
        key = {
            hdr.pkt.field_k_8: exact @name("hdr.pkt.field_k_8") ;
        }
        size = 256;
        default_action = NoAction();
    }
    apply {
        table_10.apply();
        table_11.apply();
        table_12.apply();
        table_13.apply();
        table_14.apply();
        table_15.apply();
        table_16.apply();
        table_17.apply();
        table_18.apply();
        table_19.apply();
        table_a_0.apply();
        table_b_0.apply();
        table_c_0.apply();
        table_d_0.apply();
        table_e_0.apply();
        table_f_0.apply();
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
