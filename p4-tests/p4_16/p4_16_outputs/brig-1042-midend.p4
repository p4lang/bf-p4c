#include <core.p4>
#include <tofino2.p4>

struct tuple_0 {
    bit<8> field;
    bit<8> field_0;
    bit<8> field_1;
    bit<8> field_2;
    bit<8> field_3;
    bit<8> field_4;
    bit<8> field_5;
    bit<8> field_6;
    bit<8> field_7;
    bit<8> field_8;
    bit<8> field_9;
    bit<8> field_10;
    bit<8> field_11;
    bit<8> field_12;
    bit<8> field_13;
    bit<8> field_14;
}
#include <t2na.p4>

header data_h {
    bit<32> da;
    bit<32> db;
}

struct headers_t {
    data_h data;
}

struct user_metadata_t {
}

parser InParser(packet_in pkt, out headers_t hdr, out user_metadata_t md, out ingress_intrinsic_metadata_t ig_intr_md) {
    state start {
        transition accept;
    }
}

control SwitchIngress(inout headers_t hdr, inout user_metadata_t md, in ingress_intrinsic_metadata_t ig_intr_md, in ingress_intrinsic_metadata_from_parser_t ig_intr_md_from_prsr, inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md, inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    @name(".NoAction") action NoAction_0() {
    }
    @name("SwitchIngress.m_action") action m_action(bit<32> afc) {
        ig_intr_dprsr_md.adv_flow_ctl = afc;
    }
    @name("SwitchIngress.nop") action nop() {
    }
    @name("SwitchIngress.t") table t_0 {
        actions = {
            nop();
            m_action();
            @defaultonly NoAction_0();
        }
        key = {
            hdr.data.db: exact @name("hdr.data.db") ;
        }
        default_action = NoAction_0();
    }
    apply {
        t_0.apply();
    }
}

control SwitchIngressDeparser(packet_out pkt, inout headers_t hdr, in user_metadata_t meta, in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {
    @hidden action act() {
        pkt.emit<data_h>(hdr.data);
    }
    @hidden table tbl_act {
        actions = {
            act();
        }
        const default_action = act();
    }
    apply {
        tbl_act.apply();
    }
}

parser EgParser(packet_in pkt, out headers_t hdr, out user_metadata_t md, out egress_intrinsic_metadata_t ig_intr_md) {
    state start {
        pkt.extract<data_h>(hdr.data);
        transition accept;
    }
}

control SwitchEgress(inout headers_t hdr, inout user_metadata_t md, in egress_intrinsic_metadata_t eg_intr_md, in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_parser, inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr, inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {
    apply {
    }
}

control SwitchEgressDeparser(packet_out pkt, inout headers_t hdr, in user_metadata_t md, in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {
    @hidden action act_0() {
        pkt.emit<data_h>(hdr.data);
    }
    @hidden table tbl_act_0 {
        actions = {
            act_0();
        }
        const default_action = act_0();
    }
    apply {
        tbl_act_0.apply();
    }
}

Pipeline<headers_t, user_metadata_t, headers_t, user_metadata_t>(InParser(), SwitchIngress(), SwitchIngressDeparser(), EgParser(), SwitchEgress(), SwitchEgressDeparser()) pipe0;

Switch<headers_t, user_metadata_t, headers_t, user_metadata_t, _, _, _, _, _, _, _, _, _, _, _, _>(pipe0) main;
