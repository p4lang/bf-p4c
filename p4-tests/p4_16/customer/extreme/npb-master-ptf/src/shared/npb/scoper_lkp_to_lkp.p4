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

#ifndef _SCOPER_LKP_TO_LKP_
#define _SCOPER_LKP_TO_LKP_

// ============================================================================
// Low Level Routines (meant to only be used by functions within this file)
// ============================================================================

control Scoper_DataMux_LkpToLkp(
		in    switch_lookup_fields_t lkp_curr,

		inout switch_lookup_fields_t lkp
) {

//	action scoper() {
	apply {
#if 0
		// Derek: Can't use this code, as we need to alias the 128-bit ip addresses with a 32-bit version.  Need to use the code below instead.
		lkp = lkp_curr;
#else
		// l2
		if(lkp_curr.l2_valid != false) {
			// only update if next layer has l2
			lkp.mac_src_addr        = lkp_curr.mac_src_addr;
			lkp.mac_dst_addr        = lkp_curr.mac_dst_addr;
//			lkp.mac_type            = lkp_curr.mac_type;
			lkp.pcp                 = lkp_curr.pcp;
			lkp.pad                 = lkp_curr.pad;
			lkp.vid                 = lkp_curr.vid;
		}
		lkp.mac_type            = lkp_curr.mac_type;

		// l3
		lkp.ip_type             = lkp_curr.ip_type;
		lkp.ip_proto            = lkp_curr.ip_proto;
		lkp.ip_tos              = lkp_curr.ip_tos;
		lkp.ip_flags            = lkp_curr.ip_flags;
		lkp.ip_src_addr         = lkp_curr.ip_src_addr;
		lkp.ip_dst_addr         = lkp_curr.ip_dst_addr;
		// Comment the two below as they are alias fields and do not need to be written again.
		//lkp.ip_src_addr_v4    = lkp_curr.ip_src_addr_v4;
		//lkp.ip_dst_addr_v4    = lkp_curr.ip_dst_addr_v4;
		lkp.ip_len              = lkp_curr.ip_len;

		// l4
		lkp.tcp_flags           = lkp_curr.tcp_flags;
		lkp.l4_src_port         = lkp_curr.l4_src_port;
		lkp.l4_dst_port         = lkp_curr.l4_dst_port;

		// tunnel
  #ifdef INGRESS_PARSER_INNER_TUNNEL_INFO_OVERLOAD
		if(lkp_curr.tunnel_type != SWITCH_TUNNEL_TYPE_NONE) {
			// only update if next layer has tunnel
			lkp.tunnel_type         = lkp_curr.tunnel_type;
			lkp.tunnel_id           = lkp_curr.tunnel_id;
		}
  #else
		lkp.tunnel_type         = lkp_curr.tunnel_type;
		lkp.tunnel_id           = lkp_curr.tunnel_id;
  #endif

  #ifdef SF_2_ACL_INNER_OUTER_TUNNEL_KEY_ENABLE
		// outer means two back from current scope (scope-2), inner means one back from current scope (scope-1)
		lkp.tunnel_outer_type   = lkp_curr.tunnel_outer_type; // egress only
		lkp.tunnel_inner_type   = lkp_curr.tunnel_inner_type; // egress only
  #endif

		// misc
		lkp.next_lyr_valid      = lkp_curr.next_lyr_valid;
#endif
	}
/*
	apply {
		scoper();
	}
*/
}

#endif
