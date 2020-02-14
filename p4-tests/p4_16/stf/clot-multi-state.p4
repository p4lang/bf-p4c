#include <t2na.p4>

header h64_t {
  bit<64> f;
}

header h56_t {
  bit<56> f;
}

header h48_t {
  bit<48> f;
}

header h8_t {
  bit<8> f;
}

struct header_t {
  h8_t  h8a;

  h64_t h64a;
  h56_t h56a;

  h8_t h8b;

  h48_t h48b1;
  h48_t h48b2;

  h64_t h64b;

  h8_t h8c;
}

struct metadata_t {
}

parser MyIngressParser(
    packet_in pkt,
    out header_t hdr,
    out metadata_t ig_md,
    out ingress_intrinsic_metadata_t ig_intr_md) {

  state start {
    pkt.extract(ig_intr_md);
    pkt.advance(PORT_METADATA_SIZE);

    pkt.extract(hdr.h8a);
    transition select(hdr.h8a.f) {
      0: branch_a1;
      1: branch_a2;
      default: accept;
    }
  }

  // Expect h64a to be in CLOTs.
  // Expect h56a[31:24] to be in CLOTs.

  state branch_a1 {
    pkt.extract(hdr.h64a);
    pkt.extract(hdr.h56a);
    transition join;
  }

  state branch_a2 {
    pkt.extract(hdr.h56a);
    pkt.extract(hdr.h64a);
    transition join;
  }

  state join {
    pkt.extract(hdr.h8b);
    transition select(hdr.h8b.f) {
      0: branch_b1;
      1: branch_b2;
      default: accept;
    }
  }

  // Expect h64b to be in CLOTs.
  // Expect h48b1[31:24] to be in CLOTs.
  // Expect h48b2[31:24] to be in CLOTs.

  state branch_b1 {
    pkt.extract(hdr.h48b1);
    pkt.extract(hdr.h64b);
    pkt.extract(hdr.h8c);
    transition accept;
  }

  state branch_b2 {
    pkt.extract(hdr.h48b2);
    pkt.extract(hdr.h64b);
    pkt.extract(hdr.h8c);
    transition accept;
  }
}

control MyIngress(
    inout header_t hdr,
    inout metadata_t ig_md,
    in ingress_intrinsic_metadata_t ig_intr_md,
    in ingress_intrinsic_metadata_from_parser_t ig_prsr_md,
    inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
    inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {

  apply {
    hdr.h8c.f = 0;
    ig_tm_md.ucast_egress_port = 10;
  }
}

control MyIngressDeparser(packet_out pkt,
    inout header_t hdr,
    in metadata_t ig_md,
    in ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md) {

  apply {
    pkt.emit(hdr);
  }
}

parser MyEgressParser(
    packet_in pkt,
    out header_t hdr,
    out metadata_t eg_md,
    out egress_intrinsic_metadata_t eg_intr_md) {

  state start {
    pkt.extract(eg_intr_md);
    transition accept;
  }
}

control MyEgress(
    inout header_t hdr,
    inout metadata_t eg_md,
    in egress_intrinsic_metadata_t eg_intr_md,
    in egress_intrinsic_metadata_from_parser_t eg_prsr_md,
    inout egress_intrinsic_metadata_for_deparser_t eg_dprsr_md,
    inout egress_intrinsic_metadata_for_output_port_t eg_oport_md) {

  apply {
  }
}

control MyEgressDeparser(
    packet_out pkt,
    inout header_t hdr,
    in metadata_t eg_md,
    in egress_intrinsic_metadata_for_deparser_t eg_dprsr_md) {

  apply {
    pkt.emit(hdr);
  }
}

Pipeline(MyIngressParser(),
       MyIngress(),
       MyIngressDeparser(),
       MyEgressParser(),
       MyEgress(),
       MyEgressDeparser()) pipe;

Switch(pipe) main;
