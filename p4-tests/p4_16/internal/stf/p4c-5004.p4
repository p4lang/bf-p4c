#include <core.p4>
#include <tna.p4>

header test_h {
    bit<32>      flag;
    bit<32>      val;
}

struct headers {
    test_h       test;
}

struct metadata { }

parser ParserImpl(packet_in        pkt,
    out headers          hdr,
    out metadata         meta,
    out ingress_intrinsic_metadata_t  ig_intr_md)
{
    state start {
        pkt.extract(ig_intr_md);
        pkt.advance(PORT_METADATA_SIZE);
        transition parse_header;
    }

    state parse_header {
        pkt.extract(hdr.test);
        transition accept;
    }
}

control ingress(
    inout headers                       hdr,
    inout metadata                      meta,
    in    ingress_intrinsic_metadata_t               ig_intr_md,
    in    ingress_intrinsic_metadata_from_parser_t   ig_prsr_md,
    inout ingress_intrinsic_metadata_for_deparser_t  ig_dprsr_md,
    inout ingress_intrinsic_metadata_for_tm_t        ig_tm_md)
{
    Register<bit<32>,bit<32>>(1) vals0;
    RegisterAction<bit<32>,bit<32>,bit<32>>(vals0) vals0_write = {
        void apply(inout bit<32> value) {
            value = hdr.test.val;
        }
    };

    RegisterAction<bit<32>,bit<32>,bit<32>>(vals0) vals0_test = {
        void apply(inout bit<32> value, out bit<32> read_value){
            if(hdr.test.val > 2){
                read_value = value;
            } else {
                read_value = 32w2;
            }
        }
    };

    RegisterAction<bit<32>,bit<32>,bit<32>>(vals0) vals0_test2 = {
        void apply(inout bit<32> value, out bit<32> read_value){
            if(hdr.test.val > 2){
                read_value = -value;
            } else {
                read_value = 32w2;
            }
        }
    };

    RegisterAction<bit<32>,bit<32>,bit<32>>(vals0) vals0_test3 = {
        void apply(inout bit<32> value, out bit<32> read_value){
            if(hdr.test.val > 2){
                read_value = 32w2;
            } else {
                read_value = value;
            }
        }
    };

    action write() {
        vals0_write.execute(0);
    }
    action read() {
        hdr.test.val = vals0_test.execute(0);
    }
    action read2() {
        hdr.test.val = vals0_test2.execute(0);
    }
    action read3() {
        hdr.test.val = vals0_test3.execute(0);
    }

    table t {
        key = { hdr.test.flag : exact; }
        actions = {
            write;
            read;
            read2;
            read3;
        }
        const entries = {
            0 : write();
            1 : read();
            2 : read2();
            3 : read3();
        }
        size = 5;
    }

    apply {
        t.apply();
        ig_tm_md.ucast_egress_port = ig_intr_md.ingress_port;
    }
}

#include "common_tna_test.h"
