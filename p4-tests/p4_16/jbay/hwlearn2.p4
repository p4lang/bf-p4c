#include <t2na.p4>

struct metadata {
    bit<16> src_port;
    bit<16> dst_port;
    bit<12> cache_id;
    bit<12> old_cache_id;
    bit<4> retire_stage;
    bit<16> flow_id;
    bit<1>  new_flow;
    bit<32> fix32w1;
    bit<32> tmp32;
    bit<16> tmp16;
    bit<64> digest;
    bit<16> learn;
    bit<4> learn_stage;
}
#define METADATA_INIT(M) \
    M.src_port = 0; \
    M.dst_port = 0; \
    M.cache_id = 0; \
    M.old_cache_id = 0; \
    M.retire_stage = 0; \
    M.flow_id = 0; \
    M.new_flow = 0; \
    M.fix32w1 = 1; \
    M.tmp32 = 0; \
    M.tmp16 = 0; \
    M.digest = 0; \
    M.learn = 0; \
    M.learn_stage = 0;

struct pair {
    bit<64>     first;
    bit<64>     second;
}
struct map_pair {
    bit<16>     cid;
    bit<16>     fid;
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
        meta.tmp32 = digest_hash.get({ hdr.ipv4.src_addr, hdr.ipv4.dst_addr,
                                       hdr.ipv4.protocol, meta.src_port, meta.dst_port }); }
    action set_egress_port() { ig_intr_tm_md.ucast_egress_port = 4; }

    /* 1st dleft cache table -- 1 way in one stage (so no sbus) */
    Register<pair, bit<12>>(4096) learn_cache_1;
    RegisterAction<pair, bit<12>, bit<32>>(learn_cache_1) learn_act_1 = {
        void apply(inout pair value, out bit<32> cid, out bit<32> pred) {
            if (value.first & ~64w30 == meta.digest) {
                value.first = meta.digest | 31;
                cid = this.address(0);
            } else if (value.second & ~64w30 == meta.digest) {
                value.second = meta.digest | 31;
                cid = this.address(1);
            } else if (value.first & 1 == 0) {
                value.first = meta.digest | 31;
                cid = this.address(0);
            } else if (value.second & 1 == 0) {
                value.second = meta.digest | 31;
                cid = this.address(1);
            } else {
                cid = 0;
            }
            pred = this.predicate();
        }
    };
    // we leave src_port out of the lookup hash so we can easily generate collisions
    action do_learn_match_1() {
        bit<32> tmp2;
        bit<12> addr = lookup_hash.get({ hdr.ipv4.src_addr, hdr.ipv4.dst_addr,
                                         hdr.ipv4.protocol, // meta.src_port,
                                         meta.dst_port });
        bit<32> tmp = learn_act_1.execute(addr, tmp2);
        meta.cache_id = tmp[17:6];
        meta.learn = tmp2[15:0];
        meta.learn_stage = 1;
    }
    table learn_match_1 {
        actions = { do_learn_match_1; }
        default_action = do_learn_match_1;
    }

    /* 2nd dleft cache table -- 1 way in one stage (so no sbus) */
    Register<pair, bit<12>>(4096) learn_cache_2;
    RegisterAction2<pair, bit<12>, bit<32>, bit<4>>(learn_cache_2) retire_act_2 = {
        void apply(inout pair value, out bit<32> cid, out bit<4> retire_stage) {
            if (value.first & ~64w30 == meta.digest) {
                value.first = 0;
                cid = this.address<bit<32>>(0);
                retire_stage = 2;
            } else if (value.second & ~64w30 == meta.digest) {
                value.second = 0;
                cid = this.address<bit<32>>(1);
                retire_stage = 2;
            } else {
                cid = 0;
                retire_stage = 0; }
        }
    };
    RegisterAction<pair, bit<12>, bit<32>>(learn_cache_2) learn_act_2 = {
        void apply(inout pair value, out bit<32> cid, out bit<32> pred) {
            if (value.first & ~64w30 == meta.digest) {
                value.first = meta.digest | 31;
                cid = this.address(0);
            } else if (value.second & ~64w30 == meta.digest) {
                value.second = meta.digest | 31;
                cid = this.address(1);
            } else if (value.first & 1 == 0) {
                value.first = meta.digest | 31;
                cid = this.address(0);
            } else if (value.second & 1 == 0) {
                value.second = meta.digest | 31;
                cid = this.address(1);
            } else {
                cid = 0;
            }
            pred = this.predicate();
        }
    };
    // we leave src_port out of the lookup hash so we can easily generate collisions
    action retire_match_2() {
        bit<12> addr = lookup_hash.get({ hdr.ipv4.src_addr, hdr.ipv4.dst_addr,
                                         hdr.ipv4.protocol, // meta.src_port,
                                         meta.dst_port });
        bit<32> tmp = retire_act_2.execute(addr, meta.retire_stage);
        meta.old_cache_id = tmp[17:6];
    }
    // we leave src_port out of the lookup hash so we can easily generate collisions
    action do_learn_match_2() {
        bit<32> tmp2;
        bit<12> addr = lookup_hash.get({ hdr.ipv4.src_addr, hdr.ipv4.dst_addr,
                                         hdr.ipv4.protocol, // meta.src_port,
                                         meta.dst_port });
        bit<32> tmp = learn_act_2.execute(addr, tmp2);
        meta.learn = tmp2[15:0];
        meta.learn_stage = 2;
    }
    table learn_match_2 {
        key = { meta.learn : ternary; }
        actions = { retire_match_2; do_learn_match_2; }
        // default_action = retire_match_2;
    }


    /* new flow fifo -- source for new flowids from the driver */
    Register<bit<32>, _>(4096) fid_fifo;
    RegisterAction<bit<32>, _, bit<32>>(fid_fifo) new_fid = {
        void apply(inout bit<32> fid, out bit<32> rv) { rv = fid; } };
    action new_flow() {
        meta.new_flow = 1;
        meta.flow_id = (bit<16>)new_fid.dequeue(); }
    action old_flow() { meta.new_flow = 0; }
    action move_flow() { meta.new_flow = 0; }
    action failed_overflow() { }
    @stage(5)
    table process_dleft_result {
        key = { meta.learn : ternary; meta.retire_stage : ternary; }
        actions = { new_flow; old_flow; move_flow; failed_overflow; }
    }

    // only needed for stf to insert things into the input fifo
    RegisterAction<bit<32>, _, bit<32>>(fid_fifo) insert_fid = {
        void apply(inout bit<32> fid) { fid = (bit<32>)meta.tmp16; } };
    action insert_new_fid() { insert_fid.enqueue(); }
    @stage(5)
    table do_insert_new_fid {
        actions = { insert_new_fid; }
        default_action = insert_new_fid(); }

    /* output fifo -- outputs cache ids of new flows */
    Register<bit<32>, _>(4096) output_fifo;
    RegisterAction<bit<32>, _, bit<32>>(output_fifo) report_cacheid = {
        void apply(inout bit<32> val) { val = (bit<32>)meta.cache_id; } };
    action do_report_cacheid() { report_cacheid.enqueue(); }

    /* map table -- records mapping from cache id to flow id.  Stages match the learn_match
     * stages in reverse ordder */
    action nop() {}
    Register<map_pair, bit<12>>(4096) cid2fidmap_2;
    RegisterAction<map_pair, bit<12>, bit<16>>(cid2fidmap_2) register_new_flow_2 = {
        void apply(inout map_pair val, out bit<16> rv) {
            val.cid = (bit<16>)meta.cache_id;
            val.fid = meta.flow_id;
            rv = meta.flow_id; } };
    RegisterAction<map_pair, bit<12>, bit<16>>(cid2fidmap_2) existing_flow_2 = {
        void apply(inout map_pair val, out bit<16> rv) {
            rv = val.fid; } };
    action new_flow_2() { register_new_flow_2.execute(meta.cache_id); }
    action old_flow_2() { meta.flow_id = existing_flow_2.execute(meta.cache_id); }
    table map_table_2 {
        key = {
            meta.new_flow : ternary;
            meta.learn_stage : ternary;
            meta.retire_stage : ternary; }
        actions = { new_flow_2; old_flow_2; nop; }
        default_action = nop(); }

    Register<map_pair, bit<12>>(4096) cid2fidmap_1;
    RegisterAction<map_pair, bit<12>, bit<16>>(cid2fidmap_1) register_new_flow_1 = {
        void apply(inout map_pair val, out bit<16> rv) {
            val.cid = (bit<16>)meta.cache_id;
            val.fid = meta.flow_id;
            rv = meta.flow_id; } };
    RegisterAction<map_pair, bit<12>, bit<16>>(cid2fidmap_1) existing_flow_1 = {
        void apply(inout map_pair val, out bit<16> rv) {
            rv = val.fid; } };
    action new_flow_1() { register_new_flow_1.execute(meta.cache_id); }
    action old_flow_1() { meta.flow_id = existing_flow_1.execute(meta.cache_id); }
    table map_table_1 {
        key = {
            meta.new_flow : ternary;
            meta.learn_stage : ternary;
            meta.retire_stage : ternary; }
        actions = { new_flow_1; old_flow_1; nop; }
        default_action = nop(); }

    /* final flow packet counter */
    // FIXME -- t2na Counter broken?  crashes on CounterType_t.PACKETS
    Register<bit<16>, bit<16>>(4096) flow_counter;
    RegisterAction<bit<16>, bit<16>, bit<16>>(flow_counter) inc_flow_counter = {
        void apply(inout bit<16> val) { val = val + 1; } };

    apply {
        meta.fix32w1 = 1;  // FIXME -- setting this to 1 in the parser doesn't work?
        if (hdr.tcp.isValid()) {
            meta.src_port = hdr.tcp.src_port;
            meta.dst_port = hdr.tcp.dst_port;
        } else if (hdr.udp.isValid()) {
            meta.src_port = hdr.udp.src_port;
            meta.dst_port = hdr.udp.dst_port;
        }

        // only need this to prime the fifo with STF as it does not support directly pushing
        if (hdr.ethernet.ether_type == 0xffff) {
            meta.tmp16 = hdr.ethernet.dst_addr[15:0];
            do_insert_new_fid.apply();
        } else {
            compute_digest();
            meta.digest[31:0] = meta.fix32w1;  // hack to force 32bit phv use
            meta.digest[63:32] = meta.tmp32;  // hack to force 32bit phv use
            set_egress_port();
            learn_match_1.apply();
            learn_match_2.apply();
            process_dleft_result.apply();
            if (meta.new_flow == 1) { do_report_cacheid(); }
            map_table_2.apply();
            map_table_1.apply();
            inc_flow_counter.execute(meta.flow_id);
        }
    }
}

#include "common_t2na_test.h"
