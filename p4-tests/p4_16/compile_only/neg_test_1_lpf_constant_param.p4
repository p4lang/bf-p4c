#include <tna.p4>       /* TOFINO1_ONLY */

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

    Lpf<bit<32>, bit<9>>(2) lpf;
    action m_action(bit<9> index) {
	lpf.execute(1, index);
    }

    action nop() {
    }

    table t {
        actions = { nop; m_action; }
        key = { hdr.data.db : exact; }
    }
    apply {
        t.apply();
    }
}

control SwitchIngressDeparser(packet_out pkt, inout headers_t hdr, in user_metadata_t meta, in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {
    apply {
        pkt.emit(hdr);
    }
}

parser EgParser(packet_in pkt, out headers_t hdr, out user_metadata_t md, out egress_intrinsic_metadata_t ig_intr_md) {
  state start {
    pkt.extract(hdr.data);
    transition accept;
  }
}

control SwitchEgress(inout headers_t hdr, inout user_metadata_t md, in egress_intrinsic_metadata_t eg_intr_md, in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_parser, inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr, inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {
    apply {} 
}

control SwitchEgressDeparser(packet_out pkt, inout headers_t hdr, in user_metadata_t md, in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {
    apply {
        pkt.emit(hdr);
    }
}

Pipeline(InParser(), SwitchIngress(), SwitchIngressDeparser(),
        EgParser(), SwitchEgress(), SwitchEgressDeparser()) pipe0;

Switch(pipe0) main;
