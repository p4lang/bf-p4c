#include <jna.p4>

struct metadata {
    bit<16> src_port;
    bit<16> dst_port;
    bit<12> cache_id;
    bit<12> proxy_hash;
    bit<64> digest;
    bit<3> learn;
}
#define METADATA_INIT(M) \
    M.src_port = 0; \
    M.dst_port = 0; \
    M.cache_id = 0; \
    M.proxy_hash = 0; \
    M.digest = 1; \
    M.learn = 0;

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
    Hash<bit<32>>(HashAlgorithm_t.RANDOM) digest_hash;
    Hash<bit<12>>(HashAlgorithm_t.RANDOM) lookup_hash;
    action compute_digest() {
        meta.digest[63:32] = digest_hash.get({ hdr.ipv4.src_addr, hdr.ipv4.dst_addr,
                                               hdr.ipv4.protocol, meta.src_port, meta.dst_port }); }
    action compute_hash() {
        meta.proxy_hash = lookup_hash.get({ hdr.ipv4.src_addr, hdr.ipv4.dst_addr, hdr.ipv4.protocol,
                                            meta.src_port, meta.dst_port }); }
    action set_egress_port() { ig_intr_tm_md.ucast_egress_port = 3; }

    Register<pair>(4096) learn_cache;
    RegisterAction<pair, bit<32>>(learn_cache) learn_act = {
        void apply(inout pair value, out bit<32> cid, out bit<32> learn_match) {
            if (value.first & -31 == meta.digest) {
                value.first = value.first | 30;
                cid = this.address();
                learn_match = 2;
#if 0
            } else if (value.second & -31 == meta.digest) {
                value.second = value.second | 30;
                cid = this.address();
                learn_match = 3;
#endif
            } else if (value.first & 1 == 0) {
                value.first = meta.digest | 31;
                cid = this.address();
                learn_match = 4;
#if 0
            } else if (value.second & 1 == 0) {
                value.second = meta.digest | 31;
                cid = this.address();
                learn_match = 5;
#endif
            } else {
                cid = 0;
                learn_match = 0;
            }
        }
    };
    action do_learn_match() {
        bit<32> tmp2;
        bit<32> tmp = learn_act.execute(meta.proxy_hash, tmp2);
        meta.cache_id = tmp[11:0];
        meta.learn = tmp2[2:0];
    }
    @dleft_learn_cache
    table learn_match {
        actions = { do_learn_match; }
        default_action = do_learn_match;
        // FIXME -- frontend doesn't like implementation as anything other than
        // an action_profile, so use a pragma for now.
        // implementation = learn_act;
    }

    apply {
        if (hdr.tcp.isValid()) {
            meta.src_port = hdr.tcp.src_port;
            meta.dst_port = hdr.tcp.dst_port;
        } else if (hdr.udp.isValid()) {
            meta.src_port = hdr.udp.src_port;
            meta.dst_port = hdr.udp.dst_port; }
        compute_digest();
        compute_hash();
        set_egress_port();
        learn_match.apply();
        hdr.ipv4.identification = (bit<16>)meta.cache_id;
        hdr.ipv4.diffserv = (bit<8>)meta.learn;
    }
}

#include "common_jna_test.h"
