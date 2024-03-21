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
    @name(".NoAction") action NoAction_17() {
    }
    @name(".NoAction") action NoAction_18() {
    }
    @name(".NoAction") action NoAction_19() {
    }
    @name(".NoAction") action NoAction_20() {
    }
    @name(".NoAction") action NoAction_21() {
    }
    @name(".NoAction") action NoAction_22() {
    }
    @name(".NoAction") action NoAction_23() {
    }
    @name(".NoAction") action NoAction_24() {
    }
    @name(".NoAction") action NoAction_25() {
    }
    @name(".NoAction") action NoAction_26() {
    }
    @name(".NoAction") action NoAction_27() {
    }
    @name(".NoAction") action NoAction_28() {
    }
    @name(".NoAction") action NoAction_29() {
    }
    @name(".NoAction") action NoAction_30() {
    }
    @name(".NoAction") action NoAction_31() {
    }
    @name(".action_0") action action_0() {
    }
    @name(".action_0") action action_1() {
    }
    @name(".action_0") action action_34() {
    }
    @name(".action_0") action action_35() {
    }
    @name(".action_0") action action_36() {
    }
    @name(".action_0") action action_37() {
    }
    @name(".action_0") action action_38() {
    }
    @name(".action_0") action action_39() {
    }
    @name(".action_0") action action_40() {
    }
    @name(".action_0") action action_41() {
    }
    @name(".action_0") action action_42() {
    }
    @name(".action_0") action action_43() {
    }
    @name(".action_0") action action_44() {
    }
    @name(".action_0") action action_45() {
    }
    @name(".action_0") action action_46() {
    }
    @name(".action_0") action action_47() {
    }
    @name(".action_1") action action_48() {
    }
    @name(".action_1") action action_49() {
    }
    @name(".action_1") action action_50() {
    }
    @name(".action_1") action action_51() {
    }
    @name(".action_1") action action_52() {
    }
    @name(".action_1") action action_53() {
    }
    @name(".action_1") action action_54() {
    }
    @name(".action_1") action action_55() {
    }
    @name(".action_1") action action_56() {
    }
    @name(".action_1") action action_57() {
    }
    @name(".action_1") action action_58() {
    }
    @name(".action_1") action action_59() {
    }
    @name(".action_1") action action_60() {
    }
    @name(".action_1") action action_61() {
    }
    @name(".action_1") action action_62() {
    }
    @name(".action_1") action action_63() {
    }
    @name(".table_0") table table_10 {
        actions = {
            action_0();
            action_48();
            @defaultonly NoAction_0();
        }
        key = {
            hdr.pkt.field_i_8: exact @name("pkt.field_i_8") ;
        }
        size = 256;
        default_action = NoAction_0();
    }
    @name(".table_1") table table_11 {
        actions = {
            action_1();
            action_49();
            @defaultonly NoAction_17();
        }
        key = {
            hdr.pkt.field_i_8: exact @name("pkt.field_i_8") ;
        }
        size = 256;
        default_action = NoAction_17();
    }
    @name(".table_2") table table_12 {
        actions = {
            action_34();
            action_50();
            @defaultonly NoAction_18();
        }
        key = {
            hdr.pkt.field_i_8: exact @name("pkt.field_i_8") ;
        }
        size = 256;
        default_action = NoAction_18();
    }
    @name(".table_3") table table_13 {
        actions = {
            action_35();
            action_51();
            @defaultonly NoAction_19();
        }
        key = {
            hdr.pkt.field_i_8: exact @name("pkt.field_i_8") ;
        }
        size = 256;
        default_action = NoAction_19();
    }
    @name(".table_4") table table_14 {
        actions = {
            action_36();
            action_52();
            @defaultonly NoAction_20();
        }
        key = {
            hdr.pkt.field_i_8: exact @name("pkt.field_i_8") ;
        }
        size = 256;
        default_action = NoAction_20();
    }
    @name(".table_5") table table_15 {
        actions = {
            action_37();
            action_53();
            @defaultonly NoAction_21();
        }
        key = {
            hdr.pkt.field_i_8: exact @name("pkt.field_i_8") ;
        }
        size = 256;
        default_action = NoAction_21();
    }
    @name(".table_6") table table_16 {
        actions = {
            action_38();
            action_54();
            @defaultonly NoAction_22();
        }
        key = {
            hdr.pkt.field_i_8: exact @name("pkt.field_i_8") ;
        }
        size = 256;
        default_action = NoAction_22();
    }
    @name(".table_7") table table_17 {
        actions = {
            action_39();
            action_55();
            @defaultonly NoAction_23();
        }
        key = {
            hdr.pkt.field_i_8: exact @name("pkt.field_i_8") ;
        }
        size = 256;
        default_action = NoAction_23();
    }
    @name(".table_8") table table_18 {
        actions = {
            action_40();
            action_56();
            @defaultonly NoAction_24();
        }
        key = {
            hdr.pkt.field_i_8: exact @name("pkt.field_i_8") ;
        }
        size = 256;
        default_action = NoAction_24();
    }
    @name(".table_9") table table_19 {
        actions = {
            action_41();
            action_57();
            @defaultonly NoAction_25();
        }
        key = {
            hdr.pkt.field_a_32: exact @name("pkt.field_a_32") ;
        }
        size = 512;
        default_action = NoAction_25();
    }
    @ways(2) @name(".table_a") table table_a_0 {
        actions = {
            action_42();
            action_58();
            @defaultonly NoAction_26();
        }
        key = {
            hdr.pkt.field_a_32: exact @name("pkt.field_a_32") ;
        }
        size = 1024;
        default_action = NoAction_26();
    }
    @name(".table_b") table table_b_0 {
        actions = {
            action_43();
            action_59();
            @defaultonly NoAction_27();
        }
        key = {
            hdr.pkt.field_j_8: exact @name("pkt.field_j_8") ;
        }
        size = 256;
        default_action = NoAction_27();
    }
    @name(".table_c") table table_c_0 {
        actions = {
            action_44();
            action_60();
            @defaultonly NoAction_28();
        }
        key = {
            hdr.pkt.field_k_8: exact @name("pkt.field_k_8") ;
        }
        size = 256;
        default_action = NoAction_28();
    }
    @name(".table_d") table table_d_0 {
        actions = {
            action_45();
            action_61();
            @defaultonly NoAction_29();
        }
        key = {
            hdr.pkt.field_b_32: exact @name("pkt.field_b_32") ;
        }
        size = 1024;
        default_action = NoAction_29();
    }
    @name(".table_e") table table_e_0 {
        actions = {
            action_46();
            action_62();
            @defaultonly NoAction_30();
        }
        key = {
            hdr.pkt.field_j_8: exact @name("pkt.field_j_8") ;
        }
        size = 256;
        default_action = NoAction_30();
    }
    @name(".table_f") table table_f_0 {
        actions = {
            action_47();
            action_63();
            @defaultonly NoAction_31();
        }
        key = {
            hdr.pkt.field_k_8: exact @name("pkt.field_k_8") ;
        }
        size = 256;
        default_action = NoAction_31();
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

control verifyChecksum(inout headers hdr, inout metadata meta) {
    apply {
    }
}

control computeChecksum(inout headers hdr, inout metadata meta) {
    apply {
    }
}

V1Switch<headers, metadata>(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;

