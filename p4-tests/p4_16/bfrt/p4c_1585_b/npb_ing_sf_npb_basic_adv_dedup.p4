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
	in    switch_header_t                             hdr,
	inout switch_egress_metadata_t                    eg_md,
	in    egress_intrinsic_metadata_t                 eg_intr_md,
	in    egress_intrinsic_metadata_from_parser_t     eg_intr_from_prsr,
	inout egress_intrinsic_metadata_for_deparser_t    eg_intr_md_for_dprsr,
	inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport
) {

	bit<32> flowtable_hash;
	bit<16> flowtable_hash_hi;
	bit<16> flowtable_hash_lo;

	// =========================================================================
	// The Hash Function
	// =========================================================================

//	Hash<bit<32>>(HashAlgorithm_t.CRC32) h;

	Hash<bit<16>>(HashAlgorithm_t.CRC16) h1;
	Hash<bit<16>>(HashAlgorithm_t.CRC16) h2;

	// =========================================================================
	// The Register Array
	// =========================================================================

	Register      <pair_t, bit<16>        >(32w65536) test_reg;           // syntax seems to be <data type, index type>
//	Register      <pair_t, bit<16>        >(32w1024 ) test_reg;           // syntax seems to be <data type, index type>

	// =========================================================================

	RegisterAction<pair_t, bit<16>, bit<8>>(test_reg) register_array = { // syntax seems to be <data type, index type, return type>
		void apply(
			inout pair_t  reg_value,   // register entry
			out   bit<8>  return_value // return value
		) {
			// check entry
/*
			if((reg_value.hash == flowtable_hash_hi) && (reg_value.data != (bit<16>)eg_md.ingress_port)) {
//			if((reg_value.hash == flowtable_hash[31:16]) && (reg_value.data != (bit<16>)eg__md.ingress_port)) {
				return_value = 1; // drop packet
			} else {
				return_value = 0; // pass packet
			}

			// update entry
			reg_value.hash = flowtable_hash_hi;
//			reg_value.hash = (bit<16>)flowtable_hash[31:16];
			reg_value.data = (bit<16>)eg_md.ingress_port;
*/

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

		bit<16> l4_src_port;
		bit<16> l4_dst_port;

		if(hdr.tcp.isValid() == true) {
			l4_src_port = hdr.tcp.src_port;
			l4_dst_port = hdr.tcp.dst_port;
		} else if(hdr.udp.isValid() == true) {
			l4_src_port = hdr.udp.src_port;
			l4_dst_port = hdr.udp.dst_port;
		}

//		if(lkp.ip_type == SWITCH_IP_TYPE_IPV4) {
		if(hdr.ipv4.isValid() == true) {
			// ***** hash the key *****
/*
			flowtable_hash    = h.get({lkp.ipv4_src_addr, lkp.ipv4_dst_addr, lkp.ip_proto, lkp.l4_src_port, lkp.l4_dst_port});
			flowtable_hash_lo = flowtable_hash[15: 0];
			flowtable_hash_hi = flowtable_hash[31:16];
*/
//			flowtable_hash_lo = h1.get({lkp.ipv4_src_addr, lkp.ipv4_dst_addr, lkp.ip_proto, lkp.l4_src_port, lkp.l4_dst_port});
//			flowtable_hash_hi = h2.get({lkp.ipv4_src_addr, lkp.ipv4_dst_addr, lkp.ip_proto, lkp.l4_src_port, lkp.l4_dst_port});
			flowtable_hash_lo = h1.get({hdr.ipv4.src_addr, hdr.ipv4.dst_addr, hdr.ipv4.protocol, l4_src_port, l4_dst_port});
			flowtable_hash_hi = h2.get({hdr.ipv4.src_addr, hdr.ipv4.dst_addr, hdr.ipv4.protocol, l4_src_port, l4_dst_port});

			// ***** use hashed key to index register *****
			return_value = register_array.execute(flowtable_hash_lo);

			// ***** drop packet? *****
			if(return_value != 0) {
				eg_intr_md_for_dprsr.drop_ctl = 0x1; // drop packet
			}
		}

	}

}
