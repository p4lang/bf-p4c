#include "npb_egr_sf_proxy_hdr_strip.p4"
#include "npb_egr_sf_proxy_hdr_edit.p4"
#include "npb_egr_sf_proxy_truncate.p4"
//#include "npb_egr_sf_proxy_meter.p4"
#ifdef SF_2_DEDUP_ENABLE
  #include "npb_ing_sf_npb_basic_adv_dedup.p4"
#endif

#include "acl.p4"

control npb_egr_sf_proxy_top (
	inout switch_header_transport_t                   hdr_0,
	inout switch_header_outer_t                       hdr_1,
	inout switch_egress_metadata_t                    eg_md,
	in    egress_intrinsic_metadata_t                 eg_intr_md,
	in    egress_intrinsic_metadata_from_parser_t     eg_intr_md_from_prsr,
	inout egress_intrinsic_metadata_for_deparser_t    eg_intr_md_for_dprsr,
	inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport
) {

	EgressAcl(
		EGRESS_IPV4_ACL_TABLE_SIZE,
#if defined(SF_2_ACL_SHARED_IP_ENABLE)
#else
		EGRESS_IPV6_ACL_TABLE_SIZE,
#endif
		EGRESS_MAC_ACL_TABLE_SIZE
	) acl;

	// =========================================================================
	// Notes
	// =========================================================================

	// Note: egress action_bitmask defined as follows....
	//
	//   [0:0] act #1: policy
	//   [1:1] act #2: header strip
	//   [2:2] act #3: header edit
	//   [3:3] act #4: truncate
	//   [4:4] act #5: meter
	//   [5:5] act #6: dedup

	// =========================================================================
	// Table #1: Action Select
	// =========================================================================

	bit<SF_INT_CTRL_FLAGS_WIDTH> int_ctrl_flags = 0;

	action egr_sf_action_sel_hit(
//		bit<6>                                                action_bitmask,
#ifdef SF_2_ACL_INT_CTRL_FLAGS_ENABLE
		bit<SF_INT_CTRL_FLAGS_WIDTH> int_ctrl_flags,
#endif
		bit<DSAP_ID_WIDTH>                                    dsap
//		bit<NPB_EGR_SF_2_EGRESS_SFP_ACT_SEL_TABLE_DEPTH_POW2> action_3_meter_id,
//		bit<8>                                                action_3_meter_overhead
//		bit<3>                                                discard
	) {
//		eg_md.action_bitmask          = action_bitmask;
#ifdef SF_2_ACL_INT_CTRL_FLAGS_ENABLE
		int_ctrl_flags                = int_ctrl_flags;
#endif
		eg_md.nsh_md.dsap             = dsap;

//		eg_md.action_3_meter_id       = action_3_meter_id;
//		eg_md.action_3_meter_overhead = action_3_meter_overhead;

//		eg_intr_md_for_dprsr.drop_ctl = discard; // drop packet
	}

	// =====================================

	action egr_sf_action_sel_miss(
	) {
//		eg_md.action_bitmask          = 0;
//		int_ctrl_flags                = 0;
//		eg_md.nsh_md.dsap             = 0;
	}

	// =====================================

	table egr_sf_action_sel {
		key = {
		    hdr_0.nsh_type1.spi : exact @name("spi");
		    hdr_0.nsh_type1.si  : exact @name("si");
		}

		actions = {
			NoAction;
		    egr_sf_action_sel_hit;
		    egr_sf_action_sel_miss;
		}

		const default_action = egr_sf_action_sel_miss;
		size = NPB_EGR_SF_2_EGRESS_SFP_ACT_SEL_TABLE_DEPTH;
	}

	// =========================================================================
	// Table #x: Ip Length Range
	// =========================================================================

	bit<SF_L3_LEN_RNG_WIDTH> ip_len = 0;
	bool                     ip_len_is_rng_bitmask = false;

#ifdef SF_2_L3_LEN_RNG_TABLE_ENABLE
	action egr_sf_ip_len_rng_hit(
		bit<SF_L3_LEN_RNG_WIDTH> rng_bitmask
	) {
		ip_len = rng_bitmask;
		ip_len_is_rng_bitmask = true;
	}

	// =====================================

	action egr_sf_ip_len_rng_miss(
	) {
		ip_len = eg_md.lkp_1.ip_len;
		ip_len_is_rng_bitmask = false;
	}

	// =====================================

	table egr_sf_ip_len_rng {
		key = {
			eg_md.lkp_1.ip_len : range @name("ip_len");
		}

		actions = {
			NoAction;
			egr_sf_ip_len_rng_hit;
			egr_sf_ip_len_rng_miss;
		}

		const default_action = egr_sf_ip_len_rng_miss;
		size = NPB_EGR_SF_2_EGRESS_SFP_POLICY_L3_LEN_RNG_TABLE_DEPTH;
	}
#endif

	// =========================================================================
	// Table #2: L4 Src Port Range
	// =========================================================================

	bit<SF_L4_SRC_RNG_WIDTH> l4_src_port = 0;
	bool                     l4_src_port_is_rng_bitmask = false;

#ifdef SF_2_L4_SRC_RNG_TABLE_ENABLE
	action egr_sf_l4_src_port_rng_hit(
		bit<SF_L4_SRC_RNG_WIDTH> rng_bitmask
	) {
		l4_src_port = rng_bitmask;
		l4_src_port_is_rng_bitmask = true;
	}

	// =====================================

	action egr_sf_l4_src_port_rng_miss(
	) {
		l4_src_port = eg_md.lkp_1.l4_src_port;
		l4_src_port_is_rng_bitmask = false;
	}

	// =====================================

	table egr_sf_l4_src_port_rng {
		key = {
			eg_md.lkp_1.l4_src_port : range @name("l4_src_port");
		}

		actions = {
			NoAction;
			egr_sf_l4_src_port_rng_hit;
			egr_sf_l4_src_port_rng_miss;
		}

		const default_action = egr_sf_l4_src_port_rng_miss;
		size = NPB_EGR_SF_2_EGRESS_SFP_POLICY_L4_SRC_RNG_TABLE_DEPTH;
	}
#endif

	// =========================================================================
	// Table #2: L4 Dst Port Range
	// =========================================================================

	bit<SF_L4_DST_RNG_WIDTH> l4_dst_port = 0;
	bool                     l4_dst_port_is_rng_bitmask = false;

#ifdef SF_2_L4_DST_RNG_TABLE_ENABLE
	action egr_sf_l4_dst_port_rng_hit(
		bit<SF_L4_DST_RNG_WIDTH> rng_bitmask
	) {
		l4_dst_port = rng_bitmask;
		l4_dst_port_is_rng_bitmask = true;
	}

	// =====================================

	action egr_sf_l4_dst_port_rng_miss(
	) {
		l4_dst_port = eg_md.lkp_1.l4_dst_port;
		l4_dst_port_is_rng_bitmask = false;
	}

	// =====================================

	table egr_sf_l4_dst_port_rng {
		key = {
			eg_md.lkp_1.l4_dst_port : range @name("l4_dst_port");
		}

		actions = {
			NoAction;
			egr_sf_l4_dst_port_rng_hit;
			egr_sf_l4_dst_port_rng_miss;
		}

		const default_action = egr_sf_l4_dst_port_rng_miss;
		size = NPB_EGR_SF_2_EGRESS_SFP_POLICY_L4_DST_RNG_TABLE_DEPTH;
	}
#endif

	// =========================================================================
	// Apply
	// =========================================================================

	apply {

		eg_md.nsh_md.dsap             = 0;

		// ==================================
		// Action Lookup
		// ==================================

		if(egr_sf_action_sel.apply().hit) {

			// ==================================
			// Decrement SI
			// ==================================

			// Derek: We have moved this here, rather than at the end of the sf,
			// in violation of RFC8300.  This is because of an issue were a sf
			// can reclassify the packet with a new si, which would then get immediately
			// decremented.  This means firmware would have to add 1 to the si value
			// the really wanted.  So we move it here so that is gets decremented after
			// the lookup that uses it, but before any actions have run....

#ifdef BUG_09719_WORKAROUND
			hdr_0.nsh_type1.si = hdr_0.nsh_type1.si - 1; // decrement sp_index
#else
			hdr_0.nsh_type1.si = hdr_0.nsh_type1.si |-| 1; // decrement sp_index
#endif

			// ==================================
			// Actions(s)
			// ==================================

//			if(eg_md.action_bitmask[0:0] == 1) {

				// ----------------------------------
				// Action #0 - Policy
				// ----------------------------------

#ifdef SF_2_L3_LEN_RNG_TABLE_ENABLE
				egr_sf_ip_len_rng.apply();
#else
				ip_len = eg_md.lkp_1.ip_len;
				ip_len_is_rng_bitmask = false;
#endif
#ifdef SF_2_L4_SRC_RNG_TABLE_ENABLE
				egr_sf_l4_src_port_rng.apply();
#else
				l4_src_port = eg_md.lkp_1.l4_src_port;
				l4_src_port_is_rng_bitmask = false;
#endif
#ifdef SF_2_L4_DST_RNG_TABLE_ENABLE
				egr_sf_l4_dst_port_rng.apply();
#else
				l4_dst_port = eg_md.lkp_1.l4_dst_port;
				l4_dst_port_is_rng_bitmask = false;
#endif

				acl.apply(
					eg_md.lkp_1,
					eg_md,
					eg_intr_md_for_dprsr,
					ip_len,
					ip_len_is_rng_bitmask,
					l4_src_port,
					l4_src_port_is_rng_bitmask,
					l4_dst_port,
					l4_dst_port_is_rng_bitmask,
					hdr_0,
					hdr_1,
					int_ctrl_flags
				);
//			}

//			if(eg_md.action_bitmask[1:1] == 1) {

				// ----------------------------------
				// Action #1 - Hdr Strip
				// ----------------------------------
				npb_egr_sf_proxy_hdr_strip.apply (
					hdr_0,
					hdr_1,
					eg_md,
					eg_intr_md,
					eg_intr_md_from_prsr,
					eg_intr_md_for_dprsr,
					eg_intr_md_for_oport
				);

//			}

//			if(eg_md.action_bitmask[2:2] == 1) {

				// ----------------------------------
				// Action #2 - Hdr Edit
				// ----------------------------------
				npb_egr_sf_proxy_hdr_edit.apply (
					hdr_0,
					hdr_1,
					eg_md,
					eg_intr_md,
					eg_intr_md_from_prsr,
					eg_intr_md_for_dprsr,
					eg_intr_md_for_oport
				);

//			}

//			if(eg_md.action_bitmask[3:3] == 1) {
/*
				// ----------------------------------
				// Action #3 - Truncate
				// ----------------------------------
				npb_egr_sf_proxy_truncate.apply (
					hdr_0,
					eg_md,
					eg_intr_md,
					eg_intr_md_from_prsr,
					eg_intr_md_for_dprsr,
					eg_intr_md_for_oport
				);
*/
//			}

//			if(eg_md.action_bitmask[4:4] == 1) {

				// ----------------------------------
				// Action #4 - Meter
				// ----------------------------------
#ifdef SF_2_METER_ENABLE
				npb_egr_sf_proxy_meter.apply (
					hdr_0,
					eg_md,
					eg_intr_md,
					eg_intr_md_from_prsr,
					eg_intr_md_for_dprsr,
					eg_intr_md_for_oport
				);
#endif
//			}

//			if(eg_md.action_bitmask[5:5] == 1) {

				// ----------------------------------
				// Action #5 - Deduplication
				// ----------------------------------
#ifdef SF_2_DEDUP_ENABLE
				npb_egr_sf_proxy_dedup.apply (
					eg_md.nsh_md.dedup_en,
					eg_md.lkp_1,         // for hash
					(bit<VPN_ID_WIDTH>)hdr_0.nsh_type1.vpn, // for hash
//					eg_md.ingress_port,  // for dedup
					hdr_0.nsh_type1.sap, // for dedup
					eg_intr_md_for_dprsr.drop_ctl
				);
#endif
//			}

		}
	}
}
