#if __p4c__ && __p4c_major__ >= 6
#include <tofino.p4>

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
    inout user_metadata_t md,
    in ingress_intrinsic_metadata_t ig_intr_md,
    in ingress_intrinsic_metadata_from_parser_t ig_intr_md_from_prsr,
    inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm) {
    action m_action() {
        ig_intr_md_for_tm.ucast_egress_port = 1;
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
    packet_out pkt,
    in headers_t hdr,
    in user_metadata_t meta) {
    apply {
        pkt.emit(hdr);
    }
}
parser EgParser(
    packet_in pkt,
    out headers_t hdr,
    out user_metadata_t md,
    out egress_intrinsic_metadata_t eg_intr_md) {
  state start {
    pkt.extract(hdr.data);
    transition accept;
  }
}
control SwitchEgress(
    inout headers_t hdr,
    inout user_metadata_t md,
    in egress_intrinsic_metadata_t eg_intr_md,
    in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_parser) {
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
    packet_out pkt,
    in headers_t hdr) {
    apply {
        pkt.emit(hdr);
    }
}
Switch(InParser(), SwitchIngress(), SwitchIngressDeparser(),
       EgParser(), SwitchEgress(), SwitchEgressDeparser()) main;

#else
#error "Tofino Native Arch not supported on compiler versions earlier than 6.0"
#endif
