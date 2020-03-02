//#include "npb_ing_sf_npb_basic_adv_acl.p4"
//#include "npb_ing_sf_npb_basic_adv_dedup.p4"

control npb_ing_sf_npb_basic_adv_top (
	inout switch_header_transport_t                 hdr_0,
	inout switch_header_inner_t                     hdr_2,
	inout switch_ingress_metadata_t                 ig_md,
	in    ingress_intrinsic_metadata_t              ig_intr_md,
	in    ingress_intrinsic_metadata_from_parser_t  ig_intr_md_from_prsr,
	inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
	inout ingress_intrinsic_metadata_for_tm_t       ig_intr_md_for_tm
) {

	IngressAcl(
		INGRESS_IPV4_ACL_TABLE_SIZE,
#if defined(SF_0_ACL_SHARED_IP_ENABLE)
#else
        INGRESS_IPV6_ACL_TABLE_SIZE,
#endif
        INGRESS_MAC_ACL_TABLE_SIZE,
        INGRESS_L7_ACL_TABLE_SIZE
	) acl;

	// temporary internal variables
	bit<2>  action_bitmask_internal;
	bit<16> int_ctrl_flags_internal;

    // =========================================================================
    // Notes
    // =========================================================================

    // Note: egress action_bitmask defined as follows....
    //
    //   [0:0] act #1: policy
    //   [1:1] act #2: unused (was dedup)

    // =========================================================================
    // Table #1: Action Select
    // =========================================================================

    action ing_sf_action_sel_hit(
        bit<2>  action_bitmask,
		bit<16> int_ctrl_flags
//      bit<3>  discard
    ) {
        action_bitmask_internal = action_bitmask;
		int_ctrl_flags_internal = int_ctrl_flags;

//      ig_intr_md_for_dprsr.drop_ctl = discard; // drop packet
    }

    // =====================================

    action ing_sf_action_sel_miss(
    ) {
        action_bitmask_internal = 0;
		int_ctrl_flags_internal = 0;
    }

    // =====================================

    table ing_sf_action_sel {
        key = {
            hdr_0.nsh_type1.spi        : exact @name("spi");
            hdr_0.nsh_type1.si         : exact @name("si");
        }

        actions = {
            ing_sf_action_sel_hit;
            ing_sf_action_sel_miss;
        }

        const default_action = ing_sf_action_sel_miss;
        size = NPB_ING_SF_0_BAS_ADV_ACT_SEL_TABLE_DEPTH;
    }

    // =========================================================================
    // Table #2: IP Length Range
    // =========================================================================

	bit<16> length_bitmask_internal = 0;

#ifdef SF_0_LEN_RNG_TABLE_ENABLE
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

    table ing_sf_ip_len_rng {
        key = {
            ig_md.lkp.ip_len : range @name("ip_len");
        }

        actions = {
            ing_sf_ip_len_rng_hit;
            ing_sf_ip_len_rng_miss;
        }

        const default_action = ing_sf_ip_len_rng_miss;
        size = NPB_ING_SF_0_BAS_ADV_POLICY_LEN_RNG_TABLE_DEPTH;
    }
#endif

    // =========================================================================
    // Apply
    // =========================================================================

	apply {
		if(ig_md.nsh_type1.sf_bitmask[0:0] == 1) {

			// =====================================
			// Action Lookup
			// =====================================

			ing_sf_action_sel.apply();

			// =====================================
			// Decrement SI
			// =====================================

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

			// =====================================
			// Action(s)
			// =====================================

			if(action_bitmask_internal[0:0] == 1) {

				// -------------------------------------
				// Action #0 - Policy
				// -------------------------------------

#ifdef SF_0_LEN_RNG_TABLE_ENABLE
				ing_sf_ip_len_rng.apply();
#endif

				acl.apply(ig_md.lkp, ig_md, ig_intr_md_for_dprsr, length_bitmask_internal, hdr_0, hdr_2, int_ctrl_flags_internal);

			}

			if(action_bitmask_internal[1:1] == 1) {

				// -------------------------------------
				// Action #1 - Deduplication
				// -------------------------------------
/*
#ifdef SF_0_DEDUP_ENABLE
				npb_ing_sf_npb_basic_adv_dedup.apply (
					hdr_0,
					ig_md,
					ig_intr_md,
					ig_intr_md_from_prsr,
					ig_intr_md_for_dprsr,
					ig_intr_md_for_tm
				);
#endif
*/
			}

		}

	}
}
