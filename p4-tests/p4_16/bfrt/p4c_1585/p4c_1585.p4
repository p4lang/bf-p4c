#include <t2na.p4>

header ident_t {
  bit<48> f1;
  bit<48> f2;
  bit<24> f3;
}

header data_t {
  bit<8> f1;
  bit<160> f2;
}

struct headers_t {
  ident_t id1;
  ident_t id2;
  data_t data;
}

header user_metadata_t {
}

parser InParser(
    packet_in pkt,
    out headers_t hdr,
    out user_metadata_t md,
    out ingress_intrinsic_metadata_t ig_intr_md) {

  bit<24> id;

  state start {
    pkt.extract(ig_intr_md);
    pkt.advance(PORT_METADATA_SIZE);
    transition id1;
  }

  state id1 {
    pkt.extract(hdr.id1);
    id = hdr.id1.f3;
    transition select(id) {
      0x424242: id2;
      default: sel;
    }
  }

  state id2 {
    pkt.extract(hdr.id2);
    id = hdr.id2.f3;
    transition sel;
  }

  state sel {
    transition select(id) {
      0x424242: data;
      default: accept;
    }
  }

  state data {
    pkt.extract(hdr.data);
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
    key = { hdr.data.f1 : exact; }
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

