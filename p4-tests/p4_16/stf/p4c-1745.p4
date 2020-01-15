#if __TARGET_TOFINO__ == 3
#include <t3na.p4>
#elif __TARGET_TOFINO__ == 2
#include <t2na.p4>
#elif __TARGET_TOFINO__ == 1
#include <tna.p4>
#else
#error Unsupported target
#endif
#include <core.p4>

header data_t {
  bit<32> f;
}

struct headers_t {
  data_t data;
  data_t dataL;
  data_t dataR;
}

@pa_alias("ingress", "hdr.dataR.f", "md.f")
struct user_metadata_t {
  bit<32> f;
}

parser InParser(
    packet_in pkt,
    out headers_t hdr,
    out user_metadata_t md,
    out ingress_intrinsic_metadata_t ig_intr_md) {

  state start {
    pkt.extract(ig_intr_md);
    pkt.advance(PORT_METADATA_SIZE);
    transition data;
  }

  state data {
    pkt.extract(hdr.data);
    transition select(hdr.data.f) {
      0: dataL;
      default: dataR;
    }
  }

  state dataL {
    pkt.extract(hdr.dataL);
    transition accept;
  }

  state dataR {
    pkt.extract(hdr.dataR);
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

  action setL() {
    hdr.dataL.f = 0xdeadbeef;
  }

  action setR() {
    hdr.dataR.f = 0xc0def00d;
  }

  action setMeta() {
    md.f = 0xdeafd00d;
  }

  action drop() {
    ig_intr_dprsr_md.drop_ctl = 1;
  }

  action noop() {}

  table t1 {
    key = {
      hdr.data.f : exact;
    }

    actions = {
      setMeta;
      noop();
    }

    default_action = setMeta();
  }

  table t2 {
    key = {
      hdr.data.f : exact;
      hdr.dataL.f : ternary;
    }

    actions = {
      setL;
      noop;
    }

    default_action = noop;
  }

  table t3 {
    key = {
      hdr.data.f : exact;
      hdr.dataR.f : ternary;
    }

    actions = {
      setR;
      noop;
    }

    default_action = noop;
  }

  table t4 {
    key = {
      md.f : exact;
    }

    actions = {
      drop;
      noop;
    }

    default_action = noop;
  }

  apply {
    ig_intr_tm_md.ucast_egress_port = 10;
    t1.apply();
    t2.apply();
    t3.apply();
    t4.apply();
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
