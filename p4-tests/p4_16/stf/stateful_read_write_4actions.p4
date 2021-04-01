/* -*- P4_16 -*- */

#include <core.p4>
#include <tna.p4>

typedef bit<32> reg_value_t;
typedef bit<8>  index_t;
typedef bit<8>  action_t;

struct metadata { }

#define DATA_T_OVERRIDE
header data_t {
    index_t     index;
    action_t    action_id;
    reg_value_t write_value;
    reg_value_t value1;
    reg_value_t value2;
}

#include "trivial_parser.h"

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
    Register<reg_value_t, index_t>(256, 0) reg;

    action write_action1() {
        reg.write(hdr.data.index, hdr.data.write_value);
    }

    action write_action2() {
        reg.write(hdr.data.index, hdr.data.write_value);
    }

    action read_action1() {
        hdr.data.value1 = reg.read(hdr.data.index);
        hdr.data.value2 = 0x11111111;
    }

    action read_action2() {
        hdr.data.value2 = reg.read(hdr.data.index);
        hdr.data.value1 = 0x22222222;
    }

    table test_table {
        key = {
            hdr.data.action_id : exact;
        }
        actions = {
            write_action1;
            write_action2;
            read_action1;
            read_action2;
        }
    }

    apply {
        test_table.apply();
        ig_tm_md.ucast_egress_port = ig_intr_md.ingress_port;
    }
}

#include "common_tna_test.h"