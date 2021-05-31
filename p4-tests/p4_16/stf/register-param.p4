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

    RegisterParam<bit<32>>(0x01ABCDEF) reg1param1;
    RegisterParam<bit<32>>(0x0000FFFF) reg1param2;

    Register<bit<32>, bit<10>>(1024) reg1;

    RegisterAction<bit<32>, bit<10>, bit<32>>(reg1) reg1action1 = {
        void apply(inout bit<32> value, out bit<32> read_value) {
            read_value = reg1param1.read();
        }
    };

    RegisterAction<bit<32>, bit<10>, bit<32>>(reg1) reg1action2 = {
        void apply(inout bit<32> value, out bit<32> read_value) {
            if (hdr.data.f1 < reg1param2.read())
                value = hdr.data.f1;
        }
    };

    RegisterAction<bit<32>, bit<10>, bit<32>>(reg1) reg1action3 = {
        void apply(inout bit<32> value, out bit<32> read_value) {
            if (hdr.data.f1 - value > reg1param2.read())
                value = hdr.data.f1;
        }
    };

    RegisterAction<bit<32>, bit<10>, bit<32>>(reg1) reg1action4 = {
        void apply(inout bit<32> value, out bit<32> read_value) {
            value = reg1param1.read();
        }
    };

    apply {
        ig_intr_tm_md.ucast_egress_port = ig_intr_md.ingress_port;
        if (hdr.data.b1 == 0) {
            hdr.data.f1 = reg1action1.execute((bit<10>)ig_intr_md.ingress_port);
        } else if (hdr.data.b1 == 1) {
            reg1action2.execute((bit<10>)ig_intr_md.ingress_port);
        } else if (hdr.data.b1 == 2) {
            reg1action3.execute((bit<10>)ig_intr_md.ingress_port);
        } else if (hdr.data.b1 == 3) {
            reg1action4.execute((bit<10>)ig_intr_md.ingress_port);
        }
    }
}

#include "common_tna_test.h"
