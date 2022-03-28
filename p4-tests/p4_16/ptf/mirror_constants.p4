/* -*- P4_16 -*- */

#include <core.p4>
#if __TARGET_TOFINO__ == 3
#include <t3na.p4>
#elif __TARGET_TOFINO__ == 2
#include <t2na.p4>
#else
#include <tna.p4>
#endif


const MirrorType_t MIRROR_TYPE_I2E = 1;

typedef bit<8> packet_type_t;
const packet_type_t DIRECT_PACKET = 1;
const packet_type_t MIRRORED_PACKET = 2;

header packet_header_h {
  packet_type_t type;
}

header ethernet_h {
  bit<48>   dst_addr;
  bit<48>   src_addr;
  bit<16>   ether_type;
}

header test_packet_h {
  bit<8> field1;
  bit<16> field2;
  bit<32> field4;
  bit<32> fixed;
}

struct ingress_headers_t {
  ethernet_h ethernet;
  test_packet_h test;
}

struct egress_headers_t {
  packet_header_h hdr;
  ethernet_h ethernet;
  test_packet_h test;
}

header switch_mirror_h {
  packet_type_t type;
  bit<8> field1;
  bit<16> field2;
  bit<32> field4;
  bit<32> fixed;
}

struct ingress_metadata_t {
  packet_header_h direct_hdr;
  packet_header_h mirrored_hdr;
  MirrorId_t mirror_session;
  bit<32> fixed_mirror;
}

struct egress_metadata_t {
  switch_mirror_h mirror;
}

parser IngressParser(
    packet_in pkt,
    out ingress_headers_t hdr,
    out ingress_metadata_t meta,
    out ingress_intrinsic_metadata_t ig_intr_md)
{
  state start {
    pkt.extract(ig_intr_md);
    pkt.advance(PORT_METADATA_SIZE);
    meta.mirror_session = 0;
    meta.fixed_mirror = 0;
    pkt.extract(hdr.ethernet);
    pkt.extract(hdr.test);
    transition accept;
  }
}

control Ingress(
    inout ingress_headers_t hdr,
    inout ingress_metadata_t meta,
    in ingress_intrinsic_metadata_t ig_intr_md,
    in ingress_intrinsic_metadata_from_parser_t ig_prsr_md,
    inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
    inout ingress_intrinsic_metadata_for_tm_t ig_tm_md)
{
  apply {
    if(hdr.test.isValid()) {
      meta.direct_hdr.type = DIRECT_PACKET;
      meta.direct_hdr.setValid();
      meta.mirrored_hdr.type = MIRRORED_PACKET;
      meta.mirror_session = 1;
      meta.fixed_mirror = 87;

      ig_dprsr_md.drop_ctl = 0;
      ig_dprsr_md.mirror_type = MIRROR_TYPE_I2E;
      ig_tm_md.ucast_egress_port = ig_intr_md.ingress_port;
    }
    else {
      ig_dprsr_md.drop_ctl = 1;
    }
  }
}

control IngressDeparser(
    packet_out pkt,
    inout ingress_headers_t hdr,
    in ingress_metadata_t meta,
    in ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md)
{
  Mirror() mirror;

  apply {
    if(ig_dprsr_md.mirror_type == MIRROR_TYPE_I2E) {
      mirror.emit<switch_mirror_h>(
          meta.mirror_session,
          {
            meta.mirrored_hdr.type,
            8w0,
            16w0,
            32w0,
            meta.fixed_mirror
          });
    }

    pkt.emit(meta.direct_hdr);
    pkt.emit(hdr.ethernet);
    pkt.emit(hdr.test);
  }
}

parser EgressParser(
    packet_in pkt,
    out egress_headers_t hdr,
    out egress_metadata_t meta,
    out egress_intrinsic_metadata_t eg_intr_md)
{
  state start {
    pkt.extract(eg_intr_md);
    packet_header_h pkt_hdr = pkt.lookahead<packet_header_h>();
    transition select(pkt_hdr.type) {
      DIRECT_PACKET: parse_direct;
      MIRRORED_PACKET: parse_mirrored;
      default: reject;
    }
  }

  state parse_direct {
    pkt.extract(hdr.hdr);
    transition parse_common;
  }

  state parse_mirrored {
    pkt.extract(meta.mirror);
    hdr.hdr.setValid();
    hdr.hdr.type = meta.mirror.type;
    transition parse_common;
  }

  state parse_common {
    pkt.extract(hdr.ethernet);
    pkt.extract(hdr.test);
    transition accept;
  }
}

control Egress(
    inout egress_headers_t hdr,
    inout egress_metadata_t meta,
    in egress_intrinsic_metadata_t eg_intr_md,
    in egress_intrinsic_metadata_from_parser_t eg_prsr_md,
    inout egress_intrinsic_metadata_for_deparser_t eg_dprsr_md,
    inout egress_intrinsic_metadata_for_output_port_t eg_oport_md)
{
  apply {
    if(hdr.hdr.type == MIRRORED_PACKET) {
      hdr.test.field1 = meta.mirror.field1 + 1;
      hdr.test.field2 = meta.mirror.field2 + 2;
      hdr.test.field4 = meta.mirror.field4 + 3;
      hdr.test.fixed = meta.mirror.fixed + 4;
    }
    else {
      hdr.test.field1 = hdr.test.field1 + 10;
      hdr.test.field2 = hdr.test.field2 + 20;
      hdr.test.field4 = hdr.test.field4 + 40;
      hdr.test.fixed = 144;
    }
  }
}

control EgressDeparser(
    packet_out pkt,
    inout egress_headers_t hdr,
    in egress_metadata_t meta,
    in egress_intrinsic_metadata_for_deparser_t eg_dprsr_md)
{
  apply {
    pkt.emit(hdr.ethernet);
    pkt.emit(hdr.test);
  }
}

Pipeline(
    IngressParser(),
    Ingress(),
    IngressDeparser(),
    EgressParser(),
    Egress(),
    EgressDeparser()
) pipe;

Switch(pipe) main;
