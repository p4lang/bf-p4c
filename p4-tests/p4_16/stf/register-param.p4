#include <core.p4>
#if __TARGET_TOFINO__ == 3
#include <t3na.p4>
#elif __TARGET_TOFINO__ == 2
#include <t2na.p4>
#else
#include <tna.p4>
#endif

struct metadata { }

struct pair {
    bit<32>     first;
    bit<32>     second;
}

#include "trivial_parser.h"

control ingress(inout headers hdr, inout metadata meta,
                in ingress_intrinsic_metadata_t ig_intr_md,
                in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
                inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
                inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {

    // Register parameters attached to an indirect register

    Register<bit<32>, bit<10>>(1024) reg1;

    RegisterParam<bit<32>>(0x01ABCDEF) reg1param1;
    RegisterParam<bit<32>>(0x0000FFFF) reg1param2;

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

    // Register parameters attached to an indirect register storing pairs of values

    Register<pair, bit<32>>(1024, {0, 0}) reg2;

    RegisterParam<bit<32>>(1) reg2param1;
    RegisterParam<bit<32>>(100) reg2param2;

    RegisterAction<pair, bit<10>, bit<32>>(reg2) reg2action1 = {
        void apply(inout pair value, out bit<32> read_value) {
            read_value = value.first;
        }
    };

    RegisterAction<pair, bit<10>, bit<32>>(reg2) reg2action2 = {
        void apply(inout pair value, out bit<32> read_value) {
            read_value = value.second;
        }
    };

    RegisterAction<pair, bit<10>, bit<32>>(reg2) reg2action3 = {
        void apply(inout pair value, out bit<32> read_value) {
            value.first = value.first + reg2param1.read();
            value.second = value.second + reg2param2.read();
        }
    };

    // Register parameters attached to a direct register

    DirectRegister<pair>({0, 0}) dirreg1;

    RegisterParam<bit<32>>(3) dirreg1param1;
    RegisterParam<bit<32>>(300) dirreg1param2;

    DirectRegisterAction<pair, bit<32>>(dirreg1) dirreg1action1 = {
        void apply(inout pair value, out bit<32> read_value) {
            read_value = value.first;
            value.first = value.first + dirreg1param1.read();
            value.second = value.second + dirreg1param2.read();
        }
    };

    action table1action1() {
        hdr.data.f1 = dirreg1action1.execute();
    }

    table table1 {
        key = {
            hdr.data.f1 : exact;
        }
        actions = {
            table1action1;
        }
        default_action = table1action1;
        registers = dirreg1;
    }

    apply {
        ig_intr_tm_md.ucast_egress_port = ig_intr_md.ingress_port;
        if (hdr.data.b1 == 0x00) {
            hdr.data.f1 = reg1action1.execute((bit<10>)ig_intr_md.ingress_port);
        } else if (hdr.data.b1 == 0x01) {
            reg1action2.execute((bit<10>)ig_intr_md.ingress_port);
        } else if (hdr.data.b1 == 0x02) {
            reg1action3.execute((bit<10>)ig_intr_md.ingress_port);
        } else if (hdr.data.b1 == 0x03) {
            reg1action4.execute((bit<10>)ig_intr_md.ingress_port);
        } else if (hdr.data.b1 == 0x10) {
            hdr.data.f1 = reg2action1.execute((bit<10>)ig_intr_md.ingress_port);
        } else if (hdr.data.b1 == 0x11) {
            hdr.data.f1 = reg2action2.execute((bit<10>)ig_intr_md.ingress_port);
        } else if (hdr.data.b1 == 0x12) {
            reg2action3.execute((bit<10>)ig_intr_md.ingress_port);
        } else if (hdr.data.b1 == 0x20) {
            table1.apply();
        }
    }
}

#include "common_tna_test.h"
