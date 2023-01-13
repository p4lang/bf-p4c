#include <core.p4>
#include <tna.p4>

header one_byte_h {
    bit<8>      val;
}

header two_bytes_h {
    bit<16>     val;
}

struct headers {
#ifdef LOOP
    one_byte_h[3] data;
    one_byte_h[4] more_data;
#else
    one_byte_h  data;
#endif
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

#ifdef LOOP
    @dont_unroll
    state parse_data {
        pkt.extract(hdr.data.next);
        sum.subtract({hdr.data.last}); /* expect error: "Checksum .* operates on an odd number of bytes \
inside a loop consisting of states .* which makes it impossible to implement on Tofino\. Consider adding \
an add / subtract instruction with a constant argument 8w0 in one of the states in the loop to make the \
checksum operate on an even number of bytes\." */
        
        transition select(hdr.data.last.val) {
            8w0x00 : parse_more_data;
            _ : parse_checksum;
        }
    }

    @dont_unroll
    state parse_more_data {
        pkt.extract(hdr.more_data.next);
        transition parse_data;
    }
#else
    state parse_data {
        pkt.extract(hdr.data);
        sum.subtract({hdr.data});
        
        transition select(hdr.data.val) {
            8w0x00 : reject;
            _ : parse_checksum;
        }
    }
#endif

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
#ifdef LOOP
        transition accept;
#else
        transition extra;
#endif
    }

    state payload_len_two_bytes {
        pkt.extract(hdr.payload_len_two);

        sum.subtract({hdr.payload_len_two});

#ifdef LOOP
        transition accept;
#else
        transition extra;
#endif
    }

#ifndef LOOP
    state extra { 
        pkt.extract(hdr.payload);

        sum.subtract({hdr.payload}); /* expect error: "Before instruction .* in state .*, checksum .* \
operates on either an odd or an even number of bytes, depending on path through the parser\. This makes it \
impossible to implement on Tofino\. Consider adding a subtract instruction with a constant \
argument 8w0 in a preceding state to make the checksum always operate on either an odd or an \
even number of bytes\." */
        meta.checksum_tmp = sum.get();

        transition accept;
    }
#endif
}

control ingress(inout headers hdr, inout metadata meta, 
        in ingress_intrinsic_metadata_t                  ig_intr_md,
		in ingress_intrinsic_metadata_from_parser_t      ig_prsr_md,
		inout ingress_intrinsic_metadata_for_deparser_t  ig_dprsr_md,
		inout ingress_intrinsic_metadata_for_tm_t        ig_tm_md) {
    apply {
        ig_tm_md.ucast_egress_port = ig_intr_md.ingress_port;
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
#ifndef LOOP
                hdr.data,
#endif
                hdr.payload_len_one
            }, zeros_as_ones = true);
        } else if (hdr.payload_len_two.isValid()) {
            hdr.checksum.val = sum.update(data = {
                meta.checksum_tmp,
#ifndef LOOP
                hdr.data,
#endif
                hdr.payload_len_two
            }, zeros_as_ones = true);
        }

        pkt.emit(hdr);
    }
}

#include "common_tna_test.h"
