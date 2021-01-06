#include <tna.p4>

@pa_auto_init_metadata
#if __TARGET_TOFINO__ > 1
@phv_limit(H0-5)
#endif

struct metadata { 
    bit<16>     a;
    bit<16>     b;
    bit<16>     c;
}

#define METADATA_INIT(meta) \
    meta.a = 1; \
    meta.b = 2; \
    meta.c = 3; \

#include "trivial_parser.h"

control ingress(inout headers hdr, inout metadata meta,
                in ingress_intrinsic_metadata_t ig_intr_md,
                in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
                inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
                inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    action seta(bit<16> v) { meta.a = v; }
    action setb(bit<16> v) { meta.b = v; }
    action setc(bit<16> v) { meta.c = v; }
    action outa() { hdr.data.h1 = meta.a; }
    action outb() { hdr.data.h1 = meta.b; }
    action outc() { hdr.data.h1 = meta.c; }
    table t1 {
        key = { hdr.data.f1 : exact; }
        actions = { seta; setb; setc; }
        size = 1024; }
    table t2 {
        key = { hdr.data.f2 : exact; }
        actions = { outa; outb; outc; }
        size = 1024; }
    apply {
        ig_intr_tm_md.ucast_egress_port = 3;
        t1.apply();
        t2.apply();
    }
}

#include "common_tna_test.h"
