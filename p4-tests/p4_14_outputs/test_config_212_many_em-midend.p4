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
    @name("NoAction") action NoAction_0() {
    }
    @name("NoAction") action NoAction_17() {
    }
    @name("NoAction") action NoAction_18() {
    }
    @name("NoAction") action NoAction_19() {
    }
    @name("NoAction") action NoAction_20() {
    }
    @name("NoAction") action NoAction_21() {
    }
    @name("NoAction") action NoAction_22() {
    }
    @name("NoAction") action NoAction_23() {
    }
    @name("NoAction") action NoAction_24() {
    }
    @name("NoAction") action NoAction_25() {
    }
    @name("NoAction") action NoAction_26() {
    }
    @name("NoAction") action NoAction_27() {
    }
    @name("NoAction") action NoAction_28() {
    }
    @name("NoAction") action NoAction_29() {
    }
    @name("NoAction") action NoAction_30() {
    }
    @name("NoAction") action NoAction_31() {
    }
    @name("action_0") action action_2() {
    }
    @name("action_0") action action_3() {
    }
    @name("action_0") action action_34() {
    }
    @name("action_0") action action_35() {
    }
    @name("action_0") action action_36() {
    }
    @name("action_0") action action_37() {
    }
    @name("action_0") action action_38() {
    }
    @name("action_0") action action_39() {
    }
    @name("action_0") action action_40() {
    }
    @name("action_0") action action_41() {
    }
    @name("action_0") action action_42() {
    }
    @name("action_0") action action_43() {
    }
    @name("action_0") action action_44() {
    }
    @name("action_0") action action_45() {
    }
    @name("action_0") action action_46() {
    }
    @name("action_0") action action_47() {
    }
    @name("action_1") action action_48() {
    }
    @name("action_1") action action_49() {
    }
    @name("action_1") action action_50() {
    }
    @name("action_1") action action_51() {
    }
    @name("action_1") action action_52() {
    }
    @name("action_1") action action_53() {
    }
    @name("action_1") action action_54() {
    }
    @name("action_1") action action_55() {
    }
    @name("action_1") action action_56() {
    }
    @name("action_1") action action_57() {
    }
    @name("action_1") action action_58() {
    }
    @name("action_1") action action_59() {
    }
    @name("action_1") action action_60() {
    }
    @name("action_1") action action_61() {
    }
    @name("action_1") action action_62() {
    }
    @name("action_1") action action_63() {
    }
    @name("table_0") table table_0() {
        actions = {
            action_2();
            action_48();
            @default_only NoAction_0();
        }
        key = {
            hdr.pkt.field_i_8: exact @name("hdr.pkt.field_i_8") ;
        }
        size = 256;
        default_action = NoAction_0();
    }
    @name("table_1") table table_1() {
        actions = {
            action_3();
            action_49();
            @default_only NoAction_17();
        }
        key = {
            hdr.pkt.field_i_8: exact @name("hdr.pkt.field_i_8") ;
        }
        size = 256;
        default_action = NoAction_17();
    }
    @name("table_2") table table_2() {
        actions = {
            action_34();
            action_50();
            @default_only NoAction_18();
        }
        key = {
            hdr.pkt.field_i_8: exact @name("hdr.pkt.field_i_8") ;
        }
        size = 256;
        default_action = NoAction_18();
    }
    @name("table_3") table table_3() {
        actions = {
            action_35();
            action_51();
            @default_only NoAction_19();
        }
        key = {
            hdr.pkt.field_i_8: exact @name("hdr.pkt.field_i_8") ;
        }
        size = 256;
        default_action = NoAction_19();
    }
    @name("table_4") table table_4() {
        actions = {
            action_36();
            action_52();
            @default_only NoAction_20();
        }
        key = {
            hdr.pkt.field_i_8: exact @name("hdr.pkt.field_i_8") ;
        }
        size = 256;
        default_action = NoAction_20();
    }
    @name("table_5") table table_5() {
        actions = {
            action_37();
            action_53();
            @default_only NoAction_21();
        }
        key = {
            hdr.pkt.field_i_8: exact @name("hdr.pkt.field_i_8") ;
        }
        size = 256;
        default_action = NoAction_21();
    }
    @name("table_6") table table_6() {
        actions = {
            action_38();
            action_54();
            @default_only NoAction_22();
        }
        key = {
            hdr.pkt.field_i_8: exact @name("hdr.pkt.field_i_8") ;
        }
        size = 256;
        default_action = NoAction_22();
    }
    @name("table_7") table table_7() {
        actions = {
            action_39();
            action_55();
            @default_only NoAction_23();
        }
        key = {
            hdr.pkt.field_i_8: exact @name("hdr.pkt.field_i_8") ;
        }
        size = 256;
        default_action = NoAction_23();
    }
    @name("table_8") table table_8() {
        actions = {
            action_40();
            action_56();
            @default_only NoAction_24();
        }
        key = {
            hdr.pkt.field_i_8: exact @name("hdr.pkt.field_i_8") ;
        }
        size = 256;
        default_action = NoAction_24();
    }
    @name("table_9") table table_9() {
        actions = {
            action_41();
            action_57();
            @default_only NoAction_25();
        }
        key = {
            hdr.pkt.field_a_32: exact @name("hdr.pkt.field_a_32") ;
        }
        size = 512;
        default_action = NoAction_25();
    }
    @ways(2) @name("table_a") table table_a() {
        actions = {
            action_42();
            action_58();
            @default_only NoAction_26();
        }
        key = {
            hdr.pkt.field_a_32: exact @name("hdr.pkt.field_a_32") ;
        }
        size = 1024;
        default_action = NoAction_26();
    }
    @name("table_b") table table_b() {
        actions = {
            action_43();
            action_59();
            @default_only NoAction_27();
        }
        key = {
            hdr.pkt.field_j_8: exact @name("hdr.pkt.field_j_8") ;
        }
        size = 256;
        default_action = NoAction_27();
    }
    @name("table_c") table table_c() {
        actions = {
            action_44();
            action_60();
            @default_only NoAction_28();
        }
        key = {
            hdr.pkt.field_k_8: exact @name("hdr.pkt.field_k_8") ;
        }
        size = 256;
        default_action = NoAction_28();
    }
    @name("table_d") table table_d() {
        actions = {
            action_45();
            action_61();
            @default_only NoAction_29();
        }
        key = {
            hdr.pkt.field_b_32: exact @name("hdr.pkt.field_b_32") ;
        }
        size = 1024;
        default_action = NoAction_29();
    }
    @name("table_e") table table_e() {
        actions = {
            action_46();
            action_62();
            @default_only NoAction_30();
        }
        key = {
            hdr.pkt.field_j_8: exact @name("hdr.pkt.field_j_8") ;
        }
        size = 256;
        default_action = NoAction_30();
    }
    @name("table_f") table table_f() {
        actions = {
            action_47();
            action_63();
            @default_only NoAction_31();
        }
        key = {
            hdr.pkt.field_k_8: exact @name("hdr.pkt.field_k_8") ;
        }
        size = 256;
        default_action = NoAction_31();
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

control verifyChecksum(in headers hdr, inout metadata meta) {
    apply {
    }
}

control computeChecksum(inout headers hdr, inout metadata meta) {
    apply {
    }
}

V1Switch<headers, metadata>(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;
