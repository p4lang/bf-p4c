/* -*- P4_16 -*- */

//#define DEPTH      32w65536
//#define DEPTH_POW2 16

#define DEPTH      32w131072
#define DEPTH_POW2 17

//#define DEPTH      32w262144
//#define DEPTH_POW2 18

#define HASH_HACK

// =============================================================================
// =============================================================================
// Example register code, taken from "P4 Language Cheat Sheet"
// =============================================================================
// =============================================================================

struct pair_t {
	bit<16> hash;
	bit<16> data;
};

// =============================================================================

control npb_ing_sf_npb_basic_adv_dedup_reg (
	in    switch_header_transport_t                   hdr,
	inout switch_egress_metadata_t                    eg_md,
	in    egress_intrinsic_metadata_t                 eg_intr_md,
	in    egress_intrinsic_metadata_from_parser_t     eg_intr_md_from_prsr,
	inout egress_intrinsic_metadata_for_deparser_t    eg_intr_md_for_dprsr,
	inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport,

	in    bit<DEPTH_POW2>                             flowtable_hash_lo,
	in    bit<16>                                     flowtable_hash_hi // always 16 bits
) {

	// =========================================================================
	// The Register Array
	// =========================================================================

	Register      <pair_t, bit<DEPTH_POW2>>(DEPTH)            test_reg;          // syntax seems to be <data type, index type>

	// =========================================================================

	RegisterAction<pair_t, bit<DEPTH_POW2>, bit<8>>(test_reg) register_array = { // syntax seems to be <data type, index type, return type>
		void apply(
			inout pair_t  reg_value,   // register entry
			out   bit<8>  return_value // return value
		) {
			if(reg_value.hash == flowtable_hash_hi) {
				// existing flow
				// --------
				if(reg_value.data == (bit<16>)(eg_md.ingress_port)) {
					// same port
					// --------
					return_value = 0; // pass packet
				} else {
					// different port
					// --------
					return_value = 1; // drop packet
				}
			} else {
				// new flow (entry collision, overwrite old flow)
				// --------
				// update entry
				reg_value.hash = flowtable_hash_hi;
				reg_value.data = (bit<16>)(eg_md.ingress_port);

				return_value = 0; // pass packet
			}
		}
	};

	// =========================================================================
	// The Apply Block
	// =========================================================================

	apply {

		bit<8> return_value;

		// ***** hash the key *****
//		flowtable_hash_lo = flowtable_hash[15: 0];
//		flowtable_hash_hi = flowtable_hash[31:16];

		// ***** use hashed key to index register *****
		return_value = register_array.execute(flowtable_hash_lo);

		// ***** drop packet? *****
		if(return_value != 0) {
			eg_intr_md_for_dprsr.drop_ctl = 0x1; // drop packet
		}

	}

}

// =============================================================================
// =============================================================================
// =============================================================================
// =============================================================================
// =============================================================================

control npb_ing_sf_npb_basic_adv_dedup (
	in    switch_header_transport_t                   hdr,
	inout switch_egress_metadata_t                    eg_md,
	in    egress_intrinsic_metadata_t                 eg_intr_md,
	in    egress_intrinsic_metadata_from_parser_t     eg_intr_md_from_prsr,
	inout egress_intrinsic_metadata_for_deparser_t    eg_intr_md_for_dprsr,
	inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport
) {
	npb_ing_sf_npb_basic_adv_dedup_reg() npb_ing_sf_npb_basic_adv_dedup_reg_0;

	bit<32> flowtable_hash;

	bit<DEPTH_POW2> flowtable_hash_lo;
	bit<16>         flowtable_hash_hi; // always 16 bits

	// =========================================================================
	// The Hash Function
	// =========================================================================

#ifndef HASH_HACK
	Hash<bit<32        >>(HashAlgorithm_t.CRC32) h;
#else
	Hash<bit<DEPTH_POW2>>(HashAlgorithm_t.CRC32) h_lo;
	Hash<bit<16        >>(HashAlgorithm_t.CRC16) h_hi; // always 16 bits
#endif

	// =========================================================================
	// The Apply Block
	// =========================================================================

	apply {
		// ***** hash the key *****
#ifndef HASH_HACK
		flowtable_hash    = h.get ({
#ifdef BUG_10439_WORKAROUND
                eg_md.lkp.ip_src_addr_3,
                eg_md.lkp.ip_src_addr_2,
                eg_md.lkp.ip_src_addr_1,
                eg_md.lkp.ip_src_addr_0,
                eg_md.lkp.ip_dst_addr_3,
                eg_md.lkp.ip_dst_addr_2,
                eg_md.lkp.ip_dst_addr_1,
                eg_md.lkp.ip_dst_addr_0,
#else
                eg_md.lkp.ip_src_addr,
                eg_md.lkp.ip_dst_addr,
#endif // BUG_10439_WORKAROUND
                eg_md.lkp.ip_proto,
                eg_md.lkp.l4_src_port,
                eg_md.lkp.l4_dst_port});
		flowtable_hash_lo = flowtable_hash[15: 0];
		flowtable_hash_hi = flowtable_hash[31:16];
#else
		flowtable_hash_lo = h_lo.get({
#ifdef BUG_10439_WORKAROUND
                eg_md.lkp.ip_src_addr_3,
                eg_md.lkp.ip_src_addr_2,
                eg_md.lkp.ip_src_addr_1,
                eg_md.lkp.ip_src_addr_0,
                eg_md.lkp.ip_dst_addr_3,
                eg_md.lkp.ip_dst_addr_2,
                eg_md.lkp.ip_dst_addr_1,
                eg_md.lkp.ip_dst_addr_0,
#else
                eg_md.lkp.ip_src_addr,
                eg_md.lkp.ip_dst_addr,
#endif // BUG_10439_WORKAROUND
                eg_md.lkp.ip_proto,
                eg_md.lkp.l4_src_port,
                eg_md.lkp.l4_dst_port});
		flowtable_hash_hi = h_hi.get({
#ifdef BUG_10439_WORKAROUND
                eg_md.lkp.ip_src_addr_3,
                eg_md.lkp.ip_src_addr_2,
                eg_md.lkp.ip_src_addr_1,
                eg_md.lkp.ip_src_addr_0,
                eg_md.lkp.ip_dst_addr_3,
                eg_md.lkp.ip_dst_addr_2,
                eg_md.lkp.ip_dst_addr_1,
                eg_md.lkp.ip_dst_addr_0,
#else
                eg_md.lkp.ip_src_addr,
                eg_md.lkp.ip_dst_addr,
#endif // BUG_10439_WORKAROUND
                eg_md.lkp.ip_proto,
                eg_md.lkp.l4_src_port,
                eg_md.lkp.l4_dst_port});
#endif

		// note: the register code has been structured such that multiple
		// registers can be laid down, perhaps using the upper bits of the hash
		// to select between them....

		// ***** call dedup function *****
		npb_ing_sf_npb_basic_adv_dedup_reg_0.apply (
			hdr,
			eg_md,
			eg_intr_md,
			eg_intr_md_from_prsr,
			eg_intr_md_for_dprsr,
			eg_intr_md_for_oport,

			flowtable_hash_lo,
			flowtable_hash_hi
		);

	}
}
