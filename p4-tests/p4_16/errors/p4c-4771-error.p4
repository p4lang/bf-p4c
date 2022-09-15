#include <core.p4>
#include <tna.p4>

header one_byte_h {
    bit<8>      val;
}

header two_bytes_h {
    bit<16>     val;
}

struct headers {
    one_byte_h  data;
    two_bytes_h checksum;
    one_byte_h  payload_len_one;
    two_bytes_h payload_len_two;
    one_byte_h  payload;
}

struct metadata {
    bit<16> checksum_tmp;
}

parser ParserImpl(packet_in pkt, out headers hdr, out metadata meta, out ingress_intrinsic_metadata_t ig_intr_md)
{
    Checksum() sum;

    state start {
        pkt.extract(ig_intr_md);
        pkt.advance(PORT_METADATA_SIZE);

        transition parse_data;
    }

    state parse_data {
        pkt.extract(hdr.data);
        sum.subtract({hdr.data});
        
        transition select(hdr.data.val) {
            8w0x00 : reject;
            _ : parse_checksum;
        }
    }

    state parse_checksum {
        pkt.extract(hdr.checksum);

        bit<16> x = pkt.lookahead<bit<16>>();
        transition select(x) {
            16w0 &&& 16w0x8000 : payload_len_one_byte;
            16w0 &&& 16w0x0080 : payload_len_two_bytes;
            _ : reject;
        }
    }

    state payload_len_one_byte {
        pkt.extract(hdr.payload_len_one);

        sum.subtract({hdr.payload_len_one});

        transition extra;
    }

    state payload_len_two_bytes {
        pkt.extract(hdr.payload_len_two);

        sum.subtract({hdr.payload_len_two});

        transition extra;
    }

    state extra {
        pkt.extract(hdr.payload);

        sum.subtract({hdr.payload});
        meta.checksum_tmp = sum.get();

        transition accept;
    }
}

control ingress(inout headers hdr, inout metadata meta, 
        in ingress_intrinsic_metadata_t                  ig_intr_md,
		in ingress_intrinsic_metadata_from_parser_t      ig_prsr_md,
		inout ingress_intrinsic_metadata_for_deparser_t  ig_dprsr_md,
		inout ingress_intrinsic_metadata_for_tm_t        ig_tm_md) {
    apply {
        ig_tm_md.ucast_egress_port = ig_intr_md.ingress_port;
        hdr.data.val = hdr.checksum.val[7:0];
    }
}

#define INGRESS_DPRSR_OVERRIDE
control ingressDeparser(packet_out pkt, inout headers hdr, in metadata meta,
        in ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md) {
    Checksum() sum;

    apply {
        if (hdr.payload_len_one.isValid()) {
            hdr.checksum.val = sum.update(data = {
                meta.checksum_tmp,
                hdr.data,
                hdr.payload_len_one
            }, zeros_as_ones = true);
        } else if (hdr.payload_len_two.isValid()) {
            hdr.checksum.val = sum.update(data = {
                meta.checksum_tmp,
                hdr.data,
                hdr.payload_len_two
            }, zeros_as_ones = true);
        }

        pkt.emit(hdr);
    }
}

#include "common_tna_test.h"
