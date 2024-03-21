#include "core.p4"
#include "tna.p4"

typedef bit<13> stats_index_t;

struct range_pair {
    bit<32> start;
    bit<32> end;
}

header example_bridge_h {
    bit<8> l2_offset;

    @padding bit<5> pad;
    bit<1> l47_timestamp_insert;
    bit<1> l23_txtstmp_insert;
    bit<1> l23_rxtstmp_insert;
}

struct metadata {}

struct headers {
    example_bridge_h bridge;
}

struct eg_headers {}

parser PacketParserIngress(packet_in pkt,
                    out headers hdr,
                    out metadata meta,
                    out ingress_intrinsic_metadata_t ig_intr_md) {
    state start {
        pkt.extract(ig_intr_md);
        hdr.bridge.setValid();
        hdr.bridge.l47_timestamp_insert = 0;
        hdr.bridge.l23_txtstmp_insert = 0;
        hdr.bridge.l23_rxtstmp_insert = 0;
        hdr.bridge.l2_offset = 0;
        transition accept;
    }
}

control inbound_l47_gen_lookup() {
  stats_index_t index = 0;
  bit<16> remap_addr_6;
  bit<16> remap_addr_7;
  bit<32> range_addr = 0;
  bit<32> range_result = 0;
  Hash<bit<32>>(HashAlgorithm_t.IDENTITY) identity_hash32_l;

  Register<range_pair, stats_index_t>(size=1<<13, initial_value={0, 0}) range_reg;
  RegisterAction<range_pair, stats_index_t, bit<32>>(range_reg)
  compare_range = {
      void apply(inout range_pair value, out bit<32> rv) {
          rv = (bit<32>)this.predicate(value.start > range_addr, value.end < range_addr);
      }
   };

  action range_match(stats_index_t stats_index) {
    range_result = compare_range.execute(stats_index);
  }

  table EgressRangecompare {
    actions = {
      range_match;
    }
  }

  table EgressRangeCnTbl {
    key = {
      range_result : exact;
    }
    actions = {}
  }

  apply
  {
    range_addr = identity_hash32_l.get({1w0 +++ remap_addr_6[14:0] +++ remap_addr_7});
    EgressRangecompare.apply();

    EgressRangeCnTbl.apply();
  }
}

parser ParserImpl(packet_in pkt,
       out headers hdr,
       out metadata meta,
       out ingress_intrinsic_metadata_t ig_intr_md) {
    PacketParserIngress() pkt_parser;

    state start {
      pkt_parser.apply(pkt, hdr, meta, ig_intr_md);
      transition accept;
    }
}

control ingress(inout headers hdr,
         inout metadata meta,
         in ingress_intrinsic_metadata_t ig_intr_md,
         in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
         inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md,
         inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    apply {
        inbound_l47_gen_lookup.apply();
    }
}

#include "common_tna_test.h"
