#if __TARGET_TOFINO__ >= 2
#include "t2na.p4"
#else
#include "tna.p4"
#endif

struct metadata {
    bool        flag;
}

struct pair {
    bit<8>      lo;
    bit<8>      hi;
}

#include "trivial_parser.h"

control ingress(inout headers hdr, inout metadata meta,
                in ingress_intrinsic_metadata_t ig_intr_md,
                in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
                inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
                inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {

    Register<bit<16>, bit<16>>(1024) quotas;
    RegisterAction<bit<16>, bit<16>, bool>(quotas) update_quota = {
        void apply(inout bit<16> reg, out bool flag) {
            flag = false;
            if (reg> 0) {
                reg= reg - 1;
                flag = true ;
            }
        }
    };

    apply {
        meta.flag = update_quota.execute(hdr.data.h1);
        if (meta.flag)
            ig_intr_tm_md.ucast_egress_port = 2;
        else
            ig_intr_tm_md.ucast_egress_port = 3;
    }
}

#include "common_tna_test.h"
