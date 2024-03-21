#include <tna.p4>

struct digest_0 {
    bit<8> field1;
    bit<8> field2;
    bit<8> field3;
    bit<8> field4;
    bit<8> field5;
    bit<8> field6;
    bit<8> field7;
    bit<8> field8;
    bit<8> field9;
    bit<8> field10;
    bit<8> field11;
    bit<8> field12;
    bit<8> field13;
}


header protocol_h {
    bit<8> field1;
    bit<8> field2;
    bit<8> field3;
    bit<8> field4;
    bit<8> field5;
    bit<8> field6;
    bit<8> field7;
    bit<8> field8;
    bit<8> field9;
    bit<8> field10;
    bit<8> field11;
    bit<8> field12;
    bit<8> field13;
}

struct metadata {
  PortId_t port;
  bit<8> field1;
  bit<8> field2;
  bit<8> field3;
  bit<8> field4;
  bit<8> field5;
  bit<8> field6;
  bit<8> field7;
  bit<8> field8;
  bit<8> field9;
  bit<8> field10;
  bit<8> field11;
  bit<8> field12;
  bit<8> field13;
}
struct headers {
    protocol_h p;
}

parser iPrsr(packet_in pkt, out headers hdr, out metadata md,
             out ingress_intrinsic_metadata_t ig_intr_md) {
  state start {
    pkt.extract(hdr.p);
    transition accept;
  }
}

control ig(inout headers hdr, inout metadata md,
           in ingress_intrinsic_metadata_t ig_intr_md,
           in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
           inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md,
           inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {

  action gen_digest_0() { ig_intr_dprsr_md.digest_type = 0; }
  table digest_select {
    key = { hdr.p.field1 : exact; }
    actions = {
      gen_digest_0;
    }
    size = 8;
    const entries = {
      (0) : gen_digest_0();
    }
  }

  action do_set_dest() {
    ig_intr_tm_md.ucast_egress_port = ig_intr_md.ingress_port;
    ig_intr_tm_md.bypass_egress = 1w1;
    md.port = ig_intr_md.ingress_port;
  }
  table set_dest {
    actions = { do_set_dest; }
    default_action = do_set_dest();
  }

  apply {
    digest_select.apply();
    set_dest.apply();
    md.field1 = hdr.p.field1;
    md.field2 = hdr.p.field2;
    md.field3 = hdr.p.field3;
    md.field4 = hdr.p.field4;
    md.field5 = hdr.p.field5;
    md.field6 = hdr.p.field6;
    md.field7 = hdr.p.field7;
    md.field8 = hdr.p.field8;
    md.field9 = hdr.p.field9;
    md.field10 = hdr.p.field10;
    md.field11 = hdr.p.field11;
    md.field12 = hdr.p.field12;
    md.field13 = hdr.p.field13;
  }
}


control iDprsr(packet_out pkt, inout headers hdr, in metadata md,
               in ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md) {
  Digest<digest_0>() d0;
  apply {
    if (ig_intr_dprsr_md.digest_type == 0) {
      
      digest_0 d = { 
        md.field1,
        md.field2,
        md.field3,
        md.field4,
        md.field5,
        md.field6,
        md.field7,
        md.field8,
        md.field9,
        md.field10,
        md.field11,
        md.field12,
        md.field13
      };
      d0.pack( d );
    }
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
