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
  bit<32> field1;
  bit<32> field2;
  bit<32> field3;
}

header test_result_h {
  bit<16> result1;
  bit<16> result2;
  bit<16> result3;
  bit<16> result4;
  bit<16> result3t;
  bit<16> result4t;
  bit<16> result5;
  bit<16> result6;
  bit<16> result5t;
  bit<16> result6t;
  bit<16> result7;
  bit<16> result8;
  bit<16> result9;
  bit<32> result10;
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
  /* -- change values of the headers to check that hashes are computed with updated values */
  action updateFields() {
    hdr.test.field1 = hdr.test.field1 + 10;
    hdr.test.field2 = hdr.test.field2 + 20;
    hdr.test.field3 = hdr.test.field3 + 30;
  }

  @symmetric("hdr.test.field1","hdr.test.field2")
  Hash<bit<16>>(HashAlgorithm_t.CRC16) hasher1;
  @symmetric("hdr.test.field1","hdr.test.field2")
  Hash<bit<16>>(HashAlgorithm_t.CRC16) hasher2;

  action actionJustList() {
    hdr.result.result1 = hasher1.get({hdr.test.field1, hdr.test.field2, hdr.test.field3, 32w0xaa77aa77});
    hdr.result.result2 = hasher2.get({hdr.test.field2, hdr.test.field1, hdr.test.field3, 32w0xaa77aa77});
  }

  @symmetric("hdr.test.field1","hdr.test.field2")
  Hash<bit<16>>(HashAlgorithm_t.CRC16) hasher3;
  @symmetric("hdr.test.field1","hdr.test.field2")
  Hash<bit<16>>(HashAlgorithm_t.CRC16) hasher4;

  action actionLocal() {
    bit<32> local = hdr.test.field1 & hdr.test.field2;
    hdr.result.result3 = hasher3.get({hdr.test.field1, hdr.test.field2, local, 32w0xaa77aa77});
    hdr.result.result4 = hasher4.get({hdr.test.field2, hdr.test.field1, local, 32w0xaa77aa77});
  }

  @symmetric("hdr.test.field1","hdr.test.field2")
  Hash<bit<16>>(HashAlgorithm_t.CRC16) hasher3t;
  @symmetric("hdr.test.field1","hdr.test.field2")
  Hash<bit<16>>(HashAlgorithm_t.CRC16) hasher4t;

  action actionLocalTable() {
      bit<32> local = hdr.test.field1 & hdr.test.field2;
      hdr.result.result3t = hasher3t.get({hdr.test.field1, hdr.test.field2, local, 32w0xaa77aa77});
      hdr.result.result4t = hasher4t.get({hdr.test.field2, hdr.test.field1, local, 32w0xaa77aa77});
  }

  table tableLocalTable {
    key = {
      hdr.ethernet.ether_type: exact;
    }
    actions = {
      actionLocalTable;
      NoAction;
    }
    default_action = NoAction;
    size = 1;
  }

  @symmetric("hdr.test.field1","hdr.test.field2")
  Hash<bit<16>>(HashAlgorithm_t.CRC16) hasher5;
  @symmetric("hdr.test.field1","hdr.test.field2")
  Hash<bit<16>>(HashAlgorithm_t.CRC16) hasher6;

  action actionDirectExpression() {
      hdr.result.result5 = hasher5.get({
          hdr.test.field1,
          hdr.test.field2,
          hdr.test.field1 & hdr.test.field2,
          32w0xaa77aa77});
      hdr.result.result6 = hasher6.get({
          hdr.test.field2,
          hdr.test.field1,
          hdr.test.field1 & hdr.test.field2,
          32w0xaa77aa77});
  }

  @symmetric("hdr.test.field1","hdr.test.field2")
  Hash<bit<16>>(HashAlgorithm_t.CRC16) hasher5t;
  @symmetric("hdr.test.field1","hdr.test.field2")
  Hash<bit<16>>(HashAlgorithm_t.CRC16) hasher6t;

  action actionDirectExpressionTable() {
      hdr.result.result5t = hasher5t.get({
          hdr.test.field1,
          hdr.test.field2,
          hdr.test.field1 & hdr.test.field2,
          32w0xaa77aa77});
      hdr.result.result6t = hasher6t.get({
          hdr.test.field2,
          hdr.test.field1,
          hdr.test.field1 & hdr.test.field2,
          32w0xaa77aa77});
  }

  table tableDirectExpressionTable {
    key = {
      hdr.ethernet.ether_type: exact;
    }
    actions = {
      actionDirectExpressionTable;
      NoAction;
    }
    default_action = NoAction;
    size = 1;
  }

  @symmetric("hdr.test.field1","hdr.test.field2")
  Hash<bit<16>>(HashAlgorithm_t.CRC16) hasher7;
  @symmetric("hdr.test.field1","hdr.test.field2")
  Hash<bit<16>>(HashAlgorithm_t.CRC16) hasher8;

  action actionConstantVariable() {
      bit<32> const_value = (32w0x12345678 + 10) & (32w0x9abcdef + 20);
      hdr.result.result7 = hasher7.get({
          hdr.test.field1,
          hdr.test.field2,
          const_value,
          32w0xaa77aa77});
      hdr.result.result8 = hasher8.get({
          hdr.test.field2,
          hdr.test.field1,
          const_value,
          32w0xaa77aa77});
  }

  Hash<bit<16>>(HashAlgorithm_t.CRC16) hasher9;

  action actionConcatenation() {
      hdr.result.result9 = hasher9.get(
          hdr.test.field1 ++ hdr.test.field2 ++ (hdr.test.field1 & hdr.test.field2)
              ++ 32w0xaa77aa77);
  }

  action actionInHashBlock() {
      @in_hash {
          hdr.result.result10 = hdr.test.field1 + (hdr.test.field2 ^ (hdr.test.field3 & 32w0xaa77aa77));
      }
  }

  apply {
    updateFields();
    actionJustList();
    actionLocal();
    tableLocalTable.apply();
    actionDirectExpression();
    updateFields();
    tableDirectExpressionTable.apply();
    actionConstantVariable();
    actionConcatenation();
    actionInHashBlock();

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
