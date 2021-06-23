#include <core.p4>
#if __TARGET_TOFINO__ == 3
#include <t3na.p4>
#elif __TARGET_TOFINO__ == 2
#include <t2na.p4>
#else
#include <tna.p4>
#endif

struct metadata { }

#include "trivial_parser.h"

control ingress(inout headers hdr, inout metadata meta,
                in ingress_intrinsic_metadata_t ig_intr_md,
                in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
                inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
                inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {

    int<16> int16 = 0;
    bit<16> bit16 = 0;
    int<8>  int8 = 0;
    bit<8>  bit8 = 255;

    action bit8toint8(){
        int8 = (int<8>)bit8;
    }
    action int8toint16(){
        int16 = (int<16>)int8;
    }
    action bit8tobit16(){
        bit16 = (bit<16>)bit8;
    }
    action bit16toint16(){
        int16 = (int<16>)bit16;
    }
    action bit8toint16(){
        int16 = (int<16>)(int<8>)bit8;
    }
    action bit8toint16_2(){
        int16 = (int<16>)(bit<16>)bit8;
    }

    apply {
        bit8toint8();
        int8toint16();

        if (int16 !=0){
            bit8tobit16();
            bit16toint16();
        }
        if (int16 !=0){
            bit8toint16();
        }
        if (int16 !=0){
            bit8toint16_2();
        }
        if (int16 != 0){
            ig_intr_tm_md.ucast_egress_port = ig_intr_md.ingress_port;
            ig_intr_tm_md.bypass_egress = 1w1;
        }
    }
}

#include "common_tna_test.h"
