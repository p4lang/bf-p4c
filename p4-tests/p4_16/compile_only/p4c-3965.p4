#include <tna.p4>


@pa_alias("ingress", "md.field1", "hdr.p[0].field1")
header protocol_h {
    bit<8> field1;
}

struct metadata {
  PortId_t port;
  bit<8> field1;
}
struct headers {
    protocol_h[2] p;
}

parser iPrsr(packet_in pkt, out headers hdr, out metadata md,
             out ingress_intrinsic_metadata_t ig_intr_md) {
  state start {
    pkt.extract(hdr.p[0]);
    pkt.extract(hdr.p[1]);
    transition accept;
  }
}

control ig(inout headers hdr, inout metadata md,
           in ingress_intrinsic_metadata_t ig_intr_md,
           in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
           inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md,
           inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {

  action inc() { md.field1 = md.field1 + 1; }
  table t {
    key = { md.field1 : exact; }
    actions = {
      inc;
    }
    size = 8;
  }


  apply {
    md.field1 = hdr.p[0].field1;
    t.apply();
  }
}


control iDprsr(packet_out pkt, inout headers hdr, in metadata md,
               in ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md) {
  apply {
    pkt.emit(hdr);
  }
}

parser ePrsr(packet_in pkt, out headers hdr, out metadata md,
             out egress_intrinsic_metadata_t eg_intr_md) {
  state start { transition reject; }
}

control eg(inout headers hdr, inout metadata md, in egress_intrinsic_metadata_t eg_intr_md,
           in egress_intrinsic_metadata_from_parser_t eg_intr_prsr_md,
           inout egress_intrinsic_metadata_for_deparser_t eg_intr_dprsr_md,
           inout egress_intrinsic_metadata_for_output_port_t eg_intr_eport_md) {
  apply {}
}

control eDprsr(packet_out pkt, inout headers hdr, in metadata md,
               in egress_intrinsic_metadata_for_deparser_t eg_intr_dprsr_md) {
  apply {}
}

Pipeline(iPrsr(), ig(), iDprsr(), ePrsr(), eg(), eDprsr()) pipe;
Switch(pipe) main;