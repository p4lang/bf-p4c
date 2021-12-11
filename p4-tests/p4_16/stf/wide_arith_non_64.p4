#include <core.p4>
#include <tna.p4>

struct ingress_metadata_t {
    bit<48> a_clone;
    bit<48> b_clone;
    bit<48> sum_clone;
}
struct egress_metadata_t {}

header sum_t {
    bit<64> sum;
}

header ab_t {
    bit<48> b;
    bit<48> a;
}

struct Headers {
    sum_t sum;
    ab_t  ab;
}

parser SwitchIngressParser(packet_in pkt, out Headers hdr, out ingress_metadata_t ig_md, out ingress_intrinsic_metadata_t ig_intr_md) {
    state start {
        pkt.extract(ig_intr_md);
        pkt.advance(PORT_METADATA_SIZE);
        transition parse_hdrs;
    }
    state parse_hdrs {
        pkt.extract(hdr.sum);
        pkt.extract(hdr.ab);
        ig_md.a_clone = hdr.ab.a;
        ig_md.b_clone = hdr.ab.b;
        transition accept;
    }
}

control ingress(inout Headers h, inout ingress_metadata_t m, in ingress_intrinsic_metadata_t ig_intr_md, in ingress_intrinsic_metadata_from_parser_t ig_prsr_md, inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md, inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {
    action sum_up() {
        m.sum_clone = m.a_clone + m.b_clone;
    }
    action copy_back() {
        h.sum.sum = (bit<64>)m.sum_clone;
    }
    apply {
        ig_tm_md.ucast_egress_port = 2;
        sum_up();
        copy_back();
    }
}

// ---------------------------------------------------------------------------
// Ingress Deparser
// ---------------------------------------------------------------------------
control SwitchIngressDeparser(
        packet_out pkt,
        inout Headers hdr,
        in ingress_metadata_t ig_md,
        in ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md) {

    apply {
        pkt.emit(hdr);
    }

}
parser SwitchEgressParser(
        packet_in pkt,
        out Headers hdr,
        out egress_metadata_t eg_md,
        out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        pkt.extract(eg_intr_md);
        transition accept;
    }
}

control SwitchEgressDeparser(
        packet_out pkt,
        inout Headers hdr,
        in egress_metadata_t eg_md,
        in egress_intrinsic_metadata_for_deparser_t eg_intr_dprs_md) {

    apply {
        pkt.emit(hdr);
    }
}

control SwitchEgress(
        inout Headers hdr,
        inout egress_metadata_t eg_md,
        in egress_intrinsic_metadata_t eg_intr_md,
        in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
        inout egress_intrinsic_metadata_for_deparser_t eg_intr_dprs_md,
        inout egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md) {
    apply {}
}

Pipeline(SwitchIngressParser(),
         ingress(),
         SwitchIngressDeparser(),
         SwitchEgressParser(),
         SwitchEgress(),
         SwitchEgressDeparser()) pipe;

Switch(pipe) main;
