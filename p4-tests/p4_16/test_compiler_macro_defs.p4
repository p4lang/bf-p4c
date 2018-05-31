#if __p4c__ && __p4c_major__ >= 6
#include <tna.p4>

header data_h {
    bit<32> da;
}
struct headers_t {
    data_h data;
}
struct user_metadata_t {
    bit<8> f1;
}
parser InParser(
    packet_in pkt,
    out headers_t hdr,
    out user_metadata_t md,
    out ingress_intrinsic_metadata_t ig_intr_md) {
    state start {
        transition accept;
    }
}
control SwitchIngress(
    inout headers_t hdr,
    inout user_metadata_t meta,
    in ingress_intrinsic_metadata_t ig_intr_md,
    in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
    inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
    inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {

    action m_action() {
        ig_intr_tm_md.ucast_egress_port = 1;
    }
    action nop() {
    }
    table t {
        actions = { nop; m_action; }
        key = { hdr.data.da : exact; }
    }
    apply {
        t.apply();
    }
}
control SwitchIngressDeparser(
    packet_out b,
    inout headers_t hdr,
    in user_metadata_t meta,
    in ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md) {
    apply {
        b.emit(hdr);
    }
}
parser EgParser(
    packet_in b,
    out headers_t hdr,
    out user_metadata_t meta,
    out egress_intrinsic_metadata_t eg_intr_md) {
  state start {
    b.extract(hdr.data);
    transition accept;
  }
}
control SwitchEgress(
    inout headers_t hdr,
    inout user_metadata_t meta,
    in egress_intrinsic_metadata_t eg_intr_md,
    in egress_intrinsic_metadata_from_parser_t eg_intr_prsr_md,
    inout egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
    inout egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md) {
    table t {
        key = {
            eg_intr_md.egress_port : exact;
        }
        actions = { NoAction; }
    }
    apply {
        t.apply();
    }
}
control SwitchEgressDeparser(
    packet_out b,
    inout headers_t hdr,
    in user_metadata_t meta,
    in egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md) {
    apply {
        b.emit(hdr);
    }
}
Pipeline(InParser(), SwitchIngress(), SwitchIngressDeparser(),
       EgParser(), SwitchEgress(), SwitchEgressDeparser()) pipe0;
Switch(pipe0) main;

#else
#error "Tofino Native Arch not supported on compiler versions earlier than 6.0"
#endif
