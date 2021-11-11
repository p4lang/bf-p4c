/* -*- P4_16 -*- */

#ifndef _NPB_ING_SF_0_DEDUP_
#define _NPB_ING_SF_0_DEDUP_

#ifndef dedup_num_blocks
#define dedup_num_blocks 1
#endif

#ifndef dedup_addr_width
#define dedup_addr_width 16 // 64k deep
#endif

// =============================================================================
// =============================================================================
// =============================================================================
// Register (Ingress & Egress Shared Code)
// =============================================================================
// =============================================================================
// =============================================================================

struct pair_t {
	bit<16> hash;
//	bit<16> data;  // ssap
//	bit<16> data;  // sport
	bit<16> data;  // {count[15:12], unused[11:9], sport[8:0]}
};

// =============================================================================

// note: this register code has been structured such that multiple registers can
// be laid down, perhaps using upper bits of the hash to select between them....

control npb_dedup_reg (
	in    bit<32>                                     hash,  // address (high bits), data (low bits)
	in    bit<16>                                     ssap,  // data
	in    bit<9>                                      sport, // data

	out   bit<1>                                      drop
) (
	switch_uint32_t addr_width_      = 16 // 64k deep
) {

	// =========================================================================
	// Register Array
	// =========================================================================

	// This code works similar to how vpp's flow collector works...on a hash
	// collision, the current flow occupying the slot is simply replaced with
	// the new flow (i.e. the old flow is simply booted out of the cache).

	Register <pair_t, bit<dedup_addr_width>>(1 << dedup_addr_width) array1; // syntax seems to be <data type, index type>

	// =========================================================================

	RegisterAction<pair_t, bit<dedup_addr_width>, bit<1>>(array1) filter1 = { // syntax seems to be <data type, index type, return type>
		void apply(
			inout pair_t  reg_value,   // register entry
			out   bit<1>  return_value // return value
		) {
			if(reg_value.hash == (bit<16>)hash[15:0]) {
				// existing flow
				// --------
//				if(reg_value.data == (bit<16>)ssap) {
				if(reg_value.data <= (bit<16>)sport + 0xf000) { // check count
// DEREK: WE WANT THIS ONE, BUT IT GETS A COMPILER ERROR.  CASE OPENED WITH INTEL: 
//				if((reg_value.data & 0x01ff == (bit<16>)sport) && (reg_value.data & 0xf000 < 0xf000)) { // check count
					// same source
					// ---------
					reg_value.data = (bit<16>)reg_value.data + 0x1000; // increment count
					return_value = 0; // pass packet
				} else {
					// different source
					// ---------
					reg_value.data = (bit<16>)reg_value.data; // same count
					return_value = 1; // drop packet
				}
			} else {
				// new flow (overwrite any existing flow)
				// --------
				// update entry
				reg_value.hash = (bit<16>)hash[15:0];
//				reg_value.data = (bit<16>)ssap;
				reg_value.data = (bit<16>)sport; // clear count

				return_value = 0; // pass packet
			}
		}
	};

	// =========================================================================
	// Apply Block
	// =========================================================================

	apply {
		drop = filter1.execute(hash[(dedup_addr_width - 1):0]);
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
	in    bit<VPN_ID_WIDTH>      vpn,  // for hash
	in    bit<32>                hash,
	in    bit<16>                ssap, // for dedup
	in    bit<9>                 sport, // for dedup
	inout bit<3>                 drop_ctl
) (
	switch_uint32_t num_blocks  = 1,
	switch_uint32_t addr_width_ = 16 // 64k deep
) {
	npb_dedup_reg(addr_width_) npb_dedup_reg_0;
	npb_dedup_reg(addr_width_) npb_dedup_reg_1;
	npb_dedup_reg(addr_width_) npb_dedup_reg_2;
	npb_dedup_reg(addr_width_) npb_dedup_reg_3;
	npb_dedup_reg(addr_width_) npb_dedup_reg_4;
	npb_dedup_reg(addr_width_) npb_dedup_reg_5;
	npb_dedup_reg(addr_width_) npb_dedup_reg_6;
	npb_dedup_reg(addr_width_) npb_dedup_reg_7;
	npb_dedup_reg(addr_width_) npb_dedup_reg_8;
	npb_dedup_reg(addr_width_) npb_dedup_reg_9;
	npb_dedup_reg(addr_width_) npb_dedup_reg_10;
	npb_dedup_reg(addr_width_) npb_dedup_reg_11;
	npb_dedup_reg(addr_width_) npb_dedup_reg_12;
	npb_dedup_reg(addr_width_) npb_dedup_reg_13;
	npb_dedup_reg(addr_width_) npb_dedup_reg_14;
	npb_dedup_reg(addr_width_) npb_dedup_reg_15;
	npb_dedup_reg(addr_width_) npb_dedup_reg_16;
	npb_dedup_reg(addr_width_) npb_dedup_reg_17;
	npb_dedup_reg(addr_width_) npb_dedup_reg_18;
	npb_dedup_reg(addr_width_) npb_dedup_reg_19;
	npb_dedup_reg(addr_width_) npb_dedup_reg_20;
	npb_dedup_reg(addr_width_) npb_dedup_reg_21;
	npb_dedup_reg(addr_width_) npb_dedup_reg_22;
	npb_dedup_reg(addr_width_) npb_dedup_reg_23;
	npb_dedup_reg(addr_width_) npb_dedup_reg_24;
	npb_dedup_reg(addr_width_) npb_dedup_reg_25;
	npb_dedup_reg(addr_width_) npb_dedup_reg_26;
	npb_dedup_reg(addr_width_) npb_dedup_reg_27;
	npb_dedup_reg(addr_width_) npb_dedup_reg_28;
	npb_dedup_reg(addr_width_) npb_dedup_reg_29;
	npb_dedup_reg(addr_width_) npb_dedup_reg_30;
	npb_dedup_reg(addr_width_) npb_dedup_reg_31;

	bit<1> drop;

	// =========================================================================
	// Hash - This is what defines a flow (6-tuple + vpn)
	// =========================================================================

	bit<32> hash_with_vpn;

	// TODO (msharif): Use a better hash
	Hash<bit<32>>(HashAlgorithm_t.CRC32) hash_1;

	// =========================================================================
	// Apply
	// =========================================================================

	apply {
		hash_with_vpn = hash_1.get({vpn,  hash}); // TODO: determine if this is needed (do we need vpn as part of the hash?)

		// ***** call dedup function *****
		if(enable) {
			if(num_blocks == 1) {
				npb_dedup_reg_0.apply (hash_with_vpn, ssap, sport, drop);
			} else if(num_blocks == 2) {
				bit<1> upper_addr = hash_with_vpn[31:31];
				if       (upper_addr ==  0) { npb_dedup_reg_0.apply (hash_with_vpn, ssap, sport, drop);
				} else                      { npb_dedup_reg_1.apply (hash_with_vpn, ssap, sport, drop);
				}
			} else if(num_blocks == 4) {
				bit<2> upper_addr = hash_with_vpn[31:30];
				if       (upper_addr ==  0) { npb_dedup_reg_0.apply (hash_with_vpn, ssap, sport, drop);
				} else if(upper_addr ==  1) { npb_dedup_reg_1.apply (hash_with_vpn, ssap, sport, drop);
				} else if(upper_addr ==  2) { npb_dedup_reg_2.apply (hash_with_vpn, ssap, sport, drop);
				} else                      { npb_dedup_reg_3.apply (hash_with_vpn, ssap, sport, drop);
				}
			} else if(num_blocks == 8) {
				bit<3> upper_addr = hash_with_vpn[31:29];
				if       (upper_addr ==  0) { npb_dedup_reg_0.apply (hash_with_vpn, ssap, sport, drop);
				} else if(upper_addr ==  1) { npb_dedup_reg_1.apply (hash_with_vpn, ssap, sport, drop);
				} else if(upper_addr ==  2) { npb_dedup_reg_2.apply (hash_with_vpn, ssap, sport, drop);
				} else if(upper_addr ==  3) { npb_dedup_reg_3.apply (hash_with_vpn, ssap, sport, drop);
				} else if(upper_addr ==  4) { npb_dedup_reg_4.apply (hash_with_vpn, ssap, sport, drop);
				} else if(upper_addr ==  5) { npb_dedup_reg_5.apply (hash_with_vpn, ssap, sport, drop);
				} else if(upper_addr ==  6) { npb_dedup_reg_6.apply (hash_with_vpn, ssap, sport, drop);
				} else                      { npb_dedup_reg_7.apply (hash_with_vpn, ssap, sport, drop);
				}
			} else if(num_blocks == 16) {
				bit<4> upper_addr = hash_with_vpn[31:28];
				if       (upper_addr ==  0) { npb_dedup_reg_0.apply (hash_with_vpn, ssap, sport, drop);
				} else if(upper_addr ==  1) { npb_dedup_reg_1.apply (hash_with_vpn, ssap, sport, drop);
				} else if(upper_addr ==  2) { npb_dedup_reg_2.apply (hash_with_vpn, ssap, sport, drop);
				} else if(upper_addr ==  3) { npb_dedup_reg_3.apply (hash_with_vpn, ssap, sport, drop);
				} else if(upper_addr ==  4) { npb_dedup_reg_4.apply (hash_with_vpn, ssap, sport, drop);
				} else if(upper_addr ==  5) { npb_dedup_reg_5.apply (hash_with_vpn, ssap, sport, drop);
				} else if(upper_addr ==  6) { npb_dedup_reg_6.apply (hash_with_vpn, ssap, sport, drop);
				} else if(upper_addr ==  7) { npb_dedup_reg_7.apply (hash_with_vpn, ssap, sport, drop);
				} else if(upper_addr ==  8) { npb_dedup_reg_8.apply (hash_with_vpn, ssap, sport, drop);
				} else if(upper_addr ==  9) { npb_dedup_reg_9.apply (hash_with_vpn, ssap, sport, drop);
				} else if(upper_addr == 10) { npb_dedup_reg_10.apply (hash_with_vpn, ssap, sport, drop);
				} else if(upper_addr == 11) { npb_dedup_reg_11.apply (hash_with_vpn, ssap, sport, drop);
				} else if(upper_addr == 12) { npb_dedup_reg_12.apply (hash_with_vpn, ssap, sport, drop);
				} else if(upper_addr == 13) { npb_dedup_reg_13.apply (hash_with_vpn, ssap, sport, drop);
				} else if(upper_addr == 14) { npb_dedup_reg_14.apply (hash_with_vpn, ssap, sport, drop);
				} else                      { npb_dedup_reg_15.apply (hash_with_vpn, ssap, sport, drop);
				}
			} else {
				bit<5> upper_addr = hash_with_vpn[31:27];
				if       (upper_addr ==  0) { npb_dedup_reg_0.apply (hash_with_vpn, ssap, sport, drop);
				} else if(upper_addr ==  1) { npb_dedup_reg_1.apply (hash_with_vpn, ssap, sport, drop);
				} else if(upper_addr ==  2) { npb_dedup_reg_2.apply (hash_with_vpn, ssap, sport, drop);
				} else if(upper_addr ==  3) { npb_dedup_reg_3.apply (hash_with_vpn, ssap, sport, drop);
				} else if(upper_addr ==  4) { npb_dedup_reg_4.apply (hash_with_vpn, ssap, sport, drop);
				} else if(upper_addr ==  5) { npb_dedup_reg_5.apply (hash_with_vpn, ssap, sport, drop);
				} else if(upper_addr ==  6) { npb_dedup_reg_6.apply (hash_with_vpn, ssap, sport, drop);
				} else if(upper_addr ==  7) { npb_dedup_reg_7.apply (hash_with_vpn, ssap, sport, drop);
				} else if(upper_addr ==  8) { npb_dedup_reg_8.apply (hash_with_vpn, ssap, sport, drop);
				} else if(upper_addr ==  9) { npb_dedup_reg_9.apply (hash_with_vpn, ssap, sport, drop);
				} else if(upper_addr == 10) { npb_dedup_reg_10.apply (hash_with_vpn, ssap, sport, drop);
				} else if(upper_addr == 11) { npb_dedup_reg_11.apply (hash_with_vpn, ssap, sport, drop);
				} else if(upper_addr == 12) { npb_dedup_reg_12.apply (hash_with_vpn, ssap, sport, drop);
				} else if(upper_addr == 13) { npb_dedup_reg_13.apply (hash_with_vpn, ssap, sport, drop);
				} else if(upper_addr == 14) { npb_dedup_reg_14.apply (hash_with_vpn, ssap, sport, drop);
				} else if(upper_addr == 15) { npb_dedup_reg_15.apply (hash_with_vpn, ssap, sport, drop);
				} else if(upper_addr == 16) { npb_dedup_reg_16.apply (hash_with_vpn, ssap, sport, drop);
				} else if(upper_addr == 17) { npb_dedup_reg_17.apply (hash_with_vpn, ssap, sport, drop);
				} else if(upper_addr == 18) { npb_dedup_reg_18.apply (hash_with_vpn, ssap, sport, drop);
				} else if(upper_addr == 19) { npb_dedup_reg_19.apply (hash_with_vpn, ssap, sport, drop);
				} else if(upper_addr == 20) { npb_dedup_reg_20.apply (hash_with_vpn, ssap, sport, drop);
				} else if(upper_addr == 21) { npb_dedup_reg_21.apply (hash_with_vpn, ssap, sport, drop);
				} else if(upper_addr == 22) { npb_dedup_reg_22.apply (hash_with_vpn, ssap, sport, drop);
				} else if(upper_addr == 23) { npb_dedup_reg_23.apply (hash_with_vpn, ssap, sport, drop);
				} else if(upper_addr == 24) { npb_dedup_reg_24.apply (hash_with_vpn, ssap, sport, drop);
				} else if(upper_addr == 25) { npb_dedup_reg_25.apply (hash_with_vpn, ssap, sport, drop);
				} else if(upper_addr == 26) { npb_dedup_reg_26.apply (hash_with_vpn, ssap, sport, drop);
				} else if(upper_addr == 27) { npb_dedup_reg_27.apply (hash_with_vpn, ssap, sport, drop);
				} else if(upper_addr == 28) { npb_dedup_reg_28.apply (hash_with_vpn, ssap, sport, drop);
				} else if(upper_addr == 29) { npb_dedup_reg_29.apply (hash_with_vpn, ssap, sport, drop);
				} else if(upper_addr == 30) { npb_dedup_reg_30.apply (hash_with_vpn, ssap, sport, drop);
				} else                      { npb_dedup_reg_31.apply (hash_with_vpn, ssap, sport, drop);
				}
			}
		}

		if(drop == 1) {
			drop_ctl = 0x1;
		}
	}
}

#endif
