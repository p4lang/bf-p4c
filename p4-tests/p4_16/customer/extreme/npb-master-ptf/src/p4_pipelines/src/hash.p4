/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2015-2019 Barefoot Networks, Inc.

 * All Rights Reserved.
 *
 * NOTICE: All information contained herein is, and remains the property of
 * Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
 * technical concepts contained herein are proprietary to Barefoot Networks,
 * Inc.
 * and its suppliers and may be covered by U.S. and Foreign Patents, patents in
 * process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material is
 * strictly forbidden unless prior written permission is obtained from
 * Barefoot Networks, Inc.
 *
 * No warranty, explicit or implicit is provided, unless granted under a
 * written agreement with Barefoot Networks, Inc.
 *
 ******************************************************************************/

#ifndef _HASH_
#define _HASH_

#include "types.p4"

// Flow hash calculation.

// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
// Hash Mask -------------------------------------------------------------------
// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------

control HashMask(
	inout switch_lookup_fields_t lkp,
	inout bit<6>                 lkp_hash_mask_en
) {

	// -----------------------------------------

	apply {
#ifdef LAG_HASH_MASKING_ENABLE
//		if(lkp_hash_mask_en[0:0] == 1) { lkp.mac_type     = 0; }
//		if(lkp_hash_mask_en[1:1] == 1) { lkp.mac_src_addr = 0; }
//		if(lkp_hash_mask_en[1:1] == 1) { lkp.mac_dst_addr = 0; }
		if(lkp_hash_mask_en[2:2] == 1) { lkp.ip_src_addr  = 0; }
		if(lkp_hash_mask_en[2:2] == 1) { lkp.ip_dst_addr  = 0; }
		if(lkp_hash_mask_en[3:3] == 1) { lkp.ip_proto     = 0; }
		if(lkp_hash_mask_en[4:4] == 1) { lkp.l4_src_port  = 0; }
		if(lkp_hash_mask_en[4:4] == 1) { lkp.l4_dst_port  = 0; }
		if(lkp_hash_mask_en[5:5] == 1) { lkp.tunnel_id    = 0; }
#endif
	}
}

// -----------------------------------------------------------------------------

// If fragments, then reset hash l4 port values to zero
// For non fragments, hash l4 ports will be init to l4 port values
control EnableFragHash(
	inout switch_lookup_fields_t lkp
) {
	apply {
//		if (lkp.ip_frag != SWITCH_IP_FRAG_NON_FRAG) {
//			lkp.hash_l4_dst_port = 0;
//			lkp.hash_l4_src_port = 0;
//		}
	}
}

// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
// Hash ------------------------------------------------------------------------
// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------

#ifdef RESILIENT_ECMP_HASH_ENABLE
//Hash<bit<32>>(HashAlgorithm_t.CRC32) ipv4_hash0;
//Hash<bit<32>>(HashAlgorithm_t.CRC32) ipv6_hash0;
//Hash<bit<32>>(HashAlgorithm_t.CRC32) non_ip_hash;
//Hash<bit<32>>(HashAlgorithm_t.CRC32) mpls_hash;
//Hash<bit<32>>(HashAlgorithm_t.CRC32) ipv4_hash1;
//Hash<bit<32>>(HashAlgorithm_t.CRC32) ipv6_hash1;

// -----------------------------------------------------------------------------
// Normal Hashes ---------------------------------------------------------------
// -----------------------------------------------------------------------------

control compute_ipv4_hash0(
	in switch_lookup_fields_t lkp,
	out bit<32> hash
) (
	switch_uint32_t coeff = 0x04c11db7 // crc32 -- for making wider hashes, we can pass in other polynoials (see training docs for more info)
) {
//	CRCPolynomial<bit<32>>(coeff = coeff, reversed = true, msb = false, extended = false, init = 0xffffffff, xor = 0xffffffff) poly; // crc32

	Hash<bit<32>>(HashAlgorithm_t.CRC32) ipv4_hash;
//	Hash<bit<32>>(HashAlgorithm_t.CUSTOM, poly) ipv4_hash;

	apply {
		hash [31:0] = ipv4_hash.get({
//			lkp.ip_src_addr[31:0],
			lkp.ip_src_addr_v4,
//			lkp.ip_dst_addr[31:0],
			lkp.ip_dst_addr_v4,
			lkp.ip_proto,
			lkp.l4_dst_port,
			lkp.l4_src_port,
			lkp.tunnel_id // extreme added
		});
	}
}

control compute_ipv6_hash0(	
	in switch_lookup_fields_t lkp,
	out bit<32> hash
) (
	switch_uint32_t coeff = 0x04c11db7 // crc32 -- for making wider hashes, we can pass in other polynoials (see training docs for more info)
) {
//	CRCPolynomial<bit<32>>(coeff = coeff, reversed = true, msb = false, extended = false, init = 0xffffffff, xor = 0xffffffff) poly; // crc32

	Hash<bit<32>>(HashAlgorithm_t.CRC32) ipv6_hash;
//	Hash<bit<32>>(HashAlgorithm_t.CUSTOM, poly) ipv6_hash;

	apply {
		hash[31:0] = ipv6_hash.get({
			lkp.ip_src_addr,
			lkp.ip_dst_addr,
			lkp.ip_proto,
			lkp.l4_dst_port,
			lkp.l4_src_port,
			lkp.tunnel_id // extreme added
		});
	}
}

control compute_non_ip_hash(
	in switch_lookup_fields_t lkp,
	out bit<32> hash
) (
	switch_uint32_t coeff = 0x04c11db7 // crc32 -- for making wider hashes, we can pass in other polynoials (see training docs for more info)
) {
//	CRCPolynomial<bit<32>>(coeff = coeff, reversed = true, msb = false, extended = false, init = 0xffffffff, xor = 0xffffffff) poly; // crc32

	Hash<bit<32>>(HashAlgorithm_t.CRC32) non_ip_hash;
//	Hash<bit<32>>(HashAlgorithm_t.CUSTOM, poly) non_ip_hash;

	apply {
		hash [31:0] = non_ip_hash.get({
			lkp.mac_type,
			lkp.mac_src_addr,
			lkp.mac_dst_addr
		});
	}
}

control compute_ipv4_hash1(
	in switch_lookup_fields_t lkp,
	out bit<32> hash
) (
	switch_uint32_t coeff = 0x04c11db7 // crc32 -- for making wider hashes, we can pass in other polynoials (see training docs for more info)
) {
//	CRCPolynomial<bit<32>>(coeff = coeff, reversed = true, msb = false, extended = false, init = 0xffffffff, xor = 0xffffffff) poly; // crc32

	Hash<bit<32>>(HashAlgorithm_t.CRC32) ipv4_hash;
//	Hash<bit<32>>(HashAlgorithm_t.CUSTOM, poly) ipv4_hash;

	apply {
		hash [31:0] = ipv4_hash.get({
			lkp.ip_proto,
			lkp.l4_src_port,
//			lkp.ip_dst_addr[31:0],
			lkp.ip_src_addr_v4,
			lkp.l4_dst_port,
//			lkp.ip_src_addr[31:0],
			lkp.ip_dst_addr_v4,
			lkp.tunnel_id // extreme added
		});
	}
}

control compute_ipv6_hash1(	
	in switch_lookup_fields_t lkp,
	out bit<32> hash
) (
	switch_uint32_t coeff = 0x04c11db7 // crc32 -- for making wider hashes, we can pass in other polynoials (see training docs for more info)
) {
//	CRCPolynomial<bit<32>>(coeff = coeff, reversed = true, msb = false, extended = false, init = 0xffffffff, xor = 0xffffffff) poly; // crc32

	Hash<bit<32>>(HashAlgorithm_t.CRC32) ipv6_hash;
//	Hash<bit<32>>(HashAlgorithm_t.CUSTOM, poly) ipv6_hash;

	apply {
		hash[31:0] = ipv6_hash.get({
			lkp.ip_proto,
			lkp.l4_src_port,
			lkp.ip_dst_addr,
			lkp.l4_dst_port,
			lkp.ip_src_addr,
			lkp.tunnel_id // extreme added
		});
	}
}

//action compute_non_ip_hash(in switch_lookup_fields_t lkp, out switch_hash_t hash) {
//    hash[31:0] = non_ip_hash.get({lkp.mac_type, lkp.mac_src_addr, lkp.mac_dst_addr});
//    hash[47:32] = 0;
//}
//

// -----------------------------------------------------------------------------
// Symmetric Hashes ------------------------------------------------------------
// -----------------------------------------------------------------------------

control compute_ipv4_hash0_symmetric(
	in switch_lookup_fields_t lkp,
	out bit<32> hash
) (
	switch_uint32_t coeff = 0x04c11db7 // crc32 -- for making wider hashes, we can pass in other polynoials (see training docs for more info)
) {
//	@symmetric("ig_md.lkp_1.ip_src_addr[31:0]", "ig_md.lkp_1.ip_dst_addr[31:0]")
	@symmetric("ig_md.lkp_1.ip_src_addr_v4",    "ig_md.lkp_1.ip_dst_addr_v4")
	@symmetric("ig_md.lkp_1.l4_src_port",       "ig_md.lkp_1.l4_dst_port")

//	CRCPolynomial<bit<32>>(coeff = coeff, reversed = true, msb = false, extended = false, init = 0xffffffff, xor = 0xffffffff) poly; // crc32

	Hash<bit<32>>(HashAlgorithm_t.CRC32) ipv4_hash;
//	Hash<bit<32>>(HashAlgorithm_t.CUSTOM, poly) ipv4_hash;

	apply {
		hash [31:0] = ipv4_hash.get({
//			lkp.ip_src_addr[31:0],
			lkp.ip_src_addr_v4,
//			lkp.ip_dst_addr[31:0],
			lkp.ip_dst_addr_v4,
			lkp.ip_proto,
			lkp.l4_dst_port,
			lkp.l4_src_port,
			lkp.tunnel_id // extreme added
		});
	}
}

control compute_ipv6_hash0_symmetric(
	in switch_lookup_fields_t lkp,
	out bit<32> hash
) (
	switch_uint32_t coeff = 0x04c11db7 // crc32 -- for making wider hashes, we can pass in other polynoials (see training docs for more info)
) {
	@symmetric("ig_md.lkp_1.ip_src_addr", "ig_md.lkp_1.ip_dst_addr")
	@symmetric("ig_md.lkp_1.l4_src_port", "ig_md.lkp_1.l4_dst_port")

//	CRCPolynomial<bit<32>>(coeff = coeff, reversed = true, msb = false, extended = false, init = 0xffffffff, xor = 0xffffffff) poly; // crc32

	Hash<bit<32>>(HashAlgorithm_t.CRC32) ipv6_hash;
//	Hash<bit<32>>(HashAlgorithm_t.CUSTOM, poly) ipv6_hash;

	apply {
		hash[31:0] = ipv6_hash.get({
			lkp.ip_src_addr,
			lkp.ip_dst_addr,
			lkp.ip_proto,
			lkp.l4_dst_port,
			lkp.l4_src_port,
			lkp.tunnel_id // extreme added
		});
	}
}

control compute_non_ip_hash_symmetric(
	in switch_lookup_fields_t lkp,
	out bit<32> hash
) (
	switch_uint32_t coeff = 0x04c11db7 // crc32 -- for making wider hashes, we can pass in other polynoials (see training docs for more info)
) {
	@symmetric("ig_md.lkp_1.mac_src_addr", "ig_md.lkp_1.mac_dst_addr")

//	CRCPolynomial<bit<32>>(coeff = coeff, reversed = true, msb = false, extended = false, init = 0xffffffff, xor = 0xffffffff) poly; // crc32

	Hash<bit<32>>(HashAlgorithm_t.CRC32) non_ip_hash;
//	Hash<bit<32>>(HashAlgorithm_t.CUSTOM, poly) non_ip_hash;

	apply {
		hash [31:0] = non_ip_hash.get({
			lkp.mac_type,
			lkp.mac_src_addr,
			lkp.mac_dst_addr
		});
	}
}

control compute_ipv4_hash1_symmetric(
	in switch_lookup_fields_t lkp,
	out bit<32> hash
) (
	switch_uint32_t coeff = 0x04c11db7 // crc32 -- for making wider hashes, we can pass in other polynoials (see training docs for more info)
) {
//	@symmetric("ig_md.lkp_1.ip_src_addr[31:0]", "ig_md.lkp_1.ip_dst_addr[31:0]")
	@symmetric("ig_md.lkp_1.ip_src_addr_v4",    "ig_md.lkp_1.ip_dst_addr_v4")
	@symmetric("ig_md.lkp_1.l4_src_port",       "ig_md.lkp_1.l4_dst_port")

//	CRCPolynomial<bit<32>>(coeff = coeff, reversed = true, msb = false, extended = false, init = 0xffffffff, xor = 0xffffffff) poly; // crc32

	Hash<bit<32>>(HashAlgorithm_t.CRC32) ipv4_hash;
//	Hash<bit<32>>(HashAlgorithm_t.CUSTOM, poly) ipv4_hash;

	apply {
		hash [31:0] = ipv4_hash.get({
			lkp.ip_proto,
			lkp.l4_src_port,
//			lkp.ip_dst_addr[31:0],
			lkp.ip_dst_addr_v4,
			lkp.l4_dst_port,
//			lkp.ip_src_addr[31:0],
			lkp.ip_src_addr_v4,
			lkp.tunnel_id // extreme added
		});
	}
}

control compute_ipv6_hash1_symmetric(
	in switch_lookup_fields_t lkp,
	out bit<32> hash
) (
	switch_uint32_t coeff = 0x04c11db7 // crc32 -- for making wider hashes, we can pass in other polynoials (see training docs for more info)
) {
	@symmetric("ig_md.lkp_1.ip_src_addr", "ig_md.lkp_1.ip_dst_addr")
	@symmetric("ig_md.lkp_1.l4_src_port", "ig_md.lkp_1.l4_dst_port")

//	CRCPolynomial<bit<32>>(coeff = coeff, reversed = true, msb = false, extended = false, init = 0xffffffff, xor = 0xffffffff) poly; // crc32

	Hash<bit<32>>(HashAlgorithm_t.CRC32) ipv6_hash;
//	Hash<bit<32>>(HashAlgorithm_t.CUSTOM, poly) ipv6_hash;

	apply {
		hash[31:0] = ipv6_hash.get({
			lkp.ip_proto,
			lkp.l4_src_port,
			lkp.ip_dst_addr,
			lkp.l4_dst_port,
			lkp.ip_src_addr,
			lkp.tunnel_id // extreme added
		});
	}
}

//action compute_non_ip_hash_symmetric(in switch_lookup_fields_t lkp, out switch_hash_t hash) {
//    hash[31:0] = non_ip_hash.get({lkp.mac_type, lkp.mac_src_addr, lkp.mac_dst_addr});
//    hash[47:32] = 0;
//}
//
#endif

// -----------------------------------------------------------------------------
// Normal Hashes ---------------------------------------------------------------
// -----------------------------------------------------------------------------

control Ipv4Hash(
	in switch_lookup_fields_t lkp,
	out switch_hash_t hash
) (
	switch_uint32_t coeff = 0x04c11db7 // crc32 -- for making wider hashes, we can pass in other polynoials (see training docs for more info)
) {
//	CRCPolynomial<bit<32>>(coeff = coeff, reversed = true, msb = false, extended = false, init = 0xffffffff, xor = 0xffffffff) poly; // crc32

	Hash<bit<32>>(HashAlgorithm_t.CRC32) ipv4_hash;
//	Hash<bit<32>>(HashAlgorithm_t.CUSTOM, poly) ipv4_hash;

	apply {
		hash [31:0] = ipv4_hash.get({
//			lkp.ip_src_addr[31:0],
			lkp.ip_src_addr_v4,
//			lkp.ip_dst_addr[31:0],
			lkp.ip_dst_addr_v4,
			lkp.ip_proto,
			lkp.l4_dst_port,
			lkp.l4_src_port,
			lkp.tunnel_id // extreme added
		});
	}
}

control Ipv6Hash(	
	in switch_lookup_fields_t lkp,
	out switch_hash_t hash
) (
	switch_uint32_t coeff = 0x04c11db7 // crc32 -- for making wider hashes, we can pass in other polynoials (see training docs for more info)
) {
//	CRCPolynomial<bit<32>>(coeff = coeff, reversed = true, msb = false, extended = false, init = 0xffffffff, xor = 0xffffffff) poly; // crc32

	Hash<bit<32>>(HashAlgorithm_t.CRC32) ipv6_hash;
//	Hash<bit<32>>(HashAlgorithm_t.CUSTOM, poly) ipv6_hash;

	apply {
		hash[31:0] = ipv6_hash.get({
			lkp.ip_src_addr,
			lkp.ip_dst_addr,
			lkp.ip_proto,
			lkp.l4_dst_port,
			lkp.l4_src_port,
			lkp.tunnel_id // extreme added
		});
	}
}

control NonIpHash(
	in switch_lookup_fields_t lkp,
	out switch_hash_t hash
) (
	switch_uint32_t coeff = 0x04c11db7 // crc32 -- for making wider hashes, we can pass in other polynoials (see training docs for more info)
) {
//	CRCPolynomial<bit<32>>(coeff = coeff, reversed = true, msb = false, extended = false, init = 0xffffffff, xor = 0xffffffff) poly; // crc32

	Hash<bit<32>>(HashAlgorithm_t.CRC32) non_ip_hash;
//	Hash<bit<32>>(HashAlgorithm_t.CUSTOM, poly) non_ip_hash;

	apply {
		hash [31:0] = non_ip_hash.get({
			lkp.mac_type,
			lkp.mac_src_addr,
			lkp.mac_dst_addr
		});
	}
}

#ifdef MPLS_ENABLE
control MplsHash(
	in switch_header_t hdr,
	in switch_lookup_fields_t lkp,
	out switch_hash_t hash
) (
	switch_uint32_t coeff = 0x04c11db7 // crc32 -- for making wider hashes, we can pass in other polynoials (see training docs for more info)
) {
//	CRCPolynomial<bit<32>>(coeff = coeff, reversed = true, msb = false, extended = false, init = 0xffffffff, xor = 0xffffffff) poly; // crc32

	Hash<bit<32>>(HashAlgorithm_t.CRC32) mpls_hash;
//	Hash<bit<32>>(HashAlgorithm_t.CUSTOM, poly) mpls_hash;

	apply {
		hash [31:0] = mpls_hash.get({
			hdr.mpls[0].label,
			hdr.mpls[1].label,
			hdr.mpls[2].label
		});
	}
}
#endif /* MPLS_ENABLE */

// -----------------------------------------------------------------------------
// Symmetric Hashes ------------------------------------------------------------
// -----------------------------------------------------------------------------

control Ipv4HashSymmetric(
	in switch_lookup_fields_t lkp,
	out switch_hash_t hash
) (
	switch_uint32_t coeff = 0x04c11db7 // crc32 -- for making wider hashes, we can pass in other polynoials (see training docs for more info)
) {
//	@symmetric("ig_md.lkp_1.ip_src_addr[31:0]", "ig_md.lkp_1.ip_dst_addr[31:0]")
	@symmetric("ig_md.lkp_1.ip_src_addr_v4",    "ig_md.lkp_1.ip_dst_addr_v4")
	@symmetric("ig_md.lkp_1.l4_src_port",       "ig_md.lkp_1.l4_dst_port")

//	CRCPolynomial<bit<32>>(coeff = coeff, reversed = true, msb = false, extended = false, init = 0xffffffff, xor = 0xffffffff) poly; // crc32

	Hash<bit<32>>(HashAlgorithm_t.CRC32) ipv4_hash;
//	Hash<bit<32>>(HashAlgorithm_t.CUSTOM, poly) ipv4_hash;

	apply {
		hash [31:0] = ipv4_hash.get({
//			lkp.ip_src_addr[31:0],
			lkp.ip_src_addr_v4,
//			lkp.ip_dst_addr[31:0],
			lkp.ip_dst_addr_v4,
			lkp.ip_proto,
			lkp.l4_dst_port,
			lkp.l4_src_port,
			lkp.tunnel_id // extreme added
		});
	}
}

control Ipv6HashSymmetric(
	in switch_lookup_fields_t lkp,
	out switch_hash_t hash
) (
	switch_uint32_t coeff = 0x04c11db7 // crc32 -- for making wider hashes, we can pass in other polynoials (see training docs for more info)
) {
	@symmetric("ig_md.lkp_1.ip_src_addr", "ig_md.lkp_1.ip_dst_addr")
	@symmetric("ig_md.lkp_1.l4_src_port", "ig_md.lkp_1.l4_dst_port")

//	CRCPolynomial<bit<32>>(coeff = coeff, reversed = true, msb = false, extended = false, init = 0xffffffff, xor = 0xffffffff) poly; // crc32

	Hash<bit<32>>(HashAlgorithm_t.CRC32) ipv6_hash;
//	Hash<bit<32>>(HashAlgorithm_t.CUSTOM, poly) ipv6_hash;

	apply {
		hash[31:0] = ipv6_hash.get({
			lkp.ip_src_addr,
			lkp.ip_dst_addr,
			lkp.ip_proto,
			lkp.l4_dst_port,
			lkp.l4_src_port,
			lkp.tunnel_id // extreme added
		});
	}
}

control NonIpHashSymmetric(
	in switch_lookup_fields_t lkp,
	out switch_hash_t hash
) (
	switch_uint32_t coeff = 0x04c11db7 // crc32 -- for making wider hashes, we can pass in other polynoials (see training docs for more info)
) {
	@symmetric("ig_md.lkp_1.mac_src_addr", "ig_md.lkp_1.mac_dst_addr")

//	CRCPolynomial<bit<32>>(coeff = coeff, reversed = true, msb = false, extended = false, init = 0xffffffff, xor = 0xffffffff) poly; // crc32

	Hash<bit<32>>(HashAlgorithm_t.CRC32) non_ip_hash;
//	Hash<bit<32>>(HashAlgorithm_t.CUSTOM, poly) non_ip_hash;

	apply {
		hash [31:0] = non_ip_hash.get({
			lkp.mac_type,
			lkp.mac_src_addr,
			lkp.mac_dst_addr
		});
	}
}

#endif /* _HASH_ */
