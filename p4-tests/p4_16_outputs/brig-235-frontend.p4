#include <core.p4>
#include <tofino.p4>
#include <tna.p4>

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
    headers_t hdr_0;
    state start {
        hdr_0 = hdr;
        transition NestedParser_start;
    }
    state NestedParser_start {
        pkt.extract<data_h>(hdr_0.data);
        transition start_0;
    }
    state start_0 {
        hdr = hdr_0;
        transition accept;
    }
}

control SwitchIngress(inout headers_t hdr, inout user_metadata_t md, in ingress_intrinsic_metadata_t ig_intr_md, in ingress_intrinsic_metadata_from_parser_t ig_intr_md_from_prsr, inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md, inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    @name(".NoAction") action NoAction_0() {
    }
    @name("SwitchIngress.m_action") action m_action() {
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
    apply {
        pkt.emit<headers_t>(hdr);
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
    apply {
        pkt.emit<headers_t>(hdr);
    }
}

Pipeline<headers_t, user_metadata_t, headers_t, user_metadata_t>(InParser(), SwitchIngress(), SwitchIngressDeparser(), EgParser(), SwitchEgress(), SwitchEgressDeparser()) pipe0;

Switch<headers_t, user_metadata_t, headers_t, user_metadata_t, _, _, _, _, _, _, _, _, _, _, _, _>(pipe0) main;

