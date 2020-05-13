#include <t2na.p4>

struct metadata { }

#include "trivial_parser.h"

Register<bit<32>, bit<11>>(2048) ping_table;
Register<bit<32>, bit<11>>(2048) pong_table;

control ingress(inout headers hdr, inout metadata meta,
                in ingress_intrinsic_metadata_t ig_intr_md,
                in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
                inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md,
                inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md,
                in ghost_intrinsic_metadata_t gmd) {

    action noop() {}
    table skip_packet {
        key = { hdr.data.f2 : exact; }
        actions = { noop; } }

    RegisterAction<bit<32>, bit<11>, bit<32>>(ping_table) ping_read = {
        void apply(inout bit<32> value, out bit<32> rv) { rv = value; } };
    RegisterAction<bit<32>, bit<11>, bit<32>>(pong_table) pong_read = {
        void apply(inout bit<32> value, out bit<32> rv) { rv = value; } };

    apply {
        ig_intr_tm_md.ucast_egress_port = 3;
        if (!skip_packet.apply().hit) {
            if (gmd.ping_pong == 0) {
                hdr.data.f2 = ping_read.execute(hdr.data.h1[10:0]);
            } else {
                hdr.data.f2 = pong_read.execute(hdr.data.h1[10:0]);
            }
        }
    }
}

control ghost(in ghost_intrinsic_metadata_t md) {
    bit<11> register_idx;
    action set_register_idx(bit<11> idx) { register_idx = idx; }

    table map_register_idx {
        key = { md.qid : ternary; }
        actions = { set_register_idx; }
        default_action = set_register_idx(0); }

    RegisterAction<bit<32>, bit<11>, bit<32>>(ping_table) ping_update = {
        void apply(inout bit<32> value) { value = (bit<32>)md.qlength; } };
    RegisterAction<bit<32>, bit<11>, bit<32>>(pong_table) pong_update = {
        void apply(inout bit<32> value) { value = (bit<32>)md.qlength; } };

    apply {
        map_register_idx.apply();
        if (md.ping_pong == 1) {
            ping_update.execute(register_idx);
        } else {
            pong_update.execute(register_idx);
        }
    }
}

#define USE_GHOST ghost
#include "common_t2na_test.h"