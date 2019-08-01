#if __TARGET_TOFINO__ == 2
#include "t2na.p4"
#else
#include "tna.p4"
#endif

header foo_t {
  bit<48> bar;
}

struct headers {
  foo_t          foo;
}

struct ing_metadata {
  bit<8>       lame;
}

struct egr_metadata {
}

parser iPrsr(packet_in packet,
             out headers hdr,
             out ing_metadata md,
             out ingress_intrinsic_metadata_t intr_md) {
  state start {
    packet.extract(intr_md);
    packet.advance(PORT_METADATA_SIZE);
    packet.extract(hdr.foo);
    md.lame = hdr.foo.bar[7:0];
    transition accept;
  }
}

control ingr(inout headers hdr,
             inout ing_metadata md,
             in    ingress_intrinsic_metadata_t              intr_md,
             in    ingress_intrinsic_metadata_from_parser_t  intr_prsr_md,
             inout ingress_intrinsic_metadata_for_deparser_t intr_dprsr_md,
             inout ingress_intrinsic_metadata_for_tm_t       intr_tm_md) {
  apply {
    if (md.lame == 0x6) {
      intr_tm_md.ucast_egress_port = 0x1;
    }
  }
}

control iDprsr(packet_out packet,
               inout headers hdr,
               in ing_metadata md,
               in ingress_intrinsic_metadata_for_deparser_t intr_md_for_dprsr) {
  apply {
    packet.emit(hdr);
  }
}

parser ePrsr(packet_in packet,
             out headers hdr,
             out egr_metadata md,
             out egress_intrinsic_metadata_t intr_md) {
  state start {
    packet.extract(intr_md);
    transition accept; 
  }
}

control egr(inout headers hdr,
            inout egr_metadata md,
            in    egress_intrinsic_metadata_t                 intr_md,
            in    egress_intrinsic_metadata_from_parser_t     intr_prsr_md,
            inout egress_intrinsic_metadata_for_deparser_t    intr_dprsr_md,
            inout egress_intrinsic_metadata_for_output_port_t intr_oport_md) {
  apply {
  }
}

control eDprsr(packet_out packet, inout headers hdr, in egr_metadata md,
               in egress_intrinsic_metadata_for_deparser_t intr_md_for_dprsr) {
  apply {
  }
}

Pipeline(iPrsr(), ingr(), iDprsr(), ePrsr(), egr(), eDprsr()) pipe;
Switch(pipe) main;
