/* -*- P4_16 -*- */

#define FLOWTABLE_DEPTH      65536 //
#define FLOWTABLE_DEPTH_POW2 16    //

// *****************************************************************************
// Example register code, taken from "P4 Language Cheat Sheet"
// *****************************************************************************

struct pair_t {
	bit<16> hash;
	bit<16> data;
};

// =============================================================================

control npb_ing_sf_npb_basic_adv_dedup (
	in    switch_header_t                           hdr,
	inout switch_ingress_metadata_t                 ig_md,
	in    ingress_intrinsic_metadata_t              ig_intr_md,
	in    ingress_intrinsic_metadata_from_parser_t  ig_intr_from_prsr,
	inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
	inout ingress_intrinsic_metadata_for_tm_t       ig_intr_md_for_tm
) {

	bit<32> flowtable_hash;
	bit<16> flowtable_hash_hi;
	bit<16> flowtable_hash_lo;

	// =========================================================================
	// The Register Array
	// =========================================================================

	Register<pair_t, bit<32>>(32w1024) test_reg;                          // syntax seems to be <data type, index type>

	RegisterAction<pair_t, bit<32>, bit<8>>(test_reg) test_reg_action = { // syntax seems to be <data type, index type, return type>
		void apply(
			inout pair_t  reg_value,   // register entry
			out   bit<8>  return_value // return value
		) {
			// check entry
			if((reg_value.hash == flowtable_hash[31:16]) && (reg_value.data != (bit<16>)ig_intr_md.ingress_port)) {
				return_value = 1; // drop packet
			} else {
				return_value = 0; // pass packet
			}

/*
			return_value = (bit<8>)((bit<1>)((bit<16>)flowtable_hash[31:16]   - reg_value.hash == 0) &
			                        (bit<1>)((bit<16>)ig_intr_md.ingress_port - reg_value.data != 0));
*/

			// update entry
			reg_value.hash = (bit<16>)(flowtable_hash[31:16]);
			reg_value.data = (bit<16>)(ig_intr_md.ingress_port);
		}
	};

	// =========================================================================
	// The Hash Function
	// =========================================================================

	Hash<bit<32>>(HashAlgorithm_t.CRC32) h;

	// =========================================================================
	// The Apply Block
	// =========================================================================

	apply {

		bit<8> return_value;

		// ***** hash the key *****
		flowtable_hash = h.get({hdr.ipv4.src_addr, hdr.ipv4.dst_addr, hdr.ipv4.protocol, hdr.tcp.src_port, hdr.tcp.dst_port});

		flowtable_hash_hi = flowtable_hash[31:16];
		flowtable_hash_lo = flowtable_hash[15: 0];

		// ***** use hashed key to index register *****
		return_value = test_reg_action.execute((bit<32>)flowtable_hash_lo);

		// ***** drop packet? *****
		if(return_value != 0) {
			ig_intr_md_for_dprsr.drop_ctl = 0x1; // drop packet
		}

	}

}
