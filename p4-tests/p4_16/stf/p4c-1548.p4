#if __TARGET_TOFINO__ == 3
#include <t3na.p4>
#elif __TARGET_TOFINO__ == 2
#include <t2na.p4>
#elif __TARGET_TOFINO__ == 1
#include <tna.p4>
#else
#error Unsupported target
#endif

typedef bit<32> FlowCounter;

struct metadata {
    FlowCounter         res;
    bit<32>             carry_min;
}

#define FLOW_TABLE_SIZE_EACH    256

#include "trivial_parser.h"
                
control ingress(inout headers hdr, inout metadata meta,
                in ingress_intrinsic_metadata_t ig_intr_md,
                in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
                inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
                inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {

    Register<FlowCounter, bit<8> >(FLOW_TABLE_SIZE_EACH)  flow_table_ctrs_2;

    RegisterAction<FlowCounter, bit<8>, bit<8>>(flow_table_ctrs_2) flow_table_ctrs_2_read_cmp_action = {
        void apply(inout FlowCounter val, out bit<8> rv) {
            rv = 0;
            if (val == 0) {
                rv = 1;
            } else if (meta.carry_min > val) {
                rv = 2;
            }
            val = val + 1;
        }
    };
    
    apply {
        meta.carry_min = hdr.data.f1;
        ig_intr_tm_md.ucast_egress_port = 3;
        hdr.data.b2 = flow_table_ctrs_2_read_cmp_action.execute(hdr.data.b1);
    }
}

#include "common_tna_test.h"


