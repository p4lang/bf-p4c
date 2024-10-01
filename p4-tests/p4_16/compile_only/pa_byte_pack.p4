#include <tna.p4>

header hdr_t {
  bit<32> op;
}

struct headers_t {
  hdr_t hdr;
}
// without using pa_byte_pack pragma, the allocation might look like:
//  hdrs.hdr.op: W0
//  md.m1: B1(0..3)
//  md.m_r1: B1(4..7)
//  md.m2: B0(1..6)
//  md.m_r2: B2(3..4)
//  md.m3: B2(0..2)
// then it takes 3 bytes for match_metadata and 2 bytes for the gate way.
@pa_auto_init_metadata
@pa_byte_pack("ingress", "md.m1", "md.m3", 1, "md.m2", 2)
struct user_metadata_t {
    bit<4> m1;
    bit<4> m_r1;
    bit<6> m2;
    bit<2> m_r2;
    bit<3> m3;
}

parser InParser(
    packet_in pkt,
    out headers_t hdrs,
    out user_metadata_t md,
    out ingress_intrinsic_metadata_t ig_intr_md) {

    state start {
        pkt.extract(hdrs.hdr);
        transition accept;
    }
}


#define def_set_metadata(m, sz) action set_##m(sz p) { md.m = p; }

control SwitchIngress(
    inout headers_t hdrs,
    inout user_metadata_t md,
    in ingress_intrinsic_metadata_t ig_intr_md,
    in ingress_intrinsic_metadata_from_parser_t ig_intr_md_from_prsr,
    inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md,
    inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {

    def_set_metadata(m1, bit<4>)
    def_set_metadata(m_r1, bit<4>)
    def_set_metadata(m2, bit<6>)
    def_set_metadata(m_r2, bit<2>)
    def_set_metadata(m3, bit<3>)

    table set_metadata {
        actions = { set_m1; set_m2; set_m3; set_m_r1; set_m_r2;}
        key = { hdrs.hdr.op: exact; }
        size = 512;
    }

    action set_hdr(bit<32> op) { hdrs.hdr.op = op; }
    table match_metadata {
        actions = { set_hdr; }
        key = {
            md.m1 : exact;
            md.m2 : exact;
            md.m3 : exact;
        }
        size = 65535;
    }

    apply {
        set_metadata.apply();
        if (md.m_r1 == 1 && md.m_r2 == 2) {
            match_metadata.apply();
        }
    }
}

control SwitchIngressDeparser(
    packet_out pkt, 
    inout headers_t hdr,
    in user_metadata_t meta,
    in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {
    apply {
        pkt.emit(hdr);
    }
}

parser EgParser(
    packet_in pkt, 
    out headers_t hdrs,
    out user_metadata_t md,
    out egress_intrinsic_metadata_t ig_intr_md) {  
  state start {
    pkt.extract(hdrs.hdr);
    transition accept;
  }
}

control SwitchEgress(
    inout headers_t hdr,
    inout user_metadata_t md,
    in egress_intrinsic_metadata_t eg_intr_md,
    in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_parser,
    inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
    inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {
    apply {} 
}

control SwitchEgressDeparser(
    packet_out pkt,
    inout headers_t hdr,
    in user_metadata_t md,
    in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {
    apply {
        pkt.emit(hdr);
    }
}

Pipeline(InParser(), SwitchIngress(), SwitchIngressDeparser(),
        EgParser(), SwitchEgress(), SwitchEgressDeparser()) pipe0;

Switch(pipe0) main;
