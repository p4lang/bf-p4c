#include <jna.p4>

struct metadata { }

struct pair {
    bit<64>     first;
    bit<64>     second;
}

#include "ipv4_parser.h"

control ingress(inout headers hdr, inout metadata meta,
                in ingress_intrinsic_metadata_t ig_intr_md,
                in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
                inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md,
                inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    bit<16> src_port = 0;
    bit<16> dst_port = 0;
    bit<12> cache_id;

    action match_flow(bit<16> fid) { }
    action new_flow() { }
    table cuckoo_match {
        actions = { match_flow; @default_only new_flow; }
        default_action = new_flow();
        key = {
            hdr.ipv4.src_addr : exact;
            hdr.ipv4.dst_addr : exact;
            hdr.ipv4.protocol : exact;
            src_port : exact;
            dst_port : exact;
        }
    }

    Register<pair>(4096) learn_cache;
    LearnAction<pair, bit<59>, bit<12>>(learn_cache) learn_act = {
        void apply(inout pair value, in bit<59> digest, in bool learn, out bit<2> match) {
            if (value.first & -31 == digest ++ 5w1) {
                value.first = value.first | 30;
                match = 1;
            } else if (value.second & -31 == digest ++ 5w1) {
                value.second = value.second | 30;
                match = 2;
            } else if (learn && value.first & 1 == 0) {
                value.first = digest ++ 5w31;
                match = 1;
            } else if (learn && value.second & 1 == 0) {
                value.second = digest ++ 5w31;
                match = 2;
            } else {
                match = 0;
            }
        }
    };
    action do_learn_match() {
        cache_id = learn_act.execute();
    }
    @dleft_learn_cache
    table learn_match {
        key = {
            hdr.ipv4.src_addr : exact;
            hdr.ipv4.dst_addr : exact;
            hdr.ipv4.protocol : exact;
            src_port : exact;
            dst_port : exact;
        }
        actions = { do_learn_match; }
        default_action = do_learn_match;
        // FIXME -- frontend doesn't like implementation as anything other than
        // an action_profile, so use a pragma for now.
        // implementation = learn_act;
    }

    apply {
        if (hdr.tcp.isValid()) {
            src_port = hdr.tcp.src_port;
            dst_port = hdr.tcp.dst_port;
        } else if (hdr.udp.isValid()) {
            src_port = hdr.udp.src_port;
            dst_port = hdr.udp.dst_port; }
        ig_intr_tm_md.ucast_egress_port = 3;
        if (!cuckoo_match.apply().hit) {
            learn_match.apply();
        }
    }
}

#include "common_jna_test.h"
