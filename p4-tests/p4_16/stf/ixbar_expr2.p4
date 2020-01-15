#if __TARGET_TOFINO__ == 3
#include <t3na.p4>
#elif __TARGET_TOFINO__ == 2
#include <t2na.p4>
#elif __TARGET_TOFINO__ == 1
#include <tna.p4>
#else
#error Unsupported target
#endif

struct metadata { }

struct pair {
    int<16>     lo;
    int<16>     hi;
}

#include "trivial_parser.h"

control ingress(inout headers hdr, inout metadata meta,
                in ingress_intrinsic_metadata_t ig_intr_md,
                in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
                inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
                inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    Register<pair, bit<1>>(1) accum;
    RegisterAction<pair, bit<1>, bit<16>>(accum) run = {
        void apply(inout pair value, out bit<16> rv) {
            value.lo = value.lo + (int<16>)(int<8>)hdr.data.b2;
            rv = (bit<16>)value.lo;
            value.hi = (int<16>)(hdr.data.b2 ++ hdr.data.b1); } };
    RegisterAction<pair, bit<1>, bit<16>>(accum) read = {
        void apply(inout pair value, out bit<16> rv) {
            rv = (bit<16>)value.hi; } };

    action do_run() {
        ig_intr_tm_md.ucast_egress_port = 3;
        hdr.data.h1 = run.execute(0); }
    action do_read() {
        ig_intr_tm_md.ucast_egress_port = 2;
        hdr.data.h1 = read.execute(0); }
    table test {
        key = { hdr.data.f1: exact; }
        actions = { do_run; do_read; }
        default_action = do_run();
    }

    apply {
        test.apply();
    }
}

#include "common_tna_test.h"
