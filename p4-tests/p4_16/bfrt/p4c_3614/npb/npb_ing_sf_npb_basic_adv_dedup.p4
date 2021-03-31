/* -*- P4_16 -*- */

#ifndef _NPB_ING_SF_0_DEDUP_
#define _NPB_ING_SF_0_DEDUP_

#define DEPTH      32w65536
#define DEPTH_POW2 16

//#define DEPTH      32w131072
//#define DEPTH_POW2 17

//#define DEPTH      32w262144
//#define DEPTH_POW2 18

#undef  HASH_HACK

// =============================================================================
// =============================================================================
// =============================================================================
// Register (Ingress & Egress Shared Code)
// =============================================================================
// =============================================================================
// =============================================================================

struct pair_t {
	bit<16> hash;
	bit<16> data;
};

// =============================================================================

// note: this register code has been structured such that multiple registers can
// be laid down, perhaps using upper bits of the hash to select between them....

control npb_dedup_reg (
	in    bit<DEPTH_POW2>                             flowtable_hash_lo, // address
	in    bit<16>                                     flowtable_hash_hi, // data -- always 16 bits
	in    bit<16>                                     ssap,

	out   bit<1>                                      drop
) {

	// =========================================================================
	// Register Array
	// =========================================================================

	// This code works similar to how vpp's flow collector works...on a hash
	// collision, the current flow occupying the slot is simply replaced with
	// the new flow (i.e. the old flow is simply booted out of the cache).

	Register      <pair_t, bit<DEPTH_POW2>>(DEPTH)            test_reg;          // syntax seems to be <data type, index type>

	// =========================================================================

	RegisterAction<pair_t, bit<DEPTH_POW2>, bit<1>>(test_reg) register_array = { // syntax seems to be <data type, index type, return type>
		void apply(
			inout pair_t  reg_value,   // register entry
			out   bit<1>  return_value // return value
		) {
			if(reg_value.hash == (bit<16>)flowtable_hash_hi) {
				// existing flow
				// --------
				if(reg_value.data == (bit<16>)ssap) {
					// same ssap
					// ---------
					return_value = 0; // pass packet
				} else {
					// different ssap
					// ---------
					return_value = 1; // drop packet
				}
			} else {
				// new flow (entry collision, overwrite old flow)
				// --------
				// update entry
				reg_value.hash = (bit<16>)flowtable_hash_hi;
				reg_value.data = (bit<16>)ssap;

				return_value = 0; // pass packet
			}
		}
	};

	// =========================================================================
	// Apply Block
	// =========================================================================

	apply {
		drop = register_array.execute(flowtable_hash_lo);
	}

}

// =============================================================================
// =============================================================================
// =============================================================================
// Ingress
// =============================================================================
// =============================================================================
// =============================================================================

control npb_ing_sf_npb_basic_adv_dedup_hash (
	in    switch_lookup_fields_t lkp, // for hash
	in    bit<VPN_ID_WIDTH>      vpn, // for hash
	out   bit<32>                hash
) {
	// =========================================================================
	// Hash
	// =========================================================================

#ifdef HASH_HACK
	Hash<bit<DEPTH_POW2>>(HashAlgorithm_t.CRC32) h_lo;
	Hash<bit<16        >>(HashAlgorithm_t.CRC16) h_hi; // always 16 bits
#else
	Hash<bit<32        >>(HashAlgorithm_t.CRC32) h;
#endif

	// =========================================================================
	// Apply
	// =========================================================================

	apply {
		// ***** hash the key *****
#ifdef HASH_HACK
		hash = h_lo.get({
			vpn,
			lkp.ip_src_addr,
			lkp.ip_dst_addr,
			lkp.ip_proto,
			lkp.l4_src_port,
			lkp.l4_dst_port
		});

		hash = h_hi.get({
			vpn,
			lkp.ip_src_addr,
			lkp.ip_dst_addr,
			lkp.ip_proto,
			lkp.l4_src_port,
			lkp.l4_dst_port
		});
#else
		hash = h.get ({
			vpn,
			lkp.ip_src_addr,
			lkp.ip_dst_addr,
			lkp.ip_proto,
			lkp.l4_src_port,
			lkp.l4_dst_port
		});
	}
#endif
}

// =============================================================================

control npb_ing_sf_npb_basic_adv_dedup (
	in    bool                   enable,
	in    switch_lookup_fields_t lkp,  // for hash
	in    bit<VPN_ID_WIDTH>      vpn,  // for hash
	in    bit<32>                hash,
	in    bit<16>                ssap, // for dedup
	inout bit<3>                 drop_ctl
) {
	npb_dedup_reg() npb_dedup_reg_0;
	npb_dedup_reg() npb_dedup_reg_1;
	npb_dedup_reg() npb_dedup_reg_2;
	npb_dedup_reg() npb_dedup_reg_3;
	npb_dedup_reg() npb_dedup_reg_4;
	npb_dedup_reg() npb_dedup_reg_5;
	npb_dedup_reg() npb_dedup_reg_6;
	npb_dedup_reg() npb_dedup_reg_7;
	npb_dedup_reg() npb_dedup_reg_8;
	npb_dedup_reg() npb_dedup_reg_9;
	npb_dedup_reg() npb_dedup_reg_10;
	npb_dedup_reg() npb_dedup_reg_11;
	npb_dedup_reg() npb_dedup_reg_12;
	npb_dedup_reg() npb_dedup_reg_13;
	npb_dedup_reg() npb_dedup_reg_14;
	npb_dedup_reg() npb_dedup_reg_15;
/*
	npb_dedup_reg() npb_dedup_reg_16;
	npb_dedup_reg() npb_dedup_reg_17;
	npb_dedup_reg() npb_dedup_reg_18;
	npb_dedup_reg() npb_dedup_reg_19;
	npb_dedup_reg() npb_dedup_reg_20;
	npb_dedup_reg() npb_dedup_reg_21;
	npb_dedup_reg() npb_dedup_reg_22;
	npb_dedup_reg() npb_dedup_reg_23;
	npb_dedup_reg() npb_dedup_reg_24;
	npb_dedup_reg() npb_dedup_reg_25;
	npb_dedup_reg() npb_dedup_reg_26;
	npb_dedup_reg() npb_dedup_reg_27;
	npb_dedup_reg() npb_dedup_reg_28;
	npb_dedup_reg() npb_dedup_reg_29;
	npb_dedup_reg() npb_dedup_reg_30;
	npb_dedup_reg() npb_dedup_reg_31;
*/

	// =========================================================================

	bit<32> flowtable_hash = 0;

	bit<DEPTH_POW2> flowtable_hash_lo;
	bit<16>         flowtable_hash_hi; // always 16 bits
	bit<4>          flowtable_hash_chk; // always 16 bits

	bit<1> drop = 0;

	// =========================================================================
	// Hash
	// =========================================================================

#ifdef HASH_HACK
	Hash<bit<DEPTH_POW2>>(HashAlgorithm_t.CRC32) h_lo;
	Hash<bit<16        >>(HashAlgorithm_t.CRC16) h_hi; // always 16 bits
#else
	Hash<bit<32        >>(HashAlgorithm_t.CRC32) h;
#endif

	// =========================================================================
	// Apply
	// =========================================================================

	apply {
		// ***** hash the key *****
#ifdef HASH_HACK
		flowtable_hash_lo = h_lo.get({
			vpn,
			lkp.ip_src_addr,
			lkp.ip_dst_addr,
			lkp.ip_proto,
			lkp.l4_src_port,
			lkp.l4_dst_port
		});

		flowtable_hash_hi = h_hi.get({
			vpn,
			lkp.ip_src_addr,
			lkp.ip_dst_addr,
			lkp.ip_proto,
			lkp.l4_src_port,
			lkp.l4_dst_port
		});
#else
/*
		flowtable_hash    = h.get ({
			vpn,
			lkp.ip_src_addr,
			lkp.ip_dst_addr,
			lkp.ip_proto,
			lkp.l4_src_port,
			lkp.l4_dst_port
		});
		flowtable_hash_lo  = flowtable_hash[15: 0];
		flowtable_hash_hi  = flowtable_hash[31:16];
		flowtable_hash_chk = flowtable_hash[31:28];
*/
		flowtable_hash_lo  = hash[15: 0];
		flowtable_hash_hi  = hash[31:16];
		flowtable_hash_chk = hash[31:28];
#endif

		// note: putting the enable check around all the dedup blocks doesn't fit, so instead if disabled
		// we force it to use block 0 by setting hash_chk to 0, and then put the enable check around only that block.

		// ***** call dedup function *****
		if(enable) {
			       if(flowtable_hash_chk ==  0) { npb_dedup_reg_0.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk ==  1) { npb_dedup_reg_1.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk ==  2) { npb_dedup_reg_2.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk ==  3) { npb_dedup_reg_3.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk ==  4) { npb_dedup_reg_4.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk ==  5) { npb_dedup_reg_5.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk ==  6) { npb_dedup_reg_6.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk ==  7) { npb_dedup_reg_7.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk ==  8) { npb_dedup_reg_8.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk ==  9) { npb_dedup_reg_9.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk == 10) { npb_dedup_reg_10.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk == 11) { npb_dedup_reg_11.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk == 12) { npb_dedup_reg_12.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk == 13) { npb_dedup_reg_13.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk == 14) { npb_dedup_reg_14.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk == 15) { npb_dedup_reg_15.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			}

/*
			       if(flowtable_hash_chk ==  0) { npb_dedup_reg_0.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk ==  1) { npb_dedup_reg_1.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk ==  2) { npb_dedup_reg_2.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk ==  3) { npb_dedup_reg_3.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk ==  4) { npb_dedup_reg_4.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk ==  5) { npb_dedup_reg_5.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk ==  6) { npb_dedup_reg_6.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk ==  7) { npb_dedup_reg_7.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk ==  8) { npb_dedup_reg_8.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk ==  9) { npb_dedup_reg_9.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk == 10) { npb_dedup_reg_10.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk == 11) { npb_dedup_reg_11.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk == 12) { npb_dedup_reg_12.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk == 13) { npb_dedup_reg_13.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk == 14) { npb_dedup_reg_14.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk == 15) { npb_dedup_reg_15.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk == 16) { npb_dedup_reg_16.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk == 17) { npb_dedup_reg_17.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk == 18) { npb_dedup_reg_18.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk == 19) { npb_dedup_reg_19.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk == 20) { npb_dedup_reg_20.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk == 21) { npb_dedup_reg_21.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk == 22) { npb_dedup_reg_22.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk == 23) { npb_dedup_reg_23.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk == 24) { npb_dedup_reg_24.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk == 25) { npb_dedup_reg_25.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk == 26) { npb_dedup_reg_26.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk == 27) { npb_dedup_reg_27.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk == 28) { npb_dedup_reg_28.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk == 29) { npb_dedup_reg_29.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk == 30) { npb_dedup_reg_30.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk == 31) { npb_dedup_reg_31.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			}
*/
		}

		if(drop == 1) {
			drop_ctl = 0x1;
		}
	}
}

// =============================================================================
// =============================================================================
// =============================================================================
// Egress
// =============================================================================
// =============================================================================
// =============================================================================

control npb_egr_sf_proxy_dedup (
	in    bool                   enable,
	in    switch_lookup_fields_t lkp,  // for hash
	in    bit<VPN_ID_WIDTH>      vpn,  // for hash
	in    bit<16>                ssap, // for dedup
	inout bit<3>                 drop_ctl
) {
	npb_dedup_reg() npb_dedup_reg_0;
	npb_dedup_reg() npb_dedup_reg_1;
	npb_dedup_reg() npb_dedup_reg_2;
	npb_dedup_reg() npb_dedup_reg_3;
	npb_dedup_reg() npb_dedup_reg_4;
	npb_dedup_reg() npb_dedup_reg_5;
	npb_dedup_reg() npb_dedup_reg_6;
	npb_dedup_reg() npb_dedup_reg_7;
	npb_dedup_reg() npb_dedup_reg_8;
	npb_dedup_reg() npb_dedup_reg_9;
	npb_dedup_reg() npb_dedup_reg_10;
	npb_dedup_reg() npb_dedup_reg_11;
	npb_dedup_reg() npb_dedup_reg_12;
	npb_dedup_reg() npb_dedup_reg_13;
	npb_dedup_reg() npb_dedup_reg_14;
	npb_dedup_reg() npb_dedup_reg_15;
/*
	npb_dedup_reg() npb_dedup_reg_16;
	npb_dedup_reg() npb_dedup_reg_17;
	npb_dedup_reg() npb_dedup_reg_18;
	npb_dedup_reg() npb_dedup_reg_19;
	npb_dedup_reg() npb_dedup_reg_20;
	npb_dedup_reg() npb_dedup_reg_21;
	npb_dedup_reg() npb_dedup_reg_22;
	npb_dedup_reg() npb_dedup_reg_23;
	npb_dedup_reg() npb_dedup_reg_24;
	npb_dedup_reg() npb_dedup_reg_25;
	npb_dedup_reg() npb_dedup_reg_26;
	npb_dedup_reg() npb_dedup_reg_27;
	npb_dedup_reg() npb_dedup_reg_28;
	npb_dedup_reg() npb_dedup_reg_29;
	npb_dedup_reg() npb_dedup_reg_30;
	npb_dedup_reg() npb_dedup_reg_31;
*/

	// =========================================================================

	bit<32> flowtable_hash = 0;

	bit<DEPTH_POW2> flowtable_hash_lo;
	bit<16>         flowtable_hash_hi; // always 16 bits
	bit<4>          flowtable_hash_chk; // always 16 bits

	bit<1> drop = 0;

	// =========================================================================
	// Hash
	// =========================================================================

#ifdef HASH_HACK
	Hash<bit<DEPTH_POW2>>(HashAlgorithm_t.CRC32) h_lo;
	Hash<bit<16        >>(HashAlgorithm_t.CRC16) h_hi; // always 16 bits
#else
	Hash<bit<32        >>(HashAlgorithm_t.CRC32) h;
#endif

	// =========================================================================
	// Apply
	// =========================================================================

	apply {
		// ***** hash the key *****
#ifdef HASH_HACK
		flowtable_hash_lo = h_lo.get({
			vpn,
			lkp.ip_src_addr,
			lkp.ip_dst_addr,
			lkp.ip_proto,
			lkp.l4_src_port,
			lkp.l4_dst_port
		});

		flowtable_hash_hi = h_hi.get({
			vpn,
			lkp.ip_src_addr,
			lkp.ip_dst_addr,
			lkp.ip_proto,
			lkp.l4_src_port,
			lkp.l4_dst_port
		});
#else
		flowtable_hash    = h.get ({
			vpn,
			lkp.ip_src_addr,
			lkp.ip_dst_addr,
			lkp.ip_proto,
			lkp.l4_src_port,
			lkp.l4_dst_port
		});

		flowtable_hash_lo  = flowtable_hash[15: 0];
		flowtable_hash_hi  = flowtable_hash[31:16];
		flowtable_hash_chk = flowtable_hash[31:28];
#endif

		// note: putting the enable check around all the dedup blocks doesn't fit, so instead if disabled
		// we force it to use block 0 by setting hash_chk to 0, and then put the enable check around only that block.

		// ***** call dedup function *****
		if(enable) {
			       if(flowtable_hash_chk ==  0) { npb_dedup_reg_0.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk ==  1) { npb_dedup_reg_1.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk ==  2) { npb_dedup_reg_2.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk ==  3) { npb_dedup_reg_3.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk ==  4) { npb_dedup_reg_4.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk ==  5) { npb_dedup_reg_5.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk ==  6) { npb_dedup_reg_6.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk ==  7) { npb_dedup_reg_7.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk ==  8) { npb_dedup_reg_8.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk ==  9) { npb_dedup_reg_9.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk == 10) { npb_dedup_reg_10.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk == 11) { npb_dedup_reg_11.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk == 12) { npb_dedup_reg_12.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk == 13) { npb_dedup_reg_13.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk == 14) { npb_dedup_reg_14.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk == 15) { npb_dedup_reg_15.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			}

/*
			       if(flowtable_hash_chk ==  0) { npb_dedup_reg_0.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk ==  1) { npb_dedup_reg_1.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk ==  2) { npb_dedup_reg_2.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk ==  3) { npb_dedup_reg_3.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk ==  4) { npb_dedup_reg_4.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk ==  5) { npb_dedup_reg_5.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk ==  6) { npb_dedup_reg_6.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk ==  7) { npb_dedup_reg_7.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk ==  8) { npb_dedup_reg_8.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk ==  9) { npb_dedup_reg_9.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk == 10) { npb_dedup_reg_10.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk == 11) { npb_dedup_reg_11.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk == 12) { npb_dedup_reg_12.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk == 13) { npb_dedup_reg_13.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk == 14) { npb_dedup_reg_14.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk == 15) { npb_dedup_reg_15.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk == 16) { npb_dedup_reg_16.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk == 17) { npb_dedup_reg_17.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk == 18) { npb_dedup_reg_18.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk == 19) { npb_dedup_reg_19.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk == 20) { npb_dedup_reg_20.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk == 21) { npb_dedup_reg_21.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk == 22) { npb_dedup_reg_22.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk == 23) { npb_dedup_reg_23.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk == 24) { npb_dedup_reg_24.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk == 25) { npb_dedup_reg_25.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk == 26) { npb_dedup_reg_26.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk == 27) { npb_dedup_reg_27.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk == 28) { npb_dedup_reg_28.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk == 29) { npb_dedup_reg_29.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk == 30) { npb_dedup_reg_30.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk == 31) { npb_dedup_reg_31.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			}
*/
		}

		if(drop == 1) {
			drop_ctl = 0x1;
		}
	}
}

#endif
