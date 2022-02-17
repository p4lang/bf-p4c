#ifndef _PKT_LEN_
#define _PKT_LEN_

//=================================================================================
// Egress
//=================================================================================

control PayloadLenEgress(
	inout switch_header_transport_t hdr_0,
	inout switch_header_outer_t hdr_1,
	inout switch_header_inner_t hdr_2,
	inout switch_header_inner_inner_t hdr_3,

	inout bit<16> gre_proto,

	inout switch_egress_metadata_t eg_md,
	in    egress_intrinsic_metadata_t eg_intr_md
) (
	MODULE_DEPLOYMENT_PARAMS
) {

	bit<16> l2_len;

	//=============================================================================
	// Table:
	//=============================================================================

	action get_l2_len_hit(bit<16> l2_len_) {
		l2_len = l2_len_;
	}

	// Find the length of the l2.  Note that since this routine is only used for
	// mirrored packets, and we don't allow decaps on mirrored packets, we only ever
	// need to look at the first ethernet, since it will always be valid....

	table get_l2_len {
		key = {
			hdr_1.e_tag.isValid()       : exact;
			hdr_1.vn_tag.isValid()      : exact;
			hdr_1.vlan_tag[0].isValid() : exact;
			hdr_1.vlan_tag[1].isValid() : exact;
		}

		actions = {
			NoAction;
			get_l2_len_hit;
		}

		const entries = {
			(false, false, false, false) : get_l2_len_hit(14); // no tag

			(true,  false, false, false) : get_l2_len_hit(22); // e tag
			(false, true,  false, false) : get_l2_len_hit(20); // vn tag

			(false, false, true,  false) : get_l2_len_hit(18); // 1 vlan
			(false, false, true,  true ) : get_l2_len_hit(22); // 2 vlan

			(true,  false, true,  false) : get_l2_len_hit(26); // e tag,  1 vlan
			(false, true,  true,  true ) : get_l2_len_hit(24); // vn tag, 2 vlan
		}
		const default_action = NoAction;
	}

	//=============================================================================
	// Table:
	//=============================================================================

	action rewrite_inner_ipv4_hdr1() {
		eg_md.payload_len = hdr_1.ipv4.total_len;
		gre_proto = GRE_PROTOCOLS_IP;
	}

	action rewrite_inner_ipv4_hdr2() {
		eg_md.payload_len = hdr_2.ipv4.total_len;
		gre_proto = GRE_PROTOCOLS_IP;
	}

	action rewrite_inner_ipv4_hdr3() {
		eg_md.payload_len = hdr_3.ipv4.total_len;
		gre_proto = GRE_PROTOCOLS_IP;
	}

	// --------------------------------

	action rewrite_inner_ipv6_hdr1() {
		if(OUTER_IPV6_ENABLE) {
//			eg_md.payload_len = hdr_1.ipv6.payload_len + 16w40;
			eg_md.payload_len = hdr_1.ipv6.payload_len;
			gre_proto = GRE_PROTOCOLS_IPV6;
		}
	}

	action rewrite_inner_ipv6_hdr2() {
		if(INNER_IPV6_ENABLE) {
//			eg_md.payload_len = hdr_2.ipv6.payload_len + 16w40;
			eg_md.payload_len = hdr_2.ipv6.payload_len;
			gre_proto = GRE_PROTOCOLS_IPV6;
		}
	}

	action rewrite_inner_ipv6_hdr3() {
		if(INNER_INNER_IPV6_ENABLE) {
//			eg_md.payload_len = hdr_3.ipv6.payload_len + 16w40;
			eg_md.payload_len = hdr_3.ipv6.payload_len;
			gre_proto = GRE_PROTOCOLS_IPV6;
		}
	}

	// --------------------------------

	// Look for the first valid l3.

	bool hdr_1_ipv6_isValid;
	bool hdr_2_ipv6_isValid;
	bool hdr_3_ipv6_isValid;

	table find_first_valid_l3 {
		key = {
// TODO: Derek: using the ipv6_isValid's does not fit!
			hdr_1.ipv4.isValid() : exact;
			hdr_1.ipv6.isValid() : exact;
//			hdr_1_ipv6_isValid   : exact;
			hdr_2.ipv4.isValid() : exact;
			hdr_2.ipv6.isValid() : exact;
//			hdr_2_ipv6_isValid   : exact;
			hdr_3.ipv4.isValid() : exact;
			hdr_3.ipv6.isValid() : exact;
//			hdr_3_ipv6_isValid   : exact;
		}

		actions = {
			rewrite_inner_ipv4_hdr1;
			rewrite_inner_ipv4_hdr2;
			rewrite_inner_ipv4_hdr3;

			rewrite_inner_ipv6_hdr1;
			rewrite_inner_ipv6_hdr2;
			rewrite_inner_ipv6_hdr3;
		}

		const entries = {
			// hdr_1       hdr_2         hdr_3
			// ----------- ------------- ------------
//			(true,  false, _,     _,     _,     _    ) : rewrite_inner_ipv4_hdr1(); // outer v4       (note: hdr_2 and hdr_3 are don't care)
//			(false, false, true,  false, _,     _    ) : rewrite_inner_ipv4_hdr2(); // inner v4       (note:           hdr_3 are don't care)
//			(false, false, false, false, true,  false) : rewrite_inner_ipv4_hdr3(); // inner-inner v4 (note:                 are don't care)
//
//			(false, true,  _,     _,     _,     _    ) : rewrite_inner_ipv6_hdr1(); // outer v6       (note: hdr_2 and hdr_3 are don't care)
//			(false, false, false, true,  _,     _    ) : rewrite_inner_ipv6_hdr2(); // inner v6       (note:           hdr_3 are don't care)
//			(false, false, false, false, false, true ) : rewrite_inner_ipv6_hdr3(); // inner-inner v6 (note:                 are don't care)

			(true,  false, false, false, false, false) : rewrite_inner_ipv4_hdr1(); // outer v4       (note: hdr_2 and hdr_3 are don't care)
			(true,  false, true,  false, false, false) : rewrite_inner_ipv4_hdr1(); // outer v4       (note: hdr_2 and hdr_3 are don't care)
			(true,  false, false, true,  false, false) : rewrite_inner_ipv4_hdr1(); // outer v4       (note: hdr_2 and hdr_3 are don't care)
			(true,  false, true,  true,  false, false) : rewrite_inner_ipv4_hdr1(); // outer v4       (note: hdr_2 and hdr_3 are don't care)
			(true,  false, false, false, true,  false) : rewrite_inner_ipv4_hdr1(); // outer v4       (note: hdr_2 and hdr_3 are don't care)
			(true,  false, true,  false, true,  false) : rewrite_inner_ipv4_hdr1(); // outer v4       (note: hdr_2 and hdr_3 are don't care)
			(true,  false, false, true,  true,  false) : rewrite_inner_ipv4_hdr1(); // outer v4       (note: hdr_2 and hdr_3 are don't care)
			(true,  false, true,  true,  true,  false) : rewrite_inner_ipv4_hdr1(); // outer v4       (note: hdr_2 and hdr_3 are don't care)
			(true,  false, false, false, false, true ) : rewrite_inner_ipv4_hdr1(); // outer v4       (note: hdr_2 and hdr_3 are don't care)
			(true,  false, true,  false, false, true ) : rewrite_inner_ipv4_hdr1(); // outer v4       (note: hdr_2 and hdr_3 are don't care)
			(true,  false, false, true,  false, true ) : rewrite_inner_ipv4_hdr1(); // outer v4       (note: hdr_2 and hdr_3 are don't care)
			(true,  false, true,  true,  false, true ) : rewrite_inner_ipv4_hdr1(); // outer v4       (note: hdr_2 and hdr_3 are don't care)
			(true,  false, false, false, true,  true ) : rewrite_inner_ipv4_hdr1(); // outer v4       (note: hdr_2 and hdr_3 are don't care)
			(true,  false, true,  false, true,  true ) : rewrite_inner_ipv4_hdr1(); // outer v4       (note: hdr_2 and hdr_3 are don't care)
			(true,  false, false, true,  true,  true ) : rewrite_inner_ipv4_hdr1(); // outer v4       (note: hdr_2 and hdr_3 are don't care)
			(true,  false, true,  true,  true,  true ) : rewrite_inner_ipv4_hdr1(); // outer v4       (note: hdr_2 and hdr_3 are don't care)

			(false, false, true,  false, false, false) : rewrite_inner_ipv4_hdr2(); // inner v4       (note:           hdr_3 are don't care)
			(false, false, true,  false, true,  false) : rewrite_inner_ipv4_hdr2(); // inner v4       (note:           hdr_3 are don't care)
			(false, false, true,  false, false, true ) : rewrite_inner_ipv4_hdr2(); // inner v4       (note:           hdr_3 are don't care)
			(false, false, true,  false, true,  true ) : rewrite_inner_ipv4_hdr2(); // inner v4       (note:           hdr_3 are don't care)

			(false, false, false, false, true,  false) : rewrite_inner_ipv4_hdr3(); // inner-inner v4 (note:                 are don't care)

			(false, true,  false, false, false, false) : rewrite_inner_ipv6_hdr1(); // outer v6       (note: hdr_2 and hdr_3 are don't care)
			(false, true,  true,  false, false, false) : rewrite_inner_ipv6_hdr1(); // outer v6       (note: hdr_2 and hdr_3 are don't care)
			(false, true,  false, true,  false, false) : rewrite_inner_ipv6_hdr1(); // outer v6       (note: hdr_2 and hdr_3 are don't care)
			(false, true,  true,  true,  false, false) : rewrite_inner_ipv6_hdr1(); // outer v6       (note: hdr_2 and hdr_3 are don't care)
			(false, true,  false, false, true,  false) : rewrite_inner_ipv6_hdr1(); // outer v6       (note: hdr_2 and hdr_3 are don't care)
			(false, true,  true,  false, true,  false) : rewrite_inner_ipv6_hdr1(); // outer v6       (note: hdr_2 and hdr_3 are don't care)
			(false, true,  false, true,  true,  false) : rewrite_inner_ipv6_hdr1(); // outer v6       (note: hdr_2 and hdr_3 are don't care)
			(false, true,  true,  true,  true,  false) : rewrite_inner_ipv6_hdr1(); // outer v6       (note: hdr_2 and hdr_3 are don't care)
			(false, true,  false, false, false, true ) : rewrite_inner_ipv6_hdr1(); // outer v6       (note: hdr_2 and hdr_3 are don't care)
			(false, true,  true,  false, false, true ) : rewrite_inner_ipv6_hdr1(); // outer v6       (note: hdr_2 and hdr_3 are don't care)
			(false, true,  false, true,  false, true ) : rewrite_inner_ipv6_hdr1(); // outer v6       (note: hdr_2 and hdr_3 are don't care)
			(false, true,  true,  true,  false, true ) : rewrite_inner_ipv6_hdr1(); // outer v6       (note: hdr_2 and hdr_3 are don't care)
			(false, true,  false, false, true,  true ) : rewrite_inner_ipv6_hdr1(); // outer v6       (note: hdr_2 and hdr_3 are don't care)
			(false, true,  true,  false, true,  true ) : rewrite_inner_ipv6_hdr1(); // outer v6       (note: hdr_2 and hdr_3 are don't care)
			(false, true,  false, true,  true,  true ) : rewrite_inner_ipv6_hdr1(); // outer v6       (note: hdr_2 and hdr_3 are don't care)
			(false, true,  true,  true,  true,  true ) : rewrite_inner_ipv6_hdr1(); // outer v6       (note: hdr_2 and hdr_3 are don't care)

			(false, false, false, true,  false, false) : rewrite_inner_ipv6_hdr2(); // inner v6       (note:           hdr_3 are don't care)
			(false, false, false, true,  true,  false) : rewrite_inner_ipv6_hdr2(); // inner v6       (note:           hdr_3 are don't care)
			(false, false, false, true,  false, true ) : rewrite_inner_ipv6_hdr2(); // inner v6       (note:           hdr_3 are don't care)
			(false, false, false, true,  true,  true ) : rewrite_inner_ipv6_hdr2(); // inner v6       (note:           hdr_3 are don't care)

			(false, false, false, false, false, true ) : rewrite_inner_ipv6_hdr3(); // inner-inner v6 (note:                 are don't care)
		}
	}

	//=============================================================================
	// Table:
	//=============================================================================

	action remove_metadata_len_hit(bit<16> length_offset) {
		eg_md.payload_len = eg_md.payload_len + length_offset;
		eg_md.mirror.type = SWITCH_MIRROR_TYPE_INVALID;
	}

	table remove_metadata_len {
		key = { eg_md.mirror.type : exact; }
		actions = { remove_metadata_len_hit; }
		const entries = {
			//-14
			SWITCH_MIRROR_TYPE_CPU               : remove_metadata_len_hit(0xFFF2); // TODO: derek: need to fix
#ifdef INT_V2
			//-13
//          SWITCH_MIRROR_TYPE_PORT              : remove_metadata_len_hit(0xFFF3); // derek: not used
			SWITCH_MIRROR_TYPE_DTEL_DROP         : remove_metadata_len_hit(0);
//          SWITCH_MIRROR_TYPE_DTEL_SWITCH_LOCAL : remove_metadata_len_hit(0);
			SWITCH_MIRROR_TYPE_DTEL_SWITCH_LOCAL : remove_metadata_len_hit(0xFFE0);
#else
			//-11
//          SWITCH_MIRROR_TYPE_PORT              : remove_metadata_len_hit(0xFFF5); // derek: not used
			SWITCH_MIRROR_TYPE_DTEL_DROP         : remove_metadata_len_hit(2);
			SWITCH_MIRROR_TYPE_DTEL_SWITCH_LOCAL : remove_metadata_len_hit(0x0);
#endif /* INT_V2 */
			//-7
			SWITCH_MIRROR_TYPE_SIMPLE            : remove_metadata_len_hit(0xFFF9);
#ifdef INT_V2
			/* len(telemetry report v2.0 header included in report_length)
			 * + len(telemetry drop metadata) - 4 bytes of CRC */
			SWITCH_MIRROR_TYPE_DTEL_DEFLECT      : remove_metadata_len_hit(20);
#else
			/* len(telemetry report v0.5 header)
			 * + len(telemetry drop report header) - 4 bytes of CRC */
			SWITCH_MIRROR_TYPE_DTEL_DEFLECT      : remove_metadata_len_hit(20);
#endif /* INT_V2 */
		}
	}

	//=============================================================================
	// Apply
	//=============================================================================

	apply {
		if(OUTER_IPV6_ENABLE)       hdr_1_ipv6_isValid = hdr_1.ipv6.isValid();
		if(INNER_IPV6_ENABLE)       hdr_2_ipv6_isValid = hdr_2.ipv6.isValid();
		if(INNER_INNER_IPV6_ENABLE) hdr_3_ipv6_isValid = hdr_3.ipv6.isValid();

		get_l2_len.apply();

		if(eg_md.pkt_src == SWITCH_PKT_SRC_BRIDGED) {

			// *** For bridged packets, we use the payload length in the l3 header directly. ***

			find_first_valid_l3.apply();

			// For ipv6, add hdr size to payload len.
			if(gre_proto == GRE_PROTOCOLS_IPV6) {
				eg_md.payload_len = eg_md.payload_len + 16w40;
			}
		} else {
			// *** For mirrored packets, we use the packet length to derive the payload length.         ***
			// *** (this is what switch.p4 does, I believe so as not to have to parse everything again) ***
			
			remove_metadata_len.apply();

			// Subtract off ethernet header.
			eg_md.payload_len =  eg_md.payload_len - l2_len;
		}
	}
}

//	sizeInBits(meta.mpls_resubmit)
//	sizeInBytes(meta.mpls_resubmit)

#endif
