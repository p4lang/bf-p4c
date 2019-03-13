// Hardware Learning.
//
// Header fields
//    or       _____________
//  Digest    |             |
//     ---->--| Match Table |---->---- Flow_id, ...
//       |    |_____________|
//       |          |
//       |          | Miss
//       |       ___V___                 _______
//       |      |       |               |  Map  |
//       ---->--| Cache |-->-- CID -->--| Table |---->---- Flow_id
//              |_______|               |_______|
//                  |                      ^
//                  | Miss(Learn)          |
//                  |                      |
//                  |    |  |              |     |  |
//                  ---->|==|-->-- FID --------->|==| Digest + FID
//                       |==|                    |==|
//                       |==|                    |==|
//


#define FLOW_CACHE_SIZE 64
#define TABLE_SIZE 256

typedef bit<18> fid_t;

extern Learning<T, I> {
    // bit<18> flow_id
    Learning(int size_, bool sweep_true);
    bit<18> learn(in T digest); //learn
    void invalidate(I index); // For cache-only
    void invalidate(T digest);
    // Invalidates the cache entry when the timestamp reaches zero.
    void decrement_ts(I index);
}

control NetFlow(in switch_header_t hdr) {
    fid_t flow_id;
    // Flow digest cannot be larget that 126 bits.
    bit<32> flow_digest;
    Learning(FLOW_CACHE_SIZE, bit<16>) netflow_cache;
    bool new_flow;
    hash<bit<32>>(HashAlgorithm_t.CRC32) hash_;

    action set_fid(fid_t fid) {
        flow_id = fid;
        new_flow = false;
        netflow_cache.invalidate(flow_digest);
    }

    table net_flow {
        key = { flow_digest : exact; }
        actions = {
            NoAction;
            set_fid;
        }

        size = TABLE_SIZE
    }

    table update_state {
        key = { flow_id; }
        actions = { NoAction; }
    }

    apply {
        flow_digest = hash_.get_hash({
            hdr.ipv4.src_addr,
            hdr.ipv4.dst_addr,
            hdr.ipv4.proto,
            hdr.tcp.src_port,
            hdr.tcp.dst_port});

        if (hdr.pktgen_timer.isValid()) {
            // This generally happens in a separate control block.
            netflow_cache.invalidate(hdr.pktgen_timer.packet_id);
        } else {
            new_flow = true;
            if(!net_flow.apply().hit) {
                NoAction : { fid = netflow_cache.learn(flow_digest) };
            }

            update_state.apply();
        }
    }
}
