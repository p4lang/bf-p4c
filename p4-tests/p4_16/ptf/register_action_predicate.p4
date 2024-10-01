#include "core.p4"
#include "tna.p4"

typedef bit<13> stats_index_t;

struct range_pair {
    bit<32> start;
    bit<32> end;
}

struct portMetadata_t {
    bit<8> skipKey;
}

struct metadata {
    portMetadata_t portMetadata;
}

header skipBlob_h {
    bit<112> data;
}

header dataBlob_h {
    bit<32> range_addr;
    bit<32> range_result;
}

struct headers {
  skipBlob_h skip;
  dataBlob_h data;
}

parser ParserImpl(packet_in pkt,
       out headers hdr,
       out metadata meta,
       out ingress_intrinsic_metadata_t ig_intr_md) {
    state start {
      pkt.extract(ig_intr_md);
      meta.portMetadata = port_metadata_unpack<portMetadata_t>(pkt);
      pkt.extract(hdr.skip);
      pkt.extract(hdr.data);
      transition accept;
    }
}

control ingress(inout headers hdr,
         inout metadata meta,
         in ingress_intrinsic_metadata_t ig_intr_md,
         in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
         inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md,
         inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md)
{
  Register<range_pair, stats_index_t>(size=1<<13, initial_value={1, 3}) range_reg;
  RegisterAction<range_pair, stats_index_t, bit<32>>(range_reg)
  compare_range = {
      void apply(inout range_pair value, out bit<32> rv) {
          rv = this.predicate(value.start > hdr.data.range_addr, value.end < hdr.data.range_addr);
      }
   };

  action range_match(stats_index_t stats_index) {
    hdr.data.range_result = compare_range.execute(stats_index);
  }

  table EgressRangecompare {
    actions = {
      range_match;
    }
    default_action = range_match(0);
  }

  apply {
      EgressRangecompare.apply();

      ig_intr_tm_md.ucast_egress_port = ig_intr_md.ingress_port;
  }
}

#include "common_tna_test.h"
