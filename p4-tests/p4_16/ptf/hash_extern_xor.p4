/* -*- P4_16 -*- */

#include <core.p4>
#if __TARGET_TOFINO__ == 3
#include <t3na.p4>
#elif __TARGET_TOFINO__ == 2
#include <t2na.p4>
#else
#include <tna.p4>
#endif

header ethernet_h {
  bit<48>   dst_addr;
  bit<48>   src_addr;
  bit<16>   ether_type;
}

header test_packet_h {
  bit<8> field1;
  bit<16> field2;
  bit<32> field4;
}

header test_result_h {
  bit<8> xor8;
  bit<16> xor16;
  bit<32> xor32;
}

struct headers {
  ethernet_h ethernet;
  test_packet_h test;
  test_result_h result;
}

struct metadata {
}

parser ParserImpl(
    packet_in pkt,
    out headers hdr,
    out metadata meta,
    out ingress_intrinsic_metadata_t ig_intr_md)
{
  state start {
    pkt.extract(ig_intr_md);
    pkt.advance(PORT_METADATA_SIZE);
    pkt.extract(hdr.ethernet);
    pkt.extract(hdr.test);
    transition accept;
  }
}

control ingress(
    inout headers hdr,
    inout metadata meta,
    in ingress_intrinsic_metadata_t ig_intr_md,
    in ingress_intrinsic_metadata_from_parser_t ig_prsr_md,
    inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
    inout ingress_intrinsic_metadata_for_tm_t ig_tm_md)
{
  Hash<bit<8>>(HashAlgorithm_t.XOR8) hash8;
  Hash<bit<16>>(HashAlgorithm_t.XOR16) hash16;
  Hash<bit<32>>(HashAlgorithm_t.XOR32) hash32;

  action computeHashCode8() {
    hdr.result.xor8 = hash8.get({hdr.test.field1, hdr.test.field2, 16w0xaa77, hdr.test.field4});
  }
  
  table hashTable8 {
    key = {
      hdr.ethernet.ether_type: exact;
    }
    actions = {
      computeHashCode8;
      NoAction;
    }
    default_action = NoAction;
    size = 1;
  }

  action computeHashCode16() {
    hdr.result.xor16 = hash16.get({hdr.test.field1, hdr.test.field2, 16w0xaa77, hdr.test.field4});
  }
  
  table hashTable16 {
    key = {
      hdr.ethernet.ether_type: exact;
    }
    actions = {
      computeHashCode16;
      NoAction;
    }
    default_action = NoAction;
    size = 1;
  }

  action computeHashCode32() {
    hdr.result.xor32 = hash32.get({hdr.test.field1, hdr.test.field2, 16w0xaa77, hdr.test.field4});
  }

  table hashTable32 {
    key = {
      hdr.ethernet.ether_type: exact;
    }
    actions = {
      computeHashCode32;
      NoAction;
    }
    default_action = NoAction;
    size = 1;
  }

  apply {
    hashTable8.apply();
    hashTable16.apply();
    hashTable32.apply();

    hdr.result.setValid();
    hdr.ethernet.ether_type = hdr.ethernet.ether_type + 1;
    ig_tm_md.ucast_egress_port = ig_intr_md.ingress_port;
    ig_tm_md.bypass_egress = 1;
  }
}

control ingressDeparser(
    packet_out pkt,
    inout headers hdr,
    in metadata meta,
    in ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md)
{
  apply {
    pkt.emit(hdr.ethernet);
    pkt.emit(hdr.result);
  }
}

#define INGRESS_DPRSR_OVERRIDE 1
#include "../includes/common_tna_test.h"
