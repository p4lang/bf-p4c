/* -*- P4_16 -*- */

#ifndef _NPB_ING_SF_0_DEDUP_
#define _NPB_ING_SF_0_DEDUP_

#define DEDUP_ADDR_WIDTH_DEFINE 16

// =============================================================================
// =============================================================================
// =============================================================================
// Register (Ingress & Egress Shared Code)
// =============================================================================
// =============================================================================
// =============================================================================

struct pair_t {
	bit<16> hash_l34; // {              hash_l34[15:0]}
	bit<16> data;     // {count[15:12], hash_l2 [11:0]}
};

// =============================================================================

// note: this register code has been structured such that multiple registers can
// be laid down, perhaps using upper bits of the hash to select between them....

control npb_dedup_reg (
	in    bit<12>                                     hash_l2,   // address (high bits), data (low bits)
	in    bit<16>                                     hash_l34,  // address (high bits), data (low bits)
	in    bit<16>                                     ssap,      // data
	in    bit<16>                                     vpn,       // data
	in    bit<9>                                      sport,     // data

	out   bit<1>                                      drop
) (
	switch_uint32_t DEDUP_ADDR_WIDTH      = 16 // 64k deep
) {

	// =========================================================================
	// Register Array
	// =========================================================================

	// This code works similar to how vpp's flow collector works...on a hash
	// collision, the current flow occupying the slot is simply replaced with
	// the new flow (i.e. the old flow is simply booted out of the cache).

	Register <pair_t, bit<(DEDUP_ADDR_WIDTH_DEFINE)>>(1 << (DEDUP_ADDR_WIDTH_DEFINE)) array1; // syntax seems to be <data type, index type>

	// =========================================================================

	RegisterAction<pair_t, bit<(DEDUP_ADDR_WIDTH_DEFINE)>, bit<1>>(array1) filter1 = { // syntax seems to be <data type, index type, return type>
		void apply(
			inout pair_t  reg_value,   // register entry
			out   bit<1>  return_value // return value
		) {
			if(reg_value.hash_l34 == (bit<16>)hash_l34[15:0]) {
				// existing flow
				// --------
//				if((reg_value.data & 0x0fff == (bit<16>)hash_l2[11:0]) && (reg_value.data & 0xf000 < 0xf000)) { // check count
				if((reg_value.data & 0x0fff == (bit<16>)hash_l2[11:0]) && (reg_value.data          < 0xf000)) { // check count
					// same source
					// ---------
					reg_value.data = (bit<16>)reg_value.data + 0x1000; // increment count

					return_value   = 0; // forward packet
				} else {
					// different source
					// ---------
					reg_value.data = (bit<16>)reg_value.data; // same count

					return_value   = 1; // drop packet
				}
			} else {
				// new flow (overwrite any existing flow)
				// --------
				// update entry
				reg_value.hash_l34 = (bit<16>)hash_l34[15:0];
				reg_value.data     = (bit<16>)hash_l2 [11:0]; // this also clears counter in bits [15:12] to 0

				return_value       = 0; // forward packet
			}
		}
	};

	// =========================================================================
	// Apply Block
	// =========================================================================

	apply {
		drop = filter1.execute(hash_l34[((DEDUP_ADDR_WIDTH_DEFINE) - 1):0]);
	}

}

// =============================================================================
// =============================================================================
// =============================================================================
// 
// =============================================================================
// =============================================================================
// =============================================================================

control npb_dedup_ (
	in    bool                   enable,
	in    switch_lookup_fields_t lkp,  // for hash
	in    bit<32>                hash_l2,
	in    bit<32>                hash_l34,
	in    bit<16>                ssap,  // for dedup
	in    bit<16>                vpn,   // for dedup
	in    bit<9>                 sport, // for dedup
	inout bit<3>                 drop_ctl
) (
	MODULE_DEPLOYMENT_PARAMS
) {
	npb_dedup_reg(DEDUP_ADDR_WIDTH) npb_dedup_reg_0;
	npb_dedup_reg(DEDUP_ADDR_WIDTH) npb_dedup_reg_1;
	npb_dedup_reg(DEDUP_ADDR_WIDTH) npb_dedup_reg_2;
	npb_dedup_reg(DEDUP_ADDR_WIDTH) npb_dedup_reg_3;
	npb_dedup_reg(DEDUP_ADDR_WIDTH) npb_dedup_reg_4;
	npb_dedup_reg(DEDUP_ADDR_WIDTH) npb_dedup_reg_5;
	npb_dedup_reg(DEDUP_ADDR_WIDTH) npb_dedup_reg_6;
	npb_dedup_reg(DEDUP_ADDR_WIDTH) npb_dedup_reg_7;
	npb_dedup_reg(DEDUP_ADDR_WIDTH) npb_dedup_reg_8;
	npb_dedup_reg(DEDUP_ADDR_WIDTH) npb_dedup_reg_9;
	npb_dedup_reg(DEDUP_ADDR_WIDTH) npb_dedup_reg_10;
	npb_dedup_reg(DEDUP_ADDR_WIDTH) npb_dedup_reg_11;
	npb_dedup_reg(DEDUP_ADDR_WIDTH) npb_dedup_reg_12;
	npb_dedup_reg(DEDUP_ADDR_WIDTH) npb_dedup_reg_13;
	npb_dedup_reg(DEDUP_ADDR_WIDTH) npb_dedup_reg_14;
	npb_dedup_reg(DEDUP_ADDR_WIDTH) npb_dedup_reg_15;
	npb_dedup_reg(DEDUP_ADDR_WIDTH) npb_dedup_reg_16;
	npb_dedup_reg(DEDUP_ADDR_WIDTH) npb_dedup_reg_17;
	npb_dedup_reg(DEDUP_ADDR_WIDTH) npb_dedup_reg_18;
	npb_dedup_reg(DEDUP_ADDR_WIDTH) npb_dedup_reg_19;
	npb_dedup_reg(DEDUP_ADDR_WIDTH) npb_dedup_reg_20;
	npb_dedup_reg(DEDUP_ADDR_WIDTH) npb_dedup_reg_21;
	npb_dedup_reg(DEDUP_ADDR_WIDTH) npb_dedup_reg_22;
	npb_dedup_reg(DEDUP_ADDR_WIDTH) npb_dedup_reg_23;
	npb_dedup_reg(DEDUP_ADDR_WIDTH) npb_dedup_reg_24;
	npb_dedup_reg(DEDUP_ADDR_WIDTH) npb_dedup_reg_25;
	npb_dedup_reg(DEDUP_ADDR_WIDTH) npb_dedup_reg_26;
	npb_dedup_reg(DEDUP_ADDR_WIDTH) npb_dedup_reg_27;
	npb_dedup_reg(DEDUP_ADDR_WIDTH) npb_dedup_reg_28;
	npb_dedup_reg(DEDUP_ADDR_WIDTH) npb_dedup_reg_29;
	npb_dedup_reg(DEDUP_ADDR_WIDTH) npb_dedup_reg_30;
	npb_dedup_reg(DEDUP_ADDR_WIDTH) npb_dedup_reg_31;

	bit<1> drop;

	// =========================================================================
	// Hash (shrink to 12 bits)
	// =========================================================================

//	bit<12> hash_l2_reduced;

//	Hash<bit<12>>(HashAlgorithm_t.IDENTITY) hash_1;

	// =========================================================================
	// Apply
	// =========================================================================

	apply {
//		hash_l2_reduced[11:0] = hash_1.get({hash_l2});

		// ***** call dedup function *****
		if(enable) {
			if(DEDUP_NUM_BLOCKS == 1) {
				npb_dedup_reg_0.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
			} else if(DEDUP_NUM_BLOCKS == 2) {
				bit<1> upper_addr = hash_l34[31:31];
				if       (upper_addr ==  0) { npb_dedup_reg_0.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
				} else                      { npb_dedup_reg_1.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
				}
			} else if(DEDUP_NUM_BLOCKS == 4) {
				bit<2> upper_addr = hash_l34[31:30];
				if       (upper_addr ==  0) { npb_dedup_reg_0.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
				} else if(upper_addr ==  1) { npb_dedup_reg_1.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
				} else if(upper_addr ==  2) { npb_dedup_reg_2.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
				} else                      { npb_dedup_reg_3.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
				}
			} else if(DEDUP_NUM_BLOCKS == 8) {
				bit<3> upper_addr = hash_l34[31:29];
				if       (upper_addr ==  0) { npb_dedup_reg_0.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
				} else if(upper_addr ==  1) { npb_dedup_reg_1.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
				} else if(upper_addr ==  2) { npb_dedup_reg_2.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
				} else if(upper_addr ==  3) { npb_dedup_reg_3.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
				} else if(upper_addr ==  4) { npb_dedup_reg_4.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
				} else if(upper_addr ==  5) { npb_dedup_reg_5.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
				} else if(upper_addr ==  6) { npb_dedup_reg_6.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
				} else                      { npb_dedup_reg_7.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
				}
			} else if(DEDUP_NUM_BLOCKS == 16) {
				bit<4> upper_addr = hash_l34[31:28];
				if       (upper_addr ==  0) { npb_dedup_reg_0.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
				} else if(upper_addr ==  1) { npb_dedup_reg_1.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
				} else if(upper_addr ==  2) { npb_dedup_reg_2.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
				} else if(upper_addr ==  3) { npb_dedup_reg_3.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
				} else if(upper_addr ==  4) { npb_dedup_reg_4.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
				} else if(upper_addr ==  5) { npb_dedup_reg_5.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
				} else if(upper_addr ==  6) { npb_dedup_reg_6.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
				} else if(upper_addr ==  7) { npb_dedup_reg_7.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
				} else if(upper_addr ==  8) { npb_dedup_reg_8.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
				} else if(upper_addr ==  9) { npb_dedup_reg_9.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
				} else if(upper_addr == 10) { npb_dedup_reg_10.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
				} else if(upper_addr == 11) { npb_dedup_reg_11.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
				} else if(upper_addr == 12) { npb_dedup_reg_12.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
				} else if(upper_addr == 13) { npb_dedup_reg_13.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
				} else if(upper_addr == 14) { npb_dedup_reg_14.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
				} else                      { npb_dedup_reg_15.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
				}
			} else {
				bit<5> upper_addr = hash_l34[31:27];
				if       (upper_addr ==  0) { npb_dedup_reg_0.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
				} else if(upper_addr ==  1) { npb_dedup_reg_1.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
				} else if(upper_addr ==  2) { npb_dedup_reg_2.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
				} else if(upper_addr ==  3) { npb_dedup_reg_3.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
				} else if(upper_addr ==  4) { npb_dedup_reg_4.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
				} else if(upper_addr ==  5) { npb_dedup_reg_5.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
				} else if(upper_addr ==  6) { npb_dedup_reg_6.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
				} else if(upper_addr ==  7) { npb_dedup_reg_7.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
				} else if(upper_addr ==  8) { npb_dedup_reg_8.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
				} else if(upper_addr ==  9) { npb_dedup_reg_9.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
				} else if(upper_addr == 10) { npb_dedup_reg_10.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
				} else if(upper_addr == 11) { npb_dedup_reg_11.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
				} else if(upper_addr == 12) { npb_dedup_reg_12.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
				} else if(upper_addr == 13) { npb_dedup_reg_13.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
				} else if(upper_addr == 14) { npb_dedup_reg_14.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
				} else if(upper_addr == 15) { npb_dedup_reg_15.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
				} else if(upper_addr == 16) { npb_dedup_reg_16.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
				} else if(upper_addr == 17) { npb_dedup_reg_17.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
				} else if(upper_addr == 18) { npb_dedup_reg_18.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
				} else if(upper_addr == 19) { npb_dedup_reg_19.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
				} else if(upper_addr == 20) { npb_dedup_reg_20.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
				} else if(upper_addr == 21) { npb_dedup_reg_21.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
				} else if(upper_addr == 22) { npb_dedup_reg_22.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
				} else if(upper_addr == 23) { npb_dedup_reg_23.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
				} else if(upper_addr == 24) { npb_dedup_reg_24.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
				} else if(upper_addr == 25) { npb_dedup_reg_25.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
				} else if(upper_addr == 26) { npb_dedup_reg_26.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
				} else if(upper_addr == 27) { npb_dedup_reg_27.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
				} else if(upper_addr == 28) { npb_dedup_reg_28.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
				} else if(upper_addr == 29) { npb_dedup_reg_29.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
				} else if(upper_addr == 30) { npb_dedup_reg_30.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
				} else                      { npb_dedup_reg_31.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
				}
			}
		}

		if(drop == 1) {
			drop_ctl = 0x1;
		}
	}
}

#endif
