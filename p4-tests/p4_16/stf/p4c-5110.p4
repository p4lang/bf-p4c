#include <tna.p4>

struct metadata { }

#include "trivial_parser.h"

control ingress(inout headers hdr, inout metadata m,
                in ingress_intrinsic_metadata_t ig_intr_md,
                in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
                inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
                inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {

    bit<32> meta = 0;

    Register<bit<32>, _>(1) test_register;
    RegisterAction<bit<32>, _, bit<32>>(test_register) test_register_action = {
        void apply(inout bit<32>  store_valid_data, out bit<32> read_valid_data) {
            read_valid_data = store_valid_data;
            if ((int<32>)(hdr.data.f1 - store_valid_data) > 0) {
                store_valid_data = hdr.data.f1;
            }
        }
    };

    action test_action() {
        hdr.data.f2 = test_register_action.execute(0);
    }

    apply {
        ig_intr_tm_md.ucast_egress_port = 4;
        test_action();
        ig_intr_tm_md.bypass_egress = 1;
    }
}

#include "common_tna_test.h"
