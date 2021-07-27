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

#ifndef _UTIL_
#define _UTIL_

#include "types.p4"

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

// Flow hash calculation.

control Ipv4Hash(in switch_lookup_fields_t lkp, out switch_hash_t hash) {
//	@symmetric("ig_md.lkp_1.ip_src_addr[31:0]", "ig_md.lkp_1.ip_dst_addr[31:0]")
	@symmetric("ig_md.lkp_1.ip_src_addr_v4",    "ig_md.lkp_1.ip_dst_addr_v4")
	@symmetric("ig_md.lkp_1.l4_src_port",       "ig_md.lkp_1.l4_dst_port")

	Hash<bit<switch_lag_hash_width>>(HashAlgorithm_t.CRC32) ipv4_hash;

	apply {
		hash [31:0] = ipv4_hash.get({
//			lkp.ip_src_addr[31:0],
//			lkp.ip_dst_addr[31:0],
			lkp.ip_src_addr_v4,
			lkp.ip_dst_addr_v4,
			lkp.ip_proto,
			lkp.l4_dst_port,
			lkp.l4_src_port,
			lkp.tunnel_id // extreme added
		});
	}
}

control Ipv6Hash(in switch_lookup_fields_t lkp, out switch_hash_t hash) {
	@symmetric("ig_md.lkp_1.ip_src_addr", "ig_md.lkp_1.ip_dst_addr")
	@symmetric("ig_md.lkp_1.l4_src_port", "ig_md.lkp_1.l4_dst_port")

	Hash<bit<switch_lag_hash_width>>(HashAlgorithm_t.CRC32) ipv6_hash;

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

control NonIpHash(in switch_lookup_fields_t lkp, out switch_hash_t hash) {
	@symmetric("ig_md.lkp_1.mac_src_addr", "ig_md.lkp_1.mac_dst_addr")

	Hash<bit<switch_lag_hash_width>>(HashAlgorithm_t.CRC32) non_ip_hash;

	apply {
		hash [31:0] = non_ip_hash.get({
			lkp.mac_type,
			lkp.mac_src_addr,
			lkp.mac_dst_addr
		});
	}
}

// -----------------------------------------------------------------------------

// Bridged metadata fields for Egress pipeline.
action add_bridged_md(
	inout switch_bridged_metadata_h bridged_md,
	in switch_ingress_metadata_t ig_md
) {
	bridged_md.setValid();
	bridged_md.src = SWITCH_PKT_SRC_BRIDGED;
	bridged_md.base = {
		ig_md.port,
#ifdef CPU_HDR_CONTAINS_EG_PORT
		ig_md.egress_port,
#else
		ig_md.port_lag_index,
#endif
//		ig_md.bd,
		0,
		ig_md.nexthop,
//		ig_md.lkp.pkt_type,
		ig_md.cpu_reason,
		ig_md.timestamp,
		ig_md.hash,
		ig_md.flags.transport_valid,
		ig_md.flags.bypass_egress
	};

	bridged_md.nsh = {
//		ig_md.nsh_md.start_of_path,
		ig_md.nsh_md.end_of_path,
		ig_md.nsh_md.l2_fwd_en,
//		ig_md.nsh_md.sf1_active,
		ig_md.nsh_md.dedup_en
	};

#ifdef TUNNEL_ENABLE
	bridged_md.tunnel = {
		ig_md.tunnel_0.dip_index,
		ig_md.tunnel_nexthop
//		ig_md.hash[15:0],

//		ig_md.tunnel_0.terminate // unused, but removing causes a compiler error
//		ig_md.tunnel_1.terminate,
//		ig_md.tunnel_2.terminate
	};
#endif

#ifdef DTEL_ENABLE
	bridged_md.dtel = {
		ig_md.dtel.report_type,
		ig_md.dtel.session_id,
		ig_md.hash,
		ig_md.egress_port
	};
#endif
}

// -----------------------------------------------------------------------------

action set_ig_intr_md(
	in switch_ingress_metadata_t ig_md,
	inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
	inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm
) {
	ig_intr_md_for_tm.mcast_grp_b = ig_md.multicast.id;

	// Set PRE hash values
	bit<13> hash;
#if(switch_lag_hash_width < 26)
	hash = (bit<13>)ig_md.hash[switch_lag_hash_width-1   :switch_lag_hash_width/2]; // grow to 13 bits
#else
	hash =          ig_md.hash[switch_lag_hash_width/2+12:switch_lag_hash_width/2]; // cap  at 13 bits
#endif

//	ig_intr_md_for_tm.level1_mcast_hash = ig_md.hash[12:0];
//	ig_intr_md_for_tm.level2_mcast_hash = ig_md.hash[28:16];
	ig_intr_md_for_tm.level2_mcast_hash = hash;
#if __TARGET_TOFINO__ == 2 || __TARGET_TOFINO__ == 3
//	ig_intr_md_for_dprsr.mirror_type = (bit<4>) ig_md.mirror.type;
#else
//	ig_intr_md_for_dprsr.mirror_type = (bit<3>) ig_md.mirror.type;
#endif
}

// -----------------------------------------------------------------------------

action set_eg_intr_md(
	in switch_egress_metadata_t eg_md,
	inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
	inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport
) {
#ifdef MIRROR_ENABLE
#if __TARGET_TOFINO__ == 1
	eg_intr_md_for_dprsr.mirror_type = (bit<3>) eg_md.mirror.type;
#else
	eg_intr_md_for_dprsr.mirror_type = (bit<4>) eg_md.mirror.type;
	eg_intr_md_for_dprsr.mirror_io_select = 1;
#endif
#endif
}


#endif /* _UTIL_ */
