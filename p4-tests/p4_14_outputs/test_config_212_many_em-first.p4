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
    @name(".action_0") action action_0() {
    }
    @name(".action_1") action action_1() {
    }
    @name(".table_0") table table_0 {
        actions = {
            action_0();
            action_1();
            @defaultonly NoAction();
        }
        key = {
            hdr.pkt.field_i_8: exact @name("pkt.field_i_8") ;
        }
        size = 256;
        default_action = NoAction();
    }
    @name(".table_1") table table_1 {
        actions = {
            action_0();
            action_1();
            @defaultonly NoAction();
        }
        key = {
            hdr.pkt.field_i_8: exact @name("pkt.field_i_8") ;
        }
        size = 256;
        default_action = NoAction();
    }
    @name(".table_2") table table_2 {
        actions = {
            action_0();
            action_1();
            @defaultonly NoAction();
        }
        key = {
            hdr.pkt.field_i_8: exact @name("pkt.field_i_8") ;
        }
        size = 256;
        default_action = NoAction();
    }
    @name(".table_3") table table_3 {
        actions = {
            action_0();
            action_1();
            @defaultonly NoAction();
        }
        key = {
            hdr.pkt.field_i_8: exact @name("pkt.field_i_8") ;
        }
        size = 256;
        default_action = NoAction();
    }
    @name(".table_4") table table_4 {
        actions = {
            action_0();
            action_1();
            @defaultonly NoAction();
        }
        key = {
            hdr.pkt.field_i_8: exact @name("pkt.field_i_8") ;
        }
        size = 256;
        default_action = NoAction();
    }
    @name(".table_5") table table_5 {
        actions = {
            action_0();
            action_1();
            @defaultonly NoAction();
        }
        key = {
            hdr.pkt.field_i_8: exact @name("pkt.field_i_8") ;
        }
        size = 256;
        default_action = NoAction();
    }
    @name(".table_6") table table_6 {
        actions = {
            action_0();
            action_1();
            @defaultonly NoAction();
        }
        key = {
            hdr.pkt.field_i_8: exact @name("pkt.field_i_8") ;
        }
        size = 256;
        default_action = NoAction();
    }
    @name(".table_7") table table_7 {
        actions = {
            action_0();
            action_1();
            @defaultonly NoAction();
        }
        key = {
            hdr.pkt.field_i_8: exact @name("pkt.field_i_8") ;
        }
        size = 256;
        default_action = NoAction();
    }
    @name(".table_8") table table_8 {
        actions = {
            action_0();
            action_1();
            @defaultonly NoAction();
        }
        key = {
            hdr.pkt.field_i_8: exact @name("pkt.field_i_8") ;
        }
        size = 256;
        default_action = NoAction();
    }
    @name(".table_9") table table_9 {
        actions = {
            action_0();
            action_1();
            @defaultonly NoAction();
        }
        key = {
            hdr.pkt.field_a_32: exact @name("pkt.field_a_32") ;
        }
        size = 512;
        default_action = NoAction();
    }
    @ways(2) @name(".table_a") table table_a {
        actions = {
            action_0();
            action_1();
            @defaultonly NoAction();
        }
        key = {
            hdr.pkt.field_a_32: exact @name("pkt.field_a_32") ;
        }
        size = 1024;
        default_action = NoAction();
    }
    @name(".table_b") table table_b {
        actions = {
            action_0();
            action_1();
            @defaultonly NoAction();
        }
        key = {
            hdr.pkt.field_j_8: exact @name("pkt.field_j_8") ;
        }
        size = 256;
        default_action = NoAction();
    }
    @name(".table_c") table table_c {
        actions = {
            action_0();
            action_1();
            @defaultonly NoAction();
        }
        key = {
            hdr.pkt.field_k_8: exact @name("pkt.field_k_8") ;
        }
        size = 256;
        default_action = NoAction();
    }
    @name(".table_d") table table_d {
        actions = {
            action_0();
            action_1();
            @defaultonly NoAction();
        }
        key = {
            hdr.pkt.field_b_32: exact @name("pkt.field_b_32") ;
        }
        size = 1024;
        default_action = NoAction();
    }
    @name(".table_e") table table_e {
        actions = {
            action_0();
            action_1();
            @defaultonly NoAction();
        }
        key = {
            hdr.pkt.field_j_8: exact @name("pkt.field_j_8") ;
        }
        size = 256;
        default_action = NoAction();
    }
    @name(".table_f") table table_f {
        actions = {
            action_0();
            action_1();
            @defaultonly NoAction();
        }
        key = {
            hdr.pkt.field_k_8: exact @name("pkt.field_k_8") ;
        }
        size = 256;
        default_action = NoAction();
    }
    apply {
        table_0.apply();
        table_1.apply();
        table_2.apply();
        table_3.apply();
        table_4.apply();
        table_5.apply();
        table_6.apply();
        table_7.apply();
        table_8.apply();
        table_9.apply();
        table_a.apply();
        table_b.apply();
        table_c.apply();
        table_d.apply();
        table_e.apply();
        table_f.apply();
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

