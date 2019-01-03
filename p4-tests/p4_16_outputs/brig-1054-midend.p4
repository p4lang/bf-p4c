#include <core.p4>
#include <tofino.p4>
#include <tna.p4>

header hdr1_t {
    bit<8>  a;
    bit<16> b;
    bit<8>  c;
    bit<48> d;
}

struct headers_t {
    hdr1_t hdr1;
}

struct user_metadata_t {
}

parser InParser(packet_in pkt, out headers_t hdr, out user_metadata_t md, out ingress_intrinsic_metadata_t ig_intr_md) {
    hdr1_t hdr_0_hdr1;
    state start {
        hdr_0_hdr1 = hdr.hdr1;
        pkt.extract<hdr1_t>(hdr_0_hdr1);
        hdr.hdr1 = hdr_0_hdr1;
        transition accept;
    }
}

control SwitchIngress(inout headers_t hdr, inout user_metadata_t md, in ingress_intrinsic_metadata_t ig_intr_md, in ingress_intrinsic_metadata_from_parser_t ig_intr_md_from_prsr, inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md, inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    @name(".NoAction") action NoAction_0() {
    }
    @name("SwitchIngress.set_pkt") action set_pkt() {
        hdr.hdr1.d = ig_intr_md_from_prsr.global_tstamp;
    }
    @name("SwitchIngress.t1") table t1_0 {
        actions = {
            set_pkt();
            NoAction_0();
        }
        key = {
            hdr.hdr1.a: ternary @name("hdr.hdr1.a") ;
        }
        size = 512;
        default_action = NoAction_0();
    }
    apply {
        t1_0.apply();
    }
}

control SwitchIngressDeparser(packet_out pkt, inout headers_t hdr, in user_metadata_t meta, in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {
    @hidden action act() {
        pkt.emit<hdr1_t>(hdr.hdr1);
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
        pkt.extract<hdr1_t>(hdr.hdr1);
        transition accept;
    }
}

control SwitchEgress(inout headers_t hdr, inout user_metadata_t md, in egress_intrinsic_metadata_t eg_intr_md, in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_parser, inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr, inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {
    apply {
    }
}

control SwitchEgressDeparser(packet_out pkt, inout headers_t hdr, in user_metadata_t md, in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {
    @hidden action act_0() {
        pkt.emit<hdr1_t>(hdr.hdr1);
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

