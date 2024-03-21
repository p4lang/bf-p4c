#include <core.p4>
#include <tna.p4>

header skipBlob_h {
    bit<112> data;
}

header dataBlob_h {
    bit<4> pad1;
    bit<4> pri1;
    bit<4> pad2;
    bit<4> pri2;
}

struct headers {
  skipBlob_h skip;
  dataBlob_h data;
}

struct portMetadata_t {
    bit<8> skipKey;
}

struct metadata {
    portMetadata_t portMetadata;
}

struct emetadata {}

parser ParserImpl(packet_in        pkt,
    out headers         hdr,
    out metadata         meta,
    /* Intrinsic */
    out ingress_intrinsic_metadata_t  ig_intr_md)
{
    state start {
        pkt.extract(ig_intr_md);
        meta.portMetadata = port_metadata_unpack<portMetadata_t>(pkt);
        pkt.extract(hdr.skip);
        pkt.extract(hdr.data);
        transition accept;
    }
}

control ingress(
    inout headers                       hdr,
    inout metadata                     meta,
    in    ingress_intrinsic_metadata_t               ig_intr_md,
    in    ingress_intrinsic_metadata_from_parser_t   ig_prsr_md,
    inout ingress_intrinsic_metadata_for_deparser_t  ig_dprsr_md,
    inout ingress_intrinsic_metadata_for_tm_t        ig_tm_md)
{
    apply {
       bit<4> pri = hdr.data.pri1;
       bit<4> pri2 = hdr.data.pri2;
       if( 
           ((pri[3:3] != pri2[3:3]) && ((pri & 0x8) == 0x8)) ||
           ((pri[3:3] == pri2[3:3]) && (pri[2:2] != pri2[2:2]) && ((pri & 0x4) == 0x4)) ||
           ((pri[3:2] == pri2[3:2]) && (pri[1:1] != pri2[1:1]) && ((pri & 0x2) == 0x2)) ||
           ((pri[3:1] == pri2[3:1]) && (pri[0:0] != pri2[0:0]) && ((pri & 0x1) == 0x1))
       ) {
         hdr.data.pri1 = hdr.data.pri2;
      }
      ig_tm_md.ucast_egress_port = ig_intr_md.ingress_port;
    }
}

#include "common_tna_test.h"