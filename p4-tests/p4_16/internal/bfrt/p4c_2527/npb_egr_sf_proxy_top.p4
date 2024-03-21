#include "npb_egr_sf_proxy_hdr_strip.p4"
#include "npb_egr_sf_proxy_hdr_edit.p4"
#include "npb_egr_sf_proxy_truncate.p4"
#include "npb_egr_sf_proxy_meter.p4"
#include "npb_ing_sf_npb_basic_adv_dedup.p4"

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
#if defined(SF_2_SHARED_IP_ACL_ENABLE)
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

	action egr_sf_action_sel_hit(
		bit<SAP_ID_WIDTH>                                     dsap,
		bit<6>                                                action_bitmask,
		bit<NPB_EGR_SF_2_EGRESS_SFP_ACT_SEL_TABLE_DEPTH_POW2> action_3_meter_id,
		bit<8>                                                action_3_meter_overhead
//		bit<3>                                                discard
	) {
		eg_md.nsh_type1.dsap          = dsap;

		eg_md.action_bitmask          = action_bitmask;

		eg_md.action_3_meter_id       = action_3_meter_id;
		eg_md.action_3_meter_overhead = action_3_meter_overhead;

//		eg_intr_md_for_dprsr.drop_ctl = discard; // drop packet
	}

	// =====================================

	action egr_sf_action_sel_miss(
	) {
		eg_md.action_bitmask          = 0;
	}

	// =====================================

	table egr_sf_action_sel {
		key = {
		    hdr_0.nsh_type1.spi : exact @name("spi");
		    hdr_0.nsh_type1.si  : exact @name("si");
		}

		actions = {
		    egr_sf_action_sel_hit;
		    egr_sf_action_sel_miss;
		}

		const default_action = egr_sf_action_sel_miss;
		size = NPB_EGR_SF_2_EGRESS_SFP_ACT_SEL_TABLE_DEPTH;
	}

	// =========================================================================
	// Table #x: Ip Length Range
	// =========================================================================

    bit<16> length_bitmask_internal = 0;

#ifdef SF_2_LEN_RNG_TABLE_ENABLE
    action ing_sf_ip_len_rng_hit(
        bit<16> length_bitmask
    ) {
        length_bitmask_internal = length_bitmask;
    }

    // =====================================

    action ing_sf_ip_len_rng_miss(
    ) {
//      length_bitmask_internal = 0;
    }

    // =====================================

    table egr_sf_ip_len_rng {
        key = {
            eg_md.lkp.ip_len : range @name("ip_len");
        }

        actions = {
            ing_sf_ip_len_rng_hit;
            ing_sf_ip_len_rng_miss;
        }

        const default_action = ing_sf_ip_len_rng_miss;
        size = NPB_EGR_SF_2_EGRESS_SFP_POLICY_LEN_RNG_TABLE_DEPTH;
    }
#endif

	// =========================================================================
	// Apply
	// =========================================================================

	apply {

		if(eg_md.nsh_type1.sf_bitmask[2:2] == 1) {

			// ==================================
			// Action Lookup
			// ==================================

			egr_sf_action_sel.apply();

			// ==================================
			// Decrement SI
			// ==================================

			// Derek: We have moved this here, rather than at the end of the sf,
			// in violation of RFC8300.  This is becuase of an issue were a sf
			// can reclassify the packet with a new si, which would then get immediately
			// decremented.  This means firmware would have to add 1 to the si value
			// the really wanted.  So move it here so that is gets decremented after
			// the lookup that uses it, but before any actions have run....

#ifdef BUG_09719_WORKAROUND
			hdr_0.nsh_type1.si = hdr_0.nsh_type1.si - 1; // decrement sp_index
#else
			hdr_0.nsh_type1.si = hdr_0.nsh_type1.si |-| 1; // decrement sp_index
#endif

			// ==================================
			// Actions(s)
			// ==================================

			if(eg_md.action_bitmask[0:0] == 1) {

				// ----------------------------------
				// Action #0 - Policy
				// ----------------------------------

#ifdef SF_2_LEN_RNG_TABLE_ENABLE
				egr_sf_ip_len_rng.apply();
#endif

				// multiple small policy tables....
				acl.apply(eg_md.lkp, eg_md, eg_intr_md_for_dprsr, length_bitmask_internal, hdr_0);

			}

			if(eg_md.action_bitmask[1:1] == 1) {

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

			}

			if(eg_md.action_bitmask[2:2] == 1) {

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

			}

			if(eg_md.action_bitmask[3:3] == 1) {

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

			}

			if(eg_md.action_bitmask[4:4] == 1) {

				// ----------------------------------
				// Action #4 - Meter
				// ----------------------------------
#ifdef SF_2_METER_ENABLE
				npb_egr_sf_proxy_meter.apply (
					hdr,
					eg_md,
					eg_intr_md,
					eg_intr_md_from_prsr,
					eg_intr_md_for_dprsr,
					eg_intr_md_for_oport
				);
#endif
			}

			if(eg_md.action_bitmask[5:5] == 1) {

				// ----------------------------------
				// Action #5 - Deduplication
				// ----------------------------------
#ifdef SF_2_DEDUP_ENABLE
				npb_ing_sf_npb_basic_adv_dedup.apply (
					hdr,
					eg_md,
					eg_intr_md,
					eg_intr_md_from_prsr,
					eg_intr_md_for_dprsr,
					eg_intr_md_for_oport
				);
#endif
			}

		}
	}
}

// =============================================================================
// =============================================================================
// =============================================================================
// =============================================================================
// =============================================================================
/*
control npb_egr_sf_proxy_top_part2 (
	inout switch_header_transport_t                   hdr_0,
	inout switch_header_outer_t                       hdr_1,
	inout switch_egress_metadata_t                    eg_md,
	in    egress_intrinsic_metadata_t                 eg_intr_md,
	in    egress_intrinsic_metadata_from_parser_t     eg_intr_md_from_prsr,
	inout egress_intrinsic_metadata_for_deparser_t    eg_intr_md_for_dprsr,
	inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport
) {

	// =========================================================================
	// Notes
	// =========================================================================

	// Note: egress action_bitmask defined as follows....
	//
	//   [0:0] act #1: unused (was header strip)
	//   [1:1] act #2: unused (was header edit)
	//   [2:2] act #3: unused (reserved for truncate)
	//   [3:3] act #4: meter
	//   [4:4] act #5: dedup

	// =========================================================================
	// Apply
	// =========================================================================

	apply {

		if(eg_md.nsh_type1.sf_bitmask[2:2] == 1) {

			// ==================================
			// Actions(s)
			// ==================================

			if(eg_md.action_bitmask[0:0] == 1) {

				// ----------------------------------
				// Action #0 - Policy
				// ----------------------------------

#ifdef SF_2_LEN_RNG_TABLE_ENABLE
				egr_sf_ip_len_rng.apply();
#endif

				// multiple small policy tables....
				acl.apply(eg_md.lkp, eg_md, eg_intr_md_for_dprsr, length_bitmask_internal);

			}

			if(eg_md.action_bitmask[1:1] == 1) {

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

			}

			if(eg_md.action_bitmask[2:2] == 1) {

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

			}

			if(eg_md.action_bitmask[3:3] == 1) {

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

			}

			if(eg_md.action_bitmask[4:4] == 1) {

				// ----------------------------------
				// Action #4 - Meter
				// ----------------------------------
#ifdef SF_2_METER_ENABLE
				npb_egr_sf_proxy_meter.apply (
					hdr,
					eg_md,
					eg_intr_md,
					eg_intr_md_from_prsr,
					eg_intr_md_for_dprsr,
					eg_intr_md_for_oport
				);
#endif
			}

			if(eg_md.action_bitmask[5:5] == 1) {

				// ----------------------------------
				// Action #5 - Deduplication
				// ----------------------------------
#ifdef SF_2_DEDUP_ENABLE
				npb_ing_sf_npb_basic_adv_dedup.apply (
					hdr,
					eg_md,
					eg_intr_md,
					eg_intr_md_from_prsr,
					eg_intr_md_for_dprsr,
					eg_intr_md_for_oport
				);
#endif
			}
		}
	}
}
*/
