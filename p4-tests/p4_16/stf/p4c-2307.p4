#if __TARGET_TOFINO__ == 2
#include "t2na.p4"
#else
#include "tna.p4"
#endif

struct metadata { }

struct pair_t {
    bit<16>      hash;
    bit<16>      data;
}

#include "trivial_parser.h"

control ingress(inout headers hdr, inout metadata meta,
                in ingress_intrinsic_metadata_t ig_intr_md,
                in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
                inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
                inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {

    bit<32> flowtable_hash;
    bit<16> flowtable_hash_hi;
    bit<16> flowtable_hash_lo;
    Register<pair_t, bit<32>>(32w1024) test_reg;
    RegisterAction<pair_t, bit<32>, bit<8>>(test_reg) test_reg_action = {
        void apply(
            inout pair_t reg_value,
            out bit<8> return_value
        ) {
            if((reg_value.hash == flowtable_hash[31:16]) && (reg_value.data != (bit<16>)ig_intr_md.ingress_port)) {
                return_value = 1;
            } else {
                return_value = 0;
            }
            reg_value.hash = (bit<16>)(flowtable_hash[31:16]);
            reg_value.data = (bit<16>)(ig_intr_md.ingress_port);
        }
    };
    Hash<bit<32>>(HashAlgorithm_t.CRC32) h;
    apply {
        bit<8> return_value;
        ig_intr_tm_md.ucast_egress_port = ig_intr_md.ingress_port;
        flowtable_hash = h.get({hdr.data.f1, hdr.data.f2, hdr.data.h1 });
        flowtable_hash_hi = flowtable_hash[31:16];
        flowtable_hash_lo = flowtable_hash[15: 0];
        return_value = test_reg_action.execute((bit<32>)flowtable_hash_lo);
        if (return_value != 0) {
            ig_intr_md_for_dprsr.drop_ctl = 0x1;
        }

    }
}

#include "common_tna_test.h"
