/**
 * Two fields are packed in a PHV only when they are from the same header. This
 * program exercises a (now fixed) bug in the CLOT allocator in which this
 * same-header condition was missing, resulting in the parser-lowering pass
 * incorrectly expecting a field (hdr.h.f in this program) to be PHV-allocated.
 */
#include <t2na.p4>

header h_t {
  bit<24> pad1;
  bit<8> f;
  bit<24> pad2;
}

struct headers_t {
  h_t h;
}

struct metadata_t {
  bit<8> f;
}

parser InParser(
    packet_in pkt,
    out headers_t hdr,
    out metadata_t md,
    out ingress_intrinsic_metadata_t ig_intr_md) {

  state start {
    pkt.extract(ig_intr_md);
    pkt.advance(PORT_METADATA_SIZE);
    pkt.extract(hdr.h);
    md.f = hdr.h.f;
    transition accept;
  }
}

control SwitchIngress(
    inout headers_t hdr,
    inout metadata_t md,
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
    in metadata_t meta,
    in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {

  apply {
    pkt.emit(hdr);
  }
}

parser EgParser(
    packet_in pkt, 
    out headers_t hdr,
    out metadata_t md,
    out egress_intrinsic_metadata_t eg_intr_md) {  

  state start {
    pkt.extract(eg_intr_md);
    transition accept;
  }
}

control SwitchEgress(
    inout headers_t hdr,
    inout metadata_t md,
    in egress_intrinsic_metadata_t eg_intr_md,
    in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_parser,
    inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
    inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {

  apply {} 
}

control EgDeparser(
    packet_out pkt,
    inout headers_t hdr,
    in metadata_t md,
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
