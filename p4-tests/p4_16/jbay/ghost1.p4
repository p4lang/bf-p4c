#include <jna.p4>

struct metadata { }

#include "trivial_parser.h"

Register<bit<32>>(2048) ping_table;
Register<bit<32>>(2048) pong_table;

control ingress(inout headers hdr, inout metadata meta,
                in ingress_intrinsic_metadata_t ig_intr_md,
                in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
                inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md,
                inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md,
                in ghost_intrinsic_metadata_t gh_intr_md) {

    RegisterAction<bit<32>, bit<32>>(ping_table) ping_read = {
        void apply(inout bit<32> value, out bit<32> rv) { rv = value; } };
    RegisterAction<bit<32>, bit<32>>(pong_table) pong_read = {
        void apply(inout bit<32> value, out bit<32> rv) { rv = value; } };

    apply {
        if (gh_intr_md.ping_pong == 0) {
            hdr.data.f2 = ping_read.execute(hdr.data.h1[10:0]);
        } else {
            hdr.data.f2 = pong_read.execute(hdr.data.h1[10:0]);
        }
    }
}

control ghost(in ghost_intrinsic_metadata_t md) {
    RegisterAction<bit<32>, bit<32>>(ping_table) ping_update = {
        void apply(inout bit<32> value) { value = (bit<32>)md.qlength; } };
    RegisterAction<bit<32>, bit<32>>(pong_table) pong_update = {
        void apply(inout bit<32> value) { value = (bit<32>)md.qlength; } };

    apply {
        if (md.ping_pong == 1) {
            ping_update.execute(md.qid);
        } else {
            pong_update.execute(md.qid);
        }
    }
}

#define USE_GHOST ghost
#include "common_jna_test.h"
