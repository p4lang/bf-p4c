#if __TARGET_TOFINO__ == 2
#include <t2na.p4>
#else
#include <tna.p4>
#endif

header h1_t {
  bit<8> f1;
  bit<8> f2;
  bit<8> f3;
  bit<8> f4;
}

header h2_t {
  bit<24> f;
}

struct headers_t {
  h1_t h1;
  h2_t h2;
}

header user_metadata_t {
  bit<24> f;
}

parser InParser(
    packet_in pkt,
    out headers_t hdr,
    out user_metadata_t md,
    out ingress_intrinsic_metadata_t ig_intr_md) {

  state start {
    pkt.extract(ig_intr_md);
    pkt.advance(PORT_METADATA_SIZE);
    transition h1;
  }

  state h1 {
    pkt.extract(hdr.h1);
    md.f = pkt.lookahead<bit<24>>();
    transition select(md.f) {
      0xc0ffee: h2;
      default: accept;
    }
  }

  state h2 {
    pkt.extract(hdr.h2);
    transition accept;
  }
}

control SwitchIngress(
    inout headers_t hdr,
    inout user_metadata_t md,
    in ingress_intrinsic_metadata_t ig_intr_md,
    in ingress_intrinsic_metadata_from_parser_t ig_intr_md_from_prsr,
    inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md,
    inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {

  action forward() {
    ig_intr_tm_md.ucast_egress_port = 10;
  }

  table t {
    actions = { forward; }
    key = { md.f : exact; }
  }

  apply {
    t.apply();
  }
}

control IgDeparser(
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
    out headers_t hdr,
    out user_metadata_t md,
    out egress_intrinsic_metadata_t eg_intr_md) {  

  state start {
    pkt.extract(eg_intr_md);
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

control EgDeparser(
    packet_out pkt,
    inout headers_t hdr,
    in user_metadata_t md,
    in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {

  apply {}
}

Pipeline(
    InParser(),
    SwitchIngress(),
    IgDeparser(),
    EgParser(),
    SwitchEgress(),
    EgDeparser()) pipe0;

Switch(pipe0) main;

