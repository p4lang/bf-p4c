#if __TARGET_TOFINO__ == 2
#include "t2na.p4"
#else
#include "tna.p4"
#endif

#define DATA_T_OVERRIDE
header data_t {
    bit<32> f1;
    bit<32> f2;
    bit<32> f3;
    bit<32> f4;
    bit<8>  b1;
    bit<8>  b2;
    bit<8>  b3;
    bit<8>  b4;
}

struct metadata {
}

#include "trivial_parser.h"

control ingress(inout headers hdr, inout metadata meta,
                in ingress_intrinsic_metadata_t ig_intr_md,
                in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
                inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
                inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    Hash<bit<16>>(HashAlgorithm_t.CRC16) hash_fn;
    Register<bit<1>, _>(1024) sel_register;
    ActionSelector(1024, hash_fn, SelectorMode_t.FAIR, sel_register) sel_profile;
    RegisterAction<bit<1>,_,bit<1>>(sel_register) port_down = {
        void apply(inout bit<1> value) {
            bit<1> in_value;
            in_value = value;
            value = 1w0;
        }
    };
    RegisterAction<bit<1>,_,bit<1>>(sel_register) port_up = {
        void apply(inout bit<1> value) {
            bit<1> in_value;
            in_value = value;
            value = 1w1;
        }
    };
    action set_output(bit<9> port) {
        ig_intr_tm_md.ucast_egress_port = port;
    }
    action set_port_up() {
        port_up.execute(hdr.data.b4);
        ig_intr_tm_md.ucast_egress_port = 0;
    }
    action set_port_down() {
        port_down.execute(hdr.data.b4);
        ig_intr_tm_md.ucast_egress_port = 0;
    }
    table select_output {
        actions = {
            set_output;
        }
        key = {
            hdr.data.b1: exact;
            hdr.data.f1: selector;
            hdr.data.f2: selector;
            hdr.data.f3: selector;
            hdr.data.f4: selector;
        }
        size = 1024;
        implementation = sel_profile;
    }
    table update_output {
        actions = {
            set_port_up;
            set_port_down;
        }
        key = {
            hdr.data.b3: exact;
        }
        size = 1024;
    }
    apply {
        if (hdr.data.b2 == 8w1) {
            update_output.apply();
        }
        else {
            select_output.apply();
        }
    }
}

#include "common_tna_test.h"
