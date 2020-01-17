#include <t2na.p4>

struct metadata {
    bit<16> src_port;
    bit<16> dst_port;
    @pa_container_size("ingress", "cache_id", 32)
    @pa_atomic("ingress", "cache_id")
    bit<19> cache_id;
    @pa_container_size("ingress", "learn_pred", 32)
    bit<16> learn_pred;
    bit<1>  new_flow_flag;
    bit<16> flow_id;
}

#define METADATA_INIT(M) \
    M.src_port = 0;  \
    M.dst_port = 0;  \
    M.cache_id = 0;  \
    M.learn_pred = 0; \
    M.new_flow_flag = 0; \
    M.flow_id = 0;

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
    action nop() {}
    action match_flow(bit<16> fid) { meta.flow_id = fid; }
    table cuckoo_match {
        actions = { match_flow; @defaultonly nop; }
        default_action = nop();
        key = {
            hdr.ipv4.src_addr : exact;
            hdr.ipv4.dst_addr : exact;
            hdr.ipv4.protocol : exact;
            meta.src_port : exact;
            meta.dst_port : exact;
        }
    }

    Register<pair, bit<14>>(16364) learn_cache;
    Hash<bit<14>>(HashAlgorithm_t.RANDOM) lookup_hash;
    LearnAction<pair, bit<14>, bit<64>, bit<32>>(learn_cache) learn_act = {
        void apply(inout pair value, in bit<64> digest, in bool lmatch,
                   out bit<32> cid, out bit<32> pred) {
            if (value.first & ~64w0x1f == digest) {
                value.first = digest | 31;
                cid = this.address(0);
            } else if (value.second & ~64w0x1f == digest) {
                value.second = digest | 31;
                cid = this.address(1);
            } else if (!lmatch && value.first & 1 == 0) {
                value.first = digest | 31;
                cid = this.address(0);
            } else if (!lmatch && value.second & 1 == 0) {
                value.second = digest | 31;
                cid = this.address(1);
            } else {
                cid = 0;
            }
            pred = this.predicate();
        }
    };
    action do_learn_match() {
        bit<32> tmp2;
        // hash skipping ports -- makes it easy to generate collisions
        bit<14> addr = lookup_hash.get({ hdr.ipv4.src_addr, hdr.ipv4.dst_addr, hdr.ipv4.protocol });
        bit<32> tmp = learn_act.execute(addr, tmp2);
        meta.cache_id = tmp[24:6];
        meta.learn_pred = tmp2[15:0];
    }

    table learn_match {
        key = {
            hdr.ipv4.src_addr : dleft_hash;
            hdr.ipv4.dst_addr : dleft_hash;
            hdr.ipv4.protocol : dleft_hash;
            meta.src_port : dleft_hash;
            meta.dst_port : dleft_hash;
        }
        actions = { do_learn_match; }
        default_action = do_learn_match;
    }

    /* new flow fifo -- source for new flowids from the driver */
    Register<bit<16>, _>(32767) fid_fifo;
    RegisterAction<bit<16>, _, bit<16>>(fid_fifo) new_fid = {
        void apply(inout bit<16> fid, out bit<16> rv) { rv = fid; } };
    action new_flow() {
        meta.new_flow_flag = 1;
        meta.flow_id = new_fid.dequeue(); }
    action old_flow() { meta.new_flow_flag = 0; }
    action failed_overflow() { meta.new_flow_flag = 0; }
    @stage(5)  // FIXME -- table_placement needs to put the tables using RegisterActions
               // in the same stage as the Register.
    table process_dleft_result {
        key = { meta.learn_pred : ternary; }
        actions = { new_flow; old_flow; failed_overflow; }
    }

    // only needed for stf to insert things into the input fifo
    RegisterAction<bit<16>, _, bit<16>>(fid_fifo) insert_fid = {
        void apply(inout bit<16> fid) { fid = meta.flow_id; } };
    action insert_new_fid() { insert_fid.enqueue(); }
    @stage(5)
    table do_insert_new_fid {
        actions = { insert_new_fid; }
        default_action = insert_new_fid(); }

    /* output fifo -- outputs cache ids of new flows */
    Register<bit<16>, _>(32768) output_fifo;
    RegisterAction<bit<16>, _, bit<16>>(output_fifo) report_cacheid = {
        void apply(inout bit<16> val) { val = meta.cache_id[15:0]; } };
    action do_report_cacheid() { report_cacheid.enqueue(); }

    /* map table -- records mapping from cache id to flow id */
    Register<map_pair, bit<15>>(32768) cid2fidmap;
    RegisterAction<map_pair, bit<15>, bit<16>>(cid2fidmap) register_new_flow = {
        void apply(inout map_pair val, out bit<16> rv) {
            val.cid = meta.cache_id[15:0];
            val.fid = meta.flow_id;
            rv = meta.flow_id; } };
    RegisterAction<map_pair, bit<15>, bit<16>>(cid2fidmap) existing_flow = {
        void apply(inout map_pair val, out bit<16> rv) {
            rv = val.fid; } };

    /* final flow packet counter */
    // FIXME -- t2na Counter broken?  crashes on CounterType_t.PACKETS
    Register<bit<16>, bit<16>>(4096) flow_counter;
    RegisterAction<bit<16>, bit<16>, bit<16>>(flow_counter) inc_flow_counter = {
        void apply(inout bit<16> val) { val = val + 1; } };

    apply {
        if (hdr.tcp.isValid()) {
            meta.src_port = hdr.tcp.src_port;
            meta.dst_port = hdr.tcp.dst_port;
        } else if (hdr.udp.isValid()) {
            meta.src_port = hdr.udp.src_port;
            meta.dst_port = hdr.udp.dst_port; }

        // only need this to prime the fifo with STF as it does not support directly pushing
        if (hdr.ethernet.ether_type == 0xffff) {
            meta.flow_id = hdr.ethernet.dst_addr[15:0];
            do_insert_new_fid.apply();
        } else {
            ig_intr_tm_md.ucast_egress_port = 3;
            if (!cuckoo_match.apply().hit) {
                learn_match.apply();
                meta.cache_id[14:13] = meta.cache_id[18:17];  // squeeze out excess vpn bits
                process_dleft_result.apply();
                if (meta.new_flow_flag == 1) {
                    do_report_cacheid();
                    register_new_flow.execute(meta.cache_id[14:0]);
                } else {
                    meta.flow_id = existing_flow.execute(meta.cache_id[14:0]);
                }
            }
            inc_flow_counter.execute(meta.flow_id);
        }
    }
}

#include "common_t2na_test.h"
