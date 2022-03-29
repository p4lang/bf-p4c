#include <t2na.p4>

struct metadata { }

#include "trivial_parser.h"

Register<bit<32>, bit<11>>(2048) p_table;

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

    RegisterAction<bit<32>, bit<11>, bit<32>>(p_table) p_read = {
        void apply(inout bit<32> value, out bit<32> rv) { rv = value; } };

    apply {
        if (!skip_packet.apply().hit) {
            hdr.data.f2 = p_read.execute(hdr.data.h1[10:0]);
        }
        ig_intr_tm_md.ucast_egress_port = 4;
    }
}

control ghost(in ghost_intrinsic_metadata_t md) {
    DirectCounter<bit<12>>(CounterType_t.PACKETS) dcounter;

    RegisterAction<bit<32>, bit<11>, bit<32>>(p_table) p_update = {
        void apply(inout bit<32> value) { value = (bit<32>)md.qlength; } };
    RegisterAction<bit<32>, bit<11>, bit<32>>(p_table) p_update_const = {
        void apply(inout bit<32> value) { value = (bit<32>)1; } };

    action do_p_update() {
        p_update.execute(md.qid);
        dcounter.count();
    }

    action do_p_update_const() {
        p_update_const.execute(md.qid);
        dcounter.count();
    }

    table p_update_tbl {
        key = {
            md.qid : exact;
        }
        actions = {
            do_p_update;
            do_p_update_const;
        }
        size = 8;
        counters = dcounter;
    }

    apply {
        p_update_tbl.apply();
    }
}

#define USE_GHOST ghost
#include "common_t2na_test.h"
