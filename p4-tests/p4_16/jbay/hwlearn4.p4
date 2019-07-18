#include <t2na.p4>

#define INVALID_FID (~32w0)

#define STATE_SIZE (23 * 1024)
#define CID_VPN_BITS 3 // 8 VPNs
#define CACHE_WAY_SIZE ((1<<CID_VPN_BITS)*1024)
#define CACHE_STAGE_SZ (CACHE_WAY_SIZE*4) // Four ways of 8k lines (16k buckets)
#define CACHE_WAY_IDX_BITS 13     // To address CACHE_WAY_SIZE entries
#define CACHE_WAY_AGE_IDX_BITS (CACHE_WAY_IDX_BITS+1)
#define MAP_STAGE_SZ  (2*CACHE_STAGE_SZ)
#define MAP_IDX_BITS (CACHE_WAY_IDX_BITS+1+2) // +1 for two buckets/line, +2 for way
#define FID_ALLOCATOR_SZ (64*1024)

/* The layout of a 64 bit cache entry is:
 * [63:60] Unused
 * [59:59] Parity bit for digest hash
 * [58:9]  50 Bit Digest
 * [8:8]   Valid2 - Bit0 of digest is always 1
 * [7:6]   Unused
 * [5:5]   Aged-Out (only need for cache-only implementations)
 * [4:1]   TTL
 * [0:0]   Valid bit for TMatch
 */
#define ENTRY_CMP_MASK (64w0xFFFFFFFFFFFFF00) // Ignores bits 7:0 and 63:60
#define ENTRY_DEL_MASK (~32w0x101) // Clears bits 8 and 0
struct reg64x2 {
  bit<64> a;
  bit<64> b;
}
struct reg32x2 {
  bit<32> lo;
  bit<32> hi;
}
struct reg16x2 {
  bit<16> lo;
  bit<16> hi;
}

header ethernet_hdr {
  bit<48> dst;
  bit<48> src;
  bit<16> etype;
}
header ipv4_hdr {
  bit<4>  version;
  bit<4>  ihl;
  bit<6>  dscp;
  bit<2>  ecn;
  bit<16> total_len;
  bit<16> identification;
  bit<1>  unused;
  bit<1>  dont_frag;
  bit<1>  more_frag;
  bit<13> frag_offset;
  bit<8>  ttl;
  bit<8>  protocol;
  bit<16> cksum;
  bit<32> src;
  bit<32> dst;
}
header tcp_hdr {
  bit<16> src;
  bit<16> dst;
  bit<32> seq_num;
  bit<32> ack_num;
  bit<4>  hlen;
  bit<6>  rsvd;
  bit<1>  urg;
  bit<1>  ack;
  bit<1>  psh;
  bit<1>  rst;
  bit<1>  syn;
  bit<1>  fin;
  bit<16> window;
  bit<16> cksum;
  bit<16> urgent;
}
header udp_hdr {
    bit<16> src;
    bit<16> dst;
    bit<16> hlen;
    bit<16> cksum;
}


struct headers {
    ethernet_hdr ethernet;
    ipv4_hdr     ipv4;
    tcp_hdr      tcp;
    udp_hdr      udp;
}

struct metadata {
  @pa_container_size("ingress", "md.fid", 32)
  @pa_container_size("ingress", "md.cid", 32)
  @pa_container_size("ingress", "md.flush_cid", 32)
  @pa_container_size("ingress", "md.learn_res", 32)
  @pa_container_size("ingress", "md.flush_res", 32)
  @pa_solitary("ingress", "md.fid")
  @pa_solitary("ingress", "md.cid")
  @pa_solitary("ingress", "md.flush_cid")
  @pa_solitary("ingress", "md.learn_res")
  @pa_solitary("ingress", "md.flush_res")

  bit<16> sport;
  bit<16> dport;
  bit<32> fid;

  /* The cid layout is as follows:
   * The ALU outputs 30 bits
   *   [29:25] stage
   *   [24:23] alu
   *   [22:17] VPN
   *   [16:7]  line
   *   [6:0]   subword
   * We need the top bit of subword to say which 64-bit bucket it is.
   * We need all 10 bits of line.
   * We need a variable number of VPN bits based on the table size.
   * The ALU bits identify the "way" in the stage.
   * We need enough stage bits to identify which stage of cache it is.
   * This results in:
   *   [17:16] stage (Assumes 3 stages)
   *   [15:14] alu (Assumes four ways per stage)
   *   [13:11] VPN (Assumes three bits of VPN)
   *   [10:1]  line
   *   [0:0]   subword
   * In the action which runs the ALU we drop the lower subword bits but we do
   * not compress the extra VPN bits which gives us the following intermediate
   * format:
   *   [23:19] stage
   *   [18:17] alu
   *   [16:11] VPN
   *   [10:1]  line
   *   [0:0]   subword
   */
  bit<26> cid;
  bit<26> flush_cid;

  bit<1>  learn_requested;
  bit<1>  flush_requested;
  bit<16> learn_res; /* 16-bit 1-hot encoded predication result */
  bit<16> flush_res; /* 16-bit 1-hot encoded predication result */

  bit<1> map_0_set;
  bit<1> map_0_get;
  bit<1> map_0_clr;
  bit<1> map_0_get_clr;
  bit<1> map_1_set;
  bit<1> map_1_get;
  bit<1> map_1_clr;
  bit<1> map_1_get_clr;
  bit<1> map_2_set;
  bit<1> map_2_get;
  bit<1> map_2_clr;
  bit<1> map_2_get_clr;

  bit<1> learn_event;
}

/*
 * This is the one hot encoded predication result for the learn_X_op stateful
 * ALU instructions.  C1 and C2 are the cache-hit conditions, C3 and C4 are the
 * cache-learn conditions, if none of the conditions are true then we neither
 * hit or learnt in the cache-way.
 * C4 C3 C2 C1  16 Bit Result
 * 0  0  0  0   0000000000000001 1     Miss - See note below
 * 0  0  0  1   0000000000000010 2     Hit
 * 0  0  1  0   0000000000000100 4     Hit
 * 0  0  1  1   0000000000001000 8     Hit
 * 0  1  0  0   0000000000010000 16    Learn
 * 0  1  0  1   0000000000100000 32    Hit
 * 0  1  1  0   0000000001000000 64    Hit
 * 0  1  1  1   0000000010000000 128   Hit
 * 1  0  0  0   0000000100000000 256   Learn
 * 1  0  0  1   0000001000000000 512   Hit
 * 1  0  1  0   0000010000000000 1024  Hit
 * 1  0  1  1   0000100000000000 2048  Hit
 * 1  1  0  0   0001000000000000 4096  Learn
 * 1  1  0  1   0010000000000000 8192  Hit
 * 1  1  1  0   0100000000000000 16384 Hit
 * 1  1  1  1   1000000000000000 32768 Hit
 * Note - An output of 1 will never be seen.  Each SALU predicates its output on
 * the compare results such that if all conditions are false the output is
 * disabled and the output is zero.
 *
 * This is the one hot encoded predication result for the flush_X_op stateful
 * ALU instructions.  C1 and C2 are the cache-hit and clear conditions.
 * C2 C1  16 Bit Result
 * 0  0   0000000000000001 1     Miss
 * 0  1   0000000000000010 2     Hit (cleared bucket 0)
 * 1  0   0000000000000100 4     Hit (cleared bucket 1)
 * 1  1   0000000000001000 8     Hit (unexpected, both buckets matched!)
 */

#define WAS_LEARN(res) ((res) == 16 || (res) == 256 || (res) == 4096)
#define WAS_MISS(res)  ((res) == 1)
#define WAS_HIT(res)   (res != 0 && !WAS_LEARN(res) && !WAS_MISS(res))
#define WAS_FLUSH(res) ((res) == 2 || (res) == 4)

parser iPrsr(packet_in packet, out headers hdr, out metadata md,
             out ingress_intrinsic_metadata_t ig_intr_md) {
  state start {
    packet.extract(ig_intr_md);
    transition select(ig_intr_md.resubmit_flag) {
      1 : parse_resubmit;
      0 : parse_non_resubmit;
    }
  }
  state parse_resubmit {
    packet.advance(128);
    packet.advance(64);
    md.learn_res = 0;
    md.learn_res = 1;
    transition parse_pkt_headers;
  }
  state parse_non_resubmit {
    packet.advance(128);
    packet.advance(64);
    transition parse_pkt_headers;
  }
  state parse_pkt_headers {
    packet.extract(hdr.ethernet);
    packet.extract(hdr.ipv4);
    transition select(hdr.ipv4.protocol) {
      6  : parse_tcp;
      17 : parse_udp;
      default : accept;
    }
  }
  state parse_tcp {
    packet.extract(hdr.tcp);
    transition accept;
  }
  state parse_udp {
    packet.extract(hdr.udp);
    transition accept;
  }
}

control cache_stage(in headers hdr, in bit<16> sport, in bit<16> dport,
                    in bit<1> learn_requested, in bit<1> flush_requested,
                    inout bit<16> learn_result, inout bit<16> flush_result,
                    inout bit<26> cid, inout bit<26> flush_cid)
                    (bit<2> stage) {
  Hash<bit<CACHE_WAY_IDX_BITS>>(HashAlgorithm_t.RANDOM) lookup_hash;

  Register<reg64x2, bit<CACHE_WAY_IDX_BITS>>(CACHE_STAGE_SZ) cache_way;
  LearnAction<reg64x2, bit<CACHE_WAY_IDX_BITS>, bit<64>, bit<32>>(cache_way) learn_op = {
    void apply(inout reg64x2 value, in bit<64> lkup_key, in bool lmatch, out bit<32> full_cid, out bit<32> pred_result) {

      /* Mask off the extra bits and compare only the digest to the lookup key.
       * Note that the lookup key is a 52 bit digest with the first bit set to
       * one as an additional valid bit.  If it matches then it is a cache hit.
       */
      if (value.a & ENTRY_CMP_MASK == lkup_key) {
        /* Refresh the timestamp on hit by writing the key back and ORing in the
         * control bits. */
        value.a = lkup_key | 0x1F;
        full_cid = this.address(0);
        pred_result = this.predicate();
      }

      /* Didn't hit on the first bucket, perform the same check against the
       * second bucket. */
      else if (value.b & ENTRY_CMP_MASK == lkup_key) {
        /* Refresh the timestamp on hit by writing the key back and ORing in the
         * control bits. */
        value.b = lkup_key | 0x1F;
        full_cid = this.address(1);
        pred_result = this.predicate();
      }

      /* Didn't hit on either bucket.  If the first bucket is empty we can
       * learn there. */
      else if (!lmatch && value.a & 0x1 == 0) {
        value.a = lkup_key | 0x1F;
        full_cid = this.address(0);
        pred_result = this.predicate();
      }

      /* First bucket is occupied, check if the second bucket is empty. */
      else if (!lmatch && value.b & 0x1 == 0) {
        value.b = lkup_key | 0x1F;
        full_cid = this.address(1);
        pred_result = this.predicate();
      }

      else {
        full_cid = 0;
        pred_result = 0;
      }

    }
  };

  LearnAction<reg64x2, bit<CACHE_WAY_IDX_BITS>, bit<64>, bit<32>>(cache_way) flush_op = {
    void apply(inout reg64x2 value, in bit<64> lkup_key, in bool lmatch, out bit<32> full_cid, out bit<32> pred_result) {
      /* Mask off the TTL and check if the upper 60 bits (digest, padding, and
       * valid bit match our lookup key.  If so it is a cache hit and the entry
       * should be cleared.  The instruction can only access the lower 32 bits
       * of the 64 bit cache entry so we cannot zero the entire bucket.  Instead
       * just turn off the valid bit. */
      if (value.a & ENTRY_CMP_MASK == lkup_key) {
        //value.a[31:0] = value.a[31:0] & ENTRY_DEL_MASK;
        value.a = 0;
        pred_result = this.predicate();
        full_cid = this.address(0);
      }

      /* Didn't match the first bucket, perform the same check against the
       * second bucket. */
      else if (value.b & ENTRY_CMP_MASK == lkup_key) {
        //value.b[31:0] = value.b[31:0] & ENTRY_DEL_MASK;
        value.b = 0;
        pred_result = this.predicate();
        full_cid = this.address(1);
      }

      else {
        pred_result = 0;
        full_cid = 0;
      }

    }
  };

  /* Note the register size is different here.  We need to sweep each 64 bit
   * bucket, not 128 bit pairs of buckets.  */
  RegisterAction<reg32x2, bit<CACHE_WAY_AGE_IDX_BITS>, bit<32>>(cache_way) age_op = {
    void apply(inout reg32x2 value) {
      /* Check if the entry is valid. */
      if (value.lo & 1 == 1) {
        /* Check if the entry has a TTL of one and age it out if it does
         * otherwise decrement the TTL by one. */
        if (value.lo & 0x1F == 3) {
          value.lo = 0;
          value.hi = 0;
        } else {
          value.lo = value.lo - 2;
        }
      }
    }
  };

  action search_with_learn() {
    bit<CACHE_WAY_IDX_BITS> search_addr = lookup_hash.get({hdr.ipv4.src,
                                                           hdr.ipv4.dst,
                                                           hdr.ipv4.protocol,
                                                           sport,
                                                           dport});
    bit<32> full_pred_result;
    bit<32> full_cid = learn_op.execute(search_addr, full_pred_result);
    cid = full_cid[31:6];
    learn_result = full_pred_result[19:4];
    flush_result = 0; /* Flush result set to 0 so next stage tries to flush. */
  }

  action flush() {
    bit<CACHE_WAY_IDX_BITS> search_addr = lookup_hash.get({hdr.ipv4.src,
                                                           hdr.ipv4.dst,
                                                           hdr.ipv4.protocol,
                                                           sport,
                                                           dport});
    bit<32> full_pred_result;
    bit<32> full_cid = flush_op.execute(search_addr, full_pred_result);
    flush_cid = full_cid[31:6];
    flush_result = full_pred_result[19:4];
  }

  action nop() { }

  action age(bit<CACHE_WAY_AGE_IDX_BITS> idx) {
    age_op.execute(idx);
  }

  table flow_cache {
    key = {
      hdr.ipv4.src      : dleft_hash;
      hdr.ipv4.dst      : dleft_hash;
      hdr.ipv4.protocol : dleft_hash;
      sport             : dleft_hash;
      dport             : dleft_hash;
      learn_requested   : ternary;
      flush_requested   : ternary;
      learn_result      : ternary;
      flush_result      : ternary;
    }
    actions = { search_with_learn; flush; nop; }
    default_action = nop();
    size = 512;
    /*
    size = 2;
    const entries = {
      (_,_,_,_,_,1,1,0,_) : search_with_learn();
      (_,_,_,_,_,_,1,_,0) : flush();
    }
    */
  }
  table age_tbl {
    key = {}
    actions = { nop; age; }
    size = 1;
    default_action = nop;
  }

  apply {
    if (hdr.ethernet.isValid()) {
      flow_cache.apply();
    } else {
      age_tbl.apply();
    }
  }
}

control fid_allocator(out bit<32> fid, out bit<1> learn_event)() {
  Register<bit<32>, bit<32>>(FID_ALLOCATOR_SZ) free_fids;
  RegisterAction<bit<32>, bit<32>, bit<32>>(free_fids) get_flow_id_op = {
    void apply(inout bit<32> value, out bit<32> rv) {
      rv = value;
    }
    void underflow(inout bit<32> value, out bit<32> rv) {
      rv = INVALID_FID;
    }
  };
  action do_get_flow_id() {
    fid = get_flow_id_op.dequeue();
    learn_event = 1;
  }
  table get_flow_id {
    actions = { do_get_flow_id; }
    default_action = do_get_flow_id();
  }

  apply {
    get_flow_id.apply();
  }
}

control map_stage(in bit<16> learn_res, in bit<16> flush_res,
                  in bit<MAP_IDX_BITS> learn_cid, in bit<MAP_IDX_BITS> flush_cid,
                  in bit<2>  learn_stg, in bit<2>  flush_stg,
                  out bit<1> set, out bit<1> get, out bit<1> clr, out bit<1> get_clr,
                  inout bit<32> fid)(bit<2> stage) {
  Register<bit<32>, bit<MAP_IDX_BITS>>(MAP_STAGE_SZ) map;
  RegisterAction<bit<32>, bit<MAP_IDX_BITS>, bit<32>>(map) get_fid_op = {
    void apply(inout bit<32> value, out bit<32> rv) {
      rv = value;
    }
  };
  RegisterAction<bit<32>, bit<MAP_IDX_BITS>, bit<32>>(map) set_fid_op = {
    void apply(inout bit<32> value) {
      value = fid;
    }
  };
  RegisterAction<bit<32>, bit<MAP_IDX_BITS>, bit<32>>(map) rd_clr_fid_op = {
    void apply(inout bit<32> value, out bit<32> rv) {
      rv = value;
      value = 0xFFFFFFFF;
    }
  };
  RegisterAction<bit<32>, bit<MAP_IDX_BITS>, bit<32>>(map) clr_fid_op = {
    void apply(inout bit<32> value) {
      value = 0xFFFFFFFF;
    }
  };
  action log_map_result(bit<1> a, bit<1> b, bit<1> c, bit<1> d) {
     set = a;
     get = b;
     clr = c;
     get_clr = d;
  }
  action do_get_fid() {
    fid = get_fid_op.execute(learn_cid);
    log_map_result(0, 1, 0, 0);
  }
  table map_get_fid {
    actions = { do_get_fid; }
    default_action = do_get_fid();
  }
  action do_set_fid() {
    set_fid_op.execute(learn_cid);
    log_map_result(1, 0, 0, 0);
  }
  table map_set_fid {
    actions = { do_set_fid; }
    default_action = do_set_fid();
  }
  action do_rd_clr_fid() {
    fid = rd_clr_fid_op.execute(flush_cid);
    log_map_result(0, 0, 0, 1);
  }
  table map_rd_clr_fid {
    actions = { do_rd_clr_fid; }
    default_action = do_rd_clr_fid();
  }
  action do_clr_fid() {
    clr_fid_op.execute(flush_cid);
    log_map_result(0, 0, 1, 0);
  }
  table map_clr_fid {
    actions = { do_clr_fid; }
    default_action = do_clr_fid();
  }

  apply {
    /* If there was a successful cache flush then clear the map entry for the
     * cid.  If this was a move case then we need to hold onto the FID from
     * this entry. */
    if (stage == flush_stg && WAS_FLUSH(flush_res)) {
      if (fid == INVALID_FID) {
        map_rd_clr_fid.apply();
      } else {
        map_clr_fid.apply();
      }
    }

    /* If a learn event happened then we write the FID into the map. */
    else if (stage == learn_stg && WAS_LEARN(learn_res)) {
      map_set_fid.apply();
    }

    /* If a cache hit happened then we read the entry out of the map. */
    else if (stage == learn_stg && WAS_HIT(learn_res)) {
      map_get_fid.apply();
    }
  }
}

control cpu_notify_fifo(inout headers hdr, inout metadata md)() {
  Register<bit<32>, bit<32>>(FID_ALLOCATOR_SZ) fid_notify;
  RegisterAction<bit<32>, bit<32>, bit<32>>(fid_notify) notify_op = {
    void apply(inout bit<32> value) {
      value = md.fid;
    }
  };
  action do_notify_cpu_of_fid() {
     notify_op.enqueue();
  }
  table notify_cpu_of_fid {
    actions = { do_notify_cpu_of_fid; }
    default_action = do_notify_cpu_of_fid();
  }

  apply {
    notify_cpu_of_fid.apply();
  }
}

control ingr(inout headers hdr, inout metadata md,
             in ingress_intrinsic_metadata_t ig_intr_md,
             in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
             inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md,
             inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
  Hash<bit<32>>(HashAlgorithm_t.IDENTITY) identity_hash;

  action do_set_dest() {
    ig_intr_tm_md.ucast_egress_port = ig_intr_md.ingress_port;
    ig_intr_tm_md.bypass_egress = 1w1;
  }
  action do_set_no_dest() {
    ig_intr_dprsr_md.drop_ctl = 7;
  }
  table set_dest {
    actions = { do_set_dest; do_set_no_dest; }
    default_action = do_set_dest;
  }

  /*
   * Cache Tables
   */
  cache_stage(0) cache_stg_0;
  cache_stage(1) cache_stg_1;
  cache_stage(2) cache_stg_2;

  /*
   * Flow Id Allocator
   */
  fid_allocator() fid_alloc;

  /*
   * Map Tables
   */
  map_stage(2) map_stg_2;
  map_stage(1) map_stg_1;
  map_stage(0) map_stg_0;

  /*
   * Learn Notification FIFO to CPU
   */
  cpu_notify_fifo() notify;

  /*
   * Main Match Table
   */
  action learn_flow() {
    md.learn_requested = 1;
    md.flush_requested = 1;
    md.learn_res = 0;
    md.flush_res = 0;
    md.fid = INVALID_FID;
  }
  action dont_learn() {
    md.learn_requested = 0;
    md.flush_requested = 1;
    md.learn_res = 0;
    md.flush_res = 0;
  }
  action assign_id(bit<32> fid) {
    md.fid = fid;
    md.learn_requested = 0;
    md.flush_requested = 1;
    md.learn_res = 0;
    md.flush_res = 0;
  }
  table flow_v4 {
    key = {
      hdr.ipv4.src : exact;
      hdr.ipv4.dst : exact;
      hdr.ipv4.protocol : exact;
      md.sport : exact;
      md.dport : exact;
    }
    actions = {
      assign_id;
      learn_flow;
      dont_learn;
    }

    size = STATE_SIZE;
    idle_timeout = true;
  }

  /*
   * State Tables
   */
  Register<reg32x2, bit<32>>(STATE_SIZE) ips;
  RegisterAction<reg32x2, bit<32>, bit<32>>(ips) write_ips = {
    void apply(inout reg32x2 value) {
      value.lo = hdr.ipv4.src;
      value.hi = hdr.ipv4.dst;
    }
  };

  Register<reg16x2, bit<32>>(STATE_SIZE) ports;
  RegisterAction<reg16x2, bit<32>, bit<32>>(ports) write_ports = {
    void apply(inout reg16x2 value) {
      value.lo = md.sport;
      value.hi = md.dport;
    }
  };

  Register<bit<8>, bit<32>>(STATE_SIZE) protocol;
  RegisterAction<bit<8>, bit<32>, bit<32>>(protocol) write_protocol = {
    void apply(inout bit<8> value) {
      value = hdr.ipv4.protocol;
    }
  };

  Counter<bit<1>, bit<32>>(STATE_SIZE, CounterType_t.PACKETS_AND_BYTES) flow_cntr;
  action log_ips() {
    bit<32> idx = identity_hash.get({md.fid});
    write_ips.execute(idx);
  }
  action log_ports() {
    bit<32> idx = identity_hash.get({md.fid});
    write_ports.execute(idx);
  }
  action log_protocol() {
    bit<32> idx = identity_hash.get({md.fid});
    write_protocol.execute(idx);
  }
  action count_flow() {
    bit<32> idx = identity_hash.get({md.fid});
    flow_cntr.count(idx);
  }

  action do_resubmit_to_flush() {
    ig_intr_dprsr_md.resubmit_type = 0;
    exit;
  }
  table resubmit_to_flush {
    actions = { do_resubmit_to_flush; }
    default_action = do_resubmit_to_flush();
  }

  action do_discard() {
    ig_intr_dprsr_md.drop_ctl = 1;
  }
  table discard {
    actions = { do_discard; }
    default_action = do_discard();
  }

  /*
   * Dummy table so that fields are not eliminated by compiler.
   */
  action nothing() {}
  table dead_code {
    key = {
      #if 0
      md.tried_learn_0 : exact;
      md.tried_learn_1 : exact;
      md.tried_learn_2 : exact;
      md.tried_flush_0 : exact;
      md.tried_flush_1 : exact;
      md.tried_flush_2 : exact;
      #endif
      md.map_0_set     : exact;
      md.map_0_get     : exact;
      md.map_0_clr     : exact;
      md.map_0_get_clr : exact;
      md.map_1_set     : exact;
      md.map_1_get     : exact;
      md.map_1_clr     : exact;
      md.map_1_get_clr : exact;
      md.map_2_set     : exact;
      md.map_2_get     : exact;
      md.map_2_clr     : exact;
      md.map_2_get_clr : exact;
    }
    actions = { nothing; do_discard; }
    default_action = nothing();
    size = 519;
  }

  apply {

    if (ig_intr_md.resubmit_flag == 0) {
      /* Send the packet out the same port it came in on. */
      set_dest.apply();

      /* Populate the src and dst port metadata from either the TCP or UDP header,
       * which ever is valid. */
      if (hdr.tcp.isValid()) {
        md.sport = hdr.tcp.src;
        md.dport = hdr.tcp.dst;
      } else if (hdr.udp.isValid()) {
        md.sport = hdr.udp.src;
        md.dport = hdr.udp.dst;
      }

      flow_v4.apply();
    }

    cache_stg_0.apply(hdr, md.sport, md.dport, md.learn_requested, md.flush_requested, md.learn_res, md.flush_res, md.cid, md.flush_cid);
    cache_stg_1.apply(hdr, md.sport, md.dport, md.learn_requested, md.flush_requested, md.learn_res, md.flush_res, md.cid, md.flush_cid);
    cache_stg_2.apply(hdr, md.sport, md.dport, md.learn_requested, md.flush_requested, md.learn_res, md.flush_res, md.cid, md.flush_cid);

    md.flush_cid[20:14] = md.flush_cid[23:17]; // FIXME - Update when changing table sizes
    md.cid[20:14] = md.cid[23:17];

    if (ig_intr_md.resubmit_flag == 0) {

      if (WAS_LEARN(md.learn_res)) {
        /* Learn event happened. */
        if (WAS_FLUSH(md.flush_res)) {
          /* Move event happened. */
        } else {
          /* New learn happened. */
          fid_alloc.apply(md.fid, md.learn_event);
        }
      }

      map_stg_2.apply(md.learn_res, md.flush_res, md.cid[MAP_IDX_BITS-1:0], md.flush_cid[MAP_IDX_BITS-1:0], md.cid[MAP_IDX_BITS+1:MAP_IDX_BITS], md.flush_cid[MAP_IDX_BITS+1:MAP_IDX_BITS], md.map_2_set, md.map_2_get, md.map_2_clr, md.map_2_get_clr, md.fid);
      map_stg_1.apply(md.learn_res, md.flush_res, md.cid[MAP_IDX_BITS-1:0], md.flush_cid[MAP_IDX_BITS-1:0], md.cid[MAP_IDX_BITS+1:MAP_IDX_BITS], md.flush_cid[MAP_IDX_BITS+1:MAP_IDX_BITS], md.map_1_set, md.map_1_get, md.map_1_clr, md.map_1_get_clr, md.fid);
      map_stg_0.apply(md.learn_res, md.flush_res, md.cid[MAP_IDX_BITS-1:0], md.flush_cid[MAP_IDX_BITS-1:0], md.cid[MAP_IDX_BITS+1:MAP_IDX_BITS], md.flush_cid[MAP_IDX_BITS+1:MAP_IDX_BITS], md.map_0_set, md.map_0_get, md.map_0_clr, md.map_0_get_clr, md.fid);

      log_ips();
      log_ports();
      log_protocol();
      count_flow();

      if (md.learn_event == 1) {
        notify.apply(hdr, md);
      }
      dead_code.apply();
    } else {
      // TODO - Consider letting sweeper delete these entries out
      // TODO - Ask Glen if resubmit packets can be dropped, or if there is a
      //        way to prevent them from being dropped.
      discard.apply();
    }
  }
}


control iDprsr(packet_out packet, inout headers hdr, in metadata md,
               in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprs) {
  Resubmit() resubmit;
  apply {
    if (ig_intr_md_for_dprs.resubmit_type == 0) {
      resubmit.emit();
    }
    packet.emit(hdr);
  }
}

parser ePrsr(packet_in packet, out headers hdr, out metadata md,
             out egress_intrinsic_metadata_t eg_intr_md) {
  state start { transition reject; }
}

control egr(inout headers hdr, inout metadata md, in egress_intrinsic_metadata_t eg_intr_md,
            in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
            inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprs,
            inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {
  apply {}
}

control eDprsr(packet_out packet, inout headers hdr, in metadata md,
               in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprs) {
  apply {}
}

Pipeline(iPrsr(), ingr(), iDprsr(), ePrsr(), egr(), eDprsr()) jojo;
Switch(jojo) main;
