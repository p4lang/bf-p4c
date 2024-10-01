/* -*- P4_16 -*- */

#include <core.p4>
#include <tna.p4>

typedef bit<8>  pol_color_8_t;
typedef bit<16> pol_color_16_t;
typedef bit<32> pol_color_32_t;
typedef bit<8>  index_t;
typedef bit<8>  action_t;

struct metadata { }

#define DATA_T_OVERRIDE
header data_t {
    index_t        index;
    action_t       action_id;
    pol_color_8_t  in_color_8;
    pol_color_8_t  out_color_8;
    pol_color_16_t out_color_16;
    pol_color_32_t out_color_32;
}

#include "trivial_parser.h"

@pa_container_size("ingress", "hdr.data.out_color_16", 16)
@pa_container_size("ingress", "hdr.data.out_color_32", 32)
control ingress(
    /* User */
    inout headers hdr,
    inout metadata meta,
    /* Intrinsic */
    in    ingress_intrinsic_metadata_t               ig_intr_md,
    in    ingress_intrinsic_metadata_from_parser_t   ig_prsr_md,
    inout ingress_intrinsic_metadata_for_deparser_t  ig_dprsr_md,
    inout ingress_intrinsic_metadata_for_tm_t        ig_tm_md)
{
    DirectMeter(MeterType_t.BYTES, 8w0xf6, 8w0x57, 8w0x3f) IMeterDirect;

    action pol_action8() {
        hdr.data.out_color_8 = IMeterDirect.execute((MeterColor_t)hdr.data.in_color_8, 32w0);
    }

    action pol_action16() {
        hdr.data.out_color_16[11:4] = IMeterDirect.execute((MeterColor_t)hdr.data.in_color_8, 32w0);
    }

    action pol_action32() {
        hdr.data.out_color_32[23:16] = IMeterDirect.execute((MeterColor_t)hdr.data.in_color_8, 32w0);
    }

    table test_table1 {
        key = {
            hdr.data.action_id : exact;
        }
        actions = {
            pol_action8;
            pol_action16;
	    pol_action32;
        }
	size = 256;
	meters = IMeterDirect;
    }

    apply {
        test_table1.apply();
        ig_tm_md.ucast_egress_port = ig_intr_md.ingress_port;
    }
}

#include "common_tna_test.h"