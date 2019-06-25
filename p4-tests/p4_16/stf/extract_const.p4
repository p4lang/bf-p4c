#include <t2na.p4>

header h1_t {
  bit<8> f;
}

header h2_t {
  bit<16> f;
}

struct headers_t {
  h1_t h1;
  h2_t h2;
}

header user_metadata_t {
}

parser InParser(
    packet_in pkt,
    out headers_t hdr,
    out user_metadata_t md,
    out ingress_intrinsic_metadata_t ig_intr_md) {

  state start {
    pkt.extract(ig_intr_md);
    pkt.advance(PORT_METADATA_SIZE);
    pkt.extract(hdr.h1);
    transition select(hdr.h1.f) {
      0: h2a;
      default: h2b;
    }
  }

  state h2a {
    hdr.h2 = { 42 };
    transition accept;
  }

  state h2b {
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
    key = { hdr.h2.f : exact; }
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

